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
            'Invoke-WebRequest'
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



