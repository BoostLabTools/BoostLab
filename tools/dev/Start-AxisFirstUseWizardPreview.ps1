[CmdletBinding()]
param(
    [switch]$BuildOnly,

    [Alias('ValidateOnly')]
    [switch]$NoShow,

    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-AxisFirstUseWizardPreviewProjectRoot {
    [CmdletBinding()]
    param(
        [string]$ProjectRoot
    )

    if (-not [string]::IsNullOrWhiteSpace($ProjectRoot)) {
        return (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
    }

    $toolsRoot = Split-Path -Parent $PSScriptRoot
    return (Split-Path -Parent $toolsRoot)
}

function Assert-AxisFirstUseWizardPreviewStaThread {
    [CmdletBinding()]
    param()

    $apartmentState = [System.Threading.Thread]::CurrentThread.GetApartmentState()
    if ($apartmentState -ne [System.Threading.ApartmentState]::STA) {
        throw 'AXIS first-use wizard preview requires an STA PowerShell session. Run: powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\tools\dev\Start-AxisFirstUseWizardPreview.ps1'
    }
}

function Import-AxisFirstUseWizardPreviewModules {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot
    )

    $resourcePath = Join-Path $ProjectRoot 'ui\AxisResources.ps1'
    $prototypePath = Join-Path $ProjectRoot 'ui\AxisFirstUseWizardPrototype.ps1'

    if (-not (Test-Path -LiteralPath $resourcePath -PathType Leaf)) {
        throw "AXIS resource file was not found: $resourcePath"
    }
    if (-not (Test-Path -LiteralPath $prototypePath -PathType Leaf)) {
        throw "AXIS first-use wizard prototype file was not found: $prototypePath"
    }

    [pscustomobject]@{
        ResourcePath = $resourcePath
        PrototypePath = $prototypePath
    }
}

function Invoke-AxisFirstUseWizardPreview {
    [CmdletBinding()]
    param(
        [switch]$BuildOnly,

        [Alias('ValidateOnly')]
        [switch]$NoShow,

        [string]$ProjectRoot
    )

    if ($NoShow) {
        $BuildOnly = $true
    }

    Assert-AxisFirstUseWizardPreviewStaThread
    $resolvedProjectRoot = Resolve-AxisFirstUseWizardPreviewProjectRoot -ProjectRoot $ProjectRoot
    $imports = Import-AxisFirstUseWizardPreviewModules -ProjectRoot $resolvedProjectRoot

    . $imports.ResourcePath
    . $imports.PrototypePath

    [void](New-AxisWpfResourceDictionary)
    $window = New-AxisFirstUseWizardPrototypeWindow
    $content = $window.Content
    $usesAxisResources = (
        $content -is [System.Windows.FrameworkElement] -and
        $content.Resources.Contains('Axis.Brush.Background.App') -and
        $content.Resources.Contains('Axis.Status.Completed.Brush')
    )

    if ($BuildOnly) {
        return [pscustomobject]@{
            Preview = 'AxisFirstUseWizard'
            Mode = $(if ($NoShow) { 'NoShow' } else { 'BuildOnly' })
            WindowCreated = $true
            WindowShown = $false
            WindowTitle = $window.Title
            WindowWidth = [double]$window.Width
            WindowHeight = [double]$window.Height
            WindowStyle = [string]$window.WindowStyle
            ResizeMode = [string]$window.ResizeMode
            CustomChrome = ($window.WindowStyle -eq [System.Windows.WindowStyle]::None)
            DefaultTitlebarVisible = ($window.WindowStyle -ne [System.Windows.WindowStyle]::None)
            ContentType = $content.GetType().FullName
            UsesAxisResources = [bool]$usesAxisResources
            ResourcePath = $imports.ResourcePath
            PrototypePath = $imports.PrototypePath
            RuntimeActionsStarted = $false
            HostMutated = $false
        }
    }

    Write-Host 'AXIS first-use wizard static preview. Buttons are visual only and no setup tools run from this window.'
    [void]$window.ShowDialog()

    return [pscustomobject]@{
        Preview = 'AxisFirstUseWizard'
        Mode = 'Shown'
        WindowCreated = $true
        WindowShown = $true
        WindowTitle = $window.Title
        WindowWidth = [double]$window.Width
        WindowHeight = [double]$window.Height
        WindowStyle = [string]$window.WindowStyle
        ResizeMode = [string]$window.ResizeMode
        CustomChrome = ($window.WindowStyle -eq [System.Windows.WindowStyle]::None)
        DefaultTitlebarVisible = ($window.WindowStyle -ne [System.Windows.WindowStyle]::None)
        ContentType = $content.GetType().FullName
        UsesAxisResources = [bool]$usesAxisResources
        ResourcePath = $imports.ResourcePath
        PrototypePath = $imports.PrototypePath
        RuntimeActionsStarted = $false
        HostMutated = $false
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-AxisFirstUseWizardPreview `
        -BuildOnly:$BuildOnly `
        -NoShow:$NoShow `
        -ProjectRoot $ProjectRoot
}
