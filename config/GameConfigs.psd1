@{
    SchemaVersion = '1.0'
    Phase = '165D'
    Stage = 'Game Configs'
    StageOrder = 8
    ToolId = 'game-configs'
    ToolTitle = 'Game Configs'
    ImplementedActions = @('Apply')
    UpstreamRepository = 'FR33THYFR33THY/Github-Game-Configs'
    UpstreamLauncherRecipe = 'IWR.ps1'
    UpstreamLauncherRuntimeIncluded = $false
    RuntimeUsesRawUpstreamPayloadUrls = $false
    RuntimeUsesBoostLabMirrors = $true
    DisallowedRuntimePatterns = @(
        'IWR.ps1'
        'irm'
        'iex'
        'AllowScripts.cmd'
    )
    InspectorArtifactId = 'game-configs.profile-inspector.inspector-exe'
    Games = @(
        @{
            GameId = 'arc-raiders'
            SourceMenuNumber = 2
            Group = 'ARC Raiders'
            DisplayName = 'ARC Raiders'
            ArtifactId = 'game-configs.arc-raiders'
            ArtifactSourceId = 'game-configs-arc-raiders'
            SourceRecipePath = 'ARC Raiders/ARC Raiders.ps1'
            SourceRecipeSha256 = 'B79690867089AA5286C3310F6926A101481172AC4FE0615F3BFFD052C644D2AF'
            ArchivePath = '$env:SystemRoot\Temp\ARC Raiders.zip'
            ExtractPath = '$env:SystemRoot\Temp\ARC Raiders'
            CopyOperations = @(
                @{ Source = '$ExtractPath\*'; Destination = '$env:LOCALAPPDATA\PioneerGame\Saved\Config\WindowsClient'; Recurse = $true; Force = $true }
            )
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Copy extracted payload into PioneerGame WindowsClient config.')
            NeedsInspector = $false
            OpensUrl = $false
        }
        @{
            GameId = 'battlefield-6'
            SourceMenuNumber = 3.1
            Group = 'Battlefield'
            DisplayName = 'Battlefield 6'
            ArtifactId = 'game-configs.battlefield-6'
            ArtifactSourceId = 'game-configs-battlefield-6'
            SourceRecipePath = 'Battlefield/Battlefield 6.ps1'
            SourceRecipeSha256 = '32BFA5BA139216188180523253C4363BBFB9E2637FA820AAC52885A26A8200BC'
            ArchivePath = '$env:SystemRoot\Temp\Battlefield6.zip'
            ExtractPath = '$env:SystemRoot\Temp\Battlefield6'
            PromptedFolders = @(
                @{ Id = 'InstallFolder'; Prompt = 'Select Battlefield 6 install folder' }
            )
            CopyOperations = @(
                @{ Source = '$ExtractPath\PROFSAVEbf6mp_profile'; Destination = '$env:USERPROFILE\Documents\Battlefield 6\settings\PROFSAVEbf6mp_profile'; Force = $true; OnlyIfDestinationExists = $true }
                @{ Source = '$ExtractPath\PROFSAVEbf6mp_profile'; Destination = '$env:USERPROFILE\Documents\Battlefield 6\settings\steam\PROFSAVEbf6mp_profile'; Force = $true; OnlyIfDestinationExists = $true }
                @{ Source = '$ExtractPath\PROFSAVEbf6mp_profile'; Destination = '$env:USERPROFILE\Documents\Battlefield 6\settings\epic\PROFSAVEbf6mp_profile'; Force = $true; OnlyIfDestinationExists = $true }
                @{ Source = '$ExtractPath\PROFSAVEbf6mp_profile'; Destination = '$env:USERPROFILE\OneDrive\Documents\Battlefield 6\settings\PROFSAVEbf6mp_profile'; Force = $true; OnlyIfDestinationExists = $true }
                @{ Source = '$ExtractPath\PROFSAVEbf6mp_profile'; Destination = '$env:USERPROFILE\OneDrive\Documents\Battlefield 6\settings\steam\PROFSAVEbf6mp_profile'; Force = $true; OnlyIfDestinationExists = $true }
                @{ Source = '$ExtractPath\PROFSAVEbf6mp_profile'; Destination = '$env:USERPROFILE\OneDrive\Documents\Battlefield 6\settings\epic\PROFSAVEbf6mp_profile'; Force = $true; OnlyIfDestinationExists = $true }
                @{ Source = '$ExtractPath\user.cfg'; Destination = '$InstallFolder'; Force = $true }
            )
            RemovePaths = @('$env:LOCALAPPDATA\Battlefield 6')
            Inspector = @{ ArtifactId = 'game-configs.profile-inspector.inspector-exe'; Destination = '$ExtractPath\RebarOnInspector\inspector.exe'; Arguments = '$ExtractPath\RebarOnInspector\Battlefield6.nip -silent'; UnblockPath = 'C:\ProgramData\NVIDIA Corporation\Drs'; WaitSeconds = 3 }
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Replace PROFSAVEbf6mp_profile only when each destination file already exists.', 'Copy user.cfg to the selected Battlefield 6 install folder.', 'Delete Battlefield 6 local shader/cache folder.', 'Import Battlefield6.nip through inspector.exe.')
            NeedsInspector = $true
            OpensUrl = $false
        }
        @{
            GameId = 'battlefield-2042'
            SourceMenuNumber = 3.2
            Group = 'Battlefield'
            DisplayName = 'Battlefield 2042'
            ArtifactId = 'game-configs.battlefield-2042'
            ArtifactSourceId = 'game-configs-battlefield-2042'
            SourceRecipePath = 'Battlefield/Battlefield 2042.ps1'
            SourceRecipeSha256 = '3B2A513E918F13A79890B1A2F0DE037B4AA0378B0EC2BCC36DF70F0A196C88AA'
            ArchivePath = '$env:SystemRoot\Temp\Battlefield 2042.zip'
            ExtractPath = '$env:SystemRoot\Temp\Battlefield 2042'
            EnsureDirectories = @('$env:USERPROFILE\Documents\Battlefield 2042\settings', '$env:USERPROFILE\OneDrive\Documents\Battlefield 2042\settings')
            PromptedFolders = @(@{ Id = 'InstallFolder'; Prompt = 'Select Battlefield 2042 install folder' })
            CopyOperations = @(
                @{ Source = '$ExtractPath\*'; Destination = '$env:USERPROFILE\Documents\Battlefield 2042\settings'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\*'; Destination = '$env:USERPROFILE\OneDrive\Documents\Battlefield 2042\settings'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\user.cfg'; Destination = '$InstallFolder'; Force = $true }
            )
            RemovePaths = @('$env:LOCALAPPDATA\BattlefieldGameData.kin-release.Win32', '$env:USERPROFILE\Documents\Battlefield 2042\settings\user.cfg', '$env:USERPROFILE\OneDrive\Documents\Battlefield 2042\settings\user.cfg')
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Copy extracted payload into Documents and OneDrive settings, copy user.cfg to selected install folder, then remove settings user.cfg copies and BattlefieldGameData cache.')
            NeedsInspector = $false
            OpensUrl = $false
        }
        @{
            GameId = 'battlefield-v'
            SourceMenuNumber = 3.3
            Group = 'Battlefield'
            DisplayName = 'Battlefield V'
            ArtifactId = 'game-configs.battlefield-v'
            ArtifactSourceId = 'game-configs-battlefield-v'
            SourceRecipePath = 'Battlefield/Battlefield V.ps1'
            SourceRecipeSha256 = 'F7E03572B2812C423BAFFD2F7CC1D3110FDB0E9C83867E7CC8B6FE446E7162FB'
            ArchivePath = '$env:SystemRoot\Temp\Battlefield V.zip'
            ExtractPath = '$env:SystemRoot\Temp\Battlefield V'
            EnsureDirectories = @('$env:USERPROFILE\Documents\Battlefield V\settings', '$env:USERPROFILE\OneDrive\Documents\Battlefield V\settings')
            PromptedFolders = @(@{ Id = 'InstallFolder'; Prompt = 'Select Battlefield V install folder' })
            CopyOperations = @(
                @{ Source = '$ExtractPath\*'; Destination = '$env:USERPROFILE\Documents\Battlefield V\settings'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\*'; Destination = '$env:USERPROFILE\OneDrive\Documents\Battlefield V\settings'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\user.cfg'; Destination = '$InstallFolder'; Force = $true }
            )
            RemovePaths = @('$env:USERPROFILE\Documents\Battlefield V\settings\user.cfg', '$env:USERPROFILE\OneDrive\Documents\Battlefield V\settings\user.cfg')
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Copy extracted payload into Documents and OneDrive settings, copy user.cfg to selected install folder, then remove settings user.cfg copies.')
            NeedsInspector = $false
            OpensUrl = $false
        }
        @{
            GameId = 'battlefield-1'
            SourceMenuNumber = 3.4
            Group = 'Battlefield'
            DisplayName = 'Battlefield 1'
            ArtifactId = 'game-configs.battlefield-1'
            ArtifactSourceId = 'game-configs-battlefield-1'
            SourceRecipePath = 'Battlefield/Battlefield 1.ps1'
            SourceRecipeSha256 = '8EED1098B753E7B4E002186CDA36AAC2ED4BB1F3C26A29B2AC2249BFAD1EADCD'
            ArchivePath = '$env:SystemRoot\Temp\Battlefield 1.zip'
            ExtractPath = '$env:SystemRoot\Temp\Battlefield 1'
            EnsureDirectories = @('$env:USERPROFILE\Documents\Battlefield 1\settings', '$env:USERPROFILE\OneDrive\Documents\Battlefield 1\settings')
            PromptedFolders = @(@{ Id = 'InstallFolder'; Prompt = 'Select Battlefield 1 install folder' })
            CopyOperations = @(
                @{ Source = '$ExtractPath\*'; Destination = '$env:USERPROFILE\Documents\Battlefield 1\settings'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\*'; Destination = '$env:USERPROFILE\OneDrive\Documents\Battlefield 1\settings'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\user.cfg'; Destination = '$InstallFolder'; Force = $true }
            )
            RemovePaths = @('$env:USERPROFILE\Documents\Battlefield 1\settings\user.cfg', '$env:USERPROFILE\OneDrive\Documents\Battlefield 1\settings\user.cfg')
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Copy extracted payload into Documents and OneDrive settings, copy user.cfg to selected install folder, then remove settings user.cfg copies.')
            NeedsInspector = $false
            OpensUrl = $false
        }
        @{
            GameId = 'battlefield-hardline'
            SourceMenuNumber = 3.5
            Group = 'Battlefield'
            DisplayName = 'Battlefield Hardline'
            ArtifactId = 'game-configs.battlefield-hardline'
            ArtifactSourceId = 'game-configs-battlefield-hardline'
            SourceRecipePath = 'Battlefield/Battlefield Hardline.ps1'
            SourceRecipeSha256 = 'A517CD828F676544F390768D3449CA2B66718A2855DD0A43A65FDC0A410389A0'
            ArchivePath = '$env:SystemRoot\Temp\Battlefield Hardline.zip'
            ExtractPath = '$env:SystemRoot\Temp\Battlefield Hardline'
            EnsureDirectories = @('$env:USERPROFILE\Documents\BFH\settings', '$env:USERPROFILE\OneDrive\Documents\BFH\settings')
            PromptedFolders = @(@{ Id = 'InstallFolder'; Prompt = 'Select Battlefield Hardline install folder' })
            CopyOperations = @(
                @{ Source = '$ExtractPath\*'; Destination = '$env:USERPROFILE\Documents\BFH\settings'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\*'; Destination = '$env:USERPROFILE\OneDrive\Documents\BFH\settings'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\user.cfg'; Destination = '$InstallFolder'; Force = $true }
            )
            RemovePaths = @('$env:USERPROFILE\Documents\BFH\settings\user.cfg', '$env:USERPROFILE\OneDrive\Documents\BFH\settings\user.cfg')
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Copy extracted payload into Documents and OneDrive BFH settings, copy user.cfg to selected install folder, then remove settings user.cfg copies.')
            NeedsInspector = $false
            OpensUrl = $false
        }
        @{
            GameId = 'battlefield-4'
            SourceMenuNumber = 3.6
            Group = 'Battlefield'
            DisplayName = 'Battlefield 4'
            ArtifactId = 'game-configs.battlefield-4'
            ArtifactSourceId = 'game-configs-battlefield-4'
            SourceRecipePath = 'Battlefield/Battlefield 4.ps1'
            SourceRecipeSha256 = 'D6FF41179A462343273D1DD4F0AA9006FC0AD3BB0F27C4CD3640462BCD69491F'
            ArchivePath = '$env:SystemRoot\Temp\Battlefield 4.zip'
            ExtractPath = '$env:SystemRoot\Temp\Battlefield 4'
            EnsureDirectories = @('$env:USERPROFILE\Documents\Battlefield 4\settings', '$env:USERPROFILE\OneDrive\Documents\Battlefield 4\settings')
            PromptedFolders = @(@{ Id = 'InstallFolder'; Prompt = 'Select Battlefield 4 install folder' })
            CopyOperations = @(
                @{ Source = '$ExtractPath\*'; Destination = '$env:USERPROFILE\Documents\Battlefield 4\settings'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\*'; Destination = '$env:USERPROFILE\OneDrive\Documents\Battlefield 4\settings'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\user.cfg'; Destination = '$InstallFolder'; Force = $true }
            )
            RemovePaths = @('$env:USERPROFILE\Documents\Battlefield 4\settings\user.cfg', '$env:USERPROFILE\OneDrive\Documents\Battlefield 4\settings\user.cfg')
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Copy extracted payload into Documents and OneDrive settings, copy user.cfg to selected install folder, then remove settings user.cfg copies.')
            NeedsInspector = $false
            OpensUrl = $false
        }
        @{
            GameId = 'battlefield-3'
            SourceMenuNumber = 3.7
            Group = 'Battlefield'
            DisplayName = 'Battlefield 3'
            ArtifactId = 'game-configs.battlefield-3'
            ArtifactSourceId = 'game-configs-battlefield-3'
            SourceRecipePath = 'Battlefield/Battlefield 3.ps1'
            SourceRecipeSha256 = 'D6BE552FF2A390F139FAFF9E430EACA615072E0D765137F222F76F46B9ED6681'
            ArchivePath = '$env:SystemRoot\Temp\Battlefield 3.zip'
            ExtractPath = '$env:SystemRoot\Temp\Battlefield 3'
            EnsureDirectories = @('$env:USERPROFILE\Documents\Battlefield 3\settings', '$env:USERPROFILE\OneDrive\Documents\Battlefield 3\settings')
            PromptedFolders = @(@{ Id = 'InstallFolder'; Prompt = 'Select Battlefield 3 install folder' })
            CopyOperations = @(
                @{ Source = '$ExtractPath\*'; Destination = '$env:USERPROFILE\Documents\Battlefield 3\settings'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\*'; Destination = '$env:USERPROFILE\OneDrive\Documents\Battlefield 3\settings'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\user.cfg'; Destination = '$InstallFolder'; Force = $true }
            )
            RemovePaths = @('$env:USERPROFILE\Documents\Battlefield 3\settings\user.cfg', '$env:USERPROFILE\OneDrive\Documents\Battlefield 3\settings\user.cfg', '$env:USERPROFILE\Documents\Battlefield 3\settings\Venice Unleashed.url', '$env:USERPROFILE\OneDrive\Documents\Battlefield 3\settings\Venice Unleashed.url')
            OpenUrls = @('https://veniceunleashed.net')
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Copy extracted payload into Documents and OneDrive settings, copy user.cfg to selected install folder, remove settings user.cfg and Venice Unleashed.url copies, then open Venice Unleashed.')
            NeedsInspector = $false
            OpensUrl = $true
        }
        @{
            GameId = 'battlefield-bad-company-2'
            SourceMenuNumber = 3.8
            Group = 'Battlefield'
            DisplayName = 'Battlefield Bad Company 2'
            ArtifactId = 'game-configs.battlefield-bad-company-2'
            ArtifactSourceId = 'game-configs-battlefield-bad-company-2'
            SourceRecipePath = 'Battlefield/Battlefield Bad Company 2.ps1'
            SourceRecipeSha256 = '959D8C135C618D81EC56BC08104122126B5A4933F7162BF9CD67BEF2D9617667'
            ArchivePath = '$env:SystemRoot\Temp\Battlefield Bad Company 2.zip'
            ExtractPath = '$env:SystemRoot\Temp\Battlefield Bad Company 2'
            EnsureDirectories = @('$env:USERPROFILE\Documents\BFBC2\input', '$env:USERPROFILE\OneDrive\Documents\BFBC2\input')
            CopyOperations = @(
                @{ Source = '$ExtractPath\*'; Destination = '$env:USERPROFILE\Documents\BFBC2'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\*'; Destination = '$env:USERPROFILE\OneDrive\Documents\BFBC2'; Recurse = $true; Force = $true }
            )
            MoveOperations = @(
                @{ Source = '$env:USERPROFILE\Documents\BFBC2\air.dbx'; Destination = '$env:USERPROFILE\Documents\BFBC2\input'; Force = $true }
                @{ Source = '$env:USERPROFILE\Documents\BFBC2\infantry.dbx'; Destination = '$env:USERPROFILE\Documents\BFBC2\input'; Force = $true }
                @{ Source = '$env:USERPROFILE\Documents\BFBC2\land.dbx'; Destination = '$env:USERPROFILE\Documents\BFBC2\input'; Force = $true }
                @{ Source = '$env:USERPROFILE\Documents\BFBC2\shared.dbx'; Destination = '$env:USERPROFILE\Documents\BFBC2\input'; Force = $true }
                @{ Source = '$env:USERPROFILE\OneDrive\Documents\BFBC2\air.dbx'; Destination = '$env:USERPROFILE\OneDrive\Documents\BFBC2\input'; Force = $true }
                @{ Source = '$env:USERPROFILE\OneDrive\Documents\BFBC2\infantry.dbx'; Destination = '$env:USERPROFILE\OneDrive\Documents\BFBC2\input'; Force = $true }
                @{ Source = '$env:USERPROFILE\OneDrive\Documents\BFBC2\land.dbx'; Destination = '$env:USERPROFILE\OneDrive\Documents\BFBC2\input'; Force = $true }
                @{ Source = '$env:USERPROFILE\OneDrive\Documents\BFBC2\shared.dbx'; Destination = '$env:USERPROFILE\OneDrive\Documents\BFBC2\input'; Force = $true }
            )
            RemovePaths = @('$env:USERPROFILE\Documents\BFBC2\Project Rome.url', '$env:USERPROFILE\OneDrive\Documents\BFBC2\Project Rome.url')
            OpenUrls = @('https://veniceunleashed.net/project-rome')
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Copy extracted payload into BFBC2 roots, move DBX files into input folders, remove Project Rome.url files, then open Project Rome.')
            NeedsInspector = $false
            OpensUrl = $true
        }
        @{
            GameId = 'call-of-duty-black-ops-7'
            SourceMenuNumber = 4.1
            Group = 'Call of Duty'
            DisplayName = 'Call of Duty Black Ops 7'
            ArtifactId = 'game-configs.call-of-duty-black-ops-7'
            ArtifactSourceId = 'game-configs-call-of-duty-black-ops-7'
            SourceRecipePath = 'Call of Duty/Call of Duty Black Ops 7.ps1'
            SourceRecipeSha256 = '0750D024157EBEA919205852587B0358E500BC8EF1EB145CF79F01E5825E4453'
            ArchivePath = '$env:SystemRoot\Temp\BO7.zip'
            ExtractPath = '$env:SystemRoot\Temp\BO7'
            RendererReplacementFiles = @('$ExtractPath\players\s.1.0.cod25.txt0', '$ExtractPath\players\s.1.0.cod25.txt1')
            CopyOperations = @(@{ Source = '$ExtractPath\players\*'; Destination = '$env:LocalAppData\Activision\Call of Duty\players'; Recurse = $true; Force = $true })
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Prompt for RendererWorkerCount, replace $ placeholders in both BO7 player files, copy players payload.')
            NeedsInspector = $false
            OpensUrl = $false
        }
        @{
            GameId = 'call-of-duty-black-ops-6'
            SourceMenuNumber = 4.2
            Group = 'Call of Duty'
            DisplayName = 'Call of Duty Black Ops 6 & WZ'
            ArtifactId = 'game-configs.call-of-duty-black-ops-6'
            ArtifactSourceId = 'game-configs-call-of-duty-black-ops-6'
            SourceRecipePath = 'Call of Duty/Call of Duty Black Ops 6.ps1'
            SourceRecipeSha256 = '7FF714F634FF5773EEC18601C51960DB9433AFAB5F206DD8FC255E500981B658'
            ArchivePath = '$env:SystemRoot\Temp\BO6.zip'
            ExtractPath = '$env:SystemRoot\Temp\BO6'
            RendererReplacementFiles = @('$ExtractPath\players\s.1.0.cod24.txt0', '$ExtractPath\players\s.1.0.cod24.txt1')
            CopyOperations = @(
                @{ Source = '$ExtractPath\players\*'; Destination = '$env:USERPROFILE\Documents\Call of Duty\players'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\players\*'; Destination = '$env:USERPROFILE\OneDrive\Documents\Call of Duty\players'; Recurse = $true; Force = $true }
            )
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Prompt for RendererWorkerCount, replace $ placeholders in both BO6 player files, copy players payload.')
            NeedsInspector = $false
            OpensUrl = $false
        }
        @{
            GameId = 'call-of-duty-modern-warfare-3-2023'
            SourceMenuNumber = 4.3
            Group = 'Call of Duty'
            DisplayName = 'Call of Duty Modern Warfare 3 2023'
            ArtifactId = 'game-configs.call-of-duty-modern-warfare-3-2023'
            ArtifactSourceId = 'game-configs-call-of-duty-modern-warfare-3-2023'
            SourceRecipePath = 'Call of Duty/Call of Duty Modern Warfare 3 2023.ps1'
            SourceRecipeSha256 = 'C84C595414C5504674102340E7AA023D50F14063E8776217781300497E01E445'
            ArchivePath = '$env:SystemRoot\Temp\MW3.zip'
            ExtractPath = '$env:SystemRoot\Temp\MW3'
            RendererReplacementFiles = @('$ExtractPath\players\options.4.cod23.cst')
            CopyOperations = @(
                @{ Source = '$ExtractPath\players\*'; Destination = '$env:USERPROFILE\Documents\Call of Duty MWIII\players'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\players\*'; Destination = '$env:USERPROFILE\OneDrive\Documents\Call of Duty MWIII\players'; Recurse = $true; Force = $true }
            )
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Prompt for RendererWorkerCount, replace $ placeholders in MW3 options file, copy players payload.')
            NeedsInspector = $false
            OpensUrl = $false
        }
        @{
            GameId = 'call-of-duty-modern-warfare-2-2022'
            SourceMenuNumber = 4.4
            Group = 'Call of Duty'
            DisplayName = 'Call of Duty Modern Warfare 2 2022'
            ArtifactId = 'game-configs.call-of-duty-modern-warfare-2-2022'
            ArtifactSourceId = 'game-configs-call-of-duty-modern-warfare-2-2022'
            SourceRecipePath = 'Call of Duty/Call of Duty Modern Warfare 2 2022.ps1'
            SourceRecipeSha256 = '6DA0DDF1D6643833F6293CA1620249894929EC2E8771FB293528813629211948'
            ArchivePath = '$env:SystemRoot\Temp\MW2.zip'
            ExtractPath = '$env:SystemRoot\Temp\MW2'
            RendererReplacementFiles = @('$ExtractPath\players\options.3.cod22.cst')
            CopyOperations = @(
                @{ Source = '$ExtractPath\players\*'; Destination = '$env:USERPROFILE\Documents\Call of Duty MWII\players'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\players\*'; Destination = '$env:USERPROFILE\OneDrive\Documents\Call of Duty MWII\players'; Recurse = $true; Force = $true }
            )
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Prompt for RendererWorkerCount, replace $ placeholders in MW2 options file, copy players payload.')
            NeedsInspector = $false
            OpensUrl = $false
        }
        @{
            GameId = 'call-of-duty-black-ops-cold-war'
            SourceMenuNumber = 4.5
            Group = 'Call of Duty'
            DisplayName = 'Call of Duty Black Ops Cold War'
            ArtifactId = 'game-configs.call-of-duty-black-ops-cold-war'
            ArtifactSourceId = 'game-configs-call-of-duty-black-ops-cold-war'
            SourceRecipePath = 'Call of Duty/Call of Duty Black Ops Cold War.ps1'
            SourceRecipeSha256 = 'C4B567420027011A2DC17E07F2EE84EF5349D5E28E5A50067C1A20872981AE8B'
            ArchivePath = '$env:SystemRoot\Temp\ColdWar.zip'
            ExtractPath = '$env:SystemRoot\Temp\ColdWar'
            PromptedFolders = @(@{ Id = 'ConfigFolder1'; Prompt = 'Select Call Of Duty Black Ops Cold War YourID folder' })
            CopyOperations = @(
                @{ Source = '$ExtractPath\player\*'; Destination = '$env:USERPROFILE\Documents\Call Of Duty Black Ops Cold War\player'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\player\*'; Destination = '$env:USERPROFILE\OneDrive\Documents\Call Of Duty Black Ops Cold War\player'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\YourID\*'; Destination = '$ConfigFolder1'; Recurse = $true; Force = $true }
            )
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Copy player payload to Documents and OneDrive, then copy YourID payload to selected folder.')
            NeedsInspector = $false
            OpensUrl = $false
        }
        @{
            GameId = 'call-of-duty-vanguard'
            SourceMenuNumber = 4.6
            Group = 'Call of Duty'
            DisplayName = 'Call of Duty Vanguard'
            ArtifactId = 'game-configs.call-of-duty-vanguard'
            ArtifactSourceId = 'game-configs-call-of-duty-vanguard'
            SourceRecipePath = 'Call of Duty/Call of Duty Vanguard.ps1'
            SourceRecipeSha256 = '45591330401DC42D0B11D9E681D222B10001ABC2F4C8BD4B9F0E4C10C4C0CB76'
            ArchivePath = '$env:SystemRoot\Temp\Vanguard.zip'
            ExtractPath = '$env:SystemRoot\Temp\Vanguard'
            EnsureDirectories = @('$env:USERPROFILE\Documents\Call of Duty Vanguard\players', '$env:USERPROFILE\OneDrive\Documents\Call of Duty Vanguard\players')
            RendererReplacementFiles = @('$ExtractPath\players\options.Vanguard')
            CopyOperations = @(
                @{ Source = '$ExtractPath\players\*'; Destination = '$env:USERPROFILE\Documents\Call of Duty Vanguard\players'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\players\*'; Destination = '$env:USERPROFILE\OneDrive\Documents\Call of Duty Vanguard\players'; Recurse = $true; Force = $true }
            )
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Create player directories, prompt for RendererWorkerCount, replace $ placeholders in Vanguard options file, copy players payload.')
            NeedsInspector = $false
            OpensUrl = $false
        }
        @{
            GameId = 'call-of-duty-modern-warfare-2019'
            SourceMenuNumber = 4.7
            Group = 'Call of Duty'
            DisplayName = 'Call of Duty Modern Warfare 2019'
            ArtifactId = 'game-configs.call-of-duty-modern-warfare-2019'
            ArtifactSourceId = 'game-configs-call-of-duty-modern-warfare-2019'
            SourceRecipePath = 'Call of Duty/Call of Duty Modern Warfare 2019.ps1'
            SourceRecipeSha256 = '7FA69AC0B9B96F12365703F3D102EECE76F8B254BFDECDCC9E98A6877E2E36F3'
            ArchivePath = '$env:SystemRoot\Temp\2019.zip'
            ExtractPath = '$env:SystemRoot\Temp\2019'
            EnsureDirectories = @('$env:USERPROFILE\Documents\Call of Duty Modern Warfare\players', '$env:USERPROFILE\OneDrive\Documents\Call of Duty Modern Warfare\players')
            RendererReplacementFiles = @('$ExtractPath\players\adv_options.ini')
            CopyOperations = @(
                @{ Source = '$ExtractPath\players\*'; Destination = '$env:USERPROFILE\Documents\Call of Duty Modern Warfare\players'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\players\*'; Destination = '$env:USERPROFILE\OneDrive\Documents\Call of Duty Modern Warfare\players'; Recurse = $true; Force = $true }
            )
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Create player directories, prompt for RendererWorkerCount, replace $ placeholders in adv_options.ini, copy players payload.')
            NeedsInspector = $false
            OpensUrl = $false
        }
        @{
            GameId = 'call-of-duty-black-ops-4'
            SourceMenuNumber = 4.8
            Group = 'Call of Duty'
            DisplayName = 'Call of Duty Black Ops 4'
            ArtifactId = 'game-configs.call-of-duty-black-ops-4'
            ArtifactSourceId = 'game-configs-call-of-duty-black-ops-4'
            SourceRecipePath = 'Call of Duty/Call of Duty Black Ops 4.ps1'
            SourceRecipeSha256 = 'C9107B314479F79228277772CEF6BC2A4B75AE42AD815901C067F00E588737A7'
            ArchivePath = '$env:SystemRoot\Temp\BO4.zip'
            ExtractPath = '$env:SystemRoot\Temp\BO4'
            PromptedFolders = @(@{ Id = 'ConfigFolder1'; Prompt = 'Select Call of Duty Black Ops 4 YourID folder' })
            RendererReplacementFiles = @('$ExtractPath\players\config.ini')
            CopyOperations = @(
                @{ Source = '$ExtractPath\YourID\*'; Destination = '$ConfigFolder1'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\players\*'; Destination = '$ConfigFolder1'; Recurse = $true; Force = $true }
            )
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Prompt for RendererWorkerCount, replace $ placeholders in config.ini, select YourID folder, then copy YourID and players payloads to it.')
            NeedsInspector = $false
            OpensUrl = $false
        }
        @{
            GameId = 'counter-strike-2'
            SourceMenuNumber = 5
            Group = 'Counter Strike 2'
            DisplayName = 'Counter Strike 2'
            ArtifactId = 'game-configs.counter-strike-2'
            ArtifactSourceId = 'game-configs-counter-strike-2'
            SourceRecipePath = 'Counter Strike 2/Counter Strike 2.ps1'
            SourceRecipeSha256 = 'AA8C9BFAFA3EB57EF9BCA48A207C1ED44DC97BBB32FDF0745BEB9D098505A069'
            ArchivePath = '$env:SystemRoot\Temp\Counter Strike 2.zip'
            ExtractPath = '$env:SystemRoot\Temp\Counter Strike 2'
            PromptedFolders = @(@{ Id = 'ConfigFolder'; Prompt = 'Select Counter Strike 2 config folder' })
            CopyOperations = @(@{ Source = '$ExtractPath\*'; Destination = '$ConfigFolder'; Recurse = $true; Force = $true })
            RemovePaths = @('$ConfigFolder\-allow_third_party_software.launchoption')
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Copy extracted payload to selected config folder and remove -allow_third_party_software.launchoption.')
            NeedsInspector = $false
            OpensUrl = $false
        }
        @{
            GameId = 'delta-force'
            SourceMenuNumber = 6
            Group = 'Delta Force'
            DisplayName = 'Delta Force'
            ArtifactId = 'game-configs.delta-force'
            ArtifactSourceId = 'game-configs-delta-force'
            SourceRecipePath = 'Delta Force/Delta Force.ps1'
            SourceRecipeSha256 = '9F23F5AA4410ECE8AD4DD097C0FF04FCF16F88A90C9CBFD4C371B141B22B1AA6'
            ArchivePath = '$env:SystemRoot\Temp\Delta Force.zip'
            ExtractPath = '$env:SystemRoot\Temp\Delta Force'
            PromptedFolders = @(@{ Id = 'ConfigFolder'; Prompt = 'Select Delta Force config folder' })
            CopyOperations = @(@{ Source = '$ExtractPath\*'; Destination = '$ConfigFolder'; Recurse = $true; Force = $true })
            RemovePaths = @('$ConfigFolder\-dx11.launchoption')
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Copy extracted payload to selected config folder and remove -dx11.launchoption.')
            NeedsInspector = $false
            OpensUrl = $false
        }
        @{
            GameId = 'frag-punk'
            SourceMenuNumber = 7
            Group = 'Frag Punk'
            DisplayName = 'Frag Punk'
            ArtifactId = 'game-configs.frag-punk'
            ArtifactSourceId = 'game-configs-frag-punk'
            SourceRecipePath = 'Frag Punk/Frag Punk.ps1'
            SourceRecipeSha256 = '86A9516D939AEBE33FC51D60124E5A03258B3A1D3E3968EA5D2D0936F986FFD5'
            ArchivePath = '$env:SystemRoot\Temp\Frag Punk.zip'
            ExtractPath = '$env:SystemRoot\Temp\FragPunk'
            EnsureDirectories = @('$env:LOCALAPPDATA\FragPunk\A50\Saved\Config\WindowsClient', '$env:LOCALAPPDATA\FragPunk\Epic\Saved\Config\WindowsClient', '$env:LOCALAPPDATA\FragPunk\Steam\Saved\Config\WindowsClient')
            Inspector = @{ ArtifactId = 'game-configs.profile-inspector.inspector-exe'; Destination = '$ExtractPath\RebarOffInspector\inspector.exe'; Arguments = '$ExtractPath\RebarOffInspector\FragPunk.nip -silent'; UnblockPath = 'C:\ProgramData\NVIDIA Corporation\Drs'; WaitSeconds = 3 }
            CopyOperations = @(
                @{ Source = '$ExtractPath\Engine.ini'; Destination = '$env:LOCALAPPDATA\FragPunk\A50\Saved\Config\WindowsClient'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\GameUserSettings.ini'; Destination = '$env:LOCALAPPDATA\FragPunk\A50\Saved\Config\WindowsClient'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\Engine.ini'; Destination = '$env:LOCALAPPDATA\FragPunk\Epic\Saved\Config\WindowsClient'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\GameUserSettings.ini'; Destination = '$env:LOCALAPPDATA\FragPunk\Epic\Saved\Config\WindowsClient'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\Engine.ini'; Destination = '$env:LOCALAPPDATA\FragPunk\Steam\Saved\Config\WindowsClient'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\GameUserSettings.ini'; Destination = '$env:LOCALAPPDATA\FragPunk\Steam\Saved\Config\WindowsClient'; Recurse = $true; Force = $true }
            )
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Create FragPunk platform config folders, import FragPunk.nip through inspector.exe, then copy Engine.ini and GameUserSettings.ini to A50, Epic, and Steam config folders.')
            NeedsInspector = $true
            OpensUrl = $false
        }
        @{
            GameId = 'marvel-rivals'
            SourceMenuNumber = 8
            Group = 'Marvel Rivals'
            DisplayName = 'Marvel Rivals'
            ArtifactId = 'game-configs.marvel-rivals'
            ArtifactSourceId = 'game-configs-marvel-rivals'
            SourceRecipePath = 'Marvel Rivals/Marvel Rivals.ps1'
            SourceRecipeSha256 = 'F52C60B62AF8441FE75D546744AC066108F6D204DA47599241AC04060FEE6FCD'
            ArchivePath = '$env:SystemRoot\Temp\Marvel Rivals.zip'
            ExtractPath = '$env:SystemRoot\Temp\Marvel Rivals'
            CopyOperations = @(@{ Source = '$ExtractPath\*'; Destination = '$env:LOCALAPPDATA\Marvel\Saved\Config\Windows'; Recurse = $true; Force = $true })
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Copy extracted payload into Marvel Windows config folder.')
            NeedsInspector = $false
            OpensUrl = $false
        }
        @{
            GameId = 'pubg-battlegrounds'
            SourceMenuNumber = 9
            Group = 'PUBG BATTLEGROUNDS'
            DisplayName = 'PUBG BATTLEGROUNDS'
            ArtifactId = 'game-configs.pubg-battlegrounds'
            ArtifactSourceId = 'game-configs-pubg-battlegrounds'
            SourceRecipePath = 'PUBG BATTLEGROUNDS/PUBG BATTLEGROUNDS.ps1'
            SourceRecipeSha256 = '9455C0853DC7B4558FF355CC29A103E81ED90AEA7A6C4476C6BE3DAE79069F11'
            ArchivePath = '$env:SystemRoot\Temp\PUBG BATTLEGROUNDS.zip'
            ExtractPath = '$env:SystemRoot\Temp\PUBG BATTLEGROUNDS'
            CopyOperations = @(@{ Source = '$ExtractPath\*'; Destination = '$env:LOCALAPPDATA\TslGame\Saved\Config\WindowsNoEditor'; Recurse = $true; Force = $true })
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Copy extracted payload into TslGame WindowsNoEditor config folder.')
            NeedsInspector = $false
            OpensUrl = $false
        }
        @{
            GameId = 'splitgate-1'
            SourceMenuNumber = 10.1
            Group = 'Splitgate'
            DisplayName = 'Splitgate 1'
            ArtifactId = 'game-configs.splitgate-1'
            ArtifactSourceId = 'game-configs-splitgate-1'
            SourceRecipePath = 'Splitgate/Splitgate 1.ps1'
            SourceRecipeSha256 = 'C62192E08DB797ECBB25675E252FE6A55709C14EE9286BA5593B35E6ED8F8354'
            ArchivePath = '$env:SystemRoot\Temp\Splitgate 1.zip'
            ExtractPath = '$env:SystemRoot\Temp\Splitgate 1'
            EnsureDirectories = @('$env:LOCALAPPDATA\PortalWars\Saved\Config\WindowsNoEditor')
            CopyOperations = @(@{ Source = '$ExtractPath\GameUserSettings.ini'; Destination = '$env:LOCALAPPDATA\PortalWars\Saved\Config\WindowsNoEditor'; Recurse = $true; Force = $true })
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Create PortalWars WindowsNoEditor config folder and copy GameUserSettings.ini.')
            NeedsInspector = $false
            OpensUrl = $false
        }
        @{
            GameId = 'splitgate-2'
            SourceMenuNumber = 10.2
            Group = 'Splitgate'
            DisplayName = 'Splitgate 2'
            ArtifactId = 'game-configs.splitgate-2'
            ArtifactSourceId = 'game-configs-splitgate-2'
            SourceRecipePath = 'Splitgate/Splitgate 2.ps1'
            SourceRecipeSha256 = '9C55CF5C235BEBA1BE2BB08C24CF2F9661208D96750EADDFFD20B8C509E784C9'
            ArchivePath = '$env:SystemRoot\Temp\Splitgate 2.zip'
            ExtractPath = '$env:SystemRoot\Temp\Splitgate 2'
            EnsureDirectories = @('$env:LOCALAPPDATA\PortalWars2\Saved\Config\WindowsClient')
            CopyOperations = @(@{ Source = '$ExtractPath\GameUserSettings.ini'; Destination = '$env:LOCALAPPDATA\PortalWars2\Saved\Config\WindowsClient'; Recurse = $true; Force = $true })
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Create PortalWars2 WindowsClient config folder and copy GameUserSettings.ini.')
            NeedsInspector = $false
            OpensUrl = $false
        }
        @{
            GameId = 'star-wars-battlefront-i-2015'
            SourceMenuNumber = 11.1
            Group = 'STAR WARS Battlefront'
            DisplayName = 'STAR WARS Battlefront I 2015'
            ArtifactId = 'game-configs.star-wars-battlefront-i-2015'
            ArtifactSourceId = 'game-configs-star-wars-battlefront-i-2015'
            SourceRecipePath = 'STAR WARS Battlefront/STAR WARS Battlefront I 2015.ps1'
            SourceRecipeSha256 = 'A9273EF1DD2408191E6160264D2F006F794DB0EF482A09D4FAF2B952177E9906'
            ArchivePath = '$env:SystemRoot\Temp\STAR WARS Battlefront I 2015.zip'
            ExtractPath = '$env:SystemRoot\Temp\STAR WARS Battlefront I 2015'
            EnsureDirectories = @('$env:USERPROFILE\Documents\STAR WARS Battlefront\settings', '$env:USERPROFILE\OneDrive\Documents\STAR WARS Battlefront\settings')
            PromptedFolders = @(@{ Id = 'InstallFolder'; Prompt = 'Select STAR WARS Battlefront I 2015 install folder' })
            CopyOperations = @(
                @{ Source = '$ExtractPath\*'; Destination = '$env:USERPROFILE\Documents\STAR WARS Battlefront\settings'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\*'; Destination = '$env:USERPROFILE\OneDrive\Documents\STAR WARS Battlefront\settings'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\user.cfg'; Destination = '$InstallFolder'; Force = $true }
            )
            RemovePaths = @('$env:USERPROFILE\Documents\STAR WARS Battlefront\settings\user.cfg', '$env:USERPROFILE\OneDrive\Documents\STAR WARS Battlefront\settings\user.cfg')
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Copy extracted payload into Documents and OneDrive settings, copy user.cfg to selected install folder, then remove settings user.cfg copies.')
            NeedsInspector = $false
            OpensUrl = $false
        }
        @{
            GameId = 'star-wars-battlefront-ii-2017'
            SourceMenuNumber = 11.2
            Group = 'STAR WARS Battlefront'
            DisplayName = 'STAR WARS Battlefront II 2017'
            ArtifactId = 'game-configs.star-wars-battlefront-ii-2017'
            ArtifactSourceId = 'game-configs-star-wars-battlefront-ii-2017'
            SourceRecipePath = 'STAR WARS Battlefront/STAR WARS Battlefront II 2017.ps1'
            SourceRecipeSha256 = '86A6EE8D608ED65AED2916DC6F431C7870C7DCC67879EA37EFDBC4CC9EF43322'
            ArchivePath = '$env:SystemRoot\Temp\STAR WARS Battlefront II 2017.zip'
            ExtractPath = '$env:SystemRoot\Temp\STAR WARS Battlefront II 2017'
            EnsureDirectories = @('$env:USERPROFILE\Documents\STAR WARS Battlefront II\settings', '$env:USERPROFILE\OneDrive\Documents\STAR WARS Battlefront II\settings')
            PromptedFolders = @(@{ Id = 'InstallFolder'; Prompt = 'Select STAR WARS Battlefront II 2017 install folder' })
            CopyOperations = @(
                @{ Source = '$ExtractPath\*'; Destination = '$env:USERPROFILE\Documents\STAR WARS Battlefront II\settings'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\*'; Destination = '$env:USERPROFILE\OneDrive\Documents\STAR WARS Battlefront II\settings'; Recurse = $true; Force = $true }
                @{ Source = '$ExtractPath\user.cfg'; Destination = '$InstallFolder'; Force = $true }
            )
            RemovePaths = @('$env:USERPROFILE\Documents\STAR WARS Battlefront II\settings\user.cfg', '$env:USERPROFILE\OneDrive\Documents\STAR WARS Battlefront II\settings\user.cfg')
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Copy extracted payload into Documents and OneDrive settings, copy user.cfg to selected install folder, then remove settings user.cfg copies.')
            NeedsInspector = $false
            OpensUrl = $false
        }
        @{
            GameId = 'the-finals'
            SourceMenuNumber = 12
            Group = 'The Finals'
            DisplayName = 'The Finals'
            ArtifactId = 'game-configs.the-finals'
            ArtifactSourceId = 'game-configs-the-finals'
            SourceRecipePath = 'The Finals/The Finals.ps1'
            SourceRecipeSha256 = 'E5F6DB65922ED553A0E589FA481BACC882F4B362E99F42A8DF1EC071880B9033'
            ArchivePath = '$env:SystemRoot\Temp\The Finals.zip'
            ExtractPath = '$env:SystemRoot\Temp\The Finals'
            PreRemovePaths = @('$env:LOCALAPPDATA\Discovery')
            EnsureDirectories = @('$env:LOCALAPPDATA\Discovery\Saved\Config\WindowsClient', '$env:LOCALAPPDATA\Discovery\Saved\SaveGames')
            CopyOperations = @(@{ Source = '$ExtractPath\GameUserSettings.ini'; Destination = '$env:LOCALAPPDATA\Discovery\Saved\Config\WindowsClient'; Recurse = $true; Force = $true })
            CleanupPaths = @('$ExtractPath', '$ArchivePath')
            SpecialSteps = @('Delete Discovery local app data, recreate WindowsClient and SaveGames folders, then copy GameUserSettings.ini.')
            NeedsInspector = $false
            OpensUrl = $false
        }
    )
}
