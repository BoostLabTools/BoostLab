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
    elseif (-not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
        $MyInvocation.MyCommand.Path
    }
    else {
        throw 'Unable to determine the Unattended test script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulePath = Join-Path $ProjectRoot 'modules\Refresh\unattended.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\2 Refresh\2 Unattended.ps1'
$recordPath = Join-Path $ProjectRoot 'docs\migrations\unattended.md'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$sourceHash = '8A010A0B88860C88C4109A37BE21B03BA5C5686333D5B4A1C30F40C2FEE1D3DD'

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$tools = @($configuration['Stages'] | ForEach-Object { $_['Tools'] })
$tool = $tools | Where-Object { $_['Id'] -eq 'unattended' } | Select-Object -First 1
if ($null -eq $tool) {
    throw 'Unattended metadata is missing.'
}
if (
    [string]$tool['Stage'] -ne 'Refresh' -or
    [int]$tool['Order'] -ne 2 -or
    [string]$tool['Type'] -ne 'action' -or
    [string]$tool['RiskLevel'] -ne 'high' -or
    (@($tool['Actions']) -join ',') -ne 'Analyze,Apply'
) {
    throw 'Unattended metadata is incorrect.'
}

$capabilities = $tool['Capabilities']
foreach ($field in @(
    'RequiresAdmin'
    'CanModifyRegistry'
    'CanInstallSoftware'
    'CanModifySecurity'
    'CanDeleteFiles'
    'NeedsExplicitConfirmation'
)) {
    if (-not [bool]$capabilities[$field]) {
        throw "Unattended capability '$field' must be true."
    }
}
foreach ($field in @(
    'RequiresInternet'
    'CanReboot'
    'CanModifyServices'
    'CanDownload'
    'CanModifyDrivers'
    'UsesTrustedInstaller'
    'UsesSafeMode'
    'SupportsDefault'
    'SupportsRestore'
)) {
    if ([bool]$capabilities[$field]) {
        throw "Unattended capability '$field' must be false."
    }
}

if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -ne $sourceHash) {
    throw 'Unattended Ultimate source hash changed.'
}

$source = Get-Content -Raw -LiteralPath $sourcePath
$moduleSource = Get-Content -Raw -LiteralPath $modulePath
foreach ($requiredText in @(
    '<Name>@</Name>'
    'net accounts /maxpwage:unlimited'
    'net user @ /active:Yes'
    'net user @ /passwordreq:no'
    'BypassTPMCheck'
    'BypassRAMCheck'
    'BypassSecureBootCheck'
    'BypassCPUCheck'
    'BypassStorageCheck'
    'Set-Content -Path "$env:SystemRoot\Temp\autounattendtemplate.xml"'
    'Move-Item -Path $file -Destination $destination -Force'
)) {
    if (-not $source.Contains($requiredText)) {
        throw "Unattended source no longer contains: $requiredText"
    }
}

foreach ($requiredText in @(
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'')'
    '$script:BoostLabUnattendedSourceHash'
    'function Show-BoostLabUnattendedSelectionDialog'
    'function Copy-BoostLabUnattendedBackup'
    'function Save-BoostLabUnattendedState'
    'function New-BoostLabUnattendedVerificationResult'
    'function Get-BoostLabUnattendedHostScope'
    'SupportedForWindows11Preparation'
    'DriveType = 2'
    'Move-Item -LiteralPath $SourcePath -Destination $DestinationPath -Force'
    'Windows 10 optimization branches remain unsupported'
    '[bool]$Confirmed = $false'
)) {
    if (-not $moduleSource.Contains($requiredText)) {
        throw "Unattended module is missing: $requiredText"
    }
}
foreach ($forbiddenText in @(
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'Restart-Computer'
    'Stop-Computer'
    'diskpart'
    'format.com'
    'setup.exe'
    'mediacreationtool'
    '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'', ''Default'')'
)) {
    if ($moduleSource.Contains($forbiddenText)) {
        throw "Unattended module contains unapproved behavior: $forbiddenText"
    }
}

$module = Import-Module -Name $modulePath -Force -PassThru -Prefix 'UnattendedTest' -Scope Local -DisableNameChecking -ErrorAction Stop
try {
    $infoCommand = Get-Command -Name 'Get-UnattendedTestBoostLabToolInfo' -Module $module.Name -ErrorAction Stop
    $compatibilityCommand = Get-Command -Name 'Test-UnattendedTestBoostLabToolCompatibility' -Module $module.Name -ErrorAction Stop

    $info = & $infoCommand
    if (
        (@($info.Actions) -join ',') -ne 'Analyze,Apply' -or
        (@($info.ImplementedActions) -join ',') -ne 'Analyze,Apply'
    ) {
        throw 'Unattended exported action metadata is incorrect.'
    }

    $windows11Compatibility = & $compatibilityCommand -WindowsInfoReader {
        [pscustomobject]@{ Caption = 'Microsoft Windows 11 Pro'; Build = 26100 }
    }
    $windows10Compatibility = & $compatibilityCommand -WindowsInfoReader {
        [pscustomobject]@{ Caption = 'Microsoft Windows 10 Pro'; Build = 19045 }
    }
    $serverCompatibility = & $compatibilityCommand -WindowsInfoReader {
        [pscustomobject]@{ Caption = 'Microsoft Windows Server 2022'; Build = 20348 }
    }
    if (
        -not $windows11Compatibility.Supported -or
        -not $windows10Compatibility.Supported -or
        $windows10Compatibility.PayloadTarget -ne 'Windows 11' -or
        $windows10Compatibility.Reason -notmatch 'may host this Windows 11 preparation workflow' -or
        $serverCompatibility.Supported
    ) {
        throw 'Unattended Windows 10/11 host compatibility behavior is incorrect.'
    }

    $analysis = & $module {
        Get-BoostLabUnattendedAnalyzeData `
            -WindowsInfoReader { [pscustomobject]@{ Caption = 'Windows 10 Pro'; Build = 19045 } } `
            -DriveReader { @([pscustomobject]@{ Root = 'E:\'; Label = 'INSTALL'; FreeSpace = 100GB }) }
    }
    if (
        -not $analysis.HostSupportedForWindows11Preparation -or
        -not $analysis.HostIsWindows10 -or
        $analysis.CurrentHostOS -ne 'Windows 10' -or
        $analysis.PayloadTarget -ne 'Windows 11' -or
        $analysis.Windows10OptimizationBranches -notmatch 'Unsupported' -or
        $analysis.RemovableMediaCount -ne 1 -or
        $analysis.ChangesExecuted -or
        @($analysis.HardwareRequirementBypasses).Count -ne 5
    ) {
        throw 'Unattended Analyze did not support a Windows 10 host for read-only Windows 11 preparation.'
    }

    $cancelled = & $module {
        Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$false
    }
    if (-not $cancelled.Cancelled -or $cancelled.Message -ne 'Cancelled by user') {
        throw 'Unattended confirmation cancellation is incorrect.'
    }

    $windows10Events = [System.Collections.Generic.List[string]]::new()
    $windows10Result = & $module {
        param($Events)
        Invoke-BoostLabUnattendedApplyAction `
            -AdministratorChecker { $true } `
            -WindowsInfoReader { [pscustomobject]@{ Caption = 'Windows 10'; Build = 19045 } } `
            -DriveReader { @() } `
            -SelectionProvider {
                param($Drives)
                $Events.Add('SELECT') | Out-Null
                [pscustomobject]@{ AccountName = 'Yazan'; DriveRoot = 'E:\' }
            } `
            -TextWriter { param($Path, $Content, $Encoding) $Events.Add('WRITE') | Out-Null }
    } $windows10Events
    if (
        $windows10Result.Status -ne 'Failed' -or
        $windows10Result.Message -notmatch 'not currently detected as removable media' -or
        'SELECT' -notin @($windows10Events) -or
        @($windows10Events | Where-Object { $_ -eq 'WRITE' }).Count -ne 0
    ) {
        throw 'Unattended did not allow Windows 10 preparation while retaining removable-media gating.'
    }

    $mock = [pscustomobject]@{
        Files = @{}
        Events = [System.Collections.Generic.List[string]]::new()
        States = [System.Collections.Generic.List[object]]::new()
    }
    $mock.Files['C:\Windows\Temp\autounattendtemplate.xml'] = 'OLD_TEMPLATE'
    $mock.Files['C:\Windows\Temp\autounattend.xml'] = 'OLD_TEMP'
    $mock.Files['E:\autounattend.xml'] = 'OLD_DESTINATION'

    $applyResult = & $module {
        param($Mock)

        $fileStateReader = {
            param($Path)
            $exists = $Mock.Files.ContainsKey($Path)
            [pscustomobject]@{
                Exists = $exists
                Path = $Path
                Sha256 = if ($exists) { 'HASH-' + $Path } else { $null }
                Length = if ($exists) { ([string]$Mock.Files[$Path]).Length } else { $null }
                ReadSucceeded = $true
                Message = if ($exists) { 'Detected' } else { 'Absent' }
            }
        }
        $backupWriter = {
            param($SourcePath, $BackupPath)
            $Mock.Events.Add("BACKUP:$SourcePath") | Out-Null
            $Mock.Files[$BackupPath] = $Mock.Files[$SourcePath]
            [pscustomobject]@{
                Success = $true
                BackupPath = $BackupPath
                Sha256 = 'HASH-' + $SourcePath
                Message = 'Mock backup created.'
            }
        }
        $stateWriter = {
            param($State, $ManifestPath)
            $Mock.Events.Add("STATE:$($State.Status)") | Out-Null
            $Mock.States.Add($State) | Out-Null
        }
        $textWriter = {
            param($Path, $Content, $Encoding)
            $Mock.Events.Add("WRITE:$Path") | Out-Null
            $Mock.Files[$Path] = [string]$Content
        }
        $textReader = {
            param($Path)
            return [string]$Mock.Files[$Path]
        }
        $fileRemover = {
            param($Path)
            $Mock.Events.Add("REMOVE:$Path") | Out-Null
            $Mock.Files.Remove($Path) | Out-Null
        }
        $fileMover = {
            param($SourcePath, $DestinationPath)
            $Mock.Events.Add("MOVE:$SourcePath->$DestinationPath") | Out-Null
            $Mock.Files[$DestinationPath] = $Mock.Files[$SourcePath]
            $Mock.Files.Remove($SourcePath) | Out-Null
        }
        $directoryOpener = {
            param($Path)
            $Mock.Events.Add("OPEN:$Path") | Out-Null
        }

        Invoke-BoostLabUnattendedApplyAction `
            -AdministratorChecker { $true } `
            -WindowsInfoReader { [pscustomobject]@{ Caption = 'Windows 10 Pro'; Build = 19045 } } `
            -DriveReader { @([pscustomobject]@{ Root = 'E:\'; Label = 'INSTALL'; FreeSpace = 100GB }) } `
            -SelectionProvider { param($Drives) [pscustomobject]@{ AccountName = 'Yazan'; DriveRoot = 'E:\' } } `
            -FileStateReader $fileStateReader `
            -BackupWriter $backupWriter `
            -StateWriter $stateWriter `
            -TextWriter $textWriter `
            -TextReader $textReader `
            -FileRemover $fileRemover `
            -FileMover $fileMover `
            -DirectoryOpener $directoryOpener `
            -SystemRoot 'C:\Windows' `
            -ProgramData 'C:\ProgramData'
    } $mock

    if (
        -not $applyResult.Success -or
        $applyResult.VerificationResult.Status -ne 'Passed' -or
        @($applyResult.VerificationResult.Checks | Where-Object Status -eq 'Failed').Count -ne 0 -or
        @($applyResult.VerificationResult.Checks | Where-Object Name -eq 'Temporary template cleanup').Count -ne 1 -or
        @($applyResult.VerificationResult.Checks | Where-Object Name -eq 'Temporary unattended move').Count -ne 1 -or
        @($applyResult.VerificationResult.Checks | Where-Object Name -eq 'Pre-existing file backups').Count -ne 1 -or
        $applyResult.Data.DestinationPath -ne 'E:\autounattend.xml' -or
        $applyResult.Data.CurrentHostOS -ne 'Windows 10' -or
        $applyResult.Data.PayloadTarget -ne 'Windows 11' -or
        $applyResult.Data.Windows10OptimizationBranches -notmatch 'Unsupported' -or
        $applyResult.Data.BackupCount -ne 3 -or
        @($applyResult.Data.Backups).Count -ne 3 -or
        -not $applyResult.Data.ChangesExecuted
    ) {
        throw "Mocked Unattended Apply failed: $($applyResult.Message)"
    }

    $firstWrite = @($mock.Events | Where-Object { $_ -like 'WRITE:*' } | Select-Object -First 1)
    $firstWriteIndex = $mock.Events.IndexOf($firstWrite[0])
    $backupIndexes = @(
        for ($index = 0; $index -lt $mock.Events.Count; $index++) {
            if ($mock.Events[$index] -like 'BACKUP:*') { $index }
        }
    )
    $pendingStateIndex = $mock.Events.IndexOf('STATE:PendingApply')
    if (
        $backupIndexes.Count -ne 3 -or
        ($backupIndexes | Measure-Object -Maximum).Maximum -gt $firstWriteIndex -or
        $pendingStateIndex -gt $firstWriteIndex
    ) {
        throw 'Unattended did not finish backups and pending state capture before the first write.'
    }

    $generated = [string]$mock.Files['E:\autounattend.xml']
    foreach ($requiredGeneratedText in @(
        '<Name>Yazan</Name>'
        'net user Yazan /active:Yes'
        'net user Yazan /passwordreq:no'
        'BypassTPMCheck'
        'BypassRAMCheck'
        'BypassSecureBootCheck'
        'BypassCPUCheck'
        'BypassStorageCheck'
    )) {
        if (-not $generated.Contains($requiredGeneratedText)) {
            throw "Generated Unattended payload is missing: $requiredGeneratedText"
        }
    }
    if (
        $mock.Files.ContainsKey('C:\Windows\Temp\autounattendtemplate.xml') -or
        $mock.Files.ContainsKey('C:\Windows\Temp\autounattend.xml') -or
        'OPEN:E:\' -notin @($mock.Events)
    ) {
        throw 'Unattended source temp-file cleanup, move, or destination-open behavior is incorrect.'
    }

    $template = & $module { $script:BoostLabUnattendedTemplate }
    $sha256Template = [Security.Cryptography.SHA256]::Create()
    try {
        $templateHash = [BitConverter]::ToString(
            $sha256Template.ComputeHash([Text.Encoding]::UTF8.GetBytes($template))
        ).Replace('-', '')
    }
    finally {
        $sha256Template.Dispose()
    }
    if ($templateHash -ne '6293F4C6121B44A297B67BAF83BA165FB1330FF0749EEEE3601CEE941AA06F65') {
        throw 'The approved Windows 11 autounattend.xml payload changed.'
    }
}
finally {
    Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
}

$actionPlanModule = Import-Module -Name $actionPlanPath -Force -PassThru -Scope Local -ErrorAction Stop
try {
    $analyzePlan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName 'Analyze' -IsDryRun:$false
    $applyPlan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName 'Apply' -IsDryRun:$false
    if (
        -not $analyzePlan.NeedsExplicitConfirmation -or
        -not $applyPlan.NeedsExplicitConfirmation -or
        $applyPlan.CanReboot -or
        (@($applyPlan.PlannedChanges) -join ' ') -notmatch 'Windows 10 or Windows 11 host' -or
        $applyPlan.ConfirmationMessage -notmatch 'blank-password local administrator' -or
        $applyPlan.ConfirmationMessage -notmatch 'TPM, RAM, Secure Boot, CPU, and storage'
    ) {
        throw 'Unattended Action Plan behavior is incorrect.'
    }
}
finally {
    Remove-Module -ModuleInfo $actionPlanModule -Force -ErrorAction SilentlyContinue
}

$executionSource = Get-Content -Raw -LiteralPath $executionPath
foreach ($requiredText in @(
    '''unattended'' = @{'
    'Refresh\unattended.psm1'
    'Actions = @(''Analyze'', ''Apply'')'
)) {
    if (-not $executionSource.Contains($requiredText)) {
        throw "Unattended runtime mapping is missing: $requiredText"
    }
}

$record = Get-Content -Raw -LiteralPath $recordPath
foreach ($requiredText in @(
    'source-ultimate/2 Refresh/2 Unattended.ps1'
    $sourceHash
    'Windows 10 or Windows 11'
    'Windows 10 optimization'
    'former `Default` action is removed'
    'No Restore action is claimed'
    'Automated tests must be static or mocked only'
)) {
    if (-not $record.Contains($requiredText)) {
        throw "Unattended migration record is missing: $requiredText"
    }
}

$implementedCount = @(
    Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'modules') -Recurse -File -Filter '*.psm1' |
        Where-Object { $_.Directory.Parent.FullName -eq (Join-Path $ProjectRoot 'modules') } |
        Where-Object { (Get-Content -Raw -LiteralPath $_.FullName).Contains('$script:BoostLabImplementedActions') }
).Count
$placeholderCount = $inventoryBaseline.ActiveTools - $implementedCount
if ($implementedCount -ne $inventoryBaseline.ImplementedTools -or $placeholderCount -ne $inventoryBaseline.DeferredPlaceholders) {
    throw "Unexpected Phase 33 inventory: $implementedCount implemented, $placeholderCount placeholders."
}

$remainingRefusedPlaceholders = @()
foreach ($relativePath in $remainingRefusedPlaceholders) {
    $placeholderSource = Get-Content -Raw -LiteralPath (Join-Path (Join-Path $ProjectRoot 'modules') $relativePath)
    if (
        -not $placeholderSource.Contains('ToolModule.Placeholder.ps1') -or
        $placeholderSource.Contains('$script:BoostLabImplementedActions')
    ) {
        throw "Refused tool changed from placeholder status: $relativePath"
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
$sha256 = [Security.Cryptography.SHA256]::Create()
try {
    $manifestHash = [BitConverter]::ToString(
        $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sourceLines -join "`n")))
    ).Replace('-', '')
}
finally {
    $sha256.Dispose()
}
if (@($sourceLines).Count -ne 49 -or $manifestHash -ne 'B07E015D5BA32E9CF4DBC1804597311D8A41CE7FA537C0091914056BEF06FFF4') {
    throw 'source-ultimate content or paths changed.'
}

$normalizedCatalog = @($tools | ForEach-Object { ([string]$_['Title'] -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant() })
foreach ($deletedName in @('Loudness EQ', 'NVME Faster Driver')) {
    if ((($deletedName -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()) -in $normalizedCatalog) {
        throw "Deleted tool returned to the catalog: $deletedName"
    }
}

[pscustomobject]@{
    Success = $true
    ToolId = 'unattended'
    ImplementedActions = @('Analyze', 'Apply')
    MockedApplyPassed = $true
    BackupOrderingPassed = $true
    ImplementedModuleCount = $implementedCount
    PlaceholderModuleCount = $placeholderCount
    SourceUltimateUnchanged = $true
    Message = 'Unattended Windows 11 artifact generation passed static and mocked validation.'
    Timestamp = Get-Date
}



