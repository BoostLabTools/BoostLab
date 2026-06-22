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
        throw 'Unable to determine the Game Configs Stage 8 runtime validator path.'
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

$modulePath = Join-Path $ProjectRoot 'modules\GameConfigs\game-configs.psm1'
$manifestPath = Join-Path $ProjectRoot 'config\GameConfigs.psd1'
$sourcesPath = Join-Path $ProjectRoot 'config\GameConfigArtifactSources.psd1'
$provenancePath = Join-Path $ProjectRoot 'config\GameConfigArtifactProvenance.psd1'
$stagesPath = Join-Path $ProjectRoot 'config\Stages.psd1'

foreach ($requiredPath in @($modulePath, $manifestPath, $sourcesPath, $provenancePath, $stagesPath)) {
    Assert-BoostLabCondition (Test-Path -LiteralPath $requiredPath -PathType Leaf) "Required Game Configs runtime file is missing: $requiredPath"
}

Import-Module -Name $modulePath -Force -ErrorAction Stop

$manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
$sources = Import-PowerShellDataFile -LiteralPath $sourcesPath
$provenance = Import-PowerShellDataFile -LiteralPath $provenancePath
$stages = Import-PowerShellDataFile -LiteralPath $stagesPath

$gameStage = @($stages.Stages | Where-Object { [string]$_.Name -eq 'Game Configs' }) | Select-Object -First 1
$gameTool = @($gameStage.Tools | Where-Object { [string]$_.Id -eq 'game-configs' }) | Select-Object -First 1
Assert-BoostLabCondition ($null -ne $gameStage) 'Game Configs stage is missing.'
Assert-BoostLabCondition ($null -ne $gameTool) 'Game Configs tool is missing.'
Assert-BoostLabCondition ((@($gameTool.Actions) -join '|') -eq 'Apply') 'Game Configs must expose Apply only.'
Assert-BoostLabCondition ([string]$gameTool.SelectionMode -eq 'SingleSelect') 'Game Configs must use single-select selection.'
Assert-BoostLabCondition (@($gameTool.SelectionItems).Count -eq 27) 'Game Configs must expose 27 selectable entries.'
Assert-BoostLabCondition (@($manifest.Games).Count -eq 27) 'Game Configs runtime manifest must contain 27 recipes.'
Assert-BoostLabCondition ($manifest.RuntimeUsesBoostLabMirrors -eq $true) 'Runtime manifest must use BoostLab mirrors.'
Assert-BoostLabCondition ($manifest.RuntimeUsesRawUpstreamPayloadUrls -eq $false) 'Runtime manifest must not use raw upstream payload URLs.'
Assert-BoostLabCondition (@($sources.PayloadSources).Count -eq 28) 'Game Configs source manifest must contain 28 payload records.'
Assert-BoostLabCondition (@($provenance.ProvenanceApprovals).Count -eq 28) 'Game Configs provenance manifest must contain 28 payload records.'

function New-MockedGameConfigAdapter {
    param(
        [Parameter(Mandatory)]
        [object]$PayloadSources
    )

    $operations = [System.Collections.Generic.List[object]]::new()
    $pathToArtifact = @{}
    $sourceByArtifact = @{}
    foreach ($source in @($PayloadSources)) {
        $sourceByArtifact[[string]$source.ManifestCandidateId] = $source
    }

    $adapter = @{
        Download = {
            param($ArtifactId, $Url, $Destination, $ExpectedName)
            $operations.Add([pscustomobject]@{
                Operation = 'Download'
                ArtifactId = [string]$ArtifactId
                Url = [string]$Url
                Destination = [string]$Destination
                ExpectedName = [string]$ExpectedName
            }) | Out-Null
            $pathToArtifact[[string]$Destination] = [string]$ArtifactId
            return $true
        }
        GetFileSize = {
            param($Path)
            $artifactId = [string]$pathToArtifact[[string]$Path]
            return [int64]$sourceByArtifact[$artifactId].ExpectedSizeBytes
        }
        GetFileHash = {
            param($Path)
            $artifactId = [string]$pathToArtifact[[string]$Path]
            return [string]$sourceByArtifact[$artifactId].ExpectedSha256
        }
        ExpandArchive = {
            param($ArchivePath, $DestinationPath, $ArtifactId)
            $operations.Add([pscustomobject]@{ Operation = 'ExpandArchive'; ArchivePath = [string]$ArchivePath; DestinationPath = [string]$DestinationPath; ArtifactId = [string]$ArtifactId }) | Out-Null
            return $true
        }
        EnsureDirectory = {
            param($Path)
            $operations.Add([pscustomobject]@{ Operation = 'EnsureDirectory'; Path = [string]$Path }) | Out-Null
            return $true
        }
        CopyItem = {
            param($Source, $Destination, $Recurse, $Force)
            $operations.Add([pscustomobject]@{ Operation = 'CopyItem'; Source = [string]$Source; Destination = [string]$Destination; Recurse = [bool]$Recurse; Force = [bool]$Force }) | Out-Null
            return $true
        }
        MoveItem = {
            param($Source, $Destination, $Force)
            $operations.Add([pscustomobject]@{ Operation = 'MoveItem'; Source = [string]$Source; Destination = [string]$Destination; Force = [bool]$Force }) | Out-Null
            return $true
        }
        RemoveItem = {
            param($Path)
            $operations.Add([pscustomobject]@{ Operation = 'RemoveItem'; Path = [string]$Path }) | Out-Null
            return $true
        }
        TestPath = {
            param($Path)
            $operations.Add([pscustomobject]@{ Operation = 'TestPath'; Path = [string]$Path }) | Out-Null
            return $true
        }
        PromptFolder = {
            param($Prompt, $Id)
            $operations.Add([pscustomobject]@{ Operation = 'PromptFolder'; Id = [string]$Id; Prompt = [string]$Prompt }) | Out-Null
            return "C:\Mock\$Id"
        }
        PromptText = {
            param($Prompt)
            $operations.Add([pscustomobject]@{ Operation = 'PromptText'; Prompt = [string]$Prompt }) | Out-Null
            return '6'
        }
        ReplaceRendererWorkerCount = {
            param($Path, $RendererWorkerCount)
            $operations.Add([pscustomobject]@{ Operation = 'ReplaceRendererWorkerCount'; Path = [string]$Path; RendererWorkerCount = [string]$RendererWorkerCount }) | Out-Null
            return $true
        }
        UnblockPath = {
            param($Path)
            $operations.Add([pscustomobject]@{ Operation = 'UnblockPath'; Path = [string]$Path }) | Out-Null
            return $true
        }
        StartProcess = {
            param($FilePath, $ArgumentList, $Wait)
            $operations.Add([pscustomobject]@{ Operation = 'StartProcess'; FilePath = [string]$FilePath; ArgumentList = [string]$ArgumentList; Wait = [bool]$Wait }) | Out-Null
            return $true
        }
        Sleep = {
            param($Seconds)
            $operations.Add([pscustomobject]@{ Operation = 'Sleep'; Seconds = [int]$Seconds }) | Out-Null
            return $true
        }
    }

    foreach ($key in @($adapter.Keys)) {
        $adapter[$key] = $adapter[$key].GetNewClosure()
    }

    return [pscustomobject]@{
        Adapter = $adapter
        Operations = $operations
    }
}

function Invoke-MockedGameConfigApply {
    param(
        [Parameter(Mandatory)]
        [string]$GameId,

        [hashtable]$FolderSelections = @{},

        [string]$RendererWorkerCount = ''
    )

    $mock = New-MockedGameConfigAdapter -PayloadSources $sources.PayloadSources
    $result = Invoke-BoostLabToolAction `
        -ActionName 'Apply' `
        -Confirmed:$true `
        -Branch $GameId `
        -FolderSelections $FolderSelections `
        -RendererWorkerCount $RendererWorkerCount `
        -OperationAdapter $mock.Adapter

    return [pscustomobject]@{
        Result = $result
        Operations = @($mock.Operations)
    }
}

$toolInfo = Get-BoostLabToolInfo
Assert-BoostLabCondition ([string]$toolInfo.Id -eq 'game-configs') 'Game Configs tool info id mismatch.'
Assert-BoostLabCondition ((@($toolInfo.Actions) -join '|') -eq 'Apply') 'Game Configs tool info must expose Apply only.'
Assert-BoostLabCondition ($toolInfo.SupportsDefault -eq $false) 'Game Configs must not support Default.'
Assert-BoostLabCondition ($toolInfo.SupportsRestore -eq $false) 'Game Configs must not support Restore.'
Assert-BoostLabCondition ($toolInfo.SupportsAnalyze -eq $false) 'Game Configs must not support Analyze.'

$missingSelectionMock = New-MockedGameConfigAdapter -PayloadSources $sources.PayloadSources
$missingSelection = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$true -Branch '' -OperationAdapter $missingSelectionMock.Adapter
Assert-BoostLabCondition ($missingSelection.Success -eq $false) 'Game Configs Apply without selection must fail closed.'
Assert-BoostLabCondition ([string]$missingSelection.Status -eq 'SelectionRequired') 'Game Configs Apply without selection must report SelectionRequired.'
Assert-BoostLabCondition (@($missingSelectionMock.Operations).Count -eq 0) 'Game Configs missing-selection path must not run operations.'

$multiSelectionMock = New-MockedGameConfigAdapter -PayloadSources $sources.PayloadSources
$multiSelection = Invoke-BoostLabToolAction -ActionName 'Apply' -Confirmed:$true -Branch @('arc-raiders', 'frag-punk') -OperationAdapter $multiSelectionMock.Adapter
Assert-BoostLabCondition ($multiSelection.Success -eq $false) 'Game Configs Apply with multiple selections must fail closed.'
Assert-BoostLabCondition ([string]$multiSelection.Status -eq 'SelectionRequired') 'Game Configs multi-select must report SelectionRequired.'
Assert-BoostLabCondition (@($multiSelectionMock.Operations).Count -eq 0) 'Game Configs multi-select path must not run operations.'

$arc = Invoke-MockedGameConfigApply -GameId 'arc-raiders'
Assert-BoostLabCondition ($arc.Result.Success -eq $true) 'ARC Raiders Apply should complete through mocked operations.'
Assert-BoostLabCondition ('Download' -in @($arc.Operations.Operation)) 'ARC Raiders must download the verified mirror payload.'
Assert-BoostLabCondition ('ExpandArchive' -in @($arc.Operations.Operation)) 'ARC Raiders must extract the payload.'
Assert-BoostLabCondition ('CopyItem' -in @($arc.Operations.Operation)) 'ARC Raiders must copy source-defined config files.'
Assert-BoostLabCondition (@($arc.Operations | Where-Object { [string]$_.Operation -eq 'Download' -and [string]$_.Url -like 'https://github.com/BoostLabTools/BoostLab/releases/download/boostlab-game-configs-v1/*' }).Count -eq 1) 'ARC Raiders must download only from the verified BoostLab mirror URL.'
Assert-BoostLabCondition (@($arc.Operations | Where-Object { [string]$_.Operation -eq 'Download' -and [string]$_.Url -like 'https://github.com/FR33THYFR33THY/*' }).Count -eq 0) 'ARC Raiders must not use raw upstream payload URLs at runtime.'

$bf6 = Invoke-MockedGameConfigApply -GameId 'battlefield-6' -FolderSelections @{ InstallFolder = 'C:\Mock\Battlefield6' }
Assert-BoostLabCondition ($bf6.Result.Success -eq $true) 'Battlefield 6 Apply should complete through mocked operations.'
Assert-BoostLabCondition (@($bf6.Operations | Where-Object { [string]$_.Operation -eq 'Download' -and [string]$_.ArtifactId -eq 'game-configs.profile-inspector.inspector-exe' }).Count -eq 1) 'Battlefield 6 must download the verified inspector artifact.'
Assert-BoostLabCondition (@($bf6.Operations | Where-Object { [string]$_.Operation -eq 'StartProcess' -and [string]$_.ArgumentList -like '*Battlefield6.nip -silent*' }).Count -eq 1) 'Battlefield 6 must invoke inspector with Battlefield6.nip -silent.'
Assert-BoostLabCondition (@($bf6.Operations | Where-Object { [string]$_.Operation -eq 'RemoveItem' -and [string]$_.Path -like '*Battlefield 6*' }).Count -ge 1) 'Battlefield 6 must preserve source-defined local folder cleanup.'

$fragPunk = Invoke-MockedGameConfigApply -GameId 'frag-punk'
Assert-BoostLabCondition ($fragPunk.Result.Success -eq $true) 'Frag Punk Apply should complete through mocked operations.'
Assert-BoostLabCondition (@($fragPunk.Operations | Where-Object { [string]$_.Operation -eq 'Download' -and [string]$_.ArtifactId -eq 'game-configs.profile-inspector.inspector-exe' }).Count -eq 1) 'Frag Punk must download the verified inspector artifact.'
Assert-BoostLabCondition (@($fragPunk.Operations | Where-Object { [string]$_.Operation -eq 'StartProcess' -and [string]$_.ArgumentList -like '*FragPunk.nip -silent*' }).Count -eq 1) 'Frag Punk must invoke inspector with FragPunk.nip -silent.'

$bf3 = Invoke-MockedGameConfigApply -GameId 'battlefield-3' -FolderSelections @{ InstallFolder = 'C:\Mock\Battlefield3' }
Assert-BoostLabCondition ($bf3.Result.Success -eq $true) 'Battlefield 3 Apply should complete through mocked operations.'
Assert-BoostLabCondition (@($bf3.Operations | Where-Object { [string]$_.Operation -eq 'StartProcess' -and [string]$_.FilePath -eq 'https://veniceunleashed.net' -and [bool]$_.Wait -eq $false }).Count -eq 1) 'Battlefield 3 must preserve the Venice Unleashed browser-open behavior.'

$badCompany2 = Invoke-MockedGameConfigApply -GameId 'battlefield-bad-company-2' -FolderSelections @{ InstallFolder = 'C:\Mock\BadCompany2' }
Assert-BoostLabCondition ($badCompany2.Result.Success -eq $true) 'Battlefield Bad Company 2 Apply should complete through mocked operations.'
Assert-BoostLabCondition (@($badCompany2.Operations | Where-Object { [string]$_.Operation -eq 'StartProcess' -and [string]$_.FilePath -eq 'https://veniceunleashed.net/project-rome' -and [bool]$_.Wait -eq $false }).Count -eq 1) 'Battlefield Bad Company 2 must preserve the Project Rome browser-open behavior.'

$blackOps6 = Invoke-MockedGameConfigApply -GameId 'call-of-duty-black-ops-6' -RendererWorkerCount '7'
Assert-BoostLabCondition ($blackOps6.Result.Success -eq $true) 'Black Ops 6 Apply should complete through mocked operations.'
Assert-BoostLabCondition (@($blackOps6.Operations | Where-Object { [string]$_.Operation -eq 'ReplaceRendererWorkerCount' -and [string]$_.RendererWorkerCount -eq '7' }).Count -ge 1) 'Black Ops 6 must preserve RendererWorkerCount replacement behavior.'

$allOperations = @($arc.Operations + $bf6.Operations + $fragPunk.Operations + $bf3.Operations + $badCompany2.Operations + $blackOps6.Operations)
Assert-BoostLabCondition (@($allOperations | Where-Object { [string]$_.Operation -eq 'StartProcess' -and [string]$_.ArgumentList -like '*-silent*' }).Count -eq 2) 'Only Battlefield 6 and Frag Punk should use inspector process execution in the mocked coverage.'
Assert-BoostLabCondition (@($allOperations | Where-Object { [string]$_.Operation -eq 'StartProcess' -and [string]$_.FilePath -like 'https://veniceunleashed.net*' }).Count -eq 2) 'Only Battlefield 3 and Battlefield Bad Company 2 should open browser URLs in the mocked coverage.'
Assert-BoostLabCondition (@($allOperations | Where-Object { [string]$_.Operation -eq 'Download' -and [string]$_.Url -like 'https://github.com/FR33THYFR33THY/*' }).Count -eq 0) 'No mocked runtime download may use raw upstream payload URLs.'

$moduleText = Get-Content -LiteralPath $modulePath -Raw
Assert-BoostLabCondition ($moduleText -notmatch 'Invoke-Expression') 'Game Configs runtime must not use Invoke-Expression.'
Assert-BoostLabCondition ($moduleText -notmatch 'irm\\s*\\|\\s*iex') 'Game Configs runtime must not use irm | iex.'
Assert-BoostLabCondition ($moduleText -notmatch 'AllowScripts\\.cmd') 'Game Configs runtime must not include AllowScripts.cmd.'
Assert-BoostLabCondition ($moduleText -notmatch 'FR33THYFR33THY/Github-Game-Configs/raw') 'Game Configs runtime must not use raw upstream payload URLs.'

Write-Host 'Game Configs Stage 8 Apply-only runtime validated with mocked operations.'
