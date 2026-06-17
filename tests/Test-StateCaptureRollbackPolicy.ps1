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
        throw 'Unable to determine the state capture policy test path.'
    }

    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$policyPath = Join-Path $ProjectRoot 'config\RollbackPolicy.psd1'
$captureModulePath = Join-Path $ProjectRoot 'core\StateCapture.psm1'
$rollbackModulePath = Join-Path $ProjectRoot 'core\Rollback.psm1'
$executionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$policyDocPath = Join-Path $ProjectRoot 'docs\file-registry-state-capture-rollback.md'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$errors = [System.Collections.Generic.List[string]]::new()
foreach ($requiredPath in @(
    $policyPath
    $captureModulePath
    $rollbackModulePath
    $policyDocPath
)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        $errors.Add("Required Phase 36 file is missing: $requiredPath")
    }
}
if ($errors.Count -gt 0) {
    throw "State capture policy validation failed:`r`n- $($errors -join "`r`n- ")"
}

$captureModule = Import-Module `
    -Name $captureModulePath `
    -Force `
    -PassThru `
    -Scope Local `
    -ErrorAction Stop
$rollbackModule = Import-Module `
    -Name $rollbackModulePath `
    -Force `
    -PassThru `
    -Scope Local `
    -ErrorAction Stop

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("BoostLab-RollbackTest-{0}" -f [guid]::NewGuid())
$targetRoot = Join-Path $tempRoot 'Targets'
$stateRoot = Join-Path $tempRoot 'State'
[IO.Directory]::CreateDirectory($targetRoot) | Out-Null

try {
    foreach ($commandName in @(
        'Get-BoostLabRollbackPolicy'
        'Get-BoostLabRollbackStateRoot'
        'Test-BoostLabRollbackPolicy'
        'Test-BoostLabFileCaptureTarget'
        'Test-BoostLabRegistryCaptureTarget'
        'Test-BoostLabRollbackRecord'
        'Save-BoostLabRollbackRecord'
        'Import-BoostLabRollbackRecord'
        'New-BoostLabFileStateCapture'
        'New-BoostLabRegistryStateCapture'
        'Set-BoostLabRollbackMutationState'
        'Invoke-BoostLabFileRollback'
        'Invoke-BoostLabRegistryRollback'
    )) {
        if (-not (Get-Command -Name $commandName -ErrorAction SilentlyContinue)) {
            $errors.Add("Phase 36 helper is not exported: $commandName")
        }
    }

    $productionPolicy = Get-BoostLabRollbackPolicy -PolicyPath $policyPath
    $productionValidation = Test-BoostLabRollbackPolicy -Policy $productionPolicy
    if (-not $productionValidation.IsValid) {
        $errors.Add("Production rollback policy is invalid: $($productionValidation.Errors -join '; ')")
    }
    if (
        $productionValidation.FileScopeCount -ne 0 -or
        $productionValidation.RegistryScopeCount -ne 0
    ) {
        $errors.Add('Phase 36 must not approve production file or registry scopes.')
    }

    $testRegistryPath = 'HKCU:\Software\BoostLab\Tests\Phase36'
    $testPolicy = @{
        SchemaVersion = '1.0'
        FileScopes = @(
            @{
                ScopeId         = 'local-test-files'
                ToolIds        = @('mock-tool')
                AllowedRoot    = $targetRoot
                AllowDirectories = $true
                MaxFiles       = 25
                MaxBytes       = 1048576
            }
        )
        RegistryScopes = @(
            @{
                ScopeId             = 'local-test-registry'
                ToolIds            = @('mock-tool')
                AllowedPath        = $testRegistryPath
                AllowedValueNames  = @('TestValue')
                AllowKeyCapture    = $false
                AllowProtectedSystem = $false
            }
        )
        DeniedRegistryPrefixes = @(
            'HKLM:\SYSTEM'
            'Registry::HKEY_LOCAL_MACHINE\SYSTEM'
        )
    }
    $testPolicyValidation = Test-BoostLabRollbackPolicy -Policy $testPolicy
    if (
        -not $testPolicyValidation.IsValid -or
        $testPolicyValidation.FileScopeCount -ne 1 -or
        $testPolicyValidation.RegistryScopeCount -ne 1
    ) {
        $errors.Add("Local mock rollback policy was rejected: $($testPolicyValidation.Errors -join '; ')")
    }

    $missingScope = Test-BoostLabFileCaptureTarget `
        -ToolId 'mock-tool' `
        -ScopeId 'not-approved' `
        -TargetPath (Join-Path $targetRoot 'missing.txt') `
        -ItemType File `
        -Policy $testPolicy
    if ($missingScope.IsAllowed -or $missingScope.Status -ne 'Blocked') {
        $errors.Add('File capture without an approved scope was not denied.')
    }

    $relativeTarget = Test-BoostLabFileCaptureTarget `
        -ToolId 'mock-tool' `
        -ScopeId 'local-test-files' `
        -TargetPath 'relative.txt' `
        -ItemType File `
        -Policy $testPolicy
    if ($relativeTarget.IsAllowed) {
        $errors.Add('Relative file capture target was not denied.')
    }

    $broadFilePolicy = @{
        SchemaVersion = '1.0'
        FileScopes = @(
            @{
                ScopeId         = 'broad-root'
                ToolIds        = @('mock-tool')
                AllowedRoot    = 'C:\'
                AllowDirectories = $true
                MaxFiles       = 100
                MaxBytes       = 1048576
            }
        )
        RegistryScopes = @()
        DeniedRegistryPrefixes = @('HKLM:\SYSTEM')
    }
    $broadFileTarget = Test-BoostLabFileCaptureTarget `
        -ToolId 'mock-tool' `
        -ScopeId 'broad-root' `
        -TargetPath 'C:\' `
        -ItemType Directory `
        -Policy $broadFilePolicy
    if ($broadFileTarget.IsAllowed -or $broadFileTarget.Status -ne 'Blocked') {
        $errors.Add('Broad drive-root file capture was not denied.')
    }

    $wildcardTarget = Test-BoostLabFileCaptureTarget `
        -ToolId 'mock-tool' `
        -ScopeId 'local-test-files' `
        -TargetPath (Join-Path $targetRoot '*.txt') `
        -ItemType File `
        -Policy $testPolicy
    if ($wildcardTarget.IsAllowed) {
        $errors.Add('Wildcard file capture was not denied.')
    }

    $filePath = Join-Path $targetRoot 'sample.txt'
    [IO.File]::WriteAllText($filePath, 'captured original state', [Text.Encoding]::UTF8)
    $originalFileHash = (Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash
    $fileCapture = New-BoostLabFileStateCapture `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -ScopeId 'local-test-files' `
        -TargetPath $filePath `
        -ItemType File `
        -IntendedMutation Overwrite `
        -RiskClassification Medium `
        -Policy $testPolicy `
        -StateRoot $stateRoot
    if (
        -not $fileCapture.Success -or
        $fileCapture.Status -ne 'Captured' -or
        -not $fileCapture.BackupCreated -or
        -not (Test-Path -LiteralPath $fileCapture.RecordPath -PathType Leaf)
    ) {
        $errors.Add("Local file capture failed: $($fileCapture.Errors -join '; ')")
    }
    foreach ($requiredField in @(
        'OperationId'
        'ToolId'
        'ActionId'
        'Timestamp'
        'SchemaVersion'
        'BoostLabVersion'
        'SourcePath'
        'ItemType'
        'OriginalExists'
        'OriginalMetadata'
        'OriginalHash'
        'BackupLocation'
        'IntendedMutation'
        'RollbackEligible'
        'VerificationRequirement'
        'RiskClassification'
    )) {
        if ($null -eq $fileCapture.Record.PSObject.Properties[$requiredField]) {
            $errors.Add("Captured rollback record is missing field: $requiredField")
        }
    }
    if (
        $fileCapture.Record.OriginalHash -ne $originalFileHash -or
        $fileCapture.Record.BackupHash -ne $originalFileHash
    ) {
        $errors.Add('File capture did not preserve matching original and backup hashes.')
    }

    $missingRecord = Invoke-BoostLabFileRollback `
        -RecordPath (Join-Path $stateRoot 'Records\missing.json') `
        -StateRoot $stateRoot `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -Policy $testPolicy
    if (
        $missingRecord.Success -or
        $missingRecord.Status -ne 'Blocked' -or
        $missingRecord.RestoreAttempted
    ) {
        $errors.Add('Missing rollback record was not denied before restore.')
    }

    $corruptRecordPath = Join-Path $stateRoot 'Records\corrupt.json'
    [IO.File]::WriteAllText($corruptRecordPath, '{not-json', [Text.Encoding]::UTF8)
    $corruptRecord = Import-BoostLabRollbackRecord `
        -RecordPath $corruptRecordPath `
        -StateRoot $stateRoot
    if ($corruptRecord.IsValid -or $corruptRecord.Status -ne 'Blocked') {
        $errors.Add('Corrupt rollback record was not denied.')
    }

    [IO.File]::WriteAllText($filePath, 'first mutation', [Text.Encoding]::UTF8)
    $firstMutationHash = (Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash
    $mutationRecorded = Set-BoostLabRollbackMutationState `
        -RecordPath $fileCapture.RecordPath `
        -StateRoot $stateRoot `
        -PostMutationExists $true `
        -PostMutationHash $firstMutationHash
    if (-not $mutationRecorded.Success) {
        $errors.Add("Post-mutation file state was not recorded: $($mutationRecorded.Errors -join '; ')")
    }

    [IO.File]::WriteAllText($fileCapture.Record.BackupLocation, 'tampered backup', [Text.Encoding]::UTF8)
    $tamperedBackupResult = Invoke-BoostLabFileRollback `
        -RecordPath $fileCapture.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -Policy $testPolicy
    if (
        $tamperedBackupResult.Success -or
        $tamperedBackupResult.Status -ne 'Blocked' -or
        $tamperedBackupResult.RestoreAttempted
    ) {
        $errors.Add('Hash-mismatched backup was not denied before restore.')
    }
    if ((Get-Content -LiteralPath $filePath -Raw) -ne 'first mutation') {
        $errors.Add('Blocked backup mismatch altered the target file.')
    }

    $restoreFilePath = Join-Path $targetRoot 'restore-sample.txt'
    [IO.File]::WriteAllText($restoreFilePath, 'restore original', [Text.Encoding]::UTF8)
    $capturedLastWriteTime = [datetime]'2025-01-02T03:04:05Z'
    [IO.File]::SetLastWriteTimeUtc($restoreFilePath, $capturedLastWriteTime)
    $restoreCapture = New-BoostLabFileStateCapture `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -ScopeId 'local-test-files' `
        -TargetPath $restoreFilePath `
        -ItemType File `
        -IntendedMutation Overwrite `
        -RiskClassification Medium `
        -Policy $testPolicy `
        -StateRoot $stateRoot
    [IO.File]::WriteAllText($restoreFilePath, 'approved mutation', [Text.Encoding]::UTF8)
    $restoreMutationHash = (Get-FileHash -LiteralPath $restoreFilePath -Algorithm SHA256).Hash
    Set-BoostLabRollbackMutationState `
        -RecordPath $restoreCapture.RecordPath `
        -StateRoot $stateRoot `
        -PostMutationExists $true `
        -PostMutationHash $restoreMutationHash | Out-Null

    $wrongIdentityResult = Invoke-BoostLabFileRollback `
        -RecordPath $restoreCapture.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'wrong-tool' `
        -ActionId 'Apply' `
        -Policy $testPolicy
    if (
        $wrongIdentityResult.Success -or
        $wrongIdentityResult.Status -ne 'Blocked' -or
        $wrongIdentityResult.RestoreAttempted
    ) {
        $errors.Add('Mismatched tool identity did not block file rollback.')
    }

    $fileRollback = Invoke-BoostLabFileRollback `
        -RecordPath $restoreCapture.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -Policy $testPolicy
    if (
        -not $fileRollback.Success -or
        $fileRollback.Status -ne 'Restored' -or
        -not $fileRollback.RestoreAttempted -or
        $fileRollback.Verification.Status -ne 'Passed'
    ) {
        $errors.Add("Verified local file rollback failed: $($fileRollback.Errors -join '; ')")
    }
    if ((Get-Content -LiteralPath $restoreFilePath -Raw) -ne 'restore original') {
        $errors.Add('Verified file rollback did not restore the original content.')
    }
    if (
        [IO.File]::GetLastWriteTimeUtc($restoreFilePath) -ne
        $capturedLastWriteTime.ToUniversalTime()
    ) {
        $errors.Add('Verified file rollback did not restore captured file metadata.')
    }

    $directoryPath = Join-Path $targetRoot 'BoundedDirectory'
    [IO.Directory]::CreateDirectory($directoryPath) | Out-Null
    [IO.File]::WriteAllText(
        (Join-Path $directoryPath 'one.txt'),
        'bounded directory content',
        [Text.Encoding]::UTF8
    )
    $directoryCapture = New-BoostLabFileStateCapture `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -ScopeId 'local-test-files' `
        -TargetPath $directoryPath `
        -ItemType Directory `
        -IntendedMutation Delete `
        -RiskClassification Medium `
        -Policy $testPolicy `
        -StateRoot $stateRoot
    if (
        -not $directoryCapture.Success -or
        $directoryCapture.Status -ne 'Captured' -or
        -not $directoryCapture.BackupCreated -or
        $directoryCapture.Record.OriginalMetadata.FileCount -ne 1
    ) {
        $errors.Add("Bounded directory capture failed: $($directoryCapture.Errors -join '; ')")
    }

    $broadRegistryPolicy = @{
        SchemaVersion = '1.0'
        FileScopes = @()
        RegistryScopes = @(
            @{
                ScopeId             = 'broad-registry'
                ToolIds            = @('mock-tool')
                AllowedPath        = 'HKCU:\'
                AllowedValueNames  = @('TestValue')
                AllowKeyCapture    = $false
                AllowProtectedSystem = $false
            }
        )
        DeniedRegistryPrefixes = @('HKLM:\SYSTEM')
    }
    $broadRegistryTarget = Test-BoostLabRegistryCaptureTarget `
        -ToolId 'mock-tool' `
        -ScopeId 'broad-registry' `
        -RegistryPath 'HKCU:\' `
        -ItemType RegistryValue `
        -ValueName 'TestValue' `
        -Policy $broadRegistryPolicy
    if ($broadRegistryTarget.IsAllowed) {
        $errors.Add('Broad registry hive capture was not denied.')
    }

    $protectedRegistryPolicy = @{
        SchemaVersion = '1.0'
        FileScopes = @()
        RegistryScopes = @(
            @{
                ScopeId             = 'protected-registry'
                ToolIds            = @('mock-tool')
                AllowedPath        = 'HKLM:\SYSTEM\CurrentControlSet\Control\Mock'
                AllowedValueNames  = @('TestValue')
                AllowKeyCapture    = $false
                AllowProtectedSystem = $false
            }
        )
        DeniedRegistryPrefixes = @('HKLM:\SYSTEM')
    }
    $protectedRegistryTarget = Test-BoostLabRegistryCaptureTarget `
        -ToolId 'mock-tool' `
        -ScopeId 'protected-registry' `
        -RegistryPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Mock' `
        -ItemType RegistryValue `
        -ValueName 'TestValue' `
        -Policy $protectedRegistryPolicy
    if ($protectedRegistryTarget.IsAllowed) {
        $errors.Add('Protected HKLM SYSTEM registry capture was not denied.')
    }

    $unapprovedValue = Test-BoostLabRegistryCaptureTarget `
        -ToolId 'mock-tool' `
        -ScopeId 'local-test-registry' `
        -RegistryPath $testRegistryPath `
        -ItemType RegistryValue `
        -ValueName 'OtherValue' `
        -Policy $testPolicy
    if ($unapprovedValue.IsAllowed) {
        $errors.Add('Registry value outside the exact allowlist was not denied.')
    }

    $registryStore = @{
        Exists = $true
        Metadata = [ordered]@{
            ValueName = 'TestValue'
            ValueType = 'DWord'
            ValueData = 1
        }
    }
    $registryReader = {
        param($RegistryPath, $ItemType, $ValueName)

        return [pscustomobject]@{
            Exists  = [bool]$registryStore.Exists
            Metadata = $registryStore.Metadata
        }
    }.GetNewClosure()
    $registryWriter = {
        param($RegistryPath, $ItemType, $ValueName, $Metadata)

        $registryStore.Exists = $true
        $registryStore.Metadata = $Metadata
    }.GetNewClosure()
    $registryRemover = {
        param($RegistryPath, $ItemType, $ValueName)

        $registryStore.Exists = $false
        $registryStore.Metadata = $null
    }.GetNewClosure()

    $registryCapture = New-BoostLabRegistryStateCapture `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -ScopeId 'local-test-registry' `
        -RegistryPath $testRegistryPath `
        -ItemType RegistryValue `
        -ValueName 'TestValue' `
        -IntendedMutation RegistrySet `
        -Policy $testPolicy `
        -RegistryReader $registryReader `
        -StateRoot $stateRoot
    if (
        -not $registryCapture.Success -or
        $registryCapture.Status -ne 'Captured' -or
        $registryCapture.Record.OriginalMetadata.ValueType -ne 'DWord' -or
        $registryCapture.Record.OriginalMetadata.ValueData -ne 1
    ) {
        $errors.Add("Mocked registry capture failed: $($registryCapture.Errors -join '; ')")
    }

    $registryStore.Exists = $true
    $registryStore.Metadata = [ordered]@{
        ValueName = 'TestValue'
        ValueType = 'DWord'
        ValueData = 2
    }
    Set-BoostLabRollbackMutationState `
        -RecordPath $registryCapture.RecordPath `
        -StateRoot $stateRoot `
        -PostMutationExists $true `
        -PostMutationMetadata $registryStore.Metadata | Out-Null

    $registryRollback = Invoke-BoostLabRegistryRollback `
        -RecordPath $registryCapture.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-tool' `
        -ActionId 'Apply' `
        -RegistryReader $registryReader `
        -RegistryWriter $registryWriter `
        -RegistryRemover $registryRemover `
        -Policy $testPolicy
    if (
        -not $registryRollback.Success -or
        $registryRollback.Status -ne 'Restored' -or
        -not $registryRollback.RestoreAttempted -or
        $registryStore.Metadata.ValueData -ne 1
    ) {
        $errors.Add("Mocked registry rollback failed: $($registryRollback.Errors -join '; ')")
    }

    foreach ($modulePath in @($captureModulePath, $rollbackModulePath)) {
        $tokens = $null
        $parseErrors = $null
        [System.Management.Automation.Language.Parser]::ParseFile(
            $modulePath,
            [ref]$tokens,
            [ref]$parseErrors
        ) | Out-Null
        if (@($parseErrors).Count -gt 0) {
            $errors.Add("$modulePath has a syntax error: $($parseErrors[0].Message)")
        }
    }

    $executionSource = Get-Content -LiteralPath $executionPath -Raw
    foreach ($newHelperName in @(
        'StateCapture.psm1'
        'Rollback.psm1'
        'New-BoostLabFileStateCapture'
        'Invoke-BoostLabFileRollback'
        'Invoke-BoostLabRegistryRollback'
    )) {
        if ($executionSource.Contains($newHelperName)) {
            $errors.Add("Existing tool runtime was wired to the Phase 36 helper: $newHelperName")
        }
    }
    $approvedPhase36CaptureConsumers = @(
        Join-Path $modulesRoot 'Windows\write-cache-buffer-flushing.psm1'
    )
    foreach ($module in Get-ChildItem -LiteralPath $modulesRoot -Recurse -File -Filter '*.psm1') {
        $moduleSource = Get-Content -LiteralPath $module.FullName -Raw
        $isApprovedCaptureConsumer = $module.FullName -in $approvedPhase36CaptureConsumers
        if (
            $isApprovedCaptureConsumer -and
            (
                $moduleSource.Contains('New-BoostLabFileStateCapture') -or
                $moduleSource.Contains('Invoke-BoostLabFileRollback') -or
                $moduleSource.Contains('Invoke-BoostLabRegistryRollback')
            )
        ) {
            $errors.Add("Approved Phase 36 capture consumer used rollback or file-capture behavior: $($module.FullName)")
        }
        if (
            -not $isApprovedCaptureConsumer -and
            (
                $moduleSource.Contains('New-BoostLabFileStateCapture') -or
                $moduleSource.Contains('New-BoostLabRegistryStateCapture') -or
                $moduleSource.Contains('Invoke-BoostLabFileRollback') -or
                $moduleSource.Contains('Invoke-BoostLabRegistryRollback')
            )
        ) {
            $errors.Add("Tool module was wired to the Phase 36 foundation: $($module.FullName)")
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
        $allModules.Count -ne 49 -or
        $implementedModules.Count -ne 31 -or
        $placeholderModules.Count -ne 18
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
        'Default Versus Restore'
        'Production `FileScopes` and `RegistryScopes` are empty'
        'Broad hive roots are denied'
        'Backup hash'
        'post-mutation state'
        'does not add a Restore action to any tool'
    )) {
        if (-not $policyText.Contains($requiredPhrase)) {
            $errors.Add("Rollback policy documentation is missing phrase: $requiredPhrase")
        }
    }
}
finally {
    Remove-Module -ModuleInfo $rollbackModule -Force -ErrorAction SilentlyContinue
    Remove-Module -ModuleInfo $captureModule -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $tempRoot -PathType Container) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($errors.Count -gt 0) {
    throw "State capture policy validation failed:`r`n- $($errors -join "`r`n- ")"
}

[pscustomobject]@{
    Success                  = $true
    ProductionFileScopes     = 0
    ProductionRegistryScopes = 0
    FileCapturePassed        = $true
    FileRollbackPassed       = $true
    HashMismatchBlocked      = $true
    MissingRecordBlocked     = $true
    CorruptRecordBlocked     = $true
    BroadFileRootBlocked     = $true
    BroadRegistryHiveBlocked = $true
    ProtectedHklmBlocked     = $true
    MockRegistryRollbackPassed = $true
    ImplementedModuleCount   = 31
    PlaceholderModuleCount   = 18
    SourceUltimateUnchanged  = $true
    Message                  = 'File and registry state capture and rollback policy is bounded and deny-by-default.'
    Timestamp                = Get-Date
}

