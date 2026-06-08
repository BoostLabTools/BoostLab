Set-StrictMode -Version Latest

$script:BoostLabCapabilityFields = @(
    'RequiresAdmin'
    'RequiresInternet'
    'CanReboot'
    'CanModifyRegistry'
    'CanModifyServices'
    'CanInstallSoftware'
    'CanDownload'
    'CanModifyDrivers'
    'CanModifySecurity'
    'CanDeleteFiles'
    'UsesTrustedInstaller'
    'UsesSafeMode'
    'SupportsDefault'
    'SupportsRestore'
    'NeedsExplicitConfirmation'
)

function ConvertTo-BoostLabCapabilityObject {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Capabilities
    )

    $normalized = [ordered]@{}
    foreach ($field in $script:BoostLabCapabilityFields) {
        $normalized[$field] = if ($Capabilities.Contains($field)) {
            [bool]$Capabilities[$field]
        }
        else {
            $false
        }
    }

    return [pscustomobject]$normalized
}

function Test-BoostLabPlanNeedsConfirmation {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('low', 'medium', 'high')]
        [string]$RiskLevel,

        [Parameter(Mandatory)]
        [pscustomobject]$Capabilities,

        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default', 'Open', 'Analyze', 'Restore')]
        [string]$ActionName
    )

    if ($RiskLevel -eq 'high') {
        return $true
    }
    if ($ActionName -eq 'Analyze') {
        return $false
    }
    if ($ActionName -eq 'Open') {
        return [bool]$Capabilities.CanReboot
    }

    return (
        $Capabilities.NeedsExplicitConfirmation -or
        $Capabilities.CanReboot -or
        $Capabilities.CanModifyServices -or
        $Capabilities.CanInstallSoftware -or
        $Capabilities.CanDownload -or
        $Capabilities.CanModifyDrivers -or
        $Capabilities.CanModifySecurity -or
        $Capabilities.CanDeleteFiles -or
        $Capabilities.UsesTrustedInstaller -or
        $Capabilities.UsesSafeMode
    )
}

function New-BoostLabActionPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$ToolMetadata,

        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default', 'Open', 'Analyze', 'Restore')]
        [string]$ActionName,

        [bool]$IsDryRun = $true
    )

    foreach ($field in @('Id', 'Title', 'RiskLevel', 'Actions', 'Capabilities')) {
        if (-not $ToolMetadata.Contains($field)) {
            throw "Cannot build an action plan because metadata field '$field' is missing."
        }
    }
    if ($ActionName -notin @($ToolMetadata['Actions'])) {
        throw "Cannot build an action plan for undeclared action '$ActionName'."
    }
    if ($ToolMetadata['Capabilities'] -isnot [System.Collections.IDictionary]) {
        throw 'Cannot build an action plan because Capabilities is not a dictionary.'
    }

    $toolId = [string]$ToolMetadata['Id']
    $toolTitle = [string]$ToolMetadata['Title']
    $riskLevel = ([string]$ToolMetadata['RiskLevel']).ToLowerInvariant()
    if ($riskLevel -notin @('low', 'medium', 'high')) {
        throw "Cannot build an action plan for unsupported risk level '$riskLevel'."
    }

    $capabilities = ConvertTo-BoostLabCapabilityObject -Capabilities $ToolMetadata['Capabilities']
    $needsConfirmation = Test-BoostLabPlanNeedsConfirmation `
        -RiskLevel $riskLevel `
        -Capabilities $capabilities `
        -ActionName $ActionName

    $summary = if ($toolId -eq 'restore-point' -and $ActionName -eq 'Apply') {
        'Enable System Restore if needed and create the approved backup restore point.'
    }
    elseif ($toolId -eq 'restore-point' -and $ActionName -eq 'Open') {
        'Open Windows System Protection and System Restore.'
    }
    elseif ($toolId -eq 'widgets' -and $ActionName -eq 'Apply') {
        'Disable Windows Widgets and remove Widgets from the taskbar using the approved policies.'
    }
    elseif ($toolId -eq 'widgets' -and $ActionName -eq 'Default') {
        'Restore the approved default Windows Widgets policy behavior.'
    }
    elseif ($toolId -eq 'memory-compression' -and $ActionName -eq 'Apply') {
        'Disable Windows Memory Compression using the approved Ultimate recommendation.'
    }
    elseif ($toolId -eq 'memory-compression' -and $ActionName -eq 'Default') {
        'Restore the approved default enabled Memory Compression state.'
    }
    else {
        switch ($ActionName) {
        'Analyze' { "Analyze $toolTitle without applying changes." }
        'Open' {
            if ($capabilities.CanReboot) {
                "Open the approved $toolTitle workflow, which can restart the computer."
            }
            else {
                "Open the approved Windows interface or resource for $toolTitle."
            }
        }
        'Apply' { "Apply the approved $toolTitle behavior." }
        'Default' { "Return $toolTitle to its approved default behavior." }
        'Restore' { "Restore $toolTitle from a previous state captured by BoostLab." }
        }
    }

    $plannedChanges = [System.Collections.Generic.List[string]]::new()
    if ($toolId -eq 'restore-point' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Temporarily set SystemRestorePointCreationFrequency to 0.')
        $plannedChanges.Add('Enable System Restore on C:\ if it is disabled.')
        $plannedChanges.Add('Create a restore point named backup with type MODIFY_SETTINGS.')
        $plannedChanges.Add('Remove the temporary restore-point frequency override.')
    }
    elseif ($toolId -eq 'restore-point' -and $ActionName -eq 'Open') {
        $plannedChanges.Add('Open the System Protection page.')
        $plannedChanges.Add('Open the Windows System Restore interface.')
    }
    elseif ($toolId -eq 'widgets' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Set PolicyManager AllowNewsAndInterests value to 0.')
        $plannedChanges.Add('Set the Dsh AllowNewsAndInterests policy value to 0.')
        $plannedChanges.Add('Stop Widgets and WidgetService if they are running.')
    }
    elseif ($toolId -eq 'widgets' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Set PolicyManager AllowNewsAndInterests value to 1.')
        $plannedChanges.Add('Remove the Dsh policy key used to block Widgets.')
    }
    elseif ($toolId -eq 'memory-compression' -and $ActionName -eq 'Apply') {
        $plannedChanges.Add('Run Disable-MMAgent -MemoryCompression.')
        $plannedChanges.Add('Read the resulting MemoryCompression state with Get-MMAgent.')
    }
    elseif ($toolId -eq 'memory-compression' -and $ActionName -eq 'Default') {
        $plannedChanges.Add('Run Enable-MMAgent -MemoryCompression.')
        $plannedChanges.Add('Read the resulting MemoryCompression state with Get-MMAgent.')
    }
    else {
        switch ($ActionName) {
        'Analyze' {
            $plannedChanges.Add('Collect and report read-only information defined by the approved tool.')
        }
        'Open' {
            $plannedChanges.Add('Open only the approved interface or workflow declared by the tool.')
        }
        'Apply' {
            $plannedChanges.Add('Apply the approved operational behavior documented for this tool.')
        }
        'Default' {
            $plannedChanges.Add('Apply the tool-specific approved default behavior.')
        }
        'Restore' {
            $plannedChanges.Add('Use a previous state captured by BoostLab; do not infer or invent restore data.')
        }
        }
    }

    $isPotentialChangeAction = $ActionName -in @('Apply', 'Default', 'Restore')
    if ($isPotentialChangeAction) {
        $capabilityChanges = [ordered]@{
            CanModifyRegistry = 'Modify approved Windows registry values.'
            CanModifyServices = 'Modify approved Windows service configuration or state.'
            CanInstallSoftware = 'Install or repair approved software.'
            CanDownload = 'Download approved external content.'
            CanModifyDrivers = 'Modify approved driver configuration or installation.'
            CanModifySecurity = 'Modify approved Windows security configuration.'
            CanDeleteFiles = 'Delete files within the approved tool scope.'
            UsesTrustedInstaller = 'Use an approved TrustedInstaller execution flow.'
            UsesSafeMode = 'Use an approved Safe Mode workflow.'
        }
        foreach ($field in $capabilityChanges.Keys) {
            if ([bool]$capabilities.$field) {
                $plannedChanges.Add([string]$capabilityChanges[$field])
            }
        }
    }
    if ($capabilities.CanReboot -and $ActionName -ne 'Analyze') {
        $plannedChanges.Add('Request or perform an approved restart when required by the workflow.')
    }

    $sideEffects = [System.Collections.Generic.List[string]]::new()
    if ($toolId -eq 'restore-point' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('System Restore may be enabled on C:\ and remains enabled after the action.')
        $sideEffects.Add('The new restore point consumes space allocated to System Protection.')
        $sideEffects.Add('A temporary registry value is created and removed during the operation.')
    }
    elseif ($toolId -eq 'widgets' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Widgets and News and Interests are disabled by machine policy.')
        $sideEffects.Add('Running Widgets and WidgetService processes are closed.')
        $sideEffects.Add('The taskbar may update immediately or after Windows refreshes its policy state.')
    }
    elseif ($toolId -eq 'widgets' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Widgets availability returns to the approved Windows default policy behavior.')
        $sideEffects.Add('The taskbar may update after Windows refreshes its policy state.')
    }
    elseif ($toolId -eq 'memory-compression' -and $ActionName -eq 'Apply') {
        $sideEffects.Add('Windows will stop using memory compression until it is enabled again.')
        $sideEffects.Add('The setting is changed immediately; BoostLab does not restart the computer.')
    }
    elseif ($toolId -eq 'memory-compression' -and $ActionName -eq 'Default') {
        $sideEffects.Add('Windows will be allowed to use memory compression again.')
        $sideEffects.Add('The setting is changed immediately; BoostLab does not restart the computer.')
    }
    if ($ActionName -eq 'Analyze') {
        $sideEffects.Add('Read-only system information may be collected and displayed.')
    }
    elseif ($ActionName -eq 'Open' -and -not $capabilities.CanReboot) {
        $sideEffects.Add('A Windows interface or approved external resource may be opened.')
    }
    if ($capabilities.RequiresInternet) {
        $sideEffects.Add('The requested action may fail when internet access is unavailable.')
    }
    if ($capabilities.CanReboot -and $ActionName -ne 'Analyze') {
        $sideEffects.Add('The computer may restart; unsaved work could be lost.')
    }
    if ($isPotentialChangeAction -and $capabilities.CanModifyServices) {
        $sideEffects.Add('Service changes may affect dependent Windows or application features.')
    }
    if ($isPotentialChangeAction -and $capabilities.CanModifyDrivers) {
        $sideEffects.Add('Driver changes may affect display, devices, stability, or hardware availability.')
    }
    if ($isPotentialChangeAction -and $capabilities.CanModifySecurity) {
        $sideEffects.Add('Security changes may alter system protection or compatibility.')
    }
    if ($isPotentialChangeAction -and $capabilities.CanDeleteFiles) {
        $sideEffects.Add('Deleted files may not be recoverable unless an approved checkpoint exists.')
    }
    if ($isPotentialChangeAction -and $capabilities.CanInstallSoftware) {
        $sideEffects.Add('Installed software may add files, services, tasks, or application settings.')
    }
    if ($isPotentialChangeAction -and $capabilities.UsesTrustedInstaller) {
        $sideEffects.Add('TrustedInstaller execution has elevated system impact and requires explicit review.')
    }
    if ($isPotentialChangeAction -and $capabilities.UsesSafeMode) {
        $sideEffects.Add('Safe Mode changes the next startup flow and requires a documented recovery path.')
    }
    if ($sideEffects.Count -eq 0) {
        $sideEffects.Add('No system-changing side effects are declared for this action.')
    }

    $confirmationMessage = if ($toolId -eq 'bios-settings' -and $ActionName -eq 'Open') {
        'This PC will restart immediately and attempt to enter BIOS/UEFI firmware settings. Save your work before continuing. Do you want to proceed?'
    }
    elseif ($toolId -eq 'restore-point' -and $ActionName -eq 'Apply') {
        'BoostLab will enable System Restore on C:\ if needed and create a restore point named backup. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'widgets' -and $ActionName -eq 'Apply') {
        'BoostLab will disable Widgets by machine policy and close Widgets processes if they are running. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'widgets' -and $ActionName -eq 'Default') {
        'BoostLab will restore the approved default Widgets policy values. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'memory-compression' -and $ActionName -eq 'Apply') {
        'BoostLab will run Disable-MMAgent -MemoryCompression and verify the result. No restart is required. Do you want to continue?'
    }
    elseif ($toolId -eq 'memory-compression' -and $ActionName -eq 'Default') {
        'BoostLab will run Enable-MMAgent -MemoryCompression and verify the result. No restart is required. Do you want to continue?'
    }
    elseif ($needsConfirmation) {
        "Review the action plan for $toolTitle. Confirm only if you understand the planned changes and side effects."
    }
    else {
        'No explicit confirmation is required for this action.'
    }

    return [pscustomobject]@{
        ToolId                    = $toolId
        ToolTitle                 = $toolTitle
        Action                    = $ActionName
        RiskLevel                 = $riskLevel
        Capabilities              = $capabilities
        Summary                   = $summary
        PlannedChanges            = $plannedChanges.ToArray()
        SideEffects               = $sideEffects.ToArray()
        RequiresAdmin             = [bool]$capabilities.RequiresAdmin
        RequiresInternet          = [bool]$capabilities.RequiresInternet
        CanReboot                 = [bool]$capabilities.CanReboot
        NeedsExplicitConfirmation = [bool]$needsConfirmation
        SupportsDefault           = [bool]$capabilities.SupportsDefault
        SupportsRestore           = [bool]$capabilities.SupportsRestore
        ConfirmationMessage       = $confirmationMessage
        IsDryRun                  = $IsDryRun
        Timestamp                 = Get-Date
    }
}

Export-ModuleMember -Function @(
    'ConvertTo-BoostLabCapabilityObject'
    'Test-BoostLabPlanNeedsConfirmation'
    'New-BoostLabActionPlan'
)
