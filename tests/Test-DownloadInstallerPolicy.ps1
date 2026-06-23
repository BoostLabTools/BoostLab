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
        throw 'Unable to determine the download and installer policy test path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

. (Join-Path $ProjectRoot 'tests\BoostLab.InventoryBaseline.ps1')
$inventoryBaseline = Get-BoostLabInventoryBaseline -ProjectRoot $ProjectRoot

$manifestPath = Join-Path $ProjectRoot 'config\ArtifactProvenance.psd1'
$downloadModulePath = Join-Path $ProjectRoot 'core\DownloadProvenance.psm1'
$installerModulePath = Join-Path $ProjectRoot 'core\InstallerExecution.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$policyDocPath = Join-Path $ProjectRoot 'docs\download-provenance-installer-policy.md'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$errors = [System.Collections.Generic.List[string]]::new()
foreach ($requiredPath in @(
    $manifestPath
    $downloadModulePath
    $installerModulePath
    $policyDocPath
)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        $errors.Add("Required Phase 35 file is missing: $requiredPath")
    }
}
if ($errors.Count -gt 0) {
    throw "Download and installer policy validation failed:`r`n- $($errors -join "`r`n- ")"
}

$downloadModule = Import-Module `
    -Name $downloadModulePath `
    -Force `
    -PassThru `
    -Scope Local `
    -ErrorAction Stop
$installerModule = Import-Module `
    -Name $installerModulePath `
    -Force `
    -PassThru `
    -Scope Local `
    -ErrorAction Stop

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("BoostLab-PolicyTest-{0}" -f [guid]::NewGuid())
New-Item -ItemType Directory -Path $tempRoot -Force -ErrorAction Stop | Out-Null

try {
    foreach ($commandName in @(
        'Get-BoostLabArtifactProvenanceManifest'
        'Get-BoostLabExternalArtifactSourceManifest'
        'Get-BoostLabExternalRuntimeArtifactDefinitions'
        'Get-BoostLabOfficialVendorDirectRuntimePolicy'
        'Get-BoostLabOfficialVendorDirectRuntimeSources'
        'Get-BoostLabApprovedOfficialVendorRuntimeSource'
        'Invoke-BoostLabOfficialVendorDownload'
        'Test-BoostLabArtifactDefinition'
        'Test-BoostLabArtifactProvenanceManifest'
        'Get-BoostLabArtifactDefinition'
        'Test-BoostLabArtifactProvenance'
        'New-BoostLabArtifactDownloadRequest'
        'New-BoostLabInstallerExecutionPlan'
        'Test-BoostLabInstallerExecutionRequest'
        'Invoke-BoostLabInstallerExecution'
    )) {
        if (-not (Get-Command -Name $commandName -ErrorAction SilentlyContinue)) {
            $errors.Add("Phase 35 helper is not exported: $commandName")
        }
    }

    $productionManifest = Get-BoostLabArtifactProvenanceManifest -ManifestPath $manifestPath
    $productionValidation = Test-BoostLabArtifactProvenanceManifest -Manifest $productionManifest
    if (-not $productionValidation.IsValid) {
        $errors.Add("Production provenance manifest is invalid: $($productionValidation.Errors -join '; ')")
    }
    if ($productionValidation.ArtifactCount -ne 0) {
        $errors.Add('Phase 35 must not approve real artifacts in the production manifest.')
    }
    $externalRuntimeArtifacts = @(Get-BoostLabExternalRuntimeArtifactDefinitions)
    if ($externalRuntimeArtifacts.Count -ne 28) {
        $errors.Add("Phase 164H must expose exactly 28 verified runtime mirror artifact definitions; found $($externalRuntimeArtifacts.Count).")
    }
    $approvedMirrorSource = Get-BoostLabApprovedArtifactRuntimeSource -ArtifactId 'directx-runtime-package'
    if (
        -not $approvedMirrorSource.Allowed -or
        [string]$approvedMirrorSource.SourceUrl -notlike 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-artifacts-v1/*'
    ) {
        $errors.Add('Approved runtime mirror artifact source was not resolved from the verified BoostLab mirror catalog.')
    }

    $officialPolicy = Get-BoostLabOfficialVendorDirectRuntimePolicy
    $officialRuntimeSources = @(Get-BoostLabOfficialVendorDirectRuntimeSources)
    if ([int]$officialPolicy.ApprovedCount -ne 22 -or $officialRuntimeSources.Count -ne 22) {
        $errors.Add("Phase 164I must approve exactly 22 OfficialVendorDirect runtime sources; found $($officialRuntimeSources.Count).")
    }
    $officialKindCounts = @{}
    foreach ($group in @($officialRuntimeSources | Group-Object SourceKind)) {
        $officialKindCounts[[string]$group.Name] = [int]$group.Count
    }
    $expectedOfficialKindCounts = @{
        StaticOfficialInstaller = 3
        FloatingOfficialInstaller = 15
        OfficialVendorLookupPage = 2
        OfficialVendorApi = 1
        BrowserExtensionOfficialSource = 1
    }
    foreach ($kind in $expectedOfficialKindCounts.Keys) {
        if ([int]$officialKindCounts[$kind] -ne [int]$expectedOfficialKindCounts[$kind]) {
            $errors.Add("OfficialVendorDirect classification count mismatch for $kind.")
        }
    }
    if (@($officialRuntimeSources | Where-Object { [string]$_.SourceUrl -like 'https://github.com/BoostLabTools/BoostLab/*' }).Count -ne 0) {
        $errors.Add('OfficialVendorDirect runtime sources must not use BoostLab mirror URLs.')
    }

    $discordOfficial = Get-BoostLabApprovedOfficialVendorRuntimeSource `
        -ArtifactId 'installers-discord' `
        -Purpose Download `
        -SourceUrl 'https://discord.com/api/downloads/distributions/app/installers/latest?channel=stable&platform=win&arch=x64'
    if (-not $discordOfficial.Allowed) {
        $errors.Add("Approved Discord official source was blocked: $($discordOfficial.Errors -join '; ')")
    }
    $badHostOfficial = Get-BoostLabApprovedOfficialVendorRuntimeSource `
        -ArtifactId 'installers-discord' `
        -Purpose Download `
        -SourceUrl 'https://example.invalid/Discord.exe'
    if ($badHostOfficial.Allowed -or (@($badHostOfficial.Errors) -join ' ') -notmatch 'approved vendor host') {
        $errors.Add('Official source with an unapproved host was not blocked.')
    }
    $badSchemeOfficial = Get-BoostLabApprovedOfficialVendorRuntimeSource `
        -ArtifactId 'installers-discord' `
        -Purpose Download `
        -SourceUrl 'http://discord.com/Discord.exe'
    if ($badSchemeOfficial.Allowed -or (@($badSchemeOfficial.Errors) -join ' ') -notmatch 'HTTPS') {
        $errors.Add('Official source with a non-HTTPS scheme was not blocked.')
    }
    $nvidiaLookup = Get-BoostLabApprovedOfficialVendorRuntimeSource `
        -ArtifactId 'driver-install-latest-nvidia-lookup' `
        -Purpose Lookup
    $nvidiaLookupDownload = Get-BoostLabApprovedOfficialVendorRuntimeSource `
        -ArtifactId 'driver-install-latest-nvidia-lookup' `
        -Purpose Download
    if (-not $nvidiaLookup.Allowed -or $nvidiaLookupDownload.Allowed) {
        $errors.Add('NVIDIA lookup API must be lookup-approved but not executable/download-approved.')
    }
    $nvidiaTemplateWithoutResolvedUrl = Get-BoostLabApprovedOfficialVendorRuntimeSource `
        -ArtifactId 'driver-install-latest-nvidia-driver-template' `
        -Purpose Download
    $nvidiaResolvedDownload = Get-BoostLabApprovedOfficialVendorRuntimeSource `
        -ArtifactId 'driver-install-latest-nvidia-driver-template' `
        -Purpose Download `
        -SourceUrl 'https://international.download.nvidia.com/Windows/555.85/555.85-desktop-win10-win11-64bit-international-dch-whql.exe'
    $nvidiaBadResolvedDownload = Get-BoostLabApprovedOfficialVendorRuntimeSource `
        -ArtifactId 'driver-install-latest-nvidia-driver-template' `
        -Purpose Download `
        -SourceUrl 'https://international.download.nvidia.com/Windows/555.85/555.85-not-approved.exe'
    if ($nvidiaTemplateWithoutResolvedUrl.Allowed -or -not $nvidiaResolvedDownload.Allowed -or $nvidiaBadResolvedDownload.Allowed) {
        $errors.Add('NVIDIA driver template must require a resolved, pattern-approved official download URL.')
    }
    $intelLookup = Get-BoostLabApprovedOfficialVendorRuntimeSource `
        -ArtifactId 'driver-install-latest-intel-driver-page' `
        -Purpose Lookup
    $intelDownload = Get-BoostLabApprovedOfficialVendorRuntimeSource `
        -ArtifactId 'driver-install-latest-intel-driver-page' `
        -Purpose Download
    if (-not $intelLookup.Allowed -or $intelDownload.Allowed) {
        $errors.Add('INTEL official driver page must be lookup-approved but not executable/download-approved.')
    }

    $blockedOfficialManifest = Get-BoostLabExternalArtifactSourceManifest
    $blockedPolicy = [ordered]@{}
    foreach ($key in $blockedOfficialManifest.OfficialVendorDirectRuntimePolicy.Keys) {
        $blockedPolicy[$key] = $blockedOfficialManifest.OfficialVendorDirectRuntimePolicy[$key]
    }
    $blockedEntries = @()
    foreach ($entry in @($blockedOfficialManifest.OfficialVendorDirectRuntimePolicy.Entries)) {
        $copy = [ordered]@{}
        foreach ($key in $entry.Keys) {
            $copy[$key] = $entry[$key]
        }
        if ([string]$copy.Id -eq 'installers-discord') {
            $copy['ProductionAllowlistApproved'] = $false
        }
        $blockedEntries += $copy
    }
    $blockedPolicy['Entries'] = $blockedEntries
    $blockedOfficialManifest['OfficialVendorDirectRuntimePolicy'] = $blockedPolicy
    $missingOfficialApproval = Get-BoostLabApprovedOfficialVendorRuntimeSource `
        -ArtifactId 'installers-discord' `
        -Purpose Download `
        -SourceUrl 'https://discord.com/api/downloads/distributions/app/installers/latest?channel=stable&platform=win&arch=x64' `
        -Manifest $blockedOfficialManifest
    if ($missingOfficialApproval.Allowed -or (@($missingOfficialApproval.Errors) -join ' ') -notmatch 'ProductionAllowlistApproved') {
        $errors.Add('Official source without production approval was not blocked.')
    }

    $mockInstallerPath = Join-Path $tempRoot 'boostlab-policy-mock.exe'
    [IO.File]::WriteAllText(
        $mockInstallerPath,
        'BoostLab local policy test data. This file is not executable code.',
        [Text.Encoding]::UTF8
    )
    $mockFile = Get-Item -LiteralPath $mockInstallerPath
    $mockHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $mockInstallerPath).Hash

    $mockArtifact = [ordered]@{
        Id                       = 'mock-local-installer'
        DisplayName              = 'BoostLab Local Mock Installer'
        SourceUrl                = 'https://example.invalid/boostlab-policy-mock.exe'
        ExpectedSha256           = $mockHash
        ExpectedFileName         = $mockFile.Name
        ExpectedSizeBytes        = [long]$mockFile.Length
        MinimumSizeBytes         = 0L
        MaximumSizeBytes         = 0L
        ArtifactType             = 'Installer'
        ExpectedPublisher        = 'BoostLab Test Publisher'
        ExpectedSignatureStatus  = 'Valid'
        VerifiedBoostLabMirrorUrl = 'https://example.invalid/boostlab-policy-mock.exe'
        SourceToolIds            = @('mock-tool')
        LicenseNote              = 'Local mocked test data only; not redistributable software.'
        AllowExecution           = $true
        RequiresAdmin            = $true
        CanReboot                = $false
        VerificationRequirements = @(
            'FileName'
            'SHA256'
            'FileSize'
            'AuthenticodeSigner'
        )
        ApprovalStatus           = 'Approved'
        ProductionAllowlistApproved = $true
        RuntimeSourceSelectionApproved = $true
    }
    $mockManifest = @{
        SchemaVersion = '1.0'
        Artifacts     = @($mockArtifact)
    }

    $mockManifestValidation = Test-BoostLabArtifactProvenanceManifest -Manifest $mockManifest
    if (-not $mockManifestValidation.IsValid -or $mockManifestValidation.ArtifactCount -ne 1) {
        $errors.Add("Valid local mock manifest was rejected: $($mockManifestValidation.Errors -join '; ')")
    }

    $missingHashArtifact = [ordered]@{}
    foreach ($key in $mockArtifact.Keys) {
        $missingHashArtifact[$key] = $mockArtifact[$key]
    }
    $missingHashArtifact['ExpectedSha256'] = ''
    $missingHashValidation = Test-BoostLabArtifactDefinition -Artifact $missingHashArtifact
    if ($missingHashValidation.IsValid -or (@($missingHashValidation.Errors) -join ' ') -notmatch 'ExpectedSha256') {
        $errors.Add('Artifact definition without a complete hash was not blocked.')
    }

    $missingSignerArtifact = [ordered]@{}
    foreach ($key in $mockArtifact.Keys) {
        $missingSignerArtifact[$key] = $mockArtifact[$key]
    }
    $missingSignerArtifact['ExpectedPublisher'] = ''
    $missingSignerValidation = Test-BoostLabArtifactDefinition -Artifact $missingSignerArtifact
    if ($missingSignerValidation.IsValid -or (@($missingSignerValidation.Errors) -join ' ') -notmatch 'ExpectedPublisher') {
        $errors.Add('Executable artifact without a signer/publisher requirement was not blocked.')
    }

    $nonExecutableArtifact = [ordered]@{}
    foreach ($key in $mockArtifact.Keys) {
        $nonExecutableArtifact[$key] = $mockArtifact[$key]
    }
    $nonExecutableArtifact['Id'] = 'mock-non-executable'
    $nonExecutableArtifact['ArtifactType'] = 'NonExecutable'
    $nonExecutableArtifact['ExpectedPublisher'] = ''
    $nonExecutableArtifact['AllowExecution'] = $false
    $nonExecutableArtifact['VerificationRequirements'] = @('FileName', 'SHA256')
    $nonExecutableValidation = Test-BoostLabArtifactDefinition -Artifact $nonExecutableArtifact
    if (-not $nonExecutableValidation.IsValid) {
        $errors.Add('Explicitly non-executable artifact was incorrectly required to declare a signer.')
    }

    $unknownLookup = Get-BoostLabArtifactDefinition `
        -ArtifactId 'not-in-manifest' `
        -Manifest $mockManifest
    $unknownDownload = New-BoostLabArtifactDownloadRequest `
        -ArtifactId 'not-in-manifest' `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -Manifest $mockManifest
    if (
        $unknownLookup.Found -or
        $unknownLookup.Status -ne 'Blocked' -or
        $unknownDownload.Allowed -or
        $unknownDownload.DownloadStarted
    ) {
        $errors.Add('Unknown artifacts are not denied by default.')
    }

    $signatureInspector = {
        param([string]$Path)

        [pscustomobject]@{
            Status    = 'Valid'
            Publisher = 'CN=BoostLab Test Publisher'
        }
    }
    $verifiedProvenance = Test-BoostLabArtifactProvenance `
        -ArtifactId 'mock-local-installer' `
        -LocalPath $mockInstallerPath `
        -Manifest $mockManifest `
        -SignatureInspector $signatureInspector
    if (-not $verifiedProvenance.Verified -or $verifiedProvenance.Status -ne 'Verified') {
        $errors.Add("Valid local mock provenance was rejected: $($verifiedProvenance.Errors -join '; ')")
    }

    $mockDownloadRoot = Join-Path $tempRoot 'download'
    New-Item -ItemType Directory -Path $mockDownloadRoot -Force -ErrorAction Stop | Out-Null
    $mockDownloadPath = Join-Path $mockDownloadRoot $mockFile.Name
    $downloadedUrls = [System.Collections.Generic.List[string]]::new()
    $mockDownloader = {
        param(
            [string]$Uri,
            [string]$OutFile
        )

        $downloadedUrls.Add($Uri) | Out-Null
        Copy-Item -LiteralPath $mockInstallerPath -Destination $OutFile -Force
    }
    $downloadResult = Invoke-BoostLabVerifiedArtifactDownload `
        -ArtifactId 'mock-local-installer' `
        -Destination $mockDownloadPath `
        -Manifest $mockManifest `
        -Downloader $mockDownloader `
        -SignatureInspector $signatureInspector
    $downloadedUrl = if ($downloadedUrls.Count -gt 0) {
        [string]$downloadedUrls[0]
    }
    else {
        ''
    }
    if (
        -not $downloadResult.Success -or
        [string]$downloadResult.SourceUrl -ne [string]$mockArtifact.SourceUrl -or
        $downloadedUrl -ne [string]$mockArtifact.SourceUrl
    ) {
        $errors.Add('Verified artifact download did not use the approved manifest source through the mock downloader.')
    }

    $officialDownloadPath = Join-Path $mockDownloadRoot 'Discord.exe'
    $officialDownloadedUrls = [System.Collections.Generic.List[string]]::new()
    $officialDownloader = {
        param(
            [string]$Uri,
            [string]$OutFile
        )

        $officialDownloadedUrls.Add($Uri) | Out-Null
        [IO.File]::WriteAllText($OutFile, 'BoostLab official direct mocked download.', [Text.Encoding]::UTF8)
    }
    $officialSignatureInspector = {
        param([string]$Path)

        [pscustomobject]@{
            Status = 'Valid'
            Publisher = 'CN=BoostLab Official Mock Publisher'
        }
    }
    $officialDownload = Invoke-BoostLabOfficialVendorDownload `
        -ArtifactId 'installers-discord' `
        -SourceUrl 'https://discord.com/api/downloads/distributions/app/installers/latest?channel=stable&platform=win&arch=x64' `
        -Destination $officialDownloadPath `
        -Downloader $officialDownloader `
        -SignatureInspector $officialSignatureInspector
    if (-not $officialDownload.Success -or $officialDownloadedUrls.Count -ne 1) {
        $errors.Add('Official vendor mocked download did not use the approved source through the verification helper.')
    }

    $officialBadTypeBlocked = $false
    try {
        Invoke-BoostLabOfficialVendorDownload `
            -ArtifactId 'installers-discord' `
            -SourceUrl 'https://discord.com/api/downloads/distributions/app/installers/latest?channel=stable&platform=win&arch=x64' `
            -Destination (Join-Path $mockDownloadRoot 'Discord.txt') `
            -Downloader $officialDownloader `
            -SignatureInspector $officialSignatureInspector | Out-Null
    }
    catch {
        $officialBadTypeBlocked = $_.Exception.Message -match 'filename|extension'
    }
    if (-not $officialBadTypeBlocked) {
        $errors.Add('Official vendor download with the wrong local filename/type was not blocked.')
    }

    $officialBadSignerBlocked = $false
    try {
        Invoke-BoostLabOfficialVendorDownload `
            -ArtifactId 'installers-discord' `
            -SourceUrl 'https://discord.com/api/downloads/distributions/app/installers/latest?channel=stable&platform=win&arch=x64' `
            -Destination (Join-Path $mockDownloadRoot 'Discord.exe') `
            -Downloader $officialDownloader `
            -SignatureInspector { param([string]$Path) [pscustomobject]@{ Status = 'NotSigned'; Publisher = '' } } | Out-Null
    }
    catch {
        $officialBadSignerBlocked = $_.Exception.Message -match 'signature'
    }
    if (-not $officialBadSignerBlocked) {
        $errors.Add('Official vendor executable download with a bad signer was not blocked.')
    }

    $xpiDownloadPath = Join-Path $mockDownloadRoot 'uBlock0@raymondhill.net.xpi'
    $xpiDownload = Invoke-BoostLabOfficialVendorDownload `
        -ArtifactId 'installers-ublock-origin-xpi' `
        -SourceUrl 'https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi' `
        -Destination $xpiDownloadPath `
        -Downloader $officialDownloader
    if (-not $xpiDownload.Success -or [string]$xpiDownload.Verification.SourceKind -ne 'BrowserExtensionOfficialSource') {
        $errors.Add('Official browser extension XPI source was not verified by extension/source policy.')
    }

    $sevenZipPolicy = @($officialPolicy.Entries | Where-Object { [string]$_['Id'] -eq 'installers-seven-zip' })[0]
    if (
        $null -eq $sevenZipPolicy -or
        [string]$sevenZipPolicy['ExpectedSignatureStatus'] -ne 'NotSigned' -or
        $sevenZipPolicy['UnsignedOfficialArtifactApproved'] -ne $true -or
        [string]$sevenZipPolicy['ExpectedSha256'] -ne '26CB6E9F56333682122FAFE79DBCDFD51E9F47CC7217DCCD29AC6FC33B5598CD' -or
        [int64]$sevenZipPolicy['ExpectedSizeBytes'] -ne 1589510 -or
        [string]$sevenZipPolicy['ExpectedSourceFileName'] -ne '7z2301-x64.exe'
    ) {
        $errors.Add('Installers 7-Zip must carry the exact narrow NotSigned official-source approval metadata.')
    }

    $sevenZipMockSource = Join-Path $tempRoot 'mock-7zip-source.bin'
    [IO.File]::WriteAllText(
        $sevenZipMockSource,
        'BoostLab mocked 7-Zip official vendor payload for policy tests only.',
        [Text.Encoding]::UTF8
    )
    $sevenZipMockFile = Get-Item -LiteralPath $sevenZipMockSource
    $sevenZipMockHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sevenZipMockSource).Hash
    $sevenZipMockManifest = Get-BoostLabExternalArtifactSourceManifest
    $sevenZipMockPolicy = @($sevenZipMockManifest.OfficialVendorDirectRuntimePolicy.Entries | Where-Object { [string]$_['Id'] -eq 'installers-seven-zip' })[0]
    $sevenZipMockPolicy['ExpectedSha256'] = $sevenZipMockHash
    $sevenZipMockPolicy['ExpectedSizeBytes'] = [int64]$sevenZipMockFile.Length
    $sevenZipDestination = Join-Path $mockDownloadRoot '7 Zip.exe'
    $sevenZipDownloader = {
        param(
            [string]$Uri,
            [string]$OutFile
        )

        Copy-Item -LiteralPath $sevenZipMockSource -Destination $OutFile -Force
    }
    $notSignedInspector = {
        param([string]$Path)

        [pscustomobject]@{
            Status = 'NotSigned'
            Publisher = ''
        }
    }
    $sevenZipDownload = Invoke-BoostLabOfficialVendorDownload `
        -ArtifactId 'installers-seven-zip' `
        -SourceUrl 'https://www.7-zip.org/a/7z2301-x64.exe' `
        -Destination $sevenZipDestination `
        -Manifest $sevenZipMockManifest `
        -Downloader $sevenZipDownloader `
        -SignatureInspector $notSignedInspector
    if (
        -not $sevenZipDownload.Success -or
        [string]$sevenZipDownload.Verification.Signature.Status -ne 'Verified' -or
        [string]$sevenZipDownload.Verification.LocalFileIdentity.Status -ne 'Verified'
    ) {
        $errors.Add('Exact Installers 7-Zip NotSigned official artifact was not accepted by URL, hash, size, and signature-status policy.')
    }

    $sevenZipBadUrlBlocked = $false
    try {
        Invoke-BoostLabOfficialVendorDownload `
            -ArtifactId 'installers-seven-zip' `
            -SourceUrl 'https://www.7-zip.org/a/7z2302-x64.exe' `
            -Destination (Join-Path $mockDownloadRoot '7 Zip.exe') `
            -Manifest $sevenZipMockManifest `
            -Downloader $sevenZipDownloader `
            -SignatureInspector $notSignedInspector | Out-Null
    }
    catch {
        $sevenZipBadUrlBlocked = $_.Exception.Message -match 'exact approved vendor URL|approved source filename'
    }
    if (-not $sevenZipBadUrlBlocked) {
        $errors.Add('Installers 7-Zip NotSigned exception was not constrained to the exact approved vendor URL/source filename.')
    }

    $sevenZipMissingHashManifest = Get-BoostLabExternalArtifactSourceManifest
    $sevenZipMissingHashPolicy = @($sevenZipMissingHashManifest.OfficialVendorDirectRuntimePolicy.Entries | Where-Object { [string]$_['Id'] -eq 'installers-seven-zip' })[0]
    $sevenZipMissingHashPolicy['ExpectedSha256'] = ''
    $sevenZipMissingHashBlocked = $false
    try {
        Invoke-BoostLabOfficialVendorDownload `
            -ArtifactId 'installers-seven-zip' `
            -SourceUrl 'https://www.7-zip.org/a/7z2301-x64.exe' `
            -Destination (Join-Path $mockDownloadRoot '7 Zip.exe') `
            -Manifest $sevenZipMissingHashManifest `
            -Downloader $sevenZipDownloader `
            -SignatureInspector $notSignedInspector | Out-Null
    }
    catch {
        $sevenZipMissingHashBlocked = $_.Exception.Message -match 'SHA-256'
    }
    if (-not $sevenZipMissingHashBlocked) {
        $errors.Add('Installers 7-Zip NotSigned exception without SHA-256 evidence was not blocked.')
    }

    $sevenZipHashMismatchBlocked = $false
    try {
        Invoke-BoostLabOfficialVendorDownload `
            -ArtifactId 'installers-seven-zip' `
            -SourceUrl 'https://www.7-zip.org/a/7z2301-x64.exe' `
            -Destination (Join-Path $mockDownloadRoot '7 Zip.exe') `
            -Manifest (Get-BoostLabExternalArtifactSourceManifest) `
            -Downloader $sevenZipDownloader `
            -SignatureInspector $notSignedInspector | Out-Null
    }
    catch {
        $sevenZipHashMismatchBlocked = $_.Exception.Message -match 'SHA-256 mismatch'
    }
    if (-not $sevenZipHashMismatchBlocked) {
        $errors.Add('Installers 7-Zip NotSigned exception with wrong local hash was not blocked.')
    }

    $missingProductionApproval = [ordered]@{}
    foreach ($key in $mockArtifact.Keys) {
        $missingProductionApproval[$key] = $mockArtifact[$key]
    }
    $missingProductionApproval['ProductionAllowlistApproved'] = $false
    $missingProductionManifest = @{
        SchemaVersion = '1.0'
        Artifacts     = @($missingProductionApproval)
    }
    $blockedRuntimeSource = Get-BoostLabApprovedArtifactRuntimeSource `
        -ArtifactId 'mock-local-installer' `
        -Manifest $missingProductionManifest
    if ($blockedRuntimeSource.Allowed -or (@($blockedRuntimeSource.Errors) -join ' ') -notmatch 'production allowlist') {
        $errors.Add('Artifact without production allowlist approval was not blocked for runtime source selection.')
    }

    $hashMismatchArtifact = [ordered]@{}
    foreach ($key in $mockArtifact.Keys) {
        $hashMismatchArtifact[$key] = $mockArtifact[$key]
    }
    $hashMismatchArtifact['ExpectedSha256'] = ('0' * 64)
    $hashMismatchManifest = @{
        SchemaVersion = '1.0'
        Artifacts     = @($hashMismatchArtifact)
    }
    $hashMismatchResult = Test-BoostLabArtifactProvenance `
        -ArtifactId 'mock-local-installer' `
        -LocalPath $mockInstallerPath `
        -Manifest $hashMismatchManifest `
        -SignatureInspector $signatureInspector
    if ($hashMismatchResult.Verified -or $hashMismatchResult.Status -ne 'Blocked') {
        $errors.Add('Hash-mismatched artifact was not blocked.')
    }

    $actionPlan = [pscustomobject]@{
        ToolId                   = 'mock-tool'
        Action                   = 'Apply'
        NeedsExplicitConfirmation = $true
    }
    $mockCommandLine = '"{0}" /mock' -f $mockInstallerPath
    $installerPlan = New-BoostLabInstallerExecutionPlan `
        -Artifact $mockArtifact `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -ExactCommandLine $mockCommandLine `
        -TimeoutSeconds 30
    if (
        -not $installerPlan.RequiresVerifiedArtifact -or
        -not $installerPlan.NeedsExplicitConfirmation -or
        $installerPlan.AllowNetworkExecution -or
        $installerPlan.AllowUnverifiedTempPath -or
        $installerPlan.AllowUnrelatedCleanup -or
        -not $installerPlan.IsDryRun
    ) {
        $errors.Add('Installer execution plan does not preserve the Phase 35 safety policy.')
    }

    $unconfirmedRequest = Test-BoostLabInstallerExecutionRequest `
        -ProvenanceResult $verifiedProvenance `
        -ActionPlan $actionPlan `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -ExactCommandLine $mockCommandLine `
        -Confirmed:$false `
        -TimeoutSeconds 30
    if ($unconfirmedRequest.IsAllowed -or $unconfirmedRequest.Status -ne 'Blocked') {
        $errors.Add('Installer request without explicit confirmation was not blocked.')
    }

    $unverifiedProvenance = [pscustomobject]@{
        Verified     = $false
        VerifiedPath = $mockInstallerPath
        Artifact     = $mockArtifact
    }
    $unverifiedRequest = Test-BoostLabInstallerExecutionRequest `
        -ProvenanceResult $unverifiedProvenance `
        -ActionPlan $actionPlan `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -ExactCommandLine $mockCommandLine `
        -Confirmed:$true `
        -TimeoutSeconds 30
    if ($unverifiedRequest.IsAllowed -or $unverifiedRequest.Status -ne 'Blocked') {
        $errors.Add('Installer request without verified provenance was not blocked.')
    }

    $wrongPathRequest = Test-BoostLabInstallerExecutionRequest `
        -ProvenanceResult $verifiedProvenance `
        -ActionPlan $actionPlan `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -ExactCommandLine '"C:\Unverified\other-installer.exe" /mock' `
        -Confirmed:$true `
        -TimeoutSeconds 30
    if ($wrongPathRequest.IsAllowed -or $wrongPathRequest.Status -ne 'Blocked') {
        $errors.Add('Installer command line pointing outside the verified artifact path was not blocked.')
    }

    $validatedRequest = Test-BoostLabInstallerExecutionRequest `
        -ProvenanceResult $verifiedProvenance `
        -ActionPlan $actionPlan `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -ExactCommandLine $mockCommandLine `
        -Confirmed:$true `
        -TimeoutSeconds 30
    if (-not $validatedRequest.IsAllowed -or $validatedRequest.Status -ne 'Validated') {
        $errors.Add("Fully verified local mock request did not validate: $($validatedRequest.Errors -join '; ')")
    }

    $inertExecution = Invoke-BoostLabInstallerExecution `
        -ProvenanceResult $verifiedProvenance `
        -ActionPlan $actionPlan `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -ExactCommandLine $mockCommandLine `
        -Confirmed:$true `
        -TimeoutSeconds 30
    if (
        $inertExecution.Success -or
        $inertExecution.Status -ne 'NotImplemented' -or
        $inertExecution.ProcessStarted -or
        $null -ne $inertExecution.ProcessId -or
        $null -ne $inertExecution.ExitCode
    ) {
        $errors.Add('Phase 35 installer execution boundary is not inert.')
    }

    foreach ($modulePath in @($downloadModulePath, $installerModulePath)) {
        $tokens = $null
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $modulePath,
            [ref]$tokens,
            [ref]$parseErrors
        )
        if (@($parseErrors).Count -gt 0) {
            $errors.Add("$modulePath has a syntax error: $($parseErrors[0].Message)")
            continue
        }
        $commands = @(
            $ast.FindAll(
                { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
                $true
            ) |
                ForEach-Object { $_.GetCommandName() } |
                Where-Object { $_ }
        )
        foreach ($forbiddenCommand in @(
            'Invoke-RestMethod'
            'Start-BitsTransfer'
            'Start-Process'
            'Invoke-Expression'
        )) {
            if ($forbiddenCommand -in $commands) {
                $errors.Add("$modulePath contains prohibited executable command: $forbiddenCommand")
            }
        }
    }

    $executionSource = Get-Content -LiteralPath $executionPath -Raw
    foreach ($newHelperName in @(
        'DownloadProvenance.psm1'
        'InstallerExecution.psm1'
        'Invoke-BoostLabInstallerExecution'
    )) {
        if ($executionSource.Contains($newHelperName)) {
            $errors.Add("Existing tool runtime was wired to the Phase 35 helper: $newHelperName")
        }
    }

    $allModules = @(
        Get-ChildItem -LiteralPath $modulesRoot -Recurse -File -Filter '*.psm1' |
            Where-Object { $_.Directory.Parent.FullName -eq $modulesRoot }
    )
    $implementedModules = @(
        $allModules | Where-Object {
            (Get-Content -LiteralPath $_.FullName -Raw).Contains('$script:BoostLabImplementedActions')
        }
    )
    $placeholderModules = @(
        $allModules | Where-Object {
            (Get-Content -LiteralPath $_.FullName -Raw).Contains('ToolModule.Placeholder.ps1')
        }
    )
    if (
        $allModules.Count -ne $inventoryBaseline.ActiveTools -or
        $implementedModules.Count -ne $inventoryBaseline.ImplementedTools -or
        $placeholderModules.Count -ne $inventoryBaseline.DeferredPlaceholders
    ) {
        $errors.Add(
            "Tool inventory changed: total=$($allModules.Count), implemented=$($implementedModules.Count), placeholders=$($placeholderModules.Count)."
        )
    }

    $configuration = Import-PowerShellDataFile -LiteralPath $configPath
    $tools = @($configuration['Stages'] | ForEach-Object { $_['Tools'] })
    $activeNames = @(
        $tools | ForEach-Object {
            ([string]$_['Id'] -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()
            ([string]$_['Title'] -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()
        }
    )
    foreach ($deletedTool in @('Loudness EQ', 'NVME Faster Driver')) {
        $normalized = ($deletedTool -replace '[^a-zA-Z0-9]+', '').ToLowerInvariant()
        if ($normalized -in $activeNames) {
            $errors.Add("Deleted tool was reintroduced: $deletedTool")
        }
    }

    $sourceLines = @(
        Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
            Sort-Object { $_.FullName.Substring($ProjectRoot.Length + 1).Replace('\', '/') } |
            ForEach-Object {
                '{0}|{1}' -f `
                    $_.FullName.Substring($ProjectRoot.Length + 1).Replace('\', '/'), `
                    (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
            }
    )
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $sourceManifestHash = [BitConverter]::ToString(
            $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sourceLines -join "`n")))
        ).Replace('-', '')
    }
    finally {
        $sha256.Dispose()
    }
    if (
        $sourceLines.Count -ne 49 -or
        $sourceManifestHash -ne '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477'
    ) {
        $errors.Add('source-ultimate content or paths changed.')
    }

    $policyText = Get-Content -LiteralPath $policyDocPath -Raw
    foreach ($requiredPhrase in @(
        'deny-by-default'
        'Unknown artifact'
        'SHA-256'
        'Authenticode'
        'explicit user confirmation'
        'ProcessStarted = false'
        'approves no real third-party artifact'
    )) {
        if ($policyText -notmatch [regex]::Escape($requiredPhrase)) {
            $errors.Add("Policy documentation is missing phrase: $requiredPhrase")
        }
    }
}
finally {
    Remove-Module -ModuleInfo $installerModule -Force -ErrorAction SilentlyContinue
    Remove-Module -ModuleInfo $downloadModule -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $tempRoot -PathType Container) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($errors.Count -gt 0) {
    throw "Download and installer policy validation failed:`r`n- $($errors -join "`r`n- ")"
}

[pscustomobject]@{
    Success                 = $true
    ProductionArtifactCount = 0
    RuntimeMirrorArtifactApprovals = $externalRuntimeArtifacts.Count
    MockArtifactVerified    = $true
    UnknownArtifactBlocked  = $true
    MissingHashBlocked      = $true
    MissingSignerBlocked    = $true
    HashMismatchBlocked     = $true
    ConfirmationRequired    = $true
    InstallerExecuted       = $false
    ImplementedModuleCount  = 35
    PlaceholderModuleCount = $inventoryBaseline.DeferredPlaceholders
    SourceUltimateUnchanged = $true
    Message                 = 'Download provenance and installer execution policies are valid and inert.'
    Timestamp               = Get-Date
}



