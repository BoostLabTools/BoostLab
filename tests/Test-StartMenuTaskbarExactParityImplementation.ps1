[CmdletBinding()]
param(
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-BoostLabCondition {
    param(
        [Parameter(Mandatory)]
        [bool]$Condition,

        [Parameter(Mandatory)]
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Assert-OperationExists {
    param(
        [Parameter(Mandatory)]
        [object[]]$Operations,

        [Parameter(Mandatory)]
        [string]$Kind,

        [Parameter(Mandatory)]
        [string]$Path,

        [string]$Name = '',

        [AllowNull()]
        [object]$Data = $null
    )

    $matches = @(
        $Operations | Where-Object {
            [string]$_.Kind -eq $Kind -and
            [string]$_.Path -eq $Path -and
            ([string]::IsNullOrEmpty($Name) -or [string]$_.Name -eq $Name)
        }
    )
    if ($null -ne $Data) {
        $matches = @($matches | Where-Object {
            if ($Data -is [byte[]]) {
                [BitConverter]::ToString([byte[]]$_.Data) -eq [BitConverter]::ToString([byte[]]$Data)
            }
            else {
                [string]$_.Data -eq [string]$Data
            }
        })
    }
    Assert-BoostLabCondition ($matches.Count -gt 0) "Missing operation: $Kind $Path $Name"
}

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $scriptPath = if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $PSCommandPath
    }
    elseif (-not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
        $MyInvocation.MyCommand.Path
    }
    else {
        throw 'Unable to determine the Start Menu Taskbar exact parity validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot

$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\1 Start Menu Taskbar.ps1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\start-menu-taskbar.psm1'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$parityPath = Join-Path $ProjectRoot 'config\ParityStatusBaseline.psd1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'

$expectedSourceHash = '88BEB0E8C41F7A32AAE6A0A6E184E87E678FB25BEDEB092C63F4BA98B8712E91'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
Assert-BoostLabCondition ($actualSourceHash -eq $expectedSourceHash) 'Start Menu Taskbar source checksum mismatch.'

$stages = Import-PowerShellDataFile -LiteralPath $stagesPath
$allTools = @($stages.Stages | ForEach-Object { $_.Tools })
$tool = $allTools | Where-Object { $_.Id -eq 'start-menu-taskbar' } | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $tool) 'Start Menu Taskbar stage metadata was not found.'
Assert-BoostLabCondition ((@($tool.Actions) -join ',') -eq 'Apply,Default') 'Start Menu Taskbar must expose Apply/Default only.'
Assert-BoostLabCondition ([string]$tool.RiskLevel -eq 'high') 'Start Menu Taskbar must be high risk.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.RequiresAdmin) 'Start Menu Taskbar must require Administrator.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.CanModifyRegistry) 'Start Menu Taskbar must declare registry mutation.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.CanDeleteFiles) 'Start Menu Taskbar must declare file deletion.'
Assert-BoostLabCondition ([bool]$tool.Capabilities.SupportsDefault) 'Start Menu Taskbar must support source-defined Default.'
Assert-BoostLabCondition (-not [bool]$tool.Capabilities.SupportsRestore) 'Start Menu Taskbar must not support Restore.'

$executionText = Get-Content -LiteralPath $executionPath -Raw
Assert-BoostLabCondition ($executionText.Contains("'start-menu-taskbar' = @{")) 'Execution routing must register Start Menu Taskbar.'
Assert-BoostLabCondition ($executionText.Contains("Windows\start-menu-taskbar.psm1")) 'Execution routing must point to the Start Menu Taskbar module.'

$uiText = Get-Content -LiteralPath $uiPath -Raw
Assert-BoostLabCondition ($uiText.Contains("if (`$toolId -eq 'start-menu-taskbar')")) 'UI label helper must handle Start Menu Taskbar.'
Assert-BoostLabCondition ($uiText.Contains("'Apply' { return 'Clean (Recommended)' }")) 'Apply must display as Clean (Recommended).'

$moduleText = Get-Content -LiteralPath $modulePath -Raw
Assert-BoostLabCondition (-not $moduleText.Contains('ToolModule.Placeholder.ps1')) 'Start Menu Taskbar must not remain placeholder.'
Assert-BoostLabCondition ($moduleText.Contains('$script:BoostLabImplementedActions = @(''Apply'', ''Default'')')) 'Module implemented actions must be Apply and Default only.'
Assert-BoostLabCondition (-not $moduleText.Contains('$script:BoostLabImplementedActions = @(''Open''')) 'Module must not expose placeholder Open.'
Assert-BoostLabCondition (-not $moduleText.Contains('RestoreUnavailable')) 'Start Menu Taskbar must not expose a Restore implementation.'
Assert-BoostLabCondition (-not $moduleText.Contains('certutil.exe')) 'Module must not execute certutil; start2.bin is decoded internally.'

$module = Import-Module -Name $modulePath -Force -PassThru -ErrorAction Stop
try {
    $info = Get-BoostLabToolInfo
    Assert-BoostLabCondition ((@($info.ImplementedActions) -join ',') -eq 'Apply,Default') 'Module info must expose Apply/Default only.'
    Assert-BoostLabCondition ([string]$info.RiskLevel -eq 'high') 'Module info risk must be high.'

    $payload = Get-BoostLabStartMenuTaskbarStart2PayloadStatus
    Assert-BoostLabCondition ([string]$payload.Status -eq 'Passed') 'start2.bin payload status must pass.'
    Assert-BoostLabCondition ([int]$payload.Length -eq 4540) 'start2.bin payload length mismatch.'
    Assert-BoostLabCondition ([string]$payload.Sha256 -eq '21EAF7925A26A59880D799509C5E49D4034B36BD86D84D035A50D17D6A32206D') 'start2.bin payload hash mismatch.'

    $fakeSystemRoot = 'X:\Windows'
    $fakeSystemDrive = 'X:'
    $fakeUserProfile = 'X:\Users\BoostLab'
    $fakeProgramData = 'X:\ProgramData'
    $cleanOps = @(Get-BoostLabStartMenuTaskbarOperationCatalog -ActionName 'Apply' -SystemRoot $fakeSystemRoot -SystemDrive $fakeSystemDrive -UserProfile $fakeUserProfile -ProgramData $fakeProgramData)
    $defaultOps = @(Get-BoostLabStartMenuTaskbarOperationCatalog -ActionName 'Default' -SystemRoot $fakeSystemRoot -SystemDrive $fakeSystemDrive -UserProfile $fakeUserProfile -ProgramData $fakeProgramData)

    Assert-BoostLabCondition ($cleanOps.Count -gt 0) 'Clean operation catalog is empty.'
    Assert-BoostLabCondition ($defaultOps.Count -gt 0) 'Default operation catalog is empty.'
    Assert-OperationExists -Operations $cleanOps -Kind 'SetRegistryValue' -Path 'HKLM:\Software\Policies\Microsoft\Dsh' -Name 'AllowNewsAndInterests' -Data 0
    Assert-OperationExists -Operations $cleanOps -Kind 'SetRegistryValue' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAl' -Data 0
    Assert-OperationExists -Operations $cleanOps -Kind 'SetRegistryValue' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'SearchboxTaskbarMode' -Data 0
    Assert-OperationExists -Operations $cleanOps -Kind 'SetRegistryValue' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowTaskViewButton' -Data 0
    Assert-OperationExists -Operations $cleanOps -Kind 'SetRegistryValue' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarMn' -Data 0
    Assert-OperationExists -Operations $cleanOps -Kind 'SetRegistryValue' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowCopilotButton' -Data 0
    Assert-OperationExists -Operations $cleanOps -Kind 'SetRegistryValue' -Path 'HKLM:\Software\Policies\Microsoft\Windows\Windows Feeds' -Name 'EnableFeeds' -Data 0
    Assert-OperationExists -Operations $cleanOps -Kind 'SetRegistryValue' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'HideSCAMeetNow' -Data 1
    Assert-OperationExists -Operations $cleanOps -Kind 'SetRegistryValue' -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start' -Name 'HideRecommendedSection' -Data 1
    Assert-OperationExists -Operations $cleanOps -Kind 'SetRegistryValue' -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Education' -Name 'IsEducationEnvironment' -Data 1
    Assert-OperationExists -Operations $cleanOps -Kind 'SetRegistryValue' -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'HideRecommendedSection' -Data 1
    foreach ($overrideId in @('2792562829', '3036241548', '734731404', '762256525')) {
        Assert-OperationExists -Operations $cleanOps -Kind 'SetRegistryValue' -Path "HKLM:\SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\14\$overrideId" -Name 'EnabledState' -Data 2
        Assert-OperationExists -Operations $defaultOps -Kind 'DeleteRegistryValue' -Path "HKLM:\SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\14\$overrideId" -Name 'EnabledState'
    }
    Assert-OperationExists -Operations $cleanOps -Kind 'SetRegistryValue' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Start' -Name 'AllAppsViewMode' -Data 2
    Assert-OperationExists -Operations $cleanOps -Kind 'DeleteRegistryKey' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband'
    Assert-OperationExists -Operations $cleanOps -Kind 'DeleteDirectory' -Path 'X:\Users\BoostLab\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch'
    Assert-OperationExists -Operations $cleanOps -Kind 'SetNotifyIconSettings' -Path 'HKCU:\Control Panel\NotifyIconSettings' -Name 'IsPromoted' -Data 1
    Assert-OperationExists -Operations $cleanOps -Kind 'DeleteFile' -Path 'X:\Windows\StartMenuLayout.xml'
    Assert-OperationExists -Operations $cleanOps -Kind 'WriteTextFile' -Path 'C:\Windows\StartMenuLayout.xml'
    Assert-OperationExists -Operations $cleanOps -Kind 'WriteTextFile' -Path 'X:\Windows\Temp\start2.txt'
    Assert-OperationExists -Operations $cleanOps -Kind 'WriteBytesFile' -Path 'X:\Windows\Temp\start2.bin'
    Assert-OperationExists -Operations $cleanOps -Kind 'CopyFile' -Path 'X:\Windows\Temp\start2.bin'
    Assert-BoostLabCondition ((@($cleanOps | Where-Object { $_.Kind -eq 'RestartExplorer' }).Count -eq 2)) 'Clean must represent both source Explorer restarts.'

    Assert-OperationExists -Operations $defaultOps -Kind 'SetRegistryValue' -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband\AuxilliaryPins' -Name 'MailPin' -Data 1
    Assert-OperationExists -Operations $defaultOps -Kind 'DeleteRegistryKey' -Path 'HKLM:\Software\Policies\Microsoft\Dsh'
    Assert-OperationExists -Operations $defaultOps -Kind 'DeleteRegistryKey' -Path 'HKLM:\Software\Policies\Microsoft\Windows\Windows Feeds'
    Assert-OperationExists -Operations $defaultOps -Kind 'DeleteRegistryKey' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'
    Assert-OperationExists -Operations $defaultOps -Kind 'DeleteRegistryKey' -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start'
    Assert-OperationExists -Operations $defaultOps -Kind 'DeleteRegistryKey' -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Education'
    Assert-OperationExists -Operations $defaultOps -Kind 'DeleteRegistryValue' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAl'
    Assert-OperationExists -Operations $defaultOps -Kind 'DeleteRegistryValue' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'SearchboxTaskbarMode'
    Assert-OperationExists -Operations $defaultOps -Kind 'DeleteRegistryValue' -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'HideRecommendedSection'
    Assert-OperationExists -Operations $defaultOps -Kind 'SetRegistryValue' -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Start' -Name 'AllAppsViewMode' -Data 0
    Assert-OperationExists -Operations $defaultOps -Kind 'SetNotifyIconSettings' -Path 'HKCU:\Control Panel\NotifyIconSettings' -Name 'IsPromoted' -Data 0
    Assert-OperationExists -Operations $defaultOps -Kind 'DeleteFile' -Path 'X:\Windows\StartMenuLayout.xml'
    Assert-OperationExists -Operations $defaultOps -Kind 'WriteTextFile' -Path 'C:\Windows\StartMenuLayout.xml'
    Assert-OperationExists -Operations $defaultOps -Kind 'DeleteFile' -Path 'X:\Users\BoostLab\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\start2.bin'
    Assert-BoostLabCondition ((@($defaultOps | Where-Object { $_.Kind -eq 'RestartExplorer' }).Count -eq 2)) 'Default must represent both source Explorer restarts.'
    Assert-BoostLabCondition ((@($defaultOps | Where-Object { $_.Kind -eq 'CopyFile' -or $_.Kind -eq 'WriteBytesFile' }).Count -eq 0)) 'Default must not create a replacement start2.bin payload.'

    $script:mockOperations = [System.Collections.Generic.List[object]]::new()
    $recordRegistrySet = {
        param($Path, $Name, $Type, $Data)
        $script:mockOperations.Add([pscustomobject]@{ Kind = 'SetRegistryValue'; Path = $Path; Name = $Name; Type = $Type; Data = $Data })
        [pscustomobject]@{ Success = $true }
    }.GetNewClosure()
    $recordRegistryValueDelete = {
        param($Path, $Name)
        $script:mockOperations.Add([pscustomobject]@{ Kind = 'DeleteRegistryValue'; Path = $Path; Name = $Name })
        [pscustomobject]@{ Success = $true }
    }.GetNewClosure()
    $recordRegistryKeyDelete = {
        param($Path, $Recursive)
        $script:mockOperations.Add([pscustomobject]@{ Kind = 'DeleteRegistryKey'; Path = $Path; Recursive = $Recursive })
        [pscustomobject]@{ Success = $true }
    }.GetNewClosure()
    $recordDirectoryDelete = {
        param($Path, $Recursive)
        $script:mockOperations.Add([pscustomobject]@{ Kind = 'DeleteDirectory'; Path = $Path; Recursive = $Recursive })
        [pscustomobject]@{ Success = $true }
    }.GetNewClosure()
    $recordFileDelete = {
        param($Path)
        $script:mockOperations.Add([pscustomobject]@{ Kind = 'DeleteFile'; Path = $Path })
        [pscustomobject]@{ Success = $true }
    }.GetNewClosure()
    $recordTextWrite = {
        param($Path, $Content)
        $script:mockOperations.Add([pscustomobject]@{ Kind = 'WriteTextFile'; Path = $Path; Length = ([string]$Content).Length })
        [pscustomobject]@{ Success = $true }
    }.GetNewClosure()
    $recordBytesWrite = {
        param($Path, [byte[]]$Bytes)
        $script:mockOperations.Add([pscustomobject]@{ Kind = 'WriteBytesFile'; Path = $Path; Length = $Bytes.Length })
        [pscustomobject]@{ Success = $true }
    }.GetNewClosure()
    $recordCopy = {
        param($Path, $Destination)
        $script:mockOperations.Add([pscustomobject]@{ Kind = 'CopyFile'; Path = $Path; Destination = $Destination })
        [pscustomobject]@{ Success = $true }
    }.GetNewClosure()
    $recordFolderAttribute = {
        param($Path, $Hidden)
        $script:mockOperations.Add([pscustomobject]@{ Kind = 'SetFolderAttribute'; Path = $Path; Hidden = $Hidden })
        [pscustomobject]@{ Success = $true }
    }.GetNewClosure()
    $mockNotifyEnumerator = {
        param($Path)
        @('HKCU:\Control Panel\NotifyIconSettings\a', 'HKCU:\Control Panel\NotifyIconSettings\b')
    }.GetNewClosure()
    $recordExplorerRestart = {
        $script:mockOperations.Add([pscustomobject]@{ Kind = 'RestartExplorer'; Process = 'explorer' })
        [pscustomobject]@{ Success = $true }
    }.GetNewClosure()
    $recordSleep = {
        param($Seconds)
        $script:mockOperations.Add([pscustomobject]@{ Kind = 'Sleep'; Seconds = $Seconds })
        [pscustomobject]@{ Success = $true }
    }.GetNewClosure()

    $cancelled = Invoke-BoostLabToolAction -ActionName 'Apply' -AdministratorChecker { $true }
    Assert-BoostLabCondition (-not [bool]$cancelled.Success -and [string]$cancelled.Status -eq 'Cancelled') 'Unconfirmed Clean must fail closed before mutation.'

    $script:mockOperations.Clear()
    $applyResult = Invoke-BoostLabToolAction `
        -ActionName 'Clean (Recommended)' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -RegistrySetter $recordRegistrySet `
        -RegistryValueDeleter $recordRegistryValueDelete `
        -RegistryKeyDeleter $recordRegistryKeyDelete `
        -DirectoryDeleter $recordDirectoryDelete `
        -FileDeleter $recordFileDelete `
        -TextFileWriter $recordTextWrite `
        -BytesFileWriter $recordBytesWrite `
        -FileCopier $recordCopy `
        -FolderAttributeSetter $recordFolderAttribute `
        -NotifyIconEnumerator $mockNotifyEnumerator `
        -ExplorerRestarter $recordExplorerRestart `
        -Sleep $recordSleep
    Assert-BoostLabCondition ([bool]$applyResult.Success) 'Mocked Clean should succeed.'
    Assert-BoostLabCondition ([bool]$applyResult.ChangesExecuted) 'Mocked Clean should report executed changes.'
    Assert-BoostLabCondition ((@($script:mockOperations | Where-Object { $_.Kind -eq 'RestartExplorer' }).Count -eq 2)) 'Mocked Clean must route Explorer handling through the adapter.'
    Assert-BoostLabCondition ((@($script:mockOperations | Where-Object { $_.Kind -eq 'WriteBytesFile' -and $_.Length -eq 4540 }).Count -eq 1)) 'Mocked Clean must write the decoded start2.bin payload through the bytes adapter.'

    $script:mockOperations.Clear()
    $defaultResult = Invoke-BoostLabToolAction `
        -ActionName 'Default' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -RegistrySetter $recordRegistrySet `
        -RegistryValueDeleter $recordRegistryValueDelete `
        -RegistryKeyDeleter $recordRegistryKeyDelete `
        -DirectoryDeleter $recordDirectoryDelete `
        -FileDeleter $recordFileDelete `
        -TextFileWriter $recordTextWrite `
        -BytesFileWriter $recordBytesWrite `
        -FileCopier $recordCopy `
        -FolderAttributeSetter $recordFolderAttribute `
        -NotifyIconEnumerator $mockNotifyEnumerator `
        -ExplorerRestarter $recordExplorerRestart `
        -Sleep $recordSleep
    Assert-BoostLabCondition ([bool]$defaultResult.Success) 'Mocked Default should succeed.'
    Assert-BoostLabCondition ((@($script:mockOperations | Where-Object { $_.Kind -eq 'WriteBytesFile' -or $_.Kind -eq 'CopyFile' }).Count -eq 0)) 'Mocked Default must not write or copy start2.bin.'
    Assert-BoostLabCondition ((@($script:mockOperations | Where-Object { $_.Kind -eq 'RestartExplorer' }).Count -eq 2)) 'Mocked Default must route Explorer handling through the adapter.'
}
finally {
    Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
}

$parity = Import-PowerShellDataFile -LiteralPath $parityPath
$record = $parity.Tools | Where-Object { $_['ToolId'] -eq 'start-menu-taskbar' } | Select-Object -First 1
Assert-BoostLabCondition ([string]$record['RuntimeStatus'] -eq 'RuntimeImplemented') 'Start Menu Taskbar parity runtime status must be RuntimeImplemented.'
Assert-BoostLabCondition ([string]$record['ImplementationLevel'] -eq 'ParityImplemented') 'Start Menu Taskbar must be final accepted parity after Phase 134.'
Assert-BoostLabCondition ([string]$record['UltimateParity'] -eq 'Yes') 'Start Menu Taskbar must be marked as Ultimate parity after Yazan acceptance.'
Assert-BoostLabCondition (-not [bool]$record['YazanFinalException']) 'Start Menu Taskbar must not use a Yazan final exception.'
$isOrderedParityComplete = ($parity.ContainsKey('OrderedParityComplete') -and [bool]$parity.OrderedParityComplete)
if ($isOrderedParityComplete) {
    Assert-BoostLabCondition ($null -eq $parity.CurrentOrderedParityTarget) 'Completed ordered parity must not keep a current target.'
}
else {
    Assert-BoostLabCondition (-not [string]::IsNullOrWhiteSpace([string]$parity.CurrentOrderedParityTarget)) 'Current ordered parity target must be populated.'
}

$placeholderModules = @(
    Get-ChildItem -Path (Join-Path $ProjectRoot 'modules') -Recurse -Filter '*.psm1' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1') }
)
Assert-BoostLabCondition ($allTools.Count -eq $inventoryBaseline.ActiveTools) 'Active tool count must match the central inventory baseline.'
Assert-BoostLabCondition ($placeholderModules.Count -eq $inventoryBaseline.DeferredPlaceholders) 'Placeholder count must match the central inventory baseline.'
Assert-BoostLabCondition (($allTools.Count - $placeholderModules.Count) -eq $inventoryBaseline.ImplementedTools) 'Implemented count must match the central inventory baseline.'

foreach ($protectedPath in @(
    'source-ultimate\6 Windows\1 Start Menu Taskbar.ps1',
    'config\ArtifactProvenance.psd1'
)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath (Join-Path $ProjectRoot $protectedPath)) "Protected path missing: $protectedPath"
}

$loudnessPath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\17 Loudness EQ.ps1'
Assert-BoostLabCondition (-not (Test-Path -LiteralPath $loudnessPath)) 'Loudness EQ source was reintroduced.'
$nvmeSource = @(
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'source-ultimate') -Recurse -File |
        Where-Object { $_.Name -like '*NVME Faster Driver*' }
)
Assert-BoostLabCondition ($nvmeSource.Count -eq 0) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    Success = $true
    ToolId = 'start-menu-taskbar'
    SourceHash = $actualSourceHash
    Start2PayloadSha256 = '21EAF7925A26A59880D799509C5E49D4034B36BD86D84D035A50D17D6A32206D'
    CleanOperationCount = $cleanOps.Count
    DefaultOperationCount = $defaultOps.Count
    ActiveToolCount = $inventoryBaseline.ActiveTools
    ImplementedToolCount = $inventoryBaseline.ImplementedTools
    PlaceholderToolCount = $inventoryBaseline.DeferredPlaceholders
    OrderedParityTarget = [string]$parity.CurrentOrderedParityTarget
    Message = 'Start Menu Taskbar exact source-equivalent Clean and Default catalogs are implemented with mock-safe execution.'
    Timestamp = Get-Date
}
