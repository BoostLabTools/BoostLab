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
        throw 'Unable to determine the Write Cache Buffer Flushing test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

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
$modulePath = Join-Path $ProjectRoot 'modules\Windows\write-cache-buffer-flushing.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$uiPath = Join-Path $ProjectRoot 'ui\MainWindow.ps1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\20 Write Cache Buffer Flushing.ps1'
$migrationPath = Join-Path $ProjectRoot 'docs\migrations\write-cache-buffer-flushing.md'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('BoostLab-WriteCache-Test-{0}' -f ([guid]::NewGuid()))

try {
    New-Item -Path $tempRoot -ItemType Directory -Force | Out-Null

    Assert-BoostLabCondition (Test-Path -LiteralPath $modulePath -PathType Leaf) 'Write Cache Buffer Flushing module is missing.'
    Assert-BoostLabCondition (Test-Path -LiteralPath $migrationPath -PathType Leaf) 'Write Cache Buffer Flushing migration record is missing.'
    Assert-BoostLabCondition ((Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash -eq '67D8CA0FECBFD9FCE7D2C81CE1713F1B08E83B729DC8FEC7B8C2E33806F9AD5D') 'Write Cache Buffer Flushing source hash changed.'

    $config = Import-PowerShellDataFile -LiteralPath $configPath
    $tool = @($config['Stages'] | ForEach-Object { $_['Tools'] }) |
        Where-Object { [string]$_['Id'] -eq 'write-cache-buffer-flushing' } |
        Select-Object -First 1
    Assert-BoostLabCondition ($null -ne $tool) 'Write Cache Buffer Flushing catalog entry is missing.'
    Assert-BoostLabCondition ((@($tool['Actions']) -join ',') -eq 'Analyze,Apply') 'Write Cache Buffer Flushing must expose only Analyze and Apply.'
    Assert-BoostLabCondition ([string]$tool['Type'] -eq 'action') 'Write Cache Buffer Flushing must be an action tool.'
    Assert-BoostLabCondition ([string]$tool['RiskLevel'] -eq 'high') 'Write Cache Buffer Flushing must remain high risk.'
    Assert-BoostLabCondition ([bool]$tool['Capabilities']['RequiresAdmin']) 'Write Cache Buffer Flushing must require Administrator.'
    Assert-BoostLabCondition ([bool]$tool['Capabilities']['CanModifyRegistry']) 'Write Cache Buffer Flushing must declare registry modification capability.'
    Assert-BoostLabCondition (-not [bool]$tool['Capabilities']['CanModifyDrivers']) 'Write Cache Buffer Flushing must not declare driver modification capability.'
    Assert-BoostLabCondition (-not [bool]$tool['Capabilities']['CanReboot']) 'Write Cache Buffer Flushing must not declare reboot capability.'
    Assert-BoostLabCondition (-not [bool]$tool['Capabilities']['SupportsDefault']) 'Write Cache Buffer Flushing must not claim Default support.'
    Assert-BoostLabCondition (-not [bool]$tool['Capabilities']['SupportsRestore']) 'Write Cache Buffer Flushing must not claim Restore support.'
    Assert-BoostLabCondition ([bool]$tool['Capabilities']['NeedsExplicitConfirmation']) 'Write Cache Buffer Flushing Apply must require explicit confirmation.'

    $moduleSource = Get-Content -LiteralPath $modulePath -Raw
    foreach ($requiredText in @(
        '$script:BoostLabImplementedActions = @(''Analyze'', ''Apply'')'
        'New-BoostLabRegistryStateCapture'
        'Set-BoostLabRollbackMutationState'
        'CacheIsPowerProtected'
        'HKLM:\SYSTEM\ControlSet001\Enum'
        'Test-BoostLabWriteCacheProductScope'
        'shared Windows storage registry behavior'
        'SupportsDefault           = $false'
        'SupportsRestore           = $false'
    )) {
        Assert-BoostLabCondition ($moduleSource.Contains($requiredText)) "Write Cache module is missing required text: $requiredText"
    }
    foreach ($forbiddenText in @(
        'reg delete'
        'Remove-ItemProperty'
        'Remove-Item -LiteralPath'
        'Disable-PnpDevice'
        'Uninstall-PnpDevice'
        'pnputil'
        'devcon'
        'Restart-Computer'
        'Stop-Computer'
        'Invoke-WebRequest'
        'Invoke-RestMethod'
        'Start-BitsTransfer'
        'Set-Service'
        'Stop-Service'
        'UsesTrustedInstaller      = $true'
        'UsesSafeMode              = $true'
    )) {
        Assert-BoostLabCondition (-not $moduleSource.Contains($forbiddenText)) "Write Cache module contains forbidden behavior: $forbiddenText"
    }

    $executionSource = Get-Content -LiteralPath $executionPath -Raw
    Assert-BoostLabCondition ($executionSource.Contains("'write-cache-buffer-flushing'")) 'Execution runtime does not register Write Cache Buffer Flushing.'
    Assert-BoostLabCondition ($executionSource.Contains("Actions = @('Analyze', 'Apply')")) 'Execution runtime does not restrict Write Cache actions to Analyze and Apply.'

    $actionPlanSource = Get-Content -LiteralPath $actionPlanPath -Raw
    foreach ($requiredPlanText in @(
        'write-cache-buffer-flushing'
        'Capture the prior CacheIsPowerProtected existence, type, and data'
        'Do not run the Ultimate Default broad Disk-key deletion.'
    )) {
        Assert-BoostLabCondition ($actionPlanSource.Contains($requiredPlanText)) "Action Plan is missing Write Cache text: $requiredPlanText"
    }

    $uiSource = Get-Content -LiteralPath $uiPath -Raw
    Assert-BoostLabCondition ($uiSource.Contains("'Not applicable' { 'Info' }")) 'UI activity severity handling must map NotApplicable results to INFO.'
    Assert-BoostLabCondition ($executionSource.Contains('ToolAction.NotApplicable')) 'Execution runtime must log NotApplicable results as a neutral event.'

    Import-Module -Name $actionPlanPath -Force -ErrorAction Stop
    $hostBuild = 0
    $hostProductName = 'Windows'
    try {
        $currentVersion = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
        [void][int]::TryParse([string]$currentVersion.CurrentBuildNumber, [ref]$hostBuild)
        $hostProductName = [string]$currentVersion.ProductName
    }
    catch {
        $hostBuild = [Environment]::OSVersion.Version.Build
    }
    if ($hostBuild -ge 10240 -and $hostBuild -lt 22000 -and $hostProductName -match 'Windows 10') {
        $windows10Plan = New-BoostLabActionPlan -ToolMetadata $tool -ActionName 'Apply' -IsDryRun:$false
        Assert-BoostLabCondition ([bool]$windows10Plan.RequiresAdmin) 'Windows 10 Write Cache shared behavior should preserve Administrator requirement.'
        Assert-BoostLabCondition ([bool]$windows10Plan.NeedsExplicitConfirmation) 'Windows 10 Write Cache shared behavior should preserve confirmation requirement.'
        Assert-BoostLabCondition (($windows10Plan.PlannedChanges -join "`n") -match 'Capture the prior CacheIsPowerProtected') 'Windows 10 Write Cache plan should describe registry capture for shared behavior.'
    }

    $migrationText = Get-Content -LiteralPath $migrationPath -Raw
    foreach ($requiredMigrationText in @(
        'Source SHA-256: `67D8CA0FECBFD9FCE7D2C81CE1713F1B08E83B729DC8FEC7B8C2E33806F9AD5D`'
        'Default is not implemented'
        'Restore is not exposed'
        'no explicit Windows 10-only branch'
        'CacheIsPowerProtected'
        'REG_DWORD 1'
    )) {
        Assert-BoostLabCondition ($migrationText.Contains($requiredMigrationText)) "Migration record is missing: $requiredMigrationText"
    }

    $sourceText = Get-Content -LiteralPath $sourcePath -Raw
    Assert-BoostLabCondition (-not ($sourceText -match 'Windows\s*10|Windows\s*11')) 'Write Cache source should not contain Windows-version branches.'

    $moduleInfo = Import-Module -Name $modulePath -Force -PassThru

    $windows10Events = [System.Collections.Generic.List[string]]::new()
    $windows10Target = [pscustomobject]@{
        ClassName    = 'SCSI'
        RegistryPath = 'HKLM:\SYSTEM\ControlSet001\Enum\SCSI\Win10Disk\Device Parameters\Disk'
    }
    $windows10Analyze = & $moduleInfo {
        param($Events, $Target)

        Invoke-BoostLabWriteCacheAnalyze `
            -WindowsInfoReader { [pscustomobject]@{ OperatingSystem = 'Windows_NT'; Caption = 'Microsoft Windows 10 Pro'; BuildNumber = '19045' } } `
            -TargetEnumerator {
                $Events.Add('DISCOVERY')
                [pscustomobject]@{ Succeeded = $true; Targets = @($Target); Warnings = @(); Message = 'Windows 10 shared target.' }
            } `
            -RegistryReader {
                param($Path, $ItemType, $ValueName)
                $Events.Add("READ:$Path")
                [pscustomobject]@{
                    ReadSucceeded = $true
                    KeyExists     = $true
                    Exists        = $false
                    Metadata      = $null
                    DisplayValue  = 'Absent'
                    Message       = 'Mock Windows 10 shared state read.'
                }
            }
    } $windows10Events $windows10Target

    Assert-BoostLabCondition ([bool]$windows10Analyze.Success) 'Windows 10 Analyze should support shared Windows behavior.'
    Assert-BoostLabCondition ([string]$windows10Analyze.Status -eq 'Analyzed') "Windows 10 Analyze should be Analyzed, got $($windows10Analyze.Status)."
    Assert-BoostLabCondition ([int]$windows10Analyze.Data.TargetCount -eq 1) 'Windows 10 Analyze should enumerate mocked shared storage targets.'
    Assert-BoostLabCondition (-not [bool]$windows10Analyze.Data.ChangesExecuted) 'Windows 10 Analyze must not execute changes.'
    Assert-BoostLabCondition (@($windows10Analyze.Errors).Count -eq 0) 'Windows 10 Analyze top-level Errors should be empty.'
    Assert-BoostLabCondition (($windows10Events -join '|') -match 'DISCOVERY' -and ($windows10Events -join '|') -match 'READ:') 'Windows 10 Analyze did not use the shared discovery/read path.'

    $windows10ApplyEvents = [System.Collections.Generic.List[string]]::new()
    $windows10RegistryStore = @{
        $windows10Target.RegistryPath = [pscustomobject]@{ Exists = $false; ValueType = ''; ValueData = $null }
    }
    $windows10Apply = & $moduleInfo {
        param($Events, $Target, $RegistryStore, $StateRoot)

        Invoke-BoostLabWriteCacheApply `
            -WindowsInfoReader { [pscustomobject]@{ OperatingSystem = 'Windows_NT'; Caption = 'Microsoft Windows 10 Pro'; BuildNumber = '19045' } } `
            -AdministratorChecker { $Events.Add('ADMIN'); $true } `
            -TargetEnumerator {
                $Events.Add('DISCOVERY')
                [pscustomobject]@{ Succeeded = $true; Targets = @($Target); Warnings = @(); Message = 'Windows 10 shared target.' }
            } `
            -RegistryReader {
                param($Path, $ItemType, $ValueName)
                $Events.Add("READ:$Path")
                $entry = $RegistryStore[$Path]
                [pscustomobject]@{
                    ReadSucceeded = $true
                    KeyExists     = $true
                    Exists        = [bool]$entry.Exists
                    Metadata      = if ([bool]$entry.Exists) {
                        [ordered]@{ ValueName = $ValueName; ValueType = [string]$entry.ValueType; ValueData = $entry.ValueData }
                    }
                    else {
                        $null
                    }
                    DisplayValue  = if ([bool]$entry.Exists) { "$($entry.ValueType):$($entry.ValueData)" } else { 'Absent' }
                    Message       = 'Mock Windows 10 shared state read.'
                }
            } `
            -RegistryWriter {
                param($Target, $Value)
                $path = [string]$Target.RegistryPath
                $Events.Add("WRITE:$path")
                $RegistryStore[$path] = [pscustomobject]@{ Exists = $true; ValueType = 'DWord'; ValueData = [int]$Value }
            } `
            -StateRoot $StateRoot
    } $windows10ApplyEvents $windows10Target $windows10RegistryStore $tempRoot

    Assert-BoostLabCondition ([bool]$windows10Apply.Success) 'Windows 10 Apply should support shared Windows behavior with mocked registry operations.'
    Assert-BoostLabCondition ([string]$windows10Apply.Status -eq 'Completed') "Windows 10 Apply should be Completed, got $($windows10Apply.Status)."
    Assert-BoostLabCondition ([bool]$windows10Apply.Data.ChangesExecuted) 'Windows 10 Apply should execute the mocked shared write path.'
    Assert-BoostLabCondition (@($windows10Apply.Data.CaptureRecords).Count -eq 1) 'Windows 10 Apply should capture the mocked prior value state before mutation.'
    Assert-BoostLabCondition ([int]$windows10RegistryStore[$windows10Target.RegistryPath].ValueData -eq 1) 'Windows 10 Apply did not set the mocked CacheIsPowerProtected value to 1.'
    Assert-BoostLabCondition (@($windows10Apply.Errors).Count -eq 0) 'Windows 10 Apply top-level Errors should be empty.'
    Assert-BoostLabCondition (@($windows10Apply.Data.Errors).Count -eq 0) 'Windows 10 Apply should not report errors.'
    Assert-BoostLabCondition (($windows10ApplyEvents -join '|') -match 'ADMIN' -and ($windows10ApplyEvents -join '|') -match 'DISCOVERY' -and ($windows10ApplyEvents -join '|') -match 'WRITE:') 'Windows 10 Apply did not use the shared admin/discovery/write path.'

    $targets = @(
        [pscustomobject]@{
            ClassName    = 'SCSI'
            RegistryPath = 'HKLM:\SYSTEM\ControlSet001\Enum\SCSI\DiskA\Device Parameters\Disk'
        }
        [pscustomobject]@{
            ClassName    = 'NVME'
            RegistryPath = 'HKLM:\SYSTEM\ControlSet001\Enum\NVME\DiskB\Device Parameters\Disk'
        }
    )
    $registryStore = @{
        $targets[0].RegistryPath = [pscustomobject]@{ Exists = $false; ValueType = ''; ValueData = $null }
        $targets[1].RegistryPath = [pscustomobject]@{ Exists = $true; ValueType = 'DWord'; ValueData = 0 }
    }
    $events = [System.Collections.Generic.List[string]]::new()

    $applyResult = & $moduleInfo {
        param($Targets, $RegistryStore, $Events, $StateRoot)

        $targetEnumerator = {
            [pscustomobject]@{
                Succeeded = $true
                Targets   = @($Targets)
                Warnings  = @()
                Message   = 'Mocked storage targets.'
            }
        }.GetNewClosure()
        $registryReader = {
            param($Path, $ItemType, $ValueName)

            $Events.Add("READ:$Path")
            if (-not $RegistryStore.ContainsKey($Path)) {
                return [pscustomobject]@{
                    ReadSucceeded = $true
                    KeyExists     = $false
                    Exists        = $false
                    Metadata      = $null
                    DisplayValue  = 'Absent'
                    Message       = 'Mock key absent.'
                }
            }

            $entry = $RegistryStore[$Path]
            return [pscustomobject]@{
                ReadSucceeded = $true
                KeyExists     = $true
                Exists        = [bool]$entry.Exists
                Metadata      = if ([bool]$entry.Exists) {
                    [ordered]@{
                        ValueName = $ValueName
                        ValueType = [string]$entry.ValueType
                        ValueData = $entry.ValueData
                    }
                }
                else {
                    $null
                }
                DisplayValue  = if ([bool]$entry.Exists) { "$($entry.ValueType):$($entry.ValueData)" } else { 'Absent' }
                Message       = 'Mock state read.'
            }
        }.GetNewClosure()
        $registryWriter = {
            param($Target, $Value)

            $path = [string]$Target.RegistryPath
            $Events.Add("WRITE:$path")
            $RegistryStore[$path] = [pscustomobject]@{
                Exists    = $true
                ValueType = 'DWord'
                ValueData = [int]$Value
            }
        }.GetNewClosure()

        Invoke-BoostLabWriteCacheApply `
            -WindowsInfoReader { [pscustomobject]@{ OperatingSystem = 'Windows_NT'; Caption = 'Microsoft Windows 11 Pro'; BuildNumber = '22631' } } `
            -AdministratorChecker { $true } `
            -TargetEnumerator $targetEnumerator `
            -RegistryReader $registryReader `
            -RegistryWriter $registryWriter `
            -StateRoot $StateRoot
    } $targets $registryStore $events $tempRoot

    Assert-BoostLabCondition ([bool]$applyResult.Success) "Mock Apply should succeed: $($applyResult.Message)"
    Assert-BoostLabCondition ([string]$applyResult.Status -eq 'Completed') "Mock Apply status should be Completed, got $($applyResult.Status)."
    Assert-BoostLabCondition ([int]$registryStore[$targets[0].RegistryPath].ValueData -eq 1) 'Mock SCSI target was not set to DWORD 1.'
    Assert-BoostLabCondition ([int]$registryStore[$targets[1].RegistryPath].ValueData -eq 1) 'Mock NVME target was not set to DWORD 1.'
    Assert-BoostLabCondition (@($applyResult.Data.CaptureRecords).Count -eq 2) 'Mock Apply did not record one capture record per target.'
    Assert-BoostLabCondition ([string]$applyResult.VerificationResult.Status -eq 'Passed') "Mock Apply verification should pass, got $($applyResult.VerificationResult.Status)."
    $firstWriteIndex = -1
    for ($i = 0; $i -lt $events.Count; $i++) {
        if ($events[$i].StartsWith('WRITE:', [StringComparison]::Ordinal)) {
            $firstWriteIndex = $i
            break
        }
    }
    Assert-BoostLabCondition ($firstWriteIndex -ge 2) 'Mock Apply wrote before reading/capturing both targets.'

    $failedWriteEvents = [System.Collections.Generic.List[string]]::new()
    $captureFailure = & $moduleInfo {
        param($Targets, $Events, $StateRoot)

        $targetEnumerator = {
            [pscustomobject]@{ Succeeded = $true; Targets = @($Targets); Warnings = @(); Message = 'Mocked targets.' }
        }.GetNewClosure()
        $invalidReader = {
            param($Path, $ItemType, $ValueName)
            $Events.Add("READ:$Path")
            return $null
        }.GetNewClosure()
        $writer = {
            param($Target, $Value)
            $Events.Add("WRITE:$([string]$Target.RegistryPath)")
        }.GetNewClosure()

        Invoke-BoostLabWriteCacheApply `
            -WindowsInfoReader { [pscustomobject]@{ OperatingSystem = 'Windows_NT'; Caption = 'Microsoft Windows 11 Pro'; BuildNumber = '22631' } } `
            -AdministratorChecker { $true } `
            -TargetEnumerator $targetEnumerator `
            -RegistryReader $invalidReader `
            -RegistryWriter $writer `
            -StateRoot $StateRoot
    } @($targets[0]) $failedWriteEvents $tempRoot

    Assert-BoostLabCondition (-not [bool]$captureFailure.Success) 'Capture failure should block Apply.'
    Assert-BoostLabCondition ([string]$captureFailure.Status -eq 'Error') 'Capture failure should return Error.'
    Assert-BoostLabCondition (-not [bool]$captureFailure.Data.ChangesExecuted) 'Capture failure must report no changes executed.'
    Assert-BoostLabCondition (-not (@($failedWriteEvents) -match '^WRITE:')) 'Capture failure still invoked the registry writer.'

    $noTargetResult = & $moduleInfo {
        param($StateRoot)

        $targetEnumerator = {
            [pscustomobject]@{ Succeeded = $true; Targets = @(); Warnings = @(); Message = 'No mock targets.' }
        }
        Invoke-BoostLabWriteCacheApply `
            -WindowsInfoReader { [pscustomobject]@{ OperatingSystem = 'Windows_NT'; Caption = 'Microsoft Windows 11 Pro'; BuildNumber = '22631' } } `
            -AdministratorChecker { $true } `
            -TargetEnumerator $targetEnumerator `
            -RegistryReader { param($Path, $ItemType, $ValueName) throw 'Reader should not be called.' } `
            -RegistryWriter { param($Target, $Value) throw 'Writer should not be called.' } `
            -StateRoot $StateRoot
    } $tempRoot

    Assert-BoostLabCondition ([bool]$noTargetResult.Success) 'No-target Apply should be a clean not-applicable result.'
    Assert-BoostLabCondition ([string]$noTargetResult.Status -eq 'NotApplicable') "No-target Apply should be NotApplicable, got $($noTargetResult.Status)."
    Assert-BoostLabCondition (-not [bool]$noTargetResult.Data.ChangesExecuted) 'No-target Apply must not execute changes.'

    $unsupportedDefault = Invoke-BoostLabToolAction -ActionName 'Default' -Confirmed:$true
    Assert-BoostLabCondition (-not [bool]$unsupportedDefault.Success) 'Default action should be unsupported.'
    Assert-BoostLabCondition ([string]$unsupportedDefault.Message -like '*Default is refused*') 'Default refusal message should explain broad Disk key deletion.'

    $restoreResult = Restore-BoostLabToolDefault -Confirmed:$true
    Assert-BoostLabCondition (-not [bool]$restoreResult.Success) 'Restore should not be exposed as implemented.'
    Assert-BoostLabCondition ([string]$restoreResult.Status -eq 'NotImplemented') 'Restore must return NotImplemented.'

    $allModules = @(
        Get-ChildItem -LiteralPath $modulesRoot -Recurse -File -Filter '*.psm1' |
            Where-Object { $_.Directory.Parent.FullName -eq $modulesRoot }
    )
    $implementedModules = @(
        $allModules | Where-Object {
            (Get-Content -LiteralPath $_.FullName -Raw).Contains('$script:BoostLabImplementedActions')
        }
    )
    $placeholderModules = @(
        $allModules | Where-Object {
            (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1')
        }
    )
    Assert-BoostLabCondition ($allModules.Count -eq 51) "Expected 51 active modules, found $($allModules.Count)."
    Assert-BoostLabCondition ($implementedModules.Count -eq 33) "Expected 33 implemented modules, found $($implementedModules.Count)."
    Assert-BoostLabCondition ($placeholderModules.Count -eq 18) "Expected 18 placeholder modules, found $($placeholderModules.Count)."

    Assert-BoostLabCondition (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'source-ultimate\6 Windows\17 Loudness EQ.ps1'))) 'Loudness EQ source was reintroduced.'
    Assert-BoostLabCondition (@(Get-ChildItem -LiteralPath $sourceRoot -Recurse -File -Filter '*NVME Faster Driver*.ps1').Count -eq 0) 'NVME Faster Driver source was reintroduced.'

    [pscustomobject]@{
        Success                 = $true
        SourceHash              = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
        ImplementedActionCount  = 2
        MockTargetCount         = 2
        CaptureRecordCount      = @($applyResult.Data.CaptureRecords).Count
        DefaultExposed          = $false
        RestoreExposed          = $false
        SourceUltimateUnchanged = $true
        ImplementedModuleCount  = $implementedModules.Count
        PlaceholderModuleCount  = $placeholderModules.Count
        Message                 = 'Write Cache Buffer Flushing preserves Apply with mocked capture-before-write and refuses unsafe Default.'
        Timestamp               = Get-Date
    }
}
finally {
    Remove-Module write-cache-buffer-flushing -Force -ErrorAction SilentlyContinue
    Remove-Module ActionPlan -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $tempRoot -PathType Container) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
