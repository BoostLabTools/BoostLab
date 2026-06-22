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
        throw 'Unable to determine the source checksum packaging robustness validator path.'
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

$sourceVerificationPath = Join-Path $ProjectRoot 'core\SourceVerification.psm1'
$reinstallModulePath = Join-Path $ProjectRoot 'modules\Refresh\reinstall.psm1'
$reinstallSourcePath = Join-Path $ProjectRoot 'source-ultimate\2 Refresh\1 Reinstall.ps1'
foreach ($path in @($sourceVerificationPath, $reinstallModulePath, $reinstallSourcePath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required checksum robustness file missing: $path"
}

Import-Module -Name $sourceVerificationPath -Force -ErrorAction Stop

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('BoostLabSourceChecksum-' + [guid]::NewGuid().ToString('N'))
New-Item -Path $tempRoot -ItemType Directory -Force | Out-Null
try {
    $utf8NoBom = [Text.UTF8Encoding]::new($false)
    $contentLf = "Write-Host 'BoostLab source check'`n`$value = 1`n"
    $contentCrlf = $contentLf -replace "`n", "`r`n"
    $contentMutated = $contentLf + "Write-Host 'mutated'`n"

    $crlfPath = Join-Path $tempRoot 'Source-Crlf.ps1'
    $lfPath = Join-Path $tempRoot 'Source-Lf.ps1'
    $bomPath = Join-Path $tempRoot 'Source-Bom.ps1'
    $mutatedPath = Join-Path $tempRoot 'Source-Mutated.ps1'

    [IO.File]::WriteAllBytes($crlfPath, $utf8NoBom.GetBytes($contentCrlf))
    [IO.File]::WriteAllBytes($lfPath, $utf8NoBom.GetBytes($contentLf))
    [IO.File]::WriteAllBytes($bomPath, ([byte[]]@(0xEF, 0xBB, 0xBF) + $utf8NoBom.GetBytes($contentLf)))
    [IO.File]::WriteAllBytes($mutatedPath, $utf8NoBom.GetBytes($contentMutated))

    $expectedRaw = (Get-FileHash -LiteralPath $crlfPath -Algorithm SHA256).Hash
    $expectedCanonical = Get-BoostLabSha256Hex -Bytes (ConvertTo-BoostLabCanonicalSourceTextBytes -Bytes ([IO.File]::ReadAllBytes($crlfPath)))

    $crlfStatus = Test-BoostLabSourceChecksum -LiteralPath $crlfPath -ExpectedSha256 $expectedRaw -ExpectedCanonicalSha256 $expectedCanonical
    $lfStatus = Test-BoostLabSourceChecksum -LiteralPath $lfPath -ExpectedSha256 $expectedRaw -ExpectedCanonicalSha256 $expectedCanonical
    $bomStatus = Test-BoostLabSourceChecksum -LiteralPath $bomPath -ExpectedSha256 $expectedRaw -ExpectedCanonicalSha256 $expectedCanonical
    $mutatedStatus = Test-BoostLabSourceChecksum -LiteralPath $mutatedPath -ExpectedSha256 $expectedRaw -ExpectedCanonicalSha256 $expectedCanonical

    Assert-BoostLabCondition ([string]$crlfStatus.ChecksumStatus -eq 'Passed') 'CRLF source variant should verify.'
    Assert-BoostLabCondition ([string]$lfStatus.ChecksumStatus -eq 'Passed') 'LF source variant should verify through canonical text checksum.'
    Assert-BoostLabCondition ([string]$lfStatus.VerificationMode -eq 'CanonicalTextSha256') 'LF source variant should use canonical text verification.'
    Assert-BoostLabCondition ([string]$bomStatus.ChecksumStatus -eq 'Passed') 'UTF-8 BOM source variant should verify through canonical text checksum.'
    Assert-BoostLabCondition ([string]$mutatedStatus.ChecksumStatus -eq 'Failed') 'Actual content mutation must fail source verification.'

    $reinstallRawExpected = '137F519926293F37052817ACBBE20851652E5EA1B9F3B5B9F933AA1E22C2D9FB'
    $reinstallCanonicalExpected = '64F76A856E4CC57BEE34C6DEA86F2B7ADC432B01A3FA4AEB5C2A650B9AE9A477'
    $reinstallBytes = [IO.File]::ReadAllBytes($reinstallSourcePath)
    $reinstallText = [Text.UTF8Encoding]::new($false, $true).GetString($reinstallBytes)
    $reinstallText = $reinstallText -replace "`r`n", "`n"
    $reinstallText = $reinstallText -replace "`r", "`n"
    $packagedLfPath = Join-Path $tempRoot 'Reinstall-Packaged-Lf.ps1'
    [IO.File]::WriteAllBytes($packagedLfPath, $utf8NoBom.GetBytes($reinstallText))

    $packagedStatus = Test-BoostLabSourceChecksum `
        -LiteralPath $packagedLfPath `
        -ExpectedSha256 $reinstallRawExpected `
        -ExpectedCanonicalSha256 $reinstallCanonicalExpected `
        -TextNormalizationEnabled $true

    Assert-BoostLabCondition ([string]$packagedStatus.ChecksumStatus -eq 'Passed') 'Reinstall packaged LF source should pass canonical verification.'
    Assert-BoostLabCondition ([string]$packagedStatus.VerificationMode -eq 'CanonicalTextSha256') 'Reinstall packaged LF source should not require the raw CRLF hash.'

    $module = Import-Module -Name $reinstallModulePath -Force -PassThru -ErrorAction Stop
    try {
        $analysis = Invoke-BoostLabToolAction -ActionName 'Analyze'
        Assert-BoostLabCondition ([bool]$analysis.Success) 'Reinstall Analyze should pass source verification.'
        Assert-BoostLabCondition ([string]$analysis.Data.Source.ChecksumStatus -eq 'Passed') 'Reinstall Analyze source status should pass.'
        Assert-BoostLabCondition ([string]$analysis.Data.Source.ExpectedCanonicalSha256 -eq $reinstallCanonicalExpected) 'Reinstall Analyze should report the canonical source checksum.'

        $apply = Invoke-BoostLabToolAction -ActionName 'Apply'
        Assert-BoostLabCondition (-not [bool]$apply.Success) 'Unconfirmed Reinstall Apply must remain blocked before execution.'
        Assert-BoostLabCondition ([string]$apply.Status -eq 'ConfirmationRequired') 'Unconfirmed Reinstall Apply should require confirmation, not fail source verification.'
        Assert-BoostLabCondition (-not [bool]$apply.ChangesExecuted) 'Checksum robustness test must not execute Reinstall Apply.'
    }
    finally {
        if ($null -ne $module) {
            Remove-Module -ModuleInfo $module -Force -ErrorAction SilentlyContinue
        }
    }
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

[pscustomobject]@{
    Test = 'SourceChecksumPackagingRobustness'
    CrlfVariantVerified = $true
    LfVariantVerified = $true
    BomVariantVerified = $true
    ContentMutationBlocked = $true
    ReinstallPackagedSourceVerified = $true
    RuntimeActionExecuted = $false
    Message = 'Canonical source checksum verification tolerates packaging line-ending/BOM normalization while blocking real content mutation.'
}
