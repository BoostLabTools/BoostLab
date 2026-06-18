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
        throw 'Unable to determine the AppX package policy test path.'
    }
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
}
else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
}

$policyPath = Join-Path $ProjectRoot 'config\AppxPackagePolicy.psd1'
$inventoryModulePath = Join-Path $ProjectRoot 'core\AppxPackageInventory.psm1'
$executionModulePath = Join-Path $ProjectRoot 'core\AppxPackageExecution.psm1'
$policyDocPath = Join-Path $ProjectRoot 'docs\appx-package-inventory-restore.md'
$runtimeExecutionPath = Join-Path $ProjectRoot 'core\Execution.psm1'
$configPath = Join-Path $ProjectRoot 'config\Stages.psd1'
$modulesRoot = Join-Path $ProjectRoot 'modules'
$sourceRoot = Join-Path $ProjectRoot 'source-ultimate'

$errors = [System.Collections.Generic.List[string]]::new()
foreach ($requiredPath in @(
    $policyPath
    $inventoryModulePath
    $executionModulePath
    $policyDocPath
)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        $errors.Add("Required Phase 39 file is missing: $requiredPath")
    }
}
if ($errors.Count -gt 0) {
    throw "AppX package policy validation failed:`r`n- $($errors -join "`r`n- ")"
}

Import-Module `
    -Name $inventoryModulePath `
    -Force `
    -Scope Local `
    -ErrorAction Stop
Import-Module `
    -Name $executionModulePath `
    -Force `
    -Scope Local `
    -ErrorAction Stop

$tempRoot = Join-Path `
    ([IO.Path]::GetTempPath()) `
    ("BoostLab-AppxPolicyTest-{0}" -f [guid]::NewGuid())
$stateRoot = Join-Path $tempRoot 'State'
$mockInstallRoot = Join-Path $tempRoot 'MockPackage'
$mockManifestPath = Join-Path $mockInstallRoot 'AppxManifest.xml'
[IO.Directory]::CreateDirectory($mockInstallRoot) | Out-Null
[IO.File]::WriteAllText(
    $mockManifestPath,
    '<Package />',
    [Text.Encoding]::UTF8
)

try {
    foreach ($commandName in @(
        'Get-BoostLabAppxPackagePolicy'
        'Get-BoostLabAppxPackageStateRoot'
        'Test-BoostLabAppxPackagePolicy'
        'Test-BoostLabAppxPackageTarget'
        'New-BoostLabAppxInventoryRecord'
        'Save-BoostLabAppxInventoryRecord'
        'Import-BoostLabAppxInventoryRecord'
        'Test-BoostLabAppxInventoryRecord'
        'New-BoostLabAppxMutationPlan'
        'Set-BoostLabAppxInventoryMutationState'
        'Set-BoostLabAppxInventoryRestoreState'
        'New-BoostLabAppxRestorePlan'
        'Test-BoostLabAppxExecutionRequest'
        'Invoke-BoostLabAppxPackageMutation'
        'Test-BoostLabAppxRestoreExecutionRequest'
        'Invoke-BoostLabAppxPackageRestore'
    )) {
        if (-not (Get-Command -Name $commandName -ErrorAction SilentlyContinue)) {
            $errors.Add("Phase 39 helper is not exported: $commandName")
        }
    }

    $productionPolicy = Get-BoostLabAppxPackagePolicy -PolicyPath $policyPath
    $productionValidation = Test-BoostLabAppxPackagePolicy `
        -Policy $productionPolicy
    if (-not $productionValidation.IsValid) {
        $errors.Add(
            'Production AppX policy is invalid: ' +
            ($productionValidation.Errors -join '; ')
        )
    }
    if ($productionValidation.PackageScopeCount -ne 0) {
        $errors.Add('Phase 39 must not approve production AppX package scopes.')
    }

    $mockFamily = 'Contoso.MockApp_abcd1234'
    $testPolicy = @{
        SchemaVersion = '1.0'
        MaxRecordAgeDays = 30
        ProtectedPackageTokens = @(
            'MicrosoftEdge'
            'Microsoft.Win32WebViewHost'
            'Microsoft.WindowsStore'
            'Microsoft.StorePurchaseApp'
            'Microsoft.Windows.ShellExperienceHost'
            'Microsoft.Windows.StartMenuExperienceHost'
            'Microsoft.DesktopAppInstaller'
            'Microsoft.VCLibs'
            'Microsoft.UI.Xaml'
            'Microsoft.NET.Native'
            'Microsoft.WindowsAppRuntime'
        )
        PackageScopes = @(
            @{
                ScopeId = 'mock-current-user-package'
                ToolIds = @('mock-appx-tool')
                ActionIds = @('Apply', 'Restore')
                PackageFamilyNames = @($mockFamily)
                AllowedUserScopes = @('CurrentUser')
                AllowedMutations = @('RemoveCurrentUser', 'ReRegister')
                AllowProtectedPackages = $false
                AllowSystemPackages = $false
                AllowFrameworkPackages = $false
                AllowDependencyPackages = $false
                AllowAllUsersRemoval = $false
                AllowProvisionedRemoval = $false
                AllowRestore = $true
                NeedsExplicitConfirmation = $true
            }
            @{
                ScopeId = 'mock-provisioned-package'
                ToolIds = @('mock-appx-tool')
                ActionIds = @('Apply', 'Restore')
                PackageFamilyNames = @($mockFamily)
                AllowedUserScopes = @('ProvisionedImage')
                AllowedMutations = @(
                    'RemoveProvisioned'
                    'RestoreProvisioned'
                )
                AllowProtectedPackages = $false
                AllowSystemPackages = $false
                AllowFrameworkPackages = $false
                AllowDependencyPackages = $false
                AllowAllUsersRemoval = $false
                AllowProvisionedRemoval = $true
                AllowRestore = $true
                NeedsExplicitConfirmation = $true
            }
        )
    }
    $testPolicyValidation = Test-BoostLabAppxPackagePolicy -Policy $testPolicy
    if (
        -not $testPolicyValidation.IsValid -or
        $testPolicyValidation.PackageScopeCount -ne 2
    ) {
        $errors.Add(
            'Local mock AppX policy was rejected: ' +
            ($testPolicyValidation.Errors -join '; ')
        )
    }

    foreach ($family in @(
        ''
        '*'
        'Microsoft.*'
        'Microsoft'
        'Microsoft.Windows'
    )) {
        $target = Test-BoostLabAppxPackageTarget `
            -ToolId 'mock-appx-tool' `
            -ActionId 'Apply' `
            -ScopeId 'mock-current-user-package' `
            -PackageFamilyName $family `
            -UserScope CurrentUser `
            -IntendedMutation RemoveCurrentUser `
            -PackageSnapshot ([pscustomobject]@{}) `
            -Policy $testPolicy
        if ($target.IsAllowed) {
            $errors.Add("Broad or wildcard AppX family was allowed: '$family'")
        }
    }

    foreach ($family in @(
        'Microsoft.MicrosoftEdge_8wekyb3d8bbwe'
        'Microsoft.Win32WebViewHost_8wekyb3d8bbwe'
        'Microsoft.WindowsStore_8wekyb3d8bbwe'
        'Microsoft.Windows.ShellExperienceHost_cw5n1h2txyewy'
        'Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy'
        'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe'
        'Microsoft.VCLibs.140.00_8wekyb3d8bbwe'
        'Microsoft.UI.Xaml.2.8_8wekyb3d8bbwe'
    )) {
        $protectedPolicy = @{
            SchemaVersion = '1.0'
            MaxRecordAgeDays = 30
            ProtectedPackageTokens = $testPolicy.ProtectedPackageTokens
            PackageScopes = @(
                @{
                    ScopeId = 'protected-test'
                    ToolIds = @('mock-appx-tool')
                    ActionIds = @('Apply')
                    PackageFamilyNames = @($family)
                    AllowedUserScopes = @('CurrentUser')
                    AllowedMutations = @('RemoveCurrentUser')
                    AllowProtectedPackages = $false
                    AllowSystemPackages = $false
                    AllowFrameworkPackages = $false
                    AllowDependencyPackages = $false
                    AllowAllUsersRemoval = $false
                    AllowProvisionedRemoval = $false
                    AllowRestore = $false
                    NeedsExplicitConfirmation = $true
                }
            )
        }
        $protectedTarget = Test-BoostLabAppxPackageTarget `
            -ToolId 'mock-appx-tool' `
            -ActionId 'Apply' `
            -ScopeId 'protected-test' `
            -PackageFamilyName $family `
            -UserScope CurrentUser `
            -IntendedMutation RemoveCurrentUser `
            -PackageSnapshot ([pscustomobject]@{
                IsSystemCritical = $true
            }) `
            -Policy $protectedPolicy
        if ($protectedTarget.IsAllowed) {
            $errors.Add("Protected AppX package was allowed: $family")
        }
    }

    foreach ($classification in @(
        @{ Property = 'IsSystemCritical'; Label = 'system-critical' }
        @{ Property = 'IsFramework'; Label = 'framework' }
        @{ Property = 'IsDependency'; Label = 'dependency' }
    )) {
        $snapshot = [pscustomobject]@{
            IsSystemCritical = $false
            IsFramework = $false
            IsDependency = $false
        }
        $snapshot.($classification.Property) = $true
        $classifiedTarget = Test-BoostLabAppxPackageTarget `
            -ToolId 'mock-appx-tool' `
            -ActionId 'Apply' `
            -ScopeId 'mock-current-user-package' `
            -PackageFamilyName $mockFamily `
            -UserScope CurrentUser `
            -IntendedMutation RemoveCurrentUser `
            -PackageSnapshot $snapshot `
            -Policy $testPolicy
        if ($classifiedTarget.IsAllowed) {
            $errors.Add(
                "Unapproved $($classification.Label) package was allowed."
            )
        }
    }

    $allUsersTarget = Test-BoostLabAppxPackageTarget `
        -ToolId 'mock-appx-tool' `
        -ActionId 'Apply' `
        -ScopeId 'mock-current-user-package' `
        -PackageFamilyName $mockFamily `
        -UserScope AllUsers `
        -IntendedMutation RemoveAllUsers `
        -PackageSnapshot ([pscustomobject]@{}) `
        -Policy $testPolicy
    if ($allUsersTarget.IsAllowed) {
        $errors.Add('All-user removal did not require separate approval.')
    }

    $unapprovedProvisionedPolicy = @{
        SchemaVersion = '1.0'
        MaxRecordAgeDays = 30
        ProtectedPackageTokens = $testPolicy.ProtectedPackageTokens
        PackageScopes = @(
            @{
                ScopeId = 'provisioned-denied'
                ToolIds = @('mock-appx-tool')
                ActionIds = @('Apply')
                PackageFamilyNames = @($mockFamily)
                AllowedUserScopes = @('ProvisionedImage')
                AllowedMutations = @('RemoveProvisioned')
                AllowProtectedPackages = $false
                AllowSystemPackages = $false
                AllowFrameworkPackages = $false
                AllowDependencyPackages = $false
                AllowAllUsersRemoval = $false
                AllowProvisionedRemoval = $false
                AllowRestore = $false
                NeedsExplicitConfirmation = $true
            }
        )
    }
    $provisionedTarget = Test-BoostLabAppxPackageTarget `
        -ToolId 'mock-appx-tool' `
        -ActionId 'Apply' `
        -ScopeId 'provisioned-denied' `
        -PackageFamilyName $mockFamily `
        -UserScope ProvisionedImage `
        -IntendedMutation RemoveProvisioned `
        -PackageSnapshot ([pscustomobject]@{}) `
        -Policy $unapprovedProvisionedPolicy
    if ($provisionedTarget.IsAllowed) {
        $errors.Add('Provisioned removal did not require separate approval.')
    }

    $snapshot = [pscustomobject]@{
        PackageFamilyName = $mockFamily
        PackageFullName = 'Contoso.MockApp_1.2.3.4_x64__abcd1234'
        DisplayName = 'Contoso Mock App'
        Publisher = 'CN=Contoso'
        Version = '1.2.3.4'
        Architecture = 'x64'
        InstallLocation = $mockInstallRoot
        PackageStatus = 'Ok'
        ProvisionedPackageIdentity = ''
        Exists = $true
        IsInstalled = $true
        IsProvisioned = $false
        RegistrationManifestPath = $mockManifestPath
        Dependencies = @('Contoso.MockFramework_abcd1234')
        IsFramework = $false
        IsDependency = $false
        IsSystemCritical = $false
    }
    $inventoryResult = New-BoostLabAppxInventoryRecord `
        -ToolId 'mock-appx-tool' `
        -ActionId 'Apply' `
        -ScopeId 'mock-current-user-package' `
        -PackageFamilyName $mockFamily `
        -UserScope CurrentUser `
        -IntendedMutation RemoveCurrentUser `
        -PackageInspector { param($Family, $Scope) $snapshot } `
        -RollbackEligible:$true `
        -Policy $testPolicy
    if (
        -not $inventoryResult.Success -or
        $inventoryResult.Status -ne 'Captured' -or
        $inventoryResult.InventoryRecord.PackageFamilyName -ne $mockFamily -or
        -not $inventoryResult.InventoryRecord.OriginalInstalled -or
        -not $inventoryResult.InventoryRecord.RollbackEligible
    ) {
        $errors.Add('Mock AppX inventory capture did not return the required record.')
    }

    $requiredRecordFields = @(
        'OperationId'
        'ToolId'
        'ActionId'
        'Timestamp'
        'SchemaVersion'
        'BoostLabVersion'
        'PackageFamilyName'
        'PackageFullName'
        'DisplayName'
        'Publisher'
        'Version'
        'Architecture'
        'InstallLocation'
        'PackageStatus'
        'ProvisionedPackageIdentity'
        'UserScope'
        'OriginalExists'
        'OriginalInstalled'
        'OriginalProvisioned'
        'RegistrationManifestPath'
        'Dependencies'
        'IntendedMutation'
        'RollbackEligible'
        'VerificationRequired'
        'RiskClassification'
    )
    foreach ($field in $requiredRecordFields) {
        if (
            $null -eq
            $inventoryResult.InventoryRecord.PSObject.Properties[$field]
        ) {
            $errors.Add("AppX inventory record is missing required field: $field")
        }
    }

    $saved = Save-BoostLabAppxInventoryRecord `
        -Record $inventoryResult.InventoryRecord `
        -StateRoot $stateRoot
    $imported = Import-BoostLabAppxInventoryRecord `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot
    if (-not $imported.IsValid) {
        $errors.Add(
            'Saved AppX inventory record did not pass integrity validation: ' +
            ($imported.Errors -join '; ')
        )
    }

    $mutationPlan = New-BoostLabAppxMutationPlan `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-appx-tool' `
        -ActionId 'Apply' `
        -PackageFamilyName $mockFamily `
        -IntendedMutation RemoveCurrentUser `
        -Policy $testPolicy
    if (
        -not $mutationPlan.IsAllowed -or
        -not $mutationPlan.InventoryVerified -or
        -not $mutationPlan.IsDryRun -or
        -not $mutationPlan.RequiresExplicitConfirmation
    ) {
        $errors.Add(
            'Verified mock inventory did not produce an allowed dry-run plan: ' +
            ($mutationPlan.Errors -join '; ')
        )
    }

    $mutationState = [pscustomobject]@{ Called = $false }
    $mutationResult = Invoke-BoostLabAppxPackageMutation `
        -Plan $mutationPlan `
        -ActionPlan ([pscustomobject]@{
            ToolId = 'mock-appx-tool'
            Action = 'Apply'
            NeedsExplicitConfirmation = $true
        }) `
        -Confirmed:$true `
        -PackageMutator {
            param($Plan)
            $mutationState.Called = $true
            [pscustomobject]@{
                Success = $true
                PackageChanged = $true
            }
        } `
        -PackageVerifier {
            param($Plan, $MutationResult)
            [pscustomobject]@{
                Status = 'Passed'
                DetectedState = [pscustomobject]@{
                    Exists = $false
                    IsInstalled = $false
                    IsProvisioned = $false
                }
            }
        } `
        -StateRoot $stateRoot `
        -Policy $testPolicy
    if (
        -not $mutationResult.Success -or
        $mutationResult.Status -ne 'Completed' -or
        -not $mutationState.Called
    ) {
        $errors.Add('Mock AppX mutation boundary did not complete as expected.')
    }

    $recordAfterMutation = Import-BoostLabAppxInventoryRecord `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot
    if (
        -not $recordAfterMutation.IsValid -or
        -not [bool]$recordAfterMutation.Record.MutationRecorded
    ) {
        $errors.Add('Mock AppX mutation state was not persisted.')
    }

    $restorePlan = New-BoostLabAppxRestorePlan `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-appx-tool' `
        -ActionId 'Restore' `
        -SourceActionId 'Apply' `
        -RestoreMutation ReRegister `
        -ManifestInspector {
            param($Path)
            [pscustomobject]@{
                Exists = $true
                Path = $Path
            }
        } `
        -Policy $testPolicy
    if (
        -not $restorePlan.IsAllowed -or
        -not $restorePlan.IsDryRun -or
        -not $restorePlan.RequiresExplicitConfirmation
    ) {
        $errors.Add(
            'Verified mock record did not produce an allowed restore plan: ' +
            ($restorePlan.Errors -join '; ')
        )
    }

    $restoreState = [pscustomobject]@{ Called = $false }
    $restoreResult = Invoke-BoostLabAppxPackageRestore `
        -Plan $restorePlan `
        -ActionPlan ([pscustomobject]@{
            ToolId = 'mock-appx-tool'
            Action = 'Restore'
            NeedsExplicitConfirmation = $true
        }) `
        -Confirmed:$true `
        -RestoreExecutor {
            param($Plan)
            $restoreState.Called = $true
            [pscustomobject]@{
                Success = $true
                PackageChanged = $true
            }
        } `
        -RestoreVerifier {
            param($Plan, $RestoreResult)
            [pscustomobject]@{
                Status = 'Passed'
                DetectedState = [pscustomobject]@{
                    Exists = $true
                    IsInstalled = $true
                    IsProvisioned = $false
                }
            }
        } `
        -StateRoot $stateRoot `
        -ManifestInspector {
            param($Path)
            [pscustomobject]@{
                Exists = $true
                Path = $Path
            }
        } `
        -Policy $testPolicy
    if (
        -not $restoreResult.Success -or
        $restoreResult.Status -ne 'Restored' -or
        -not $restoreState.Called
    ) {
        $errors.Add('Mock AppX restore boundary did not complete as expected.')
    }

    $recordAfterRestore = Import-BoostLabAppxInventoryRecord `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot
    if (
        -not $recordAfterRestore.IsValid -or
        -not [bool]$recordAfterRestore.Record.RestoreRecorded
    ) {
        $errors.Add('Mock AppX restore state was not persisted.')
    }

    $noInventoryExecutorState = [pscustomobject]@{ Called = $false }
    $missingRecordPath = Join-Path $stateRoot 'Records\missing.json'
    $missingInventoryPlan = New-BoostLabAppxMutationPlan `
        -RecordPath $missingRecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-appx-tool' `
        -ActionId 'Apply' `
        -PackageFamilyName $mockFamily `
        -IntendedMutation RemoveCurrentUser `
        -Policy $testPolicy
    $missingInventoryResult = Invoke-BoostLabAppxPackageMutation `
        -Plan $missingInventoryPlan `
        -ActionPlan ([pscustomobject]@{
            ToolId = 'mock-appx-tool'
            Action = 'Apply'
            NeedsExplicitConfirmation = $true
        }) `
        -Confirmed:$true `
        -PackageMutator {
            param($Plan)
            $noInventoryExecutorState.Called = $true
            [pscustomobject]@{
                Success = $true
                PackageChanged = $true
            }
        } `
        -PackageVerifier {
            [pscustomobject]@{ Status = 'Passed' }
        } `
        -StateRoot $stateRoot `
        -Policy $testPolicy
    if (
        $missingInventoryPlan.IsAllowed -or
        $missingInventoryResult.Status -ne 'Blocked' -or
        $noInventoryExecutorState.Called
    ) {
        $errors.Add('Package mutation without inventory was not blocked.')
    }

    $missingRestorePlan = New-BoostLabAppxRestorePlan `
        -RecordPath $missingRecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-appx-tool' `
        -ActionId 'Restore' `
        -SourceActionId 'Apply' `
        -RestoreMutation ReRegister `
        -ManifestInspector {
            [pscustomobject]@{ Exists = $false; Path = '' }
        } `
        -Policy $testPolicy
    if ($missingRestorePlan.IsAllowed) {
        $errors.Add('Package restore without an inventory record was not blocked.')
    }

    $missingManifestPlan = New-BoostLabAppxRestorePlan `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'mock-appx-tool' `
        -ActionId 'Restore' `
        -SourceActionId 'Apply' `
        -RestoreMutation ReRegister `
        -ManifestInspector {
            param($Path)
            [pscustomobject]@{ Exists = $false; Path = $Path }
        } `
        -Policy $testPolicy
    if ($missingManifestPlan.IsAllowed) {
        $errors.Add('Restore with a missing package manifest was not blocked.')
    }

    $mismatchedPlan = New-BoostLabAppxMutationPlan `
        -RecordPath $saved.RecordPath `
        -StateRoot $stateRoot `
        -ToolId 'different-tool' `
        -ActionId 'Apply' `
        -PackageFamilyName $mockFamily `
        -IntendedMutation RemoveCurrentUser `
        -Policy $testPolicy
    if ($mismatchedPlan.IsAllowed) {
        $errors.Add('Mismatched AppX inventory identity was not blocked.')
    }

    $staleRecord = $inventoryResult.InventoryRecord |
        Select-Object *
    $staleRecord.Timestamp = (Get-Date).AddDays(-45).ToUniversalTime().ToString('o')
    $staleRecord.OperationId = [guid]::NewGuid().ToString()
    $staleSaved = Save-BoostLabAppxInventoryRecord `
        -Record $staleRecord `
        -StateRoot $stateRoot
    $staleImported = Import-BoostLabAppxInventoryRecord `
        -RecordPath $staleSaved.RecordPath `
        -StateRoot $stateRoot
    $staleValidation = Test-BoostLabAppxInventoryRecord `
        -Record $staleImported.Record `
        -ExpectedToolId 'mock-appx-tool' `
        -ExpectedActionId 'Apply' `
        -Policy $testPolicy
    if ($staleValidation.IsValid) {
        $errors.Add('Stale AppX inventory record was not blocked.')
    }

    $corruptPath = Join-Path $stateRoot 'Records\corrupt.json'
    Copy-Item -LiteralPath $saved.RecordPath -Destination $corruptPath
    $corruptText = Get-Content -LiteralPath $corruptPath -Raw
    $corruptText = $corruptText.Replace(
        'Contoso Mock App',
        'Changed Mock App'
    )
    Set-Content -LiteralPath $corruptPath -Value $corruptText -Encoding UTF8
    $corruptImported = Import-BoostLabAppxInventoryRecord `
        -RecordPath $corruptPath `
        -StateRoot $stateRoot
    if ($corruptImported.IsValid) {
        $errors.Add('Corrupt AppX inventory record was not blocked.')
    }

    $productionExecutorState = [pscustomobject]@{ Called = $false }
    $productionCapture = New-BoostLabAppxInventoryRecord `
        -ToolId 'mock-appx-tool' `
        -ActionId 'Apply' `
        -ScopeId 'not-approved' `
        -PackageFamilyName $mockFamily `
        -UserScope CurrentUser `
        -IntendedMutation RemoveCurrentUser `
        -PackageInspector { param($Family, $Scope) $snapshot } `
        -Policy $productionPolicy
    if (
        $productionCapture.Success -or
        $productionCapture.Status -ne 'Blocked'
    ) {
        $errors.Add('Empty production AppX scopes did not deny inventory use.')
    }
    $productionPlan = [pscustomobject]@{
        IsAllowed = $false
        Status = 'Blocked'
        IsDryRun = $true
        RequiresExplicitConfirmation = $true
        InventoryVerified = $false
        Errors = @('No production scope.')
        OperationId = ''
        ToolId = 'mock-appx-tool'
        ActionId = 'Apply'
        PackageFamilyName = $mockFamily
    }
    $productionResult = Invoke-BoostLabAppxPackageMutation `
        -Plan $productionPlan `
        -ActionPlan ([pscustomobject]@{
            ToolId = 'mock-appx-tool'
            Action = 'Apply'
            NeedsExplicitConfirmation = $true
        }) `
        -Confirmed:$true `
        -PackageMutator {
            $productionExecutorState.Called = $true
            [pscustomobject]@{
                Success = $true
                PackageChanged = $true
            }
        } `
        -PackageVerifier {
            [pscustomobject]@{ Status = 'Passed' }
        } `
        -StateRoot $stateRoot
    if (
        $productionResult.Status -ne 'Blocked' -or
        $productionResult.PackageChanged -or
        $productionExecutorState.Called
    ) {
        $errors.Add('Production AppX execution helper was not inert by default.')
    }

    foreach ($corePath in @($inventoryModulePath, $executionModulePath)) {
        $tokens = $null
        $parseErrors = $null
        $ast = [Management.Automation.Language.Parser]::ParseFile(
            $corePath,
            [ref]$tokens,
            [ref]$parseErrors
        )
        if (@($parseErrors).Count -gt 0) {
            $errors.Add(
                "PowerShell parser errors in $corePath`: " +
                (@($parseErrors) -join '; ')
            )
        }
        $commandNames = @(
            $ast.FindAll(
                {
                    param($Node)
                    $Node -is [Management.Automation.Language.CommandAst]
                },
                $true
            ) |
                ForEach-Object { $_.GetCommandName() } |
                Where-Object { $_ }
        )
        foreach ($forbiddenCommand in @(
            'Get-AppxPackage'
            'Remove-AppxPackage'
            'Add-AppxPackage'
            'Get-AppxProvisionedPackage'
            'Remove-AppxProvisionedPackage'
            'Add-AppxProvisionedPackage'
            'dism.exe'
        )) {
            if ($forbiddenCommand -in $commandNames) {
                $errors.Add(
                    "Phase 39 core helper contains real package command: " +
                    "$forbiddenCommand"
                )
            }
        }
    }

    $runtimeText = Get-Content -LiteralPath $runtimeExecutionPath -Raw
    if (
        $runtimeText.Contains('AppxPackageInventory.psm1') -or
        $runtimeText.Contains('AppxPackageExecution.psm1')
    ) {
        $errors.Add('Phase 39 AppX helpers were wired into production execution.')
    }

    $config = Import-PowerShellDataFile -LiteralPath $configPath
    $allTools = @($config.Stages | ForEach-Object { $_.Tools })
    $placeholderModules = @(
        Get-ChildItem -Path $modulesRoot -Recurse -Filter '*.psm1' |
            Where-Object {
                (Get-Content -LiteralPath $_.FullName -Raw).Contains(
                    'ToolModule.Placeholder.ps1'
                )
            }
    )
    if ($allTools.Count -ne 55) {
        $errors.Add("Expected 55 active tools, found $($allTools.Count).")
    }
    if ($placeholderModules.Count -ne 17) {
        $errors.Add(
            "Expected 17 placeholder modules, found $($placeholderModules.Count)."
        )
    }
    if (($allTools.Count - $placeholderModules.Count) -ne 38) {
        $errors.Add('Implemented tool count changed from 30.')
    }
    foreach ($deletedTool in @('Loudness EQ', 'NVME Faster Driver')) {
        if ($deletedTool -in @($allTools.Title)) {
            $errors.Add("Deleted tool was reintroduced: $deletedTool")
        }
    }

    $root = (Resolve-Path -LiteralPath $ProjectRoot).Path
    $sourceLines = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File | Where-Object { $_.FullName -notlike (Join-Path $sourceRoot '_intake-promoted*') } |
        Sort-Object {
            $_.FullName.Substring($root.Length + 1).Replace('\', '/')
        } |
        ForEach-Object {
            '{0}|{1}' -f `
                $_.FullName.Substring($root.Length + 1).Replace('\', '/'), `
                (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
        }
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $manifestHash = [BitConverter]::ToString(
            $sha256.ComputeHash(
                [Text.Encoding]::UTF8.GetBytes(($sourceLines -join "`n"))
            )
        ).Replace('-', '')
    }
    finally {
        $sha256.Dispose()
    }
    if (
        @($sourceLines).Count -ne 49 -or
        $manifestHash -ne
        '4804366AADB45394EB3E8A850258A7C8F33BCA10D97D1DEB0D1548D904DE2477'
    ) {
        $errors.Add('source-ultimate content or paths changed.')
    }
}
finally {
    Remove-Module AppxPackageExecution -ErrorAction SilentlyContinue
    Remove-Module AppxPackageInventory -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}

if ($errors.Count -gt 0) {
    throw "AppX package policy validation failed:`r`n- $($errors -join "`r`n- ")"
}

[pscustomobject]@{
    Success                 = $true
    ProductionScopeCount    = 0
    MockInventoryCaptured   = $true
    MockMutationVerified    = $true
    MockRestoreVerified     = $true
    ActiveToolCount         = 55
    ImplementedToolCount    = 38
    PlaceholderToolCount    = 17
    SourceUltimateUnchanged = $true
    Message                 = 'AppX package inventory and restore foundation is deny-by-default and callback-only.'
    Timestamp               = Get-Date
}



