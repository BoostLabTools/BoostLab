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
        throw 'Unable to determine the User Account Pictures Black test path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\user-account-pictures-black.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\6 User Account Pictures Black.ps1'
$recordPath = Join-Path $ProjectRoot 'docs\migrations\user-account-pictures-black.md'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$sourceHash = '8B978374BC9D5AE51858FC71BE02D0DFFAE29AADFEFAF8662D8654D735443710'

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration['Stages'] | ForEach-Object { @($_['Tools']) })
$tool = $tools |
    Where-Object { $_['Id'] -eq 'user-account-pictures-black' } |
    Select-Object -First 1
if ($null -eq $tool) {
    throw 'User Account Pictures Black metadata is missing.'
}
if (
    [string]$tool['Stage'] -ne 'Windows' -or
    [int]$tool['Order'] -ne 6 -or
    [string]$tool['Type'] -ne 'action' -or
    [string]$tool['RiskLevel'] -ne 'medium' -or
    (@($tool['Actions']) -join ',') -ne 'Apply,Default'
) {
    throw 'User Account Pictures Black metadata does not match Phase 27.'
}

$trueCapabilities = @(
    'RequiresAdmin'
    'CanDeleteFiles'
    'SupportsDefault'
    'NeedsExplicitConfirmation'
)
foreach ($field in $tool['Capabilities'].Keys) {
    if ([bool]$tool['Capabilities'][$field] -ne ($field -in $trueCapabilities)) {
        throw "User Account Pictures Black capability is incorrect: $field"
    }
}

if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -ne $sourceHash) {
    throw 'User Account Pictures Black Ultimate source hash changed.'
}
$source = Get-Content -Raw -LiteralPath $sourcePath
foreach ($requiredSourceText in @(
    '$env:SystemDrive\ProgramData\Microsoft\User Account Pictures'
    '$env:SystemDrive\ProgramData\User Account Pictures'
    'Copy-Item "$env:SystemDrive\ProgramData\Microsoft\User Account Pictures"'
    'Get-ChildItem $accountPicturesPath -Include *.png,*.bmp -Recurse'
    '[System.Drawing.Bitmap]::FromFile($image.FullName)'
    'New-Object System.Drawing.Bitmap($width, $height)'
    '$graphics.Clear([System.Drawing.Color]::Black)'
    '$newBitmap.Save($image.FullName)'
)) {
    if (-not $source.Contains($requiredSourceText)) {
        throw "Ultimate source mapping text is missing: $requiredSourceText"
    }
}
foreach ($forbiddenSourceText in @(
    'Invoke-WebRequest'
    'Start-BitsTransfer'
    'Set-Service'
    'Stop-Service'
    'Restart-Computer'
    'Stop-Process'
    'Remove-AppxPackage'
    'TrustedInstaller'
    'safeboot'
)) {
    if ($source.Contains($forbiddenSourceText)) {
        throw "Ultimate source failed the Phase 27 safety gate: $forbiddenSourceText"
    }
}

$moduleSource = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredModuleText in @(
    '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    '$script:BoostLabApprovedExtensions = @(''.png'', ''.bmp'')'
    'Microsoft\User Account Pictures'
    'Backups\UserAccountPicturesBlack'
    'user-account-pictures-black.json'
    'Copy-BoostLabAccountPictureBackup'
    'Set-BoostLabAccountPictureBlack'
    'Restore-BoostLabAccountPictureBackup'
    'Remove-BoostLabAccountPictureBackupSet'
    'OriginalSha256'
    'BackupSha256'
    'AppliedSha256'
    'LeftIntactUnknownOwnership'
    'New-BoostLabVerificationResult'
    'VerificationResult'
    '[bool]$Confirmed = $false'
)) {
    if (-not $moduleSource.Contains($requiredModuleText)) {
        throw "User Account Pictures Black module is missing: $requiredModuleText"
    }
}
foreach ($forbiddenModuleText in @(
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'Set-Service'
    'Stop-Service'
    'Restart-Service'
    'Restart-Computer'
    'Stop-Computer'
    'Stop-Process'
    'Remove-AppxPackage'
    'UsesTrustedInstaller = $true'
    'safeboot'
    'source-ultimate'
    'ToolModule.Placeholder.ps1'
)) {
    if ($moduleSource.Contains($forbiddenModuleText)) {
        throw "User Account Pictures Black module contains prohibited behavior: $forbiddenModuleText"
    }
}

$tokens = $null
$parseErrors = $null
[void][Management.Automation.Language.Parser]::ParseFile(
    $modulePath,
    [ref]$tokens,
    [ref]$parseErrors
)
if (@($parseErrors).Count -gt 0) {
    throw "User Account Pictures Black syntax error: $($parseErrors[0].Message)"
}

$executionSource = Get-Content -Raw -LiteralPath $executionPath
foreach ($requiredRuntimeText in @(
    "'user-account-pictures-black' = @{"
    'Windows\user-account-pictures-black.psm1'
    "Actions = @('Apply', 'Default')"
)) {
    if (-not $executionSource.Contains($requiredRuntimeText)) {
        throw "Execution runtime mapping is missing: $requiredRuntimeText"
    }
}

if (-not (Test-Path -LiteralPath $recordPath -PathType Leaf)) {
    throw 'User Account Pictures Black migration record is missing.'
}
$record = Get-Content -Raw -LiteralPath $recordPath
foreach ($requiredRecordText in @(
    $sourceHash
    'Microsoft\User Account Pictures'
    'Original SHA-256'
    'Generated black-image SHA-256'
    'LeftIntactUnknownOwnership'
    'Approved by Yazan for Phase 27'
)) {
    if (-not $record.Contains($requiredRecordText)) {
        throw "Migration record is missing: $requiredRecordText"
    }
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
$toolModule = Import-Module -Name $modulePath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    $info = Get-BoostLabToolInfo
    if (
        $info.Id -ne 'user-account-pictures-black' -or
        (@($info.Actions) -join ',') -ne 'Apply,Default' -or
        (@($info.ImplementedActions) -join ',') -ne 'Apply,Default'
    ) {
        throw 'Implemented module metadata is incorrect.'
    }

    $plan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName Apply
    if (
        -not $plan.RequiresAdmin -or
        -not $plan.NeedsExplicitConfirmation -or
        -not $plan.Capabilities.CanDeleteFiles
    ) {
        throw 'User Account Pictures Black Action Plan is missing file-change confirmation requirements.'
    }

    $cancelled = Invoke-BoostLabToolAction -ActionName Apply -Confirmed:$false
    if ($cancelled.Success -or -not $cancelled.Cancelled) {
        throw 'Unconfirmed User Account Pictures Black action was not blocked.'
    }

    function New-AccountPictureMock {
        $targetRoot = 'C:\Mock\ProgramData\Microsoft\User Account Pictures'
        $paths = [pscustomobject]@{
            TargetRoot       = $targetRoot
            LegacyBackupRoot = 'C:\Mock\ProgramData\User Account Pictures'
            StateDirectory   = 'C:\Mock\ProgramData\BoostLab\State'
            BackupRoot       = 'C:\Mock\ProgramData\BoostLab\State\Backups\UserAccountPicturesBlack'
            ManifestPath     = 'C:\Mock\ProgramData\BoostLab\State\user-account-pictures-black.json'
        }
        $state = @{
            Manifest = $null
            Files = @{
                "$targetRoot\user.png" = 'ORIGINAL-PNG'
                "$targetRoot\sub\user.bmp" = 'ORIGINAL-BMP'
            }
            Events = [System.Collections.Generic.List[string]]::new()
            Cleaned = $false
        }
        $imageEnumerator = {
            param($Root)
            @(
                $state.Files.Keys |
                    Where-Object {
                        $_.StartsWith($Root + '\', [StringComparison]::OrdinalIgnoreCase) -and
                        [IO.Path]::GetExtension($_).ToLowerInvariant() -in @('.png', '.bmp')
                    } |
                    Sort-Object |
                    ForEach-Object {
                        [pscustomobject]@{
                            FullName = $_
                            RelativePath = $_.Substring($Root.TrimEnd('\').Length + 1)
                        }
                    }
            )
        }.GetNewClosure()
        $fileStateReader = {
            param($Path)
            if ($state.Files.ContainsKey($Path)) {
                [pscustomobject]@{
                    ReadSucceeded = $true
                    Exists = $true
                    Path = $Path
                    Sha256 = [string]$state.Files[$Path]
                    Length = 1
                    Message = 'Detected'
                }
            }
            else {
                [pscustomobject]@{
                    ReadSucceeded = $true
                    Exists = $false
                    Path = $Path
                    Sha256 = $null
                    Length = $null
                    Message = 'Absent'
                }
            }
        }.GetNewClosure()
        $manifestReader = {
            param($Path)
            [pscustomobject]@{
                ReadSucceeded = $true
                Exists = $null -ne $state.Manifest
                Manifest = $state.Manifest
                Message = 'Read'
            }
        }.GetNewClosure()
        $manifestWriter = {
            param($Manifest, $Path)
            $state.Manifest = $Manifest
            $state.Events.Add('Manifest')
            [pscustomobject]@{ Success = $true; Message = 'Saved' }
        }.GetNewClosure()
        $backupWriter = {
            param($SourcePath, $BackupPath)
            $state.Events.Add("Backup:$SourcePath")
            $state.Files[$BackupPath] = $state.Files[$SourcePath]
            [pscustomobject]@{
                Success = $true
                Sha256 = [string]$state.Files[$SourcePath]
                Message = 'Backed up'
            }
        }.GetNewClosure()
        $blackWriter = {
            param($Path)
            $state.Events.Add("Black:$Path")
            $state.Files[$Path] = "BLACK:$($state.Files[$Path])"
            [pscustomobject]@{
                Success = $true
                Width = 128
                Height = 128
                Sha256 = [string]$state.Files[$Path]
                Message = 'Black'
            }
        }.GetNewClosure()
        $backupRestorer = {
            param($BackupPath, $TargetPath)
            $state.Events.Add("Restore:$TargetPath")
            $state.Files[$TargetPath] = $state.Files[$BackupPath]
            [pscustomobject]@{ Success = $true; Message = 'Restored' }
        }.GetNewClosure()
        $backupCleaner = {
            param($BackupPath, $ApprovedRoot)
            $state.Events.Add("Clean:$BackupPath")
            foreach ($path in @($state.Files.Keys)) {
                if ($path.StartsWith($BackupPath + '\', [StringComparison]::OrdinalIgnoreCase)) {
                    $state.Files.Remove($path)
                }
            }
            $state.Cleaned = $true
            [pscustomobject]@{ Success = $true; Message = 'Cleaned' }
        }.GetNewClosure()

        [pscustomobject]@{
            Paths = $paths
            State = $state
            ImageEnumerator = $imageEnumerator
            FileStateReader = $fileStateReader
            ManifestReader = $manifestReader
            ManifestWriter = $manifestWriter
            BackupWriter = $backupWriter
            BlackWriter = $blackWriter
            BackupRestorer = $backupRestorer
            BackupCleaner = $backupCleaner
        }
    }

    function Invoke-AccountPictureMock {
        param(
            [Parameter(Mandatory)]
            [object]$Harness,

            [Parameter(Mandatory)]
            [ValidateSet('Apply', 'Default')]
            [string]$Action
        )

        & $toolModule {
            param($ActionName, $HarnessValue)
            Invoke-BoostLabUserAccountPicturesBlackAction `
                -ActionName $ActionName `
                -Paths $HarnessValue.Paths `
                -ImageEnumerator $HarnessValue.ImageEnumerator `
                -FileStateReader $HarnessValue.FileStateReader `
                -ManifestReader $HarnessValue.ManifestReader `
                -ManifestWriter $HarnessValue.ManifestWriter `
                -BackupWriter $HarnessValue.BackupWriter `
                -BlackImageWriter $HarnessValue.BlackWriter `
                -BackupRestorer $HarnessValue.BackupRestorer `
                -BackupCleaner $HarnessValue.BackupCleaner
        } $Action $Harness
    }

    $roundTrip = New-AccountPictureMock
    $apply = Invoke-AccountPictureMock -Harness $roundTrip -Action Apply
    if (
        -not $apply.Success -or
        $apply.VerificationResult.Status -ne 'Passed' -or
        @($apply.Data.FilesBackedUp).Count -ne 2 -or
        @($apply.Data.FilesChanged).Count -ne 2
    ) {
        throw 'Mocked Apply did not back up, blacken, and verify both account pictures.'
    }
    $backupIndexes = @(
        0..($roundTrip.State.Events.Count - 1) |
            Where-Object { $roundTrip.State.Events[$_] -like 'Backup:*' }
    )
    $blackIndexes = @(
        0..($roundTrip.State.Events.Count - 1) |
            Where-Object { $roundTrip.State.Events[$_] -like 'Black:*' }
    )
    if (
        $backupIndexes.Count -ne 2 -or
        $blackIndexes.Count -ne 2 -or
        ($backupIndexes | Measure-Object -Maximum).Maximum -gt ($blackIndexes | Measure-Object -Minimum).Minimum
    ) {
        throw 'Apply did not finish all backups before the first account-picture overwrite.'
    }
    foreach ($entry in @($roundTrip.State.Manifest.Files)) {
        if (
            [string]::IsNullOrWhiteSpace([string]$entry.OriginalSha256) -or
            [string]::IsNullOrWhiteSpace([string]$entry.BackupSha256) -or
            [string]::IsNullOrWhiteSpace([string]$entry.AppliedSha256) -or
            [int]$entry.Width -ne 128 -or
            [int]$entry.Height -ne 128
        ) {
            throw 'Apply did not persist complete backup, ownership, hash, and dimension metadata.'
        }
    }

    $default = Invoke-AccountPictureMock -Harness $roundTrip -Action Default
    if (
        -not $default.Success -or
        $default.VerificationResult.Status -ne 'Passed' -or
        $roundTrip.State.Files["$($roundTrip.Paths.TargetRoot)\user.png"] -ne 'ORIGINAL-PNG' -or
        $roundTrip.State.Files["$($roundTrip.Paths.TargetRoot)\sub\user.bmp"] -ne 'ORIGINAL-BMP' -or
        -not $roundTrip.State.Cleaned
    ) {
        throw 'Mocked Default did not restore both originals and clean only the owned backup set.'
    }

    $repeatedDefault = Invoke-AccountPictureMock -Harness $roundTrip -Action Default
    if (-not $repeatedDefault.Success -or $repeatedDefault.VerificationResult.Status -ne 'Passed') {
        throw 'Repeated Default is not idempotent after tool-owned backup cleanup.'
    }

    $unknownCase = New-AccountPictureMock
    $unknownApply = Invoke-AccountPictureMock -Harness $unknownCase -Action Apply
    if (-not $unknownApply.Success) {
        throw 'Unknown-file scenario Apply setup failed.'
    }
    $changedPath = "$($unknownCase.Paths.TargetRoot)\user.png"
    $untrackedPath = "$($unknownCase.Paths.TargetRoot)\new-user.png"
    $unknownCase.State.Files[$changedPath] = 'EXTERNAL-CHANGE'
    $unknownCase.State.Files[$untrackedPath] = 'UNTRACKED'
    $unknownDefault = Invoke-AccountPictureMock -Harness $unknownCase -Action Default
    if (
        -not $unknownDefault.Success -or
        $unknownDefault.VerificationResult.Status -ne 'Warning' -or
        $unknownCase.State.Files[$changedPath] -ne 'EXTERNAL-CHANGE' -or
        $unknownCase.State.Files[$untrackedPath] -ne 'UNTRACKED' -or
        $unknownCase.State.Cleaned -or
        @($unknownDefault.Data.UnknownFiles).Count -lt 2
    ) {
        throw 'Default did not leave externally changed and untracked account pictures intact with warnings.'
    }

    $backupFailure = New-AccountPictureMock
    $backupFailure.BackupWriter = {
        param($SourcePath, $BackupPath)
        $backupFailure.State.Events.Add("BackupFailed:$SourcePath")
        [pscustomobject]@{ Success = $false; Sha256 = $null; Message = 'Injected backup failure' }
    }.GetNewClosure()
    $failedApply = Invoke-AccountPictureMock -Harness $backupFailure -Action Apply
    if (
        $failedApply.Success -or
        @($backupFailure.State.Events | Where-Object { $_ -like 'Black:*' }).Count -ne 0
    ) {
        throw 'Apply changed account pictures after an injected backup failure.'
    }

    $malicious = New-AccountPictureMock
    $malicious.State.Manifest = [pscustomobject]@{
        Version = 1
        ToolId = 'user-account-pictures-black'
        CreatedByBoostLab = $true
        Active = $true
        TargetRoot = $malicious.Paths.TargetRoot
        BackupPath = "$($malicious.Paths.BackupRoot)\owned"
        Files = @(
            [pscustomobject]@{
                RelativePath = '..\Documents\unknown.png'
                TargetPath = 'C:\Mock\Documents\unknown.png'
                BackupPath = "$($malicious.Paths.BackupRoot)\owned\unknown.png"
                OriginalSha256 = 'ORIGINAL'
                AppliedSha256 = 'BLACK'
            }
        )
    }
    $maliciousDefault = Invoke-AccountPictureMock -Harness $malicious -Action Default
    if ($maliciousDefault.Success -or $maliciousDefault.Message -notmatch 'invalid') {
        throw 'Out-of-scope manifest target was not rejected.'
    }
}
finally {
    if ($null -ne $toolModule) {
        Remove-Module -ModuleInfo $toolModule -Force -ErrorAction SilentlyContinue
    }
    if ($null -ne $actionPlanModule) {
        Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
    }
}

$protectedFiles = [ordered]@{
    'modules\Windows\PowerPlan.psm1' = '785A352F3453C71F33A8F4BFE0A381D02CB3A70C7307C77EDADACE98F7FFCF25'
    'modules\Windows\NetworkAdapterPowerSavingsWake.psm1' = '4A0A213032E31B3D4F5A676F0706B8FB354CC0EA3EA6498D6FB51A81B24B3C77'
    'modules\Windows\SignoutLockScreenWallpaperBlack.psm1' = 'FAE90C7491B3B72936D1D293D6435BF6893C8082DCEF4C6F6FDE5E1817F55D74'
    'modules\Windows\ContextMenu.psm1' = '93325E76B02F80B1A105C83F6E268EA3652B4AB9F74582E759A4490CF30D1082'
    'modules\Windows\StartMenuLayout.psm1' = 'D93019267A3D566146F713DF69C86F41CDAD93A2B0786D5CB8DDF9F2878E103A'
    'modules\Windows\ThemeBlack.psm1' = '29F3474D93061B01E3CF9F23EADA88E932E90E4984EBB39F7DB2BEB24732230F'
    'modules\Windows\sound.psm1' = 'B20CBF149CDAA562011AABD05D5828100D0B3810A565A4B7E305EBD50C91FDE3'
    'modules\Windows\game-bar.psm1' = 'E301B2AA588537B81CAB577DA51342FAFFFB7B452C2C36054BD269C51F10CC24'
    'modules\Windows\copilot.psm1' = '740FEDE65972C413A7BF0938F3409AB683B45C914281BDDD6C25222FD39E617D'
    'modules\Windows\game-mode.psm1' = 'CADEC6B0E4262990BF9D9BBDBD8DBA55EE910EEFC1FF72B78912800AD04624E9'
    'modules\Windows\control-panel-settings.psm1' = '6B02392A74AEF177C3249F0A686E48D418693A683F36A7F4C3E9C7BF764941BE'
    'modules\Windows\cleanup.psm1' = '8F916456D7EE24C884AE3450A8127FA52F7013546912D9E5FAD65C28811A5CEB'
}
foreach ($relativePath in $protectedFiles.Keys) {
    $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $ProjectRoot $relativePath)).Hash
    if ($actualHash -ne $protectedFiles[$relativePath]) {
        throw "Protected tool changed during Phase 27: $relativePath"
    }
}

foreach ($placeholderPath in @(
    'modules\Windows\game-bar.psm1'
    'modules\Windows\copilot.psm1'
    'modules\Windows\control-panel-settings.psm1'
    'modules\Setup\edge-settings.psm1'
    'modules\Windows\cleanup.psm1'
)) {
    if (-not (Get-Content -Raw -LiteralPath (Join-Path $ProjectRoot $placeholderPath)).Contains('ToolModule.Placeholder.ps1')) {
        throw "Protected placeholder changed: $placeholderPath"
    }
}

$moduleFiles = @(
    Get-ChildItem -LiteralPath $modulesRoot -Recurse -File -Filter '*.psm1' |
        Where-Object { $_.Directory.Parent.FullName -eq $modulesRoot }
)
$implementedCount = @(
    $moduleFiles | Where-Object {
        (Get-Content -Raw -LiteralPath $_.FullName).Contains('$script:BoostLabImplementedActions')
    }
).Count
$placeholderCount = @(
    $moduleFiles | Where-Object {
        (Get-Content -Raw -LiteralPath $_.FullName).Contains('ToolModule.Placeholder.ps1')
    }
).Count
if ($tools.Count -ne $inventoryBaseline.ActiveTools -or $implementedCount -ne $inventoryBaseline.ImplementedTools -or $placeholderCount -ne $inventoryBaseline.DeferredPlaceholders) {
    throw "Unexpected Phase 27 inventory: $($tools.Count) tools, $implementedCount implemented, $placeholderCount placeholders."
}

if (
    @($tools | Where-Object { $_['Id'] -eq 'loudness-eq' }).Count -ne 0 -or
    (Test-Path -LiteralPath (Join-Path $ProjectRoot 'modules\Windows\loudness-eq.psm1')) -or
    (Test-Path -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\6 Windows\17 Loudness EQ.ps1'))
) {
    throw 'Loudness EQ was reintroduced.'
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$sourceLines = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
        Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } |
        ForEach-Object {
            '{0}|{1}' -f `
                $_.FullName.Substring($root.Length + 1).Replace('\', '/'), `
                (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
        }
)
$sha256 = [Security.Cryptography.SHA256]::Create()
try {
    $sourceManifestHash = [BitConverter]::ToString(
        $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sourceLines -join "`n")))
    ).Replace('-', '')
}
finally {
    $sha256.Dispose()
}
if (
    $sourceLines.Count -ne 49 -or
    $sourceManifestHash -ne '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477'
) {
    throw 'source-ultimate changed during Phase 27.'
}

[pscustomobject]@{
    Success                  = $true
    SourceSHA256             = $sourceHash
    MockedApplyPassed        = $true
    MockedDefaultPassed      = $true
    UnknownFilesPreserved    = $true
    BackupFailureBlocked     = $true
    ImplementedModuleCount   = $implementedCount
    PlaceholderModuleCount   = $placeholderCount
    ActiveToolCount          = $tools.Count
    ProtectedFilesUnchanged  = $true
    Message                  = 'User Account Pictures Black passed static and mocked Phase 27 validation.'
}



