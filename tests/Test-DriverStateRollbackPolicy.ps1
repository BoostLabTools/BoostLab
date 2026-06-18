[CmdletBinding()]
param(
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $scriptPath = if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $PSCommandPath
    }
    elseif (-not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
        $MyInvocation.MyCommand.Path
    }
    else {
        throw 'Unable to determine the driver policy test path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$policyPath = Join-Path $ProjectRoot 'config\DriverStatePolicy.psd1'
$stateModulePath = Join-Path $ProjectRoot 'core\DriverState.psm1'
$executionModulePath = Join-Path $ProjectRoot 'core\DriverExecution.psm1'
$policyDocPath = Join-Path $ProjectRoot 'docs\driver-state-capture-rollback.md'
$runtimeExecutionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$errors = [System.Collections.Generic.List[string]]::new()
foreach ($requiredPath in @(
    $policyPath
    $stateModulePath
    $executionModulePath
    $policyDocPath
)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        $errors.Add("Required Phase 41 file is missing: $requiredPath")
    }
}
if ($errors.Count -gt 0) {
    throw "Driver policy validation failed:`r`n- $($errors -join "`r`n- ")"
}

Import-Module `
    -Name $stateModulePath `
    -Force `
    -Scope Local `
    -DisableNameChecking `
    -ErrorAction Stop
Import-Module `
    -Name $executionModulePath `
    -Force `
    -Scope Local `
    -DisableNameChecking `
    -ErrorAction Stop

$tempRoot = Join-Path `
    ([IO.Path]::GetTempPath()) `
    ("BoostLab-DriverStateTest-{0}" -f [guid]::NewGuid())
$stateRoot = Join-Path $tempRoot 'DriverState'
$provenancePath = Join-Path $tempRoot 'mock-nvidia-driver.bin'
$rebootRecordPath = Join-Path $tempRoot 'mock-reboot-record.json'
$relatedRecordPath = Join-Path $tempRoot 'mock-related-state.json'
[IO.Directory]::CreateDirectory($tempRoot) | Out-Null
[IO.File]::WriteAllText($provenancePath, 'mock driver bytes only')
[IO.File]::WriteAllText($rebootRecordPath, '{"mockReboot":true}')
[IO.File]::WriteAllText($relatedRecordPath, '{"mockState":true}')

try {
    foreach ($commandName in @(
        'Get-BoostLabDriverStatePolicy'
        'Get-BoostLabDriverStateRoot'
        'Test-BoostLabDriverStatePolicy'
        'Test-BoostLabDriverTarget'
        'New-BoostLabDriverInventoryRecord'
        'Save-BoostLabDriverStateRecord'
        'Import-BoostLabDriverStateRecord'
        'Test-BoostLabDriverStateRecord'
        'New-BoostLabDriverMutationPlan'
        'Set-BoostLabDriverMutationState'
        'New-BoostLabDriverRollbackPlan'
        'Set-BoostLabDriverRollbackState'
        'Test-BoostLabDriverExecutionRequest'
        'Invoke-BoostLabDriverMutation'
        'Test-BoostLabDriverRollbackRequest'
        'Invoke-BoostLabDriverRollback'
    )) {
        if (-not (Get-Command -Name $commandName -ErrorAction SilentlyContinue)) {
            $errors.Add("Phase 41 helper is not exported: $commandName")
        }
    }

    $productionPolicy = Get-BoostLabDriverStatePolicy -PolicyPath $policyPath
    $productionValidation = Test-BoostLabDriverStatePolicy `
        -Policy $productionPolicy
    if (-not $productionValidation.IsValid) {
        $errors.Add(
            'Production driver state policy is invalid: ' +
            ($productionValidation.Errors -join '; ')
        )
    }
    if ($productionValidation.DriverScopeCount -ne 0) {
        $errors.Add('Phase 41 must not approve production driver scopes.')
    }

    $deviceId = 'PCI\VEN_10DE&DEV_2684&SUBSYS_00000000'
    $hardwareId = 'PCI\VEN_10DE&DEV_2684'
    $packageIdentity = 'nvidia-display-31.0.15.1234'
    $artifactId = 'mock-nvidia-driver'
    $testPolicy = @{
        SchemaVersion = '1.0'
        MaxRecordAgeDays = 30
        DriverScopes = @(
            @{
                ScopeId = 'mock-nvidia-driver-scope'
                ToolIds = @('mock-driver-tool')
                ActionIds = @('Apply')
                DeviceClasses = @('Display.NVIDIA')
                DeviceInstanceIds = @($deviceId)
                HardwareIds = @($hardwareId)
                VendorIds = @('10DE')
                VendorNames = @('NVIDIA')
                DriverPackageIdentities = @($packageIdentity)
                AllowedMutations = @(
                    'Install'
                    'Update'
                    'Uninstall'
                    'Rollback'
                    'Disable'
                    'Enable'
                    'RemovePackage'
                    'ProfileImport'
                    'DebloatComponentRemoval'
                )
                ArtifactIds = @($artifactId)
                RebootCapableMutations = @('Install', 'Update', 'Rollback')
                RequiredStateFoundations = @('Rollback', 'ServiceRollback')
                RequireArtifactProvenance = $true
                RequireRebootWorkflow = $true
                AllowGpuSpecific = $true
                AllowNvidiaGpuOnly = $true
                AllowPackageRemoval = $true
                AllowProfileImport = $true
                AllowComponentRemoval = $true
                NeedsExplicitConfirmation = $true
            }
        )
    }
    $testValidation = Test-BoostLabDriverStatePolicy -Policy $testPolicy
    if (
        -not $testValidation.IsValid -or
        $testValidation.DriverScopeCount -ne 1
    ) {
        $errors.Add(
            'Mock driver policy was rejected: ' +
            ($testValidation.Errors -join '; ')
        )
    }

    $broadPolicy = @{
        SchemaVersion = '1.0'
        MaxRecordAgeDays = 30
        DriverScopes = @(
            @{
                ScopeId = 'broad-driver-scope'
                ToolIds = @('mock-driver-tool')
                ActionIds = @('Apply')
                DeviceClasses = @('Display')
                DeviceInstanceIds = @()
                HardwareIds = @()
                VendorIds = @('10DE')
                VendorNames = @('NVIDIA')
                DriverPackageIdentities = @()
                AllowedMutations = @('Update')
                ArtifactIds = @($artifactId)
                RebootCapableMutations = @()
                RequiredStateFoundations = @()
                RequireArtifactProvenance = $true
                RequireRebootWorkflow = $false
                AllowGpuSpecific = $true
                AllowNvidiaGpuOnly = $true
                AllowPackageRemoval = $false
                AllowProfileImport = $false
                AllowComponentRemoval = $false
                NeedsExplicitConfirmation = $true
            }
        )
    }
    if ((Test-BoostLabDriverStatePolicy -Policy $broadPolicy).IsValid) {
        $errors.Add('Class-only broad driver scope was not denied.')
    }
    $wildcardPolicy = $testPolicy.Clone()
    $wildcardScope = @{} + $testPolicy.DriverScopes[0]
    $wildcardScope['DeviceInstanceIds'] = @('PCI\VEN_10DE*')
    $wildcardPolicy['DriverScopes'] = @($wildcardScope)
    if ((Test-BoostLabDriverStatePolicy -Policy $wildcardPolicy).IsValid) {
        $errors.Add('Wildcard driver device scope was not denied.')
    }

    $snapshot = [pscustomobject][ordered]@{
        DeviceClass = 'Display.NVIDIA'
        DeviceInstanceId = $deviceId
        HardwareIds = @($hardwareId)
        VendorId = '10DE'
        VendorName = 'NVIDIA'
        DriverProvider = 'NVIDIA'
        DriverVersion = '31.0.15.1234'
        DriverDate = '2026-01-15'
        InfName = 'nv_dispig.inf'
        PublishedName = 'oem42.inf'
        DriverPackageIdentity = $packageIdentity
        DeviceStatus = 'OK'
        ProblemCode = '0'
        AssociatedServices = @('mock-nvidia-service')
        AssociatedFiles = @('C:\Mock\Nvidia\driver.sys')
        SourceStoreLocation = 'C:\Mock\DriverStore\nvidia-display'
        IsGpuDevice = $true
    }
    $provenanceEvidence = [pscustomobject]@{
        ArtifactId = $artifactId
        Verified = $true
        LocalPath = $provenancePath
        Sha256 = (Get-FileHash -LiteralPath $provenancePath -Algorithm SHA256).Hash
    }
    $rebootReference = [pscustomobject]@{
        ToolId = 'mock-driver-tool'
        ActionId = 'Apply'
        RecordPath = $rebootRecordPath
        RecordHash = (
            Get-FileHash -LiteralPath $rebootRecordPath -Algorithm SHA256
        ).Hash
        Verified = $true
    }
    $relatedReferences = @(
        [pscustomobject]@{
            Foundation = 'Rollback'
            ReferenceId = 'mock-file-registry-state'
            RecordPath = $relatedRecordPath
            Verified = $true
        }
        [pscustomobject]@{
            Foundation = 'ServiceRollback'
            ReferenceId = 'mock-service-state'
            RecordPath = $relatedRecordPath
            Verified = $true
        }
    )

    $productionTarget = Test-BoostLabDriverTarget `
        -ToolId 'mock-driver-tool' `
        -ActionId 'Apply' `
        -ScopeId 'mock-nvidia-driver-scope' `
        -MutationType Update `
        -DeviceState $snapshot `
        -ProvenanceEvidence $provenanceEvidence `
        -RebootWorkflowReference $rebootReference `
        -RelatedStateReferences $relatedReferences `
        -Policy $productionPolicy
    if ($productionTarget.IsAllowed) {
        $errors.Add('Empty production driver scopes did not deny NVIDIA work.')
    }

    $amdSnapshot = $snapshot | Select-Object *
    $amdSnapshot.VendorId = '1002'
    $amdSnapshot.VendorName = 'AMD'
    $amdTarget = Test-BoostLabDriverTarget `
        -ToolId 'mock-driver-tool' `
        -ActionId 'Apply' `
        -ScopeId 'mock-nvidia-driver-scope' `
        -MutationType Update `
        -DeviceState $amdSnapshot `
        -ProvenanceEvidence $provenanceEvidence `
        -RebootWorkflowReference $rebootReference `
        -RelatedStateReferences $relatedReferences `
        -Policy $testPolicy
    if ($amdTarget.IsAllowed) {
        $errors.Add('AMD GPU driver target was not denied.')
    }
    $intelSnapshot = $snapshot | Select-Object *
    $intelSnapshot.VendorId = '8086'
    $intelSnapshot.VendorName = 'Intel'
    $intelTarget = Test-BoostLabDriverTarget `
        -ToolId 'mock-driver-tool' `
        -ActionId 'Apply' `
        -ScopeId 'mock-nvidia-driver-scope' `
        -MutationType Update `
        -DeviceState $intelSnapshot `
        -ProvenanceEvidence $provenanceEvidence `
        -RebootWorkflowReference $rebootReference `
        -RelatedStateReferences $relatedReferences `
        -Policy $testPolicy
    if ($intelTarget.IsAllowed) {
        $errors.Add('Intel GPU driver target was not denied.')
    }

    $missingProvenance = Test-BoostLabDriverTarget `
        -ToolId 'mock-driver-tool' `
        -ActionId 'Apply' `
        -ScopeId 'mock-nvidia-driver-scope' `
        -MutationType Update `
        -DeviceState $snapshot `
        -ProvenanceEvidence $null `
        -RebootWorkflowReference $rebootReference `
        -RelatedStateReferences $relatedReferences `
        -Policy $testPolicy
    if ($missingProvenance.IsAllowed) {
        $errors.Add('Driver update without provenance was not denied.')
    }
    $missingReboot = Test-BoostLabDriverTarget `
        -ToolId 'mock-driver-tool' `
        -ActionId 'Apply' `
        -ScopeId 'mock-nvidia-driver-scope' `
        -MutationType Update `
        -DeviceState $snapshot `
        -ProvenanceEvidence $provenanceEvidence `
        -RebootWorkflowReference $null `
        -RelatedStateReferences $relatedReferences `
        -Policy $testPolicy
    if ($missingReboot.IsAllowed) {
        $errors.Add('Reboot-capable driver update without workflow was not denied.')
    }
    $missingRelatedState = Test-BoostLabDriverTarget `
        -ToolId 'mock-driver-tool' `
        -ActionId 'Apply' `
        -ScopeId 'mock-nvidia-driver-scope' `
        -MutationType Update `
        -DeviceState $snapshot `
        -ProvenanceEvidence $provenanceEvidence `
        -RebootWorkflowReference $rebootReference `
        -RelatedStateReferences @() `
        -Policy $testPolicy
    if ($missingRelatedState.IsAllowed) {
        $errors.Add('Driver work without required related state was not denied.')
    }

    $inventory = New-BoostLabDriverInventoryRecord `
        -ToolId 'mock-driver-tool' `
        -ActionId 'Apply' `
        -ScopeId 'mock-nvidia-driver-scope' `
        -IntendedMutation Update `
        -DeviceInstanceId $deviceId `
        -DeviceInspector { param($RequestedId) $snapshot } `
        -ProvenanceEvidence $provenanceEvidence `
        -RebootWorkflowReference $rebootReference `
        -RelatedStateReferences $relatedReferences `
        -RollbackEligible:$true `
        -RiskClassification High `
        -Policy $testPolicy
    if (-not $inventory.Success -or $inventory.Status -ne 'Captured') {
        $errors.Add(
            'Mock driver inventory failed: ' +
            ($inventory.Errors -join '; ')
        )
    }
    $saved = Save-BoostLabDriverStateRecord `
        -Record $inventory.Record `
        -StateRoot $stateRoot
    $imported = Import-BoostLabDriverStateRecord `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot
    if (-not $imported.IsValid) {
        $errors.Add(
            'Saved driver inventory failed integrity validation: ' +
            ($imported.Errors -join '; ')
        )
    }
    $recordValidation = Test-BoostLabDriverStateRecord `
        -Record $imported.Record `
        -ExpectedToolId 'mock-driver-tool' `
        -ExpectedActionId 'Apply' `
        -Policy $testPolicy
    if (-not $recordValidation.IsValid) {
        $errors.Add(
            'Saved driver record was rejected: ' +
            ($recordValidation.Errors -join '; ')
        )
    }

    $actionPlan = [pscustomobject]@{
        ToolId = 'mock-driver-tool'
        Action = 'Apply'
        NeedsExplicitConfirmation = $true
    }
    $unconfirmedPlan = New-BoostLabDriverMutationPlan `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-driver-tool' `
        -ActionId 'Apply' `
        -ActionPlan $actionPlan `
        -Confirmed:$false `
        -Policy $testPolicy
    if ($unconfirmedPlan.IsAllowed) {
        $errors.Add('Driver mutation without confirmation was not denied.')
    }
    $mutationPlan = New-BoostLabDriverMutationPlan `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-driver-tool' `
        -ActionId 'Apply' `
        -ActionPlan $actionPlan `
        -Confirmed:$true `
        -Policy $testPolicy
    if (-not $mutationPlan.IsAllowed -or -not $mutationPlan.IsDryRun) {
        $errors.Add(
            'Valid driver mutation plan was rejected: ' +
            ($mutationPlan.Errors -join '; ')
        )
    }

    $mutationResult = Invoke-BoostLabDriverMutation `
        -Plan $mutationPlan `
        -ActionPlan $actionPlan `
        -Confirmed:$true `
        -MutationExecutor {
            param($Plan)
            [pscustomobject]@{
                Success = $true
                PostMutationState = [pscustomobject]@{
                    DeviceInstanceId = $Plan.DeviceInstanceId
                    DriverVersion = '31.0.15.9999'
                    DriverPackageIdentity = 'nvidia-display-31.0.15.9999'
                }
            }
        } `
        -MutationVerifier {
            param($Plan, $Execution)
            [pscustomobject]@{
                Status = 'Passed'
                Expected = 'Mock updated driver state'
                Actual = $Execution.PostMutationState
                Checks = @()
                Message = 'Mock driver update verified.'
            }
        } `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot `
        -Policy $testPolicy
    if (-not $mutationResult.Success -or $mutationResult.Status -ne 'Passed') {
        $errors.Add(
            'Callback-only driver mutation failed: ' +
            ($mutationResult.Errors -join '; ')
        )
    }

    $postMutationImport = Import-BoostLabDriverStateRecord `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot
    if (
        -not $postMutationImport.IsValid -or
        -not [bool]$postMutationImport.Record.MutationRecorded
    ) {
        $errors.Add('Verified post-mutation state was not persisted.')
    }

    $rollbackPlan = New-BoostLabDriverRollbackPlan `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-driver-tool' `
        -ActionId 'Apply' `
        -DeviceInspector { param($RequestedId) $snapshot } `
        -ActionPlan $actionPlan `
        -Confirmed:$true `
        -Policy $testPolicy
    if (-not $rollbackPlan.IsAllowed -or -not $rollbackPlan.IsDryRun) {
        $errors.Add(
            'Valid driver rollback plan was rejected: ' +
            ($rollbackPlan.Errors -join '; ')
        )
    }
    $rollbackResult = Invoke-BoostLabDriverRollback `
        -Plan $rollbackPlan `
        -ActionPlan $actionPlan `
        -Confirmed:$true `
        -RollbackExecutor {
            param($Plan)
            [pscustomobject]@{
                Success = $true
                PostRollbackState = [pscustomobject]@{
                    DeviceInstanceId = $Plan.DeviceInstanceId
                    DriverPackageIdentity = $Plan.OriginalDriverPackage
                }
            }
        } `
        -RollbackVerifier {
            param($Plan, $Execution)
            [pscustomobject]@{
                Status = 'Passed'
                Expected = $Plan.OriginalDriverPackage
                Actual = $Execution.PostRollbackState.DriverPackageIdentity
                Checks = @()
                Message = 'Mock driver rollback verified.'
            }
        } `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot
    if (-not $rollbackResult.Success -or $rollbackResult.Status -ne 'Passed') {
        $errors.Add(
            'Callback-only driver rollback failed: ' +
            ($rollbackResult.Errors -join '; ')
        )
    }

    $driftPlan = New-BoostLabDriverRollbackPlan `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-driver-tool' `
        -ActionId 'Apply' `
        -DeviceInspector {
            $drift = $snapshot | Select-Object *
            $drift.DeviceInstanceId = 'PCI\VEN_10DE&DEV_DEAD'
            $drift
        } `
        -ActionPlan $actionPlan `
        -Confirmed:$true `
        -Policy $testPolicy
    if ($driftPlan.IsAllowed) {
        $errors.Add('Driver rollback with current identity drift was not denied.')
    }

    $missingRecordPlan = New-BoostLabDriverMutationPlan `
        -RecordPath (Join-Path $stateRoot 'Records\missing.json') `
        -StateRoot $stateRoot `
        -ToolId 'mock-driver-tool' `
        -ActionId 'Apply' `
        -ActionPlan $actionPlan `
        -Confirmed:$true `
        -Policy $testPolicy
    if ($missingRecordPlan.IsAllowed) {
        $errors.Add('Driver mutation without inventory record was not denied.')
    }

    $corruptPath = Join-Path $stateRoot 'Records\corrupt.json'
    Copy-Item -LiteralPath $saved.RecordPath -Destination $corruptPath
    $corruptText = Get-Content -LiteralPath $corruptPath -Raw
    $corruptText = $corruptText.Replace(
        'nvidia-display-31.0.15.1234',
        'tampered-driver-package'
    )
    Set-Content -LiteralPath $corruptPath -Value $corruptText -Encoding UTF8
    $corruptPlan = New-BoostLabDriverMutationPlan `
        -RecordPath $corruptPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-driver-tool' `
        -ActionId 'Apply' `
        -ActionPlan $actionPlan `
        -Confirmed:$true `
        -Policy $testPolicy
    if ($corruptPlan.IsAllowed) {
        $errors.Add('Corrupt driver record was not denied.')
    }

    $staleRecord = $inventory.Record | Select-Object *
    $staleRecord.OperationId = [guid]::NewGuid().ToString()
    $staleRecord.Timestamp = (Get-Date).AddDays(-45).ToUniversalTime().ToString('o')
    $staleSaved = Save-BoostLabDriverStateRecord `
        -Record $staleRecord `
        -StateRoot $stateRoot
    $staleValidation = Test-BoostLabDriverStateRecord `
        -Record (
            Import-BoostLabDriverStateRecord `
                -RecordPath $staleSaved.RecordPath `
                -StateRoot $stateRoot
        ).Record `
        -Policy $testPolicy
    if ($staleValidation.IsValid) {
        $errors.Add('Stale driver state record was not denied.')
    }

    $missingSourceRecord = $postMutationImport.Record | Select-Object *
    $missingSourceRecord.OperationId = [guid]::NewGuid().ToString()
    $missingSourceRecord.SourceStoreLocation = ''
    $missingSourceSaved = Save-BoostLabDriverStateRecord `
        -Record $missingSourceRecord `
        -StateRoot $stateRoot
    $missingSourcePlan = New-BoostLabDriverRollbackPlan `
        -RecordPath $missingSourceSaved.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-driver-tool' `
        -ActionId 'Apply' `
        -DeviceInspector { $snapshot } `
        -ActionPlan $actionPlan `
        -Confirmed:$true `
        -Policy $testPolicy
    if ($missingSourcePlan.IsAllowed) {
        $errors.Add('Rollback without captured source-store information was allowed.')
    }

    foreach ($corePath in @($stateModulePath, $executionModulePath)) {
        $tokens = $null
        $parseErrors = $null
        $ast = [Management.Automation.Language.Parser]::ParseFile(
            $corePath,
            [ref]$tokens,
            [ref]$parseErrors
        )
        if (@($parseErrors).Count -gt 0) {
            $errors.Add(
                "PowerShell parser errors in $corePath`: " +
                (@($parseErrors) -join '; ')
            )
        }
        $commandNames = @(
            $ast.FindAll(
                {
                    param($Node)
                    $Node -is [Management.Automation.Language.CommandAst]
                },
                $true
            ) |
                ForEach-Object { $_.GetCommandName() } |
                Where-Object { $_ }
        )
        foreach ($forbiddenCommand in @(
            'pnputil.exe'
            'dism.exe'
            'devcon.exe'
            'Add-WindowsDriver'
            'Remove-WindowsDriver'
            'Disable-PnpDevice'
            'Enable-PnpDevice'
            'Uninstall-PnpDevice'
            'Update-PnpDevice'
            'Get-PnpDevice'
            'Start-Process'
            'Restart-Computer'
            'Stop-Service'
            'Set-Service'
            'Remove-Item'
            'Set-ItemProperty'
            'New-ItemProperty'
            'Invoke-WebRequest'
            'Invoke-RestMethod'
            'Invoke-Expression'
        )) {
            if ($forbiddenCommand -in $commandNames) {
                $errors.Add(
                    "Phase 41 helper contains forbidden command: $forbiddenCommand"
                )
            }
        }
    }

    $runtimeText = Get-Content -LiteralPath $runtimeExecutionPath -Raw
    if (
        $runtimeText.Contains('DriverState.psm1') -or
        $runtimeText.Contains('DriverExecution.psm1')
    ) {
        $errors.Add('Phase 41 helpers were wired into live tool execution.')
    }

    $config = Import-PowerShellDataFile -LiteralPath $configPath
    $allTools = @($config.Stages | ForEach-Object { $_.Tools })
    $placeholderModules = @(
        Get-ChildItem -Path $modulesRoot -Recurse -Filter '*.psm1' |
            Where-Object {
                (Get-Content -LiteralPath $_.FullName -Raw).Contains(
                    'ToolModule.Placeholder.ps1'
                )
            }
    )
    if ($allTools.Count -ne 54) {
        $errors.Add("Expected 54 active tools, found $($allTools.Count).")
    }
    if ($placeholderModules.Count -ne 18) {
        $errors.Add(
            "Expected 18 placeholder modules, found $($placeholderModules.Count)."
        )
    }
    if (($allTools.Count - $placeholderModules.Count) -ne 36) {
        $errors.Add('Implemented tool count changed from 30.')
    }
    foreach ($deletedTool in @('Loudness EQ', 'NVME Faster Driver')) {
        if ($deletedTool -in @($allTools.Title)) {
            $errors.Add("Deleted tool was reintroduced: $deletedTool")
        }
    }

    $root = (Resolve-Path -LiteralPath $ProjectRoot).Path
    $sourceLines = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
        Sort-Object {
            $_.FullName.Substring($root.Length + 1).Replace('\', '/')
        } |
        ForEach-Object {
            '{0}|{1}' -f `
                $_.FullName.Substring($root.Length + 1).Replace('\', '/'), `
                (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
        }
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $manifestHash = [BitConverter]::ToString(
            $sha256.ComputeHash(
                [Text.Encoding]::UTF8.GetBytes(($sourceLines -join "`n"))
            )
        ).Replace('-', '')
    }
    finally {
        $sha256.Dispose()
    }
    if (
        @($sourceLines).Count -ne 49 -or
        $manifestHash -ne
        '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477'
    ) {
        $errors.Add('source-ultimate content or paths changed.')
    }
}
finally {
    Remove-Module DriverExecution -ErrorAction SilentlyContinue
    Remove-Module DriverState -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}

if ($errors.Count -gt 0) {
    throw "Driver policy validation failed:`r`n- $($errors -join "`r`n- ")"
}

[pscustomobject]@{
    Success                 = $true
    ProductionScopeCount    = 0
    MockInventoryValidated  = $true
    MockMutationValidated   = $true
    MockRollbackValidated   = $true
    RealDriverOperationRun  = $false
    ActiveToolCount         = 54
    ImplementedToolCount    = 36
    PlaceholderToolCount    = 18
    SourceUltimateUnchanged = $true
    Message                 = 'Driver state and rollback foundation is deny-by-default and callback-only.'
    Timestamp               = Get-Date
}



