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
        throw 'Unable to determine the TrustedInstaller policy test path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$policyPath = Join-Path $ProjectRoot 'config\TrustedInstallerPolicy.psd1'
$policyModulePath = Join-Path $ProjectRoot 'core\TrustedInstaller.psm1'
$executionModulePath = Join-Path $ProjectRoot 'core\TrustedInstallerExecution.psm1'
$policyDocPath = Join-Path $ProjectRoot 'docs\trusted-installer-execution.md'
$runtimeExecutionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$errors = [System.Collections.Generic.List[string]]::new()
foreach ($requiredPath in @(
    $policyPath
    $policyModulePath
    $executionModulePath
    $policyDocPath
)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        $errors.Add("Required Phase 42 file is missing: $requiredPath")
    }
}
if ($errors.Count -gt 0) {
    throw "TrustedInstaller validation failed:`r`n- $($errors -join "`r`n- ")"
}

Import-Module `
    -Name $policyModulePath `
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
    ("BoostLab-TrustedInstallerTest-{0}" -f [guid]::NewGuid())
$helperPath = Join-Path $tempRoot 'mock-helper.exe'
$targetPath = Join-Path $tempRoot 'mock-target.dat'
$statePath = Join-Path $tempRoot 'mock-state.json'
[IO.Directory]::CreateDirectory($tempRoot) | Out-Null
[IO.File]::WriteAllText($helperPath, 'local mocked helper metadata')
[IO.File]::WriteAllText($targetPath, 'local mocked target')
[IO.File]::WriteAllText($statePath, '{"verified":true}')

try {
    foreach ($commandName in @(
        'Get-BoostLabTrustedInstallerPolicy'
        'Test-BoostLabTrustedInstallerSupported'
        'Test-BoostLabTrustedInstallerPolicy'
        'Test-BoostLabTrustedInstallerVerificationPlan'
        'Test-BoostLabTrustedInstallerRequest'
        'New-BoostLabTrustedInstallerRequest'
        'New-BoostLabTrustedInstallerPlan'
        'Invoke-BoostLabTrustedInstallerCommand'
        'Test-BoostLabTrustedInstallerExecutionRequest'
        'Test-BoostLabTrustedInstallerMockResult'
        'Invoke-BoostLabTrustedInstallerRequest'
    )) {
        if (-not (Get-Command -Name $commandName -ErrorAction SilentlyContinue)) {
            $errors.Add("Phase 42 helper is not exported: $commandName")
        }
    }

    $productionPolicy = Get-BoostLabTrustedInstallerPolicy `
        -PolicyPath $policyPath
    $productionValidation = Test-BoostLabTrustedInstallerPolicy `
        -Policy $productionPolicy
    if (-not $productionValidation.IsValid) {
        $errors.Add(
            'Production TrustedInstaller policy is invalid: ' +
            ($productionValidation.Errors -join '; ')
        )
    }
    if ($productionValidation.ScopeCount -ne 0) {
        $errors.Add('Phase 42 must not approve production scopes.')
    }

    $testPolicy = @{
        SchemaVersion = '1.0'
        MaxRequestAgeMinutes = 30
        RequestedIdentity = 'NT SERVICE\TrustedInstaller'
        TrustedInstallerScopes = @(
            @{
                ScopeId = 'mock-ti-scope'
                ToolIds = @('mock-ti-tool')
                ActionIds = @('Apply')
                RequestedIdentity = 'NT SERVICE\TrustedInstaller'
                Commands = @(
                    @{
                        CommandId = 'mock-operation'
                        AllowedExecutablePaths = @($helperPath)
                        AllowedHelperIds = @()
                        AllowedArguments = @(
                            @{
                                Name = 'Mode'
                                Value = 'Mock'
                            }
                        )
                        AllowedWorkingDirectories = @($tempRoot)
                    }
                )
                AllowedTargetFiles = @($targetPath)
                AllowedRegistryPaths = @(
                    'HKCU:\Software\BoostLab\Phase42Mock'
                )
                AllowedServiceNames = @('MockService')
                AllowedPackageIdentities = @('Mock.Package')
                RequiredFoundations = @(
                    'Rollback'
                    'ServiceRollback'
                )
                RequiresActionPlanConfirmation = $true
                RequiresAdministratorHost = $true
                RequiresStateCapture = $true
                RequiresVerificationPlan = $true
                AllowProtectedTargets = $false
                RiskClassification = 'High'
                TimeoutSeconds = 30
                LoggingRequirements = @(
                    'Identity'
                    'CommandId'
                    'Targets'
                    'Result'
                )
                AllowCancellation = $true
                RecoveryBehavior = 'Return a structured refusal and preserve state references.'
            }
        )
        BlockedExternalElevationTools = @(
            'advancedrun.exe'
            'nsudo.exe'
            'psexec.exe'
            'powerrun.exe'
        )
        ProtectedRegistryPrefixes = @(
            'HKLM:\SAM'
            'HKLM:\SECURITY'
            'HKLM:\SYSTEM'
        )
        ProtectedServiceNames = @(
            'TrustedInstaller'
            'WinDefend'
        )
        ProtectedPackagePrefixes = @(
            'Microsoft.WindowsStore'
        )
    }
    $testValidation = Test-BoostLabTrustedInstallerPolicy -Policy $testPolicy
    if (-not $testValidation.IsValid -or $testValidation.ScopeCount -ne 1) {
        $errors.Add(
            'Mock TrustedInstaller policy was rejected: ' +
            ($testValidation.Errors -join '; ')
        )
    }

    $actionPlan = [pscustomobject]@{
        ToolId = 'mock-ti-tool'
        Action = 'Apply'
        NeedsExplicitConfirmation = $true
        UsesTrustedInstaller = $true
    }
    $commandDescriptor = [pscustomobject]@{
        ExecutablePath = $helperPath
        HelperId = ''
        Arguments = @(
            [pscustomobject]@{
                Name = 'Mode'
                Value = 'Mock'
            }
        )
    }
    $targets = [pscustomobject]@{
        Files = @($targetPath)
        RegistryPaths = @('HKCU:\Software\BoostLab\Phase42Mock')
        Services = @('MockService')
        Packages = @('Mock.Package')
    }
    $stateReferences = @(
        [pscustomobject]@{
            Foundation = 'Rollback'
            ReferenceId = 'mock-file-registry-state'
            RecordPath = $statePath
            RecordHash = (
                Get-FileHash -LiteralPath $statePath -Algorithm SHA256
            ).Hash
            Verified = $true
        }
        [pscustomobject]@{
            Foundation = 'ServiceRollback'
            ReferenceId = 'mock-service-state'
            RecordPath = $statePath
            RecordHash = (
                Get-FileHash -LiteralPath $statePath -Algorithm SHA256
            ).Hash
            Verified = $true
        }
    )
    $verificationPlan = [pscustomobject]@{
        Checks = @(
            [pscustomobject]@{
                Name = 'MockTarget'
                MethodId = 'mock-read'
                TargetReference = 'mock-target.dat'
                Expected = 'Present'
            }
        )
    }

    $validRequest = New-BoostLabTrustedInstallerRequest `
        -ToolId 'mock-ti-tool' `
        -ActionId 'Apply' `
        -ScopeId 'mock-ti-scope' `
        -CommandId 'mock-operation' `
        -CommandDescriptor $commandDescriptor `
        -WorkingDirectory $tempRoot `
        -Targets $targets `
        -ActionPlan $actionPlan `
        -Confirmed:$true `
        -AdministratorHostVerified:$true `
        -StateCaptureReferences $stateReferences `
        -VerificationPlan $verificationPlan `
        -IsTestRequest:$true `
        -Policy $testPolicy
    if (-not $validRequest.Success -or $validRequest.Status -ne 'Allowed') {
        $errors.Add(
            'Structurally approved mocked request was rejected: ' +
            ($validRequest.Errors -join '; ')
        )
    }

    $unknownTool = New-BoostLabTrustedInstallerRequest `
        -ToolId 'unknown-tool' `
        -ActionId 'Apply' `
        -ScopeId 'mock-ti-scope' `
        -CommandId 'mock-operation' `
        -CommandDescriptor $commandDescriptor `
        -WorkingDirectory $tempRoot `
        -Targets $targets `
        -ActionPlan $actionPlan `
        -Confirmed:$true `
        -AdministratorHostVerified:$true `
        -StateCaptureReferences $stateReferences `
        -VerificationPlan $verificationPlan `
        -Policy $testPolicy
    if ($unknownTool.Success) {
        $errors.Add('Unknown TrustedInstaller tool was not denied.')
    }

    $unknownActionPlan = $actionPlan | Select-Object *
    $unknownActionPlan.Action = 'UnknownAction'
    $unknownAction = New-BoostLabTrustedInstallerRequest `
        -ToolId 'mock-ti-tool' `
        -ActionId 'UnknownAction' `
        -ScopeId 'mock-ti-scope' `
        -CommandId 'mock-operation' `
        -CommandDescriptor $commandDescriptor `
        -WorkingDirectory $tempRoot `
        -Targets $targets `
        -ActionPlan $unknownActionPlan `
        -Confirmed:$true `
        -AdministratorHostVerified:$true `
        -StateCaptureReferences $stateReferences `
        -VerificationPlan $verificationPlan `
        -Policy $testPolicy
    if ($unknownAction.Success) {
        $errors.Add('Unknown TrustedInstaller action was not denied.')
    }

    $unknownCommand = New-BoostLabTrustedInstallerRequest `
        -ToolId 'mock-ti-tool' `
        -ActionId 'Apply' `
        -ScopeId 'mock-ti-scope' `
        -CommandId 'unknown-command' `
        -CommandDescriptor $commandDescriptor `
        -WorkingDirectory $tempRoot `
        -Targets $targets `
        -ActionPlan $actionPlan `
        -Confirmed:$true `
        -AdministratorHostVerified:$true `
        -StateCaptureReferences $stateReferences `
        -VerificationPlan $verificationPlan `
        -Policy $testPolicy
    if ($unknownCommand.Success) {
        $errors.Add('Unknown TrustedInstaller command id was not denied.')
    }

    $rawDescriptor = $commandDescriptor | Select-Object *
    Add-Member `
        -InputObject $rawDescriptor `
        -NotePropertyName CommandLine `
        -NotePropertyValue 'mock-helper.exe --unsafe'
    $rawRequest = New-BoostLabTrustedInstallerRequest `
        -ToolId 'mock-ti-tool' `
        -ActionId 'Apply' `
        -ScopeId 'mock-ti-scope' `
        -CommandId 'mock-operation' `
        -CommandDescriptor $rawDescriptor `
        -WorkingDirectory $tempRoot `
        -Targets $targets `
        -ActionPlan $actionPlan `
        -Confirmed:$true `
        -AdministratorHostVerified:$true `
        -StateCaptureReferences $stateReferences `
        -VerificationPlan $verificationPlan `
        -Policy $testPolicy
    if ($rawRequest.Success) {
        $errors.Add('Raw TrustedInstaller command string was not denied.')
    }

    foreach ($case in @(
        @{
            Name = 'missing confirmation'
            Confirmed = $false
            Administrator = $true
            References = $stateReferences
            Verification = $verificationPlan
        }
        @{
            Name = 'missing Administrator host'
            Confirmed = $true
            Administrator = $false
            References = $stateReferences
            Verification = $verificationPlan
        }
        @{
            Name = 'missing state references'
            Confirmed = $true
            Administrator = $true
            References = @()
            Verification = $verificationPlan
        }
        @{
            Name = 'missing verification plan'
            Confirmed = $true
            Administrator = $true
            References = $stateReferences
            Verification = $null
        }
    )) {
        $blocked = New-BoostLabTrustedInstallerRequest `
            -ToolId 'mock-ti-tool' `
            -ActionId 'Apply' `
            -ScopeId 'mock-ti-scope' `
            -CommandId 'mock-operation' `
            -CommandDescriptor $commandDescriptor `
            -WorkingDirectory $tempRoot `
            -Targets $targets `
            -ActionPlan $actionPlan `
            -Confirmed:$case.Confirmed `
            -AdministratorHostVerified:$case.Administrator `
            -StateCaptureReferences $case.References `
            -VerificationPlan $case.Verification `
            -Policy $testPolicy
        if ($blocked.Success) {
            $errors.Add("TrustedInstaller $($case.Name) was not denied.")
        }
    }

    $networkDescriptor = [pscustomobject]@{
        ExecutablePath = '\\server\share\mock-helper.exe'
        HelperId = ''
        Arguments = $commandDescriptor.Arguments
    }
    $networkRequest = New-BoostLabTrustedInstallerRequest `
        -ToolId 'mock-ti-tool' `
        -ActionId 'Apply' `
        -ScopeId 'mock-ti-scope' `
        -CommandId 'mock-operation' `
        -CommandDescriptor $networkDescriptor `
        -WorkingDirectory $tempRoot `
        -Targets $targets `
        -ActionPlan $actionPlan `
        -Confirmed:$true `
        -AdministratorHostVerified:$true `
        -StateCaptureReferences $stateReferences `
        -VerificationPlan $verificationPlan `
        -Policy $testPolicy
    if ($networkRequest.Success) {
        $errors.Add('Network executable path was not denied.')
    }

    $externalPolicy = $testPolicy.Clone()
    $externalScope = @{} + $testPolicy.TrustedInstallerScopes[0]
    $externalCommand = @{} + $externalScope.Commands[0]
    $externalPath = Join-Path $tempRoot 'psexec.exe'
    [IO.File]::WriteAllText($externalPath, 'mock external elevation binary')
    $externalCommand['AllowedExecutablePaths'] = @($externalPath)
    $externalScope['Commands'] = @($externalCommand)
    $externalPolicy['TrustedInstallerScopes'] = @($externalScope)
    if ((Test-BoostLabTrustedInstallerPolicy -Policy $externalPolicy).IsValid) {
        $errors.Add('External elevation binary was not denied by policy.')
    }

    $broadPolicy = $testPolicy.Clone()
    $broadScope = @{} + $testPolicy.TrustedInstallerScopes[0]
    $driveRoot = [IO.Path]::GetPathRoot($tempRoot)
    $broadScope['AllowedTargetFiles'] = @($driveRoot)
    $broadPolicy['TrustedInstallerScopes'] = @($broadScope)
    $broadTargets = [pscustomobject]@{
        Files = @($driveRoot)
        RegistryPaths = @()
        Services = @()
        Packages = @()
    }
    $broadRequest = New-BoostLabTrustedInstallerRequest `
        -ToolId 'mock-ti-tool' `
        -ActionId 'Apply' `
        -ScopeId 'mock-ti-scope' `
        -CommandId 'mock-operation' `
        -CommandDescriptor $commandDescriptor `
        -WorkingDirectory $tempRoot `
        -Targets $broadTargets `
        -ActionPlan $actionPlan `
        -Confirmed:$true `
        -AdministratorHostVerified:$true `
        -StateCaptureReferences $stateReferences `
        -VerificationPlan $verificationPlan `
        -Policy $broadPolicy
    if ($broadRequest.Success) {
        $errors.Add('Broad drive-root target was not denied.')
    }

    $protectedPolicy = $testPolicy.Clone()
    $protectedScope = @{} + $testPolicy.TrustedInstallerScopes[0]
    $protectedScope['AllowedRegistryPaths'] = @('HKLM:\SYSTEM\BoostLabMock')
    $protectedPolicy['TrustedInstallerScopes'] = @($protectedScope)
    $protectedTargets = [pscustomobject]@{
        Files = @()
        RegistryPaths = @('HKLM:\SYSTEM\BoostLabMock')
        Services = @()
        Packages = @()
    }
    $protectedRequest = New-BoostLabTrustedInstallerRequest `
        -ToolId 'mock-ti-tool' `
        -ActionId 'Apply' `
        -ScopeId 'mock-ti-scope' `
        -CommandId 'mock-operation' `
        -CommandDescriptor $commandDescriptor `
        -WorkingDirectory $tempRoot `
        -Targets $protectedTargets `
        -ActionPlan $actionPlan `
        -Confirmed:$true `
        -AdministratorHostVerified:$true `
        -StateCaptureReferences $stateReferences `
        -VerificationPlan $verificationPlan `
        -Policy $protectedPolicy
    if ($protectedRequest.Success) {
        $errors.Add('Protected registry target was not denied.')
    }

    $productionRequest = New-BoostLabTrustedInstallerRequest `
        -ToolId 'mock-ti-tool' `
        -ActionId 'Apply' `
        -ScopeId 'mock-ti-scope' `
        -CommandId 'mock-operation' `
        -CommandDescriptor $commandDescriptor `
        -WorkingDirectory $tempRoot `
        -Targets $targets `
        -ActionPlan $actionPlan `
        -Confirmed:$true `
        -AdministratorHostVerified:$true `
        -StateCaptureReferences $stateReferences `
        -VerificationPlan $verificationPlan `
        -Policy $productionPolicy
    if ($productionRequest.Success) {
        $errors.Add('Empty production scopes did not deny execution.')
    }

    $executionResult = Invoke-BoostLabTrustedInstallerRequest `
        -Request $validRequest.Request `
        -ActionPlan $actionPlan `
        -Confirmed:$true `
        -AdministratorHostVerified:$true `
        -Policy $testPolicy
    if (
        $executionResult.Success -or
        $executionResult.Status -ne 'NotImplemented' -or
        $executionResult.ProcessStarted -or
        $executionResult.CommandExecuted
    ) {
        $errors.Add(
            'TrustedInstaller execution helper was not inert NotImplemented.'
        )
    }
    if (
        @($executionResult.LogEntries).Count -eq 0 -or
        [string]$executionResult.LogEntries[0].Identity -ne
            'NT SERVICE\TrustedInstaller' -or
        [string]$executionResult.LogEntries[0].CommandId -ne 'mock-operation'
    ) {
        $errors.Add('TrustedInstaller refusal log is incomplete.')
    }

    $mockValidation = Test-BoostLabTrustedInstallerMockResult `
        -ExecutionResult ([pscustomobject]@{
            Simulated = $true
            ProcessStarted = $false
            CommandExecuted = $false
            CommandId = 'mock-operation'
            Status = 'Passed'
        }) `
        -Request $validRequest.Request
    if (-not $mockValidation.IsValid) {
        $errors.Add(
            'Local mocked result could not be validated structurally: ' +
            ($mockValidation.Errors -join '; ')
        )
    }

    foreach ($corePath in @($policyModulePath, $executionModulePath)) {
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
            'Start-Process'
            'Start-Service'
            'Stop-Service'
            'Set-Service'
            'Restart-Service'
            'New-Service'
            'Remove-Service'
            'sc.exe'
            'schtasks.exe'
            'Register-ScheduledTask'
            'New-ScheduledTask'
            'Set-Acl'
            'takeown.exe'
            'icacls.exe'
            'Set-ItemProperty'
            'New-ItemProperty'
            'Remove-ItemProperty'
            'Remove-Item'
            'Copy-Item'
            'Move-Item'
            'Invoke-WebRequest'
            'Invoke-RestMethod'
            'Invoke-Expression'
            'psexec.exe'
            'nsudo.exe'
            'powerrun.exe'
            'advancedrun.exe'
        )) {
            if ($forbiddenCommand -in $commandNames) {
                $errors.Add(
                    "Phase 42 helper contains forbidden command: " +
                    $forbiddenCommand
                )
            }
        }
    }

    $runtimeText = Get-Content -LiteralPath $runtimeExecutionPath -Raw
    if (
        $runtimeText.Contains('TrustedInstallerExecution.psm1') -or
        $runtimeText.Contains('Invoke-BoostLabTrustedInstallerRequest')
    ) {
        $errors.Add('Phase 42 execution helper was wired into live tool runtime.')
    }

    $configuration = Import-PowerShellDataFile -LiteralPath $configPath
    $allTools = @($configuration.Stages | ForEach-Object { $_.Tools })
    $placeholderModules = @(
        Get-ChildItem -Path $modulesRoot -Recurse -Filter '*.psm1' |
            Where-Object {
                (Get-Content -LiteralPath $_.FullName -Raw).Contains(
                    'ToolModule.Placeholder.ps1'
                )
            }
    )
    if ($allTools.Count -ne 48) {
        $errors.Add("Expected 48 active tools, found $($allTools.Count).")
    }
    if ($placeholderModules.Count -ne 18) {
        $errors.Add(
            "Expected 18 placeholder modules, found $($placeholderModules.Count)."
        )
    }
    if (($allTools.Count - $placeholderModules.Count) -ne 30) {
        $errors.Add('Implemented tool count changed from 30.')
    }
    foreach ($deletedTool in @('Loudness EQ', 'NVME Faster Driver')) {
        if ($deletedTool -in @($allTools.Title)) {
            $errors.Add("Deleted tool was reintroduced: $deletedTool")
        }
    }

    $root = (Resolve-Path -LiteralPath $ProjectRoot).Path
    $sourceLines = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
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
    Remove-Module TrustedInstallerExecution -ErrorAction SilentlyContinue
    Remove-Module TrustedInstaller -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}

if ($errors.Count -gt 0) {
    throw "TrustedInstaller validation failed:`r`n- $($errors -join "`r`n- ")"
}

[pscustomobject]@{
    Success                    = $true
    ProductionScopeCount       = 0
    MockRequestValidated       = $true
    MockResultValidated        = $true
    ProcessStarted             = $false
    CommandExecuted            = $false
    ActiveToolCount            = 48
    ImplementedToolCount       = 30
    PlaceholderToolCount       = 18
    SourceUltimateUnchanged    = $true
    Message                    = 'TrustedInstaller foundation is deny-by-default and non-executing.'
    Timestamp                  = Get-Date
}
