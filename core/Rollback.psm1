Set-StrictMode -Version Latest

if (-not (Get-Command -Name 'Import-BoostLabRollbackRecord' -ErrorAction SilentlyContinue)) {
    Import-Module `
        -Name (Join-Path $PSScriptRoot 'StateCapture.psm1') `
        -Scope Local `
        -ErrorAction Stop
}

function Get-BoostLabRollbackPropertyValue {
    param(
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string]$Name
    )

    if ($null -eq $InputObject) {
        return $null
    }
    if ($InputObject -is [System.Collections.IDictionary]) {
        if ($InputObject.Contains($Name)) {
            return $InputObject[$Name]
        }

        return $null
    }

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

function ConvertTo-BoostLabRollbackFullPath {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw 'A non-empty path is required.'
    }
    if ($Path.IndexOfAny([char[]]'*?[]') -ge 0) {
        throw 'Wildcard paths are not allowed.'
    }
    if (-not [IO.Path]::IsPathRooted($Path)) {
        throw 'An absolute path is required.'
    }

    return [IO.Path]::GetFullPath($Path).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
}

function Test-BoostLabRollbackPathWithinRoot {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Root
    )

    $fullPath = ConvertTo-BoostLabRollbackFullPath -Path $Path
    $fullRoot = ConvertTo-BoostLabRollbackFullPath -Path $Root
    if ($fullPath.Equals($fullRoot, [StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    return $fullPath.StartsWith(
        $fullRoot + [IO.Path]::DirectorySeparatorChar,
        [StringComparison]::OrdinalIgnoreCase
    )
}

function Get-BoostLabRollbackFileState {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [ValidateSet('File', 'Directory')]
        [string]$ItemType
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{
            Exists = $false
            Hash   = ''
        }
    }

    $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'Rollback target contains a reparse point.'
    }
    if (($ItemType -eq 'Directory') -ne [bool]$item.PSIsContainer) {
        throw 'Rollback target item type does not match its record.'
    }
    if ($ItemType -eq 'File') {
        return [pscustomobject]@{
            Exists = $true
            Hash   = (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash
        }
    }

    $entries = [System.Collections.Generic.List[string]]::new()
    foreach ($child in @(Get-ChildItem -LiteralPath $Path -Recurse -Force -ErrorAction Stop)) {
        if (($child.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Rollback directory contains a reparse point: $($child.FullName)"
        }
        if (-not $child.PSIsContainer) {
            $relativePath = $child.FullName.Substring($Path.Length).TrimStart('\', '/')
            $hash = (Get-FileHash -LiteralPath $child.FullName -Algorithm SHA256).Hash
            $entries.Add('{0}|{1}|{2}' -f $relativePath, $hash, $child.Length)
        }
    }

    $manifestText = @($entries | Sort-Object) -join "`n"
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $manifestHash = [BitConverter]::ToString(
            $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($manifestText))
        ).Replace('-', '')
    }
    finally {
        $sha256.Dispose()
    }

    return [pscustomobject]@{
        Exists = $true
        Hash   = $manifestHash
    }
}

function Copy-BoostLabRollbackDirectory {
    param(
        [Parameter(Mandatory)]
        [string]$Source,

        [Parameter(Mandatory)]
        [string]$Destination
    )

    $sourceItem = Get-Item -LiteralPath $Source -Force -ErrorAction Stop
    if (($sourceItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'Rollback backup directory is a reparse point.'
    }
    [IO.Directory]::CreateDirectory($Destination) | Out-Null
    foreach ($child in @(Get-ChildItem -LiteralPath $Source -Recurse -Force -ErrorAction Stop)) {
        if (($child.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Rollback backup contains a reparse point: $($child.FullName)"
        }
        $relativePath = $child.FullName.Substring($Source.Length).TrimStart('\', '/')
        $destinationPath = Join-Path $Destination $relativePath
        if ($child.PSIsContainer) {
            [IO.Directory]::CreateDirectory($destinationPath) | Out-Null
        }
        else {
            [IO.Directory]::CreateDirectory((Split-Path -Parent $destinationPath)) | Out-Null
            Copy-Item -LiteralPath $child.FullName -Destination $destinationPath -Force -ErrorAction Stop
        }
    }
}

function Set-BoostLabRestoredFileMetadata {
    param(
        [Parameter(Mandatory)]
        [string]$TargetPath,

        [ValidateSet('File', 'Directory')]
        [string]$ItemType,

        [AllowNull()]
        [object]$OriginalMetadata
    )

    if ($null -eq $OriginalMetadata) {
        return
    }

    $itemMetadata = Get-BoostLabRollbackPropertyValue `
        -InputObject $OriginalMetadata `
        -Name 'ItemMetadata'
    if ($null -ne $itemMetadata) {
        $attributes = [string](
            Get-BoostLabRollbackPropertyValue -InputObject $itemMetadata -Name 'Attributes'
        )
        $creationTime = Get-BoostLabRollbackPropertyValue `
            -InputObject $itemMetadata `
            -Name 'CreationTimeUtc'
        $lastWriteTime = Get-BoostLabRollbackPropertyValue `
            -InputObject $itemMetadata `
            -Name 'LastWriteTimeUtc'
        if (-not [string]::IsNullOrWhiteSpace($attributes)) {
            [IO.File]::SetAttributes(
                $TargetPath,
                [IO.FileAttributes][Enum]::Parse(
                    [IO.FileAttributes],
                    $attributes
                )
            )
        }
        if ($null -ne $creationTime) {
            [IO.File]::SetCreationTimeUtc($TargetPath, [datetime]$creationTime)
        }
        if ($null -ne $lastWriteTime) {
            [IO.File]::SetLastWriteTimeUtc($TargetPath, [datetime]$lastWriteTime)
        }
    }

    if ($ItemType -eq 'Directory') {
        foreach ($entry in @(
            Get-BoostLabRollbackPropertyValue -InputObject $OriginalMetadata -Name 'Manifest'
        )) {
            $relativePath = [string](
                Get-BoostLabRollbackPropertyValue -InputObject $entry -Name 'RelativePath'
            )
            $restoredPath = Join-Path $TargetPath $relativePath
            if (-not (Test-Path -LiteralPath $restoredPath -PathType Leaf)) {
                throw "Restored directory file is missing: $restoredPath"
            }
            $attributes = [string](
                Get-BoostLabRollbackPropertyValue -InputObject $entry -Name 'Attributes'
            )
            if (-not [string]::IsNullOrWhiteSpace($attributes)) {
                [IO.File]::SetAttributes(
                    $restoredPath,
                    [IO.FileAttributes][Enum]::Parse(
                        [IO.FileAttributes],
                        $attributes
                    )
                )
            }
            $creationTime = Get-BoostLabRollbackPropertyValue `
                -InputObject $entry `
                -Name 'CreationTimeUtc'
            $lastWriteTime = Get-BoostLabRollbackPropertyValue `
                -InputObject $entry `
                -Name 'LastWriteTimeUtc'
            if ($null -ne $creationTime) {
                [IO.File]::SetCreationTimeUtc($restoredPath, [datetime]$creationTime)
            }
            if ($null -ne $lastWriteTime) {
                [IO.File]::SetLastWriteTimeUtc($restoredPath, [datetime]$lastWriteTime)
            }
        }
    }
}

function ConvertTo-BoostLabRollbackRecordTable {
    param(
        [Parameter(Mandatory)]
        [object]$Record
    )

    $table = [ordered]@{}
    foreach ($property in $Record.PSObject.Properties) {
        $table[$property.Name] = $property.Value
    }
    return $table
}

function Invoke-BoostLabFileRollback {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$RecordPath,

        [Parameter(Mandatory)]
        [string]$StateRoot,

        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ActionId,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $imported = Import-BoostLabRollbackRecord -RecordPath $RecordPath -StateRoot $StateRoot
    if (-not $imported.IsValid) {
        return [pscustomobject]@{
            Success          = $false
            Status           = 'Blocked'
            ToolId           = $ToolId
            ActionId         = $ActionId
            RecordPath       = $RecordPath
            TargetPath       = ''
            RestoreAttempted = $false
            Message          = 'File rollback was blocked because the record is missing or invalid.'
            Errors           = @($imported.Errors)
            Verification     = $null
            Timestamp        = Get-Date
        }
    }

    $record = $imported.Record
    $recordValidation = Test-BoostLabRollbackRecord `
        -Record $record `
        -ExpectedToolId $ToolId `
        -ExpectedActionId $ActionId
    if (-not $recordValidation.IsValid) {
        $errors.AddRange([string[]]@($recordValidation.Errors))
    }

    $itemType = [string](Get-BoostLabRollbackPropertyValue -InputObject $record -Name 'ItemType')
    $targetPath = [string](Get-BoostLabRollbackPropertyValue -InputObject $record -Name 'SourcePath')
    $scopeId = [string](Get-BoostLabRollbackPropertyValue -InputObject $record -Name 'ScopeId')
    if ($itemType -notin @('File', 'Directory')) {
        $errors.Add("Rollback record item type '$itemType' is not a file-system type.")
    }
    else {
        $targetValidation = Test-BoostLabFileCaptureTarget `
            -ToolId $ToolId `
            -ScopeId $scopeId `
            -TargetPath $targetPath `
            -ItemType $itemType `
            -Policy $Policy
        if (-not $targetValidation.IsAllowed) {
            $errors.AddRange([string[]]@($targetValidation.Errors))
        }
    }

    $mutationRecorded = [bool](
        Get-BoostLabRollbackPropertyValue -InputObject $record -Name 'MutationRecorded'
    )
    if (-not $mutationRecorded) {
        $errors.Add('Rollback is blocked until post-mutation state is recorded.')
    }

    $postMutationExists = [bool](
        Get-BoostLabRollbackPropertyValue -InputObject $record -Name 'PostMutationExists'
    )
    $postMutationHash = [string](
        Get-BoostLabRollbackPropertyValue -InputObject $record -Name 'PostMutationHash'
    )
    $currentState = $null
    if ($errors.Count -eq 0) {
        try {
            $currentState = Get-BoostLabRollbackFileState -Path $targetPath -ItemType $itemType
            if ([bool]$currentState.Exists -ne $postMutationExists) {
                $errors.Add('Current target existence does not match the recorded post-mutation state.')
            }
            elseif ($postMutationExists) {
                if ([string]::IsNullOrWhiteSpace($postMutationHash)) {
                    $errors.Add('Recorded post-mutation hash is missing.')
                }
                elseif ($currentState.Hash -ne $postMutationHash) {
                    $errors.Add('Current target hash does not match the recorded post-mutation state.')
                }
            }
        }
        catch {
            $errors.Add("Current file state verification failed: $($_.Exception.Message)")
        }
    }

    $originalExists = [bool](
        Get-BoostLabRollbackPropertyValue -InputObject $record -Name 'OriginalExists'
    )
    $backupPath = [string](
        Get-BoostLabRollbackPropertyValue -InputObject $record -Name 'BackupLocation'
    )
    $originalHash = [string](
        Get-BoostLabRollbackPropertyValue -InputObject $record -Name 'OriginalHash'
    )
    $originalMetadata = Get-BoostLabRollbackPropertyValue `
        -InputObject $record `
        -Name 'OriginalMetadata'
    $backupHash = [string](
        Get-BoostLabRollbackPropertyValue -InputObject $record -Name 'BackupHash'
    )
    if ($originalExists -and $errors.Count -eq 0) {
        $operationId = [string](
            Get-BoostLabRollbackPropertyValue -InputObject $record -Name 'OperationId'
        )
        $expectedBackupRoot = Join-Path `
            (ConvertTo-BoostLabRollbackFullPath -Path $StateRoot) `
            "Backups\$operationId"
        if (
            [string]::IsNullOrWhiteSpace($backupPath) -or
            -not (Test-BoostLabRollbackPathWithinRoot -Path $backupPath -Root $expectedBackupRoot)
        ) {
            $errors.Add('Backup path is outside the recorded BoostLab operation scope.')
        }
        elseif (-not (Test-Path -LiteralPath $backupPath)) {
            $errors.Add('Recorded backup does not exist.')
        }
        else {
            try {
                $backupState = Get-BoostLabRollbackFileState -Path $backupPath -ItemType $itemType
                if (
                    $backupState.Hash -ne $backupHash -or
                    $backupState.Hash -ne $originalHash
                ) {
                    $errors.Add('Backup hash does not match the recorded original state.')
                }
            }
            catch {
                $errors.Add("Backup verification failed: $($_.Exception.Message)")
            }
        }
    }

    if ($errors.Count -gt 0) {
        return [pscustomobject]@{
            Success          = $false
            Status           = 'Blocked'
            ToolId           = $ToolId
            ActionId         = $ActionId
            RecordPath       = $imported.RecordPath
            TargetPath       = $targetPath
            RestoreAttempted = $false
            Message          = 'File rollback was blocked by validation.'
            Errors           = $errors.ToArray()
            Verification     = $null
            Timestamp        = Get-Date
        }
    }

    try {
        if (Test-Path -LiteralPath $targetPath) {
            Remove-Item -LiteralPath $targetPath -Recurse -Force -ErrorAction Stop
        }
        if ($originalExists) {
            if ($itemType -eq 'File') {
                [IO.Directory]::CreateDirectory((Split-Path -Parent $targetPath)) | Out-Null
                Copy-Item -LiteralPath $backupPath -Destination $targetPath -Force -ErrorAction Stop
            }
            else {
                Copy-BoostLabRollbackDirectory -Source $backupPath -Destination $targetPath
            }
            Set-BoostLabRestoredFileMetadata `
                -TargetPath $targetPath `
                -ItemType $itemType `
                -OriginalMetadata $originalMetadata
        }

        $restoredState = Get-BoostLabRollbackFileState -Path $targetPath -ItemType $itemType
        $verificationPassed = if ($originalExists) {
            $restoredState.Exists -and $restoredState.Hash -eq $originalHash
        }
        else {
            -not $restoredState.Exists
        }
        if (-not $verificationPassed) {
            throw 'Restored file state does not match the captured original state.'
        }

        $recordTable = ConvertTo-BoostLabRollbackRecordTable -Record $record
        $recordTable['RollbackCompleted'] = $true
        $recordTable['RollbackCompletedAt'] = Get-Date
        Save-BoostLabRollbackRecord -Record $recordTable -StateRoot $StateRoot | Out-Null

        return [pscustomobject]@{
            Success          = $true
            Status           = 'Restored'
            ToolId           = $ToolId
            ActionId         = $ActionId
            RecordPath       = $imported.RecordPath
            TargetPath       = $targetPath
            RestoreAttempted = $true
            Message          = 'File rollback restored the captured original state.'
            Errors           = @()
            Verification     = [pscustomobject]@{
                Status   = 'Passed'
                Expected = if ($originalExists) { $originalHash } else { 'Absent' }
                Actual   = if ($restoredState.Exists) { $restoredState.Hash } else { 'Absent' }
            }
            Timestamp        = Get-Date
        }
    }
    catch {
        return [pscustomobject]@{
            Success          = $false
            Status           = 'Failed'
            ToolId           = $ToolId
            ActionId         = $ActionId
            RecordPath       = $imported.RecordPath
            TargetPath       = $targetPath
            RestoreAttempted = $true
            Message          = 'File rollback failed.'
            Errors           = @($_.Exception.Message)
            Verification     = $null
            Timestamp        = Get-Date
        }
    }
}

function ConvertTo-BoostLabComparableJson {
    param(
        [AllowNull()]
        [object]$Value
    )

    return $Value | ConvertTo-Json -Compress -Depth 30
}

function Get-BoostLabRollbackRegistrySnapshot {
    param(
        [Parameter(Mandatory)]
        [string]$RegistryPath,

        [ValidateSet('RegistryKey', 'RegistryValue')]
        [string]$ItemType,

        [string]$ValueName,

        [Parameter(Mandatory)]
        [scriptblock]$RegistryReader
    )

    $snapshot = & $RegistryReader $RegistryPath $ItemType $ValueName
    if ($null -eq $snapshot -or $null -eq $snapshot.PSObject.Properties['Exists']) {
        throw 'Registry reader returned an invalid snapshot.'
    }
    return $snapshot
}

function Invoke-BoostLabRegistryRollback {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$RecordPath,

        [Parameter(Mandatory)]
        [string]$StateRoot,

        [Parameter(Mandatory)]
        [string]$ToolId,

        [Parameter(Mandatory)]
        [string]$ActionId,

        [Parameter(Mandatory)]
        [scriptblock]$RegistryReader,

        [Parameter(Mandatory)]
        [scriptblock]$RegistryWriter,

        [Parameter(Mandatory)]
        [scriptblock]$RegistryRemover,

        [AllowNull()]
        [System.Collections.IDictionary]$Policy
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $imported = Import-BoostLabRollbackRecord -RecordPath $RecordPath -StateRoot $StateRoot
    if (-not $imported.IsValid) {
        return [pscustomobject]@{
            Success          = $false
            Status           = 'Blocked'
            ToolId           = $ToolId
            ActionId         = $ActionId
            RecordPath       = $RecordPath
            RegistryPath     = ''
            RestoreAttempted = $false
            Message          = 'Registry rollback was blocked because the record is missing or invalid.'
            Errors           = @($imported.Errors)
            Verification     = $null
            Timestamp        = Get-Date
        }
    }

    $record = $imported.Record
    $recordValidation = Test-BoostLabRollbackRecord `
        -Record $record `
        -ExpectedToolId $ToolId `
        -ExpectedActionId $ActionId
    if (-not $recordValidation.IsValid) {
        $errors.AddRange([string[]]@($recordValidation.Errors))
    }

    $itemType = [string](Get-BoostLabRollbackPropertyValue -InputObject $record -Name 'ItemType')
    $registryPath = [string](
        Get-BoostLabRollbackPropertyValue -InputObject $record -Name 'RegistryPath'
    )
    $valueName = [string](Get-BoostLabRollbackPropertyValue -InputObject $record -Name 'ValueName')
    $scopeId = [string](Get-BoostLabRollbackPropertyValue -InputObject $record -Name 'ScopeId')
    if ($itemType -notin @('RegistryKey', 'RegistryValue')) {
        $errors.Add("Rollback record item type '$itemType' is not a registry type.")
    }
    else {
        $targetValidation = Test-BoostLabRegistryCaptureTarget `
            -ToolId $ToolId `
            -ScopeId $scopeId `
            -RegistryPath $registryPath `
            -ItemType $itemType `
            -ValueName $valueName `
            -Policy $Policy
        if (-not $targetValidation.IsAllowed) {
            $errors.AddRange([string[]]@($targetValidation.Errors))
        }
    }

    if (-not [bool](Get-BoostLabRollbackPropertyValue -InputObject $record -Name 'MutationRecorded')) {
        $errors.Add('Rollback is blocked until post-mutation state is recorded.')
    }

    $postMutationExists = [bool](
        Get-BoostLabRollbackPropertyValue -InputObject $record -Name 'PostMutationExists'
    )
    $postMutationMetadata = Get-BoostLabRollbackPropertyValue `
        -InputObject $record `
        -Name 'PostMutationMetadata'
    if ($errors.Count -eq 0) {
        try {
            $currentState = Get-BoostLabRollbackRegistrySnapshot `
                -RegistryPath $registryPath `
                -ItemType $itemType `
                -ValueName $valueName `
                -RegistryReader $RegistryReader
            if ([bool]$currentState.Exists -ne $postMutationExists) {
                $errors.Add('Current registry existence does not match the recorded post-mutation state.')
            }
            elseif (
                $postMutationExists -and
                (ConvertTo-BoostLabComparableJson -Value $currentState.Metadata) -ne
                (ConvertTo-BoostLabComparableJson -Value $postMutationMetadata)
            ) {
                $errors.Add('Current registry data does not match the recorded post-mutation state.')
            }
        }
        catch {
            $errors.Add("Current registry state verification failed: $($_.Exception.Message)")
        }
    }

    if ($errors.Count -gt 0) {
        return [pscustomobject]@{
            Success          = $false
            Status           = 'Blocked'
            ToolId           = $ToolId
            ActionId         = $ActionId
            RecordPath       = $imported.RecordPath
            RegistryPath     = $registryPath
            RestoreAttempted = $false
            Message          = 'Registry rollback was blocked by validation.'
            Errors           = $errors.ToArray()
            Verification     = $null
            Timestamp        = Get-Date
        }
    }

    $originalExists = [bool](
        Get-BoostLabRollbackPropertyValue -InputObject $record -Name 'OriginalExists'
    )
    $originalMetadata = Get-BoostLabRollbackPropertyValue `
        -InputObject $record `
        -Name 'OriginalMetadata'
    try {
        if ($originalExists) {
            & $RegistryWriter $registryPath $itemType $valueName $originalMetadata
        }
        else {
            & $RegistryRemover $registryPath $itemType $valueName
        }

        $restoredState = Get-BoostLabRollbackRegistrySnapshot `
            -RegistryPath $registryPath `
            -ItemType $itemType `
            -ValueName $valueName `
            -RegistryReader $RegistryReader
        $verificationPassed = if ($originalExists) {
            [bool]$restoredState.Exists -and
            (ConvertTo-BoostLabComparableJson -Value $restoredState.Metadata) -eq
            (ConvertTo-BoostLabComparableJson -Value $originalMetadata)
        }
        else {
            -not [bool]$restoredState.Exists
        }
        if (-not $verificationPassed) {
            throw 'Restored registry state does not match the captured original state.'
        }

        $recordTable = ConvertTo-BoostLabRollbackRecordTable -Record $record
        $recordTable['RollbackCompleted'] = $true
        $recordTable['RollbackCompletedAt'] = Get-Date
        Save-BoostLabRollbackRecord -Record $recordTable -StateRoot $StateRoot | Out-Null

        return [pscustomobject]@{
            Success          = $true
            Status           = 'Restored'
            ToolId           = $ToolId
            ActionId         = $ActionId
            RecordPath       = $imported.RecordPath
            RegistryPath     = $registryPath
            RestoreAttempted = $true
            Message          = 'Registry rollback restored the captured original state.'
            Errors           = @()
            Verification     = [pscustomobject]@{
                Status   = 'Passed'
                Expected = $originalMetadata
                Actual   = $restoredState.Metadata
            }
            Timestamp        = Get-Date
        }
    }
    catch {
        return [pscustomobject]@{
            Success          = $false
            Status           = 'Failed'
            ToolId           = $ToolId
            ActionId         = $ActionId
            RecordPath       = $imported.RecordPath
            RegistryPath     = $registryPath
            RestoreAttempted = $true
            Message          = 'Registry rollback failed.'
            Errors           = @($_.Exception.Message)
            Verification     = $null
            Timestamp        = Get-Date
        }
    }
}

Export-ModuleMember -Function @(
    'Invoke-BoostLabFileRollback'
    'Invoke-BoostLabRegistryRollback'
)
