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
        throw 'Unable to determine the destructive cleanup policy test path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$policyPath = Join-Path $ProjectRoot 'config\CleanupPolicy.psd1'
$policyModulePath = Join-Path $ProjectRoot 'core\CleanupPolicy.psm1'
$executionModulePath = Join-Path $ProjectRoot 'core\CleanupExecution.psm1'
$runtimeExecutionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$policyDocPath = Join-Path $ProjectRoot 'docs\destructive-cleanup-policy.md'
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
        $errors.Add("Required Phase 38 file is missing: $requiredPath")
    }
}
if ($errors.Count -gt 0) {
    throw "Destructive cleanup policy validation failed:`r`n- $($errors -join "`r`n- ")"
}

$policyModule = Import-Module `
    -Name $policyModulePath `
    -Force `
    -PassThru `
    -Scope Local `
    -ErrorAction Stop
$executionModule = Import-Module `
    -Name $executionModulePath `
    -Force `
    -PassThru `
    -Scope Local `
    -ErrorAction Stop

$tempRoot = Join-Path `
    ([IO.Path]::GetTempPath()) `
    ("BoostLab-CleanupPolicyTest-{0}" -f [guid]::NewGuid())
$allowedRoot = Join-Path $tempRoot 'Allowed'
$stateRoot = Join-Path $tempRoot 'State'
$fileTarget = Join-Path $allowedRoot 'safe-file.txt'
$directoryTarget = Join-Path $allowedRoot 'safe-directory'
[IO.Directory]::CreateDirectory($allowedRoot) | Out-Null
[IO.Directory]::CreateDirectory($directoryTarget) | Out-Null
[IO.File]::WriteAllText(
    $fileTarget,
    'BoostLab isolated cleanup policy test data.',
    [Text.Encoding]::UTF8
)
[IO.File]::WriteAllText(
    (Join-Path $directoryTarget 'one.txt'),
    'one',
    [Text.Encoding]::UTF8
)
[IO.File]::WriteAllText(
    (Join-Path $directoryTarget 'two.txt'),
    'two',
    [Text.Encoding]::UTF8
)

try {
    foreach ($commandName in @(
        'Get-BoostLabCleanupPolicy'
        'Get-BoostLabCleanupStateRoot'
        'Test-BoostLabCleanupPolicy'
        'Test-BoostLabCleanupTarget'
        'Test-BoostLabCleanupStateCaptureEvidence'
        'New-BoostLabCleanupPlan'
        'New-BoostLabQuarantineRecord'
        'Save-BoostLabQuarantineRecord'
        'Import-BoostLabQuarantineRecord'
        'Test-BoostLabQuarantineRecord'
        'Test-BoostLabCleanupExecutionRequest'
        'Invoke-BoostLabCleanupOperation'
        'Invoke-BoostLabQuarantineRestore'
    )) {
        if (-not (Get-Command -Name $commandName -ErrorAction SilentlyContinue)) {
            $errors.Add("Phase 38 helper is not exported: $commandName")
        }
    }

    $productionPolicy = Get-BoostLabCleanupPolicy -PolicyPath $policyPath
    $productionValidation = Test-BoostLabCleanupPolicy -Policy $productionPolicy
    if (-not $productionValidation.IsValid) {
        $errors.Add(
            "Production cleanup policy is invalid: " +
            ($productionValidation.Errors -join '; ')
        )
    }
    if ($productionValidation.CleanupScopeCount -ne 0) {
        $errors.Add('Phase 38 must not approve production cleanup scopes.')
    }

    $testPolicy = @{
        SchemaVersion = '1.0'
        MaxRecordAgeDays = 30
        CleanupScopes = @(
            @{
                ScopeId             = 'local-cleanup-test'
                ToolIds            = @('mock-tool')
                AllowedRoot         = $allowedRoot
                AllowedTargets      = @($fileTarget, $directoryTarget)
                AllowedTargetTypes  = @('File', 'Directory')
                AllowedCleanupTypes = @(
                    'Delete'
                    'Quarantine'
                    'EmptyDirectory'
                    'RemoveGeneratedArtifact'
                )
                AllowRecursive      = $true
                MaxFiles            = 10
                MaxBytes            = 1048576
                AllowReparsePoints  = $false
                AllowUserDocuments  = $false
                RequireStateCapture = $false
                AllowPermanentDelete = $true
                AllowQuarantine     = $true
            }
        )
    }
    $testPolicyValidation = Test-BoostLabCleanupPolicy -Policy $testPolicy
    if (
        -not $testPolicyValidation.IsValid -or
        $testPolicyValidation.CleanupScopeCount -ne 1
    ) {
        $errors.Add(
            "Local mock cleanup policy was rejected: " +
            ($testPolicyValidation.Errors -join '; ')
        )
    }

    $productionPlan = New-BoostLabCleanupPlan `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -ScopeId 'not-approved' `
        -TargetPath $fileTarget `
        -TargetType File `
        -CleanupType Delete `
        -Reason 'Production deny-by-default test.' `
        -Policy $productionPolicy `
        -StateRoot $stateRoot
    $productionExecutorState = [pscustomobject]@{ Called = $false }
    $productionExecutor = {
        param($Plan)

        $productionExecutorState.Called = $true
        return [pscustomobject]@{
            Success         = $true
            CleanupExecuted = $true
        }
    }.GetNewClosure()
    $productionResult = Invoke-BoostLabCleanupOperation `
        -Plan $productionPlan `
        -ActionPlan ([pscustomobject]@{
            ToolId = 'mock-tool'
            Action = 'Apply'
            NeedsExplicitConfirmation = $true
        }) `
        -Confirmed:$true `
        -CleanupExecutor $productionExecutor `
        -CleanupVerifier {
            param($Plan, $ExecutionResult)
            [pscustomobject]@{ Status = 'Passed' }
        } `
        -StateRoot $stateRoot
    if (
        $productionPlan.IsAllowed -or
        $productionResult.Status -ne 'Blocked' -or
        $productionResult.CleanupExecuted -or
        $productionExecutorState.Called
    ) {
        $errors.Add('Empty production cleanup scopes did not deny execution.')
    }

    foreach ($broadRoot in @(
        'C:\'
        $env:SystemRoot
        (Join-Path $env:SystemRoot 'System32')
        $env:ProgramFiles
        $env:ProgramData
        $env:USERPROFILE
        [Environment]::GetFolderPath('Desktop')
        [Environment]::GetFolderPath('MyDocuments')
        (Join-Path $env:USERPROFILE 'Downloads')
        $env:APPDATA
        $env:LOCALAPPDATA
        [IO.Path]::GetTempPath()
    )) {
        if ([string]::IsNullOrWhiteSpace([string]$broadRoot)) {
            continue
        }
        $broadPolicy = @{
            SchemaVersion = '1.0'
            MaxRecordAgeDays = 30
            CleanupScopes = @(
                @{
                    ScopeId             = 'broad-root'
                    ToolIds            = @('mock-tool')
                    AllowedRoot         = $broadRoot
                    AllowedTargets      = @($broadRoot)
                    AllowedTargetTypes  = @('Directory')
                    AllowedCleanupTypes = @('Delete')
                    AllowRecursive      = $true
                    MaxFiles            = 10
                    MaxBytes            = 1024
                    AllowReparsePoints  = $false
                    AllowUserDocuments  = $false
                    RequireStateCapture = $true
                    AllowPermanentDelete = $true
                    AllowQuarantine     = $false
                }
            )
        }
        $broadValidation = Test-BoostLabCleanupPolicy -Policy $broadPolicy
        if ($broadValidation.IsValid) {
            $errors.Add("Denied broad cleanup root was accepted: $broadRoot")
        }
    }

    $wildcardTarget = Test-BoostLabCleanupTarget `
        -ToolId 'mock-tool' `
        -ScopeId 'local-cleanup-test' `
        -TargetPath (Join-Path $allowedRoot '*') `
        -TargetType File `
        -CleanupType Delete `
        -Policy $testPolicy
    if ($wildcardTarget.IsAllowed -or $wildcardTarget.Status -ne 'Blocked') {
        $errors.Add('Wildcard cleanup path was not denied.')
    }

    $traversalTarget = Test-BoostLabCleanupTarget `
        -ToolId 'mock-tool' `
        -ScopeId 'local-cleanup-test' `
        -TargetPath (Join-Path $allowedRoot '..\outside.txt') `
        -TargetType File `
        -CleanupType Delete `
        -Policy $testPolicy
    if ($traversalTarget.IsAllowed -or $traversalTarget.Status -ne 'Blocked') {
        $errors.Add('Cleanup path traversal was not denied.')
    }

    $unresolvedTarget = Test-BoostLabCleanupTarget `
        -ToolId 'mock-tool' `
        -ScopeId 'local-cleanup-test' `
        -TargetPath '%BOOSTLAB_PHASE38_UNDEFINED%\target.txt' `
        -TargetType File `
        -CleanupType Delete `
        -Policy $testPolicy
    if ($unresolvedTarget.IsAllowed -or $unresolvedTarget.Status -ne 'Blocked') {
        $errors.Add('Unresolved environment-variable cleanup path was not denied.')
    }

    $outsideTarget = Join-Path $tempRoot 'outside.txt'
    $outsideValidation = Test-BoostLabCleanupTarget `
        -ToolId 'mock-tool' `
        -ScopeId 'local-cleanup-test' `
        -TargetPath $outsideTarget `
        -TargetType File `
        -CleanupType Delete `
        -Policy $testPolicy
    if ($outsideValidation.IsAllowed -or $outsideValidation.Status -ne 'Blocked') {
        $errors.Add('Cleanup target outside the exact scope was not denied.')
    }

    $documentRoot = Join-Path `
        ([Environment]::GetFolderPath('MyDocuments')) `
        'BoostLabPhase38PolicyOnly'
    $documentTarget = Join-Path $documentRoot 'mock-document.txt'
    $documentPolicy = @{
        SchemaVersion = '1.0'
        MaxRecordAgeDays = 30
        CleanupScopes = @(
            @{
                ScopeId             = 'document-test'
                ToolIds            = @('mock-tool')
                AllowedRoot         = $documentRoot
                AllowedTargets      = @($documentTarget)
                AllowedTargetTypes  = @('File')
                AllowedCleanupTypes = @('Quarantine')
                AllowRecursive      = $false
                MaxFiles            = 1
                MaxBytes            = 1024
                AllowReparsePoints  = $false
                AllowUserDocuments  = $false
                RequireStateCapture = $true
                AllowPermanentDelete = $false
                AllowQuarantine     = $true
            }
        )
    }
    $missingFileInspector = {
        param($Path, $TargetType)

        return [pscustomobject]@{
            Exists               = $false
            TargetType           = $TargetType
            ResolvedPath         = $Path
            IsReparsePoint       = $false
            ContainsReparsePoint = $false
            FileCount            = 0
            TotalBytes           = 0L
            Hash                 = ''
            Metadata             = $null
        }
    }
    $documentDenied = Test-BoostLabCleanupTarget `
        -ToolId 'mock-tool' `
        -ScopeId 'document-test' `
        -TargetPath $documentTarget `
        -TargetType File `
        -CleanupType Quarantine `
        -Policy $documentPolicy `
        -PathInspector $missingFileInspector
    if ($documentDenied.IsAllowed -or $documentDenied.Status -ne 'Blocked') {
        $errors.Add('User document cleanup was not denied without explicit scope permission.')
    }
    $documentPolicy.CleanupScopes[0].AllowUserDocuments = $true
    $documentAllowed = Test-BoostLabCleanupTarget `
        -ToolId 'mock-tool' `
        -ScopeId 'document-test' `
        -TargetPath $documentTarget `
        -TargetType File `
        -CleanupType Quarantine `
        -Policy $documentPolicy `
        -PathInspector $missingFileInspector
    if (-not $documentAllowed.IsAllowed) {
        $errors.Add(
            'Exact mocked user document scope was rejected after explicit permission: ' +
            ($documentAllowed.Errors -join '; ')
        )
    }

    $reparseInspector = {
        param($Path, $TargetType)

        return [pscustomobject]@{
            Exists               = $true
            TargetType           = $TargetType
            ResolvedPath         = $Path
            IsReparsePoint       = $true
            ContainsReparsePoint = $true
            FileCount            = 1
            TotalBytes           = 4L
            Hash                 = ('A' * 64)
            Metadata             = [ordered]@{ Mock = $true }
        }
    }
    $reparseTarget = Test-BoostLabCleanupTarget `
        -ToolId 'mock-tool' `
        -ScopeId 'local-cleanup-test' `
        -TargetPath $fileTarget `
        -TargetType File `
        -CleanupType Delete `
        -Policy $testPolicy `
        -PathInspector $reparseInspector
    if ($reparseTarget.IsAllowed -or $reparseTarget.Status -ne 'Blocked') {
        $errors.Add('Reparse-point cleanup target was not denied.')
    }

    $nonRecursivePolicy = @{
        SchemaVersion = '1.0'
        MaxRecordAgeDays = 30
        CleanupScopes = @(
            @{
                ScopeId             = 'non-recursive'
                ToolIds            = @('mock-tool')
                AllowedRoot         = $allowedRoot
                AllowedTargets      = @($directoryTarget)
                AllowedTargetTypes  = @('Directory')
                AllowedCleanupTypes = @('EmptyDirectory')
                AllowRecursive      = $false
                MaxFiles            = 0
                MaxBytes            = 0
                AllowReparsePoints  = $false
                AllowUserDocuments  = $false
                RequireStateCapture = $true
                AllowPermanentDelete = $false
                AllowQuarantine     = $false
            }
        )
    }
    $recursiveDenied = Test-BoostLabCleanupTarget `
        -ToolId 'mock-tool' `
        -ScopeId 'non-recursive' `
        -TargetPath $directoryTarget `
        -TargetType Directory `
        -CleanupType EmptyDirectory `
        -Recursive:$true `
        -Policy $nonRecursivePolicy
    if ($recursiveDenied.IsAllowed -or $recursiveDenied.Status -ne 'Blocked') {
        $errors.Add('Recursive cleanup without explicit scope permission was not denied.')
    }

    $oversizeInspector = {
        param($Path, $TargetType)

        return [pscustomobject]@{
            Exists               = $true
            TargetType           = $TargetType
            ResolvedPath         = $Path
            IsReparsePoint       = $false
            ContainsReparsePoint = $false
            FileCount            = 11
            TotalBytes           = 1048577L
            Hash                 = ('B' * 64)
            Metadata             = [ordered]@{ Mock = $true }
        }
    }
    $oversizeTarget = Test-BoostLabCleanupTarget `
        -ToolId 'mock-tool' `
        -ScopeId 'local-cleanup-test' `
        -TargetPath $directoryTarget `
        -TargetType Directory `
        -CleanupType EmptyDirectory `
        -Recursive:$true `
        -Policy $testPolicy `
        -PathInspector $oversizeInspector
    if ($oversizeTarget.IsAllowed -or $oversizeTarget.Status -ne 'Blocked') {
        $errors.Add('Recursive cleanup exceeding file/byte limits was not denied.')
    }

    $filePlan = New-BoostLabCleanupPlan `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -ScopeId 'local-cleanup-test' `
        -TargetPath $fileTarget `
        -TargetType File `
        -CleanupType Delete `
        -Reason 'Remove one isolated mocked artifact.' `
        -RiskClassification High `
        -RollbackEligible:$true `
        -Policy $testPolicy `
        -StateRoot $stateRoot
    foreach ($requiredField in @(
        'OperationId'
        'ToolId'
        'ActionId'
        'Timestamp'
        'SchemaVersion'
        'BoostLabVersion'
        'TargetPath'
        'ResolvedPath'
        'TargetType'
        'CleanupType'
        'Reason'
        'RiskClassification'
        'RequiredConfirmationLevel'
        'RollbackEligible'
        'StateCaptureRequired'
        'VerificationRequirement'
        'ScopeId'
    )) {
        if ($null -eq $filePlan.PSObject.Properties[$requiredField]) {
            $errors.Add("Cleanup plan is missing field: $requiredField")
        }
    }
    if (
        -not $filePlan.IsAllowed -or
        -not $filePlan.IsDryRun -or
        -not $filePlan.RequiresExplicitConfirmation -or
        -not $filePlan.StateCaptureRequired
    ) {
        $errors.Add("Valid isolated cleanup plan was rejected: $($filePlan.Errors -join '; ')")
    }

    $actionPlan = [pscustomobject]@{
        ToolId = 'mock-tool'
        Action = 'Apply'
        NeedsExplicitConfirmation = $true
    }
    $missingCaptureRequest = Test-BoostLabCleanupExecutionRequest `
        -Plan $filePlan `
        -ActionPlan $actionPlan `
        -Confirmed:$true
    if ($missingCaptureRequest.IsAllowed -or $missingCaptureRequest.Status -ne 'Blocked') {
        $errors.Add('Rollback-eligible cleanup without state capture was not blocked.')
    }

    $stateCaptureEvidence = [pscustomobject]@{
        Success    = $true
        RecordPath = Join-Path $stateRoot 'MockRollbackRecord.json'
        Record     = [pscustomobject]@{
            ToolId           = 'mock-tool'
            ActionId         = 'Apply'
            SourcePath       = $filePlan.ResolvedPath
            ItemType         = 'File'
            RollbackEligible = $true
        }
    }
    $unconfirmedRequest = Test-BoostLabCleanupExecutionRequest `
        -Plan $filePlan `
        -ActionPlan $actionPlan `
        -Confirmed:$false `
        -StateCaptureEvidence $stateCaptureEvidence
    if ($unconfirmedRequest.IsAllowed -or $unconfirmedRequest.Status -ne 'Blocked') {
        $errors.Add('Destructive cleanup without explicit confirmation was not blocked.')
    }
    $validatedRequest = Test-BoostLabCleanupExecutionRequest `
        -Plan $filePlan `
        -ActionPlan $actionPlan `
        -Confirmed:$true `
        -StateCaptureEvidence $stateCaptureEvidence
    if (-not $validatedRequest.IsAllowed -or $validatedRequest.Status -ne 'Validated') {
        $errors.Add(
            "Fully approved cleanup request did not validate: " +
            ($validatedRequest.Errors -join '; ')
        )
    }

    $executorState = [pscustomobject]@{ Calls = 0 }
    $mockExecutor = {
        param($Plan)

        $executorState.Calls++
        return [pscustomobject]@{
            Success         = $true
            CleanupExecuted = $true
        }
    }.GetNewClosure()
    $mockVerifier = {
        param($Plan, $ExecutionResult)

        return [pscustomobject]@{
            Status  = 'Passed'
            Expected = 'Absent'
            Actual   = 'Mocked absent state'
            Message  = 'No real file operation was performed.'
        }
    }
    $cleanupResult = Invoke-BoostLabCleanupOperation `
        -Plan $filePlan `
        -ActionPlan $actionPlan `
        -Confirmed:$true `
        -StateCaptureEvidence $stateCaptureEvidence `
        -CleanupExecutor $mockExecutor `
        -CleanupVerifier $mockVerifier `
        -StateRoot $stateRoot
    if (
        -not $cleanupResult.Success -or
        $cleanupResult.Status -ne 'Completed' -or
        -not $cleanupResult.CleanupExecuted -or
        $cleanupResult.Verification.Status -ne 'Passed' -or
        $executorState.Calls -ne 1 -or
        -not (Test-Path -LiteralPath $fileTarget -PathType Leaf)
    ) {
        $errors.Add('Mocked cleanup execution did not remain bounded and non-destructive.')
    }

    $failedVerification = Invoke-BoostLabCleanupOperation `
        -Plan $filePlan `
        -ActionPlan $actionPlan `
        -Confirmed:$true `
        -StateCaptureEvidence $stateCaptureEvidence `
        -CleanupExecutor $mockExecutor `
        -CleanupVerifier {
            param($Plan, $ExecutionResult)
            [pscustomobject]@{ Status = 'Failed' }
        } `
        -StateRoot $stateRoot
    if (
        $failedVerification.Success -or
        $failedVerification.Status -ne 'Failed' -or
        -not $failedVerification.CleanupExecuted -or
        @($failedVerification.Errors).Count -eq 0
    ) {
        $errors.Add('Post-cleanup verification failure was ignored or hidden.')
    }

    $quarantinePlan = New-BoostLabCleanupPlan `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -ScopeId 'local-cleanup-test' `
        -TargetPath $fileTarget `
        -TargetType File `
        -CleanupType Quarantine `
        -Reason 'Quarantine one isolated mocked artifact.' `
        -RiskClassification High `
        -RollbackEligible:$true `
        -Policy $testPolicy `
        -StateRoot $stateRoot
    $quarantineEvidence = [pscustomobject]@{
        Success    = $true
        RecordPath = Join-Path $stateRoot 'MockQuarantineCapture.json'
        Record     = [pscustomobject]@{
            ToolId           = 'mock-tool'
            ActionId         = 'Apply'
            SourcePath       = $quarantinePlan.ResolvedPath
            ItemType         = 'File'
            RollbackEligible = $true
        }
    }
    $quarantineExecutor = {
        param($Plan)

        return [pscustomobject]@{
            Success            = $true
            CleanupExecuted    = $true
            QuarantinePath     = $Plan.QuarantinePath
            QuarantineHash     = $Plan.OriginalSnapshot.Hash
            QuarantineMetadata = $Plan.OriginalSnapshot.Metadata
        }
    }
    $quarantineResult = Invoke-BoostLabCleanupOperation `
        -Plan $quarantinePlan `
        -ActionPlan $actionPlan `
        -Confirmed:$true `
        -StateCaptureEvidence $quarantineEvidence `
        -CleanupExecutor $quarantineExecutor `
        -CleanupVerifier $mockVerifier `
        -StateRoot $stateRoot
    if (
        -not $quarantineResult.Success -or
        $quarantineResult.Status -ne 'Quarantined' -or
        -not (Test-Path `
            -LiteralPath $quarantineResult.QuarantineRecord.RecordPath `
            -PathType Leaf) -or
        -not (Test-Path -LiteralPath $fileTarget -PathType Leaf)
    ) {
        $errors.Add(
            "Mocked quarantine did not create a verified record: " +
            ($quarantineResult.Errors -join '; ')
        )
    }

    $quarantineRecord = $quarantineResult.QuarantineRecord.Record
    foreach ($requiredField in @(
        'OperationId'
        'ToolId'
        'ActionId'
        'OriginalPath'
        'OriginalResolvedPath'
        'OriginalHash'
        'OriginalMetadata'
        'QuarantinePath'
        'QuarantineHash'
        'Reason'
        'RestoreEligible'
    )) {
        if ($null -eq $quarantineRecord.PSObject.Properties[$requiredField]) {
            $errors.Add("Quarantine record is missing field: $requiredField")
        }
    }
    $quarantineValidation = Test-BoostLabQuarantineRecord `
        -Record $quarantineRecord `
        -ExpectedToolId 'mock-tool' `
        -ExpectedActionId 'Apply' `
        -StateRoot $stateRoot `
        -Policy $testPolicy
    if (-not $quarantineValidation.IsValid) {
        $errors.Add(
            "Valid quarantine record was rejected: " +
            ($quarantineValidation.Errors -join '; ')
        )
    }

    $hashMismatchRecord = [ordered]@{}
    foreach ($property in $quarantineRecord.PSObject.Properties) {
        $hashMismatchRecord[$property.Name] = $property.Value
    }
    $hashMismatchRecord['QuarantineHash'] = ('0' * 64)
    $hashMismatchValidation = Test-BoostLabQuarantineRecord `
        -Record ([pscustomobject]$hashMismatchRecord) `
        -ExpectedToolId 'mock-tool' `
        -ExpectedActionId 'Apply' `
        -StateRoot $stateRoot `
        -Policy $testPolicy
    if ($hashMismatchValidation.IsValid) {
        $errors.Add('Quarantine record with mismatched hashes was not denied.')
    }

    $restoreActionPlan = [pscustomobject]@{
        ToolId = 'mock-tool'
        Action = 'Apply'
        NeedsExplicitConfirmation = $true
    }
    $quarantineInspector = {
        param($Path, $TargetType)

        return [pscustomobject]@{
            Exists               = $true
            TargetType           = $TargetType
            ResolvedPath         = $Path
            IsReparsePoint       = $false
            ContainsReparsePoint = $false
            FileCount            = 1
            TotalBytes           = $quarantineRecord.OriginalTotalBytes
            Hash                 = $quarantineRecord.QuarantineHash
            Metadata             = $quarantineRecord.QuarantineMetadata
        }
    }.GetNewClosure()
    $originalAbsentInspector = {
        param($Path, $TargetType)

        return [pscustomobject]@{
            Exists               = $false
            TargetType           = $TargetType
            ResolvedPath         = $Path
            IsReparsePoint       = $false
            ContainsReparsePoint = $false
            FileCount            = 0
            TotalBytes           = 0L
            Hash                 = ''
            Metadata             = $null
        }
    }
    $restoreExecutorState = [pscustomobject]@{ Calls = 0 }
    $restoreExecutor = {
        param($Record)

        $restoreExecutorState.Calls++
        return [pscustomobject]@{
            Success         = $true
            RestoreExecuted = $true
        }
    }.GetNewClosure()
    $restoreVerifier = {
        param($Record, $RestoreResult)

        return [pscustomobject]@{
            Status   = 'Passed'
            Expected = $Record.OriginalHash
            Actual   = $Record.OriginalHash
        }
    }
    $restoreResult = Invoke-BoostLabQuarantineRestore `
        -RecordPath $quarantineResult.QuarantineRecord.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -ActionPlan $restoreActionPlan `
        -Confirmed:$true `
        -QuarantineInspector $quarantineInspector `
        -OriginalPathInspector $originalAbsentInspector `
        -RestoreExecutor $restoreExecutor `
        -RestoreVerifier $restoreVerifier `
        -Policy $testPolicy
    if (
        -not $restoreResult.Success -or
        $restoreResult.Status -ne 'Restored' -or
        -not $restoreResult.RestoreExecuted -or
        $restoreResult.Verification.Status -ne 'Passed' -or
        $restoreExecutorState.Calls -ne 1
    ) {
        $errors.Add(
            "Mocked quarantine restore failed: $($restoreResult.Errors -join '; ')"
        )
    }

    $corruptRecordPath = Join-Path $stateRoot 'Records\corrupt.quarantine.json'
    [IO.File]::WriteAllText($corruptRecordPath, '{not-json', [Text.Encoding]::UTF8)
    $corruptRecord = Import-BoostLabQuarantineRecord `
        -RecordPath $corruptRecordPath `
        -StateRoot $stateRoot
    if ($corruptRecord.IsValid -or $corruptRecord.Status -ne 'Blocked') {
        $errors.Add('Corrupt quarantine record was not denied.')
    }

    foreach ($modulePath in @($policyModulePath, $executionModulePath)) {
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
            'Remove-Item'
            'Move-Item'
            'Clear-Content'
            'Remove-ItemProperty'
            'robocopy'
            'rmdir'
            'del'
            'erase'
        )) {
            if ($forbiddenCommand -in $commands) {
                $errors.Add(
                    "$modulePath contains prohibited destructive command: $forbiddenCommand"
                )
            }
        }
    }

    $runtimeSource = Get-Content -LiteralPath $runtimeExecutionPath -Raw
    foreach ($helperName in @(
        'CleanupPolicy.psm1'
        'CleanupExecution.psm1'
        'New-BoostLabCleanupPlan'
        'Invoke-BoostLabCleanupOperation'
        'Invoke-BoostLabQuarantineRestore'
    )) {
        if ($runtimeSource.Contains($helperName)) {
            $errors.Add("Existing runtime was wired to Phase 38 helper: $helperName")
        }
    }
    foreach ($module in Get-ChildItem -LiteralPath $modulesRoot -Recurse -File -Filter '*.psm1') {
        $moduleSource = Get-Content -LiteralPath $module.FullName -Raw
        if (
            $moduleSource.Contains('New-BoostLabCleanupPlan') -or
            $moduleSource.Contains('Invoke-BoostLabCleanupOperation') -or
            $moduleSource.Contains('Invoke-BoostLabQuarantineRestore')
        ) {
            $errors.Add("Tool module was wired to Phase 38 foundation: $($module.FullName)")
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
        $implementedModules.Count -ne 30 -or
        $placeholderModules.Count -ne 18
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
        'Production `CleanupScopes` are empty'
        'Wildcard'
        'Path traversal'
        'Symlinks, junctions, and reparse points'
        'Action Plan with explicit confirmation'
        'state-capture evidence'
        'Permanent Delete'
        'Quarantine'
        'Phase 38 performs no real quarantine'
        'remain deferred'
    )) {
        if (-not $policyText.Contains($requiredPhrase)) {
            $errors.Add("Cleanup policy documentation is missing phrase: $requiredPhrase")
        }
    }
}
finally {
    Remove-Module -ModuleInfo $executionModule -Force -ErrorAction SilentlyContinue
    Remove-Module -ModuleInfo $policyModule -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $tempRoot -PathType Container) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($errors.Count -gt 0) {
    throw "Destructive cleanup policy validation failed:`r`n- $($errors -join "`r`n- ")"
}

[pscustomobject]@{
    Success                    = $true
    ProductionCleanupScopes    = 0
    BroadRootsBlocked          = $true
    WildcardsBlocked           = $true
    TraversalBlocked           = $true
    ReparsePointsBlocked       = $true
    UserDocumentsGuarded       = $true
    RecursiveLimitsEnforced    = $true
    StateCaptureRequired       = $true
    ConfirmationRequired       = $true
    MockCleanupPlanned         = $true
    MockQuarantineRecorded     = $true
    MockQuarantineRestorePassed = $true
    RealFilesDeleted           = $false
    ImplementedModuleCount     = 30
    PlaceholderModuleCount     = 18
    SourceUltimateUnchanged    = $true
    Message                    = 'Destructive cleanup policy is bounded, confirmed, verified, mocked, and deny-by-default.'
    Timestamp                  = Get-Date
}
