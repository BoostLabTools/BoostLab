Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'nvidia-settings'
    Title = 'Nvidia Settings'
    Stage = 'Graphics'
    Order = 4
    Type = 'assistant'
    RiskLevel = 'high'
    Description = 'Source-equivalent controlled runtime. Path B step 2 of 5. Run the Ultimate Nvidia Settings On (Recommended) or Default branch after explicit confirmation.'
    Actions = @('Analyze', 'Apply', 'Default')
    Capabilities = [ordered]@{
        RequiresAdmin = $true
        RequiresInternet = $true
        CanReboot = $false
        CanModifyRegistry = $true
        CanModifyServices = $false
        CanInstallSoftware = $true
        CanDownload = $true
        CanModifyDrivers = $false
        CanModifySecurity = $false
        CanDeleteFiles = $true
        UsesTrustedInstaller = $false
        UsesSafeMode = $false
        SupportsDefault = $true
        SupportsRestore = $false
        NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Analyze', 'Apply', 'Default')
$script:BoostLabExpectedSourceHash = '903F2C1E9965795E3B5C60ABD123A1B4F364A33F783BFFC681FBCB37BCE9E6D5'
$script:BoostLabSourceRelativePath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1'
$script:BoostLabSevenZipUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/7zip.exe'
$script:BoostLabInspectorUrl = 'https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/inspector.exe'
$script:BoostLabControlPanelTarget = 'shell:appsFolder\NVIDIACorp.NVIDIAControlPanel_56jybvy8sckqj!NVIDIACorp.NVIDIAControlPanel'

function Invoke-BoostLabNvidiaSettingsVerifiedArtifactDownload {
    param(
        [Parameter(Mandatory)]
        [string]$ArtifactId,

        [Parameter(Mandatory)]
        [string]$Destination
    )

    $downloadModulePath = Join-Path (Get-BoostLabNvidiaSettingsProjectRoot) 'core\DownloadProvenance.psm1'
    if (-not (Get-Command -Name 'Invoke-BoostLabVerifiedArtifactDownload' -ErrorAction SilentlyContinue)) {
        Import-Module -Name $downloadModulePath -Scope Local -Force -ErrorAction Stop
    }

    Invoke-BoostLabVerifiedArtifactDownload -ArtifactId $ArtifactId -Destination $Destination
}

function Get-BoostLabNvidiaSettingsProjectRoot {
    Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

function Get-BoostLabNvidiaSettingsSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    Join-Path (Get-BoostLabNvidiaSettingsProjectRoot) ($script:BoostLabSourceRelativePath -replace '/', '\')
}

function Get-BoostLabNvidiaSettingsSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabNvidiaSettingsSourcePath
    $exists = Test-Path -LiteralPath $sourcePath -PathType Leaf
    $detectedHash = if ($exists) {
        (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
    }
    else {
        ''
    }

    [pscustomobject]@{
        SourcePath = $sourcePath
        SourceRelativePath = $script:BoostLabSourceRelativePath
        Exists = $exists
        ExpectedSha256 = $script:BoostLabExpectedSourceHash
        DetectedSha256 = $detectedHash
        ChecksumStatus = if ($exists -and $detectedHash -eq $script:BoostLabExpectedSourceHash) {
            'Passed'
        }
        elseif ($exists) {
            'Failed'
        }
        else {
            'Missing'
        }
    }
}

function Get-BoostLabNvidiaSettingsPaths {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $systemRoot = if ([string]::IsNullOrWhiteSpace($env:SystemRoot)) { 'C:\Windows' } else { [string]$env:SystemRoot }
    $programData = if ([string]::IsNullOrWhiteSpace($env:ProgramData)) { 'C:\ProgramData' } else { [string]$env:ProgramData }

    @{
        SystemRoot = $systemRoot
        ProgramData = $programData
        SevenZipInstaller = Join-Path $systemRoot 'Temp\7zip.exe'
        SevenZipShortcut = Join-Path $programData 'Microsoft\Windows\Start Menu\Programs\7-Zip\7-Zip File Manager.lnk'
        StartMenuPrograms = Join-Path $programData 'Microsoft\Windows\Start Menu\Programs'
        SevenZipStartMenuFolder = Join-Path $programData 'Microsoft\Windows\Start Menu\Programs\7-Zip'
        DrsPath = 'C:\ProgramData\NVIDIA Corporation\Drs'
        InspectorExe = Join-Path $systemRoot 'Temp\inspector.exe'
        InspectorNip = Join-Path $systemRoot 'Temp\inspector.nip'
        DisplayClassRoot = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
        NVTweakPath = 'HKLM:\System\ControlSet001\Services\nvlddmkm\Parameters\Global\NVTweak'
        NvTrayPath = 'HKCU:\Software\NVIDIA Corporation\NvTray'
        FtsPaths = @(
            'HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\FTS'
            'HKLM:\SYSTEM\ControlSet001\Services\nvlddmkm\Parameters\FTS'
            'HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\Parameters\FTS'
        )
        ControlPanelTarget = $script:BoostLabControlPanelTarget
    }
}

function Get-BoostLabNvidiaSettingsSourceNipPayloads {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $sourceStatus = Get-BoostLabNvidiaSettingsSourceStatus
    if ([string]$sourceStatus.ChecksumStatus -ne 'Passed') {
        throw "Nvidia Settings source checksum did not pass: $($sourceStatus.ChecksumStatus)"
    }

    $sourceText = Get-Content -LiteralPath ([string]$sourceStatus.SourcePath) -Raw
    $matches = [regex]::Matches(
        $sourceText,
        '\$nipfile\s*=\s*@''\r?\n(?<Payload>.*?)\r?\n''@',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    if ($matches.Count -lt 2) {
        throw 'Nvidia Settings source did not contain both source-defined .nip payloads.'
    }

    @{
        Apply = [string]$matches[0].Groups['Payload'].Value
        Default = [string]$matches[1].Groups['Payload'].Value
    }
}

function New-BoostLabNvidiaSettingsOperation {
    param(
        [Parameter(Mandatory)]
        [int]$Order,

        [Parameter(Mandatory)]
        [string]$Branch,

        [Parameter(Mandatory)]
        [string]$Type,

        [Parameter(Mandatory)]
        [string]$Label,

        [Parameter(Mandatory)]
        [string]$SourceCommand,

        [System.Collections.IDictionary]$Parameters = @{}
    )

    [pscustomobject]@{
        Order = $Order
        Branch = $Branch
        Type = $Type
        Label = $Label
        SourceCommand = $SourceCommand
        Parameters = $Parameters
    }
}

function Get-BoostLabNvidiaSettingsOperationPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName
    )

    $paths = Get-BoostLabNvidiaSettingsPaths
    $payloads = Get-BoostLabNvidiaSettingsSourceNipPayloads
    $branch = if ($ActionName -eq 'Apply') { 'On (Recommended)' } else { 'Default' }
    $operations = New-Object System.Collections.Generic.List[object]
    $order = 1

    foreach ($operation in @(
        @{ Type = 'RequireAdmin'; Label = 'Require Administrator rights'; SourceCommand = 'SCRIPT RUN AS ADMIN'; Parameters = @{} }
        @{ Type = 'RequireInternet'; Label = 'Require internet connectivity'; SourceCommand = 'Test-Connection 8.8.8.8'; Parameters = @{} }
        @{ Type = 'DownloadFile'; Label = 'Download source-defined 7-Zip installer'; SourceCommand = 'IWR 7zip.exe'; Parameters = @{ Url = $script:BoostLabSevenZipUrl; Destination = $paths.SevenZipInstaller; ArtifactId = 'nvidia-settings-seven-zip' } }
        @{ Type = 'StartProcess'; Label = 'Install 7-Zip silently'; SourceCommand = 'Start-Process 7zip.exe /S -Wait'; Parameters = @{ FilePath = $paths.SevenZipInstaller; ArgumentList = @('/S'); Wait = $true } }
        @{ Type = 'SetRegistryValue'; Label = 'Set 7-Zip ContextMenu option'; SourceCommand = 'reg add HKCU\Software\7-Zip\Options ContextMenu 259'; Parameters = @{ Path = 'HKCU:\Software\7-Zip\Options'; Name = 'ContextMenu'; Type = 'DWord'; Data = 259 } }
        @{ Type = 'SetRegistryValue'; Label = 'Set 7-Zip CascadedMenu option'; SourceCommand = 'reg add HKCU\Software\7-Zip\Options CascadedMenu 0'; Parameters = @{ Path = 'HKCU:\Software\7-Zip\Options'; Name = 'CascadedMenu'; Type = 'DWord'; Data = 0 } }
        @{ Type = 'MoveItem'; Label = 'Move 7-Zip File Manager shortcut to Programs'; SourceCommand = 'Move-Item 7-Zip File Manager.lnk'; Parameters = @{ Source = $paths.SevenZipShortcut; Destination = $paths.StartMenuPrograms; ContinueOnMissing = $true } }
        @{ Type = 'RemoveItem'; Label = 'Remove 7-Zip Start Menu folder'; SourceCommand = 'Remove-Item 7-Zip Start Menu folder'; Parameters = @{ Path = $paths.SevenZipStartMenuFolder; Recurse = $true; ContinueOnMissing = $true } }
    )) {
        $operations.Add((New-BoostLabNvidiaSettingsOperation -Order $order -Branch 'Common' -Type $operation.Type -Label $operation.Label -SourceCommand $operation.SourceCommand -Parameters $operation.Parameters))
        $order++
    }

    $branchOperations = if ($ActionName -eq 'Apply') {
        @(
            @{ Type = 'UnblockPath'; Label = 'Unblock NVIDIA Drs files'; SourceCommand = 'Get-ChildItem C:\ProgramData\NVIDIA Corporation\Drs -Recurse | Unblock-File'; Parameters = @{ Path = $paths.DrsPath; Recurse = $true; ContinueOnMissing = $true } }
            @{ Type = 'SetRegistryValue'; Label = 'Set PhysX processor selection to GPU'; SourceCommand = 'reg add NVTweak NvCplPhysxAuto 0'; Parameters = @{ Path = $paths.NVTweakPath; Name = 'NvCplPhysxAuto'; Type = 'DWord'; Data = 0 } }
            @{ Type = 'SetRegistryValue'; Label = 'Enable NVIDIA developer settings'; SourceCommand = 'reg add NVTweak NvDevToolsVisible 1'; Parameters = @{ Path = $paths.NVTweakPath; Name = 'NvDevToolsVisible'; Type = 'DWord'; Data = 1 } }
            @{ Type = 'DynamicDisplayClassSet'; Label = 'Allow GPU performance counters for all users on display keys'; SourceCommand = 'reg add display class RmProfilingAdminOnly 0'; Parameters = @{ Root = $paths.DisplayClassRoot; Name = 'RmProfilingAdminOnly'; Type = 'DWord'; Data = 0; ExcludeLike = '*Configuration' } }
            @{ Type = 'SetRegistryValue'; Label = 'Allow GPU performance counters for all users on NVTweak'; SourceCommand = 'reg add NVTweak RmProfilingAdminOnly 0'; Parameters = @{ Path = $paths.NVTweakPath; Name = 'RmProfilingAdminOnly'; Type = 'DWord'; Data = 0 } }
            @{ Type = 'SetRegistryValue'; Label = 'Disable NVIDIA tray login startup'; SourceCommand = 'reg add HKCU\Software\NVIDIA Corporation\NvTray StartOnLogin 0'; Parameters = @{ Path = $paths.NvTrayPath; Name = 'StartOnLogin'; Type = 'DWord'; Data = 0 } }
            @{ Type = 'SetRegistryValueCollection'; Label = 'Enable source-defined NVIDIA legacy sharpen behavior'; SourceCommand = 'reg add EnableGR535 0 on three FTS paths'; Parameters = @{ Paths = $paths.FtsPaths; Name = 'EnableGR535'; Type = 'DWord'; Data = 0 } }
            @{ Type = 'DownloadFile'; Label = 'Download source-defined NVIDIA Profile Inspector'; SourceCommand = 'IWR inspector.exe'; Parameters = @{ Url = $script:BoostLabInspectorUrl; Destination = $paths.InspectorExe; ArtifactId = 'nvidia-settings-inspector' } }
            @{ Type = 'WriteTextFile'; Label = 'Write source-defined On inspector.nip'; SourceCommand = 'Set-Content inspector.nip On payload'; Parameters = @{ Path = $paths.InspectorNip; Content = $payloads.Apply; Encoding = 'Unicode' } }
            @{ Type = 'StartProcess'; Label = 'Import source-defined On .nip through NVIDIA Profile Inspector'; SourceCommand = 'Start-Process inspector.exe -silentImport -silent inspector.nip -Wait'; Parameters = @{ FilePath = $paths.InspectorExe; ArgumentList = @('-silentImport', '-silent', $paths.InspectorNip); Wait = $true } }
            @{ Type = 'StartProcess'; Label = 'Open NVIDIA Control Panel'; SourceCommand = 'Start-Process shell:appsFolder\NVIDIAControlPanel'; Parameters = @{ FilePath = $paths.ControlPanelTarget; ArgumentList = @(); Wait = $false } }
        )
    }
    else {
        @(
            @{ Type = 'UnblockPath'; Label = 'Unblock NVIDIA Drs files'; SourceCommand = 'Get-ChildItem C:\ProgramData\NVIDIA Corporation\Drs -Recurse | Unblock-File'; Parameters = @{ Path = $paths.DrsPath; Recurse = $true; ContinueOnMissing = $true } }
            @{ Type = 'RemoveRegistryValue'; Label = 'Delete PhysX processor selection value'; SourceCommand = 'reg delete NVTweak NvCplPhysxAuto'; Parameters = @{ Path = $paths.NVTweakPath; Name = 'NvCplPhysxAuto' } }
            @{ Type = 'RemoveRegistryValue'; Label = 'Delete NVIDIA developer settings value'; SourceCommand = 'reg delete NVTweak NvDevToolsVisible'; Parameters = @{ Path = $paths.NVTweakPath; Name = 'NvDevToolsVisible' } }
            @{ Type = 'DynamicDisplayClassDelete'; Label = 'Delete display-key GPU performance counter override'; SourceCommand = 'reg delete display class RmProfilingAdminOnly'; Parameters = @{ Root = $paths.DisplayClassRoot; Name = 'RmProfilingAdminOnly'; ExcludeLike = '*Configuration' } }
            @{ Type = 'RemoveRegistryValue'; Label = 'Delete NVTweak GPU performance counter override'; SourceCommand = 'reg delete NVTweak RmProfilingAdminOnly'; Parameters = @{ Path = $paths.NVTweakPath; Name = 'RmProfilingAdminOnly' } }
            @{ Type = 'RemoveRegistryKey'; Label = 'Delete NVIDIA tray key'; SourceCommand = 'reg delete HKCU\Software\NVIDIA Corporation\NvTray'; Parameters = @{ Path = $paths.NvTrayPath; Recurse = $true } }
            @{ Type = 'SetRegistryValueCollection'; Label = 'Restore source-defined NVIDIA legacy sharpen default'; SourceCommand = 'reg add EnableGR535 1 on three FTS paths'; Parameters = @{ Paths = $paths.FtsPaths; Name = 'EnableGR535'; Type = 'DWord'; Data = 1 } }
            @{ Type = 'DownloadFile'; Label = 'Download source-defined NVIDIA Profile Inspector'; SourceCommand = 'IWR inspector.exe'; Parameters = @{ Url = $script:BoostLabInspectorUrl; Destination = $paths.InspectorExe; ArtifactId = 'nvidia-settings-inspector' } }
            @{ Type = 'WriteTextFile'; Label = 'Write source-defined Default inspector.nip'; SourceCommand = 'Set-Content inspector.nip Default payload'; Parameters = @{ Path = $paths.InspectorNip; Content = $payloads.Default; Encoding = 'Unicode' } }
            @{ Type = 'StartProcess'; Label = 'Import source-defined Default .nip through NVIDIA Profile Inspector'; SourceCommand = 'Start-Process inspector.exe -silentImport -silent inspector.nip -Wait'; Parameters = @{ FilePath = $paths.InspectorExe; ArgumentList = @('-silentImport', '-silent', $paths.InspectorNip); Wait = $true } }
            @{ Type = 'StartProcess'; Label = 'Open NVIDIA Control Panel'; SourceCommand = 'Start-Process shell:appsFolder\NVIDIAControlPanel'; Parameters = @{ FilePath = $paths.ControlPanelTarget; ArgumentList = @(); Wait = $false } }
        )
    }

    foreach ($operation in $branchOperations) {
        $operations.Add((New-BoostLabNvidiaSettingsOperation -Order $order -Branch $branch -Type $operation.Type -Label $operation.Label -SourceCommand $operation.SourceCommand -Parameters $operation.Parameters))
        $order++
    }

    $operationArray = @($operations.ToArray())
    $nipPayload = if ($ActionName -eq 'Apply') { $payloads.Apply } else { $payloads.Default }

    [pscustomobject]@{
        Action = $ActionName
        Branch = $branch
        Source = (Get-BoostLabNvidiaSettingsSourceStatus)
        Operations = $operationArray
        CommonOperationCount = 8
        BranchOperationCount = @($branchOperations).Count
        TotalOperationCount = $operationArray.Count
        SevenZipUrl = $script:BoostLabSevenZipUrl
        InspectorUrl = $script:BoostLabInspectorUrl
        InspectorNipPath = $paths.InspectorNip
        ControlPanelTarget = $paths.ControlPanelTarget
        NipPayload = $nipPayload
    }
}

function New-BoostLabNvidiaSettingsResult {
    param(
        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$CommandStatus,

        [Parameter(Mandatory)]
        [string]$VerificationStatus,

        [Parameter(Mandatory)]
        [string]$Message,

        [AllowNull()]
        [object]$Data = $null,

        [string[]]$Warnings = @(),

        [string[]]$Errors = @(),

        [bool]$Cancelled = $false,

        [bool]$ChangesExecuted = $false
    )

    [pscustomobject]@{
        Success = $Success
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Action = $Action
        Status = $Status
        CommandStatus = $CommandStatus
        VerificationStatus = $VerificationStatus
        Message = $Message
        RestartRequired = $false
        Cancelled = $Cancelled
        ChangesExecuted = $ChangesExecuted
        Timestamp = Get-Date
        Data = $Data
        Warnings = @($Warnings | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Select-Object -Unique)
        Errors = @($Errors | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Select-Object -Unique)
    }
}

function Test-BoostLabNvidiaSettingsAdministrator {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function Invoke-BoostLabNvidiaSettingsDefaultOperation {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Operation
    )

    $parameters = $Operation.Parameters
    try {
        switch ([string]$Operation.Type) {
            'RequireAdmin' {
                if (-not (Test-BoostLabNvidiaSettingsAdministrator)) {
                    throw 'Administrator rights are required.'
                }
            }
            'RequireInternet' {
                if (-not (Test-Connection -ComputerName '8.8.8.8' -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
                    throw 'Internet connectivity is required.'
                }
            }
            'DownloadFile' {
                $destinationParent = Split-Path -Parent ([string]$parameters['Destination'])
                if (-not [string]::IsNullOrWhiteSpace($destinationParent)) {
                    New-Item -Path $destinationParent -ItemType Directory -Force | Out-Null
                }
                Invoke-BoostLabNvidiaSettingsVerifiedArtifactDownload `
                    -ArtifactId ([string]$parameters['ArtifactId']) `
                    -Destination ([string]$parameters['Destination']) | Out-Null
            }
            'StartProcess' {
                $startParameters = @{ FilePath = [string]$parameters['FilePath']; ErrorAction = 'Stop' }
                $argumentList = @($parameters['ArgumentList'])
                if ($argumentList.Count -gt 0) {
                    $startParameters['ArgumentList'] = $argumentList
                }
                if ([bool]$parameters['Wait']) {
                    $startParameters['Wait'] = $true
                }
                Start-Process @startParameters | Out-Null
            }
            'SetRegistryValue' {
                New-Item -Path ([string]$parameters['Path']) -Force | Out-Null
                New-ItemProperty -Path ([string]$parameters['Path']) -Name ([string]$parameters['Name']) -PropertyType ([string]$parameters['Type']) -Value $parameters['Data'] -Force | Out-Null
            }
            'SetRegistryValueCollection' {
                foreach ($path in @($parameters['Paths'])) {
                    New-Item -Path ([string]$path) -Force | Out-Null
                    New-ItemProperty -Path ([string]$path) -Name ([string]$parameters['Name']) -PropertyType ([string]$parameters['Type']) -Value $parameters['Data'] -Force | Out-Null
                }
            }
            'RemoveRegistryValue' {
                Remove-ItemProperty -Path ([string]$parameters['Path']) -Name ([string]$parameters['Name']) -Force -ErrorAction SilentlyContinue
            }
            'RemoveRegistryKey' {
                Remove-Item -Path ([string]$parameters['Path']) -Recurse:([bool]$parameters['Recurse']) -Force -ErrorAction SilentlyContinue
            }
            'DynamicDisplayClassSet' {
                $targets = @(Get-ChildItem -Path ([string]$parameters['Root']) -Force -ErrorAction SilentlyContinue | Where-Object {
                    [string]$_.Name -notlike [string]$parameters['ExcludeLike']
                })
                foreach ($target in $targets) {
                    New-ItemProperty -Path ([string]$target.PSPath) -Name ([string]$parameters['Name']) -PropertyType ([string]$parameters['Type']) -Value $parameters['Data'] -Force | Out-Null
                }
            }
            'DynamicDisplayClassDelete' {
                $targets = @(Get-ChildItem -Path ([string]$parameters['Root']) -Force -ErrorAction SilentlyContinue | Where-Object {
                    [string]$_.Name -notlike [string]$parameters['ExcludeLike']
                })
                foreach ($target in $targets) {
                    Remove-ItemProperty -Path ([string]$target.PSPath) -Name ([string]$parameters['Name']) -Force -ErrorAction SilentlyContinue
                }
            }
            'UnblockPath' {
                if (Test-Path -LiteralPath ([string]$parameters['Path'])) {
                    Get-ChildItem -LiteralPath ([string]$parameters['Path']) -Recurse:([bool]$parameters['Recurse']) -Force -ErrorAction Stop | Unblock-File -ErrorAction Stop
                }
                elseif (-not [bool]$parameters['ContinueOnMissing']) {
                    throw "Path was not found: $($parameters['Path'])"
                }
            }
            'MoveItem' {
                if (Test-Path -LiteralPath ([string]$parameters['Source'])) {
                    Move-Item -LiteralPath ([string]$parameters['Source']) -Destination ([string]$parameters['Destination']) -Force -ErrorAction Stop | Out-Null
                }
                elseif (-not [bool]$parameters['ContinueOnMissing']) {
                    throw "Path was not found: $($parameters['Source'])"
                }
            }
            'RemoveItem' {
                if (Test-Path -LiteralPath ([string]$parameters['Path'])) {
                    Remove-Item -LiteralPath ([string]$parameters['Path']) -Recurse:([bool]$parameters['Recurse']) -Force -ErrorAction Stop | Out-Null
                }
                elseif (-not [bool]$parameters['ContinueOnMissing']) {
                    throw "Path was not found: $($parameters['Path'])"
                }
            }
            'WriteTextFile' {
                $parent = Split-Path -Parent ([string]$parameters['Path'])
                if (-not [string]::IsNullOrWhiteSpace($parent)) {
                    New-Item -Path $parent -ItemType Directory -Force | Out-Null
                }
                Set-Content -Path ([string]$parameters['Path']) -Value ([string]$parameters['Content']) -Encoding ([string]$parameters['Encoding']) -Force
            }
            default {
                throw "Unsupported Nvidia Settings operation type: $($Operation.Type)"
            }
        }

        [pscustomobject]@{
            Success = $true
            Operation = $Operation
            Status = 'Completed'
            Message = "Completed: $($Operation.Label)"
        }
    }
    catch {
        [pscustomobject]@{
            Success = $false
            Operation = $Operation
            Status = 'Failed'
            Message = $_.Exception.Message
        }
    }
}

function Invoke-BoostLabNvidiaSettingsOperationPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Plan,

        [scriptblock]$OperationExecutor
    )

    $executor = if ($null -ne $OperationExecutor) { $OperationExecutor } else { ${function:Invoke-BoostLabNvidiaSettingsDefaultOperation} }
    $results = New-Object System.Collections.Generic.List[object]
    foreach ($operation in @($Plan.Operations)) {
        $result = & $executor -Operation $operation
        $results.Add($result)
        if (-not [bool]$result.Success) {
            break
        }
    }

    $resultArray = @($results.ToArray())
    $failed = @($resultArray | Where-Object { -not [bool]$_.Success })
    [pscustomobject]@{
        Success = ($failed.Count -eq 0 -and $resultArray.Count -eq @($Plan.Operations).Count)
        OperationResults = $resultArray
        CompletedOperationCount = @($resultArray | Where-Object { [bool]$_.Success }).Count
        FailedOperations = @($failed)
        WarningOperations = @()
    }
}

function Get-BoostLabNvidiaSettingsAnalysis {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabNvidiaSettingsSourceStatus
    $applyPlan = $null
    $defaultPlan = $null
    $planError = ''
    if ([string]$sourceStatus.ChecksumStatus -eq 'Passed') {
        try {
            $applyPlan = Get-BoostLabNvidiaSettingsOperationPlan -ActionName Apply
            $defaultPlan = Get-BoostLabNvidiaSettingsOperationPlan -ActionName Default
        }
        catch {
            $planError = $_.Exception.Message
        }
    }

    [pscustomobject]@{
        Mode = 'SourceEquivalentOnDefaultRuntime'
        Source = $sourceStatus
        PathBWorkflow = 'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode'
        PathBStepNumber = 2
        PathBStepTotal = 5
        PathBStep = '2 of 5'
        SourceBehaviorSummary = 'Ultimate common prelude downloads/installs 7-Zip and configures its options, then On/Default branches unblock NVIDIA Drs files, write/delete exact NVIDIA registry values, download Profile Inspector, write/import the source-defined inspector.nip payload, and open NVIDIA Control Panel.'
        CommonPrelude = 'Administrator check, internet check, 7-Zip download/install, 7-Zip HKCU option writes, Start Menu shortcut move, Start Menu folder cleanup.'
        ApplyBranch = 'NVIDIA Settings: On (Recommended)'
        DefaultBranch = 'NVIDIA Settings: Default'
        ApplyPlan = $applyPlan
        DefaultPlan = $defaultPlan
        PlanError = $planError
        NoMutationOccurred = $true
        NoDownloadOccurred = $true
        NoExternalProcessStarted = $true
        NoRegistryMutationOccurred = $true
        NoRebootOccurred = $true
        SupportsRestore = $false
        PathASeparation = 'Nvidia Settings remains separate from Driver Install Debloat & Settings.'
        PathBSeparation = 'Path B steps remain separate: Driver Install Latest, Nvidia Settings, Hdcp, P0 State, and Msi Mode.'
    }
}

function Get-BoostLabToolInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    [pscustomobject]@{
        Id = [string]$script:BoostLabToolMetadata['Id']
        Title = [string]$script:BoostLabToolMetadata['Title']
        Stage = [string]$script:BoostLabToolMetadata['Stage']
        Order = [int]$script:BoostLabToolMetadata['Order']
        Type = [string]$script:BoostLabToolMetadata['Type']
        RiskLevel = [string]$script:BoostLabToolMetadata['RiskLevel']
        Description = [string]$script:BoostLabToolMetadata['Description']
        Actions = @($script:BoostLabToolMetadata['Actions'])
        Capabilities = $script:BoostLabToolMetadata['Capabilities']
        ImplementedActions = @($script:BoostLabImplementedActions)
        ConfirmationRequiredActions = @('Apply', 'Default')
        ConfirmationText = 'Nvidia Settings will run the source-defined On (Recommended) or Default branch, including 7-Zip download/install, registry/profile changes, Profile Inspector download/import, and NVIDIA Control Panel launch. Continue only if you intend to run this source-equivalent workflow now.'
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabNvidiaSettingsSourceStatus
    [pscustomobject]@{
        Supported = $true
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        Source = $sourceStatus
        Reason = if ([string]$sourceStatus.ChecksumStatus -eq 'Passed') {
            'Nvidia Settings source identity verified.'
        }
        else {
            "Nvidia Settings source identity is not ready: $($sourceStatus.ChecksumStatus)."
        }
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $analysis = Get-BoostLabNvidiaSettingsAnalysis
    $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'

    [pscustomobject]@{
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Status = if ($sourceOk) { 'Ready' } else { 'SourceIdentityFailed' }
        Source = $analysis.Source
        ImplementedActions = @($script:BoostLabImplementedActions)
        SupportsDefault = $true
        SupportsRestore = $false
        Data = $analysis
        LastChecked = Get-Date
    }
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [ValidateSet('Analyze', 'Open', 'Apply', 'Default', 'Restore', 'On (Recommended)', 'NVIDIA Settings: On (Recommended)')]
        [string]$ActionName = 'Analyze',

        [bool]$Confirmed = $false,

        [scriptblock]$OperationExecutor
    )

    $canonicalActionName = switch ($ActionName) {
        'On (Recommended)' { 'Apply' }
        'NVIDIA Settings: On (Recommended)' { 'Apply' }
        default { $ActionName }
    }

    if ($canonicalActionName -eq 'Analyze') {
        $analysis = Get-BoostLabNvidiaSettingsAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        return New-BoostLabNvidiaSettingsResult `
            -Success $sourceOk `
            -Action 'Analyze' `
            -Status $(if ($sourceOk) { 'Analyzed' } else { 'SourceIdentityFailed' }) `
            -CommandStatus 'No execution performed' `
            -VerificationStatus $(if ($sourceOk) { 'Passed' } else { 'Failed' }) `
            -Message $(if ($sourceOk) { 'Nvidia Settings source identity and source-equivalent On/Default operation plans were analyzed. No mutation, download, installer, external process, registry write, Profile Inspector import, Control Panel launch, or reboot occurred.' } else { 'Nvidia Settings source identity could not be verified. No operation was executed.' }) `
            -Data $analysis `
            -Errors $(if ($sourceOk) { @() } else { @("Source checksum status: $($analysis.Source.ChecksumStatus)") })
    }

    if ($canonicalActionName -eq 'Open') {
        return New-BoostLabNvidiaSettingsResult `
            -Success $false `
            -Action 'Open' `
            -Status 'OpenUnavailable' `
            -CommandStatus 'Unavailable' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Nvidia Settings has no source-defined standalone Open action. Use On (Recommended) or Default after reviewing the Action Plan.' `
            -Data ([pscustomobject]@{ OpenSupported = $false; NoExternalProcessStarted = $true; NoMutationOccurred = $true })
    }

    if ($canonicalActionName -eq 'Restore') {
        return New-BoostLabNvidiaSettingsResult `
            -Success $false `
            -Action 'Restore' `
            -Status 'RestoreUnavailable' `
            -CommandStatus 'Unavailable' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Nvidia Settings Restore is unavailable because the source defines On and Default branches, not captured-state Restore. No restore or mutation is planned.' `
            -Data ([pscustomobject]@{ RestoreSupported = $false; NoMutationOccurred = $true })
    }

    if ($canonicalActionName -notin @('Apply', 'Default')) {
        return New-BoostLabNvidiaSettingsResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'UnsupportedAction' `
            -CommandStatus 'Unsupported' `
            -VerificationStatus 'NotApplicable' `
            -Message "Unsupported Nvidia Settings action: $ActionName."
    }

    $branch = if ($canonicalActionName -eq 'Apply') { 'On (Recommended)' } else { 'Default' }
    if (-not $Confirmed) {
        return New-BoostLabNvidiaSettingsResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'Cancelled' `
            -CommandStatus 'Cancelled before execution' `
            -VerificationStatus 'NotRun' `
            -Message "Nvidia Settings $branch requires explicit Action Plan confirmation before any 7-Zip download/install, Profile Inspector download/import, registry/profile change, external process, Control Panel launch, or cleanup operation." `
            -Cancelled $true `
            -Data ([pscustomobject]@{ Branch = $branch; ChangesExecuted = $false })
    }

    $sourceStatus = Get-BoostLabNvidiaSettingsSourceStatus
    if ([string]$sourceStatus.ChecksumStatus -ne 'Passed') {
        return New-BoostLabNvidiaSettingsResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'SourceIdentityFailed' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'Failed' `
            -Message "Nvidia Settings $branch blocked because source identity did not pass verification. No operation was executed." `
            -Data ([pscustomobject]@{ Branch = $branch; Source = $sourceStatus; ChangesExecuted = $false }) `
            -Errors @("Source checksum status: $($sourceStatus.ChecksumStatus)")
    }

    try {
        $plan = Get-BoostLabNvidiaSettingsOperationPlan -ActionName $canonicalActionName
        $execution = Invoke-BoostLabNvidiaSettingsOperationPlan -Plan $plan -OperationExecutor $OperationExecutor
    }
    catch {
        return New-BoostLabNvidiaSettingsResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'Failed' `
            -CommandStatus 'Failed before completion' `
            -VerificationStatus 'Failed' `
            -Message "Nvidia Settings $branch failed before operation completion: $($_.Exception.Message)" `
            -Data ([pscustomobject]@{ Branch = $branch; Source = $sourceStatus; ChangesExecuted = $false }) `
            -Errors @($_.Exception.Message)
    }

    $data = [pscustomobject]@{
        Branch = $branch
        Source = $sourceStatus
        OperationPlan = $plan
        OperationResults = @($execution.OperationResults)
        CompletedOperationCount = [int]$execution.CompletedOperationCount
        FailedOperations = @($execution.FailedOperations)
        CommonPreludeExecuted = $true
        SevenZipOperationRepresented = $true
        ProfileInspectorOperationRepresented = $true
        NipPayloadWritten = $true
        ControlPanelLaunchRepresented = $true
    }

    if ([bool]$execution.Success) {
        return New-BoostLabNvidiaSettingsResult `
            -Success $true `
            -Action $canonicalActionName `
            -Status 'Completed' `
            -CommandStatus 'Completed source-equivalent Nvidia Settings workflow' `
            -VerificationStatus 'Passed' `
            -Message "Nvidia Settings $branch completed the source-defined common 7-Zip prelude, NVIDIA registry/profile operations, Profile Inspector .nip import, and NVIDIA Control Panel launch sequence." `
            -Data $data `
            -ChangesExecuted $true
    }

    $failedMessages = @($execution.FailedOperations | ForEach-Object { "$($_.Operation.Label): $($_.Message)" })
    return New-BoostLabNvidiaSettingsResult `
        -Success $false `
        -Action $canonicalActionName `
        -Status 'Failed' `
        -CommandStatus 'Failed during source-equivalent Nvidia Settings workflow' `
        -VerificationStatus 'Failed' `
        -Message "Nvidia Settings $branch failed closed during the source-defined workflow. Failed operation(s): $($failedMessages -join '; ')" `
        -Data $data `
        -Errors $failedMessages
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [bool]$Confirmed = $false,

        [scriptblock]$OperationExecutor
    )

    Invoke-BoostLabToolAction -ActionName 'Default' -Confirmed:$Confirmed -OperationExecutor $OperationExecutor
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
)
