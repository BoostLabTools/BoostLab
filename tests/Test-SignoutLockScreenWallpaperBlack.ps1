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
        throw 'Unable to determine the Signout LockScreen Wallpaper Black test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
. (Join-Path $ProjectRoot 'tests\BoostLab.ParityStatusBaseline.ps1')

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

$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot
$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$parityOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\SignoutLockScreenWallpaperBlack.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\5 Signout Lockscreen Wallpaper Black.ps1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$recordPath = Join-Path $ProjectRoot 'docs\migrations\signout-lockscreen-wallpaper-black.md'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$modulesRoot = Join-Path $ProjectRoot 'modules'

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$stages = @($configuration['Stages'] | Sort-Object { [int]$_['Order'] })
$tools = @($stages | ForEach-Object { $_['Tools'] })
$tool = $tools |
    Where-Object { $_['Id'] -eq 'signout-lockscreen-wallpaper-black' } |
    Select-Object -First 1
Assert-BoostLabCondition ($null -ne $tool) 'Signout LockScreen Wallpaper Black metadata is missing.'
Assert-BoostLabCondition (
    [string]$tool['Stage'] -eq 'Windows' -and
    [int]$tool['Order'] -eq 5 -and
    [string]$tool['Type'] -eq 'action' -and
    [string]$tool['RiskLevel'] -eq 'medium' -and
    (@($tool['Actions']) -join ',') -eq 'Apply,Default'
) 'Signout LockScreen Wallpaper Black stage, order, type, risk, or actions are incorrect.'

$capabilities = $tool['Capabilities']
$expectedTrueCapabilities = @(
    'RequiresAdmin'
    'CanModifyRegistry'
    'CanDeleteFiles'
    'SupportsDefault'
    'NeedsExplicitConfirmation'
)
foreach ($field in $capabilities.Keys) {
    $expected = $field -in $expectedTrueCapabilities
    Assert-BoostLabCondition ([bool]$capabilities[$field] -eq $expected) "Signout LockScreen Wallpaper Black capability '$field' is incorrect."
}

Assert-BoostLabCondition (
    (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -eq
        'C5A3E791BB85EE166397748D95B0BD4725063B55DC50CAEA805DC212E485C64C'
) 'Signout LockScreen Wallpaper Black Ultimate source hash changed.'
$source = Get-Content -Raw -LiteralPath $sourcePath
foreach ($requiredText in @(
    'System.Windows.Forms.SystemInformation'
    'System.Drawing.Bitmap'
    'FillRectangle'
    'C:\Windows\Black.jpg'
    'LockScreenImagePath'
    'LockScreenImageStatus'
    'HKCU\Control Panel\Desktop'
    'UpdatePerUserSystemParameters'
    'C:\Windows\Web\Wallpaper\Windows\img0.jpg'
    'reg delete'
    'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP'
    'Remove-Item -Recurse -Force "C:\Windows\Black.jpg"'
)) {
    Assert-BoostLabCondition ($source.Contains($requiredText)) "Ultimate source no longer contains: $requiredText"
}

Assert-BoostLabCondition (Test-Path -LiteralPath $modulePath -PathType Leaf) 'The canonical Signout LockScreen Wallpaper Black module is missing.'
$moduleSource = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredText in @(
    '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    'System.Windows.Forms.SystemInformation'
    'System.Drawing.Bitmap'
    'FillRectangle'
    'C:\Windows\Black.jpg'
    'C:\Windows\Web\Wallpaper\Windows\img0.jpg'
    'LockScreenImagePath'
    'LockScreenImageStatus'
    'REG_DWORD'
    'HKCU\Control Panel\Desktop'
    'reg add'
    'reg delete'
    'DeleteKey'
    'UpdatePerUserSystemParameters'
    'Remove-Item -Recurse -Force $Path'
    'function Test-BoostLabSignoutWallpaperState'
    'New-BoostLabVerificationResult'
    'VerificationResult'
    '[bool] $Confirmed = $false'
)) {
    Assert-BoostLabCondition ($moduleSource.Contains($requiredText)) "Signout LockScreen Wallpaper Black module is missing: $requiredText"
}
foreach ($removedDeviationText in @(
    'Backup-BoostLabWallpaperFile'
    'Restore-BoostLabWallpaperBackup'
    'Remove-BoostLabOwnedWallpaperFile'
    'signout-lockscreen-wallpaper-black.json'
    'GeneratedFileSha256'
    'OriginalFileSha256'
    'OwnershipUncertain'
    'LeftIntactUnknownOwnership'
)) {
    Assert-BoostLabCondition (-not $moduleSource.Contains($removedDeviationText)) "Exact parity module still contains old safety-deviation text: $removedDeviationText"
}
Assert-BoostLabCondition (
    $moduleSource -match
        'reg delete\s+["'']\{0\}["'']\s+/f'
) 'The module no longer represents the source-defined complete PersonalizationCSP key deletion.'
foreach ($forbiddenText in @(
    'Restart-Computer'
    'Stop-Computer'
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'Set-Service'
    'Stop-Service'
    'Restart-Service'
    'Stop-Process'
    'Remove-AppxPackage'
    'UsesTrustedInstaller = $true'
    'safeboot'
)) {
    Assert-BoostLabCondition (-not $moduleSource.Contains($forbiddenText)) "The module contains unrelated behavior: $forbiddenText"
}

$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $modulePath,
    [ref]$tokens,
    [ref]$parseErrors
)
if (@($parseErrors).Count -gt 0) {
    throw "Signout LockScreen Wallpaper Black module syntax error: $($parseErrors[0].Message)"
}
$commands = @(
    $ast.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
        $true
    ) | ForEach-Object { $_.GetCommandName() } | Where-Object { $_ }
)
foreach ($forbiddenCommand in @(
    'Restart-Computer'
    'Stop-Computer'
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'Set-Service'
    'Stop-Service'
    'Restart-Service'
    'Stop-Process'
    'Remove-AppxPackage'
)) {
    Assert-BoostLabCondition ((@($commands | Where-Object { $_ -eq $forbiddenCommand }).Count -eq 0)) "The module contains forbidden command: $forbiddenCommand"
}

$wallpaperModule = Import-Module `
    -Name $modulePath `
    -Force `
    -PassThru `
    -Prefix 'WallpaperTest' `
    -Scope Local `
    -DisableNameChecking `
    -ErrorAction Stop
try {
    $toolInfo = Get-WallpaperTestBoostLabToolInfo
    Assert-BoostLabCondition (
        [string]$toolInfo.Id -eq 'signout-lockscreen-wallpaper-black' -and
        (@($toolInfo.Actions) -join ',') -eq 'Apply,Default' -and
        (@($toolInfo.ImplementedActions) -join ',') -eq 'Apply,Default'
    ) 'The module metadata or implemented actions are incorrect.'

    $targetPath = 'C:\Windows\Black.jpg'
    $defaultPath = 'C:\Windows\Web\Wallpaper\Windows\img0.jpg'
    $cspKey = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP'
    $desktopKey = 'HKCU\Control Panel\Desktop'
    $mock = @{
        Files = @{}
        Registry = @{}
        KeyExists = @{}
        Events = [System.Collections.Generic.List[string]]::new()
        RemoveCalled = $false
    }
    $mock.KeyExists[$cspKey] = $false
    $mock.KeyExists[$desktopKey] = $true

    $fileReader = {
        param($Path)
        if ($mock.Files.ContainsKey($Path)) {
            return $mock.Files[$Path]
        }

        [pscustomobject]@{ Exists = $false; Path = $Path; Length = $null; ErrorMessage = $null }
    }
    $imageGenerator = {
        param($Path)
        $mock.Events.Add('GenerateImage')
        $mock.Files[$Path] = [pscustomobject]@{
            Exists = $true; Path = $Path; Length = 200; ErrorMessage = $null
        }
        [pscustomobject]@{ Success = $true; Width = 1920; Height = 1080; Message = 'Mock image generated.' }
    }
    $registryRunner = {
        param($Operation)
        $mock.Events.Add("Registry:$($Operation.Operation):$($Operation.Name)")
        if ($Operation.Operation -eq 'DeleteKey') {
            $mock.KeyExists[$Operation.Key] = $false
            foreach ($key in @($mock.Registry.Keys)) {
                if ($key.StartsWith("$($Operation.Key)|")) {
                    [void]$mock.Registry.Remove($key)
                }
            }
        }
        else {
            $mock.KeyExists[$Operation.Key] = $true
            $mock.Registry["$($Operation.Key)|$($Operation.Name)"] = $Operation.Value
        }

        [pscustomobject]@{
            Success = $true; ExitCode = 0; Operation = $Operation.Operation
            Key = $Operation.Key; Name = $Operation.Name; Message = 'Mock registry operation completed.'
        }
    }
    $registryReader = {
        param($Key, $Name)
        $lookupKey = "$Key|$Name"
        if ($mock.Registry.ContainsKey($lookupKey)) {
            return [pscustomobject]@{
                Detected = $true; Exists = $true
                Value = $mock.Registry[$lookupKey]; ErrorMessage = $null
            }
        }

        [pscustomobject]@{ Detected = $true; Exists = $false; Value = $null; ErrorMessage = $null }
    }
    $registryKeyReader = {
        param($Key)
        [pscustomobject]@{
            Detected = $true
            Exists = ($mock.KeyExists.ContainsKey($Key) -and [bool]$mock.KeyExists[$Key])
            ErrorMessage = $null
        }
    }
    $refresher = {
        $mock.Events.Add('Refresh')
        [pscustomobject]@{ Success = $true; ExitCode = 0; Message = 'Mock refresh requested.' }
    }
    $fileRemover = {
        param($Path)
        $mock.Events.Add('RemoveFile')
        $mock.RemoveCalled = $true
        [void]$mock.Files.Remove($Path)
        [pscustomobject]@{ Success = $true; Path = $Path; Message = 'Mock Black.jpg removed.' }
    }

    $mock.Files[$targetPath] = [pscustomobject]@{ Exists = $true; Path = $targetPath; Length = 100; ErrorMessage = $null }
    $applyResult = Invoke-WallpaperTestBoostLabToolAction `
        -ActionName 'Apply' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -RegistryCommandRunner $registryRunner `
        -RegistryReader $registryReader `
        -RegistryKeyReader $registryKeyReader `
        -FileReader $fileReader `
        -ImageGenerator $imageGenerator `
        -WallpaperRefresher $refresher `
        -FileRemover $fileRemover
    Assert-BoostLabCondition (
        [bool]$applyResult.Success -and
        $null -ne $applyResult.VerificationResult -and
        [string]$applyResult.VerificationResult.Status -eq 'Passed' -and
        [string]$mock.Registry["$cspKey|LockScreenImagePath"] -eq $targetPath -and
        [int]$mock.Registry["$cspKey|LockScreenImageStatus"] -eq 1 -and
        [string]$mock.Registry["$desktopKey|Wallpaper"] -eq $targetPath -and
        $mock.Files.ContainsKey($targetPath)
    ) "Mocked Apply failed: $($applyResult.Message)"
    foreach ($orderedEvent in @('GenerateImage', 'Registry:Add:LockScreenImagePath', 'Registry:Add:LockScreenImageStatus', 'Registry:Add:Wallpaper', 'Refresh')) {
        Assert-BoostLabCondition ($mock.Events.Contains($orderedEvent)) "Apply did not record expected event: $orderedEvent"
    }
    Assert-BoostLabCondition (
        $mock.Events.IndexOf('GenerateImage') -lt $mock.Events.IndexOf('Registry:Add:LockScreenImagePath') -and
        $mock.Events.IndexOf('Registry:Add:LockScreenImagePath') -lt $mock.Events.IndexOf('Registry:Add:LockScreenImageStatus') -and
        $mock.Events.IndexOf('Registry:Add:LockScreenImageStatus') -lt $mock.Events.IndexOf('Registry:Add:Wallpaper') -and
        $mock.Events.IndexOf('Registry:Add:Wallpaper') -lt $mock.Events.IndexOf('Refresh')
    ) 'Apply did not preserve the source operation order.'
    Assert-BoostLabCondition (
        [string]$applyResult.Data.BackupOwnershipStatus -eq 'Not used; exact Ultimate parity performs no backup or ownership tracking.'
    ) 'Apply Latest Result still implies backup or ownership tracking.'

    $mock.Events.Clear()
    $mock.RemoveCalled = $false
    $defaultResult = Invoke-WallpaperTestBoostLabToolAction `
        -ActionName 'Default' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -RegistryCommandRunner $registryRunner `
        -RegistryReader $registryReader `
        -RegistryKeyReader $registryKeyReader `
        -FileReader $fileReader `
        -ImageGenerator $imageGenerator `
        -WallpaperRefresher $refresher `
        -FileRemover $fileRemover
    Assert-BoostLabCondition (
        [bool]$defaultResult.Success -and
        $null -ne $defaultResult.VerificationResult -and
        [string]$defaultResult.VerificationResult.Status -eq 'Passed' -and
        -not [bool]$mock.KeyExists[$cspKey] -and
        [string]$mock.Registry["$desktopKey|Wallpaper"] -eq $defaultPath -and
        -not $mock.Files.ContainsKey($targetPath) -and
        [bool]$mock.RemoveCalled
    ) "Mocked Default failed: $($defaultResult.Message)"
    foreach ($orderedEvent in @('Registry:DeleteKey:', 'Registry:Add:Wallpaper', 'Refresh', 'RemoveFile')) {
        Assert-BoostLabCondition ($mock.Events.Contains($orderedEvent)) "Default did not record expected event: $orderedEvent"
    }
    Assert-BoostLabCondition (
        $mock.Events.IndexOf('Registry:DeleteKey:') -lt $mock.Events.IndexOf('Registry:Add:Wallpaper') -and
        $mock.Events.IndexOf('Registry:Add:Wallpaper') -lt $mock.Events.IndexOf('Refresh') -and
        $mock.Events.IndexOf('Refresh') -lt $mock.Events.IndexOf('RemoveFile')
    ) 'Default did not preserve the source operation order.'

    $mock.Files[$targetPath] = [pscustomobject]@{ Exists = $true; Path = $targetPath; Length = 200; ErrorMessage = $null }
    $mock.KeyExists[$cspKey] = $true
    $mock.Registry["$cspKey|LockScreenImagePath"] = $targetPath
    $mock.Registry["$cspKey|LockScreenImageStatus"] = 1
    $mock.Registry["$desktopKey|Wallpaper"] = $targetPath
    $failingRegistryRunner = {
        param($Operation)
        $mock.Events.Add("RegistryFail:$($Operation.Operation):$($Operation.Name)")
        [pscustomobject]@{
            Success = $false; ExitCode = 1; Operation = $Operation.Operation
            Key = $Operation.Key; Name = $Operation.Name; Message = 'Mock registry failure.'
        }
    }
    $failedDefaultResult = Invoke-WallpaperTestBoostLabToolAction `
        -ActionName 'Default' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -RegistryCommandRunner $failingRegistryRunner `
        -RegistryReader $registryReader `
        -RegistryKeyReader $registryKeyReader `
        -FileReader $fileReader `
        -ImageGenerator $imageGenerator `
        -WallpaperRefresher $refresher `
        -FileRemover $fileRemover
    Assert-BoostLabCondition (
        -not [bool]$failedDefaultResult.Success -and
        [string]$failedDefaultResult.Data.CommandStatus -eq 'Failed verification'
    ) 'Default reported success when mocked registry verification failed.'

    $cancelled = Invoke-WallpaperTestBoostLabToolAction -ActionName 'Apply' -Confirmed:$false
    Assert-BoostLabCondition (
        [bool]$cancelled.Cancelled -and [string]$cancelled.Message -eq 'Cancelled by user'
    ) 'The module did not enforce explicit confirmation.'
}
finally {
    Remove-Module -ModuleInfo $wallpaperModule -Force -ErrorAction SilentlyContinue
}

$actionPlanModule = Import-Module `
    -Name $actionPlanPath `
    -Force `
    -PassThru `
    -Prefix 'WallpaperPlanTest' `
    -Scope Local `
    -DisableNameChecking `
    -ErrorAction Stop
try {
    $applyPlan = New-WallpaperPlanTestBoostLabActionPlan -ToolMetadata $tool -ActionName 'Apply' -IsDryRun:$false
    $defaultPlan = New-WallpaperPlanTestBoostLabActionPlan -ToolMetadata $tool -ActionName 'Default' -IsDryRun:$false
    Assert-BoostLabCondition (
        [bool]$applyPlan.RequiresAdmin -and
        [bool]$applyPlan.NeedsExplicitConfirmation -and
        [bool]$defaultPlan.NeedsExplicitConfirmation
    ) 'Action Plan privilege or confirmation behavior is incorrect.'
    $applyPlanText = @(@($applyPlan.PlannedChanges) + @($applyPlan.SideEffects) + @($applyPlan.ConfirmationMessage)) -join [Environment]::NewLine
    $defaultPlanText = @(@($defaultPlan.PlannedChanges) + @($defaultPlan.SideEffects) + @($defaultPlan.ConfirmationMessage)) -join [Environment]::NewLine
    foreach ($requiredText in @(
        'Generate C:\Windows\Black.jpg'
        'LockScreenImagePath'
        'LockScreenImageStatus'
        'Wallpaper value to C:\Windows\Black.jpg'
    )) {
        Assert-BoostLabCondition ($applyPlanText.Contains($requiredText)) "Apply Action Plan is missing: $requiredText"
    }
    foreach ($requiredText in @(
        'Delete the complete HKLM PersonalizationCSP key'
        'C:\Windows\Web\Wallpaper\Windows\img0.jpg'
        'Delete C:\Windows\Black.jpg'
    )) {
        Assert-BoostLabCondition ($defaultPlanText.Contains($requiredText)) "Default Action Plan is missing: $requiredText"
    }
    foreach ($forbiddenPlanText in @('back up', 'ownership', 'Remove only', 'Leave the shared PersonalizationCSP key')) {
        Assert-BoostLabCondition (-not $applyPlanText.Contains($forbiddenPlanText)) "Apply Action Plan still contains old deviation wording: $forbiddenPlanText"
        Assert-BoostLabCondition (-not $defaultPlanText.Contains($forbiddenPlanText)) "Default Action Plan still contains old deviation wording: $forbiddenPlanText"
    }
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$executionSource = Get-Content -Raw -LiteralPath $executionPath
foreach ($requiredText in @(
    '''signout-lockscreen-wallpaper-black'' = @{'
    'Windows\SignoutLockScreenWallpaperBlack.psm1'
    'Actions = @(''Apply'', ''Default'')'
    'ToolAction.VerificationRuntimeFailed'
    'Verification contract validation failed'
)) {
    Assert-BoostLabCondition ($executionSource.Contains($requiredText)) "Execution runtime mapping is missing: $requiredText"
}

$uiSource = Get-Content -Raw -LiteralPath $uiPath
foreach ($requiredText in @(
    '$toolId -eq ''signout-lockscreen-wallpaper-black'''
    'Expected Lock Screen / Signout Wallpaper state'
    'Detected Lock Screen / Signout Wallpaper state'
    'Registry values checked'
    'File paths checked'
    'Backup / ownership status'
)) {
    Assert-BoostLabCondition ($uiSource.Contains($requiredText)) "Latest Result rendering is missing: $requiredText"
}

Assert-BoostLabCondition (Test-Path -LiteralPath $recordPath -PathType Leaf) 'The Signout LockScreen Wallpaper Black migration record is missing.'
$recordSource = Get-Content -Raw -LiteralPath $recordPath
foreach ($requiredText in @(
    'C5A3E791BB85EE166397748D95B0BD4725063B55DC50CAEA805DC212E485C64C'
    'Exact Ultimate parity implemented and accepted in Phase 139'
    'Default deletes the complete `PersonalizationCSP` key'
    'There is no BoostLab backup or ownership-state wrapper'
    'Default is not Restore'
)) {
    Assert-BoostLabCondition ($recordSource.Contains($requiredText)) "Migration record is missing: $requiredText"
}
foreach ($forbiddenRecordText in @(
    'Yazan-Approved Registry Deviation'
    'Yazan-Approved File Ownership Deviation'
    'does not delete this shared key'
    'removes only the exact values managed by this tool'
    'left intact and the result is `Warning`'
)) {
    Assert-BoostLabCondition (-not $recordSource.Contains($forbiddenRecordText)) "Migration record still contains old deviation text: $forbiddenRecordText"
}

$signoutRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'signout-lockscreen-wallpaper-black' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $signoutRecord) 'Signout parity baseline record is missing.'
Assert-BoostLabCondition ([string]$signoutRecord.ImplementationLevel -eq 'ParityImplemented') 'Signout must be ParityImplemented after Phase 139.'
Assert-BoostLabCondition ([string]$signoutRecord.UltimateParity -eq 'Yes') 'Signout UltimateParity must be Yes after Phase 139.'
Assert-BoostLabCondition (-not [bool]$signoutRecord.YazanFinalException) 'Signout must not use YazanFinalException for exact parity.'
$firstNonFinalTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $parityOrder
Assert-BoostLabCondition ($null -ne $firstNonFinalTarget) 'Ordered parity helper must still resolve a first non-final target.'
$isOrderedParityComplete = ($parityBaseline.ContainsKey('OrderedParityComplete') -and [bool]$parityBaseline.OrderedParityComplete)
if ($isOrderedParityComplete) {
    Assert-BoostLabCondition ($null -eq $parityBaseline.CurrentOrderedParityTarget) 'Completed ordered parity must not keep a current target.'
    Assert-BoostLabCondition ([bool]$firstNonFinalTarget.IsOrderedParityComplete) 'Ordered parity helper must report completion.'
}
else {
    $cursorRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq [string]$parityBaseline.CurrentOrderedParityTarget }) | Select-Object -First 1
    Assert-BoostLabCondition ($null -ne $cursorRecord) 'Current ordered parity target must resolve to a parity baseline record.'
    $cursorOrderRecord = @($parityOrder.Stages | ForEach-Object { @($_.Tools) } | Where-Object { [string]$_.ToolId -eq [string]$parityBaseline.CurrentOrderedParityTarget }) | Select-Object -First 1
    Assert-BoostLabCondition ($null -ne $cursorOrderRecord) 'Current ordered parity target must resolve to the canonical ordered parity list.'
}
$categoryCounts = Get-BoostLabParityCategoryCounts -ParityBaseline $parityBaseline
Assert-BoostLabCondition ([int]$categoryCounts['ParityImplemented'] -eq [int]$parityBaseline.Counts.UltimateParityImplemented) 'ParityImplemented count mismatch.'
Assert-BoostLabCondition ([int]$categoryCounts['NearParityControlled'] -eq [int]$parityBaseline.Counts.NearParityControlled) 'NearParityControlled count mismatch.'

$protectedModuleHashes = [ordered]@{
    'Windows\ContextMenu.psm1' = '1F875028B1C730323E44F59CE80C9A7F8B5DE1407BB2425BD58C5924BACCA3C2'
    'Windows\StartMenuLayout.psm1' = 'D93019267A3D566146F713DF69C86F41CDAD93A2B0786D5CB8DDF9F2878E103A'
    'Windows\ThemeBlack.psm1' = '29F3474D93061B01E3CF9F23EADA88E932E90E4984EBB39F7DB2BEB24732230F'
    'Windows\game-bar.psm1' = '62B195F5D2FACF5C1060ED23704A46317392FD7488768FF43883AA6BE0062B33'
    'Windows\copilot.psm1' = 'B4E7FEC7BF1BE0AD4D5B8295008C315409B261388DB782541102409DC7E239B7'
    'Windows\game-mode.psm1' = 'CADEC6B0E4262990BF9D9BBDBD8DBA55EE910EEFC1FF72B78912800AD04624E9'
}
foreach ($relativePath in $protectedModuleHashes.Keys) {
    $protectedPath = Join-Path $modulesRoot $relativePath
    Assert-BoostLabCondition (
        (Get-FileHash -Algorithm SHA256 -LiteralPath $protectedPath).Hash -eq $protectedModuleHashes[$relativePath]
    ) "Protected module changed during Phase 139: $relativePath"
}

$sourceUltimateFiles = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File -ErrorAction Stop |
        Where-Object { $_.FullName -notlike '*\17 Loudness EQ.ps1' }
)
Assert-BoostLabCondition ($sourceUltimateFiles.Count -gt 0) 'source-ultimate inventory is unexpectedly empty.'

$gameBarSource = Get-Content -Raw -LiteralPath (Join-Path $modulesRoot 'Windows\game-bar.psm1')
Assert-BoostLabCondition (
    $gameBarSource.Contains('$script:BoostLabImplementedActions = @(''Apply'', ''Default'')')
) 'GameBar is no longer implemented with Apply/Default.'

$deletedToolNames = @(
    'Windows Activation Helper'
    'Firewall'
    'DEP'
    'File Download Security Warning'
    'MPO'
    'FSO'
    'FSE'
    'Hardware Flip'
    'AMD ULPS'
    'WHQL Secure Boot Bypass'
    'Keyboard Shortcuts'
    'Search Shell Mobsync'
    'NVME Faster Driver'
    'Core 1 Thread 1'
    'DDU'
    'UAC'
    'Scaling'
    'Start Menu Shortcuts'
    'Loudness EQ'
)
$toolTitles = @($tools | ForEach-Object { [string]$_['Title'] })
foreach ($deletedToolName in $deletedToolNames) {
    Assert-BoostLabCondition ($deletedToolName -notin $toolTitles) "Deleted tool was reintroduced: $deletedToolName"
}

$allModules = @(
    Get-ChildItem -LiteralPath $modulesRoot -Recurse -File -Filter '*.psm1' |
        Where-Object { $_.Directory.Parent.FullName -eq $modulesRoot }
)
$implementedModules = @(
    $allModules | Where-Object {
        (Get-Content -Raw -LiteralPath $_.FullName).Contains('$script:BoostLabImplementedActions')
    }
)
$placeholderModules = @(
    $allModules | Where-Object {
        (Get-Content -Raw -LiteralPath $_.FullName).Contains('ToolModule.Placeholder.ps1')
    }
)
Assert-BoostLabCondition (
    $implementedModules.Count -eq $inventoryBaseline.ImplementedTools -and
    $placeholderModules.Count -eq $inventoryBaseline.DeferredPlaceholders
) "Unexpected module counts: $($implementedModules.Count) implemented, $($placeholderModules.Count) placeholders."

[pscustomobject]@{
    Success                       = $true
    Tool                          = 'Signout LockScreen Wallpaper Black'
    ImplementedActions            = @('Apply', 'Default')
    MockedApplyPassed             = $true
    MockedDefaultPassed           = $true
    ExactDefaultDeletesCspKey     = $true
    ExactDefaultDeletesBlackJpg   = $true
    BackupOwnershipRemoved        = $true
    CurrentOrderedParityTarget    = [string]$parityBaseline.CurrentOrderedParityTarget
    FirstNonFinalParityTarget     = [string]$firstNonFinalTarget.ToolId
    ImplementedModuleCount        = $implementedModules.Count
    PlaceholderModuleCount        = $placeholderModules.Count
    SystemChangesExecuted         = $false
    Timestamp                     = Get-Date
}
