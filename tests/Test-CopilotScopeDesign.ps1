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
        throw 'Unable to determine the Copilot validator script path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
. (Join-Path $ProjectRoot 'tests\BoostLab.ParityStatusBaseline.ps1')

function Assert-CopilotCondition {
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
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$actionPlanPath = Join-Path $ProjectRoot 'core\ActionPlan.psm1'
$modulePath = Join-Path $ProjectRoot 'modules\Windows\copilot.psm1'
$sourcePath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\8 Copilot.ps1'
$artifactPolicyPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

foreach ($path in @($configPath, $executionPath, $actionPlanPath, $modulePath, $sourcePath, $artifactPolicyPath)) {
    Assert-CopilotCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required file is missing: $path"
}

$expectedSourceHash = '21B58212B241A6C0B74582063E3E74F746014E9137194B58B088CC6692F22A90'
$actualSourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash
Assert-CopilotCondition ($actualSourceHash -eq $expectedSourceHash) "Copilot source checksum changed. Expected $expectedSourceHash, found $actualSourceHash."

$sourceText = Get-Content -LiteralPath $sourcePath -Raw
foreach ($requiredSourceText in @(
    'Copilot: Off (Recommended)'
    'Copilot: Default'
    '"backgroundTaskHost", "Copilot", "CrossDeviceResume", "GameBar", "MicrosoftEdgeUpdate", "msedge", "msedgewebview2", "OneDrive", "OneDrive.Sync.Service", "OneDriveStandaloneUpdater", "Resume", "RuntimeBroker", "Search", "SearchHost", "Setup", "StoreDesktopExtension", "WidgetService", "Widgets"'
    'Where-Object { $_.ProcessName -like "*edge*" } | Stop-Process -Force -ErrorAction SilentlyContinue'
    'Get-AppXPackage -AllUsers | Where-Object'
    '$_.Name -like ''*Copilot*'''
    'Remove-AppxPackage -ErrorAction SilentlyContinue'
    'Add-AppxPackage -DisableDevelopmentMode -Register -ErrorAction SilentlyContinue "$($_.InstallLocation)\AppXManifest.xml"'
    'HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot'
    'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot'
    'TurnOffWindowsCopilot'
)) {
    Assert-CopilotCondition ($sourceText.Contains($requiredSourceText)) "Copilot source no longer contains: $requiredSourceText"
}
foreach ($forbiddenSourceText in @(
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'msiexec'
    'TrustedInstaller'
    'safeboot'
    'bcdedit'
    'Restart-Computer'
    'shutdown.exe'
)) {
    Assert-CopilotCondition (-not $sourceText.Contains($forbiddenSourceText)) "Copilot source unexpectedly contains: $forbiddenSourceText"
}

$config = Import-PowerShellDataFile -LiteralPath $configPath
$allTools = @($config.Stages | ForEach-Object { $_.Tools })
$copilotTool = $allTools | Where-Object { [string]$_['Id'] -eq 'copilot' } | Select-Object -First 1
Assert-CopilotCondition ($null -ne $copilotTool) 'Copilot stage metadata is missing.'
Assert-CopilotCondition ([string]$copilotTool['Stage'] -eq 'Windows') 'Copilot must remain in the Windows stage.'
Assert-CopilotCondition ([int]$copilotTool['Order'] -eq 8) 'Copilot must remain Windows order 8.'
Assert-CopilotCondition ([string]$copilotTool['RiskLevel'] -eq 'high') 'Copilot risk level must be high.'
Assert-CopilotCondition ((@($copilotTool['Actions']) -join ',') -eq 'Apply,Default') 'Copilot must expose only Apply and Default.'
$capabilities = $copilotTool['Capabilities']
$expectedTrueCapabilities = @(
    'RequiresAdmin'
    'CanModifyRegistry'
    'CanInstallSoftware'
    'CanModifySecurity'
    'SupportsDefault'
    'NeedsExplicitConfirmation'
)
foreach ($field in $capabilities.Keys) {
    $expected = $field -in $expectedTrueCapabilities
    Assert-CopilotCondition ([bool]$capabilities[$field] -eq $expected) "Copilot capability '$field' is incorrect."
}

$executionText = Get-Content -LiteralPath $executionPath -Raw
Assert-CopilotCondition ($executionText.Contains("'copilot' = @{")) 'Copilot is not registered in the implemented execution map.'
Assert-CopilotCondition ($executionText.Contains("Windows\copilot.psm1")) 'Copilot execution map path is missing.'
Assert-CopilotCondition ($executionText.Contains("Actions = @('Apply', 'Default')")) 'Copilot execution map actions are incorrect.'

$actionPlanText = Get-Content -LiteralPath $actionPlanPath -Raw
foreach ($requiredPlanText in @(
    'Run the approved source-equivalent Copilot Off branch'
    'stop the source process list'
    'stop *edge* process matches'
    'remove AppX packages matching *Copilot*'
    'set HKCU/HKLM TurnOffWindowsCopilot to REG_DWORD 1'
    're-register AppX packages matching *Copilot*'
    'delete the HKCU/HKLM WindowsCopilot policy keys'
    'Default is not Restore'
)) {
    Assert-CopilotCondition ($actionPlanText.Contains($requiredPlanText)) "Copilot action plan is missing: $requiredPlanText"
}

$tokens = $null
$parseErrors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile(
    $modulePath,
    [ref]$tokens,
    [ref]$parseErrors
)
if (@($parseErrors).Count -gt 0) {
    throw "Copilot module syntax error: $($parseErrors[0].Message)"
}
$moduleText = Get-Content -LiteralPath $modulePath -Raw
foreach ($requiredModuleText in @(
    '$script:BoostLabImplementedActions = @(''Apply'', ''Default'')'
    'Stop-Process -Name $Name -Force -ErrorAction SilentlyContinue'
    'Get-Process | Where-Object { $_.ProcessName -like $Pattern } | Stop-Process -Force -ErrorAction SilentlyContinue'
    'Invoke-BoostLabCopilotRemoveAppxPackages'
    'Remove-AppxPackage `'
    '-AllUsers `'
    'Add-AppxPackage -DisableDevelopmentMode -Register -ErrorAction SilentlyContinue "$($_.InstallLocation)\AppXManifest.xml"'
    'reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d "1" /f'
    'reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d "1" /f'
    'reg delete "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /f'
    'reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /f'
    '[bool]$Confirmed = $false'
)) {
    Assert-CopilotCondition ($moduleText.Contains($requiredModuleText)) "Copilot module is missing: $requiredModuleText"
}
foreach ($forbiddenModuleText in @(
    'ToolModule.Placeholder.ps1'
    'Invoke-WebRequest'
    'Invoke-RestMethod'
    'Start-BitsTransfer'
    'Start-Process'
    'Restart-Computer'
    'shutdown.exe'
    'bcdedit'
    'UsesTrustedInstaller = $true'
    'UsesSafeMode = $true'
)) {
    Assert-CopilotCondition (-not $moduleText.Contains($forbiddenModuleText)) "Copilot module contains forbidden behavior: $forbiddenModuleText"
}

$copilotModule = Import-Module `
    -Name $modulePath `
    -Force `
    -PassThru `
    -Prefix 'CopilotTest' `
    -Scope Local `
    -DisableNameChecking `
    -ErrorAction Stop
try {
    $toolInfo = Get-CopilotTestBoostLabToolInfo
    Assert-CopilotCondition ([string]$toolInfo.Id -eq 'copilot') 'Copilot exported tool id is incorrect.'
    Assert-CopilotCondition ((@($toolInfo.Actions) -join ',') -eq 'Apply,Default') 'Copilot exported actions are incorrect.'
    Assert-CopilotCondition ((@($toolInfo.ImplementedActions) -join ',') -eq 'Apply,Default') 'Copilot implemented actions are incorrect.'
    Assert-CopilotCondition ([string]$toolInfo.RiskLevel -eq 'high') 'Copilot exported risk is incorrect.'

    $applyOperations = @(& $copilotModule { Get-BoostLabCopilotOperations -ActionName 'Apply' })
    $defaultOperations = @(& $copilotModule { Get-BoostLabCopilotOperations -ActionName 'Default' })
    Assert-CopilotCondition ($applyOperations.Count -eq 5) 'Copilot Apply must contain exactly five operation groups.'
    Assert-CopilotCondition ($defaultOperations.Count -eq 3) 'Copilot Default must contain exactly three operation groups.'
    Assert-CopilotCondition ((@($applyOperations | ForEach-Object { [string]$_.Kind }) -join ',') -eq 'StopNamedProcesses,StopWildcardProcesses,RemoveAppxPackages,SetRegistryValue,SetRegistryValue') 'Copilot Apply operation order is incorrect.'
    Assert-CopilotCondition ((@($defaultOperations | ForEach-Object { [string]$_.Kind }) -join ',') -eq 'RegisterAppxPackages,DeleteRegistryKey,DeleteRegistryKey') 'Copilot Default operation order is incorrect.'

    $expectedProcessNames = @(
        'backgroundTaskHost'
        'Copilot'
        'CrossDeviceResume'
        'GameBar'
        'MicrosoftEdgeUpdate'
        'msedge'
        'msedgewebview2'
        'OneDrive'
        'OneDrive.Sync.Service'
        'OneDriveStandaloneUpdater'
        'Resume'
        'RuntimeBroker'
        'Search'
        'SearchHost'
        'Setup'
        'StoreDesktopExtension'
        'WidgetService'
        'Widgets'
    )
    Assert-CopilotCondition ((@($applyOperations[0].Targets) -join '|') -eq ($expectedProcessNames -join '|')) 'Copilot named process stop list does not match Ultimate source.'
    Assert-CopilotCondition ([string]$applyOperations[1].Pattern -eq '*edge*') 'Copilot wildcard process stop pattern must be *edge*.'
    Assert-CopilotCondition ([string]$applyOperations[2].Pattern -eq '*Copilot*') 'Copilot Apply AppX removal pattern must be *Copilot*.'
    Assert-CopilotCondition ([string]$defaultOperations[0].Pattern -eq '*Copilot*') 'Copilot Default AppX re-registration pattern must be *Copilot*.'

    $applyRegistryCommands = @($applyOperations | Where-Object { [string]$_.Kind -eq 'SetRegistryValue' } | ForEach-Object { [string]$_.Command })
    Assert-CopilotCondition ($applyRegistryCommands -contains 'reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d "1" /f') 'HKCU Apply registry command is missing.'
    Assert-CopilotCondition ($applyRegistryCommands -contains 'reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d "1" /f') 'HKLM Apply registry command is missing.'
    $defaultRegistryCommands = @($defaultOperations | Where-Object { [string]$_.Kind -eq 'DeleteRegistryKey' } | ForEach-Object { [string]$_.Command })
    Assert-CopilotCondition ($defaultRegistryCommands -contains 'reg delete "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /f') 'HKCU Default registry command is missing.'
    Assert-CopilotCondition ($defaultRegistryCommands -contains 'reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /f') 'HKLM Default registry command is missing.'

    $namedStops = [System.Collections.Generic.List[string]]::new()
    $wildcardStops = [System.Collections.Generic.List[string]]::new()
    $removedPackages = [System.Collections.Generic.List[string]]::new()
    $registeredPatterns = [System.Collections.Generic.List[string]]::new()
    $registryCommands = [System.Collections.Generic.List[string]]::new()
    $adminChecker = { $true }
    $namedStopper = { param($Name) $namedStops.Add([string]$Name) }
    $wildcardStopper = { param($Pattern) $wildcardStops.Add([string]$Pattern) }
    $appxRemover = { param($Package, $Pattern) $null = $Pattern; $removedPackages.Add([string]$Package.PackageFullName) }
    $appxRegistrar = { param($Pattern) $registeredPatterns.Add([string]$Pattern) }
    $registryRunner = {
        param($CommandText, $Description)
        $null = $Description
        $registryCommands.Add([string]$CommandText)
    }
    $applyRegistryReader = {
        param($Path, $Name)
        $null = $Path
        $null = $Name
        [pscustomobject]@{
            ReadSucceeded = $true
            KeyExists     = $true
            Exists        = $true
            Value         = 1
            DisplayValue  = '1'
            Message       = 'Mocked expected policy value.'
        }
    }
    $absentKeyReader = {
        param($Path)
        $null = $Path
        [pscustomobject]@{
            ReadSucceeded = $true
            Exists        = $false
            DisplayValue  = 'Absent'
            Message       = 'Mocked absent key.'
        }
    }
    $processReader = {
        param($Name, $Pattern)
        $null = $Name
        $null = $Pattern
        [pscustomobject]@{
            ReadSucceeded = $true
            Count         = 0
            DisplayValue  = '0'
            Message       = 'Mocked no matching process.'
        }
    }
    $applyPackage = [pscustomobject]@{
        Name              = 'Microsoft.Copilot'
        PackageFullName   = 'Microsoft.Copilot_1.0.0.0_x64__8wekyb3d8bbwe'
        PackageFamilyName = 'Microsoft.Copilot_8wekyb3d8bbwe'
        InstallLocation   = 'C:\Program Files\WindowsApps\Microsoft.Copilot_1.0.0.0_x64__8wekyb3d8bbwe'
        User              = 'S-1-5-21-test'
    }
    $applyAppxReader = {
        param($Pattern)
        $null = $Pattern
        if ($removedPackages.Count -eq 0) {
            [pscustomobject]@{
                ReadSucceeded = $true
                Count         = 1
                DisplayValue  = '1'
                Message       = 'Mocked pre-removal Copilot package.'
                Packages      = @($applyPackage)
            }
        }
        else {
            [pscustomobject]@{
                ReadSucceeded = $true
                Count         = 0
                DisplayValue  = '0'
                Message       = 'Mocked no matching AppX package.'
                Packages      = @()
            }
        }
    }.GetNewClosure()
    $defaultAppxReader = {
        param($Pattern)
        $null = $Pattern
        [pscustomobject]@{
            ReadSucceeded = $true
            Count         = 1
            DisplayValue  = '1'
            Message       = 'Mocked re-registration target.'
        }
    }

    $applyResult = & $copilotModule {
        param(
            $AdminChecker,
            $NamedProcessStopper,
            $WildcardProcessStopper,
            $AppxRemover,
            $RegistryRunner,
            $RegistryReader,
            $AbsentKeyReader,
            $ProcessReader,
            $ApplyAppxReader
        )

        Invoke-BoostLabCopilotAction `
            -ActionName 'Apply' `
            -AdministratorChecker $AdminChecker `
            -NamedProcessStopper $NamedProcessStopper `
            -WildcardProcessStopper $WildcardProcessStopper `
            -AppxRemover $AppxRemover `
            -RegistryCommandRunner $RegistryRunner `
            -RegistryReader $RegistryReader `
            -RegistryKeyReader $AbsentKeyReader `
            -ProcessReader $ProcessReader `
            -AppxReader $ApplyAppxReader
    } $adminChecker $namedStopper $wildcardStopper $appxRemover $registryRunner $applyRegistryReader $absentKeyReader $processReader $applyAppxReader
    Assert-CopilotCondition ([bool]$applyResult.Success) "Mocked Copilot Apply failed: $($applyResult.Message)"
    Assert-CopilotCondition ((@($namedStops) -join '|') -eq ($expectedProcessNames -join '|')) 'Mocked Apply did not route every named process stop through the adapter.'
    Assert-CopilotCondition ((@($wildcardStops) -join '|') -eq '*edge*') 'Mocked Apply did not route wildcard *edge* through the adapter.'
    Assert-CopilotCondition ((@($removedPackages) -join '|') -eq 'Microsoft.Copilot_1.0.0.0_x64__8wekyb3d8bbwe') 'Mocked Apply did not route the source-matching Copilot package through the AppX remover.'
    Assert-CopilotCondition ((@($registryCommands) -join '|') -eq ($applyRegistryCommands -join '|')) 'Mocked Apply did not route exact registry commands through the adapter.'
    Assert-CopilotCondition ([string]$applyResult.VerificationResult.Status -eq 'Passed') 'Mocked Apply verification did not pass.'
    Assert-CopilotCondition (@($applyResult.Data.PreRemovalCopilotPackages).Count -eq 1) 'Mocked Apply should report pre-removal Copilot packages.'
    Assert-CopilotCondition (@($applyResult.Data.PreRemovalAllUsersCopilotPackages).Count -eq 1) 'Mocked Apply should report pre-removal all-users Copilot package state.'
    Assert-CopilotCondition (@($applyResult.Data.RemainingCopilotPackages).Count -eq 0) 'Mocked Apply should report no remaining packages when verification passes.'
    Assert-CopilotCondition (@($applyResult.Data.PostRemovalAllUsersCopilotPackages).Count -eq 0) 'Mocked Apply should report post-removal all-users Copilot package state.'
    Assert-CopilotCondition (($applyResult.Data.AppxRemovalOutcomes.Outcome -join ',') -eq 'Removed') 'Mocked Apply should report the Copilot package as removed.'

    $noPackageRemover = { throw 'No AppX removal should be attempted when no matching package exists.' }
    $noPackageApply = & $copilotModule {
        param(
            $AdminChecker,
            $NamedProcessStopper,
            $WildcardProcessStopper,
            $AppxRemover,
            $RegistryRunner,
            $RegistryReader,
            $AbsentKeyReader,
            $ProcessReader,
            $AppxReader
        )

        Invoke-BoostLabCopilotAction `
            -ActionName 'Apply' `
            -AdministratorChecker $AdminChecker `
            -NamedProcessStopper $NamedProcessStopper `
            -WildcardProcessStopper $WildcardProcessStopper `
            -AppxRemover $AppxRemover `
            -RegistryCommandRunner $RegistryRunner `
            -RegistryReader $RegistryReader `
            -RegistryKeyReader $AbsentKeyReader `
            -ProcessReader $ProcessReader `
            -AppxReader $AppxReader
    } $adminChecker $namedStopper $wildcardStopper $noPackageRemover $registryRunner $applyRegistryReader $absentKeyReader $processReader { param($Pattern) $null = $Pattern; [pscustomobject]@{ ReadSucceeded = $true; Count = 0; DisplayValue = '0'; Message = 'Mocked no matching AppX package.'; Packages = @(); ProvisionedPackages = @() } }
    Assert-CopilotCondition ([bool]$noPackageApply.Success) 'Copilot Apply should succeed when policies set and no Copilot package existed.'
    Assert-CopilotCondition (($noPackageApply.Data.AppxRemovalOutcomes.Outcome -join ',') -eq 'AlreadyAbsent') 'No-package Apply should report AlreadyAbsent AppX outcome.'

    $nullProcessReader = {
        param($Name, $Pattern)
        $null = $Name
        $null = $Pattern
        $null
    }
    $nullProcessResult = & $copilotModule {
        param(
            $RegistryReader,
            $ProcessReader,
            $AppxReader
        )

        Test-BoostLabCopilotState `
            -ActionName 'Apply' `
            -RegistryReader $RegistryReader `
            -ProcessReader $ProcessReader `
            -AppxReader $AppxReader
    } $applyRegistryReader $nullProcessReader $applyAppxReader
    Assert-CopilotCondition ([string]$nullProcessResult.Status -eq 'Passed') 'Null process query results must verify as not running.'
    Assert-CopilotCondition (-not ((@($nullProcessResult.Checks) | ForEach-Object { [string]$_.Message }) -join ' ').Contains('Count')) 'Null process verification must not surface Count property errors.'

    $scalarProcessReader = {
        param($Name, $Pattern)
        $null = $Pattern
        if ([string]$Name -eq 'Copilot') {
            return [pscustomobject]@{ ProcessName = 'Copilot'; Id = 4242 }
        }
        return $null
    }
    $runningProcessResult = & $copilotModule {
        param(
            $RegistryReader,
            $ProcessReader,
            $AppxReader
        )

        Test-BoostLabCopilotState `
            -ActionName 'Apply' `
            -RegistryReader $RegistryReader `
            -ProcessReader $ProcessReader `
            -AppxReader $AppxReader
    } $applyRegistryReader $scalarProcessReader $applyAppxReader
    Assert-CopilotCondition ([string]$runningProcessResult.Status -eq 'Failed') 'Running scalar process result must fail verification.'
    $copilotProcessCheck = @($runningProcessResult.Checks | Where-Object { [string]$_.Name -eq 'Process Copilot' })[0]
    Assert-CopilotCondition ([string]$copilotProcessCheck.Actual -eq '1') 'Running scalar process result must report count 1.'
    Assert-CopilotCondition ([string]$copilotProcessCheck.Message -match 'Copilot') 'Running process verification must report process identity.'

    $remainingPackageReader = {
        param($Pattern)
        $null = $Pattern
        [pscustomobject]@{
            ReadSucceeded = $true
            Count         = 1
            DisplayValue  = '1'
            Message       = 'Mocked remaining Copilot package.'
            Packages      = @(
                [pscustomobject]@{
                    Name              = 'Microsoft.Copilot'
                    PackageFullName   = 'Microsoft.Copilot_1.0.0.0_x64__8wekyb3d8bbwe'
                    PackageFamilyName = 'Microsoft.Copilot_8wekyb3d8bbwe'
                    InstallLocation   = 'C:\Program Files\WindowsApps\Microsoft.Copilot_1.0.0.0_x64__8wekyb3d8bbwe'
                    User              = 'S-1-5-21-test'
                }
            )
        }
    }
    $remainingPackageRemoveCount = 0
    $remainingPackageStatefulReader = {
        param($Pattern)
        $null = $Pattern
        $remainingPackageRemoveCount++
        & $remainingPackageReader $Pattern
    }.GetNewClosure()
    $remainingPackageResult = & $copilotModule {
        param(
            $AdminChecker,
            $NamedProcessStopper,
            $WildcardProcessStopper,
            $AppxRemover,
            $RegistryRunner,
            $RegistryReader,
            $AbsentKeyReader,
            $ProcessReader,
            $AppxReader
        )

        Invoke-BoostLabCopilotAction `
            -ActionName 'Apply' `
            -AdministratorChecker $AdminChecker `
            -NamedProcessStopper $NamedProcessStopper `
            -WildcardProcessStopper $WildcardProcessStopper `
            -AppxRemover $AppxRemover `
            -RegistryCommandRunner $RegistryRunner `
            -RegistryReader $RegistryReader `
            -RegistryKeyReader $AbsentKeyReader `
            -ProcessReader $ProcessReader `
            -AppxReader $AppxReader
    } $adminChecker $namedStopper $wildcardStopper $appxRemover $registryRunner $applyRegistryReader $absentKeyReader $processReader $remainingPackageStatefulReader
    Assert-CopilotCondition (-not [bool]$remainingPackageResult.Success) 'Remaining Copilot package should keep Apply verification failed.'
    Assert-CopilotCondition ([string]$remainingPackageResult.Message -match 'Microsoft.Copilot_1.0.0.0_x64__8wekyb3d8bbwe') 'Remaining package identity must be present in result message.'
    Assert-CopilotCondition (@($remainingPackageResult.Data.RemainingCopilotPackages).Count -eq 1) 'Remaining package data must include the package record.'
    Assert-CopilotCondition (@($remainingPackageResult.Data.PostRemovalAllUsersCopilotPackages).Count -eq 1) 'Remaining all-users Copilot package state must be reported.'
    Assert-CopilotCondition ([string]$remainingPackageResult.Data.RemainingCopilotPackages[0].PackageFamilyName -eq 'Microsoft.Copilot_8wekyb3d8bbwe') 'Remaining package data must include PackageFamilyName.'
    Assert-CopilotCondition ([string]$remainingPackageResult.Data.ProvisionedPackageScope -match 'NotApplicable') 'Provisioned package scope must remain source-bounded and explicit.'
    Assert-CopilotCondition (($remainingPackageResult.Data.AppxRemovalOutcomes.Outcome -join ',') -match 'RemainingAfterSourceRemove') 'Unexplained remaining package must be marked RemainingAfterSourceRemove.'

    $protectedReader = {
        param($Pattern)
        $null = $Pattern
        [pscustomobject]@{
            ReadSucceeded = $true
            Count         = 1
            DisplayValue  = '1'
            Message       = 'Mocked protected Copilot package remains.'
            Packages      = @($applyPackage)
            ProvisionedPackages = @()
        }
    }
    $protectedRemover = {
        param($Package, $Pattern)
        $null = $Package
        $null = $Pattern
        throw 'Remove-AppxPackage failed with HRESULT 0x80073CFA, error 0x80070032: This app is part of Windows and cannot be uninstalled on a per-user basis.'
    }
    $protectedResult = & $copilotModule {
        param(
            $AdminChecker,
            $NamedProcessStopper,
            $WildcardProcessStopper,
            $AppxRemover,
            $RegistryRunner,
            $RegistryReader,
            $AbsentKeyReader,
            $ProcessReader,
            $AppxReader
        )

        Invoke-BoostLabCopilotAction `
            -ActionName 'Apply' `
            -AdministratorChecker $AdminChecker `
            -NamedProcessStopper $NamedProcessStopper `
            -WildcardProcessStopper $WildcardProcessStopper `
            -AppxRemover $AppxRemover `
            -RegistryCommandRunner $RegistryRunner `
            -RegistryReader $RegistryReader `
            -RegistryKeyReader $AbsentKeyReader `
            -ProcessReader $ProcessReader `
            -AppxReader $AppxReader
    } $adminChecker $namedStopper $wildcardStopper $protectedRemover $registryRunner $applyRegistryReader $absentKeyReader $processReader $protectedReader
    Assert-CopilotCondition ([bool]$protectedResult.Success) 'Known protected Copilot package removal must return warning success, not hard failure.'
    Assert-CopilotCondition ([string]$protectedResult.Status -eq 'Warning') 'Known protected Copilot package removal must report Warning status.'
    Assert-CopilotCondition ([string]$protectedResult.VerificationResult.Status -eq 'Warning') 'Known protected Copilot package removal must produce warning verification.'
    Assert-CopilotCondition ([string]$protectedResult.Message -match 'protected/non-removable') 'Known protected Copilot package result must explain protected/non-removable package.'
    Assert-CopilotCondition (($protectedResult.Data.AppxRemovalOutcomes.Outcome -join ',') -eq 'SkippedProtectedSystemApp') 'Known protected Copilot package must be classified as SkippedProtectedSystemApp.'

    $dependencyRemover = {
        param($Package, $Pattern)
        $null = $Package
        $null = $Pattern
        throw 'Remove-AppxPackage failed with HRESULT 0x80073CF3: package dependency/conflict validation failed because dependent packages remain installed.'
    }
    $dependencyResult = & $copilotModule {
        param(
            $AdminChecker,
            $NamedProcessStopper,
            $WildcardProcessStopper,
            $AppxRemover,
            $RegistryRunner,
            $RegistryReader,
            $AbsentKeyReader,
            $ProcessReader,
            $AppxReader
        )

        Invoke-BoostLabCopilotAction `
            -ActionName 'Apply' `
            -AdministratorChecker $AdminChecker `
            -NamedProcessStopper $NamedProcessStopper `
            -WildcardProcessStopper $WildcardProcessStopper `
            -AppxRemover $AppxRemover `
            -RegistryCommandRunner $RegistryRunner `
            -RegistryReader $RegistryReader `
            -RegistryKeyReader $AbsentKeyReader `
            -ProcessReader $ProcessReader `
            -AppxReader $AppxReader
    } $adminChecker $namedStopper $wildcardStopper $dependencyRemover $registryRunner $applyRegistryReader $absentKeyReader $processReader $protectedReader
    Assert-CopilotCondition ([bool]$dependencyResult.Success) 'Known dependency/framework Copilot package removal must return warning success, not hard failure.'
    Assert-CopilotCondition (($dependencyResult.Data.AppxRemovalOutcomes.Outcome -join ',') -eq 'SkippedDependencyFramework') 'Known dependency/framework Copilot package must be classified as SkippedDependencyFramework.'

    $unexpectedRemover = {
        param($Package, $Pattern)
        $null = $Package
        $null = $Pattern
        throw 'Access is denied.'
    }
    $unexpectedResult = & $copilotModule {
        param(
            $AdminChecker,
            $NamedProcessStopper,
            $WildcardProcessStopper,
            $AppxRemover,
            $RegistryRunner,
            $RegistryReader,
            $AbsentKeyReader,
            $ProcessReader,
            $AppxReader
        )

        Invoke-BoostLabCopilotAction `
            -ActionName 'Apply' `
            -AdministratorChecker $AdminChecker `
            -NamedProcessStopper $NamedProcessStopper `
            -WildcardProcessStopper $WildcardProcessStopper `
            -AppxRemover $AppxRemover `
            -RegistryCommandRunner $RegistryRunner `
            -RegistryReader $RegistryReader `
            -RegistryKeyReader $AbsentKeyReader `
            -ProcessReader $ProcessReader `
            -AppxReader $AppxReader
    } $adminChecker $namedStopper $wildcardStopper $unexpectedRemover $registryRunner $applyRegistryReader $absentKeyReader $processReader $protectedReader
    Assert-CopilotCondition (-not [bool]$unexpectedResult.Success) 'Unexpected Copilot AppX removal error must fail closed.'
    Assert-CopilotCondition (($unexpectedResult.Data.AppxRemovalOutcomes.Outcome -join ',') -match 'FailedUnexpected') 'Unexpected Copilot AppX removal error must be classified FailedUnexpected.'

    $provisionedReader = {
        param($Pattern)
        $null = $Pattern
        [pscustomobject]@{
            ReadSucceeded = $true
            Count         = 0
            DisplayValue  = '0'
            Message       = 'Mocked no installed package, but provisioned package exists.'
            Packages      = @()
            ProvisionedPackages = @([pscustomobject]@{ DisplayName = 'Microsoft.Copilot'; PackageName = 'Microsoft.Copilot_1.0.0.0_neutral_~_8wekyb3d8bbwe' })
        }
    }
    $provisionedResult = & $copilotModule {
        param(
            $AdminChecker,
            $NamedProcessStopper,
            $WildcardProcessStopper,
            $AppxRemover,
            $RegistryRunner,
            $RegistryReader,
            $AbsentKeyReader,
            $ProcessReader,
            $AppxReader
        )

        Invoke-BoostLabCopilotAction `
            -ActionName 'Apply' `
            -AdministratorChecker $AdminChecker `
            -NamedProcessStopper $NamedProcessStopper `
            -WildcardProcessStopper $WildcardProcessStopper `
            -AppxRemover $AppxRemover `
            -RegistryCommandRunner $RegistryRunner `
            -RegistryReader $RegistryReader `
            -RegistryKeyReader $AbsentKeyReader `
            -ProcessReader $ProcessReader `
            -AppxReader $AppxReader
    } $adminChecker $namedStopper $wildcardStopper $noPackageRemover $registryRunner $applyRegistryReader $absentKeyReader $processReader $provisionedReader
    Assert-CopilotCondition ([bool]$provisionedResult.Success) 'Provisioned Copilot package reporting must not broaden source parity into provisioned removal.'
    Assert-CopilotCondition (@($provisionedResult.Data.PostRemovalAllUsersCopilotPackages).Count -eq 0) 'Provisioned package reporting must still report installed all-users package state.'
    Assert-CopilotCondition (@($provisionedResult.Data.RemainingProvisionedCopilotPackages).Count -eq 1) 'Provisioned Copilot package state must be reported.'

    $namedStops.Clear()
    $wildcardStops.Clear()
    $removedPackages.Clear()
    $registeredPatterns.Clear()
    $registryCommands.Clear()
    $defaultResult = & $copilotModule {
        param(
            $AdminChecker,
            $AppxRegistrar,
            $RegistryRunner,
            $AbsentKeyReader,
            $ProcessReader,
            $DefaultAppxReader
        )

        Invoke-BoostLabCopilotAction `
            -ActionName 'Default' `
            -AdministratorChecker $AdminChecker `
            -AppxRegistrar $AppxRegistrar `
            -RegistryCommandRunner $RegistryRunner `
            -RegistryKeyReader $AbsentKeyReader `
            -ProcessReader $ProcessReader `
            -AppxReader $DefaultAppxReader
    } $adminChecker $appxRegistrar $registryRunner $absentKeyReader $processReader $defaultAppxReader
    Assert-CopilotCondition ([bool]$defaultResult.Success) "Mocked Copilot Default failed: $($defaultResult.Message)"
    Assert-CopilotCondition ($namedStops.Count -eq 0) 'Default must not stop named processes.'
    Assert-CopilotCondition ($wildcardStops.Count -eq 0) 'Default must not stop wildcard processes.'
    Assert-CopilotCondition ($removedPackages.Count -eq 0) 'Default must not remove AppX packages.'
    Assert-CopilotCondition ((@($registeredPatterns) -join '|') -eq '*Copilot*') 'Mocked Default did not route AppX re-registration through the adapter.'
    Assert-CopilotCondition ((@($registryCommands) -join '|') -eq ($defaultRegistryCommands -join '|')) 'Mocked Default did not route exact registry delete commands through the adapter.'
    Assert-CopilotCondition ([string]$defaultResult.VerificationResult.Status -eq 'Passed') 'Mocked Default verification did not pass.'

    $unsupportedResult = Invoke-CopilotTestBoostLabToolAction -ActionName 'Restore' -Confirmed:$true
    Assert-CopilotCondition (-not [bool]$unsupportedResult.Success) 'Restore must not be implemented for Copilot.'
    Assert-CopilotCondition ([string]$unsupportedResult.Message -match 'Only Apply and Default') 'Restore blocked message is incorrect.'
}
finally {
    if ($copilotModule) {
        Remove-Module -ModuleInfo $copilotModule -Force -ErrorAction SilentlyContinue
    }
}

$artifactPolicy = Import-PowerShellDataFile -LiteralPath $artifactPolicyPath
Assert-CopilotCondition (@($artifactPolicy.Artifacts).Count -eq 0) 'Copilot must not approve artifact provenance entries.'

$inventoryAssertion = Assert-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot -IncludeSourcePromoted
$parityBaseline = Get-BoostLabParityStatusBaseline -ProjectRoot $ProjectRoot
$executionOrder = Get-BoostLabUltimateParityExecutionOrder -ProjectRoot $ProjectRoot
$nextTarget = Get-BoostLabNextOrderedParityTarget -ParityBaseline $parityBaseline -ExecutionOrder $executionOrder
$copilotParity = @($parityBaseline.Tools | Where-Object { [string]$_.ToolId -eq 'copilot' }) | Select-Object -First 1
Assert-CopilotCondition ($null -ne $copilotParity) 'Copilot parity record is missing.'
Assert-CopilotCondition ([string]$copilotParity.RuntimeStatus -eq 'RuntimeImplemented') 'Copilot parity RuntimeStatus must be RuntimeImplemented.'
Assert-CopilotCondition ([string]$copilotParity.ImplementationLevel -eq 'ParityImplemented') 'Copilot parity ImplementationLevel must be ParityImplemented.'
Assert-CopilotCondition ([string]$copilotParity.UltimateParity -eq 'Yes') 'Copilot UltimateParity must be Yes.'
Assert-CopilotCondition ([string]$copilotParity.NextParityAction -match 'gamemode') 'Copilot parity action must document advancing to GameMode.'
Assert-CopilotCondition ($null -ne $nextTarget) 'Next ordered parity target must be derived from the central baseline.'
Assert-CopilotCondition ([string]$parityBaseline.CurrentOrderedParityTarget -eq [string]$nextTarget.ToolId) 'Current ordered parity cursor must match the derived first non-final target.'
Assert-CopilotCondition ([string]$parityBaseline.CurrentOrderedParityTarget -ne 'copilot') 'Current ordered parity cursor must advance beyond Copilot.'

$categoryCounts = Get-BoostLabParityCategoryCounts -ParityBaseline $parityBaseline
foreach ($level in @('ParityImplemented', 'NearParityControlled', 'ControlledSubset', 'ManualHandoffOnly', 'DeferredForParityWork')) {
    $actual = if ($categoryCounts.ContainsKey($level)) { [int]$categoryCounts[$level] } else { 0 }
    $expected = switch ($level) {
        'ParityImplemented' { [int]$parityBaseline.Counts.UltimateParityImplemented }
        'NearParityControlled' { [int]$parityBaseline.Counts.NearParityControlled }
        'ControlledSubset' { [int]$parityBaseline.Counts.ControlledSubset }
        'ManualHandoffOnly' { [int]$parityBaseline.Counts.ManualHandoffOnly }
        'DeferredForParityWork' { [int]$parityBaseline.Counts.DeferredForParityWork }
    }
    Assert-CopilotCondition ($actual -eq $expected) "Unexpected parity category count for $level."
}

$loudnessPath = Join-Path $ProjectRoot 'source-ultimate\6 Windows\17 Loudness EQ.ps1'
Assert-CopilotCondition (-not (Test-Path -LiteralPath $loudnessPath)) 'Loudness EQ source was reintroduced.'
$nvmeSource = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
        Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
        Where-Object { $_.Name -like '*NVME Faster Driver*' }
)
Assert-CopilotCondition ($nvmeSource.Count -eq 0) 'NVME Faster Driver source was reintroduced.'

[pscustomobject]@{
    Success                       = $true
    ToolId                        = 'copilot'
    SourceHash                    = $actualSourceHash
    ActiveToolCount               = [int]$inventoryAssertion.Snapshot.ActiveTools
    ImplementedToolCount          = [int]$inventoryAssertion.Snapshot.ImplementedTools
    PlaceholderToolCount          = [int]$inventoryAssertion.Snapshot.DeferredPlaceholders
    CurrentOrderedParityTarget    = [string]$parityBaseline.CurrentOrderedParityTarget
    NextOrderedParityTarget       = [string]$nextTarget.ToolId
    CopilotParityStatus           = [string]$copilotParity.ImplementationLevel
    RealOperationsExecuted        = $false
    DeletedToolsRemainDeleted     = $true
    Message                       = 'Copilot exact Ultimate parity implementation is mocked, routed, and accepted.'
    Timestamp                     = Get-Date
}
