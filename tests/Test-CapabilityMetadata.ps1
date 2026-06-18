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
        throw 'Unable to determine the capability metadata test script path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'
$requiredCapabilityFields = @(
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
$deletedToolNames = @(
    'Windows Activation Helper'
    'Firewall'
    'DEP'
    'File Download Security Warning'
    'MPO'
    'FSO'
    'FSE'
    'Hardware Flip'
    'AMD ULPS'
    'WHQL Secure Boot Bypass'
    'Keyboard Shortcuts'
    'Search Shell Mobsync'
    'NVME Faster Driver'
    'Core 1 Thread 1'
    'DDU'
    'UAC'
    'Scaling'
    'Start Menu Shortcuts'
    'Loudness EQ'
)

if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    throw "Stage configuration was not found: $configPath"
}
if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) {
    throw "Legacy source directory was not found: $sourceRoot"
}

$configuration = Import-PowerShellDataFile -LiteralPath $configPath
$stages = @($configuration['Stages'] | Sort-Object { [int]$_['Order'] })
$expectedStageOrder = @('Check', 'Refresh', 'Setup', 'Installers', 'Graphics', 'Windows', 'Advanced')
if (($stages.Name -join '|') -ne ($expectedStageOrder -join '|')) {
    throw 'Approved stage order changed.'
}

$tools = @($stages | ForEach-Object { $_['Tools'] })
$errors = [System.Collections.Generic.List[string]]::new()
$highRiskCount = 0
$rebootCount = 0

foreach ($tool in $tools) {
    $toolName = [string]$tool['Title']
    if (-not $tool.ContainsKey('Capabilities')) {
        $errors.Add("$toolName is missing Capabilities metadata.")
        continue
    }

    $capabilities = $tool['Capabilities']
    if ($capabilities -isnot [System.Collections.IDictionary]) {
        $errors.Add("$toolName Capabilities metadata is not a dictionary.")
        continue
    }

    foreach ($field in $requiredCapabilityFields) {
        if (-not $capabilities.Contains($field)) {
            $errors.Add("$toolName is missing capability: $field")
        }
        elseif ($capabilities[$field] -isnot [bool]) {
            $errors.Add("$toolName capability '$field' is not Boolean.")
        }
    }

    if ([string]$tool['RiskLevel'] -eq 'high') {
        $highRiskCount++
        if (-not [bool]$capabilities['NeedsExplicitConfirmation']) {
            $errors.Add("$toolName is high risk but does not require explicit confirmation.")
        }
    }
    if ([bool]$capabilities['CanReboot']) {
        $rebootCount++
        if (-not [bool]$capabilities['NeedsExplicitConfirmation']) {
            $errors.Add("$toolName can reboot but does not require explicit confirmation.")
        }
    }
    if (
        [bool]$capabilities['UsesTrustedInstaller'] -and
        -not [bool]$capabilities['NeedsExplicitConfirmation']
    ) {
        $errors.Add("$toolName uses TrustedInstaller but does not require explicit confirmation.")
    }
    if (
        [bool]$capabilities['UsesSafeMode'] -and
        -not [bool]$capabilities['NeedsExplicitConfirmation']
    ) {
        $errors.Add("$toolName uses Safe Mode but does not require explicit confirmation.")
    }
    $hasDefaultAction = 'Default' -in @($tool['Actions'])
    $defaultActionIsBlockedUntilApprovedContract = (
        [string]$tool['Id'] -eq 'bitlocker' -and
        $hasDefaultAction -and
        -not [bool]$capabilities['SupportsDefault']
    )
    if ([bool]$capabilities['SupportsDefault'] -ne $hasDefaultAction -and -not $defaultActionIsBlockedUntilApprovedContract) {
        $errors.Add("$toolName SupportsDefault does not match its action list.")
    }
    $hasRestoreAction = 'Restore' -in @($tool['Actions'])
    $restoreActionIsBlockedUntilSelectedState = (
        [string]$tool['Id'] -in @('hdcp', 'p0-state', 'msi-mode', 'bitlocker') -and
        $hasRestoreAction -and
        -not [bool]$capabilities['SupportsRestore']
    )
    if ([bool]$capabilities['SupportsRestore'] -ne $hasRestoreAction -and -not $restoreActionIsBlockedUntilSelectedState) {
        $errors.Add("$toolName SupportsRestore does not match its action list.")
    }
}

function ConvertTo-NormalizedToolName {
    param([Parameter(Mandatory)][string]$Name)

    return ($Name -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()
}

$approvedNames = @(
    $tools | ForEach-Object {
        ConvertTo-NormalizedToolName -Name ([string]$_['Title'])
        ConvertTo-NormalizedToolName -Name ([string]$_['Id'])
    }
)
foreach ($deletedName in $deletedToolNames) {
    if ((ConvertTo-NormalizedToolName -Name $deletedName) -in $approvedNames) {
        $errors.Add("Deleted tool is present in the catalog: $deletedName")
    }
}

$sourceFiles = @(
    Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
        Sort-Object {
            $_.FullName.Substring($ProjectRoot.Length + 1).Replace('\', '/')
        }
)
$sourceManifestLines = @(
    $sourceFiles | ForEach-Object {
        $relativePath = $_.FullName.Substring($ProjectRoot.Length + 1).Replace('\', '/')
        $fileHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
        '{0}|{1}' -f $relativePath, $fileHash
    }
)
$manifestText = $sourceManifestLines -join "`n"
$sha256 = [System.Security.Cryptography.SHA256]::Create()
try {
    $manifestHash = [BitConverter]::ToString(
        $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($manifestText))
    ).Replace('-', '')
}
finally {
    $sha256.Dispose()
}

$expectedSourceFileCount = 49
$expectedSourceManifestHash = '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477'
if ($sourceFiles.Count -ne $expectedSourceFileCount) {
    $errors.Add("source-ultimate file count changed: expected $expectedSourceFileCount, found $($sourceFiles.Count).")
}
if ($manifestHash -ne $expectedSourceManifestHash) {
    $errors.Add('source-ultimate content or paths changed.')
}

if ($errors.Count -gt 0) {
    throw "Capability metadata validation failed:`r`n- $($errors -join "`r`n- ")"
}

[pscustomobject]@{
    Success                   = $true
    ToolCount                 = $tools.Count
    CapabilityFieldCount      = $requiredCapabilityFields.Count
    HighRiskToolCount         = $highRiskCount
    RebootCapableToolCount    = $rebootCount
    DeletedToolCount          = 0
    SourceUltimateFileCount   = $sourceFiles.Count
    SourceUltimateHashValid   = $true
    Message                   = 'Capability metadata and legacy source integrity are valid.'
    Timestamp                 = Get-Date
}

