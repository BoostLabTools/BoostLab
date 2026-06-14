Set-StrictMode -Version Latest

$verificationModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1'
if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module -Name $verificationModulePath -Scope Local -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'smt-ht-assistant'
    Title = 'SMT / HT Assistant'
    Stage = 'Advanced'
    Order = 4
    Type = 'assistant'
    RiskLevel = 'high'
    Description = 'Analyze processor topology and temporarily disable sibling CPU threads per selected app or launcher.'
    Actions = @('Analyze', 'Apply', 'Open')
    Capabilities = [ordered]@{
        RequiresAdmin = $true
        RequiresInternet = $false
        CanReboot = $false
        CanModifyRegistry = $false
        CanModifyServices = $false
        CanInstallSoftware = $false
        CanDownload = $false
        CanModifyDrivers = $false
        CanModifySecurity = $false
        CanDeleteFiles = $false
        UsesTrustedInstaller = $false
        UsesSafeMode = $false
        SupportsDefault = $false
        SupportsRestore = $false
        NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Analyze', 'Apply', 'Open')
$script:BoostLabLauncherStopList = @(
    'Battle.net'
    'BsgLauncher'
    'EADesktop'
    'EpicGamesLauncher'
    'GalaxyClient'
    'RobloxPlayerBeta'
    'RiotClientServices'
    'Launcher'
    'steam'
    'upc'
)

function Test-BoostLabAdministrator {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function New-BoostLabSmtHtAssistantResult {
    param(
        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [string]$Message,

        [bool]$Cancelled = $false,

        [AllowNull()]
        [object]$Data = $null,

        [AllowNull()]
        [object]$VerificationResult = $null
    )

    [pscustomobject]@{
        Success = $Success
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Action = $Action
        Message = $Message
        RestartRequired = $false
        Cancelled = $Cancelled
        Timestamp = Get-Date
        Data = $Data
        VerificationResult = $VerificationResult
    }
}

function Get-BoostLabLogicalProcessorCount {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [scriptblock]$ComputerSystemReader = {
            Get-WmiObject Win32_ComputerSystem -ErrorAction Stop
        }
    )

    $computerSystem = & $ComputerSystemReader
    return [int]$computerSystem.NumberOfLogicalProcessors
}

function Get-BoostLabSmtHtAffinityProfile {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateRange(1, 256)]
        [int]$LogicalProcessorCount
    )

    $binary = ''
    for ($i = 0; $i -lt $LogicalProcessorCount; $i++) {
        if ($i % 2 -eq 0) {
            $binary += '0'
        }
        else {
            $binary += '1'
        }
    }

    $binary = $binary.PadLeft([math]::Ceiling($binary.Length / 4) * 4, '0')
    $hexadecimal = ''
    for ($i = 0; $i -lt $binary.Length; $i += 4) {
        $binChunk = $binary.Substring($i, 4)
        $hexadecimal += [Convert]::ToString([Convert]::ToInt32($binChunk, 2), 16)
    }

    [pscustomobject]@{
        LogicalProcessorCount = $LogicalProcessorCount
        BinaryMask = $binary
        HexMask = $hexadecimal.ToUpperInvariant()
        IntegerMask = [Convert]::ToInt32($hexadecimal, 16)
    }
}

function Get-BoostLabSmtHtCandidateProcesses {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [scriptblock]$ProcessReader = {
            Get-Process -ErrorAction Stop
        }
    )

    $candidates = @(
        & $ProcessReader |
            Where-Object { $_.WorkingSet64 -gt 500MB } |
            Sort-Object -Property WorkingSet64 -Descending |
            Select-Object `
                @{ Name = 'Name'; Expression = { [string]$_.ProcessName } },
                @{ Name = 'Id'; Expression = { [int]$_.Id } },
                @{ Name = 'WorkingSetMB'; Expression = { [math]::Round($_.WorkingSet64 / 1MB, 2) } }
    )
    return $candidates
}

function Show-BoostLabSmtHtProcessSelectionDialog {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object[]]$Candidates
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'SMT / HT Assistant - Select Running Process'
    $form.StartPosition = 'CenterScreen'
    $form.Size = New-Object System.Drawing.Size(700, 420)
    $form.MinimizeBox = $false
    $form.MaximizeBox = $false
    $form.TopMost = $true

    $label = New-Object System.Windows.Forms.Label
    $label.Text = 'Select a running process larger than 500 MB to apply the temporary SMT / HT-off affinity mask.'
    $label.AutoSize = $false
    $label.Size = New-Object System.Drawing.Size(660, 36)
    $label.Location = New-Object System.Drawing.Point(12, 12)
    $form.Controls.Add($label)

    $listView = New-Object System.Windows.Forms.ListView
    $listView.View = 'Details'
    $listView.FullRowSelect = $true
    $listView.MultiSelect = $false
    $listView.GridLines = $true
    $listView.Size = New-Object System.Drawing.Size(660, 280)
    $listView.Location = New-Object System.Drawing.Point(12, 56)
    [void]$listView.Columns.Add('Process', 260)
    [void]$listView.Columns.Add('Id', 120)
    [void]$listView.Columns.Add('Working Set (MB)', 160)
    foreach ($candidate in $Candidates) {
        $item = New-Object System.Windows.Forms.ListViewItem([string]$candidate.Name)
        [void]$item.SubItems.Add([string]$candidate.Id)
        [void]$item.SubItems.Add([string]$candidate.WorkingSetMB)
        $item.Tag = $candidate
        [void]$listView.Items.Add($item)
    }
    $form.Controls.Add($listView)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = 'Apply'
    $okButton.Location = New-Object System.Drawing.Point(486, 348)
    $okButton.Size = New-Object System.Drawing.Size(90, 28)
    $okButton.Add_Click({
        if ($listView.SelectedItems.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show(
                'Select a process before continuing.',
                'SMT / HT Assistant',
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            ) | Out-Null
            return
        }

        $form.Tag = $listView.SelectedItems[0].Tag
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    })
    $form.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = 'Cancel'
    $cancelButton.Location = New-Object System.Drawing.Point(582, 348)
    $cancelButton.Size = New-Object System.Drawing.Size(90, 28)
    $cancelButton.Add_Click({
        $form.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $form.Close()
    })
    $form.Controls.Add($cancelButton)

    $dialogResult = $form.ShowDialog()
    if ($dialogResult -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }

    return [pscustomobject]$form.Tag
}

function Show-BoostLabSmtHtExecutableSelectionDialog {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    Add-Type -AssemblyName System.Windows.Forms

    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = 'Select Launcher, Game, Shortcut, or Executable'
    $dialog.Filter = 'All Files (*.*)|*.*'
    $dialog.CheckFileExists = $true
    $dialog.Multiselect = $false

    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
        return ''
    }

    return [string]$dialog.FileName
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$OperatingSystem = $env:OS,

        [scriptblock]$CommandResolver = {
            param($CommandName)
            Get-Command -Name $CommandName -ErrorAction SilentlyContinue
        }
    )

    $missingCommands = @(
        foreach ($commandName in @(
            'Get-WmiObject'
            'Get-Process'
            'Stop-Process'
        )) {
            if (@(& $CommandResolver $commandName).Count -eq 0) {
                $commandName
            }
        }
    )

    [pscustomobject]@{
        Supported = ($OperatingSystem -eq 'Windows_NT' -and $missingCommands.Count -eq 0)
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason = if ($OperatingSystem -ne 'Windows_NT') {
            'SMT / HT Assistant requires Windows.'
        }
        elseif ($missingCommands.Count -gt 0) {
            'SMT / HT Assistant is unavailable because these commands were not found: {0}.' -f ($missingCommands -join ', ')
        }
        else {
            'The required process and CPU-topology commands are available.'
        }
        Timestamp = Get-Date
    }
}

function Get-BoostLabSmtHtAnalyzeData {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [scriptblock]$LogicalProcessorReader = { Get-BoostLabLogicalProcessorCount },
        [scriptblock]$CandidateReader = { Get-BoostLabSmtHtCandidateProcesses }
    )

    $logicalProcessorCount = & $LogicalProcessorReader
    $affinityProfile = Get-BoostLabSmtHtAffinityProfile -LogicalProcessorCount $logicalProcessorCount
    $candidates = @(& $CandidateReader)

    [pscustomobject]@{
        LogicalProcessorCount = $logicalProcessorCount
        GeneratedBinaryMask = [string]$affinityProfile.BinaryMask
        GeneratedHexMask = [string]$affinityProfile.HexMask
        CandidateProcessCount = $candidates.Count
        CandidateProcesses = $candidates
        LauncherStopList = @($script:BoostLabLauncherStopList)
        Notes = @(
            'TEMPORARILY DISABLE CPU THREADS FOR TESTING PER APP/GAME'
            'Off: Already Running targets a selected running process.'
            'Off: Startup stops approved launchers, selects a launcher/game/shortcut/exe, and starts it with the source affinity mask.'
            'This tool changes per-process affinity only. It does not change BIOS SMT/HT settings or permanent CPU configuration.'
        )
        Warnings = if ($candidates.Count -eq 0) {
            @('No running processes above 500 MB were detected for the Already Running path.')
        }
        else {
            @()
        }
        Timestamp = Get-Date
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    try {
        $analysis = Get-BoostLabSmtHtAnalyzeData
        $status = 'Logical processors: {0}; Candidate processes: {1}; Hex mask: {2}' -f `
            $analysis.LogicalProcessorCount, `
            $analysis.CandidateProcessCount, `
            $analysis.GeneratedHexMask
    }
    catch {
        $status = 'Unsupported or unavailable'
    }

    [pscustomobject]@{
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Status = $status
        LastAction = $null
        LastResult = $null
        RestartRequired = $false
        Timestamp = Get-Date
    }
}

function Test-BoostLabSmtHtVerificationResult {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Open')]
        [string]$ActionName,

        [AllowNull()]
        [object]$TargetProcess = $null,

        [Parameter(Mandatory)]
        [pscustomobject]$AffinityProfile,

        [Parameter(Mandatory)]
        [string]$TargetName,

        [Parameter(Mandatory)]
        [string]$TargetDescriptor
    )

    $checks = [System.Collections.Generic.List[object]]::new()

    if ($null -eq $TargetProcess) {
        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name 'Target process detection' `
                -Expected $TargetDescriptor `
                -Actual 'Not detected' `
                -Status 'Warning' `
                -Message 'The affinity launch command completed, but the expected process could not be detected for verification.')
        )

        return New-BoostLabVerificationResult `
            -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
            -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
            -Action $ActionName `
            -Status 'Warning' `
            -ExpectedState ([pscustomobject]@{
                Target = $TargetDescriptor
                BinaryMask = [string]$AffinityProfile.BinaryMask
                HexMask = [string]$AffinityProfile.HexMask
                IntegerMask = [int]$AffinityProfile.IntegerMask
            }) `
            -DetectedState ([pscustomobject]@{
                Target = $TargetName
                BinaryMask = 'Unknown'
                HexMask = 'Unknown'
                IntegerMask = 'Unknown'
            }) `
            -Checks $checks.ToArray() `
            -Message 'The selected affinity workflow completed, but the target process could not be detected for verification.'
    }

    $actualAffinity = [int]$TargetProcess.ProcessorAffinity
    $actualBinary = [Convert]::ToString($actualAffinity, 2).PadLeft([int]$AffinityProfile.LogicalProcessorCount, '0')
    $actualHex = [Convert]::ToString($actualAffinity, 16).ToUpperInvariant()

    $checks.Add(
        (New-BoostLabVerificationCheck `
            -Name 'Target process detected' `
            -Expected $TargetDescriptor `
            -Actual $TargetName `
            -Status 'Passed' `
            -Message 'The target process was detected.')
    )
    $checks.Add(
        (New-BoostLabVerificationCheck `
            -Name 'Processor affinity' `
            -Expected ([string]$AffinityProfile.BinaryMask) `
            -Actual $actualBinary `
            -Status $(if ($actualAffinity -eq [int]$AffinityProfile.IntegerMask) { 'Passed' } else { 'Failed' }) `
            -Message $(if ($actualAffinity -eq [int]$AffinityProfile.IntegerMask) { 'The target process affinity matches the expected SMT / HT-off mask.' } else { 'The detected process affinity does not match the expected SMT / HT-off mask.' }))
    )

    $status = if ($actualAffinity -eq [int]$AffinityProfile.IntegerMask) { 'Passed' } else { 'Failed' }

    return New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action $ActionName `
        -Status $status `
        -ExpectedState ([pscustomobject]@{
            Target = $TargetDescriptor
            BinaryMask = [string]$AffinityProfile.BinaryMask
            HexMask = [string]$AffinityProfile.HexMask
            IntegerMask = [int]$AffinityProfile.IntegerMask
        }) `
        -DetectedState ([pscustomobject]@{
            Target = $TargetName
            BinaryMask = $actualBinary
            HexMask = $actualHex
            IntegerMask = $actualAffinity
        }) `
        -Checks $checks.ToArray() `
        -Message $(if ($status -eq 'Passed') {
            'The selected process is running with the expected SMT / HT-off affinity mask.'
        }
        else {
            'The selected process does not match the expected SMT / HT-off affinity mask.'
        })
}

function Invoke-BoostLabSmtHtApplyAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [scriptblock]$AdministratorChecker = { Test-BoostLabAdministrator },
        [scriptblock]$LogicalProcessorReader = { Get-BoostLabLogicalProcessorCount },
        [scriptblock]$CandidateReader = { Get-BoostLabSmtHtCandidateProcesses },
        [scriptblock]$ProcessSelector = {
            param($Candidates)
            Show-BoostLabSmtHtProcessSelectionDialog -Candidates $Candidates
        },
        [scriptblock]$ProcessReaderById = {
            param($ProcessId)
            Get-Process -Id $ProcessId -ErrorAction Stop
        }
    )

    if (-not [bool](& $AdministratorChecker)) {
        return New-BoostLabSmtHtAssistantResult `
            -Success $false `
            -Action 'Apply' `
            -Message 'Administrator rights are required to set processor affinity.'
    }

    $logicalProcessorCount = & $LogicalProcessorReader
    $affinityProfile = Get-BoostLabSmtHtAffinityProfile -LogicalProcessorCount $logicalProcessorCount
    $candidates = @(& $CandidateReader)
    if ($candidates.Count -eq 0) {
        return New-BoostLabSmtHtAssistantResult `
            -Success $false `
            -Action 'Apply' `
            -Message 'No running processes above 500 MB were detected for the Already Running path.' `
            -Data ([pscustomobject]@{
                LogicalProcessorCount = $logicalProcessorCount
                BinaryMask = [string]$affinityProfile.BinaryMask
                HexMask = [string]$affinityProfile.HexMask
                CandidateProcesses = @()
            })
    }

    $selection = & $ProcessSelector $candidates
    if ($null -eq $selection) {
        return New-BoostLabSmtHtAssistantResult `
            -Success $false `
            -Action 'Apply' `
            -Message 'Cancelled by user' `
            -Cancelled $true
    }

    $targetProcess = & $ProcessReaderById ([int]$selection.Id)
    $targetProcess.ProcessorAffinity = [int]$affinityProfile.IntegerMask
    $reloadedProcess = & $ProcessReaderById ([int]$selection.Id)

    $verificationResult = Test-BoostLabSmtHtVerificationResult `
        -ActionName 'Apply' `
        -TargetProcess $reloadedProcess `
        -AffinityProfile $affinityProfile `
        -TargetName ([string]$reloadedProcess.ProcessName) `
        -TargetDescriptor ("ID {0}" -f [int]$selection.Id)

    $data = [pscustomobject]@{
        LogicalProcessorCount = $logicalProcessorCount
        BinaryMask = [string]$affinityProfile.BinaryMask
        HexMask = [string]$affinityProfile.HexMask
        IntegerMask = [int]$affinityProfile.IntegerMask
        TargetProcessName = [string]$reloadedProcess.ProcessName
        TargetProcessId = [int]$reloadedProcess.Id
        CandidateProcessCount = $candidates.Count
        VerificationStatus = [string]$verificationResult.Status
    }

    return New-BoostLabSmtHtAssistantResult `
        -Success ($verificationResult.Status -ne 'Failed') `
        -Action 'Apply' `
        -Message 'Temporary SMT / HT-off affinity was applied to the selected running process.' `
        -Data $data `
        -VerificationResult $verificationResult
}

function Invoke-BoostLabSmtHtOpenAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [scriptblock]$AdministratorChecker = { Test-BoostLabAdministrator },
        [scriptblock]$LogicalProcessorReader = { Get-BoostLabLogicalProcessorCount },
        [scriptblock]$LauncherStopper = {
            param($ProcessName)
            Stop-Process -Name $ProcessName -Force -ErrorAction SilentlyContinue
        },
        [scriptblock]$ExecutableSelector = { Show-BoostLabSmtHtExecutableSelectionDialog },
        [scriptblock]$LauncherInvoker = {
            param($HexMask, $TargetPath)
            $commandProcessorPath = Join-Path $env:SystemRoot 'System32\cmd.exe'
            $commandText = ('start "" /affinity {0} "{1}"' -f $HexMask, $TargetPath)
            & $commandProcessorPath /d /c $commandText | Out-Null
        },
        [scriptblock]$ProcessReaderByName = {
            param($ProcessName)
            Get-Process -Name $ProcessName -ErrorAction Stop
        },
        [scriptblock]$Sleeper = {
            param($Seconds)
            Start-Sleep -Seconds $Seconds
        }
    )

    if (-not [bool](& $AdministratorChecker)) {
        return New-BoostLabSmtHtAssistantResult `
            -Success $false `
            -Action 'Open' `
            -Message 'Administrator rights are required to launch a process with a temporary affinity mask.'
    }

    foreach ($processName in @($script:BoostLabLauncherStopList)) {
        & $LauncherStopper $processName
    }

    $logicalProcessorCount = & $LogicalProcessorReader
    $affinityProfile = Get-BoostLabSmtHtAffinityProfile -LogicalProcessorCount $logicalProcessorCount
    $selectedPath = [string](& $ExecutableSelector)
    if ([string]::IsNullOrWhiteSpace($selectedPath)) {
        return New-BoostLabSmtHtAssistantResult `
            -Success $false `
            -Action 'Open' `
            -Message 'Cancelled by user' `
            -Cancelled $true
    }

    & $LauncherInvoker $affinityProfile.HexMask $selectedPath
    & $Sleeper 10

    $targetProcessName = [System.IO.Path]::GetFileNameWithoutExtension($selectedPath)
    $detectedProcesses = @()
    try {
        $detectedProcesses = @(& $ProcessReaderByName $targetProcessName)
    }
    catch {
        $detectedProcesses = @()
    }

    $detectedProcess = if ($detectedProcesses.Count -gt 0) { $detectedProcesses[0] } else { $null }
    $warnings = [System.Collections.Generic.List[string]]::new()
    if ($detectedProcesses.Count -gt 1) {
        $warnings.Add('Multiple processes matched the launched file name. Verification used the first detected process.')
    }
    if ($null -eq $detectedProcess) {
        $warnings.Add('The launched file did not appear as a process with the same base file name after the source delay window.')
    }

    $verificationResult = Test-BoostLabSmtHtVerificationResult `
        -ActionName 'Open' `
        -TargetProcess $detectedProcess `
        -AffinityProfile $affinityProfile `
        -TargetName $targetProcessName `
        -TargetDescriptor $selectedPath

    $data = [pscustomobject]@{
        LogicalProcessorCount = $logicalProcessorCount
        BinaryMask = [string]$affinityProfile.BinaryMask
        HexMask = [string]$affinityProfile.HexMask
        IntegerMask = [int]$affinityProfile.IntegerMask
        SelectedPath = $selectedPath
        LaunchedProcessName = $targetProcessName
        StoppedLaunchers = @($script:BoostLabLauncherStopList)
        VerificationStatus = [string]$verificationResult.Status
        Warnings = $warnings.ToArray()
    }

    $success = $verificationResult.Status -ne 'Failed'
    $message = if ($verificationResult.Status -eq 'Passed') {
        'Selected launcher or executable started with the expected SMT / HT-off affinity mask.'
    }
    elseif ($verificationResult.Status -eq 'Warning') {
        'Launch command completed, but verification could not conclusively detect the expected process affinity.'
    }
    else {
        'Launch command completed, but the detected process affinity did not match the expected SMT / HT-off mask.'
    }

    return New-BoostLabSmtHtAssistantResult `
        -Success $success `
        -Action 'Open' `
        -Message $message `
        -Data $data `
        -VerificationResult $verificationResult
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
        Capabilities = [pscustomobject]$script:BoostLabToolMetadata['Capabilities']
        ImplementedActions = @($script:BoostLabImplementedActions)
    }
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ActionName,

        [bool]$Confirmed = $false
    )

    if ($ActionName -notin @($script:BoostLabImplementedActions)) {
        return New-BoostLabSmtHtAssistantResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Unsupported action. Only Analyze, Apply, and Open are allowed.'
    }

    switch ($ActionName) {
        'Analyze' {
            return New-BoostLabSmtHtAssistantResult `
                -Success $true `
                -Action 'Analyze' `
                -Message 'CPU topology and SMT / HT assistant guidance analyzed.' `
                -Data (Get-BoostLabSmtHtAnalyzeData)
        }
        'Apply' {
            if (-not $Confirmed) {
                return New-BoostLabSmtHtAssistantResult `
                    -Success $false `
                    -Action 'Apply' `
                    -Message 'Cancelled by user' `
                    -Cancelled $true
            }
            return Invoke-BoostLabSmtHtApplyAction
        }
        'Open' {
            if (-not $Confirmed) {
                return New-BoostLabSmtHtAssistantResult `
                    -Success $false `
                    -Action 'Open' `
                    -Message 'Cancelled by user' `
                    -Cancelled $true
            }
            return Invoke-BoostLabSmtHtOpenAction
        }
    }
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return New-BoostLabSmtHtAssistantResult `
        -Success $false `
        -Action 'Restore' `
        -Message 'Restore is not implemented for SMT / HT Assistant because the approved source does not provide a default or restore path.'
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
)
