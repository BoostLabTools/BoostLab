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
        throw 'Unable to determine the reboot recovery policy test path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$policyPath = Join-Path $ProjectRoot 'config\RebootRecoveryPolicy.psd1'
$workflowModulePath = Join-Path $ProjectRoot 'core\RebootWorkflow.psm1'
$executionModulePath = Join-Path $ProjectRoot 'core\RebootExecution.psm1'
$policyDocPath = Join-Path $ProjectRoot 'docs\reboot-recovery-workflow.md'
$runtimeExecutionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$errors = [System.Collections.Generic.List[string]]::new()
foreach ($requiredPath in @(
    $policyPath
    $workflowModulePath
    $executionModulePath
    $policyDocPath
)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        $errors.Add("Required Phase 40 file is missing: $requiredPath")
    }
}
if ($errors.Count -gt 0) {
    throw "Reboot recovery validation failed:`r`n- $($errors -join "`r`n- ")"
}

Import-Module `
    -Name $workflowModulePath `
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
    ("BoostLab-RebootRecoveryTest-{0}" -f [guid]::NewGuid())
$stateRoot = Join-Path $tempRoot 'WorkflowState'
$captureRoot = Join-Path $tempRoot 'CapturedState'
$trustedResumeRoot = Join-Path $tempRoot 'TrustedResume'
$trustedArtifact = Join-Path $trustedResumeRoot 'resume.payload'
$captureRecord = Join-Path $captureRoot 'state-record.json'
[IO.Directory]::CreateDirectory($captureRoot) | Out-Null
[IO.Directory]::CreateDirectory($trustedResumeRoot) | Out-Null
[IO.File]::WriteAllText(
    $captureRecord,
    '{"mock":true}',
    [Text.Encoding]::UTF8
)
[IO.File]::WriteAllText(
    $trustedArtifact,
    'mock resume metadata only',
    [Text.Encoding]::UTF8
)

try {
    foreach ($commandName in @(
        'Get-BoostLabRebootRecoveryPolicy'
        'Get-BoostLabRebootRecoveryStateRoot'
        'Test-BoostLabRebootRecoveryPolicy'
        'Test-BoostLabRebootWorkflowTarget'
        'New-BoostLabRebootWorkflowPlan'
        'New-BoostLabRebootWorkflowRecord'
        'Save-BoostLabRebootWorkflowRecord'
        'Import-BoostLabRebootWorkflowRecord'
        'Test-BoostLabRebootWorkflowRecord'
        'Stop-BoostLabRebootWorkflow'
        'New-BoostLabRebootResumePlan'
        'Set-BoostLabRebootWorkflowVerification'
        'Test-BoostLabRebootExecutionRequest'
        'Invoke-BoostLabRebootRequest'
        'Register-BoostLabPostRebootResume'
    )) {
        if (-not (Get-Command -Name $commandName -ErrorAction SilentlyContinue)) {
            $errors.Add("Phase 40 helper is not exported: $commandName")
        }
    }

    $productionPolicy = Get-BoostLabRebootRecoveryPolicy `
        -PolicyPath $policyPath
    $productionValidation = Test-BoostLabRebootRecoveryPolicy `
        -Policy $productionPolicy
    if (-not $productionValidation.IsValid) {
        $errors.Add(
            'Production reboot recovery policy is invalid: ' +
            ($productionValidation.Errors -join '; ')
        )
    }
    if ($productionValidation.WorkflowScopeCount -ne 0) {
        $errors.Add('Phase 40 must not approve production reboot scopes.')
    }

    $testPolicy = @{
        SchemaVersion = '1.0'
        MaxRecordAgeDays = 7
        WorkflowScopes = @(
            @{
                ScopeId = 'mock-reboot-workflow'
                ToolIds = @('mock-reboot-tool')
                ActionIds = @('Apply')
                AllowedRebootTypes = @(
                    'NormalReboot'
                    'PostRebootResume'
                    'ManualRebootRequired'
                )
                RequiredCheckpointNames = @(
                    'StateCaptured'
                    'PowerReady'
                )
                AllowedStateReferenceRoots = @($captureRoot)
                AllowedResumeHandlerIds = @('mock-resume-handler')
                AllowedResumeArtifactPaths = @($trustedArtifact)
                RequiresStateCapture = $true
                AllowImmediateReboot = $true
                AllowResumeScheduling = $true
                AllowFirmwareReboot = $false
                AllowSafeModeReboot = $false
                MaxResumeSteps = 3
                MaxDurationMinutes = 120
                AllowCancellation = $true
                RequiredConfirmationLevel = 'Explicit'
                NeedsExplicitConfirmation = $true
            }
        )
    }
    $testPolicyValidation = Test-BoostLabRebootRecoveryPolicy `
        -Policy $testPolicy
    if (
        -not $testPolicyValidation.IsValid -or
        $testPolicyValidation.WorkflowScopeCount -ne 1
    ) {
        $errors.Add(
            'Mock reboot recovery policy was rejected: ' +
            ($testPolicyValidation.Errors -join '; ')
        )
    }

    $actionPlan = [pscustomobject]@{
        ToolId = 'mock-reboot-tool'
        Action = 'Apply'
        NeedsExplicitConfirmation = $true
    }
    $checkpoints = @(
        [pscustomobject]@{
            Name = 'StateCaptured'
            Status = 'Passed'
            Evidence = 'Verified state record captured.'
        }
        [pscustomobject]@{
            Name = 'PowerReady'
            Status = 'Passed'
            Evidence = 'Power readiness confirmed.'
        }
    )
    $stateReferences = @(
        [pscustomobject]@{
            ReferenceId = 'mock-state-record'
            Foundation = 'Rollback'
            RecordPath = $captureRecord
            RecordHash = (
                Get-FileHash -Algorithm SHA256 -LiteralPath $captureRecord
            ).Hash
            Verified = $true
        }
    )
    $resumeSteps = @(
        [pscustomobject]@{
            StepId = 'verify-resume-state'
            Order = 1
            HandlerId = 'mock-resume-handler'
            Description = 'Validate the mocked post-reboot condition.'
            ResumeArtifactPath = $trustedArtifact
            ExpectedConditions = @('Mock condition remains true.')
            VerificationRequirements = @('Mock verification returns Passed.')
        }
    )
    $verificationRequirements = @(
        'Verify the expected mocked post-reboot condition.'
    )

    $unknownTarget = Test-BoostLabRebootWorkflowTarget `
        -ToolId 'unknown-tool' `
        -ActionId 'Apply' `
        -ScopeId 'mock-reboot-workflow' `
        -RebootType NormalReboot `
        -Policy $testPolicy
    if ($unknownTarget.IsAllowed) {
        $errors.Add('Unknown reboot tool identity was not denied.')
    }
    $unknownAction = Test-BoostLabRebootWorkflowTarget `
        -ToolId 'mock-reboot-tool' `
        -ActionId 'UnknownAction' `
        -ScopeId 'mock-reboot-workflow' `
        -RebootType NormalReboot `
        -Policy $testPolicy
    if ($unknownAction.IsAllowed) {
        $errors.Add('Unknown reboot action identity was not denied.')
    }

    $baseArguments = @{
        ToolId = 'mock-reboot-tool'
        ActionId = 'Apply'
        ScopeId = 'mock-reboot-workflow'
        RebootType = 'NormalReboot'
        Reason = 'Mock reboot workflow validation.'
        RiskClassification = 'High'
        ConfirmationLevel = 'Explicit'
        PreRebootCheckpoints = $checkpoints
        StateCaptureReferences = $stateReferences
        PendingResumeSteps = $resumeSteps
        PostRebootVerificationRequirements = $verificationRequirements
        ExpirationMinutes = 60
        CancellationEligible = $true
        RecoveryInstructions = 'Open BoostLab and review the recorded workflow.'
        UserWarningText = 'This mocked plan represents a restart request.'
        ActionPlan = $actionPlan
        Policy = $testPolicy
    }

    $unconfirmedPlan = New-BoostLabRebootWorkflowPlan `
        @baseArguments `
        -Confirmed:$false
    if ($unconfirmedPlan.IsAllowed) {
        $errors.Add('Reboot planning without confirmation was not denied.')
    }

    $missingCheckpointArguments = $baseArguments.Clone()
    $missingCheckpointArguments['PreRebootCheckpoints'] = @($checkpoints[0])
    $missingCheckpointPlan = New-BoostLabRebootWorkflowPlan `
        @missingCheckpointArguments `
        -Confirmed:$true
    if ($missingCheckpointPlan.IsAllowed) {
        $errors.Add('Reboot planning without required checkpoints was allowed.')
    }

    $missingStateArguments = $baseArguments.Clone()
    $missingStateArguments['StateCaptureReferences'] = @()
    $missingStatePlan = New-BoostLabRebootWorkflowPlan `
        @missingStateArguments `
        -Confirmed:$true
    if ($missingStatePlan.IsAllowed) {
        $errors.Add('Reboot planning without required state was allowed.')
    }

    $commandStep = $resumeSteps[0] | Select-Object *
    Add-Member `
        -InputObject $commandStep `
        -NotePropertyName CommandLine `
        -NotePropertyValue 'untrusted-command --argument'
    $commandArguments = $baseArguments.Clone()
    $commandArguments['PendingResumeSteps'] = @($commandStep)
    $commandPlan = New-BoostLabRebootWorkflowPlan `
        @commandArguments `
        -Confirmed:$true
    if ($commandPlan.IsAllowed) {
        $errors.Add('Arbitrary resume command strings were not denied.')
    }

    $untrustedStep = $resumeSteps[0] | Select-Object *
    $untrustedStep.ResumeArtifactPath = Join-Path $tempRoot 'Untrusted\resume.ps1'
    $untrustedArguments = $baseArguments.Clone()
    $untrustedArguments['PendingResumeSteps'] = @($untrustedStep)
    $untrustedPlan = New-BoostLabRebootWorkflowPlan `
        @untrustedArguments `
        -Confirmed:$true
    if ($untrustedPlan.IsAllowed) {
        $errors.Add('Untrusted resume artifact path was not denied.')
    }

    $validPlan = New-BoostLabRebootWorkflowPlan `
        @baseArguments `
        -Confirmed:$true
    if (
        -not $validPlan.IsAllowed -or
        $validPlan.Status -ne 'Allowed' -or
        -not $validPlan.IsDryRun -or
        -not $validPlan.RequiresExplicitConfirmation -or
        -not $validPlan.ImmediateRebootRequested -or
        -not $validPlan.PostRebootContinuationRequired
    ) {
        $errors.Add(
            'Valid mocked reboot workflow plan was rejected: ' +
            ($validPlan.Errors -join '; ')
        )
    }

    $manualArguments = $baseArguments.Clone()
    $manualArguments['RebootType'] = 'ManualRebootRequired'
    $manualArguments['PendingResumeSteps'] = @()
    $manualPlan = New-BoostLabRebootWorkflowPlan `
        @manualArguments `
        -Confirmed:$true
    if (
        -not $manualPlan.IsAllowed -or
        -not $manualPlan.ManualRebootRequired -or
        $manualPlan.ImmediateRebootRequested
    ) {
        $errors.Add('Manual reboot was not distinguished from immediate reboot.')
    }

    $record = New-BoostLabRebootWorkflowRecord -Plan $validPlan
    if (
        $record.WorkflowStatus -ne 'PendingResume' -or
        $record.Cancelled -or
        @($record.PendingResumeSteps).Count -ne 1
    ) {
        $errors.Add('Mock workflow record did not preserve resume state.')
    }
    $saved = Save-BoostLabRebootWorkflowRecord `
        -Record $record `
        -StateRoot $stateRoot
    $imported = Import-BoostLabRebootWorkflowRecord `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot
    if (-not $imported.IsValid) {
        $errors.Add(
            'Saved workflow record failed integrity validation: ' +
            ($imported.Errors -join '; ')
        )
    }
    $recordValidation = Test-BoostLabRebootWorkflowRecord `
        -Record $imported.Record `
        -ExpectedToolId 'mock-reboot-tool' `
        -ExpectedActionId 'Apply' `
        -Policy $testPolicy
    if (-not $recordValidation.IsValid) {
        $errors.Add(
            'Mock workflow record was rejected: ' +
            ($recordValidation.Errors -join '; ')
        )
    }

    $resumePlan = New-BoostLabRebootResumePlan `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-reboot-tool' `
        -ActionId 'Apply' `
        -MachineStateValidator {
            param($WorkflowRecord)
            [pscustomobject]@{
                IsMatch = $true
                Details = 'Mock machine state matches.'
            }
        } `
        -Policy $testPolicy
    if (
        -not $resumePlan.IsAllowed -or
        $resumePlan.Status -ne 'Allowed' -or
        @($resumePlan.PendingResumeSteps).Count -ne 1
    ) {
        $errors.Add(
            'Valid mocked resume workflow was rejected: ' +
            ($resumePlan.Errors -join '; ')
        )
    }

    $stateMismatchPlan = New-BoostLabRebootResumePlan `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-reboot-tool' `
        -ActionId 'Apply' `
        -MachineStateValidator {
            [pscustomobject]@{
                IsMatch = $false
                Details = 'Mock machine state drift.'
            }
        } `
        -Policy $testPolicy
    if ($stateMismatchPlan.IsAllowed) {
        $errors.Add('Resume with machine-state drift was not refused.')
    }

    $missingRecordPlan = New-BoostLabRebootResumePlan `
        -RecordPath (Join-Path $stateRoot 'Records\missing.json') `
        -StateRoot $stateRoot `
        -ToolId 'mock-reboot-tool' `
        -ActionId 'Apply' `
        -MachineStateValidator { [pscustomobject]@{ IsMatch = $true } } `
        -Policy $testPolicy
    if ($missingRecordPlan.IsAllowed) {
        $errors.Add('Resume without a workflow record was not denied.')
    }

    $mismatchedResume = New-BoostLabRebootResumePlan `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'different-tool' `
        -ActionId 'Apply' `
        -MachineStateValidator { [pscustomobject]@{ IsMatch = $true } } `
        -Policy $testPolicy
    if ($mismatchedResume.IsAllowed) {
        $errors.Add('Resume with mismatched identity was not denied.')
    }

    $expiredRecord = $record | Select-Object *
    $expiredRecord.OperationId = [guid]::NewGuid().ToString()
    $expiredRecord.ExpiresAt = (Get-Date).AddMinutes(-5).ToUniversalTime().ToString('o')
    $expiredSaved = Save-BoostLabRebootWorkflowRecord `
        -Record $expiredRecord `
        -StateRoot $stateRoot
    $expiredPlan = New-BoostLabRebootResumePlan `
        -RecordPath $expiredSaved.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-reboot-tool' `
        -ActionId 'Apply' `
        -MachineStateValidator { [pscustomobject]@{ IsMatch = $true } } `
        -Policy $testPolicy
    if ($expiredPlan.IsAllowed) {
        $errors.Add('Expired workflow record was not denied.')
    }

    $corruptPath = Join-Path $stateRoot 'Records\corrupt.json'
    Copy-Item -LiteralPath $saved.RecordPath -Destination $corruptPath
    $corruptText = Get-Content -LiteralPath $corruptPath -Raw
    $corruptText = $corruptText.Replace(
        'Mock reboot workflow validation.',
        'Tampered reboot workflow.'
    )
    Set-Content -LiteralPath $corruptPath -Value $corruptText -Encoding UTF8
    $corruptPlan = New-BoostLabRebootResumePlan `
        -RecordPath $corruptPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-reboot-tool' `
        -ActionId 'Apply' `
        -MachineStateValidator { [pscustomobject]@{ IsMatch = $true } } `
        -Policy $testPolicy
    if ($corruptPlan.IsAllowed) {
        $errors.Add('Corrupt workflow record was not denied.')
    }

    $rebootResult = Invoke-BoostLabRebootRequest `
        -Plan $validPlan `
        -ActionPlan $actionPlan `
        -Confirmed:$true `
        -Policy $testPolicy
    if (
        $rebootResult.Status -ne 'NotImplemented' -or
        $rebootResult.RebootInitiated -or
        $rebootResult.ScheduleCreated
    ) {
        $errors.Add('Phase 40 reboot request helper was not inert.')
    }
    $scheduleResult = Register-BoostLabPostRebootResume `
        -Plan $validPlan `
        -ActionPlan $actionPlan `
        -Confirmed:$true `
        -Policy $testPolicy
    if (
        $scheduleResult.Status -ne 'NotImplemented' -or
        $scheduleResult.RebootInitiated -or
        $scheduleResult.ScheduleCreated
    ) {
        $errors.Add('Phase 40 resume scheduling helper was not inert.')
    }

    $productionArguments = $baseArguments.Clone()
    $productionArguments['Policy'] = $productionPolicy
    $productionPlan = New-BoostLabRebootWorkflowPlan `
        @productionArguments `
        -Confirmed:$true
    if ($productionPlan.IsAllowed) {
        $errors.Add('Empty production reboot scopes did not deny planning.')
    }

    $cancellation = Stop-BoostLabRebootWorkflow `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-reboot-tool' `
        -ActionId 'Apply' `
        -Reason 'Mock user cancellation.' `
        -Policy $testPolicy
    if (
        -not $cancellation.Success -or
        -not $cancellation.Cancelled -or
        $cancellation.Status -ne 'Cancelled'
    ) {
        $errors.Add(
            'Eligible mocked workflow could not be cancelled: ' +
            ($cancellation.Errors -join '; ')
        )
    }
    $cancelledResume = New-BoostLabRebootResumePlan `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-reboot-tool' `
        -ActionId 'Apply' `
        -MachineStateValidator { [pscustomobject]@{ IsMatch = $true } } `
        -Policy $testPolicy
    if (
        $cancelledResume.IsAllowed -or
        [string]::IsNullOrWhiteSpace($cancelledResume.RecoveryInstructions)
    ) {
        $errors.Add(
            'Cancellation did not block resume with readable recovery guidance.'
        )
    }

    $verificationRecord = New-BoostLabRebootWorkflowRecord -Plan $validPlan
    $verificationRecord.OperationId = [guid]::NewGuid().ToString()
    $verificationSaved = Save-BoostLabRebootWorkflowRecord `
        -Record $verificationRecord `
        -StateRoot $stateRoot
    $failedVerification = Set-BoostLabRebootWorkflowVerification `
        -RecordPath $verificationSaved.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-reboot-tool' `
        -ActionId 'Apply' `
        -VerificationResult ([pscustomobject]@{
            Status = 'Failed'
            ExpectedState = 'Mock post-reboot state'
            DetectedState = 'Unexpected mock state'
            Checks = @(
                [pscustomobject]@{
                    Name = 'MockState'
                    Expected = 'Ready'
                    Actual = 'NotReady'
                    Status = 'Failed'
                    Message = 'Mock post-reboot verification failed.'
                }
            )
            Message = 'Mock verification failure.'
            Timestamp = Get-Date
        }) `
        -Policy $testPolicy
    if (
        $failedVerification.Success -or
        $failedVerification.Status -ne 'Failed' -or
        [string]::IsNullOrWhiteSpace(
            $failedVerification.RecoveryInstructions
        )
    ) {
        $errors.Add(
            'Failed post-reboot verification was not reported structurally.'
        )
    }

    foreach ($corePath in @($workflowModulePath, $executionModulePath)) {
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
            'Restart-Computer'
            'Stop-Computer'
            'shutdown.exe'
            'schtasks.exe'
            'Register-ScheduledTask'
            'New-ScheduledTask'
            'New-ScheduledTaskAction'
            'New-ScheduledTaskTrigger'
            'bcdedit.exe'
            'Set-ItemProperty'
            'New-ItemProperty'
            'Start-Process'
            'Invoke-Expression'
        )) {
            if ($forbiddenCommand -in $commandNames) {
                $errors.Add(
                    "Phase 40 helper contains forbidden command: " +
                    "$forbiddenCommand"
                )
            }
        }
    }

    $runtimeText = Get-Content -LiteralPath $runtimeExecutionPath -Raw
    if (
        $runtimeText.Contains('RebootWorkflow.psm1') -or
        $runtimeText.Contains('RebootExecution.psm1')
    ) {
        $errors.Add('Phase 40 helpers were wired into live tool execution.')
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
    if ($allTools.Count -ne 50) {
        $errors.Add("Expected 50 active tools, found $($allTools.Count).")
    }
    if ($placeholderModules.Count -ne 18) {
        $errors.Add(
            "Expected 18 placeholder modules, found $($placeholderModules.Count)."
        )
    }
    if (($allTools.Count - $placeholderModules.Count) -ne 32) {
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
    Remove-Module RebootExecution -ErrorAction SilentlyContinue
    Remove-Module RebootWorkflow -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}

if ($errors.Count -gt 0) {
    throw "Reboot recovery validation failed:`r`n- $($errors -join "`r`n- ")"
}

[pscustomobject]@{
    Success                 = $true
    ProductionScopeCount    = 0
    MockPlanValidated       = $true
    MockResumeValidated     = $true
    CancellationValidated   = $true
    RealRebootInitiated     = $false
    RealScheduleCreated     = $false
    ActiveToolCount         = 50
    ImplementedToolCount    = 32
    PlaceholderToolCount    = 18
    SourceUltimateUnchanged = $true
    Message                 = 'Reboot and recovery workflow foundation is deny-by-default and non-executing.'
    Timestamp               = Get-Date
}

