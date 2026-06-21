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
. (Join-Path $ProjectRoot 'tests\BoostLab.ParityStatusBaseline.ps1')
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot
$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$parityOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot

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

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\user-account-pictures-black.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\6 User Account Pictures Black.ps1'
$recordPath = Join-Path $ProjectRoot 'docs\migrations\user-account-pictures-black.md'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$sourceHash = '8B978374BC9D5AE51858FC71BE02D0DFFAE29AADFEFAF8662D8654D735443710'

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration['Stages'] | ForEach-Object { @($_['Tools']) })
$tool = $tools |
    Where-Object { $_['Id'] -eq 'user-account-pictures-black' } |
    Select-Object -First 1
Assert-BoostLabCondition ($null -ne $tool) 'User Account Pictures Black metadata is missing.'
Assert-BoostLabCondition ([string]$tool['Stage'] -eq 'Windows') 'User Account Pictures Black must stay in Windows.'
Assert-BoostLabCondition ([int]$tool['Order'] -eq 6) 'User Account Pictures Black order changed.'
Assert-BoostLabCondition ((@($tool['Actions']) -join ',') -eq 'Apply,Default') 'User Account Pictures Black must expose only Apply and Default.'
Assert-BoostLabCondition ([string]$tool['RiskLevel'] -eq 'medium') 'User Account Pictures Black risk must remain medium.'

$trueCapabilities = @(
    'RequiresAdmin'
    'CanDeleteFiles'
    'SupportsDefault'
    'NeedsExplicitConfirmation'
)
foreach ($field in $tool['Capabilities'].Keys) {
    Assert-BoostLabCondition (
        [bool]$tool['Capabilities'][$field] -eq ($field -in $trueCapabilities)
    ) "User Account Pictures Black capability is incorrect: $field"
}

Assert-BoostLabCondition ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -eq $sourceHash) 'User Account Pictures Black Ultimate source hash changed.'
$source = Get-Content -Raw -LiteralPath $sourcePath
foreach ($requiredSourceText in @(
    '$env:SystemDrive\ProgramData\Microsoft\User Account Pictures'
    '$env:SystemDrive\ProgramData\User Account Pictures'
    'Copy-Item "$env:SystemDrive\ProgramData\Microsoft\User Account Pictures"'
    'Copy-Item "$env:SystemDrive\ProgramData\User Account Pictures"'
    'Get-ChildItem $accountPicturesPath -Include *.png,*.bmp -Recurse'
    '[System.Drawing.Bitmap]::FromFile($image.FullName)'
    'New-Object System.Drawing.Bitmap($width, $height)'
    '$graphics.Clear([System.Drawing.Color]::Black)'
    '$newBitmap.Save($image.FullName)'
)) {
    Assert-BoostLabCondition ($source.Contains($requiredSourceText)) "Ultimate source mapping text is missing: $requiredSourceText"
}
foreach ($forbiddenSourceText in @(
    'Invoke-WebRequest'
    'Start-BitsTransfer'
    'Set-ItemProperty'
    'reg add'
    'Stop-Process'
    'Restart-Computer'
    'TrustedInstaller'
    'safeboot'
)) {
    Assert-BoostLabCondition (-not $source.Contains($forbiddenSourceText)) "Ultimate source has unexpected behavior for this phase: $forbiddenSourceText"
}

$moduleSource = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredModuleText in @(
    '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    '$script:BoostLabApprovedExtensions = @(''.png'', ''.bmp'')'
    'ProgramDataRoot'
    'Microsoft\User Account Pictures'
    'User Account Pictures'
    'Copy-BoostLabUltimateAccountPictureBackup'
    'Get-ChildItem -Path $TargetRoot -Include *.png,*.bmp -Recurse'
    '[System.Drawing.Bitmap]::FromFile($Path)'
    'New-Object System.Drawing.Bitmap($width, $height)'
    'System.Drawing.Color]::Black'
    'Copy-BoostLabUltimateAccountPictureDefault'
    'New-BoostLabVerificationResult'
    'VerificationResult'
    '[bool]$Confirmed = $false'
)) {
    Assert-BoostLabCondition ($moduleSource.Contains($requiredModuleText)) "User Account Pictures Black module is missing exact-parity behavior: $requiredModuleText"
}
foreach ($forbiddenModuleText in @(
    'user-account-pictures-black.json'
    'Backups\UserAccountPicturesBlack'
    'OriginalSha256'
    'BackupSha256'
    'AppliedSha256'
    'LeftIntactUnknownOwnership'
    'Restore-BoostLabAccountPictureBackup'
    'Remove-BoostLabAccountPictureBackupSet'
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'Set-Service'
    'Stop-Service'
    'Restart-Service'
    'Restart-Computer'
    'Stop-Process'
    'Remove-AppxPackage'
    'UsesTrustedInstaller = $true'
    'safeboot'
    'source-ultimate'
)) {
    Assert-BoostLabCondition (-not $moduleSource.Contains($forbiddenModuleText)) "User Account Pictures Black module contains prohibited or stale behavior: $forbiddenModuleText"
}

$tokens = $null
$parseErrors = $null
[void][Management.Automation.Language.Parser]::ParseFile(
    $modulePath,
    [ref]$tokens,
    [ref]$parseErrors
)
$syntaxMessage = if (@($parseErrors).Count -gt 0) { $parseErrors[0].Message } else { 'None' }
Assert-BoostLabCondition (@($parseErrors).Count -eq 0) "User Account Pictures Black syntax error: $syntaxMessage"

$executionSource = Get-Content -Raw -LiteralPath $executionPath
foreach ($requiredRuntimeText in @(
    "'user-account-pictures-black' = @{"
    'Windows\user-account-pictures-black.psm1'
    "Actions = @('Apply', 'Default')"
)) {
    Assert-BoostLabCondition ($executionSource.Contains($requiredRuntimeText)) "Execution runtime mapping is missing: $requiredRuntimeText"
}

Assert-BoostLabCondition (Test-Path -LiteralPath $recordPath -PathType Leaf) 'User Account Pictures Black migration record is missing.'
$record = Get-Content -Raw -LiteralPath $recordPath
foreach ($requiredRecordText in @(
    $sourceHash
    'Exact Ultimate parity implemented and accepted in Phase 140'
    'C:\ProgramData\Microsoft\User Account Pictures'
    'C:\ProgramData\User Account Pictures'
    'Default is not Restore'
    'There is no BoostLab manifest or captured-state restore wrapper'
)) {
    Assert-BoostLabCondition ($record.Contains($requiredRecordText)) "Migration record is missing: $requiredRecordText"
}

function New-AccountPictureHarness {
    $targetRoot = 'C:\Mock\ProgramData\Microsoft\User Account Pictures'
    $paths = [pscustomobject]@{
        ProgramDataRoot  = 'C:\Mock\ProgramData'
        TargetRoot       = $targetRoot
        LegacyBackupRoot = 'C:\Mock\ProgramData\User Account Pictures'
        DefaultTarget    = 'C:\Mock\ProgramData\Microsoft'
    }
    $state = [ordered]@{
        Directories = @{}
        Files = @{}
        Events = [System.Collections.Generic.List[string]]::new()
    }
    $state.Directories[$paths.TargetRoot] = $true
    $state.Directories[$paths.LegacyBackupRoot] = $false
    $state.Files["$targetRoot\user.png"] = 'ORIGINAL-PNG'
    $state.Files["$targetRoot\sub\user.bmp"] = 'ORIGINAL-BMP'
    $state.Files["$targetRoot\sub\ignored.txt"] = 'IGNORED'

    $pathProvider = { $paths }.GetNewClosure()
    $directoryExistsChecker = {
        param($Path)
        return [bool]$state.Directories[$Path]
    }.GetNewClosure()
    $legacyBackupRunner = {
        param($Paths)
        $state.Events.Add('CopyLegacyBackup')
        $state.Directories[$Paths.LegacyBackupRoot] = $true
        [pscustomobject]@{
            Success = $true
            Attempted = $true
            Skipped = $false
            Source = $Paths.TargetRoot
            Destination = $Paths.ProgramDataRoot
            Message = 'Mock legacy backup copy requested.'
        }
    }.GetNewClosure()
    $imageEnumerator = {
        param($Root)
        $state.Events.Add('EnumerateImages')
        @(
            $state.Files.Keys |
                Where-Object {
                    $_.StartsWith($Root + '\', [StringComparison]::OrdinalIgnoreCase) -and
                    [IO.Path]::GetExtension($_).ToLowerInvariant() -in @('.png', '.bmp')
                } |
                Sort-Object |
                ForEach-Object { [pscustomobject]@{ FullName = $_; Name = [IO.Path]::GetFileName($_) } }
        )
    }.GetNewClosure()
    $imageRuntimeLoader = {
        $state.Events.Add('LoadSystemDrawing')
        [pscustomobject]@{ Success = $true; Message = 'Mock image runtime loaded.' }
    }.GetNewClosure()
    $blackImageWriter = {
        param($Path)
        $state.Events.Add("Black:$Path")
        $state.Files[$Path] = "BLACK:$Path"
        [pscustomobject]@{
            Success = $true
            Path = $Path
            Width = 64
            Height = 64
            Message = 'Mock black image written.'
        }
    }.GetNewClosure()
    $defaultCopyRunner = {
        param($Paths)
        $state.Events.Add('CopyLegacyBackupToMicrosoft')
        [pscustomobject]@{
            Success = $true
            Attempted = $true
            Source = $Paths.LegacyBackupRoot
            Destination = $Paths.DefaultTarget
            Message = 'Mock default copy requested.'
        }
    }.GetNewClosure()

    [pscustomobject]@{
        Paths = $paths
        State = $state
        PathProvider = $pathProvider
        DirectoryExistsChecker = $directoryExistsChecker
        LegacyBackupRunner = $legacyBackupRunner
        ImageEnumerator = $imageEnumerator
        ImageRuntimeLoader = $imageRuntimeLoader
        BlackImageWriter = $blackImageWriter
        DefaultCopyRunner = $defaultCopyRunner
    }
}

$toolModule = $null
try {
    $toolModule = Import-Module -Name $modulePath -Force -PassThru -Scope Local -ErrorAction Stop

    $info = & $toolModule { Get-BoostLabToolInfo }
    Assert-BoostLabCondition ($info.Id -eq 'user-account-pictures-black') 'Implemented module metadata has wrong tool id.'
    Assert-BoostLabCondition ((@($info.Actions) -join ',') -eq 'Apply,Default') 'Implemented module metadata must expose Apply and Default only.'
    Assert-BoostLabCondition ((@($info.ImplementedActions) -join ',') -eq 'Apply,Default') 'Implemented module actions must expose Apply and Default only.'
    Assert-BoostLabCondition (-not [bool]$info.Capabilities.SupportsRestore) 'User Account Pictures Black must not expose Restore.'

    $cancelled = & $toolModule { Invoke-BoostLabToolAction -ActionName Apply -Confirmed:$false }
    Assert-BoostLabCondition (-not $cancelled.Success -and [bool]$cancelled.Cancelled) 'Unconfirmed Apply was not blocked.'
    Assert-BoostLabCondition (-not [bool]$cancelled.Data.ChangesExecuted) 'Unconfirmed Apply must execute no changes.'

    $applyHarness = New-AccountPictureHarness
    $apply = & $toolModule {
        param($HarnessValue)
        Invoke-BoostLabToolAction `
            -ActionName Apply `
            -Confirmed:$true `
            -AdministratorChecker { $true } `
            -PathProvider $HarnessValue.PathProvider `
            -DirectoryExistsChecker $HarnessValue.DirectoryExistsChecker `
            -LegacyBackupRunner $HarnessValue.LegacyBackupRunner `
            -ImageEnumerator $HarnessValue.ImageEnumerator `
            -ImageRuntimeLoader $HarnessValue.ImageRuntimeLoader `
            -BlackImageWriter $HarnessValue.BlackImageWriter `
            -DefaultCopyRunner $HarnessValue.DefaultCopyRunner
    } $applyHarness
    Assert-BoostLabCondition ($apply.Success) 'Mocked Apply failed.'
    Assert-BoostLabCondition ($apply.VerificationResult.Status -eq 'Passed') 'Mocked Apply verification did not pass.'
    Assert-BoostLabCondition (@($apply.Data.TargetedFiles).Count -eq 2) 'Apply did not target exactly the mock PNG/BMP files.'
    Assert-BoostLabCondition (@($apply.Data.ChangedFiles).Count -eq 2) 'Apply did not write exactly the mock PNG/BMP files.'
    Assert-BoostLabCondition ($applyHarness.State.Files["$($applyHarness.Paths.TargetRoot)\sub\ignored.txt"] -eq 'IGNORED') 'Apply touched a non-PNG/BMP file.'
    $applyEvents = @($applyHarness.State.Events)
    Assert-BoostLabCondition ($applyEvents[0] -eq 'CopyLegacyBackup') 'Apply did not request the source legacy backup copy first.'
    Assert-BoostLabCondition ($applyEvents[1] -eq 'EnumerateImages') 'Apply did not enumerate images after the backup branch.'
    Assert-BoostLabCondition ($applyEvents[2] -eq 'LoadSystemDrawing') 'Apply did not load System.Drawing before black-image writes.'
    Assert-BoostLabCondition (@($applyEvents | Where-Object { $_ -like 'Black:*' }).Count -eq 2) 'Apply did not write both discovered images.'

    $defaultHarness = New-AccountPictureHarness
    $default = & $toolModule {
        param($HarnessValue)
        Invoke-BoostLabToolAction `
            -ActionName Default `
            -Confirmed:$true `
            -AdministratorChecker { $true } `
            -PathProvider $HarnessValue.PathProvider `
            -DirectoryExistsChecker $HarnessValue.DirectoryExistsChecker `
            -LegacyBackupRunner $HarnessValue.LegacyBackupRunner `
            -ImageEnumerator $HarnessValue.ImageEnumerator `
            -ImageRuntimeLoader $HarnessValue.ImageRuntimeLoader `
            -BlackImageWriter $HarnessValue.BlackImageWriter `
            -DefaultCopyRunner $HarnessValue.DefaultCopyRunner
    } $defaultHarness
    Assert-BoostLabCondition ($default.Success) 'Mocked Default failed.'
    Assert-BoostLabCondition ($default.VerificationResult.Status -eq 'Passed') 'Mocked Default verification did not pass.'
    Assert-BoostLabCondition ((@($defaultHarness.State.Events) -join ',') -eq 'CopyLegacyBackupToMicrosoft') 'Default must only request the source legacy backup copy-back operation.'
    Assert-BoostLabCondition ($default.Data.CopyResult.Source -eq $defaultHarness.Paths.LegacyBackupRoot) 'Default source path is wrong.'
    Assert-BoostLabCondition ($default.Data.CopyResult.Destination -eq $defaultHarness.Paths.DefaultTarget) 'Default destination path is wrong.'
}
finally {
    if ($null -ne $toolModule) {
        Remove-Module -ModuleInfo $toolModule -Force -ErrorAction SilentlyContinue
    }
}

$userRecord = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'user-account-pictures-black' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $userRecord) 'User Account Pictures Black parity baseline record is missing.'
Assert-BoostLabCondition ([string]$userRecord.ImplementationLevel -eq 'ParityImplemented') 'User Account Pictures Black must be ParityImplemented after Phase 140.'
Assert-BoostLabCondition ([string]$userRecord.UltimateParity -eq 'Yes') 'User Account Pictures Black UltimateParity must be Yes after Phase 140.'
Assert-BoostLabCondition (-not [bool]$userRecord.YazanFinalException) 'User Account Pictures Black must not use YazanFinalException for exact parity.'
$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $parityOrder
Assert-BoostLabCondition ($null -ne $nextTarget) 'Ordered parity helper must resolve a first non-final target.'
Assert-BoostLabCondition ([string]$nextTarget.ToolId -eq [string]$parityBaseline.CurrentOrderedParityTarget) 'Current ordered parity target must match the first non-final ordered target.'
$categoryCounts = Get-BoostLabParityCategoryCounts -ParityBaseline $parityBaseline
Assert-BoostLabCondition ([int]$categoryCounts['ParityImplemented'] -eq [int]$parityBaseline.Counts.UltimateParityImplemented) 'ParityImplemented count mismatch.'
Assert-BoostLabCondition ([int]$categoryCounts['NearParityControlled'] -eq [int]$parityBaseline.Counts.NearParityControlled) 'NearParityControlled count mismatch.'

$moduleFiles = @(
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'modules') -Recurse -File -Filter '*.psm1' |
        Where-Object { $_.Directory.Parent.FullName -eq (Join-Path $ProjectRoot 'modules') }
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
Assert-BoostLabCondition ($tools.Count -eq $inventoryBaseline.ActiveTools) 'Active tool count changed unexpectedly.'
Assert-BoostLabCondition ($implementedCount -eq $inventoryBaseline.ImplementedTools) 'Implemented module count changed unexpectedly.'
Assert-BoostLabCondition ($placeholderCount -eq $inventoryBaseline.DeferredPlaceholders) 'Placeholder module count changed unexpectedly.'

Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $sourceRoot '6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
Assert-BoostLabCondition (@(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.Name -like '*NVME Faster Driver*' -or $_.Name -like '*NVMe Faster Driver*' }).Count -eq 0) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    Success = $true
    SourceSHA256 = $sourceHash
    Actions = @('Apply', 'Default')
    MockedApplyPassed = $true
    MockedDefaultPassed = $true
    CurrentOrderedParityTarget = $parityBaseline.CurrentOrderedParityTarget
    FirstNonFinalParityTarget = $nextTarget.ToolId
    ActiveToolCount = $tools.Count
    ImplementedModuleCount = $implementedCount
    PlaceholderModuleCount = $placeholderCount
    Message = 'User Account Pictures Black exact Ultimate parity validation passed with mocked file/image operations.'
}
