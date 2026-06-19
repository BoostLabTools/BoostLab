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
        throw 'Unable to determine the action plan test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$safetyPath = Join-Path $ProjectRoot 'core\Safety.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
$safetyModule = Import-Module -Name $safetyPath -Force -PassThru -Scope Local -ErrorAction Stop

try {
    $configuration = Import-PowerShellDataFile -LiteralPath $configPath
    $tools = @($configuration['Stages'] | ForEach-Object { $_['Tools'] })
    $requiredPlanFields = @(
        'ToolId'
        'ToolTitle'
        'Action'
        'RiskLevel'
        'Capabilities'
        'Summary'
        'PlannedChanges'
        'SideEffects'
        'RequiresAdmin'
        'UsesTrustedInstaller'
        'UsesSafeMode'
        'PrivilegeRequirements'
        'RequiresInternet'
        'CanReboot'
        'NeedsExplicitConfirmation'
        'SupportsDefault'
        'SupportsRestore'
        'ConfirmationMessage'
        'IsDryRun'
        'Timestamp'
    )

    $highRiskCount = 0
    $rebootCount = 0
    foreach ($tool in $tools) {
        $actionName = [string]@($tool['Actions'])[0]
        $plan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName $actionName

        foreach ($field in $requiredPlanFields) {
            if ($null -eq $plan.PSObject.Properties[$field]) {
                throw "$($tool['Title']) action plan is missing field: $field"
            }
        }
        if ([string]$tool['RiskLevel'] -eq 'high') {
            $highRiskCount++
            if (-not [bool]$plan.NeedsExplicitConfirmation) {
                throw "$($tool['Title']) is high risk but its plan does not require confirmation."
            }
        }
        if ([bool]$tool['Capabilities']['CanReboot']) {
            $rebootCount++
            if (-not [bool]$plan.NeedsExplicitConfirmation) {
                throw "$($tool['Title']) can reboot but its plan does not require confirmation."
            }
        }
    }

    $safeOpenToolIds = @(
        'bios-information'
        'startup-apps-settings'
        'startup-apps-task-manager'
        'graphics-configuration-center'
        'date-language-region-time'
        'game-mode'
        'pointer-precision'
        'sound'
    )
    foreach ($toolId in $safeOpenToolIds) {
        $tool = $tools | Where-Object { $_['Id'] -eq $toolId } | Select-Object -First 1
        $plan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName 'Open' -IsDryRun $false
        if ([bool]$plan.NeedsExplicitConfirmation) {
            throw "$($tool['Title']) received unnecessary Open confirmation."
        }
    }

    $biosSettings = $tools | Where-Object { $_['Id'] -eq 'bios-settings' } | Select-Object -First 1
    $biosPlan = New-BoostLabActionPlan -ToolMetadata $biosSettings -ActionName 'Open' -IsDryRun $false
    if (
        -not [bool]$biosPlan.NeedsExplicitConfirmation -or
        -not [bool]$biosPlan.CanReboot -or
        $biosPlan.ConfirmationMessage -notmatch 'restart immediately' -or
        $biosPlan.ConfirmationMessage -notmatch 'BIOS/UEFI'
    ) {
        throw 'BIOS Settings Open no longer has its explicit reboot confirmation plan.'
    }

    $blockedGate = Test-BoostLabActionPlanExecutionGate -ActionPlan $biosPlan
    if ($blockedGate.IsAllowed -or $blockedGate.Confirmed) {
        throw 'BIOS Settings action plan was allowed without confirmation.'
    }
    $declinedGate = Test-BoostLabActionPlanExecutionGate `
        -ActionPlan $biosPlan `
        -ConfirmationCallback { param($Plan) return $false }
    if ($declinedGate.IsAllowed -or -not $declinedGate.CallbackUsed) {
        throw 'A declined confirmation callback did not block the action plan.'
    }
    $confirmedGate = Test-BoostLabActionPlanExecutionGate `
        -ActionPlan $biosPlan `
        -ConfirmationCallback { param($Plan) return $true }
    if (-not $confirmedGate.IsAllowed -or -not $confirmedGate.Confirmed) {
        throw 'An approved confirmation callback did not pass the action plan gate.'
    }

    $toBios = $tools | Where-Object { $_['Id'] -eq 'to-bios' } | Select-Object -First 1
    $toBiosPlan = New-BoostLabActionPlan -ToolMetadata $toBios -ActionName 'Open' -IsDryRun $false
    if (
        -not [bool]$toBiosPlan.NeedsExplicitConfirmation -or
        -not [bool]$toBiosPlan.CanReboot -or
        $toBiosPlan.ConfirmationMessage -notmatch 'restart immediately' -or
        $toBiosPlan.ConfirmationMessage -notmatch 'BIOS/UEFI'
    ) {
        throw 'To BIOS Open does not have its explicit reboot confirmation plan.'
    }

    $capabilities = [ordered]@{}
    foreach ($field in @(
        'RequiresAdmin'
        'RequiresInternet'
        'CanReboot'
        'CanModifyRegistry'
        'CanModifyServices'
        'CanInstallSoftware'
        'CanDownload'
        'CanModifyDrivers'
        'CanModifySecurity'
        'CanDeleteFiles'
        'UsesTrustedInstaller'
        'UsesSafeMode'
        'SupportsDefault'
        'SupportsRestore'
        'NeedsExplicitConfirmation'
    )) {
        $capabilities[$field] = $false
    }
    $capabilities['RequiresAdmin'] = $true
    $capabilities['CanDeleteFiles'] = $true
    $syntheticTool = [ordered]@{
        Id = 'capability-test'
        Title = 'Capability Test'
        Stage = 'Test'
        Order = 1
        Type = 'action'
        RiskLevel = 'low'
        Description = 'Planner capability test.'
        Actions = @('Apply')
        Capabilities = $capabilities
    }
    $capabilityPlan = New-BoostLabActionPlan -ToolMetadata $syntheticTool -ActionName 'Apply'
    if (
        -not $capabilityPlan.NeedsExplicitConfirmation -or
        (@($capabilityPlan.PlannedChanges) -join ' ') -notmatch 'Delete files'
    ) {
        throw 'The planner did not use deletion capability metadata.'
    }

    $trustedInstallerTool = $tools |
        Where-Object { $_['Id'] -eq 'game-bar' } |
        Select-Object -First 1
    $trustedInstallerAction = [string]@($trustedInstallerTool['Actions'])[0]
    $trustedInstallerPlan = New-BoostLabActionPlan `
        -ToolMetadata $trustedInstallerTool `
        -ActionName $trustedInstallerAction
    $trustedInstallerText = @(
        @($trustedInstallerPlan.PrivilegeRequirements)
        @($trustedInstallerPlan.PlannedChanges)
        @($trustedInstallerPlan.SideEffects)
        $trustedInstallerPlan.ConfirmationMessage
    ) -join ' '
    if (
        -not [bool]$trustedInstallerPlan.UsesTrustedInstaller -or
        -not [bool]$trustedInstallerPlan.NeedsExplicitConfirmation -or
        $trustedInstallerText -notmatch 'TrustedInstaller' -or
        $trustedInstallerText -notmatch 'Administrator|elevated'
    ) {
        throw 'TrustedInstaller capability is not visible in the Action Plan.'
    }

    $placeholderModulePath = Join-Path $ProjectRoot 'modules\Windows\start-menu-taskbar.psm1'
    $placeholderSource = Get-Content -Raw -LiteralPath $placeholderModulePath
    if (
        -not $placeholderSource.Contains('ToolModule.Placeholder.ps1') -or
        $placeholderSource.Contains('$script:BoostLabImplementedActions')
    ) {
        throw 'The placeholder module execution boundary changed.'
    }
    $placeholderTool = $tools | Where-Object { $_['Id'] -eq 'start-menu-taskbar' } | Select-Object -First 1
    $placeholderPlan = New-BoostLabActionPlan -ToolMetadata $placeholderTool -ActionName 'Open'
    if (-not $placeholderPlan.IsDryRun) {
        throw 'Placeholder planning is not marked as a dry run.'
    }

    $executionSource = Get-Content -Raw -LiteralPath $executionPath
    foreach ($requiredText in @(
        'New-BoostLabActionPlan'
        '$isImplementedAction'
        'Placeholder actions are not executed and do not request confirmation.'
        '-NotePropertyName ''ActionPlan'''
        '-ConfirmationCallback $ConfirmationCallback'
    )) {
        if (-not $executionSource.Contains($requiredText)) {
            throw "Execution pipeline is missing action-plan behavior: $requiredText"
        }
    }

    $uiSource = Get-Content -Raw -LiteralPath $uiPath
    foreach ($requiredText in @(
        'function Show-BoostLabActionPlanConfirmation'
        '$confirmButton.Content = ''Confirm'''
        '$cancelButton.Content = ''Cancel'''
        '-ConfirmationCallback {'
        'Add-BoostLabResultSectionTitle -Panel $panel -Text ''Action Plan'''
    )) {
        if (-not $uiSource.Contains($requiredText)) {
            throw "UI is missing action-plan behavior: $requiredText"
        }
    }

    $root = (Resolve-Path -LiteralPath $ProjectRoot).Path
    $sourceLines = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
        Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
        ForEach-Object {
            '{0}|{1}' -f `
                $_.FullName.Substring($root.Length + 1).Replace('\', '/'), `
                (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
        }
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $sourceManifestHash = [BitConverter]::ToString(
            $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sourceLines -join "`n")))
        ).Replace('-', '')
    }
    finally {
        $sha256.Dispose()
    }
    if (
        @($sourceLines).Count -ne 49 -or
        $sourceManifestHash -ne '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477'
    ) {
        throw 'source-ultimate content or paths changed.'
    }

    [pscustomobject]@{
        Success                  = $true
        ToolCount                = $tools.Count
        ActionPlanFieldCount     = $requiredPlanFields.Count
        HighRiskPlanCount        = $highRiskCount
        RebootPlanCount          = $rebootCount
        SafeOpenPlanCount        = $safeOpenToolIds.Count
        PlaceholderExecutionTest = 'Static only'
        ToolActionsExecuted      = $false
        SourceUltimateUnchanged  = $true
        Message                  = 'Action planning and confirmation rules are valid without executing tool actions.'
        Timestamp                = Get-Date
    }
}
finally {
    Remove-Module -ModuleInfo $safetyModule -Force -ErrorAction SilentlyContinue
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

