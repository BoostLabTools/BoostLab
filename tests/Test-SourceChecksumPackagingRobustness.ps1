[CmdletBinding()]
param(
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'BoostLab.Hashing.ps1')
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
$updatesDriversModulePath = Join-Path $ProjectRoot 'modules\Refresh\updates-drivers-block.psm1'
$updatesDriversSourcePath = Join-Path $ProjectRoot 'source-ultimate\2 Refresh\3 Updates Drivers Block.ps1'
foreach ($path in @($sourceVerificationPath, $reinstallModulePath, $reinstallSourcePath, $updatesDriversModulePath, $updatesDriversSourcePath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $path -PathType Leaf) "Required checksum robustness file missing: $path"
}

Import-Module -Name $sourceVerificationPath -Force -ErrorAction Stop

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('BoostLabSourceChecksum-' + [guid]::NewGuid().ToString('N'))
New-Item -Path $tempRoot -ItemType Directory -Force | Out-Null
try {
    $utf8NoBom = [Text.UTF8Encoding]::new($false)
    $contentLf = "Write-Host 'BoostLab source check'`n`$value = 1`n"
    $contentCrlf = $contentLf -replace "`n", "`r`n"
    $contentCr = $contentLf -replace "`n", "`r"
    $contentMutated = $contentLf + "Write-Host 'mutated'`n"

    $crlfPath = Join-Path $tempRoot 'Source-Crlf.ps1'
    $lfPath = Join-Path $tempRoot 'Source-Lf.ps1'
    $crPath = Join-Path $tempRoot 'Source-Cr.ps1'
    $bomPath = Join-Path $tempRoot 'Source-Bom.ps1'
    $mutatedPath = Join-Path $tempRoot 'Source-Mutated.ps1'

    [IO.File]::WriteAllBytes($crlfPath, $utf8NoBom.GetBytes($contentCrlf))
    [IO.File]::WriteAllBytes($lfPath, $utf8NoBom.GetBytes($contentLf))
    [IO.File]::WriteAllBytes($crPath, $utf8NoBom.GetBytes($contentCr))
    [IO.File]::WriteAllBytes($bomPath, ([byte[]]@(0xEF, 0xBB, 0xBF) + $utf8NoBom.GetBytes($contentLf)))
    [IO.File]::WriteAllBytes($mutatedPath, $utf8NoBom.GetBytes($contentMutated))

    $expectedRaw = (Get-FileHash -LiteralPath $crlfPath -Algorithm SHA256).Hash
    $expectedCanonical = Get-BoostLabSha256Hex -Bytes (ConvertTo-BoostLabCanonicalSourceTextBytes -Bytes ([IO.File]::ReadAllBytes($crlfPath)))
    $bomCanonical = Get-BoostLabSha256Hex -Bytes (ConvertTo-BoostLabCanonicalSourceTextBytes -Bytes ([IO.File]::ReadAllBytes($bomPath)))

    $crlfStatus = Test-BoostLabSourceChecksum -LiteralPath $crlfPath -ExpectedSha256 $expectedRaw -ExpectedCanonicalSha256 $expectedCanonical
    $lfStatus = Test-BoostLabSourceChecksum -LiteralPath $lfPath -ExpectedSha256 $expectedRaw -ExpectedCanonicalSha256 $expectedCanonical
    $crStatus = Test-BoostLabSourceChecksum -LiteralPath $crPath -ExpectedSha256 $expectedRaw -ExpectedCanonicalSha256 $expectedCanonical
    $bomStatus = Test-BoostLabSourceChecksum -LiteralPath $bomPath -ExpectedSha256 $expectedRaw -ExpectedCanonicalSha256 $expectedCanonical
    $mutatedStatus = Test-BoostLabSourceChecksum -LiteralPath $mutatedPath -ExpectedSha256 $expectedRaw -ExpectedCanonicalSha256 $expectedCanonical

    Assert-BoostLabCondition ([string]$crlfStatus.ChecksumStatus -eq 'Passed') 'CRLF source variant should verify.'
    Assert-BoostLabCondition ([string]$lfStatus.ChecksumStatus -eq 'Passed') 'LF source variant should verify through canonical text checksum.'
    Assert-BoostLabCondition ([string]$lfStatus.VerificationMode -eq 'CanonicalTextSha256') 'LF source variant should use canonical text verification.'
    Assert-BoostLabCondition ([string]$crStatus.ChecksumStatus -eq 'Passed') 'CR source variant should verify through canonical text checksum.'
    Assert-BoostLabCondition ([string]$crStatus.VerificationMode -eq 'CanonicalTextSha256') 'CR source variant should use canonical text verification.'
    Assert-BoostLabCondition ($bomCanonical -ne $expectedCanonical) 'UTF-8 BOM and no-BOM source variants must produce different canonical hashes.'
    Assert-BoostLabCondition ([string]$bomStatus.ChecksumStatus -eq 'Failed') 'UTF-8 BOM source variant must fail when the expected canonical checksum has no BOM.'
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

    $updatesRawExpected = '4D4EC652C5A7F78824F53B7DC7FD46DDA948F3716A7CD6FD102D6C678EE11991'
    $updatesCanonicalExpected = 'D18878A8856096913643F7619917CAE688A19368A34792D94F3CC53BE45B0367'
    $updatesBytes = [IO.File]::ReadAllBytes($updatesDriversSourcePath)
    $updatesText = [Text.UTF8Encoding]::new($false, $true).GetString($updatesBytes)
    $updatesText = $updatesText -replace "`r`n", "`n"
    $updatesText = $updatesText -replace "`r", "`n"
    $updatesPackagedLfPath = Join-Path $tempRoot 'Updates-Drivers-Block-Packaged-Lf.ps1'
    [IO.File]::WriteAllBytes($updatesPackagedLfPath, $utf8NoBom.GetBytes($updatesText))

    $updatesPackagedStatus = Test-BoostLabSourceChecksum `
        -LiteralPath $updatesPackagedLfPath `
        -ExpectedSha256 $updatesRawExpected `
        -ExpectedCanonicalSha256 $updatesCanonicalExpected `
        -TextNormalizationEnabled $true

    Assert-BoostLabCondition ([string]$updatesPackagedStatus.ChecksumStatus -eq 'Passed') 'Updates Drivers Block packaged LF source should pass canonical verification.'
    Assert-BoostLabCondition ([string]$updatesPackagedStatus.VerificationMode -eq 'CanonicalTextSha256') 'Updates Drivers Block packaged LF source should not require the raw CRLF hash.'

    $updatesMutatedPath = Join-Path $tempRoot 'Updates-Drivers-Block-Mutated.ps1'
    [IO.File]::WriteAllBytes($updatesMutatedPath, $utf8NoBom.GetBytes($updatesText + "`n# mutation must fail`n"))
    $updatesMutatedStatus = Test-BoostLabSourceChecksum `
        -LiteralPath $updatesMutatedPath `
        -ExpectedSha256 $updatesRawExpected `
        -ExpectedCanonicalSha256 $updatesCanonicalExpected `
        -TextNormalizationEnabled $true
    Assert-BoostLabCondition ([string]$updatesMutatedStatus.ChecksumStatus -eq 'Failed') 'Updates Drivers Block real content mutation must fail source verification.'

    $updatesModule = Import-Module -Name $updatesDriversModulePath -Force -PassThru -ErrorAction Stop
    try {
        $updatesAnalyze = Invoke-BoostLabToolAction -ActionName 'Analyze' -DriveReader { @() }
        Assert-BoostLabCondition ([bool]$updatesAnalyze.Success) 'Updates Drivers Block Analyze should pass source verification.'
        Assert-BoostLabCondition ([string]$updatesAnalyze.Data.Source.ChecksumStatus -eq 'Passed') 'Updates Drivers Block Analyze source status should pass.'
        Assert-BoostLabCondition ([string]$updatesAnalyze.Data.Source.ExpectedCanonicalSha256 -eq $updatesCanonicalExpected) 'Updates Drivers Block Analyze should report the canonical source checksum.'
        Assert-BoostLabCondition (-not [bool]$updatesAnalyze.ChangesExecuted) 'Checksum robustness test must not execute Updates Drivers Block mutations.'
    }
    finally {
        if ($null -ne $updatesModule) {
            Remove-Module -ModuleInfo $updatesModule -Force -ErrorAction SilentlyContinue
        }
    }

    $sourceBackedModules = @(Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'modules') -Recurse -Filter '*.psm1' | Where-Object {
        $moduleText = Get-Content -LiteralPath $_.FullName -Raw
        $moduleText -match 'source-ultimate|_intake-promoted' -and
        $moduleText -match 'BoostLabExpectedSourceHash|BoostLab[A-Za-z0-9]+SourceHash'
    })
    Assert-BoostLabCondition ($sourceBackedModules.Count -gt 0) 'Source-backed module guard did not find any modules to inspect.'

    foreach ($sourceBackedModule in $sourceBackedModules) {
        $tokens = $null
        $parseErrors = $null
        $moduleAst = [System.Management.Automation.Language.Parser]::ParseFile($sourceBackedModule.FullName, [ref]$tokens, [ref]$parseErrors)
        Assert-BoostLabCondition ($parseErrors.Count -eq 0) "Unable to parse source-backed module $($sourceBackedModule.FullName): $($parseErrors | ForEach-Object Message -join '; ')"

        $sourceFunctions = @($moduleAst.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Name -match 'Source(Status|Info|Integrity)$'
        }, $true))
        Assert-BoostLabCondition ($sourceFunctions.Count -gt 0) "Source-backed module $($sourceBackedModule.FullName) must expose a source status/info/integrity function."

        foreach ($sourceFunction in $sourceFunctions) {
            $functionText = $sourceFunction.Extent.Text
            if ($functionText -notmatch 'BoostLabExpectedSourceHash|BoostLab[A-Za-z0-9]+SourceHash') {
                continue
            }

            Assert-BoostLabCondition ($functionText -match 'Test-BoostLabSourceChecksum') "Source verification function $($sourceFunction.Name) in $($sourceBackedModule.FullName) must use the central SourceVerification helper."
            Assert-BoostLabCondition ($functionText -notmatch 'Get-FileHash') "Source verification function $($sourceFunction.Name) in $($sourceBackedModule.FullName) must not use raw-only Get-FileHash verification."
        }

        $sourceBackedModuleText = Get-Content -LiteralPath $sourceBackedModule.FullName -Raw
        Assert-BoostLabCondition ($sourceBackedModuleText -match 'ExpectedCanonical') "Source-backed module $($sourceBackedModule.FullName) must declare or report a canonical source checksum."
    }
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

[pscustomobject]@{
    Test = 'SourceChecksumPackagingRobustness'
    CrlfVariantVerified = $true
    LfVariantVerified = $true
    CrVariantVerified = $true
    BomVariantRejected = $true
    ContentMutationBlocked = $true
    ReinstallPackagedSourceVerified = $true
    UpdatesDriversBlockPackagedSourceVerified = $true
    SourceBackedModuleGuardPassed = $true
    RuntimeActionExecuted = $false
    Message = 'Canonical source checksum verification tolerates line-ending normalization while preserving BOM and blocking real content mutation.'
}
