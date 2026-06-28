[CmdletBinding()]
param(
    [switch]$BuildOnly,

    [Alias('ValidateOnly')]
    [switch]$NoShow,

    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-AxisPrototypePreviewProjectRoot {
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

function Assert-AxisPrototypePreviewStaThread {
    [CmdletBinding()]
    param()

    $apartmentState = [System.Threading.Thread]::CurrentThread.GetApartmentState()
    if ($apartmentState -ne [System.Threading.ApartmentState]::STA) {
        throw 'AXIS prototype preview requires an STA PowerShell session. Run: powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\tools\dev\Start-AxisPrototypePreview.ps1'
    }
}

function Import-AxisPrototypePreviewModules {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot
    )

    $resourcePath = Join-Path $ProjectRoot 'ui\AxisResources.ps1'
    $prototypePath = Join-Path $ProjectRoot 'ui\AxisGuidedStageWorkspacePrototype.ps1'

    if (-not (Test-Path -LiteralPath $resourcePath -PathType Leaf)) {
        throw "AXIS resource file was not found: $resourcePath"
    }
    if (-not (Test-Path -LiteralPath $prototypePath -PathType Leaf)) {
        throw "AXIS prototype file was not found: $prototypePath"
    }

    [pscustomobject]@{
        ResourcePath = $resourcePath
        PrototypePath = $prototypePath
    }
}

function Invoke-AxisPrototypePreview {
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

    Assert-AxisPrototypePreviewStaThread
    $resolvedProjectRoot = Resolve-AxisPrototypePreviewProjectRoot -ProjectRoot $ProjectRoot
    $imports = Import-AxisPrototypePreviewModules -ProjectRoot $resolvedProjectRoot

    . $imports.ResourcePath
    . $imports.PrototypePath

    [void](New-AxisWpfResourceDictionary)
    $window = New-AxisGuidedStageWorkspacePrototypeWindow
    $content = $window.Content
    $usesAxisResources = (
        $content -is [System.Windows.FrameworkElement] -and
        $content.Resources.Contains('Axis.Brush.Background.App') -and
        $content.Resources.Contains('Axis.Status.Completed.Brush')
    )

    if ($BuildOnly) {
        return [pscustomobject]@{
            Preview = 'AxisGuidedStageWorkspace'
            Mode = $(if ($NoShow) { 'NoShow' } else { 'BuildOnly' })
            WindowCreated = $true
            WindowShown = $false
            WindowTitle = $window.Title
            ContentType = $content.GetType().FullName
            UsesAxisResources = [bool]$usesAxisResources
            ResourcePath = $imports.ResourcePath
            PrototypePath = $imports.PrototypePath
            RuntimeActionsStarted = $false
            HostMutated = $false
        }
    }

    Write-Host 'AXIS static prototype preview. No setup tools are connected or run from this window.'
    [void]$window.ShowDialog()

    return [pscustomobject]@{
        Preview = 'AxisGuidedStageWorkspace'
        Mode = 'Shown'
        WindowCreated = $true
        WindowShown = $true
        WindowTitle = $window.Title
        ContentType = $content.GetType().FullName
        UsesAxisResources = [bool]$usesAxisResources
        ResourcePath = $imports.ResourcePath
        PrototypePath = $imports.PrototypePath
        RuntimeActionsStarted = $false
        HostMutated = $false
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-AxisPrototypePreview `
        -BuildOnly:$BuildOnly `
        -NoShow:$NoShow `
        -ProjectRoot $ProjectRoot
}
