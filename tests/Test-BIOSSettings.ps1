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
        throw 'Unable to determine the BIOS Settings test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Check\BIOSSettings.psm1'
$biosInformationPath = Join-Path $ProjectRoot 'modules\Check\BIOSInformation.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$runtimePath = Join-Path $ProjectRoot 'core\Execution.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$legacyPath = Join-Path $ProjectRoot 'source-ultimate\1 Check\2 BIOS Settings.ps1'
$modulesRoot = Join-Path $ProjectRoot 'modules'

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$biosTool = $configuration['Stages'] |
    ForEach-Object { $_['Tools'] } |
    Where-Object { $_['Id'] -eq 'bios-settings' } |
    Select-Object -First 1
if ($null -eq $biosTool) {
    throw 'BIOS Settings metadata was not found.'
}
if (@($biosTool['Actions']) -join ',' -ne 'Analyze,Open') {
    throw 'BIOS Settings must expose Analyze and Open only.'
}
if ($biosTool['Type'] -ne 'assistant' -or $biosTool['RiskLevel'] -ne 'high') {
    throw 'BIOS Settings must remain a high-risk assistant.'
}
$expectedDescription = 'Review BIOS setting guidance and optionally restart into BIOS/UEFI firmware settings.'
if ($biosTool['Description'] -ne $expectedDescription) {
    throw 'BIOS Settings description is incorrect.'
}

$biosModule = Import-Module `
    -Name $modulePath `
    -Force `
    -PassThru `
    -Prefix 'BiosSettingsTool' `
    -Scope Local `
    -DisableNameChecking `
    -ErrorAction Stop

try {
    $toolInfo = Get-BiosSettingsToolBoostLabToolInfo
    $compatibility = Test-BiosSettingsToolBoostLabToolCompatibility
    $analysisResult = Invoke-BiosSettingsToolBoostLabToolAction -ActionName 'Analyze'
    $cancelledOpenResult = Invoke-BiosSettingsToolBoostLabToolAction -ActionName 'Open'
    $blockedResult = Invoke-BiosSettingsToolBoostLabToolAction -ActionName 'Apply'

    if (-not $compatibility.Supported) {
        throw 'BIOS Settings compatibility must be supported for Analyze.'
    }
    if (@($toolInfo.ImplementedActions) -join ',' -ne 'Analyze,Open') {
        throw 'BIOS Settings implemented actions are incorrect.'
    }
    if (@($toolInfo.ConfirmationRequiredActions) -notcontains 'Open') {
        throw 'BIOS Settings Open is not marked as requiring confirmation.'
    }
    if ($toolInfo.ConfirmationText -notmatch 'restart immediately' -or $toolInfo.ConfirmationText -notmatch 'BIOS/UEFI') {
        throw 'BIOS Settings confirmation text does not clearly describe the restart.'
    }
    if (-not $analysisResult.Success -or $analysisResult.Message -ne 'Guidance prepared') {
        throw 'BIOS Settings Analyze did not return guidance.'
    }
    if ($null -eq $analysisResult.Data) {
        throw 'BIOS Settings Analyze did not return structured guidance.'
    }

    foreach ($field in @(
        'Guidance'
        'GuidanceLines'
        'GuidanceLineCount'
        'Warnings'
        'SourceBehavior'
        'Timestamp'
    )) {
        if ($null -eq $analysisResult.Data.PSObject.Properties[$field]) {
            throw "BIOS Settings analysis is missing field: $field"
        }
    }

    $expectedSections = [ordered]@{
        'INTEL CPU' = @(
            'ENABLE ram profile (XMP DOCP EXPO)'
            'DISABLE c-states (K CHIPS ONLY)'
            'ENABLE resizable bar (REBAR C.A.M)'
            'DISABLE i-gpu'
        )
        'AMD CPU' = @(
            'ENABLE ram profile (XMP DOCP EXPO)'
            'ENABLE precision boost overdrive (PBO)'
            'ENABLE resizable bar (REBAR C.A.M)'
            'DISABLE iommu (NEEDED FOR FACEIT)'
            'DISABLE i-gpu'
        )
        'COOLING' = @(
            'MAX pump and set fans to performance'
        )
        'MOTHERBOARD DRIVER INSTALLERS' = @(
            'DISABLE any driver installer software'
            'Asus armory crate'
            'MSI driver utility'
            'Gigabyte update utility'
            'Asrock motherboard utility'
        )
    }
    foreach ($sectionTitle in $expectedSections.Keys) {
        $section = $analysisResult.Data.Guidance |
            Where-Object { $_.Title -eq $sectionTitle } |
            Select-Object -First 1
        if ($null -eq $section) {
            throw "BIOS Settings guidance is missing section: $sectionTitle"
        }
        $actualInstructions = @($section.Instructions) -join '|'
        $expectedInstructions = @($expectedSections[$sectionTitle]) -join '|'
        if ($actualInstructions -ne $expectedInstructions) {
            throw "BIOS Settings guidance differs from Ultimate for section: $sectionTitle"
        }
    }

    if ($cancelledOpenResult.Success -or -not $cancelledOpenResult.Cancelled) {
        throw 'BIOS Settings Open did not cancel safely without confirmation.'
    }
    if ($cancelledOpenResult.Message -ne 'Cancelled by user') {
        throw 'BIOS Settings cancellation message is incorrect.'
    }
    if ($blockedResult.Success) {
        throw 'BIOS Settings allowed an unsupported action.'
    }

    $moduleSource = Get-Content -Raw -LiteralPath $modulePath
    foreach ($requiredText in @(
        '[bool]$Confirmed = $false'
        '$commandProcessorPath = Join-Path $env:SystemRoot ''System32\cmd.exe'''
        '$shutdownPath = Join-Path $env:SystemRoot ''System32\shutdown.exe'''
        '$firmwareRestartCommand = "`"$shutdownPath`" /r /fw /t 0"'
        '& $commandProcessorPath @firmwareRestartArguments'
    )) {
        if (-not $moduleSource.Contains($requiredText)) {
            throw "BIOS Settings firmware behavior is missing: $requiredText"
        }
    }
    foreach ($forbiddenText in @(
        'https://www.google.com/search?q='
        '[System.Uri]::EscapeDataString'
        'Start-Process $searchUrl'
        'Invoke-WebRequest'
        'Invoke-RestMethod'
        'Start-BitsTransfer'
        'bcdedit'
        'source-ultimate'
    )) {
        if ($moduleSource.Contains($forbiddenText)) {
            throw "BIOS Settings contains forbidden behavior: $forbiddenText"
        }
    }

    $runtimeSource = Get-Content -Raw -LiteralPath $runtimePath
    foreach ($requiredLog in @(
        '[BIOS Settings] [Open] restart to BIOS/UEFI requested'
        '[BIOS Settings] [Open] cancelled by user'
        'Test-BoostLabActionPlanExecutionGate'
        '-ConfirmationCallback $ConfirmationCallback'
        '-Confirmed:([bool]$safetyGate.Confirmed)'
        'Original Ultimate BIOS settings guidance:'
    )) {
        if (-not $runtimeSource.Contains($requiredLog)) {
            throw "BIOS Settings runtime behavior is missing: $requiredLog"
        }
    }

    $uiSource = Get-Content -Raw -LiteralPath $uiPath
    $actionPlanSource = Get-Content -Raw -LiteralPath $actionPlanPath
    if (
        -not $actionPlanSource.Contains('This PC will restart immediately and attempt to enter BIOS/UEFI firmware settings.') -or
        -not $uiSource.Contains('function Show-BoostLabActionPlanConfirmation') -or
        -not $uiSource.Contains('$confirmButton.Content = ''Confirm''') -or
        -not $uiSource.Contains('$cancelButton.Content = ''Cancel''') -or
        -not $uiSource.Contains('-ConfirmationCallback {')
    ) {
        throw 'BIOS Settings generic action-plan confirmation is missing.'
    }

    $biosInformationSource = Get-Content -Raw -LiteralPath $biosInformationPath
    foreach ($requiredText in @(
        '[System.Uri]::EscapeDataString'
        'https://www.google.com/search?q='
        'Start-Process $searchUrl'
    )) {
        if (-not $biosInformationSource.Contains($requiredText)) {
            throw "BIOS Information search behavior changed: $requiredText"
        }
    }

    $legacyHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $legacyPath).Hash
    if ($legacyHash -ne 'C68BDADC7EEAC77A0FE8ECE999CEB5A28C51D819D69107AFD471739BA36E2737') {
        throw 'The Ultimate BIOS Settings source file was modified.'
    }

    $allModules = @(
        Get-ChildItem `
            (Join-Path $modulesRoot 'Check'), `
            (Join-Path $modulesRoot 'Refresh'), `
            (Join-Path $modulesRoot 'Setup'), `
            (Join-Path $modulesRoot 'Installers'), `
            (Join-Path $modulesRoot 'Graphics'), `
            (Join-Path $modulesRoot 'Windows'), `
            (Join-Path $modulesRoot 'Advanced') `
            -File `
            -Filter '*.psm1'
    )
    $implementedCount = @(
        $allModules | Where-Object {
            (Get-Content -Raw -LiteralPath $_.FullName).Contains('$script:BoostLabImplementedActions')
        }
    ).Count
    $placeholderCount = @(
        $allModules | Where-Object {
            (Get-Content -Raw -LiteralPath $_.FullName).Contains('ToolModule.Placeholder.ps1')
        }
    ).Count
    if ($implementedCount -ne 39 -or $placeholderCount -ne 16) {
        throw "Unexpected implementation counts: $implementedCount implemented, $placeholderCount placeholders."
    }

    [pscustomobject]@{
        Success             = $true
        ToolId              = $toolInfo.Id
        ImplementedActions  = @($toolInfo.ImplementedActions)
        GuidanceSectionCount = @($analysisResult.Data.Guidance).Count
        ImplementedModules  = $implementedCount
        PlaceholderModules  = $placeholderCount
        OpenActionExecuted  = $false
        CancelledOpenTested = $true
        Message             = 'BIOS Settings guidance and confirmation guard validated; restart was not executed.'
        Timestamp           = Get-Date
    }
}
finally {
    Remove-Module -ModuleInfo $biosModule -Force -ErrorAction SilentlyContinue
}


