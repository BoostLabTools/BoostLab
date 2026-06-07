Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'bios-settings'; Title = 'BIOS Settings'; Stage = 'Check'; Order = 2
    Type = 'assistant'; RiskLevel = 'high'
    Description = 'Review BIOS setting guidance and optionally restart into BIOS/UEFI firmware settings.'
    Actions = @('Analyze', 'Open')
}
$script:BoostLabImplementedActions = @('Analyze', 'Open')
$script:BoostLabFirmwareConfirmationText = 'This PC will restart immediately and attempt to enter BIOS/UEFI firmware settings. Save your work before continuing. Do you want to proceed?'

function New-BoostLabBiosGuidanceSection {
    param(
        [Parameter(Mandatory)]
        [string]$Title,

        [Parameter(Mandatory)]
        [string[]]$Instructions
    )

    return [pscustomobject]@{
        Title        = $Title
        Instructions = @($Instructions)
    }
}

function Get-BoostLabBiosSettingsGuidance {
    $sections = @(
        (New-BoostLabBiosGuidanceSection `
            -Title 'INTEL CPU' `
            -Instructions @(
                'ENABLE ram profile (XMP DOCP EXPO)'
                'DISABLE c-states (K CHIPS ONLY)'
                'ENABLE resizable bar (REBAR C.A.M)'
                'DISABLE i-gpu'
            ))
        (New-BoostLabBiosGuidanceSection `
            -Title 'AMD CPU' `
            -Instructions @(
                'ENABLE ram profile (XMP DOCP EXPO)'
                'ENABLE precision boost overdrive (PBO)'
                'ENABLE resizable bar (REBAR C.A.M)'
                'DISABLE iommu (NEEDED FOR FACEIT)'
                'DISABLE i-gpu'
            ))
        (New-BoostLabBiosGuidanceSection `
            -Title 'COOLING' `
            -Instructions @(
                'MAX pump and set fans to performance'
            ))
        (New-BoostLabBiosGuidanceSection `
            -Title 'MOTHERBOARD DRIVER INSTALLERS' `
            -Instructions @(
                'DISABLE any driver installer software'
                'Asus armory crate'
                'MSI driver utility'
                'Gigabyte update utility'
                'Asrock motherboard utility'
            ))
    )

    $guidanceLines = [System.Collections.Generic.List[string]]::new()
    foreach ($section in $sections) {
        $guidanceLines.Add([string]$section.Title)
        foreach ($instruction in @($section.Instructions)) {
            $guidanceLines.Add("- $instruction")
        }
    }

    return [pscustomobject]@{
        Guidance          = $sections
        GuidanceLines     = $guidanceLines.ToArray()
        GuidanceLineCount = $guidanceLines.Count
        Warnings          = @(
            'BIOS menus and setting names differ by motherboard vendor, model, and firmware version.'
            'Do not change settings you do not understand.'
            'Document current BIOS settings before making changes.'
            'The Open action restarts the PC immediately and attempts to enter BIOS/UEFI firmware settings.'
        )
        SourceBehavior    = 'Ultimate BIOS Settings guidance'
        Timestamp         = Get-Date
    }
}

function New-BoostLabBiosSettingsResult {
    param(
        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [string]$Message,

        [bool]$RestartRequired = $false,

        [bool]$Cancelled = $false,

        [AllowNull()]
        [object]$Data = $null
    )

    return [pscustomobject]@{
        Success         = $Success
        ToolId          = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
        Action          = $Action
        Message         = $Message
        RestartRequired = $RestartRequired
        Cancelled       = $Cancelled
        Timestamp       = Get-Date
        Data            = $Data
    }
}

function Get-BoostLabToolInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        Id                          = [string]$script:BoostLabToolMetadata['Id']
        Title                       = [string]$script:BoostLabToolMetadata['Title']
        Stage                       = [string]$script:BoostLabToolMetadata['Stage']
        Order                       = [int]$script:BoostLabToolMetadata['Order']
        Type                        = [string]$script:BoostLabToolMetadata['Type']
        RiskLevel                   = [string]$script:BoostLabToolMetadata['RiskLevel']
        Description                 = [string]$script:BoostLabToolMetadata['Description']
        Actions                     = @($script:BoostLabToolMetadata['Actions'])
        ImplementedActions          = @($script:BoostLabImplementedActions)
        ConfirmationRequiredActions = @('Open')
        ConfirmationText            = $script:BoostLabFirmwareConfirmationText
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        Supported = $true
        ToolId    = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason    = 'BIOS guidance is available. Firmware restart support is checked when Open is confirmed.'
        Timestamp = Get-Date
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        ToolId          = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
        Status          = 'Ready'
        LastAction      = $null
        LastResult      = $null
        RestartRequired = $false
        Timestamp       = Get-Date
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
        return New-BoostLabBiosSettingsResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Unsupported action. Only Analyze and Open are allowed.'
    }

    if ($ActionName -eq 'Analyze') {
        return New-BoostLabBiosSettingsResult `
            -Success $true `
            -Action 'Analyze' `
            -Message 'Guidance prepared' `
            -Data (Get-BoostLabBiosSettingsGuidance)
    }

    if (-not $Confirmed) {
        return New-BoostLabBiosSettingsResult `
            -Success $false `
            -Action 'Open' `
            -Message 'Cancelled by user' `
            -Cancelled $true
    }

    if ([string]::IsNullOrWhiteSpace($env:SystemRoot)) {
        return New-BoostLabBiosSettingsResult `
            -Success $false `
            -Action 'Open' `
            -Message 'Cannot enter BIOS/UEFI because the Windows system directory is unavailable.'
    }

    $commandProcessorPath = Join-Path $env:SystemRoot 'System32\cmd.exe'
    $shutdownPath = Join-Path $env:SystemRoot 'System32\shutdown.exe'
    if (
        -not (Test-Path -LiteralPath $commandProcessorPath -PathType Leaf) -or
        -not (Test-Path -LiteralPath $shutdownPath -PathType Leaf)
    ) {
        return New-BoostLabBiosSettingsResult `
            -Success $false `
            -Action 'Open' `
            -Message 'Cannot enter BIOS/UEFI because the required Windows system command was not found.'
    }

    $firmwareRestartCommand = "`"$shutdownPath`" /r /fw /t 0"
    $firmwareRestartArguments = @('/c', $firmwareRestartCommand)
    try {
        & $commandProcessorPath @firmwareRestartArguments
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            return New-BoostLabBiosSettingsResult `
                -Success $false `
                -Action 'Open' `
                -Message "Windows could not schedule a restart to BIOS/UEFI. shutdown.exe returned exit code $exitCode."
        }

        return New-BoostLabBiosSettingsResult `
            -Success $true `
            -Action 'Open' `
            -Message 'Restart to BIOS/UEFI requested' `
            -RestartRequired $true `
            -Data ([pscustomobject]@{
                Executable = $commandProcessorPath
                Arguments  = @($firmwareRestartArguments)
            })
    }
    catch {
        return New-BoostLabBiosSettingsResult `
            -Success $false `
            -Action 'Open' `
            -Message "Windows could not schedule a restart to BIOS/UEFI: $($_.Exception.Message)"
    }
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return New-BoostLabBiosSettingsResult `
        -Success $false `
        -Action 'Default' `
        -Message 'Action is not declared for this tool.'
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
)
