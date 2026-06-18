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
        throw 'Unable to determine the Safe Mode recovery policy test path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$policyPath = Join-Path $ProjectRoot 'config\SafeModeRecoveryPolicy.psd1'
$workflowModulePath = Join-Path $ProjectRoot 'core\SafeModeWorkflow.psm1'
$executionModulePath = Join-Path $ProjectRoot 'core\SafeModeExecution.psm1'
$policyDocPath = Join-Path $ProjectRoot 'docs\safe-mode-recovery-resume.md'
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
        $errors.Add("Required Phase 43 file is missing: $requiredPath")
    }
}
if ($errors.Count -gt 0) {
    throw "Safe Mode validation failed:`r`n- $($errors -join "`r`n- ")"
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
    ("BoostLab-SafeModeTest-{0}" -f [guid]::NewGuid())
$stateRoot = Join-Path $tempRoot 'SafeModeState'
$captureRoot = Join-Path $tempRoot 'CapturedState'
$rebootRoot = Join-Path $tempRoot 'RebootState'
$resumeRoot = Join-Path $tempRoot 'ResumeArtifacts'
$exitRoot = Join-Path $tempRoot 'ExitArtifacts'
$captureRecord = Join-Path $captureRoot 'capture.json'
$serviceRecord = Join-Path $captureRoot 'service.json'
$rebootRecord = Join-Path $rebootRoot 'reboot.json'
$resumeArtifact = Join-Path $resumeRoot 'resume.metadata'
$exitArtifact = Join-Path $exitRoot 'exit.metadata'
foreach ($directory in @(
    $captureRoot
    $rebootRoot
    $resumeRoot
    $exitRoot
)) {
    [IO.Directory]::CreateDirectory($directory) | Out-Null
}
[IO.File]::WriteAllText($captureRecord, '{"verified":true}')
[IO.File]::WriteAllText($serviceRecord, '{"verified":true}')
[IO.File]::WriteAllText($rebootRecord, '{"verified":true}')
[IO.File]::WriteAllText($resumeArtifact, 'mock resume metadata')
[IO.File]::WriteAllText($exitArtifact, 'mock exit metadata')

try {
    foreach ($commandName in @(
        'Get-BoostLabSafeModeRecoveryPolicy'
        'Get-BoostLabSafeModeRecoveryStateRoot'
        'Test-BoostLabSafeModeRecoveryPolicy'
        'Test-BoostLabSafeModeWorkflowTarget'
        'New-BoostLabSafeModeWorkflowPlan'
        'New-BoostLabSafeModeWorkflowRecord'
        'Save-BoostLabSafeModeWorkflowRecord'
        'Import-BoostLabSafeModeWorkflowRecord'
        'Test-BoostLabSafeModeWorkflowRecord'
        'Stop-BoostLabSafeModeWorkflow'
        'New-BoostLabSafeModeResumePlan'
        'New-BoostLabSafeModeExitPlan'
        'Set-BoostLabSafeModeWorkflowVerification'
        'Test-BoostLabSafeModeExecutionRequest'
        'Invoke-BoostLabSafeModeEntryRequest'
        'Register-BoostLabSafeModeResume'
        'Invoke-BoostLabSafeModeExitRequest'
    )) {
        if (-not (Get-Command -Name $commandName -ErrorAction SilentlyContinue)) {
            $errors.Add("Phase 43 helper is not exported: $commandName")
        }
    }

    $productionPolicy = Get-BoostLabSafeModeRecoveryPolicy `
        -PolicyPath $policyPath
    $productionValidation = Test-BoostLabSafeModeRecoveryPolicy `
        -Policy $productionPolicy
    if (-not $productionValidation.IsValid) {
        $errors.Add(
            'Production Safe Mode policy is invalid: ' +
            ($productionValidation.Errors -join '; ')
        )
    }
    if ($productionValidation.ScopeCount -ne 0) {
        $errors.Add('Phase 43 must not approve production Safe Mode scopes.')
    }

    $testPolicy = @{
        SchemaVersion = '1.0'
        MaxRecordAgeDays = 7
        SafeModeScopes = @(
            @{
                ScopeId = 'mock-safe-mode-scope'
                ToolIds = @('mock-safe-mode-tool')
                ActionIds = @('Apply')
                AllowedSafeModeTypes = @('Minimal', 'Networking')
                RequiredCheckpointNames = @(
                    'StateCaptured'
                    'RebootReady'
                )
                RequiredFoundations = @(
                    'Rollback'
                    'ServiceRollback'
                )
                AllowedStateReferenceRoots = @($captureRoot)
                AllowedRebootWorkflowScopeIds = @('mock-reboot-workflow')
                AllowedRebootRecordRoots = @($rebootRoot)
                AllowedResumeHandlerIds = @('mock-safe-resume')
                AllowedResumeArtifactPaths = @($resumeArtifact)
                AllowedExitHandlerIds = @('mock-safe-exit')
                AllowedExitArtifactPaths = @($exitArtifact)
                RequiresStateCapture = $true
                RequiresRebootWorkflowReference = $true
                RequiresExitPlan = $true
                RequiresPostResumeVerification = $true
                AllowCommandShell = $false
                MaxResumeSteps = 3
                MaxExitSteps = 2
                MaxDurationMinutes = 120
                AllowCancellation = $true
                RequiredConfirmationLevel = 'Explicit'
                NeedsExplicitConfirmation = $true
            }
        )
    }
    $testValidation = Test-BoostLabSafeModeRecoveryPolicy -Policy $testPolicy
    if (-not $testValidation.IsValid -or $testValidation.ScopeCount -ne 1) {
        $errors.Add(
            'Mock Safe Mode policy was rejected: ' +
            ($testValidation.Errors -join '; ')
        )
    }

    $actionPlan = [pscustomobject]@{
        ToolId = 'mock-safe-mode-tool'
        Action = 'Apply'
        RiskLevel = 'High'
        UsesSafeMode = $true
        NeedsExplicitConfirmation = $true
    }
    $checkpoints = @(
        [pscustomobject]@{
            Name = 'StateCaptured'
            Status = 'Passed'
            Evidence = 'Mock rollback records verified.'
        }
        [pscustomobject]@{
            Name = 'RebootReady'
            Status = 'Passed'
            Evidence = 'Mock Phase 40 record verified.'
        }
    )
    $stateReferences = @(
        [pscustomobject]@{
            ReferenceId = 'mock-file-registry-state'
            Foundation = 'Rollback'
            RecordPath = $captureRecord
            RecordHash = (
                Get-FileHash -LiteralPath $captureRecord -Algorithm SHA256
            ).Hash
            Verified = $true
        }
        [pscustomobject]@{
            ReferenceId = 'mock-service-state'
            Foundation = 'ServiceRollback'
            RecordPath = $serviceRecord
            RecordHash = (
                Get-FileHash -LiteralPath $serviceRecord -Algorithm SHA256
            ).Hash
            Verified = $true
        }
    )
    $rebootReference = [pscustomobject]@{
        ReferenceId = 'mock-phase40-record'
        ScopeId = 'mock-reboot-workflow'
        RecordPath = $rebootRecord
        RecordHash = (
            Get-FileHash -LiteralPath $rebootRecord -Algorithm SHA256
        ).Hash
        Verified = $true
        ToolId = 'mock-safe-mode-tool'
        ActionId = 'Apply'
        RequestedRebootType = 'SafeModeReboot'
    }
    $resumeSteps = @(
        [pscustomobject]@{
            StepId = 'validate-safe-mode-state'
            Order = 1
            HandlerId = 'mock-safe-resume'
            Description = 'Validate the mocked Safe Mode state.'
            ResumeArtifactPath = $resumeArtifact
            ExpectedConditions = @('Mock Safe Mode condition is present.')
            VerificationRequirements = @('Mock condition reports Passed.')
        }
    )
    $exitSteps = @(
        [pscustomobject]@{
            StepId = 'validate-safe-mode-exit'
            Order = 1
            HandlerId = 'mock-safe-exit'
            Description = 'Validate the mocked Safe Mode exit plan.'
            ExitArtifactPath = $exitArtifact
            ExpectedConditions = @('Mock exit condition is ready.')
            VerificationRequirements = @('Mock exit reports Passed.')
            RecoveryInstructions = 'Use documented mock recovery guidance.'
        }
    )
    $verificationRequirements = @(
        'Verify the mocked post-resume condition.'
        'Verify the mocked exit condition.'
    )
    $baseArguments = @{
        ToolId = 'mock-safe-mode-tool'
        ActionId = 'Apply'
        ScopeId = 'mock-safe-mode-scope'
        SafeModeType = 'Minimal'
        Reason = 'Mock Safe Mode foundation validation.'
        RiskClassification = 'High'
        ConfirmationLevel = 'Explicit'
        PreSafeModeCheckpoints = $checkpoints
        StateCaptureReferences = $stateReferences
        RebootWorkflowReference = $rebootReference
        PlannedResumeSteps = $resumeSteps
        PlannedExitStrategy = $exitSteps
        PostResumeVerificationRequirements = $verificationRequirements
        ExpirationMinutes = 60
        CancellationEligible = $true
        RecoveryInstructions = (
            'Open BoostLab normally and review the Safe Mode workflow record.'
        )
        UserWarningText = (
            'This mocked workflow represents a future Safe Mode restart.'
        )
        ActionPlan = $actionPlan
        Policy = $testPolicy
    }

    foreach ($targetCase in @(
        @{
            Name = 'unknown tool'
            ToolId = 'unknown-tool'
            ActionId = 'Apply'
        }
        @{
            Name = 'unknown action'
            ToolId = 'mock-safe-mode-tool'
            ActionId = 'UnknownAction'
        }
    )) {
        $target = Test-BoostLabSafeModeWorkflowTarget `
            -ToolId $targetCase.ToolId `
            -ActionId $targetCase.ActionId `
            -ScopeId 'mock-safe-mode-scope' `
            -SafeModeType Minimal `
            -Policy $testPolicy
        if ($target.IsAllowed) {
            $errors.Add("Safe Mode $($targetCase.Name) was not denied.")
        }
    }

    $unconfirmed = New-BoostLabSafeModeWorkflowPlan `
        @baseArguments `
        -Confirmed:$false
    if ($unconfirmed.IsAllowed) {
        $errors.Add('Safe Mode planning without confirmation was not denied.')
    }

    $missingRebootArguments = $baseArguments.Clone()
    $missingRebootArguments['RebootWorkflowReference'] = $null
    $missingReboot = New-BoostLabSafeModeWorkflowPlan `
        @missingRebootArguments `
        -Confirmed:$true
    if ($missingReboot.IsAllowed) {
        $errors.Add('Safe Mode planning without Phase 40 reference was allowed.')
    }

    $missingCheckpointArguments = $baseArguments.Clone()
    $missingCheckpointArguments['PreSafeModeCheckpoints'] = @($checkpoints[0])
    $missingCheckpoint = New-BoostLabSafeModeWorkflowPlan `
        @missingCheckpointArguments `
        -Confirmed:$true
    if ($missingCheckpoint.IsAllowed) {
        $errors.Add('Safe Mode planning without checkpoints was allowed.')
    }

    $missingExitArguments = $baseArguments.Clone()
    $missingExitArguments['PlannedExitStrategy'] = @()
    $missingExit = New-BoostLabSafeModeWorkflowPlan `
        @missingExitArguments `
        -Confirmed:$true
    if ($missingExit.IsAllowed) {
        $errors.Add('Safe Mode planning without an exit strategy was allowed.')
    }

    $rawStep = $resumeSteps[0] | Select-Object *
    Add-Member `
        -InputObject $rawStep `
        -NotePropertyName CommandLine `
        -NotePropertyValue 'bcdedit.exe /set safeboot minimal'
    $rawArguments = $baseArguments.Clone()
    $rawArguments['PlannedResumeSteps'] = @($rawStep)
    $rawPlan = New-BoostLabSafeModeWorkflowPlan `
        @rawArguments `
        -Confirmed:$true
    if ($rawPlan.IsAllowed) {
        $errors.Add('Arbitrary Safe Mode command strings were not denied.')
    }

    $untrustedStep = $resumeSteps[0] | Select-Object *
    $untrustedStep.ResumeArtifactPath = Join-Path $tempRoot 'Untrusted\resume.ps1'
    $untrustedArguments = $baseArguments.Clone()
    $untrustedArguments['PlannedResumeSteps'] = @($untrustedStep)
    $untrustedPlan = New-BoostLabSafeModeWorkflowPlan `
        @untrustedArguments `
        -Confirmed:$true
    if ($untrustedPlan.IsAllowed) {
        $errors.Add('Untrusted Safe Mode resume path was not denied.')
    }

    $validPlan = New-BoostLabSafeModeWorkflowPlan `
        @baseArguments `
        -Confirmed:$true
    if (
        -not $validPlan.IsAllowed -or
        $validPlan.Status -ne 'Allowed' -or
        -not $validPlan.IsDryRun -or
        -not $validPlan.EntrySchedulingRequested -or
        @($validPlan.PlannedResumeSteps).Count -ne 1 -or
        @($validPlan.PlannedExitStrategy).Count -ne 1
    ) {
        $errors.Add(
            'Valid mocked Safe Mode plan was rejected: ' +
            ($validPlan.Errors -join '; ')
        )
    }

    $productionArguments = $baseArguments.Clone()
    $productionArguments['Policy'] = $productionPolicy
    $productionPlan = New-BoostLabSafeModeWorkflowPlan `
        @productionArguments `
        -Confirmed:$true
    if ($productionPlan.IsAllowed) {
        $errors.Add('Empty production Safe Mode scopes did not deny planning.')
    }

    $record = New-BoostLabSafeModeWorkflowRecord -Plan $validPlan
    $saved = Save-BoostLabSafeModeWorkflowRecord `
        -Record $record `
        -StateRoot $stateRoot
    $imported = Import-BoostLabSafeModeWorkflowRecord `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot
    if (-not $imported.IsValid) {
        $errors.Add(
            'Saved Safe Mode record failed integrity validation: ' +
            ($imported.Errors -join '; ')
        )
    }
    $recordValidation = Test-BoostLabSafeModeWorkflowRecord `
        -Record $imported.Record `
        -ExpectedToolId 'mock-safe-mode-tool' `
        -ExpectedActionId 'Apply' `
        -Policy $testPolicy
    if (-not $recordValidation.IsValid) {
        $errors.Add(
            'Mock Safe Mode workflow record was rejected: ' +
            ($recordValidation.Errors -join '; ')
        )
    }

    $resume = New-BoostLabSafeModeResumePlan `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-safe-mode-tool' `
        -ActionId 'Apply' `
        -MachineStateValidator {
            [pscustomobject]@{
                IsMatch = $true
                Details = 'Mock Safe Mode state matches.'
            }
        } `
        -Policy $testPolicy
    if (
        -not $resume.IsAllowed -or
        @($resume.PlannedResumeSteps).Count -ne 1 -or
        @($resume.PlannedExitStrategy).Count -ne 1
    ) {
        $errors.Add(
            'Valid mocked Safe Mode resume was rejected: ' +
            ($resume.Errors -join '; ')
        )
    }

    $exit = New-BoostLabSafeModeExitPlan `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-safe-mode-tool' `
        -ActionId 'Apply' `
        -MachineStateValidator {
            [pscustomobject]@{
                IsMatch = $true
                Details = 'Mock exit state matches.'
            }
        } `
        -Policy $testPolicy
    if (-not $exit.IsAllowed -or @($exit.PlannedExitStrategy).Count -ne 1) {
        $errors.Add(
            'Valid mocked Safe Mode exit was rejected: ' +
            ($exit.Errors -join '; ')
        )
    }

    $stateMismatch = New-BoostLabSafeModeResumePlan `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-safe-mode-tool' `
        -ActionId 'Apply' `
        -MachineStateValidator {
            [pscustomobject]@{
                IsMatch = $false
                Details = 'Mock Safe Mode state drift.'
            }
        } `
        -Policy $testPolicy
    if ($stateMismatch.IsAllowed) {
        $errors.Add('Safe Mode resume with state drift was not refused.')
    }

    $missingRecord = New-BoostLabSafeModeResumePlan `
        -RecordPath (Join-Path $stateRoot 'Records\missing.json') `
        -StateRoot $stateRoot `
        -ToolId 'mock-safe-mode-tool' `
        -ActionId 'Apply' `
        -MachineStateValidator { [pscustomobject]@{ IsMatch = $true } } `
        -Policy $testPolicy
    if ($missingRecord.IsAllowed) {
        $errors.Add('Safe Mode resume without a record was not denied.')
    }

    $mismatched = New-BoostLabSafeModeResumePlan `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'different-tool' `
        -ActionId 'Apply' `
        -MachineStateValidator { [pscustomobject]@{ IsMatch = $true } } `
        -Policy $testPolicy
    if ($mismatched.IsAllowed) {
        $errors.Add('Mismatched Safe Mode workflow identity was not denied.')
    }

    $expiredRecord = $record | Select-Object *
    $expiredRecord.OperationId = [guid]::NewGuid().ToString()
    $expiredRecord.ExpiresAt = (
        Get-Date
    ).AddMinutes(-5).ToUniversalTime().ToString('o')
    $expiredSaved = Save-BoostLabSafeModeWorkflowRecord `
        -Record $expiredRecord `
        -StateRoot $stateRoot
    $expired = New-BoostLabSafeModeResumePlan `
        -RecordPath $expiredSaved.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-safe-mode-tool' `
        -ActionId 'Apply' `
        -MachineStateValidator { [pscustomobject]@{ IsMatch = $true } } `
        -Policy $testPolicy
    if ($expired.IsAllowed) {
        $errors.Add('Expired Safe Mode workflow record was not denied.')
    }

    $corruptPath = Join-Path $stateRoot 'Records\corrupt.json'
    [IO.File]::Copy($saved.RecordPath, $corruptPath)
    $corruptText = [IO.File]::ReadAllText($corruptPath).Replace(
        'Mock Safe Mode foundation validation.',
        'Tampered Safe Mode workflow.'
    )
    [IO.File]::WriteAllText($corruptPath, $corruptText)
    $corrupt = New-BoostLabSafeModeResumePlan `
        -RecordPath $corruptPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-safe-mode-tool' `
        -ActionId 'Apply' `
        -MachineStateValidator { [pscustomobject]@{ IsMatch = $true } } `
        -Policy $testPolicy
    if ($corrupt.IsAllowed) {
        $errors.Add('Corrupt Safe Mode workflow record was not denied.')
    }

    $entryResult = Invoke-BoostLabSafeModeEntryRequest `
        -Plan $validPlan `
        -ActionPlan $actionPlan `
        -Confirmed:$true `
        -Policy $testPolicy
    $scheduleResult = Register-BoostLabSafeModeResume `
        -Plan $validPlan `
        -ActionPlan $actionPlan `
        -Confirmed:$true `
        -Policy $testPolicy
    $exitResult = Invoke-BoostLabSafeModeExitRequest `
        -Plan $validPlan `
        -ActionPlan $actionPlan `
        -Confirmed:$true `
        -Policy $testPolicy
    foreach ($result in @($entryResult, $scheduleResult, $exitResult)) {
        if (
            $result.Status -ne 'NotImplemented' -or
            $result.SafeModeConfigured -or
            $result.BcdModified -or
            $result.RebootInitiated -or
            $result.ScheduleCreated -or
            $result.ServiceChanged -or
            $result.TrustedInstallerUsed -or
            $result.ProtectedTargetModified
        ) {
            $errors.Add('Phase 43 execution helper was not inert.')
        }
    }

    $cancellation = Stop-BoostLabSafeModeWorkflow `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-safe-mode-tool' `
        -ActionId 'Apply' `
        -Reason 'Mock technician cancellation.' `
        -Policy $testPolicy
    if (
        -not $cancellation.Success -or
        -not $cancellation.Cancelled -or
        $cancellation.Status -ne 'Cancelled'
    ) {
        $errors.Add(
            'Eligible mocked Safe Mode workflow could not be cancelled: ' +
            ($cancellation.Errors -join '; ')
        )
    }
    $cancelledResume = New-BoostLabSafeModeResumePlan `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-safe-mode-tool' `
        -ActionId 'Apply' `
        -MachineStateValidator { [pscustomobject]@{ IsMatch = $true } } `
        -Policy $testPolicy
    if (
        $cancelledResume.IsAllowed -or
        [string]::IsNullOrWhiteSpace(
            [string]$cancelledResume.RecoveryInstructions
        )
    ) {
        $errors.Add(
            'Cancellation did not block future resume with recovery guidance.'
        )
    }

    $verificationRecord = New-BoostLabSafeModeWorkflowRecord -Plan $validPlan
    $verificationRecord.OperationId = [guid]::NewGuid().ToString()
    $verificationSaved = Save-BoostLabSafeModeWorkflowRecord `
        -Record $verificationRecord `
        -StateRoot $stateRoot
    $failedVerification = Set-BoostLabSafeModeWorkflowVerification `
        -RecordPath $verificationSaved.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-safe-mode-tool' `
        -ActionId 'Apply' `
        -VerificationResult ([pscustomobject]@{
            Status = 'Failed'
            ExpectedState = 'Mock normal boot and verified tool state'
            DetectedState = 'Mock state mismatch'
            Checks = @(
                [pscustomobject]@{
                    Name = 'MockPostResume'
                    Expected = 'Ready'
                    Actual = 'NotReady'
                    Status = 'Failed'
                    Message = 'Mock post-resume verification failed.'
                }
            )
            Message = 'Mock Safe Mode verification failure.'
            Timestamp = Get-Date
        }) `
        -Policy $testPolicy
    if (
        $failedVerification.Success -or
        $failedVerification.Status -ne 'Failed' -or
        [string]::IsNullOrWhiteSpace(
            [string]$failedVerification.RecoveryInstructions
        )
    ) {
        $errors.Add(
            'Failed Safe Mode verification was not reported structurally.'
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
            'bcdedit.exe'
            'shutdown.exe'
            'Restart-Computer'
            'Stop-Computer'
            'Start-Process'
            'Register-ScheduledTask'
            'New-ScheduledTask'
            'New-ScheduledTaskAction'
            'New-ScheduledTaskTrigger'
            'schtasks.exe'
            'New-Service'
            'Start-Service'
            'Stop-Service'
            'Set-Service'
            'Restart-Service'
            'sc.exe'
            'Set-ItemProperty'
            'New-ItemProperty'
            'Remove-ItemProperty'
            'Set-Acl'
            'takeown.exe'
            'icacls.exe'
            'Invoke-WebRequest'
            'Invoke-RestMethod'
            'Invoke-Expression'
            'Invoke-BoostLabTrustedInstallerRequest'
        )) {
            if ($forbiddenCommand -in $commandNames) {
                $errors.Add(
                    "Phase 43 helper contains forbidden command: " +
                    $forbiddenCommand
                )
            }
        }
    }

    $runtimeText = Get-Content -LiteralPath $runtimeExecutionPath -Raw
    if (
        $runtimeText.Contains('SafeModeWorkflow.psm1') -or
        $runtimeText.Contains('SafeModeExecution.psm1') -or
        $runtimeText.Contains('Invoke-BoostLabSafeModeEntryRequest')
    ) {
        $errors.Add('Phase 43 helpers were wired into live tool execution.')
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
    if ($allTools.Count -ne 55) {
        $errors.Add("Expected 55 active tools, found $($allTools.Count).")
    }
    if ($placeholderModules.Count -ne 17) {
        $errors.Add(
            "Expected 17 placeholder modules, found $($placeholderModules.Count)."
        )
    }
    if (($allTools.Count - $placeholderModules.Count) -ne 38) {
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
    Remove-Module SafeModeExecution -ErrorAction SilentlyContinue
    Remove-Module SafeModeWorkflow -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}

if ($errors.Count -gt 0) {
    throw "Safe Mode validation failed:`r`n- $($errors -join "`r`n- ")"
}

[pscustomobject]@{
    Success                    = $true
    ProductionScopeCount       = 0
    MockPlanValidated          = $true
    MockResumeValidated        = $true
    MockExitValidated          = $true
    CancellationValidated      = $true
    SafeModeConfigured         = $false
    BcdModified                = $false
    RebootInitiated            = $false
    ScheduleCreated            = $false
    ServiceChanged             = $false
    TrustedInstallerUsed       = $false
    ProtectedTargetModified    = $false
    ActiveToolCount            = 55
    ImplementedToolCount       = 38
    PlaceholderToolCount       = 17
    SourceUltimateUnchanged    = $true
    Message                    = 'Safe Mode foundation is deny-by-default and non-executing.'
    Timestamp                  = Get-Date
}



