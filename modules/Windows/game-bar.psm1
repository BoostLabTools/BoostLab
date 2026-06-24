Set-StrictMode -Version Latest

$script:BoostLabExpectedSourceHash = '8C6703E68C251D63ADD81A87B7CB6C1F572A4CE55A1E092C33B9B444A9884E59'
$script:BoostLabExpectedCanonicalSourceHash = 'C35831AFE527DFA090E5DA6EBF0F6132256A4ABF3BEBDA90FC8605C47F55C0D2'
$script:BoostLabSourceRelativePath = 'source-ultimate\6 Windows\12 Gamebar.ps1'
$script:BoostLabEdgeWebViewUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/edgewebview.exe'
$script:BoostLabGamingRepairToolUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/gamingrepairtool.exe'
$script:BoostLabImplementedActions = @('Apply', 'Default')

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'game-bar'; Title = 'GameBar'; Stage = 'Windows'; Order = 12
    Type = 'action'; RiskLevel = 'high'
    Description = 'Apply the source-equivalent Gamebar Xbox Off branch or run the source-defined Default repair branch.'
    Actions = @('Apply', 'Default')
    Capabilities = @{
        RequiresAdmin = $true; RequiresInternet = $true; CanReboot = $false
        CanModifyRegistry = $true; CanModifyServices = $true; CanInstallSoftware = $true
        CanDownload = $true; CanModifyDrivers = $false; CanModifySecurity = $true
        CanDeleteFiles = $false; UsesTrustedInstaller = $true; UsesSafeMode = $false
        SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true
    }
}

function Get-BoostLabGameBarProjectRoot {
    Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

function Invoke-BoostLabGameBarVerifiedArtifactDownload {
    param(
        [Parameter(Mandatory)]
        [string]$ArtifactId,

        [Parameter(Mandatory)]
        [string]$Destination
    )

    $downloadModulePath = Join-Path (Get-BoostLabGameBarProjectRoot) 'core\DownloadProvenance.psm1'
    if (-not (Get-Command -Name 'Invoke-BoostLabVerifiedArtifactDownload' -ErrorAction SilentlyContinue)) {
        Import-Module -Name $downloadModulePath -Scope Local -Force -ErrorAction Stop
    }

    Invoke-BoostLabVerifiedArtifactDownload -ArtifactId $ArtifactId -Destination $Destination
}

function Get-BoostLabGameBarSystemRoot {
    if (-not [string]::IsNullOrWhiteSpace($env:SystemRoot)) {
        return $env:SystemRoot
    }

    return 'C:\Windows'
}

function Get-BoostLabGameBarSourceStatus {
    [CmdletBinding()]
    param()

    $projectRoot = Get-BoostLabGameBarProjectRoot
    $sourcePath = Join-Path $projectRoot $script:BoostLabSourceRelativePath
    $sourceVerificationModulePath = Join-Path $projectRoot 'core\SourceVerification.psm1'
    if (-not (Get-Command -Name 'Test-BoostLabSourceChecksum' -ErrorAction SilentlyContinue)) {
        Import-Module -Name $sourceVerificationModulePath -Scope Local -Force -ErrorAction Stop
    }

    $verification = Test-BoostLabSourceChecksum -LiteralPath $sourcePath -ExpectedSha256 $script:BoostLabExpectedSourceHash -ExpectedCanonicalSha256 $script:BoostLabExpectedCanonicalSourceHash

    [pscustomobject]@{
        SourcePath              = $sourcePath
        RelativePath            = $script:BoostLabSourceRelativePath
        ExpectedSHA256          = $script:BoostLabExpectedSourceHash
        ActualSHA256            = [string]$verification.DetectedSha256
        ExpectedCanonicalSHA256 = $script:BoostLabExpectedCanonicalSourceHash
        ActualCanonicalSHA256   = [string]$verification.DetectedCanonicalSha256
        Exists                  = [bool]$verification.Exists
        Matches                 = [string]$verification.ChecksumStatus -eq 'Passed'
        ChecksumStatus          = [string]$verification.ChecksumStatus
        VerificationMode        = [string]$verification.VerificationMode
    }
}

function Get-BoostLabGameBarOffRegContent {
@'
Windows Registry Editor Version 5.00

; disable game bar
[HKEY_CURRENT_USER\System\GameConfigStore]
"GameDVR_Enabled"=dword:00000000

[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\GameDVR]
"AppCaptureEnabled"=dword:00000000

; disable enable open xbox game bar using game controller
[HKEY_CURRENT_USER\Software\Microsoft\GameBar]
"UseNexusForGameBarEnabled"=dword:00000000

; disable use view + menu as guide button in apps
[HKEY_CURRENT_USER\Software\Microsoft\GameBar]
"GamepadNexusChordEnabled"=dword:00000000

; disable ms-gamebar notifications with xbox controller plugged in
[HKEY_CLASSES_ROOT\ms-gamebar]
"(Default)"="URL:ms-gamebar"
"URL Protocol"=""
"NoOpenWith"=""

[HKEY_CLASSES_ROOT\ms-gamebar\shell\open\command]
"(Default)"="%SystemRoot%\\System32\\systray.exe"

[HKEY_CLASSES_ROOT\ms-gamebarservices]
"(Default)"="URL:ms-gamebarservices"
"URL Protocol"=""
"NoOpenWith"=""

[HKEY_CLASSES_ROOT\ms-gamebarservices\shell\open\command]
"(Default)"="%SystemRoot%\\System32\\systray.exe"

[HKEY_CLASSES_ROOT\ms-gamingoverlay]
"(Default)"="URL:ms-gamingoverlay"
"URL Protocol"=""
"NoOpenWith"=""

[HKEY_CLASSES_ROOT\ms-gamingoverlay\shell\open\command]
"(Default)"="%SystemRoot%\\System32\\systray.exe"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter]
"ActivationType"=dword:00000000
'@
}

function Get-BoostLabGameBarDefaultRegContent {
@'
Windows Registry Editor Version 5.00

; game bar
[HKEY_CURRENT_USER\System\GameConfigStore]
"GameDVR_Enabled"=dword:00000000

[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\GameDVR]
"AppCaptureEnabled"=-

; enable open xbox game bar using game controller
[HKEY_CURRENT_USER\Software\Microsoft\GameBar]
"UseNexusForGameBarEnabled"=-

; enable use view + menu as guide button in apps
[HKEY_CURRENT_USER\Software\Microsoft\GameBar]
"GamepadNexusChordEnabled"=-

; ms-gamebar notifications with xbox controller plugged in regedit
[-HKEY_CLASSES_ROOT\ms-gamebar]

[HKEY_CLASSES_ROOT\ms-gamebar]
"URL Protocol"=""
@="URL:ms-gamebar"

[-HKEY_CLASSES_ROOT\ms-gamebar\shell\open\command]

[-HKEY_CLASSES_ROOT\ms-gamebarservices]

[-HKEY_CLASSES_ROOT\ms-gamebarservices\shell\open\command]

[-HKEY_CLASSES_ROOT\ms-gamingoverlay]

[HKEY_CLASSES_ROOT\ms-gamingoverlay]
"URL Protocol"=""
@="URL:ms-gamingoverlay"

[-HKEY_CLASSES_ROOT\ms-gamingoverlay\shell\open\command]

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter]
"ActivationType"=dword:00000001

; gameinput service
[HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\GameInputSvc]
"Start"=dword:00000003

; gamedvr and broadcast user service
[HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\BcastDVRUserService]
"Start"=dword:00000003

; xbox accessory management service
[HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\XboxGipSvc]
"Start"=dword:00000003

; xbox live auth manager service
[HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\XblAuthManager]
"Start"=dword:00000003

; xbox live game save service
[HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\XblGameSave]
"Start"=dword:00000003

; xbox live networking service
[HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\XboxNetApiSvc]
"Start"=dword:00000003
'@
}

function New-BoostLabGameBarOperation {
    param(
        [Parameter(Mandatory)][string]$OperationType,
        [Parameter(Mandatory)][string]$Description,
        [hashtable]$Parameters = @{}
    )

    [pscustomobject]@{
        OperationType = $OperationType
        Description   = $Description
        Parameters    = $Parameters
    }
}

function Get-BoostLabGameBarPreflightOperations {
    @(
        New-BoostLabGameBarOperation -OperationType 'RequireAdministrator' -Description 'Require BoostLab to be running as Administrator.'
        New-BoostLabGameBarOperation -OperationType 'RequireInternet' -Description 'Preserve the Ultimate internet preflight check against 8.8.8.8.'
    )
}

function Get-BoostLabGameBarOperationPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('OffRecommended', 'Default')]
        [string]$Branch
    )

    $systemRoot = Get-BoostLabGameBarSystemRoot
    $offRegPath = Join-Path $systemRoot 'Temp\gamebaroff.reg'
    $defaultRegPath = Join-Path $systemRoot 'Temp\gamebaron.reg'
    $edgeWebViewPath = Join-Path $systemRoot 'Temp\edgewebview.exe'
    $gamingRepairToolPath = Join-Path $systemRoot 'Temp\gamingrepairtool.exe'

    $operations = [System.Collections.Generic.List[object]]::new()
    foreach ($operation in Get-BoostLabGameBarPreflightOperations) {
        $operations.Add($operation)
    }

    if ($Branch -eq 'OffRecommended') {
        $operations.Add((New-BoostLabGameBarOperation -OperationType 'StopProcess' -Description 'Stop the GameBar process.' -Parameters @{ Name = 'GameBar' }))
        $operations.Add((New-BoostLabGameBarOperation -OperationType 'RemoveAppxWhereNameLike' -Description 'Remove all-users AppX packages whose Name matches *Gaming* or *Xbox*.' -Parameters @{ Patterns = @('*Gaming*', '*Xbox*') }))
        $operations.Add((New-BoostLabGameBarOperation -OperationType 'Cmd' -Description 'Stop the GameInputSvc service with the source command.' -Parameters @{ Command = 'sc stop "GameInputSvc" >nul 2>&1' }))
        $operations.Add((New-BoostLabGameBarOperation -OperationType 'StopProcesses' -Description 'Stop source-defined GameInput and gaming service processes.' -Parameters @{ Names = @('gamingservices', 'gamingservicesnet', 'GameInputRedistService') }))
        $operations.Add((New-BoostLabGameBarOperation -OperationType 'Sleep' -Description 'Wait for the source-defined two seconds before GameInput uninstall.' -Parameters @{ Seconds = 2 }))
        $operations.Add((New-BoostLabGameBarOperation -OperationType 'MsiUninstallByDisplayName' -Description 'Uninstall Microsoft GameInput with msiexec /x <guid> /qn /norestart when present.' -Parameters @{ RegistryPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'; DisplayNameLike = '*Microsoft GameInput*'; ArgumentsTemplate = '/x {0} /qn /norestart' }))
        $operations.Add((New-BoostLabGameBarOperation -OperationType 'Cmd' -Description 'Stop the GameInputSvc service again with the source command.' -Parameters @{ Command = 'sc stop "GameInputSvc" >nul 2>&1' }))
        $operations.Add((New-BoostLabGameBarOperation -OperationType 'StopProcesses' -Description 'Stop source-defined GameInput and gaming service processes again.' -Parameters @{ Names = @('gamingservices', 'gamingservicesnet', 'GameInputRedistService') }))
        $operations.Add((New-BoostLabGameBarOperation -OperationType 'SetContent' -Description 'Write the source gamebaroff.reg payload.' -Parameters @{ Path = $offRegPath; Content = Get-BoostLabGameBarOffRegContent }))
        $operations.Add((New-BoostLabGameBarOperation -OperationType 'ImportRegFile' -Description 'Import the source gamebaroff.reg payload with regedit.exe /S.' -Parameters @{ Path = $offRegPath }))
        $operations.Add((New-BoostLabGameBarOperation -OperationType 'TrustedInstallerCommand' -Description 'Disable GameBar PresenceWriter ActivationType with the source TrustedInstaller command.' -Parameters @{ Command = 'reg add "HKLM\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter" /v "ActivationType" /t REG_DWORD /d "0" /f' }))
    }
    else {
        $operations.Add((New-BoostLabGameBarOperation -OperationType 'SetContent' -Description 'Write the source gamebaron.reg payload.' -Parameters @{ Path = $defaultRegPath; Content = Get-BoostLabGameBarDefaultRegContent }))
        $operations.Add((New-BoostLabGameBarOperation -OperationType 'ImportRegFile' -Description 'Import the source gamebaron.reg payload with regedit.exe /S.' -Parameters @{ Path = $defaultRegPath }))
        $operations.Add((New-BoostLabGameBarOperation -OperationType 'TrustedInstallerCommand' -Description 'Restore GameBar PresenceWriter ActivationType with the source TrustedInstaller command.' -Parameters @{ Command = 'reg add "HKLM\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId\Windows.Gaming.GameBar.PresenceServer.Internal.PresenceWriter" /v "ActivationType" /t REG_DWORD /d "1" /f' }))
        $operations.Add((New-BoostLabGameBarOperation -OperationType 'AppxRegisterWhereNameLike' -Description 'Re-register all-users AppX packages whose Name matches *Gaming*, *Xbox*, or *Store*.' -Parameters @{ Patterns = @('*Gaming*', '*Xbox*', '*Store*') }))
        $operations.Add((New-BoostLabGameBarOperation -OperationType 'DownloadFile' -Description 'Download the source Edge WebView installer from the Ultimate author-hosted URL.' -Parameters @{ Url = $script:BoostLabEdgeWebViewUrl; Destination = $edgeWebViewPath; ArtifactId = 'game-bar-edge-webview'; FileName = 'edgewebview.exe'; Classification = 'UltimateAuthorHostedArtifact'; NeedsBoostLabMirror = $true }))
        $operations.Add((New-BoostLabGameBarOperation -OperationType 'StartProcess' -Description 'Launch the downloaded source Edge WebView installer and wait for it.' -Parameters @{ FilePath = $edgeWebViewPath; Wait = $true }))
        $operations.Add((New-BoostLabGameBarOperation -OperationType 'DownloadFile' -Description 'Download the source Gamebar repair tool from the Ultimate author-hosted URL.' -Parameters @{ Url = $script:BoostLabGamingRepairToolUrl; Destination = $gamingRepairToolPath; ArtifactId = 'game-bar-gaming-repair-tool'; FileName = 'gamingrepairtool.exe'; Classification = 'UltimateAuthorHostedArtifact'; NeedsBoostLabMirror = $true }))
        $operations.Add((New-BoostLabGameBarOperation -OperationType 'StartProcess' -Description 'Launch the downloaded source Gamebar repair tool.' -Parameters @{ FilePath = $gamingRepairToolPath; Wait = $false }))
    }

    [pscustomobject]@{
        Branch            = $Branch
        SourceBranchLabel = if ($Branch -eq 'OffRecommended') { 'Gamebar Xbox: Off (Recommended)' } else { 'Gamebar Xbox: Default' }
        Operations        = $operations.ToArray()
        OperationCount    = $operations.Count
        DownloadArtifacts = @($operations | Where-Object { $_.OperationType -eq 'DownloadFile' } | ForEach-Object { $_.Parameters })
        RegistryPayloads  = [pscustomobject]@{
            OffRecommended = Get-BoostLabGameBarOffRegContent
            Default        = Get-BoostLabGameBarDefaultRegContent
        }
    }
}

function Get-BoostLabGameBarAllOperationPlans {
    @(
        Get-BoostLabGameBarOperationPlan -Branch 'OffRecommended'
        Get-BoostLabGameBarOperationPlan -Branch 'Default'
    )
}

function Test-BoostLabGameBarAdministrator {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function Test-BoostLabGameBarInternet {
    Test-Connection -ComputerName '8.8.8.8' -Count 1 -Quiet -ErrorAction SilentlyContinue
}

function Invoke-BoostLabGameBarTrustedInstallerCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Command
    )

    try {
        Stop-Service -Name TrustedInstaller -Force -ErrorAction Stop -WarningAction Stop
    }
    catch {
        & taskkill.exe /im trustedinstaller.exe /f | Out-Null
    }

    $service = Get-CimInstance -ClassName Win32_Service -Filter "Name='TrustedInstaller'"
    $defaultBinPath = $service.PathName
    $trustedInstallerPath = Join-Path (Get-BoostLabGameBarSystemRoot) 'servicing\TrustedInstaller.exe'
    if ($defaultBinPath -ne $trustedInstallerPath) {
        $defaultBinPath = $trustedInstallerPath
    }

    $bytes = [Text.Encoding]::Unicode.GetBytes($Command)
    $base64Command = [Convert]::ToBase64String($bytes)
    & sc.exe config TrustedInstaller binPath= "cmd.exe /c powershell.exe -encodedcommand $base64Command" | Out-Null
    & sc.exe start TrustedInstaller | Out-Null
    & sc.exe config TrustedInstaller binpath= "`"$defaultBinPath`"" | Out-Null

    try {
        Stop-Service -Name TrustedInstaller -Force -ErrorAction Stop -WarningAction Stop
    }
    catch {
        & taskkill.exe /im trustedinstaller.exe /f | Out-Null
    }
}

function Get-BoostLabGameBarObjectProperty {
    param(
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string]$Name
    )

    if ($null -eq $InputObject) {
        return $null
    }

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

function ConvertTo-BoostLabGameBarAppxPackageRecord {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$Package
    )

    if ($null -eq $Package) {
        return [pscustomobject]@{
            Name              = ''
            PackageFullName   = ''
            PackageFamilyName = ''
            User              = ''
            InstallLocation   = ''
        }
    }

    [pscustomobject]@{
        Name              = [string](Get-BoostLabGameBarObjectProperty -InputObject $Package -Name 'Name')
        PackageFullName   = [string](Get-BoostLabGameBarObjectProperty -InputObject $Package -Name 'PackageFullName')
        PackageFamilyName = [string](Get-BoostLabGameBarObjectProperty -InputObject $Package -Name 'PackageFamilyName')
        User              = [string](Get-BoostLabGameBarObjectProperty -InputObject $Package -Name 'User')
        InstallLocation   = [string](Get-BoostLabGameBarObjectProperty -InputObject $Package -Name 'InstallLocation')
    }
}

function Test-BoostLabGameBarAppxNameMatch {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$Name,

        [string[]]$Patterns = @()
    )

    foreach ($pattern in @($Patterns)) {
        if ([string]$Name -like [string]$pattern) {
            return $true
        }
    }

    return $false
}

function Test-BoostLabGameBarConsolePipeException {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$ErrorRecord
    )

    if ($null -eq $ErrorRecord) {
        return $false
    }

    $messages = [System.Collections.Generic.List[string]]::new()
    if ($ErrorRecord -is [System.Management.Automation.ErrorRecord]) {
        $messages.Add([string]$ErrorRecord.Exception.Message)
        if ($null -ne $ErrorRecord.Exception.InnerException) {
            $messages.Add([string]$ErrorRecord.Exception.InnerException.Message)
        }
    }
    elseif ($ErrorRecord -is [System.Exception]) {
        $messages.Add([string]$ErrorRecord.Message)
        if ($null -ne $ErrorRecord.InnerException) {
            $messages.Add([string]$ErrorRecord.InnerException.Message)
        }
    }
    else {
        $messages.Add([string]$ErrorRecord)
    }

    $messageText = ($messages.ToArray() -join "`n")
    return (
        $messageText -like '*No process is on the other end of the pipe*' -or
        $messageText -like '*getting console output buffer information*' -or
        $messageText -like '*0xE9*'
    )
}

function Get-BoostLabGameBarAppxRemovalOutcome {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$ErrorRecord
    )

    $messages = [System.Collections.Generic.List[string]]::new()
    if ($null -eq $ErrorRecord) {
        $messages.Add('')
    }
    elseif ($ErrorRecord -is [System.Management.Automation.ErrorRecord]) {
        $messages.Add([string]$ErrorRecord.Exception.Message)
        if ($null -ne $ErrorRecord.Exception.InnerException) {
            $messages.Add([string]$ErrorRecord.Exception.InnerException.Message)
        }
        if (-not [string]::IsNullOrWhiteSpace([string]$ErrorRecord.FullyQualifiedErrorId)) {
            $messages.Add([string]$ErrorRecord.FullyQualifiedErrorId)
        }
    }
    elseif ($ErrorRecord -is [System.Exception]) {
        $messages.Add([string]$ErrorRecord.Message)
        if ($null -ne $ErrorRecord.InnerException) {
            $messages.Add([string]$ErrorRecord.InnerException.Message)
        }
    }
    else {
        $messages.Add([string]$ErrorRecord)
    }

    $messageText = ($messages.ToArray() -join "`n")
    if (
        $messageText -like '*0x80073CFA*' -or
        $messageText -like '*0x80070032*' -or
        $messageText -like '*part of Windows and cannot be uninstalled*'
    ) {
        return [pscustomobject]@{
            Outcome = 'SkippedProtectedSystemApp'
            IsFailure = $false
            Reason = $messageText
        }
    }

    if (
        $messageText -like '*0x80073CF3*' -or
        $messageText -like '*dependency*' -or
        $messageText -like '*conflict validation*' -or
        $messageText -like '*dependent package*'
    ) {
        return [pscustomobject]@{
            Outcome = 'SkippedDependencyFramework'
            IsFailure = $false
            Reason = $messageText
        }
    }

    [pscustomobject]@{
        Outcome = 'FailedUnexpected'
        IsFailure = $true
        Reason = $messageText
    }
}

function Invoke-BoostLabGameBarRemoveAppxWhereNameLike {
    [CmdletBinding()]
    param(
        [string[]]$Patterns = @(),

        [scriptblock]$AppxGetter = $null,

        [scriptblock]$AppxRemover = $null
    )

    if ($null -eq $AppxGetter) {
        $AppxGetter = { Get-AppXPackage -AllUsers -ErrorAction Stop }
    }
    if ($null -eq $AppxRemover) {
        $AppxRemover = {
            param(
                [Parameter(Mandatory)]
                [object]$Package
            )

            $Package | Remove-AppxPackage -ErrorAction Stop -WarningAction SilentlyContinue -InformationAction SilentlyContinue | Out-Null
        }
    }

    $matched = [System.Collections.Generic.List[object]]::new()
    $removed = [System.Collections.Generic.List[object]]::new()
    $skipped = [System.Collections.Generic.List[object]]::new()
    $protectedSkipped = [System.Collections.Generic.List[object]]::new()
    $dependencySkipped = [System.Collections.Generic.List[object]]::new()
    $failed = [System.Collections.Generic.List[object]]::new()
    $pipeWarnings = [System.Collections.Generic.List[object]]::new()
    $outcomes = [System.Collections.Generic.List[object]]::new()
    $allPackages = @()

    $previousProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try {
        try {
            $allPackages = @(& $AppxGetter)
        }
        catch {
            if (Test-BoostLabGameBarConsolePipeException -ErrorRecord $_) {
                $pipeWarnings.Add([pscustomobject]@{
                    Stage   = 'EnumeratePackages'
                    Reason  = [string]$_.Exception.Message
                    Package = $null
                })
                $allPackages = @()
            }
            else {
                throw
            }
        }

        foreach ($package in @($allPackages)) {
            $record = ConvertTo-BoostLabGameBarAppxPackageRecord -Package $package
            if (-not (Test-BoostLabGameBarAppxNameMatch -Name ([string]$record.Name) -Patterns $Patterns)) {
                $skipped.Add($record)
                $outcomes.Add([pscustomobject]@{
                    Outcome = 'SkippedExcluded'
                    Package = $record
                    Reason = 'Package did not match the source-defined GameBar/Xbox removal patterns.'
                })
                continue
            }

            $matched.Add($record)
            try {
                & $AppxRemover $package | Out-Null
                $removed.Add($record)
                $outcomes.Add([pscustomobject]@{
                    Outcome = 'Removed'
                    Package = $record
                    Reason = 'Remove-AppxPackage completed.'
                })
            }
            catch {
                if (Test-BoostLabGameBarConsolePipeException -ErrorRecord $_) {
                    $pipeWarnings.Add([pscustomobject]@{
                        Stage   = 'RemovePackage'
                        Reason  = [string]$_.Exception.Message
                        Package = $record
                    })
                    continue
                }

                $classification = Get-BoostLabGameBarAppxRemovalOutcome -ErrorRecord $_
                $classifiedResult = [pscustomobject]@{
                    Outcome = [string]$classification.Outcome
                    Package = $record
                    Reason  = [string]$classification.Reason
                }

                if ([string]$classification.Outcome -eq 'SkippedProtectedSystemApp') {
                    $protectedSkipped.Add($classifiedResult)
                    $outcomes.Add($classifiedResult)
                    continue
                }
                if ([string]$classification.Outcome -eq 'SkippedDependencyFramework') {
                    $dependencySkipped.Add($classifiedResult)
                    $outcomes.Add($classifiedResult)
                    continue
                }

                $failed.Add($classifiedResult)
                $outcomes.Add($classifiedResult)
            }
        }
    }
    finally {
        $ProgressPreference = $previousProgressPreference
    }

    $success = ($failed.Count -eq 0)
    $message = if ($success) {
        "Processed $($matched.Count) matching GameBar/Xbox AppX package(s); removed $($removed.Count); protected system skipped $($protectedSkipped.Count); dependency/framework skipped $($dependencySkipped.Count); non-matching skipped $($skipped.Count); unexpected failures $($failed.Count)."
    }
    else {
        "Failed to remove $($failed.Count) matching GameBar/Xbox AppX package(s); removed $($removed.Count); protected system skipped $($protectedSkipped.Count); dependency/framework skipped $($dependencySkipped.Count); non-matching skipped $($skipped.Count)."
    }

    if ($pipeWarnings.Count -gt 0) {
        $message = "$message Console/progress output warning(s): $($pipeWarnings.Count)."
    }

    [pscustomobject]@{
        Success              = $success
        OperationType        = 'RemoveAppxWhereNameLike'
        Description          = 'Remove all-users AppX packages whose Name matches *Gaming* or *Xbox*.'
        Message              = $message
        Patterns             = @($Patterns)
        TotalPackages        = @($allPackages).Count
        MatchedPackages      = $matched.ToArray()
        RemovedPackages      = $removed.ToArray()
        SkippedPackages      = $skipped.ToArray()
        ProtectedSystemAppSkippedPackages = $protectedSkipped.ToArray()
        DependencyFrameworkSkippedPackages = $dependencySkipped.ToArray()
        FailedPackages       = $failed.ToArray()
        PackageOutcomes      = $outcomes.ToArray()
        ConsolePipeWarnings  = $pipeWarnings.ToArray()
    }
}

function Invoke-BoostLabGameBarOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Operation
    )

    switch ([string]$Operation.OperationType) {
        'RequireAdministrator' {
            if (-not (Test-BoostLabGameBarAdministrator)) {
                throw 'Administrator rights are required for the source Gamebar workflow.'
            }
        }
        'RequireInternet' {
            if (-not (Test-BoostLabGameBarInternet)) {
                throw 'Internet connectivity is required for the source Gamebar workflow.'
            }
        }
        'StopProcess' {
            Stop-Process -Force -Name ([string]$Operation.Parameters.Name) -ErrorAction SilentlyContinue | Out-Null
        }
        'RemoveAppxWhereNameLike' {
            $patterns = @($Operation.Parameters.Patterns)
            return Invoke-BoostLabGameBarRemoveAppxWhereNameLike -Patterns $patterns
        }
        'Cmd' {
            & $env:ComSpec /c ([string]$Operation.Parameters.Command) | Out-Null
        }
        'StopProcesses' {
            foreach ($processName in @($Operation.Parameters.Names)) {
                Stop-Process -Name ([string]$processName) -Force -ErrorAction SilentlyContinue
            }
        }
        'Sleep' {
            Start-Sleep -Seconds ([int]$Operation.Parameters.Seconds)
        }
        'MsiUninstallByDisplayName' {
            $items = Get-ItemProperty ([string]$Operation.Parameters.RegistryPath) -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -like [string]$Operation.Parameters.DisplayNameLike }
            foreach ($item in @($items)) {
                $arguments = [string]::Format([string]$Operation.Parameters.ArgumentsTemplate, [string]$item.PSChildName)
                Start-Process 'msiexec.exe' -ArgumentList $arguments -Wait -NoNewWindow
            }
        }
        'SetContent' {
            Set-Content -Path ([string]$Operation.Parameters.Path) -Value ([string]$Operation.Parameters.Content) -Force
        }
        'ImportRegFile' {
            Start-Process -Wait 'regedit.exe' -ArgumentList ('/S "{0}"' -f [string]$Operation.Parameters.Path) -WindowStyle Hidden
        }
        'TrustedInstallerCommand' {
            Invoke-BoostLabGameBarTrustedInstallerCommand -Command ([string]$Operation.Parameters.Command)
        }
        'AppxRegisterWhereNameLike' {
            $patterns = @($Operation.Parameters.Patterns)
            Get-AppXPackage -AllUsers | Where-Object {
                $packageName = [string]$_.Name
                foreach ($pattern in $patterns) {
                    if ($packageName -like [string]$pattern) { return $true }
                }
                return $false
            } | ForEach-Object {
                Add-AppxPackage -DisableDevelopmentMode -Register -ErrorAction SilentlyContinue "$($_.InstallLocation)\AppXManifest.xml"
            }
        }
        'DownloadFile' {
            Invoke-BoostLabGameBarVerifiedArtifactDownload `
                -ArtifactId ([string]$Operation.Parameters.ArtifactId) `
                -Destination ([string]$Operation.Parameters.Destination) | Out-Null
        }
        'StartProcess' {
            $parameters = @{ FilePath = [string]$Operation.Parameters.FilePath }
            if ([bool]$Operation.Parameters.Wait) {
                $parameters['Wait'] = $true
            }
            Start-Process @parameters
        }
        default {
            throw "Unsupported Gamebar operation type: $($Operation.OperationType)"
        }
    }

    [pscustomobject]@{
        Success       = $true
        OperationType = [string]$Operation.OperationType
        Description   = [string]$Operation.Description
    }
}

function Invoke-BoostLabGameBarBranchWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('OffRecommended', 'Default')]
        [string]$Branch,

        [scriptblock]$OperationExecutor,

        [switch]$SkipEnvironmentChecks
    )

    $plan = Get-BoostLabGameBarOperationPlan -Branch $Branch
    $results = [System.Collections.Generic.List[object]]::new()
    $changesExecuted = $false

    foreach ($operation in @($plan.Operations)) {
        if ($SkipEnvironmentChecks -and $operation.OperationType -in @('RequireAdministrator', 'RequireInternet')) {
            $results.Add([pscustomobject]@{
                Success       = $true
                OperationType = [string]$operation.OperationType
                Description   = [string]$operation.Description
                Skipped       = $true
            })
            continue
        }

        try {
            $operationResult = if ($null -ne $OperationExecutor) {
                & $OperationExecutor $operation
            }
            else {
                Invoke-BoostLabGameBarOperation -Operation $operation
            }

            if ($null -eq $operationResult) {
                $operationResult = [pscustomobject]@{
                    Success       = $true
                    OperationType = [string]$operation.OperationType
                    Description   = [string]$operation.Description
                }
            }

            $results.Add($operationResult)
            if ($operation.OperationType -notin @('RequireAdministrator', 'RequireInternet', 'Sleep')) {
                $changesExecuted = $true
            }

            $successProperty = $operationResult.PSObject.Properties['Success']
            if ($null -ne $successProperty -and -not [bool]$successProperty.Value) {
                return [pscustomobject]@{
                    Success            = $false
                    Status             = 'Error'
                    CommandStatus      = 'Failed'
                    VerificationStatus = 'Failed'
                    Branch             = $Branch
                    SourceBranch       = $plan.SourceBranchLabel
                    Message            = "Gamebar $($plan.SourceBranchLabel) failed at operation $($operation.OperationType): $($operationResult.Message)"
                    ChangesExecuted    = $changesExecuted
                    Operations         = $results.ToArray()
                    Plan               = $plan
                }
            }
        }
        catch {
            $results.Add([pscustomobject]@{
                Success       = $false
                OperationType = [string]$operation.OperationType
                Description   = [string]$operation.Description
                Error         = $_.Exception.Message
            })

            return [pscustomobject]@{
                Success         = $false
                Status          = 'Error'
                CommandStatus   = 'Failed'
                VerificationStatus = 'Failed'
                Branch          = $Branch
                SourceBranch    = $plan.SourceBranchLabel
                Message         = "Gamebar $($plan.SourceBranchLabel) failed at operation $($operation.OperationType): $($_.Exception.Message)"
                ChangesExecuted = $changesExecuted
                Operations      = $results.ToArray()
                Plan            = $plan
            }
        }
    }

    [pscustomobject]@{
        Success            = $true
        Status             = 'Success'
        CommandStatus      = 'Completed'
        VerificationStatus = 'Passed'
        Branch             = $Branch
        SourceBranch       = $plan.SourceBranchLabel
        Message            = "Gamebar $($plan.SourceBranchLabel) source-equivalent workflow completed."
        ChangesExecuted    = $changesExecuted
        Operations         = $results.ToArray()
        Plan               = $plan
    }
}

function Get-BoostLabGameBarAnalysis {
    [CmdletBinding()]
    param()

    $sourceStatus = Get-BoostLabGameBarSourceStatus
    [pscustomobject]@{
        ToolId                    = 'game-bar'
        Source                    = $sourceStatus
        SourceBehaviorSummary     = 'Ultimate exposes two menu branches: Gamebar Xbox Off (Recommended) and Gamebar Xbox Default. Off stops GameBar, removes *Gaming*/*Xbox* AppX packages, stops GameInput targets, uninstalls Microsoft GameInput, writes/imports gamebaroff.reg, and runs a TrustedInstaller PresenceWriter registry command. Default writes/imports gamebaron.reg, runs a TrustedInstaller PresenceWriter registry command, re-registers *Gaming*/*Xbox*/*Store* AppX packages, downloads and launches edgewebview.exe, and downloads and launches gamingrepairtool.exe.'
        Actions                   = $script:BoostLabImplementedActions
        Branches                  = @('OffRecommended', 'Default')
        OperationPlans            = Get-BoostLabGameBarAllOperationPlans
        Downloads                 = @(
            [pscustomobject]@{ Url = $script:BoostLabEdgeWebViewUrl; FileName = 'edgewebview.exe'; Classification = 'UltimateAuthorHostedArtifact'; NeedsBoostLabMirror = $true }
            [pscustomobject]@{ Url = $script:BoostLabGamingRepairToolUrl; FileName = 'gamingrepairtool.exe'; Classification = 'UltimateAuthorHostedArtifact'; NeedsBoostLabMirror = $true }
        )
        OpenSupported             = $false
        RestoreSupported          = $false
        NoMutationOccurred        = $true
        NoDownloadOccurred        = $true
        NoExternalProcessStarted  = $true
    }
}

function New-BoostLabGameBarActionResult {
    param(
        [Parameter(Mandatory)][bool]$Success,
        [Parameter(Mandatory)][string]$Action,
        [Parameter(Mandatory)][string]$Status,
        [Parameter(Mandatory)][string]$CommandStatus,
        [Parameter(Mandatory)][string]$VerificationStatus,
        [Parameter(Mandatory)][string]$Message,
        [bool]$ChangesExecuted = $false,
        [object]$Data = $null,
        [string[]]$Errors = @(),
        [string[]]$Warnings = @()
    )

    [pscustomobject]@{
        Success            = $Success
        ToolId             = 'game-bar'
        ToolTitle          = 'GameBar'
        Action             = $Action
        Status             = $Status
        CommandStatus      = $CommandStatus
        VerificationStatus = $VerificationStatus
        Message            = $Message
        ChangesExecuted    = $ChangesExecuted
        Errors             = @($Errors)
        Warnings           = @($Warnings | Select-Object -Unique)
        Data               = $Data
        RestartRequired    = $false
        Cancelled          = $false
        Timestamp          = [DateTimeOffset]::Now
    }
}

function Get-BoostLabToolInfo {
    [CmdletBinding()]
    param()

    $metadata = [ordered]@{}
    foreach ($key in $script:BoostLabToolMetadata.Keys) {
        $metadata[$key] = $script:BoostLabToolMetadata[$key]
    }
    $metadata['ImplementedActions'] = $script:BoostLabImplementedActions
    $metadata['SourceRelativePath'] = $script:BoostLabSourceRelativePath
    $metadata['ExpectedSourceSHA256'] = $script:BoostLabExpectedSourceHash
    $metadata['SourceBranches'] = @('Gamebar Xbox: Off (Recommended)', 'Gamebar Xbox: Default')
    $metadata
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    param()

    $sourceStatus = Get-BoostLabGameBarSourceStatus
    [pscustomobject]@{
        Supported = [bool]$sourceStatus.Matches
        Status    = if ($sourceStatus.Matches) { 'Supported' } else { 'NeedsSourceIdentity' }
        Message   = if ($sourceStatus.Matches) { 'Gamebar source identity verified.' } else { 'Gamebar source identity could not be verified.' }
        Source    = $sourceStatus
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    param()

    Get-BoostLabGameBarAnalysis
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ActionName,
        [switch]$Confirmed,
        [scriptblock]$OperationExecutor,
        [switch]$SkipEnvironmentChecks
    )

    if ($ActionName -notin $script:BoostLabImplementedActions) {
        return New-BoostLabGameBarActionResult `
            -Success $false `
            -Action $ActionName `
            -Status 'Not supported' `
            -CommandStatus 'NotSupported' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Gamebar only exposes the source-backed Apply and Default actions. Open and Restore are not source-defined.'
    }

    $sourceStatus = Get-BoostLabGameBarSourceStatus
    if (-not $sourceStatus.Matches) {
        return New-BoostLabGameBarActionResult `
            -Success $false `
            -Action $ActionName `
            -Status 'Blocked' `
            -CommandStatus 'NeedsSourceIdentity' `
            -VerificationStatus 'Failed' `
            -Message 'Gamebar source checksum did not match the approved Ultimate source, so no operation executed.' `
            -Errors @('NeedsSourceIdentity') `
            -Data @{ Source = $sourceStatus }
    }

    if (-not $Confirmed) {
        return New-BoostLabGameBarActionResult `
            -Success $false `
            -Action $ActionName `
            -Status 'Cancelled' `
            -CommandStatus 'ConfirmationRequired' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Gamebar requires explicit Action Plan confirmation before source-equivalent package, service, registry, TrustedInstaller, download, or installer behavior can run.' `
            -Warnings @('No Gamebar operation executed because confirmation was not provided.') `
            -Data @{ Source = $sourceStatus; Analysis = Get-BoostLabGameBarAnalysis }
    }

    $branch = if ($ActionName -eq 'Apply') { 'OffRecommended' } else { 'Default' }
    $workflow = Invoke-BoostLabGameBarBranchWorkflow `
        -Branch $branch `
        -OperationExecutor $OperationExecutor `
        -SkipEnvironmentChecks:$SkipEnvironmentChecks

    return New-BoostLabGameBarActionResult `
        -Success ([bool]$workflow.Success) `
        -Action $ActionName `
        -Status ([string]$workflow.Status) `
        -CommandStatus ([string]$workflow.CommandStatus) `
        -VerificationStatus ([string]$workflow.VerificationStatus) `
        -Message ([string]$workflow.Message) `
        -ChangesExecuted ([bool]$workflow.ChangesExecuted) `
        -Errors $(if ($workflow.Success) { @() } else { @([string]$workflow.Message) }) `
        -Warnings @('Default is source-defined behavior, not captured-state Restore.') `
        -Data @{ Source = $sourceStatus; Workflow = $workflow }
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    param(
        [switch]$Confirmed,
        [scriptblock]$OperationExecutor,
        [switch]$SkipEnvironmentChecks
    )

    Invoke-BoostLabToolAction -ActionName 'Default' -Confirmed:$Confirmed -OperationExecutor $OperationExecutor -SkipEnvironmentChecks:$SkipEnvironmentChecks
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo',
    'Test-BoostLabToolCompatibility',
    'Get-BoostLabToolState',
    'Invoke-BoostLabToolAction',
    'Restore-BoostLabToolDefault',
    'Get-BoostLabGameBarSourceStatus',
    'Get-BoostLabGameBarOperationPlan',
    'Get-BoostLabGameBarAllOperationPlans',
    'Get-BoostLabGameBarAnalysis',
    'Invoke-BoostLabGameBarBranchWorkflow',
    'Invoke-BoostLabGameBarRemoveAppxWhereNameLike'
)
