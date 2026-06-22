Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'game-configs'; Title = 'Game Configs'; Stage = 'Game Configs'; Order = 1
    Type = 'assistant'; RiskLevel = 'high'
    Description = 'Apply one upstream Github-Game-Configs payload after verified BoostLab mirror download, SHA/size verification, extraction, and source-defined copy/delete/open/import steps.'
    Actions = @('Apply')
}

$script:BoostLabImplementedActions = @('Apply')
$script:BoostLabProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$script:BoostLabManifestPath = Join-Path $script:BoostLabProjectRoot 'config\GameConfigs.psd1'
$script:BoostLabArtifactSourcesPath = Join-Path $script:BoostLabProjectRoot 'config\GameConfigArtifactSources.psd1'
$script:BoostLabArtifactProvenancePath = Join-Path $script:BoostLabProjectRoot 'config\GameConfigArtifactProvenance.psd1'

function Import-BoostLabGameConfigDataFile {
    param(
        [Parameter(Mandatory)]
        [string]$LiteralPath
    )

    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Leaf)) {
        throw "Required Game Configs manifest was not found: $LiteralPath"
    }

    return Import-PowerShellDataFile -LiteralPath $LiteralPath
}

function Get-BoostLabGameConfigRuntimeManifest {
    return Import-BoostLabGameConfigDataFile -LiteralPath $script:BoostLabManifestPath
}

function Get-BoostLabGameConfigArtifactSources {
    return Import-BoostLabGameConfigDataFile -LiteralPath $script:BoostLabArtifactSourcesPath
}

function Get-BoostLabGameConfigArtifactProvenance {
    return Import-BoostLabGameConfigDataFile -LiteralPath $script:BoostLabArtifactProvenancePath
}

function Get-BoostLabToolInfo {
    $manifest = Get-BoostLabGameConfigRuntimeManifest

    return [pscustomobject]@{
        Id                       = [string]$script:BoostLabToolMetadata.Id
        Title                    = [string]$script:BoostLabToolMetadata.Title
        Stage                    = [string]$script:BoostLabToolMetadata.Stage
        Order                    = [int]$script:BoostLabToolMetadata.Order
        Type                     = [string]$script:BoostLabToolMetadata.Type
        RiskLevel                = [string]$script:BoostLabToolMetadata.RiskLevel
        Description              = [string]$script:BoostLabToolMetadata.Description
        Actions                  = @($script:BoostLabToolMetadata.Actions)
        ImplementedActions       = @($script:BoostLabImplementedActions)
        SelectionMode            = 'SingleSelect'
        SelectionRequiredActions = @('Apply')
        GameCount                = @($manifest.Games).Count
        UsesBoostLabMirrors      = [bool]$manifest.RuntimeUsesBoostLabMirrors
        SupportsDefault          = $false
        SupportsRestore          = $false
        SupportsAnalyze          = $false
    }
}

function Test-BoostLabToolCompatibility {
    return [pscustomobject]@{
        Supported = $true
        Reason    = 'Game Configs Apply runtime is available.'
    }
}

function Get-BoostLabToolState {
    $manifest = Get-BoostLabGameConfigRuntimeManifest

    return [pscustomobject]@{
        Status = 'Ready'
        AvailableActions = @($script:BoostLabImplementedActions)
        GameCount = @($manifest.Games).Count
        SelectionRequired = $true
        Message = 'Select exactly one upstream game config and run Apply.'
    }
}

function Restore-BoostLabToolDefault {
    return New-BoostLabGameConfigResult `
        -Success $false `
        -Status 'UnsupportedAction' `
        -ActionName 'Default' `
        -Message 'Game Configs does not define Default or Restore behavior upstream.'
}

function New-BoostLabGameConfigResult {
    param(
        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$ActionName,

        [Parameter(Mandatory)]
        [string]$Message,

        [object]$Data = $null,

        [string[]]$Errors = @(),

        [string]$VerificationStatus = 'NotApplicable'
    )

    return [pscustomobject]@{
        Success            = $Success
        Status             = $Status
        ToolId             = [string]$script:BoostLabToolMetadata.Id
        ToolTitle          = [string]$script:BoostLabToolMetadata.Title
        Action             = $ActionName
        Message            = $Message
        RestartRequired    = $false
        Errors             = @($Errors)
        Data               = $Data
        VerificationResult = [pscustomobject]@{
            Status  = $VerificationStatus
            Message = $Message
            Errors  = @($Errors)
        }
        Timestamp          = Get-Date
    }
}

function Get-BoostLabGameConfigSelectedId {
    param(
        [AllowNull()]
        [object]$Branch
    )

    if ($null -eq $Branch) {
        return ''
    }

    if ($Branch -is [array]) {
        $items = @($Branch | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
        if ($items.Count -ne 1) {
            return ''
        }

        return [string]$items[0]
    }

    return [string]$Branch
}

function Get-BoostLabGameConfigRecord {
    param(
        [Parameter(Mandatory)]
        [string]$GameId,

        [Parameter(Mandatory)]
        [object]$Manifest
    )

    return @($Manifest.Games | Where-Object { [string]$_['GameId'] -eq $GameId }) | Select-Object -First 1
}

function Resolve-BoostLabGameConfigTemplate {
    param(
        [Parameter(Mandatory)]
        [string]$Template,

        [Parameter(Mandatory)]
        [hashtable]$Variables
    )

    $resolved = $Template
    foreach ($key in @($Variables.Keys | Sort-Object { [string]$_ } -Descending)) {
        $resolved = $resolved.Replace([string]$key, [string]$Variables[$key])
    }

    $resolved = [regex]::Replace(
        $resolved,
        '\$env:([A-Za-z_][A-Za-z0-9_]*)',
        {
            param($match)
            $value = [Environment]::GetEnvironmentVariable([string]$match.Groups[1].Value)
            if ($null -eq $value) {
                return ''
            }

            return [string]$value
        }
    )

    return $resolved
}

function Get-BoostLabGameConfigArrayValue {
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Game,

        [Parameter(Mandatory)]
        [string]$Key
    )

    if (-not $Game.Contains($Key) -or $null -eq $Game[$Key]) {
        return @()
    }

    return @($Game[$Key] | Where-Object { $null -ne $_ })
}

function Invoke-BoostLabGameConfigAdapter {
    param(
        [Parameter(Mandatory)]
        [string]$Operation,

        [hashtable]$OperationAdapter = @{},

        [hashtable]$Arguments = @{}
    )

    if ($null -ne $OperationAdapter -and $OperationAdapter.ContainsKey($Operation)) {
        $handler = $OperationAdapter[$Operation]
        return & $handler @Arguments
    }

    switch ($Operation) {
        'Download' {
            $destinationDirectory = Split-Path -Parent ([string]$Arguments['Destination'])
            if (-not [string]::IsNullOrWhiteSpace($destinationDirectory)) {
                New-Item -ItemType Directory -Path $destinationDirectory -Force -ErrorAction Stop | Out-Null
            }
            Invoke-WebRequest -Uri ([string]$Arguments['Url']) -OutFile ([string]$Arguments['Destination']) -UseBasicParsing -ErrorAction Stop
            return $true
        }
        'GetFileSize' {
            return [int64](Get-Item -LiteralPath ([string]$Arguments['Path']) -ErrorAction Stop).Length
        }
        'GetFileHash' {
            return [string](Get-FileHash -LiteralPath ([string]$Arguments['Path']) -Algorithm SHA256 -ErrorAction Stop).Hash
        }
        'ExpandArchive' {
            Expand-Archive -LiteralPath ([string]$Arguments['ArchivePath']) -DestinationPath ([string]$Arguments['DestinationPath']) -Force -ErrorAction Stop
            return $true
        }
        'EnsureDirectory' {
            New-Item -ItemType Directory -Path ([string]$Arguments['Path']) -Force -ErrorAction SilentlyContinue | Out-Null
            return $true
        }
        'TestPath' {
            return Test-Path -LiteralPath ([string]$Arguments['Path'])
        }
        'CopyItem' {
            Copy-Item -Path ([string]$Arguments['Source']) -Destination ([string]$Arguments['Destination']) -Recurse:([bool]$Arguments['Recurse']) -Force:([bool]$Arguments['Force']) -ErrorAction SilentlyContinue | Out-Null
            return $true
        }
        'MoveItem' {
            Move-Item -Path ([string]$Arguments['Source']) -Destination ([string]$Arguments['Destination']) -Force:([bool]$Arguments['Force']) -ErrorAction SilentlyContinue | Out-Null
            return $true
        }
        'RemoveItem' {
            Remove-Item -Path ([string]$Arguments['Path']) -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
            return $true
        }
        'ReplaceRendererWorkerCount' {
            $path = [string]$Arguments['Path']
            $rendererValue = [string]$Arguments['RendererWorkerCount']
            $content = [IO.File]::ReadAllText($path)
            $updated = $content.Replace('$', $rendererValue)
            $encoding = New-Object System.Text.UTF8Encoding $false
            [IO.File]::WriteAllText($path, $updated, $encoding)
            return $true
        }
        'PromptFolder' {
            Add-Type -AssemblyName System.Windows.Forms
            $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
            $dialog.Description = [string]$Arguments['Prompt']
            if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
                throw 'Folder selection was cancelled.'
            }
            return [string]$dialog.SelectedPath
        }
        'PromptText' {
            return Read-Host -Prompt ([string]$Arguments['Prompt'])
        }
        'UnblockPath' {
            if (Test-Path -LiteralPath ([string]$Arguments['Path'])) {
                Get-ChildItem -Path ([string]$Arguments['Path']) -Recurse -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue
            }
            return $true
        }
        'StartProcess' {
            $argumentList = if ($Arguments.ContainsKey('ArgumentList')) { [string]$Arguments['ArgumentList'] } else { '' }
            if ([string]::IsNullOrWhiteSpace($argumentList)) {
                Start-Process -FilePath ([string]$Arguments['FilePath']) -Wait:([bool]$Arguments['Wait'])
            }
            else {
                Start-Process -FilePath ([string]$Arguments['FilePath']) -ArgumentList $argumentList -Wait:([bool]$Arguments['Wait'])
            }
            return $true
        }
        'Sleep' {
            Start-Sleep -Seconds ([int]$Arguments['Seconds'])
            return $true
        }
        default {
            throw "Unknown Game Config operation adapter command: $Operation"
        }
    }
}

function Test-BoostLabGameConfigArtifactApproval {
    param(
        [Parameter(Mandatory)]
        [string]$ArtifactId,

        [Parameter(Mandatory)]
        [object]$Sources,

        [Parameter(Mandatory)]
        [object]$Provenance
    )

    $source = @($Sources.PayloadSources | Where-Object { [string]$_['ManifestCandidateId'] -eq $ArtifactId }) | Select-Object -First 1
    $record = @($Provenance.ProvenanceApprovals | Where-Object { [string]$_['ArtifactId'] -eq $ArtifactId }) | Select-Object -First 1
    $errors = [System.Collections.Generic.List[string]]::new()

    if ($null -eq $source) {
        $errors.Add("Unknown Game Config artifact id: $ArtifactId")
    }
    if ($null -eq $record) {
        $errors.Add("Missing Game Config provenance record: $ArtifactId")
    }
    if ($null -ne $source) {
        if ([string]$source.VerifiedBoostLabMirrorUrl -notlike 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/*') {
            $errors.Add("Game Config artifact does not use a verified BoostLab mirror: $ArtifactId")
        }
        if (-not [bool]$source.VerifiedBoostLabMirrorAvailable) {
            $errors.Add("Game Config mirror is not available: $ArtifactId")
        }
        if (-not [bool]$source.ArtifactProvenanceApproved) {
            $errors.Add("Game Config artifact lacks provenance approval: $ArtifactId")
        }
        if (-not [bool]$source.RuntimeSourceSelectionApproved) {
            $errors.Add("Game Config artifact is not runtime source-selection approved: $ArtifactId")
        }
        if (-not [bool]$source.DownloadExecutionApproved) {
            $errors.Add("Game Config artifact download is not approved: $ArtifactId")
        }
        if ([string]$source.ExpectedSha256 -notmatch '^[A-Fa-f0-9]{64}$') {
            $errors.Add("Game Config artifact SHA-256 is missing or malformed: $ArtifactId")
        }
        if ([int64]$source.ExpectedSizeBytes -le 0) {
            $errors.Add("Game Config artifact size is missing: $ArtifactId")
        }
    }
    if ($null -ne $record) {
        if (-not [bool]$record.ArtifactProvenanceApproved) {
            $errors.Add("Game Config provenance approval flag is missing: $ArtifactId")
        }
        if (-not [bool]$record.RuntimeSourceSelectionApproved) {
            $errors.Add("Game Config provenance runtime selection approval is missing: $ArtifactId")
        }
        if ([string]$record.VerifiedBoostLabMirrorUrl -notlike 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/*') {
            $errors.Add("Game Config provenance does not use a BoostLab mirror: $ArtifactId")
        }
        if ([string]$record.ExpectedSha256 -ne [string]$source.ExpectedSha256) {
            $errors.Add("Game Config provenance SHA-256 mismatch: $ArtifactId")
        }
        if ([int64]$record.ExpectedSizeBytes -ne [int64]$source.ExpectedSizeBytes) {
            $errors.Add("Game Config provenance size mismatch: $ArtifactId")
        }
    }

    return [pscustomobject]@{
        IsValid = ($errors.Count -eq 0)
        Errors = @($errors)
        Source = $source
        Provenance = $record
    }
}

function Save-BoostLabGameConfigArtifact {
    param(
        [Parameter(Mandatory)]
        [string]$ArtifactId,

        [Parameter(Mandatory)]
        [string]$Destination,

        [Parameter(Mandatory)]
        [object]$Sources,

        [Parameter(Mandatory)]
        [object]$Provenance,

        [hashtable]$OperationAdapter = @{}
    )

    $approval = Test-BoostLabGameConfigArtifactApproval -ArtifactId $ArtifactId -Sources $Sources -Provenance $Provenance
    if (-not [bool]$approval.IsValid) {
        throw ($approval.Errors -join '; ')
    }

    $source = $approval.Source
    Invoke-BoostLabGameConfigAdapter -Operation 'Download' -OperationAdapter $OperationAdapter -Arguments @{
        ArtifactId   = $ArtifactId
        Url          = [string]$source.VerifiedBoostLabMirrorUrl
        Destination  = $Destination
        ExpectedName = [string]$source.ExpectedFileName
    } | Out-Null

    $actualSize = [int64](Invoke-BoostLabGameConfigAdapter -Operation 'GetFileSize' -OperationAdapter $OperationAdapter -Arguments @{ Path = $Destination })
    if ($actualSize -ne [int64]$source.ExpectedSizeBytes) {
        throw "Game Config artifact size mismatch for $ArtifactId. Expected $($source.ExpectedSizeBytes), found $actualSize."
    }

    $actualHash = [string](Invoke-BoostLabGameConfigAdapter -Operation 'GetFileHash' -OperationAdapter $OperationAdapter -Arguments @{ Path = $Destination })
    if ($actualHash.ToUpperInvariant() -ne ([string]$source.ExpectedSha256).ToUpperInvariant()) {
        throw "Game Config artifact SHA-256 mismatch for $ArtifactId."
    }

    return [pscustomobject]@{
        ArtifactId = $ArtifactId
        SourceUrl = [string]$source.VerifiedBoostLabMirrorUrl
        LocalPath = $Destination
        SizeBytes = $actualSize
        SHA256 = $actualHash.ToUpperInvariant()
    }
}

function Invoke-BoostLabGameConfigApply {
    param(
        [Parameter(Mandatory)]
        [object]$Game,

        [string]$RendererWorkerCount = '',

        [hashtable]$FolderSelections = @{},

        [hashtable]$PromptValues = @{},

        [hashtable]$OperationAdapter = @{}
    )

    $manifest = Get-BoostLabGameConfigRuntimeManifest
    $sources = Get-BoostLabGameConfigArtifactSources
    $provenance = Get-BoostLabGameConfigArtifactProvenance
    $operationLog = [System.Collections.Generic.List[object]]::new()
    $downloadedArtifacts = [System.Collections.Generic.List[object]]::new()
    $variables = @{
        '$ArchivePath' = Resolve-BoostLabGameConfigTemplate -Template ([string]$Game['ArchivePath']) -Variables @{}
        '$ExtractPath' = Resolve-BoostLabGameConfigTemplate -Template ([string]$Game['ExtractPath']) -Variables @{}
    }

    if (-not [bool]$manifest.RuntimeUsesBoostLabMirrors) {
        throw 'Game Configs runtime manifest does not require BoostLab mirrors.'
    }

    foreach ($pattern in @($manifest.DisallowedRuntimePatterns)) {
        if ([string]::IsNullOrWhiteSpace([string]$pattern)) {
            throw 'Game Configs runtime manifest contains an empty disallowed runtime pattern.'
        }
    }

    foreach ($pathTemplate in @(Get-BoostLabGameConfigArrayValue -Game $Game -Key 'PreRemovePaths')) {
        $path = Resolve-BoostLabGameConfigTemplate -Template ([string]$pathTemplate) -Variables $variables
        Invoke-BoostLabGameConfigAdapter -Operation 'RemoveItem' -OperationAdapter $OperationAdapter -Arguments @{ Path = $path } | Out-Null
        $operationLog.Add([pscustomobject]@{ Operation = 'RemoveItem'; Path = $path; Phase = 'PreApply' }) | Out-Null
    }

    $archivePath = [string]$variables['$ArchivePath']
    $extractPath = [string]$variables['$ExtractPath']
    $downloadedArtifacts.Add((Save-BoostLabGameConfigArtifact -ArtifactId ([string]$Game['ArtifactId']) -Destination $archivePath -Sources $sources -Provenance $provenance -OperationAdapter $OperationAdapter)) | Out-Null
    $operationLog.Add([pscustomobject]@{ Operation = 'DownloadVerifiedMirror'; ArtifactId = [string]$Game['ArtifactId']; Destination = $archivePath }) | Out-Null

    Invoke-BoostLabGameConfigAdapter -Operation 'ExpandArchive' -OperationAdapter $OperationAdapter -Arguments @{
        ArchivePath      = $archivePath
        DestinationPath  = $extractPath
        ArtifactId       = [string]$Game['ArtifactId']
    } | Out-Null
    $operationLog.Add([pscustomobject]@{ Operation = 'ExpandArchive'; ArchivePath = $archivePath; DestinationPath = $extractPath }) | Out-Null

    foreach ($prompt in @(Get-BoostLabGameConfigArrayValue -Game $Game -Key 'PromptedFolders')) {
        $promptId = [string]$prompt['Id']
        $folder = if ($null -ne $FolderSelections -and $FolderSelections.ContainsKey($promptId)) {
            [string]$FolderSelections[$promptId]
        }
        else {
            [string](Invoke-BoostLabGameConfigAdapter -Operation 'PromptFolder' -OperationAdapter $OperationAdapter -Arguments @{
                Prompt = [string]$prompt['Prompt']
                Id     = $promptId
            })
        }
        if ([string]::IsNullOrWhiteSpace($folder)) {
            throw "Required folder selection was not provided: $promptId"
        }
        $variables["`$$promptId"] = $folder
        $operationLog.Add([pscustomobject]@{ Operation = 'PromptFolder'; Id = $promptId; Value = $folder }) | Out-Null
    }

    $rendererFiles = @(Get-BoostLabGameConfigArrayValue -Game $Game -Key 'RendererReplacementFiles')
    if ($rendererFiles.Count -gt 0) {
        $rendererValue = if (-not [string]::IsNullOrWhiteSpace($RendererWorkerCount)) {
            [string]$RendererWorkerCount
        }
        elseif ($null -ne $PromptValues -and $PromptValues.ContainsKey('RendererWorkerCount')) {
            [string]$PromptValues['RendererWorkerCount']
        }
        else {
            [string](Invoke-BoostLabGameConfigAdapter -Operation 'PromptText' -OperationAdapter $OperationAdapter -Arguments @{ Prompt = 'RendererWorkerCount' })
        }
        if ([string]::IsNullOrWhiteSpace($rendererValue)) {
            throw 'RendererWorkerCount is required by the selected upstream recipe.'
        }
        foreach ($rendererFileTemplate in $rendererFiles) {
            $rendererPath = Resolve-BoostLabGameConfigTemplate -Template ([string]$rendererFileTemplate) -Variables $variables
            Invoke-BoostLabGameConfigAdapter -Operation 'ReplaceRendererWorkerCount' -OperationAdapter $OperationAdapter -Arguments @{
                Path = $rendererPath
                RendererWorkerCount = $rendererValue
            } | Out-Null
            $operationLog.Add([pscustomobject]@{ Operation = 'ReplaceRendererWorkerCount'; Path = $rendererPath }) | Out-Null
        }
    }

    foreach ($directoryTemplate in @(Get-BoostLabGameConfigArrayValue -Game $Game -Key 'EnsureDirectories')) {
        $directory = Resolve-BoostLabGameConfigTemplate -Template ([string]$directoryTemplate) -Variables $variables
        Invoke-BoostLabGameConfigAdapter -Operation 'EnsureDirectory' -OperationAdapter $OperationAdapter -Arguments @{ Path = $directory } | Out-Null
        $operationLog.Add([pscustomobject]@{ Operation = 'EnsureDirectory'; Path = $directory }) | Out-Null
    }

    if ($Game.Contains('Inspector') -and $null -ne $Game['Inspector']) {
        $inspector = $Game['Inspector']
        $inspectorPath = Resolve-BoostLabGameConfigTemplate -Template ([string]$inspector['Destination']) -Variables $variables
        $downloadedArtifacts.Add((Save-BoostLabGameConfigArtifact -ArtifactId ([string]$inspector['ArtifactId']) -Destination $inspectorPath -Sources $sources -Provenance $provenance -OperationAdapter $OperationAdapter)) | Out-Null
        $operationLog.Add([pscustomobject]@{ Operation = 'DownloadVerifiedMirror'; ArtifactId = [string]$inspector['ArtifactId']; Destination = $inspectorPath }) | Out-Null

        $unblockPath = Resolve-BoostLabGameConfigTemplate -Template ([string]$inspector['UnblockPath']) -Variables $variables
        Invoke-BoostLabGameConfigAdapter -Operation 'UnblockPath' -OperationAdapter $OperationAdapter -Arguments @{ Path = $unblockPath } | Out-Null
        $operationLog.Add([pscustomobject]@{ Operation = 'UnblockPath'; Path = $unblockPath }) | Out-Null

        $arguments = Resolve-BoostLabGameConfigTemplate -Template ([string]$inspector['Arguments']) -Variables $variables
        Invoke-BoostLabGameConfigAdapter -Operation 'StartProcess' -OperationAdapter $OperationAdapter -Arguments @{
            FilePath     = $inspectorPath
            ArgumentList = $arguments
            Wait         = $true
        } | Out-Null
        $operationLog.Add([pscustomobject]@{ Operation = 'StartProcess'; FilePath = $inspectorPath; ArgumentList = $arguments; Wait = $true }) | Out-Null

        if ([int]$inspector['WaitSeconds'] -gt 0) {
            Invoke-BoostLabGameConfigAdapter -Operation 'Sleep' -OperationAdapter $OperationAdapter -Arguments @{ Seconds = [int]$inspector['WaitSeconds'] } | Out-Null
            $operationLog.Add([pscustomobject]@{ Operation = 'Sleep'; Seconds = [int]$inspector['WaitSeconds'] }) | Out-Null
        }
    }

    foreach ($copy in @(Get-BoostLabGameConfigArrayValue -Game $Game -Key 'CopyOperations')) {
        $source = Resolve-BoostLabGameConfigTemplate -Template ([string]$copy['Source']) -Variables $variables
        $destination = Resolve-BoostLabGameConfigTemplate -Template ([string]$copy['Destination']) -Variables $variables
        if ([bool]$copy['OnlyIfDestinationExists']) {
            $exists = [bool](Invoke-BoostLabGameConfigAdapter -Operation 'TestPath' -OperationAdapter $OperationAdapter -Arguments @{ Path = $destination })
            if (-not $exists) {
                $operationLog.Add([pscustomobject]@{ Operation = 'CopyItemSkippedMissingDestination'; Source = $source; Destination = $destination }) | Out-Null
                continue
            }
        }
        Invoke-BoostLabGameConfigAdapter -Operation 'CopyItem' -OperationAdapter $OperationAdapter -Arguments @{
            Source      = $source
            Destination = $destination
            Recurse     = [bool]$copy['Recurse']
            Force       = [bool]$copy['Force']
        } | Out-Null
        $operationLog.Add([pscustomobject]@{ Operation = 'CopyItem'; Source = $source; Destination = $destination; Recurse = [bool]$copy['Recurse']; Force = [bool]$copy['Force'] }) | Out-Null
    }

    foreach ($move in @(Get-BoostLabGameConfigArrayValue -Game $Game -Key 'MoveOperations')) {
        $source = Resolve-BoostLabGameConfigTemplate -Template ([string]$move['Source']) -Variables $variables
        $destination = Resolve-BoostLabGameConfigTemplate -Template ([string]$move['Destination']) -Variables $variables
        Invoke-BoostLabGameConfigAdapter -Operation 'MoveItem' -OperationAdapter $OperationAdapter -Arguments @{
            Source      = $source
            Destination = $destination
            Force       = [bool]$move['Force']
        } | Out-Null
        $operationLog.Add([pscustomobject]@{ Operation = 'MoveItem'; Source = $source; Destination = $destination; Force = [bool]$move['Force'] }) | Out-Null
    }

    foreach ($pathTemplate in @(Get-BoostLabGameConfigArrayValue -Game $Game -Key 'RemovePaths')) {
        $path = Resolve-BoostLabGameConfigTemplate -Template ([string]$pathTemplate) -Variables $variables
        Invoke-BoostLabGameConfigAdapter -Operation 'RemoveItem' -OperationAdapter $OperationAdapter -Arguments @{ Path = $path } | Out-Null
        $operationLog.Add([pscustomobject]@{ Operation = 'RemoveItem'; Path = $path }) | Out-Null
    }

    foreach ($url in @(Get-BoostLabGameConfigArrayValue -Game $Game -Key 'OpenUrls')) {
        Invoke-BoostLabGameConfigAdapter -Operation 'StartProcess' -OperationAdapter $OperationAdapter -Arguments @{
            FilePath = [string]$url
            Wait     = $false
        } | Out-Null
        $operationLog.Add([pscustomobject]@{ Operation = 'StartProcess'; FilePath = [string]$url; Wait = $false }) | Out-Null
    }

    foreach ($pathTemplate in @(Get-BoostLabGameConfigArrayValue -Game $Game -Key 'CleanupPaths')) {
        $path = Resolve-BoostLabGameConfigTemplate -Template ([string]$pathTemplate) -Variables $variables
        Invoke-BoostLabGameConfigAdapter -Operation 'RemoveItem' -OperationAdapter $OperationAdapter -Arguments @{ Path = $path } | Out-Null
        $operationLog.Add([pscustomobject]@{ Operation = 'RemoveItem'; Path = $path; Phase = 'Cleanup' }) | Out-Null
    }

    return [pscustomobject]@{
        GameId = [string]$Game['GameId']
        DisplayName = [string]$Game['DisplayName']
        ArtifactId = [string]$Game['ArtifactId']
        SourceRecipePath = [string]$Game['SourceRecipePath']
        SourceRecipeSha256 = [string]$Game['SourceRecipeSha256']
        DownloadedArtifacts = @($downloadedArtifacts)
        OperationsExecuted = @($operationLog)
        NeedsInspector = [bool]$Game['NeedsInspector']
        OpensUrl = [bool]$Game['OpensUrl']
        RuntimeUsesBoostLabMirrors = $true
        RuntimeUsesRawUpstreamPayloadUrls = $false
    }
}

function Invoke-BoostLabToolAction {
    param(
        [Parameter(Mandatory)]
        [string]$ActionName,

        [bool]$Confirmed = $false,

        [AllowNull()]
        [object]$Branch = '',

        [string]$RendererWorkerCount = '',

        [hashtable]$FolderSelections = @{},

        [hashtable]$PromptValues = @{},

        [hashtable]$OperationAdapter = @{}
    )

    if ($ActionName -ne 'Apply') {
        return New-BoostLabGameConfigResult `
            -Success $false `
            -Status 'UnsupportedAction' `
            -ActionName $ActionName `
            -Message 'Game Configs only implements the upstream Apply action.'
    }

    $selectedGameId = Get-BoostLabGameConfigSelectedId -Branch $Branch
    $manifest = Get-BoostLabGameConfigRuntimeManifest
    $game = if (-not [string]::IsNullOrWhiteSpace($selectedGameId)) {
        Get-BoostLabGameConfigRecord -GameId $selectedGameId -Manifest $manifest
    }
    else {
        $null
    }

    if ($null -eq $game) {
        return New-BoostLabGameConfigResult `
            -Success $false `
            -Status 'SelectionRequired' `
            -ActionName $ActionName `
            -Message 'Apply requires selecting exactly one upstream game config entry. No download, extraction, file copy, delete, browser open, inspector execution, or system mutation occurred.' `
            -Data ([pscustomobject]@{
                SelectedGameId = $selectedGameId
                AvailableGameCount = @($manifest.Games).Count
                ChangesExecuted = $false
            }) `
            -VerificationStatus 'NotApplicable'
    }

    try {
        $data = Invoke-BoostLabGameConfigApply `
            -Game $game `
            -RendererWorkerCount $RendererWorkerCount `
            -FolderSelections $FolderSelections `
            -PromptValues $PromptValues `
            -OperationAdapter $OperationAdapter

        return New-BoostLabGameConfigResult `
            -Success $true `
            -Status 'Completed' `
            -ActionName $ActionName `
            -Message ("Applied upstream Game Configs recipe for {0}." -f [string]$game['DisplayName']) `
            -Data $data `
            -VerificationStatus 'Passed'
    }
    catch {
        return New-BoostLabGameConfigResult `
            -Success $false `
            -Status 'Error' `
            -ActionName $ActionName `
            -Message ("Game Configs Apply failed closed for {0}: {1}" -f [string]$game['DisplayName'], $_.Exception.Message) `
            -Data ([pscustomobject]@{
                GameId = [string]$game['GameId']
                DisplayName = [string]$game['DisplayName']
                ChangesExecuted = $false
            }) `
            -Errors @($_.Exception.Message) `
            -VerificationStatus 'Failed'
    }
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo',
    'Test-BoostLabToolCompatibility',
    'Get-BoostLabToolState',
    'Invoke-BoostLabToolAction',
    'Restore-BoostLabToolDefault',
    'Get-BoostLabGameConfigRuntimeManifest'
)
