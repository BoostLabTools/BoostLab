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
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\SignoutLockScreenWallpaperBlack.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\5 Signout Lockscreen Wallpaper Black.ps1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$recordPath = Join-Path $ProjectRoot 'docs\migrations\signout-lockscreen-wallpaper-black.md'
$modulesRoot = Join-Path $ProjectRoot 'modules'

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$stages = @($configuration['Stages'] | Sort-Object { [int]$_['Order'] })
$tools = @($stages | ForEach-Object { $_['Tools'] })
$tool = $tools |
    Where-Object { $_['Id'] -eq 'signout-lockscreen-wallpaper-black' } |
    Select-Object -First 1
if ($null -eq $tool) {
    throw 'Signout LockScreen Wallpaper Black metadata is missing.'
}
if (
    [string]$tool['Stage'] -ne 'Windows' -or
    [int]$tool['Order'] -ne 5 -or
    [string]$tool['Type'] -ne 'action' -or
    [string]$tool['RiskLevel'] -ne 'medium' -or
    (@($tool['Actions']) -join ',') -ne 'Apply,Default'
) {
    throw 'Signout LockScreen Wallpaper Black stage, order, type, risk, or actions are incorrect.'
}

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
    if ([bool]$capabilities[$field] -ne $expected) {
        throw "Signout LockScreen Wallpaper Black capability '$field' is incorrect."
    }
}

if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -ne 'C5A3E791BB85EE166397748D95B0BD4725063B55DC50CAEA805DC212E485C64C') {
    throw 'Signout LockScreen Wallpaper Black Ultimate source hash changed.'
}
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
    'Remove-Item -Recurse -Force "C:\Windows\Black.jpg"'
)) {
    if (-not $source.Contains($requiredText)) {
        throw "Ultimate source no longer contains: $requiredText"
    }
}

if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
    throw 'The canonical Signout LockScreen Wallpaper Black module is missing.'
}
$moduleSource = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredText in @(
    '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    'C:\Windows\Black.jpg'
    'C:\Windows\Web\Wallpaper\Windows\img0.jpg'
    'LockScreenImagePath'
    'LockScreenImageStatus'
    'REG_DWORD'
    'UpdatePerUserSystemParameters'
    'System.Windows.Forms.SystemInformation'
    'System.Drawing.Bitmap'
    'FillRectangle'
    'Backup-BoostLabWallpaperFile'
    'Restore-BoostLabWallpaperBackup'
    'Remove-BoostLabOwnedWallpaperFile'
    'signout-lockscreen-wallpaper-black.json'
    'GeneratedFileSha256'
    'OriginalFileSha256'
    'OwnershipUncertain'
    'LeftIntactUnknownOwnership'
    'New-BoostLabVerificationResult'
    'VerificationResult'
    '[bool] $Confirmed = $false'
)) {
    if (-not $moduleSource.Contains($requiredText)) {
        throw "Signout LockScreen Wallpaper Black module is missing: $requiredText"
    }
}
$verificationImportIndex = $moduleSource.IndexOf('-Name $verificationModulePath')
$verificationImportBlock = if ($verificationImportIndex -ge 0) {
    $moduleSource.Substring(
        $verificationImportIndex,
        [Math]::Min(180, $moduleSource.Length - $verificationImportIndex)
    )
}
else {
    ''
}
if ($verificationImportBlock.Contains('-Force')) {
    throw 'The Phase 22 module force-reloads Verification.psm1 and can remove runtime exports.'
}
if (
    $moduleSource -match
        'reg delete\s+["'']?HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\PersonalizationCSP["'']?\s+/f'
) {
    throw 'The module contains the disallowed complete PersonalizationCSP key deletion.'
}
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
    if ($moduleSource.Contains($forbiddenText)) {
        throw "The module contains unrelated behavior: $forbiddenText"
    }
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
    if (@($commands | Where-Object { $_ -eq $forbiddenCommand }).Count -gt 0) {
        throw "The module contains forbidden command: $forbiddenCommand"
    }
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
    if (
        [string]$toolInfo.Id -ne 'signout-lockscreen-wallpaper-black' -or
        (@($toolInfo.Actions) -join ',') -ne 'Apply,Default' -or
        (@($toolInfo.ImplementedActions) -join ',') -ne 'Apply,Default'
    ) {
        throw 'The module metadata or implemented actions are incorrect.'
    }

    $targetPath = 'C:\Windows\Black.jpg'
    $defaultPath = 'C:\Windows\Web\Wallpaper\Windows\img0.jpg'
    $cspKey = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP'
    $desktopKey = 'HKCU\Control Panel\Desktop'
    $mock = @{
        State = $null
        Files = @{}
        Registry = @{}
        Events = [System.Collections.Generic.List[string]]::new()
        RemoveCalled = $false
    }

    $newAbsentState = {
        [pscustomobject]@{
            ReadSucceeded = $true; Exists = $false; Active = $false
            CreatedByBoostLab = $false; PendingApply = $false
            BackupCreated = $false; BackupPath = $null
            OriginalFileSha256 = $null; GeneratedFileSha256 = $null
            OwnershipUncertain = $false; FileDisposition = 'NoState'
            ErrorMessage = $null
        }
    }
    $stateReader = {
        if ($null -eq $mock.State) {
            return & $newAbsentState
        }

        $copy = $mock.State | Select-Object *
        $copy | Add-Member -NotePropertyName ReadSucceeded -NotePropertyValue $true -Force
        $copy | Add-Member -NotePropertyName Exists -NotePropertyValue $true -Force
        return $copy
    }
    $stateWriter = {
        param($State)
        $mock.Events.Add('StateWrite')
        $mock.State = $State | Select-Object *
        [pscustomobject]@{ Success = $true; Message = 'Mock state saved.' }
    }
    $fileReader = {
        param($Path)
        if ($mock.Files.ContainsKey($Path)) {
            return $mock.Files[$Path]
        }

        [pscustomobject]@{
            Exists = $false; Path = $Path; Length = $null
            Sha256 = $null; HashDetected = $false; ErrorMessage = $null
        }
    }
    $backupWriter = {
        param($Path)
        $mock.Events.Add('Backup')
        $backupPath = 'X:\BoostLabState\Black.jpg.backup'
        $sourceState = $mock.Files[$Path]
        $mock.Files[$backupPath] = [pscustomobject]@{
            Exists = $true; Path = $backupPath; Length = 100
            Sha256 = $sourceState.Sha256; HashDetected = $true; ErrorMessage = $null
        }
        [pscustomobject]@{
            Success = $true; BackupPath = $backupPath
            Sha256 = $sourceState.Sha256; Message = 'Mock backup created.'
        }
    }
    $backupRestorer = {
        param($BackupPath, $TargetPath)
        $mock.Events.Add('RestoreBackup')
        $backupState = $mock.Files[$BackupPath]
        $mock.Files[$TargetPath] = [pscustomobject]@{
            Exists = $true; Path = $TargetPath; Length = $backupState.Length
            Sha256 = $backupState.Sha256; HashDetected = $true; ErrorMessage = $null
        }
        [pscustomobject]@{ Success = $true; Message = 'Mock backup restored.' }
    }
    $ownedFileRemover = {
        param($Path)
        $mock.Events.Add('RemoveOwnedFile')
        $mock.RemoveCalled = $true
        [void]$mock.Files.Remove($Path)
        [pscustomobject]@{ Success = $true; Message = 'Mock owned file removed.' }
    }
    $imageGenerator = {
        param($Path)
        $mock.Events.Add('GenerateImage')
        $mock.Files[$Path] = [pscustomobject]@{
            Exists = $true; Path = $Path; Length = 200
            Sha256 = 'BOOSTLAB-GENERATED'; HashDetected = $true; ErrorMessage = $null
        }
        [pscustomobject]@{
            Success = $true; Width = 1920; Height = 1080
            Message = 'Mock image generated.'
        }
    }
    $registryRunner = {
        param($Operation)
        $mock.Events.Add("Registry:$($Operation.Operation):$($Operation.Name)")
        $lookupKey = "$($Operation.Key)|$($Operation.Name)"
        if ($Operation.Operation -eq 'DeleteValue') {
            [void]$mock.Registry.Remove($lookupKey)
        }
        else {
            $mock.Registry[$lookupKey] = $Operation.Value
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

        [pscustomobject]@{
            Detected = $true; Exists = $false; Value = $null; ErrorMessage = $null
        }
    }
    $refresher = {
        $mock.Events.Add('Refresh')
        [pscustomobject]@{ Success = $true; ExitCode = 0; Message = 'Mock refresh requested.' }
    }

    $mock.Files[$targetPath] = [pscustomobject]@{
        Exists = $true; Path = $targetPath; Length = 100
        Sha256 = 'ORIGINAL-FILE'; HashDetected = $true; ErrorMessage = $null
    }
    $applyResult = Invoke-WallpaperTestBoostLabToolAction `
        -ActionName 'Apply' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -RegistryCommandRunner $registryRunner `
        -RegistryReader $registryReader `
        -FileReader $fileReader `
        -StateReader $stateReader `
        -StateWriter $stateWriter `
        -BackupWriter $backupWriter `
        -BackupRestorer $backupRestorer `
        -OwnedFileRemover $ownedFileRemover `
        -ImageGenerator $imageGenerator `
        -WallpaperRefresher $refresher
    if (
        -not [bool]$applyResult.Success -or
        $null -eq $applyResult.VerificationResult -or
        [string]$applyResult.VerificationResult.Status -ne 'Passed' -or
        [string]$mock.Files[$targetPath].Sha256 -ne 'BOOSTLAB-GENERATED' -or
        [string]$mock.State.OriginalFileSha256 -ne 'ORIGINAL-FILE' -or
        [string]$mock.State.GeneratedFileSha256 -ne 'BOOSTLAB-GENERATED'
    ) {
        throw "Mocked Apply failed: $($applyResult.Message)"
    }
    if ($mock.Events.IndexOf('Backup') -gt $mock.Events.IndexOf('GenerateImage')) {
        throw 'Apply did not back up the pre-existing Black.jpg before overwrite.'
    }
    if (
        [string]$mock.Registry["$cspKey|LockScreenImagePath"] -ne $targetPath -or
        [int]$mock.Registry["$cspKey|LockScreenImageStatus"] -ne 1 -or
        [string]$mock.Registry["$desktopKey|Wallpaper"] -ne $targetPath
    ) {
        throw 'Apply did not preserve the approved registry values.'
    }

    $mock.Events.Clear()
    $defaultResult = Invoke-WallpaperTestBoostLabToolAction `
        -ActionName 'Default' `
        -Confirmed:$true `
        -AdministratorChecker { $true } `
        -RegistryCommandRunner $registryRunner `
        -RegistryReader $registryReader `
        -FileReader $fileReader `
        -StateReader $stateReader `
        -StateWriter $stateWriter `
        -BackupWriter $backupWriter `
        -BackupRestorer $backupRestorer `
        -OwnedFileRemover $ownedFileRemover `
        -ImageGenerator $imageGenerator `
        -WallpaperRefresher $refresher
    if (
        -not [bool]$defaultResult.Success -or
        $null -eq $defaultResult.VerificationResult -or
        [string]$defaultResult.VerificationResult.Status -ne 'Passed' -or
        [string]$defaultResult.Data.FileDisposition -ne 'Restored' -or
        [string]$mock.Files[$targetPath].Sha256 -ne 'ORIGINAL-FILE' -or
        $mock.Registry.ContainsKey("$cspKey|LockScreenImagePath") -or
        $mock.Registry.ContainsKey("$cspKey|LockScreenImageStatus") -or
        [string]$mock.Registry["$desktopKey|Wallpaper"] -ne $defaultPath
    ) {
        throw "Mocked Default backup restore failed: $($defaultResult.Message)"
    }
    if ($mock.Events.IndexOf('Refresh') -gt $mock.Events.IndexOf('RestoreBackup')) {
        throw 'Default did not preserve the source order of refresh before file restore.'
    }

    $mock.State = [pscustomobject]@{
        Version = 1; Active = $true; CreatedByBoostLab = $true
        BackupCreated = $false; BackupPath = $null
        OriginalFileSha256 = $null; GeneratedFileSha256 = 'BOOSTLAB-GENERATED'
        OwnershipUncertain = $false; FileDisposition = 'Generated'
    }
    $mock.Files[$targetPath] = [pscustomobject]@{
        Exists = $true; Path = $targetPath; Length = 200
        Sha256 = 'BOOSTLAB-GENERATED'; HashDetected = $true; ErrorMessage = $null
    }
    $mock.Registry["$cspKey|LockScreenImagePath"] = $targetPath
    $mock.Registry["$cspKey|LockScreenImageStatus"] = 1
    $mock.Registry["$desktopKey|Wallpaper"] = $targetPath
    $mock.RemoveCalled = $false
    $ownedDefaultResult = Invoke-WallpaperTestBoostLabToolAction `
        -ActionName 'Default' -Confirmed:$true `
        -AdministratorChecker { $true } `
        -RegistryCommandRunner $registryRunner -RegistryReader $registryReader `
        -FileReader $fileReader -StateReader $stateReader -StateWriter $stateWriter `
        -BackupWriter $backupWriter -BackupRestorer $backupRestorer `
        -OwnedFileRemover $ownedFileRemover -ImageGenerator $imageGenerator `
        -WallpaperRefresher $refresher
    if (
        -not [bool]$ownedDefaultResult.Success -or
        -not [bool]$mock.RemoveCalled -or
        $mock.Files.ContainsKey($targetPath) -or
        [string]$ownedDefaultResult.Data.FileDisposition -ne 'Removed'
    ) {
        throw 'Default did not remove a hash-proven BoostLab-owned Black.jpg.'
    }

    $mock.State = $null
    $mock.Files[$targetPath] = [pscustomobject]@{
        Exists = $true; Path = $targetPath; Length = 300
        Sha256 = 'UNRELATED-FILE'; HashDetected = $true; ErrorMessage = $null
    }
    $mock.Registry["$cspKey|LockScreenImagePath"] = $targetPath
    $mock.Registry["$cspKey|LockScreenImageStatus"] = 1
    $mock.Registry["$desktopKey|Wallpaper"] = $targetPath
    $mock.RemoveCalled = $false
    $unknownDefaultResult = Invoke-WallpaperTestBoostLabToolAction `
        -ActionName 'Default' -Confirmed:$true `
        -AdministratorChecker { $true } `
        -RegistryCommandRunner $registryRunner -RegistryReader $registryReader `
        -FileReader $fileReader -StateReader $stateReader -StateWriter $stateWriter `
        -BackupWriter $backupWriter -BackupRestorer $backupRestorer `
        -OwnedFileRemover $ownedFileRemover -ImageGenerator $imageGenerator `
        -WallpaperRefresher $refresher
    if (
        -not [bool]$unknownDefaultResult.Success -or
        [string]$unknownDefaultResult.VerificationResult.Status -ne 'Warning' -or
        [string]$unknownDefaultResult.Data.FileDisposition -ne 'LeftIntactUnknownOwnership' -or
        [bool]$mock.RemoveCalled -or
        -not $mock.Files.ContainsKey($targetPath) -or
        [string]$mock.Files[$targetPath].Sha256 -ne 'UNRELATED-FILE'
    ) {
        throw 'Default did not preserve an unrelated Black.jpg with a Warning.'
    }

    $mock.State = [pscustomobject]@{
        Version = 1; Active = $false; PendingApply = $true; CreatedByBoostLab = $true
        BackupCreated = $true; BackupPath = 'X:\BoostLabState\Black.jpg.interrupted.backup'
        OriginalFileSha256 = 'INTERRUPTED-ORIGINAL'; GeneratedFileSha256 = $null
        OwnershipUncertain = $false; FileDisposition = 'PendingApply'
    }
    $mock.Files['X:\BoostLabState\Black.jpg.interrupted.backup'] = [pscustomobject]@{
        Exists = $true; Path = 'X:\BoostLabState\Black.jpg.interrupted.backup'; Length = 400
        Sha256 = 'INTERRUPTED-ORIGINAL'; HashDetected = $true; ErrorMessage = $null
    }
    $mock.Files[$targetPath] = [pscustomobject]@{
        Exists = $true; Path = $targetPath; Length = 200
        Sha256 = 'INTERRUPTED-GENERATED'; HashDetected = $true; ErrorMessage = $null
    }
    $mock.Registry["$cspKey|LockScreenImagePath"] = $targetPath
    $mock.Registry["$cspKey|LockScreenImageStatus"] = 1
    $mock.Registry["$desktopKey|Wallpaper"] = $targetPath
    $interruptedDefaultResult = Invoke-WallpaperTestBoostLabToolAction `
        -ActionName 'Default' -Confirmed:$true `
        -AdministratorChecker { $true } `
        -RegistryCommandRunner $registryRunner -RegistryReader $registryReader `
        -FileReader $fileReader -StateReader $stateReader -StateWriter $stateWriter `
        -BackupWriter $backupWriter -BackupRestorer $backupRestorer `
        -OwnedFileRemover $ownedFileRemover -ImageGenerator $imageGenerator `
        -WallpaperRefresher $refresher
    if (
        -not [bool]$interruptedDefaultResult.Success -or
        [string]$interruptedDefaultResult.Data.FileDisposition -ne 'Restored' -or
        [string]$mock.Files[$targetPath].Sha256 -ne 'INTERRUPTED-ORIGINAL'
    ) {
        throw 'Default did not restore the backup recorded by an interrupted Apply.'
    }

    $mock.State = $null
    [void]$mock.Files.Remove($targetPath)
    $failingRefresher = {
        [pscustomobject]@{
            Success = $false; ExitCode = 1; Message = 'Mock wallpaper refresh failure.'
        }
    }
    $refreshWarningResult = Invoke-WallpaperTestBoostLabToolAction `
        -ActionName 'Default' -Confirmed:$true `
        -AdministratorChecker { $true } `
        -RegistryCommandRunner $registryRunner -RegistryReader $registryReader `
        -FileReader $fileReader -StateReader $stateReader -StateWriter $stateWriter `
        -BackupWriter $backupWriter -BackupRestorer $backupRestorer `
        -OwnedFileRemover $ownedFileRemover -ImageGenerator $imageGenerator `
        -WallpaperRefresher $failingRefresher
    if (
        -not [bool]$refreshWarningResult.Success -or
        [string]$refreshWarningResult.VerificationResult.Status -ne 'Warning'
    ) {
        throw "A failed wallpaper refresh did not produce a Verification Warning. Success=$($refreshWarningResult.Success); Verification=$($refreshWarningResult.VerificationResult.Status); Message=$($refreshWarningResult.Message)"
    }

    $cancelled = Invoke-WallpaperTestBoostLabToolAction -ActionName 'Apply' -Confirmed:$false
    if (-not [bool]$cancelled.Cancelled -or [string]$cancelled.Message -ne 'Cancelled by user') {
        throw 'The module did not enforce explicit confirmation.'
    }
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
    if (
        -not [bool]$applyPlan.RequiresAdmin -or
        -not [bool]$applyPlan.NeedsExplicitConfirmation -or
        -not [bool]$defaultPlan.NeedsExplicitConfirmation
    ) {
        throw 'Action Plan privilege or confirmation behavior is incorrect.'
    }
    $applyPlanText = @($applyPlan.PlannedChanges) -join [Environment]::NewLine
    $defaultPlanText = @($defaultPlan.PlannedChanges) -join [Environment]::NewLine
    foreach ($requiredText in @(
        'C:\Windows\Black.jpg'
        'PersonalizationCSP'
        'back up'
        'ownership metadata'
    )) {
        if (-not $applyPlanText.Contains($requiredText)) {
            throw "Apply Action Plan is missing: $requiredText"
        }
    }
    foreach ($requiredText in @(
        'Remove only the tool-owned PersonalizationCSP values'
        'Leave the shared PersonalizationCSP key'
        'Restore a recorded backup'
        'leave uncertain or unrelated files intact'
    )) {
        if (-not $defaultPlanText.Contains($requiredText)) {
            throw "Default Action Plan is missing: $requiredText"
        }
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
    if (-not $executionSource.Contains($requiredText)) {
        throw "Execution runtime mapping is missing: $requiredText"
    }
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
    if (-not $uiSource.Contains($requiredText)) {
        throw "Latest Result rendering is missing: $requiredText"
    }
}

if (-not (Test-Path -LiteralPath $recordPath -PathType Leaf)) {
    throw 'The Signout LockScreen Wallpaper Black migration record is missing.'
}
$recordSource = Get-Content -Raw -LiteralPath $recordPath
foreach ($requiredText in @(
    'C5A3E791BB85EE166397748D95B0BD4725063B55DC50CAEA805DC212E485C64C'
    'Yazan-Approved Registry Deviation'
    'Yazan-Approved File Ownership Deviation'
    'does not delete this shared key'
    'removes only the exact values managed by this tool'
    'left intact and the result is `Warning`'
)) {
    if (-not $recordSource.Contains($requiredText)) {
        throw "Migration record is missing: $requiredText"
    }
}

$protectedModuleHashes = [ordered]@{
    'Windows\ContextMenu.psm1' = '1F875028B1C730323E44F59CE80C9A7F8B5DE1407BB2425BD58C5924BACCA3C2'
    'Windows\StartMenuLayout.psm1' = 'D93019267A3D566146F713DF69C86F41CDAD93A2B0786D5CB8DDF9F2878E103A'
    'Windows\ThemeBlack.psm1' = '29F3474D93061B01E3CF9F23EADA88E932E90E4984EBB39F7DB2BEB24732230F'
    'Windows\game-bar.psm1' = 'E301B2AA588537B81CAB577DA51342FAFFFB7B452C2C36054BD269C51F10CC24'
    'Windows\copilot.psm1' = '740FEDE65972C413A7BF0938F3409AB683B45C914281BDDD6C25222FD39E617D'
    'Windows\game-mode.psm1' = 'CADEC6B0E4262990BF9D9BBDBD8DBA55EE910EEFC1FF72B78912800AD04624E9'
}
foreach ($relativePath in $protectedModuleHashes.Keys) {
    $protectedPath = Join-Path $modulesRoot $relativePath
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $protectedPath).Hash -ne $protectedModuleHashes[$relativePath]) {
        throw "Protected module changed during Phase 22: $relativePath"
    }
}

$gameBarSource = Get-Content -Raw -LiteralPath (Join-Path $modulesRoot 'Windows\game-bar.psm1')
$copilotSource = Get-Content -Raw -LiteralPath (Join-Path $modulesRoot 'Windows\copilot.psm1')
if (
    -not $gameBarSource.Contains('ToolModule.Placeholder.ps1') -or
    -not $copilotSource.Contains('ToolModule.Placeholder.ps1')
) {
    throw 'GameBar or Copilot is no longer a placeholder.'
}

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
    if ($deletedToolName -in $toolTitles) {
        throw "Deleted tool was reintroduced: $deletedToolName"
    }
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
if (
    $implementedModules.Count -ne $inventoryBaseline.ImplementedTools -or
    $placeholderModules.Count -ne $inventoryBaseline.DeferredPlaceholders
) {
    throw "Unexpected module counts: $($implementedModules.Count) implemented, $($placeholderModules.Count) placeholders."
}

[pscustomobject]@{
    Success                    = $true
    Tool                       = 'Signout LockScreen Wallpaper Black'
    ImplementedActions         = @('Apply', 'Default')
    MockedApplyPassed          = $true
    MockedBackupRestorePassed  = $true
    MockedOwnedDeletePassed    = $true
    MockedUnknownFilePreserved = $true
    MockedInterruptedApplyRestored = $true
    MockedRefreshWarningPassed = $true
    ImplementedModuleCount     = $implementedModules.Count
    PlaceholderModuleCount     = $placeholderModules.Count
    SystemChangesExecuted      = $false
    Timestamp                  = Get-Date
}


