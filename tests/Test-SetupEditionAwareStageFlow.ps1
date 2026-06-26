[CmdletBinding()]
param(
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'BoostLab.Hashing.ps1')
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $scriptPath = if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $PSCommandPath
    }
    else {
        $MyInvocation.MyCommand.Path
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$environmentPath = Join-Path $ProjectRoot 'core\Environment.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$convertModulePath = Join-Path $ProjectRoot 'modules\Setup\convert-home-to-pro.psm1'
$bitLockerModulePath = Join-Path $ProjectRoot 'modules\Setup\bitlocker.psm1'
function Assert-BoostLabCondition {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

Import-Module -Name $environmentPath -Force -Scope Local -DisableNameChecking -ErrorAction Stop
$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$setupStage = @($configuration.Stages | Where-Object { [string]$_.Name -eq 'Setup' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $setupStage) 'Setup stage was not found.'

. $uiPath

function New-MockEditionCapability {
    param([Parameter(Mandatory)][string]$Edition)

    Resolve-BoostLabWindowsEditionCapability -WindowsVersion ([pscustomobject]@{
        ProductName = "Windows 11 $Edition"
        Edition = $Edition
    })
}

foreach ($homeEdition in @('Core', 'CoreSingleLanguage', 'CoreCountrySpecific', 'Home', 'HomeSingleLanguage')) {
    $capability = New-MockEditionCapability -Edition $homeEdition
    Assert-BoostLabCondition ([bool]$capability.IsHomeOrCore) "Edition should classify as Home/Core: $homeEdition"
    Assert-BoostLabCondition (-not [bool]$capability.SupportsBitLocker) "Home/Core edition should not support BitLocker: $homeEdition"
    $tools = @(Get-BoostLabEditionAwareStageTools -Stage $setupStage -EditionCapability $capability)
    $ids = @($tools | ForEach-Object { [string]$_['Id'] })
    Assert-BoostLabCondition ('convert-home-to-pro' -in $ids) "Convert Home To Pro should be visible on $homeEdition."
    Assert-BoostLabCondition ('bitlocker' -notin $ids) "BitLocker should not be runnable/visible on $homeEdition."
}

foreach ($proEdition in @('Professional', 'ProfessionalWorkstation', 'ProfessionalEducation', 'Enterprise', 'Education')) {
    $capability = New-MockEditionCapability -Edition $proEdition
    Assert-BoostLabCondition ([bool]$capability.SupportsBitLocker) "Edition should support BitLocker: $proEdition"
    Assert-BoostLabCondition (-not [bool]$capability.SupportsConvertHomeToPro) "Convert Home To Pro should be unavailable on $proEdition."
    $tools = @(Get-BoostLabEditionAwareStageTools -Stage $setupStage -EditionCapability $capability)
    $ids = @($tools | ForEach-Object { [string]$_['Id'] })
    Assert-BoostLabCondition ('bitlocker' -in $ids) "BitLocker should be visible on $proEdition."
    Assert-BoostLabCondition ('convert-home-to-pro' -notin $ids) "Convert Home To Pro should not be visible on $proEdition."
}

$unknownCapability = Resolve-BoostLabWindowsEditionCapability -WindowsVersion ([pscustomobject]@{ ProductName = 'Windows'; Edition = 'MysteryEdition' })
$unknownTools = @(Get-BoostLabEditionAwareStageTools -Stage $setupStage -EditionCapability $unknownCapability)
$unknownEditionTools = @($unknownTools | Where-Object { [string]$_['Id'] -in @('bitlocker', 'convert-home-to-pro') })
Assert-BoostLabCondition ($unknownEditionTools.Count -eq 2) 'Unknown edition should show disabled edition-dependent Setup tools with reasons.'
foreach ($tool in $unknownEditionTools) {
    Assert-BoostLabCondition ([string]$tool['AvailabilityStatus'] -eq 'Unavailable') "Unknown edition tool should be unavailable: $($tool['Id'])"
    Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$tool['AvailabilityReason'])) "Unknown edition tool should include an unavailable reason: $($tool['Id'])"
}

$firstRunHomeIds = @(Get-BoostLabEditionAwareStageTools -Stage $setupStage -EditionCapability (New-MockEditionCapability -Edition 'Core') | ForEach-Object { [string]$_['Id'] })
$secondRunProIds = @(Get-BoostLabEditionAwareStageTools -Stage $setupStage -EditionCapability (New-MockEditionCapability -Edition 'Professional') | ForEach-Object { [string]$_['Id'] })
Assert-BoostLabCondition ('convert-home-to-pro' -in $firstRunHomeIds -and 'bitlocker' -notin $firstRunHomeIds) 'First mocked launch on Home should expose Convert only.'
Assert-BoostLabCondition ('bitlocker' -in $secondRunProIds -and 'convert-home-to-pro' -notin $secondRunProIds) 'Second mocked launch on Pro should expose BitLocker only.'

$convertModule = Import-Module -Name $convertModulePath -Force -PassThru -Prefix 'EditionConvert' -Scope Local -DisableNameChecking -ErrorAction Stop
$bitLockerModule = Import-Module -Name $bitLockerModulePath -Force -PassThru -Scope Local -DisableNameChecking -ErrorAction Stop
$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -DisableNameChecking -ErrorAction Stop
try {
    $homeReader = { New-MockEditionCapability -Edition 'Core' }
    $proReader = { New-MockEditionCapability -Edition 'Professional' }
    $unknownReader = { Resolve-BoostLabWindowsEditionCapability -WindowsVersion ([pscustomobject]@{ ProductName = 'Windows'; Edition = 'MysteryEdition' }) }

    $convertEvents = [System.Collections.Generic.List[string]]::new()
    $clipboardWriter = { param($Value) $convertEvents.Add("Clipboard:$Value"); [pscustomobject]@{ Success = $true; CommandStatus = 'Completed'; Message = 'Mock clipboard.' } }.GetNewClosure()
    $settingsLauncher = { $convertEvents.Add('Settings'); [pscustomobject]@{ Success = $true; CommandStatus = 'Completed'; Message = 'Mock settings.' } }.GetNewClosure()
    $productKeyFlowLauncher = { $convertEvents.Add('ProductKeyFlow'); [pscustomobject]@{ Success = $true; CommandStatus = 'Completed'; Message = 'Mock product key flow.' } }.GetNewClosure()
    $dialogPresenter = { param($Dialog) $convertEvents.Add('Dialog'); [pscustomobject]@{ Success = $true; CommandStatus = 'Completed'; Message = 'Mock dialog.' } }.GetNewClosure()

    $convertOnHome = Invoke-EditionConvertBoostLabToolAction -ActionName 'Apply' -Confirmed:$true -AdministratorDetector { $true } -EditionCapabilityReader $homeReader -ClipboardWriter $clipboardWriter -SettingsLauncher $settingsLauncher -ProductKeyFlowLauncher $productKeyFlowLauncher -DialogPresenter $dialogPresenter
    Assert-BoostLabCondition ([bool]$convertOnHome.Success) 'Convert Home To Pro should run through mocks on Home/Core.'
    Assert-BoostLabCondition ([string]$convertOnHome.Data.RuntimeGuardResult -eq 'Available') 'Convert Home To Pro Home run should report available runtime guard.'
    Assert-BoostLabCondition (($convertEvents -join '|') -eq 'Dialog|Clipboard:VK7JG-NPHTM-C97JM-9MPGT-3V66T|Settings|ProductKeyFlow') 'Convert Home To Pro Home run should preserve mocked source-equivalent order.'

    $convertEvents.Clear()
    $convertOnPro = Invoke-EditionConvertBoostLabToolAction -ActionName 'Apply' -Confirmed:$true -AdministratorDetector { $true } -EditionCapabilityReader $proReader -ClipboardWriter $clipboardWriter -SettingsLauncher $settingsLauncher -ProductKeyFlowLauncher $productKeyFlowLauncher -DialogPresenter $dialogPresenter
    Assert-BoostLabCondition ([string]$convertOnPro.Status -eq 'NotApplicable') 'Convert Home To Pro should be NotApplicable on Pro or higher.'
    Assert-BoostLabCondition ([string]$convertOnPro.Data.RuntimeGuardResult -eq 'AlreadyProOrHigher') 'Convert Home To Pro Pro guard reason mismatch.'
    Assert-BoostLabCondition ($convertEvents.Count -eq 0) 'Convert Home To Pro Pro guard must block before side effects.'

    $convertUnknown = Invoke-EditionConvertBoostLabToolAction -ActionName 'Apply' -Confirmed:$true -AdministratorDetector { $true } -EditionCapabilityReader $unknownReader -ClipboardWriter $clipboardWriter -SettingsLauncher $settingsLauncher -ProductKeyFlowLauncher $productKeyFlowLauncher -DialogPresenter $dialogPresenter
    Assert-BoostLabCondition ([string]$convertUnknown.Status -eq 'NotApplicable') 'Convert Home To Pro should be unavailable on unknown edition.'
    Assert-BoostLabCondition ([string]$convertUnknown.Data.RuntimeGuardResult -eq 'EditionUnknown') 'Convert Home To Pro unknown guard reason mismatch.'

    $bitLockerCalls = [System.Collections.Generic.List[string]]::new()
    $volumeReader = {
        [pscustomobject]@{ MountPoint = 'C:'; VolumeStatus = 'FullyEncrypted'; ProtectionStatus = 'On'; EncryptionPercentage = 100; LockStatus = 'Unlocked'; KeyProtector = @() }
    }
    $disableExecutor = { param($MountPoint) $bitLockerCalls.Add("Disable:$MountPoint"); [pscustomobject]@{ Success = $true; CommandStatus = 'Completed'; Message = 'Mock disable.' } }.GetNewClosure()
    $controlPanelLauncher = { param($FilePath, $ArgumentList) $bitLockerCalls.Add('ControlPanel'); [pscustomobject]@{ Success = $true; CommandStatus = 'Completed'; Message = 'Mock control panel.' } }.GetNewClosure()
    $manageBdeExecutor = { param($ArgumentList) $bitLockerCalls.Add('ManageBde'); [pscustomobject]@{ Success = $true; CommandStatus = 'Completed'; ExitCode = 0; Message = 'Mock manage-bde.' } }.GetNewClosure()

    $bitLockerHome = & $bitLockerModule {
        param($Reader, $VolumeReader, $Disable, $Control, $Manage)
        Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$true -EditionCapabilityReader $Reader -VolumeReader $VolumeReader -DisableBitLockerExecutor $Disable -ControlPanelLauncher $Control -ManageBdeStatusExecutor $Manage
    } $homeReader $volumeReader $disableExecutor $controlPanelLauncher $manageBdeExecutor
    Assert-BoostLabCondition ([string]$bitLockerHome.Status -eq 'NotApplicable') 'BitLocker Apply should be NotApplicable on Home/Core.'
    Assert-BoostLabCondition ([string]$bitLockerHome.Data.RuntimeGuardResult -eq 'BitLockerRequiresProOrHigher') 'BitLocker Home guard reason mismatch.'
    Assert-BoostLabCondition ($bitLockerCalls.Count -eq 0) 'BitLocker Home guard must block before Disable-BitLocker/control/manage-bde.'

    $bitLockerPro = & $bitLockerModule {
        param($Reader, $VolumeReader, $Disable, $Control, $Manage)
        Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$true -EditionCapabilityReader $Reader -VolumeReader $VolumeReader -DisableBitLockerExecutor $Disable -ControlPanelLauncher $Control -ManageBdeStatusExecutor $Manage
    } $proReader $volumeReader $disableExecutor $controlPanelLauncher $manageBdeExecutor
    Assert-BoostLabCondition ([bool]$bitLockerPro.Success) 'BitLocker Apply should run through mocks on Pro or higher.'
    Assert-BoostLabCondition (($bitLockerCalls -join '|') -eq 'Disable:C:|ControlPanel|ManageBde') 'BitLocker Pro Apply should execute the mocked source-equivalent sequence only.'

    $bitLockerCalls.Clear()
    $bitLockerUnknown = & $bitLockerModule {
        param($Reader, $VolumeReader, $Disable, $Control, $Manage)
        Invoke-BoostLabToolAction -ActionName 'Open' -Confirmed:$true -EditionCapabilityReader $Reader -VolumeReader $VolumeReader -DisableBitLockerExecutor $Disable -ControlPanelLauncher $Control -ManageBdeStatusExecutor $Manage
    } $unknownReader $volumeReader $disableExecutor $controlPanelLauncher $manageBdeExecutor
    Assert-BoostLabCondition ([string]$bitLockerUnknown.Status -eq 'NotApplicable') 'BitLocker Open should be unavailable on unknown edition.'
    Assert-BoostLabCondition ([string]$bitLockerUnknown.Data.RuntimeGuardResult -eq 'EditionUnknown') 'BitLocker unknown guard reason mismatch.'
    Assert-BoostLabCondition ($bitLockerCalls.Count -eq 0) 'BitLocker unknown guard must block before external process/status actions.'

    $convertTool = @($setupStage.Tools | Where-Object { [string]$_.Id -eq 'convert-home-to-pro' }) | Select-Object -First 1
    $bitLockerTool = @($setupStage.Tools | Where-Object { [string]$_.Id -eq 'bitlocker' }) | Select-Object -First 1
    $convertPlan = New-BoostLabActionPlan -ToolMetadata $convertTool -ActionName 'Apply'
    $bitLockerPlan = New-BoostLabActionPlan -ToolMetadata $bitLockerTool -ActionName 'Apply'
    $convertPlanText = (@($convertPlan.PlannedChanges) + @($convertPlan.SideEffects) + @($convertPlan.ConfirmationMessage)) -join ' '
    $bitLockerPlanText = (@($bitLockerPlan.PlannedChanges) + @($bitLockerPlan.SideEffects) + @($bitLockerPlan.ConfirmationMessage)) -join ' '
    Assert-BoostLabCondition ($bitLockerPlanText -match 'Windows Pro or higher') 'BitLocker ActionPlan must state Pro-or-higher requirement.'
    Assert-BoostLabCondition ($convertPlanText -match 'Windows may request a restart' -and $convertPlanText -match 'will not auto-resume or auto-run BitLocker') 'Convert Home To Pro ActionPlan must describe restart/no auto-chain behavior.'
    Assert-BoostLabCondition ($convertPlanText -match 'No changepk, slmgr, DISM, KMS, crack, activation bypass') 'Convert Home To Pro ActionPlan must explicitly state forbidden activation behavior is absent.'
}
finally {
    Remove-Module -ModuleInfo $convertModule -Force -ErrorAction SilentlyContinue
    Remove-Module -ModuleInfo $bitLockerModule -Force -ErrorAction SilentlyContinue
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

[pscustomobject]@{
    Test = 'SetupEditionAwareStageFlow'
    HomeCoreVariantsChecked = 5
    ProOrHigherVariantsChecked = 5
    UnknownEditionDisabledTools = $unknownEditionTools.Count
    RuntimeGuardsMocked = $true
    SourceUltimateUnchanged = $true
    Message = 'Setup edition-aware stage flow exposes Convert Home To Pro on Home/Core, BitLocker on Pro-or-higher, and blocks direct runtime bypasses with mocks.'
}
