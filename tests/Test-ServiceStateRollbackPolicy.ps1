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
        throw 'Unable to determine the service rollback policy test path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$policyPath = Join-Path $ProjectRoot 'config\ServiceRollbackPolicy.psd1'
$stateModulePath = Join-Path $ProjectRoot 'core\ServiceState.psm1'
$rollbackModulePath = Join-Path $ProjectRoot 'core\ServiceRollback.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$policyDocPath = Join-Path $ProjectRoot 'docs\service-state-capture-rollback.md'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$errors = [System.Collections.Generic.List[string]]::new()
foreach ($requiredPath in @(
    $policyPath
    $stateModulePath
    $rollbackModulePath
    $policyDocPath
)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        $errors.Add("Required Phase 37 file is missing: $requiredPath")
    }
}
if ($errors.Count -gt 0) {
    throw "Service rollback policy validation failed:`r`n- $($errors -join "`r`n- ")"
}

$stateModule = Import-Module `
    -Name $stateModulePath `
    -Force `
    -PassThru `
    -Scope Local `
    -ErrorAction Stop
$rollbackModule = Import-Module `
    -Name $rollbackModulePath `
    -Force `
    -PassThru `
    -Scope Local `
    -ErrorAction Stop

$tempRoot = Join-Path `
    ([IO.Path]::GetTempPath()) `
    ("BoostLab-ServiceRollbackTest-{0}" -f [guid]::NewGuid())
$stateRoot = Join-Path $tempRoot 'State'
[IO.Directory]::CreateDirectory($stateRoot) | Out-Null

try {
    foreach ($commandName in @(
        'Get-BoostLabServiceRollbackPolicy'
        'Get-BoostLabServiceRollbackStateRoot'
        'Test-BoostLabServiceRollbackPolicy'
        'Test-BoostLabServiceCaptureTarget'
        'Test-BoostLabServiceRollbackRecord'
        'Save-BoostLabServiceRollbackRecord'
        'Import-BoostLabServiceRollbackRecord'
        'New-BoostLabServiceStateCapture'
        'Set-BoostLabServiceRollbackMutationState'
        'Test-BoostLabServiceState'
        'Invoke-BoostLabServiceRollback'
    )) {
        if (-not (Get-Command -Name $commandName -ErrorAction SilentlyContinue)) {
            $errors.Add("Phase 37 helper is not exported: $commandName")
        }
    }

    $productionPolicy = Get-BoostLabServiceRollbackPolicy -PolicyPath $policyPath
    $productionValidation = Test-BoostLabServiceRollbackPolicy -Policy $productionPolicy
    if (-not $productionValidation.IsValid) {
        $errors.Add(
            "Production service rollback policy is invalid: " +
            ($productionValidation.Errors -join '; ')
        )
    }
    if ($productionValidation.ServiceScopeCount -ne 0) {
        $errors.Add('Phase 37 must not approve production service scopes.')
    }

    $mockServiceName = 'BoostLabMockService'
    $testPolicy = @{
        SchemaVersion = '1.0'
        MaxRecordAgeDays = 30
        ServiceScopes = @(
            @{
                ScopeId                = 'local-mock-service'
                ToolIds               = @('mock-tool')
                ServiceNames           = @($mockServiceName)
                AllowedMutations       = @(
                    'Start'
                    'Stop'
                    'Disable'
                    'Enable'
                    'SetStartupType'
                )
                AllowProtectedServices = $false
                AllowCreateService     = $false
                AllowDeleteService     = $false
                AllowRecreateMissingService = $false
                RestoreStartupType     = $true
                RestoreDelayedAutoStart = $true
                RestoreStatus          = $true
            }
        )
        ProtectedServiceNames = @('RpcSs', 'DcomLaunch')
    }
    $testPolicyValidation = Test-BoostLabServiceRollbackPolicy -Policy $testPolicy
    if (
        -not $testPolicyValidation.IsValid -or
        $testPolicyValidation.ServiceScopeCount -ne 1
    ) {
        $errors.Add(
            "Local mock service policy was rejected: " +
            ($testPolicyValidation.Errors -join '; ')
        )
    }

    $unknownScope = Test-BoostLabServiceCaptureTarget `
        -ToolId 'mock-tool' `
        -ScopeId 'not-approved' `
        -ServiceName $mockServiceName `
        -IntendedMutation Disable `
        -Policy $testPolicy
    if ($unknownScope.IsAllowed -or $unknownScope.Status -ne 'Blocked') {
        $errors.Add('Service capture without an approved scope was not denied.')
    }

    $unknownService = Test-BoostLabServiceCaptureTarget `
        -ToolId 'mock-tool' `
        -ScopeId 'local-mock-service' `
        -ServiceName 'UnknownMockService' `
        -IntendedMutation Disable `
        -Policy $testPolicy
    if ($unknownService.IsAllowed -or $unknownService.Status -ne 'Blocked') {
        $errors.Add('Unknown service name was not denied.')
    }

    $wildcardService = Test-BoostLabServiceCaptureTarget `
        -ToolId 'mock-tool' `
        -ScopeId 'local-mock-service' `
        -ServiceName '*' `
        -IntendedMutation Disable `
        -Policy $testPolicy
    if ($wildcardService.IsAllowed -or $wildcardService.Status -ne 'Blocked') {
        $errors.Add('Wildcard service name was not denied.')
    }

    $broadPolicy = @{
        SchemaVersion = '1.0'
        MaxRecordAgeDays = 30
        ServiceScopes = @(
            @{
                ScopeId                = 'broad-service-scope'
                ToolIds               = @('mock-tool')
                ServiceNames           = @('*')
                AllowedMutations       = @('Stop')
                AllowProtectedServices = $false
                AllowCreateService     = $false
                AllowDeleteService     = $false
                AllowRecreateMissingService = $false
                RestoreStartupType     = $true
                RestoreDelayedAutoStart = $true
                RestoreStatus          = $true
            }
        )
        ProtectedServiceNames = @('RpcSs')
    }
    $broadValidation = Test-BoostLabServiceRollbackPolicy -Policy $broadPolicy
    if ($broadValidation.IsValid) {
        $errors.Add('Broad wildcard service scope was not denied.')
    }

    $protectedPolicy = @{
        SchemaVersion = '1.0'
        MaxRecordAgeDays = 30
        ServiceScopes = @(
            @{
                ScopeId                = 'protected-service-scope'
                ToolIds               = @('mock-tool')
                ServiceNames           = @('RpcSs')
                AllowedMutations       = @('Stop')
                AllowProtectedServices = $false
                AllowCreateService     = $false
                AllowDeleteService     = $false
                AllowRecreateMissingService = $false
                RestoreStartupType     = $true
                RestoreDelayedAutoStart = $true
                RestoreStatus          = $true
            }
        )
        ProtectedServiceNames = @('RpcSs')
    }
    $protectedTarget = Test-BoostLabServiceCaptureTarget `
        -ToolId 'mock-tool' `
        -ScopeId 'protected-service-scope' `
        -ServiceName 'RpcSs' `
        -IntendedMutation Stop `
        -Policy $protectedPolicy
    if ($protectedTarget.IsAllowed -or $protectedTarget.Status -ne 'Blocked') {
        $errors.Add('Protected/core Windows service was not denied by default.')
    }

    $deletePolicy = @{
        SchemaVersion = '1.0'
        MaxRecordAgeDays = 30
        ServiceScopes = @(
            @{
                ScopeId                = 'delete-denied'
                ToolIds               = @('mock-tool')
                ServiceNames           = @($mockServiceName)
                AllowedMutations       = @('Delete', 'Create')
                AllowProtectedServices = $false
                AllowCreateService     = $false
                AllowDeleteService     = $false
                AllowRecreateMissingService = $false
                RestoreStartupType     = $true
                RestoreDelayedAutoStart = $true
                RestoreStatus          = $true
            }
        )
        ProtectedServiceNames = @('RpcSs')
    }
    foreach ($mutation in @('Create', 'Delete')) {
        $target = Test-BoostLabServiceCaptureTarget `
            -ToolId 'mock-tool' `
            -ScopeId 'delete-denied' `
            -ServiceName $mockServiceName `
            -IntendedMutation $mutation `
            -Policy $deletePolicy
        if ($target.IsAllowed -or $target.Status -ne 'Blocked') {
            $errors.Add("Service $mutation was not denied by default.")
        }
    }

    $serviceStore = [ordered]@{
        Exists           = $true
        ServiceName      = $mockServiceName
        DisplayName      = 'BoostLab Mock Service'
        Status           = 'Running'
        StartupType      = 'Automatic'
        DelayedAutoStart = $true
        BinaryPath       = 'C:\BoostLabTests\MockService.exe'
        ServiceAccount   = 'LocalSystem'
        Dependencies     = @('RpcSs')
        Description      = 'Local in-memory service test data.'
        FailureActions   = [ordered]@{
            ResetPeriodSeconds = 60
            Actions            = @('Restart')
        }
    }
    $serviceReader = {
        param([string]$ServiceName)

        return [pscustomobject]$serviceStore
    }.GetNewClosure()
    $serviceMutator = {
        param($MutationPlan)

        foreach ($operation in @($MutationPlan.Operations)) {
            switch ($operation.Operation) {
                'SetStartupType' {
                    $serviceStore.StartupType = [string]$operation.Value
                }
                'SetDelayedAutoStart' {
                    $serviceStore.DelayedAutoStart = [bool]$operation.Value
                }
                'Start' {
                    $serviceStore.Status = 'Running'
                }
                'Stop' {
                    $serviceStore.Status = 'Stopped'
                }
                default {
                    throw "Unexpected mocked service operation: $($operation.Operation)"
                }
            }
        }

        return [pscustomobject]@{
            Success = $true
            Status  = 'Completed'
        }
    }.GetNewClosure()

    $capture = New-BoostLabServiceStateCapture `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -ScopeId 'local-mock-service' `
        -ServiceName $mockServiceName `
        -IntendedMutation Disable `
        -ServiceReader $serviceReader `
        -RiskClassification High `
        -Policy $testPolicy `
        -StateRoot $stateRoot
    if (
        -not $capture.Success -or
        $capture.Status -ne 'Captured' -or
        -not (Test-Path -LiteralPath $capture.RecordPath -PathType Leaf)
    ) {
        $errors.Add("Mocked service state capture failed: $($capture.Errors -join '; ')")
    }
    foreach ($requiredField in @(
        'OperationId'
        'ToolId'
        'ActionId'
        'Timestamp'
        'SchemaVersion'
        'BoostLabVersion'
        'ServiceName'
        'DisplayName'
        'OriginalExists'
        'OriginalStatus'
        'OriginalStartupType'
        'OriginalDelayedAutoStart'
        'OriginalBinaryPath'
        'OriginalServiceAccount'
        'OriginalDependencies'
        'OriginalDescription'
        'OriginalFailureActions'
        'IntendedMutation'
        'RollbackEligible'
        'VerificationRequirement'
        'RiskClassification'
    )) {
        if ($null -eq $capture.Record.PSObject.Properties[$requiredField]) {
            $errors.Add("Service rollback record is missing field: $requiredField")
        }
    }
    if (
        $capture.Record.OriginalStatus -ne 'Running' -or
        $capture.Record.OriginalStartupType -ne 'Automatic' -or
        $capture.Record.OriginalDelayedAutoStart -ne $true -or
        -not $capture.Record.RollbackEligible
    ) {
        $errors.Add('Service capture did not preserve the original rollback state.')
    }

    $originalVerification = Test-BoostLabServiceState `
        -ServiceName $mockServiceName `
        -ExpectedState ([pscustomobject]$serviceStore) `
        -ServiceReader $serviceReader
    if (
        $originalVerification.Status -ne 'Passed' -or
        @($originalVerification.Checks).Count -lt 10
    ) {
        $errors.Add('Read-only service verification did not pass for matching mock state.')
    }

    $optionalReader = {
        param([string]$ServiceName)

        $snapshot = [ordered]@{}
        foreach ($key in $serviceStore.Keys) {
            if ($key -ne 'DelayedAutoStart') {
                $snapshot[$key] = $serviceStore[$key]
            }
        }
        return [pscustomobject]$snapshot
    }.GetNewClosure()
    $optionalVerification = Test-BoostLabServiceState `
        -ServiceName $mockServiceName `
        -ExpectedState ([pscustomobject]$serviceStore) `
        -ServiceReader $optionalReader
    if ($optionalVerification.Status -ne 'Warning') {
        $errors.Add('Unavailable delayed auto-start state did not produce a verification warning.')
    }

    $missingRecord = Invoke-BoostLabServiceRollback `
        -RecordPath (Join-Path $stateRoot 'Records\missing.service.json') `
        -StateRoot $stateRoot `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -ServiceReader $serviceReader `
        -ServiceMutator $serviceMutator `
        -Policy $testPolicy
    if (
        $missingRecord.Success -or
        $missingRecord.Status -ne 'Blocked' -or
        $missingRecord.RestoreAttempted
    ) {
        $errors.Add('Missing service rollback record was not denied.')
    }

    $corruptRecordPath = Join-Path $stateRoot 'Records\corrupt.service.json'
    [IO.Directory]::CreateDirectory((Split-Path -Parent $corruptRecordPath)) | Out-Null
    [IO.File]::WriteAllText($corruptRecordPath, '{not-json', [Text.Encoding]::UTF8)
    $corruptRecord = Import-BoostLabServiceRollbackRecord `
        -RecordPath $corruptRecordPath `
        -StateRoot $stateRoot
    if ($corruptRecord.IsValid -or $corruptRecord.Status -ne 'Blocked') {
        $errors.Add('Corrupt service rollback record was not denied.')
    }

    $serviceStore.Status = 'Stopped'
    $serviceStore.StartupType = 'Disabled'
    $serviceStore.DelayedAutoStart = $false
    $mutationRecorded = Set-BoostLabServiceRollbackMutationState `
        -RecordPath $capture.RecordPath `
        -StateRoot $stateRoot `
        -PostMutationState ([pscustomobject]$serviceStore)
    if (-not $mutationRecorded.Success) {
        $errors.Add(
            "Service post-mutation state was not recorded: " +
            ($mutationRecorded.Errors -join '; ')
        )
    }

    $wrongTool = Invoke-BoostLabServiceRollback `
        -RecordPath $capture.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'wrong-tool' `
        -ActionId 'Apply' `
        -ServiceReader $serviceReader `
        -ServiceMutator $serviceMutator `
        -Policy $testPolicy
    if (
        $wrongTool.Success -or
        $wrongTool.Status -ne 'Blocked' -or
        $wrongTool.RestoreAttempted
    ) {
        $errors.Add('Mismatched service rollback tool identity was not denied.')
    }

    $serviceStore.BinaryPath = 'C:\BoostLabTests\DifferentService.exe'
    $identityMismatch = Invoke-BoostLabServiceRollback `
        -RecordPath $capture.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -ServiceReader $serviceReader `
        -ServiceMutator $serviceMutator `
        -Policy $testPolicy
    if (
        $identityMismatch.Success -or
        $identityMismatch.Status -ne 'Blocked' -or
        $identityMismatch.RestoreAttempted
    ) {
        $errors.Add('Changed service identity did not block rollback.')
    }
    $serviceStore.BinaryPath = 'C:\BoostLabTests\MockService.exe'

    $staleImported = Import-BoostLabServiceRollbackRecord `
        -RecordPath $capture.RecordPath `
        -StateRoot $stateRoot
    $staleRecord = [ordered]@{}
    foreach ($property in $staleImported.Record.PSObject.Properties) {
        $staleRecord[$property.Name] = $property.Value
    }
    $staleRecord['Timestamp'] = (Get-Date).ToUniversalTime().AddDays(-31).ToString('o')
    Save-BoostLabServiceRollbackRecord `
        -Record $staleRecord `
        -StateRoot $stateRoot | Out-Null
    $staleRollback = Invoke-BoostLabServiceRollback `
        -RecordPath $capture.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -ServiceReader $serviceReader `
        -ServiceMutator $serviceMutator `
        -Policy $testPolicy
    if (
        $staleRollback.Success -or
        $staleRollback.Status -ne 'Blocked' -or
        $staleRollback.RestoreAttempted -or
        (@($staleRollback.Errors) -join ' ') -notmatch 'stale'
    ) {
        $errors.Add('Stale service rollback record was not denied.')
    }

    $serviceStore.Status = 'Running'
    $serviceStore.StartupType = 'Automatic'
    $serviceStore.DelayedAutoStart = $true
    $successfulCapture = New-BoostLabServiceStateCapture `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -ScopeId 'local-mock-service' `
        -ServiceName $mockServiceName `
        -IntendedMutation Disable `
        -ServiceReader $serviceReader `
        -RiskClassification High `
        -Policy $testPolicy `
        -StateRoot $stateRoot
    $serviceStore.Status = 'Stopped'
    $serviceStore.StartupType = 'Disabled'
    $serviceStore.DelayedAutoStart = $false
    Set-BoostLabServiceRollbackMutationState `
        -RecordPath $successfulCapture.RecordPath `
        -StateRoot $stateRoot `
        -PostMutationState ([pscustomobject]$serviceStore) | Out-Null

    $serviceRollback = Invoke-BoostLabServiceRollback `
        -RecordPath $successfulCapture.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -ServiceReader $serviceReader `
        -ServiceMutator $serviceMutator `
        -Policy $testPolicy
    if (
        -not $serviceRollback.Success -or
        $serviceRollback.Status -ne 'Restored' -or
        -not $serviceRollback.RestoreAttempted -or
        $serviceRollback.Verification.Status -ne 'Passed' -or
        $serviceRollback.MutationPlan.Create -or
        $serviceRollback.MutationPlan.Delete -or
        $serviceStore.Status -ne 'Running' -or
        $serviceStore.StartupType -ne 'Automatic' -or
        $serviceStore.DelayedAutoStart -ne $true
    ) {
        $errors.Add(
            "Verified mocked service rollback failed: " +
            ($serviceRollback.Errors -join '; ')
        )
    }

    $serviceStore.Status = 'Running'
    $serviceStore.StartupType = 'Automatic'
    $serviceStore.DelayedAutoStart = $true
    $failedCapture = New-BoostLabServiceStateCapture `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -ScopeId 'local-mock-service' `
        -ServiceName $mockServiceName `
        -IntendedMutation Disable `
        -ServiceReader $serviceReader `
        -RiskClassification High `
        -Policy $testPolicy `
        -StateRoot $stateRoot
    $serviceStore.Status = 'Stopped'
    $serviceStore.StartupType = 'Disabled'
    $serviceStore.DelayedAutoStart = $false
    Set-BoostLabServiceRollbackMutationState `
        -RecordPath $failedCapture.RecordPath `
        -StateRoot $stateRoot `
        -PostMutationState ([pscustomobject]$serviceStore) | Out-Null
    $failingMutator = {
        param($MutationPlan)

        return [pscustomobject]@{
            Success = $false
            Status  = 'Failed'
        }
    }
    $failedRollback = Invoke-BoostLabServiceRollback `
        -RecordPath $failedCapture.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -ServiceReader $serviceReader `
        -ServiceMutator $failingMutator `
        -Policy $testPolicy
    if (
        $failedRollback.Success -or
        $failedRollback.Status -ne 'Failed' -or
        -not $failedRollback.RestoreAttempted -or
        @($failedRollback.Errors).Count -eq 0
    ) {
        $errors.Add('Service rollback mutation failure was ignored or hidden.')
    }

    foreach ($modulePath in @($stateModulePath, $rollbackModulePath)) {
        $tokens = $null
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $modulePath,
            [ref]$tokens,
            [ref]$parseErrors
        )
        if (@($parseErrors).Count -gt 0) {
            $errors.Add("$modulePath has a syntax error: $($parseErrors[0].Message)")
            continue
        }
        $commands = @(
            $ast.FindAll(
                { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
                $true
            ) |
                ForEach-Object { $_.GetCommandName() } |
                Where-Object { $_ }
        )
        foreach ($forbiddenCommand in @(
            'Get-Service'
            'Set-Service'
            'Start-Service'
            'Stop-Service'
            'Restart-Service'
            'New-Service'
            'Remove-Service'
            'sc.exe'
            'sc'
        )) {
            if ($forbiddenCommand -in $commands) {
                $errors.Add(
                    "$modulePath contains prohibited live service command: $forbiddenCommand"
                )
            }
        }
    }

    $executionSource = Get-Content -LiteralPath $executionPath -Raw
    foreach ($newHelperName in @(
        'ServiceState.psm1'
        'ServiceRollback.psm1'
        'New-BoostLabServiceStateCapture'
        'Invoke-BoostLabServiceRollback'
    )) {
        if ($executionSource.Contains($newHelperName)) {
            $errors.Add("Existing tool runtime was wired to the Phase 37 helper: $newHelperName")
        }
    }
    foreach ($module in Get-ChildItem -LiteralPath $modulesRoot -Recurse -File -Filter '*.psm1') {
        $moduleSource = Get-Content -LiteralPath $module.FullName -Raw
        if (
            $moduleSource.Contains('New-BoostLabServiceStateCapture') -or
            $moduleSource.Contains('Invoke-BoostLabServiceRollback')
        ) {
            $errors.Add("Tool module was wired to the Phase 37 foundation: $($module.FullName)")
        }
    }

    $allModules = @(
        Get-ChildItem -LiteralPath $modulesRoot -Recurse -File -Filter '*.psm1' |
            Where-Object { $_.Directory.Parent.FullName -eq $modulesRoot }
    )
    $implementedModules = @(
        $allModules | Where-Object {
            (Get-Content -LiteralPath $_.FullName -Raw).Contains(
                '$script:BoostLabImplementedActions'
            )
        }
    )
    $placeholderModules = @(
        $allModules | Where-Object {
            (Get-Content -LiteralPath $_.FullName -Raw).Contains(
                'ToolModule.Placeholder.ps1'
            )
        }
    )
    if (
        $allModules.Count -ne 48 -or
        $implementedModules.Count -ne 29 -or
        $placeholderModules.Count -ne 19
    ) {
        $errors.Add(
            "Tool inventory changed: total=$($allModules.Count), " +
            "implemented=$($implementedModules.Count), " +
            "placeholders=$($placeholderModules.Count)."
        )
    }

    $configuration = Import-PowerShellDataFile -LiteralPath $configPath
    $tools = @($configuration['Stages'] | ForEach-Object { $_['Tools'] })
    $activeNames = @(
        $tools | ForEach-Object {
            ([string]$_['Id'] -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()
            ([string]$_['Title'] -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()
        }
    )
    foreach ($deletedTool in @('Loudness EQ', 'NVME Faster Driver')) {
        $normalized = ($deletedTool -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()
        if ($normalized -in $activeNames) {
            $errors.Add("Deleted tool was reintroduced: $deletedTool")
        }
    }

    $sourceLines = @(
        Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
            Sort-Object {
                $_.FullName.Substring($ProjectRoot.Length + 1).Replace('\', '/')
            } |
            ForEach-Object {
                '{0}|{1}' -f `
                    $_.FullName.Substring($ProjectRoot.Length + 1).Replace('\', '/'), `
                    (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
            }
    )
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $sourceManifestHash = [BitConverter]::ToString(
            $sha256.ComputeHash(
                [Text.Encoding]::UTF8.GetBytes(($sourceLines -join "`n"))
            )
        ).Replace('-', '')
    }
    finally {
        $sha256.Dispose()
    }
    if (
        $sourceLines.Count -ne 49 -or
        $sourceManifestHash -ne
            '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477'
    ) {
        $errors.Add('source-ultimate content or paths changed.')
    }

    $policyText = Get-Content -LiteralPath $policyDocPath -Raw
    foreach ($requiredPhrase in @(
        'Production `ServiceScopes` are empty'
        'Wildcards, broad service selectors, unknown names'
        'Core Windows services'
        'post-mutation service snapshot'
        'Service creation, deletion, recreation'
        'does not wire service rollback into any tool'
    )) {
        if (-not $policyText.Contains($requiredPhrase)) {
            $errors.Add("Service rollback documentation is missing phrase: $requiredPhrase")
        }
    }
}
finally {
    Remove-Module -ModuleInfo $rollbackModule -Force -ErrorAction SilentlyContinue
    Remove-Module -ModuleInfo $stateModule -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $tempRoot -PathType Container) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($errors.Count -gt 0) {
    throw "Service rollback policy validation failed:`r`n- $($errors -join "`r`n- ")"
}

[pscustomobject]@{
    Success                       = $true
    ProductionServiceScopes       = 0
    ExactScopeEnforced            = $true
    WildcardServiceBlocked        = $true
    ProtectedServiceBlocked       = $true
    CreateDeleteBlocked           = $true
    MissingRecordBlocked          = $true
    CorruptRecordBlocked          = $true
    StaleRecordBlocked            = $true
    IdentityMismatchBlocked       = $true
    MockServiceRollbackPassed     = $true
    RollbackFailureReported       = $true
    LiveServiceCommandsPresent    = $false
    ImplementedModuleCount        = 29
    PlaceholderModuleCount        = 19
    SourceUltimateUnchanged       = $true
    Message                       = 'Service state capture and rollback is exact, guarded, mocked, and deny-by-default.'
    Timestamp                     = Get-Date
}
