@{
    SchemaVersion = 1
    Purpose = 'Phase 107 Ordered Ultimate Parity Execution Reset'
    DesignSystemReady = $false

    Counts = @{
        ActiveTools = 46
        RuntimeImplementedTools = 46
        DeferredPlaceholders = 0
        SourcePromotedMirrorFiles = 7
        RemainingSourcePromotedIntakeCandidates = 0
        UltimateParityImplemented = 34
        NearParityControlled = 10
        ControlledSubset = 2
        ManualHandoffOnly = 0
        SecurityAssistantOnly = 0
        DeferredForParityWork = 0
        RefusedOrDeletedOutsideActiveCatalog = 30
    }

    CurrentOrderedParityTarget = $null
    OrderedParityComplete = $true

    Policy = @{
        UltimateParityIsDefaultFinalTarget = $true
        RuntimeImplementedIsNotUltimateParity = $true
        ManualHandoffOnlyIsTemporary = $true
        ControlledSubsetIsTemporary = $true
        SecurityAssistantOnlyIsNotFinalParity = $true
        NearParityRequiresYazanAcceptance = $true
        FinalDoneRequiresParityOrYazanFinalException = $true
        WorkOrderFollowsStageToolOrder = $true
        CustomerUiNotReadyForDesignSystem = $true
    }

    RefusedOrDeletedOutsideActiveCatalog = @(
        'Windows Activation Helper'
        'Firewall Disable / Enable'
        'DEP Disable / Enable'
        'File Download Security Warning'
        'MPO'
        'FSO'
        'FSE'
        'Hardware Flip'
        'AMD ULPS'
        'WHQL Secure Boot Bypass'
        'Keyboard Shortcuts'
        'Search Shell Mobsync'
        'NVME Faster Driver'
        'Core 1 Thread 1'
        'DDU'
        'UAC Disable / Enable'
        'Scaling'
        'Start Menu Shortcuts'
        'Loudness EQ'
        'Resizable BAR Assistant'
        'SMT / HT Assistant'
        'Restore Point'
        'Spectre / Meltdown Assistant'
        'MMAgent Assistant'
        'Services Optimizer'
        'Driver Install Latest'
        'Nvidia Settings'
        'HDCP'
        'P0 State'
        'Msi Mode'
    )

    Tools = @(
        @{
            ToolId = 'bios-information'
            DisplayName = 'BIOS Information'
            Stage = 'Check'
            StageOrder = 1
            ToolOrder = 1
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Matches the approved Ultimate information behavior.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required; keep source checksum and GUI translation stable.'
        }
        @{
            ToolId = 'bios-settings'
            DisplayName = 'BIOS Settings'
            Stage = 'Check'
            StageOrder = 1
            ToolOrder = 2
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Preserves the firmware restart result through visible confirmation and safer GUI routing; Yazan accepts this confirmation as final near parity because no capability is removed.'
            YazanFinalException = $false
            YazanAcceptedNearParity = $true
            FinalProgressStatus = 'DoneYazanAcceptedNearParity'
            NextParityAction = 'Next ordered pending parity target: unattended.'
        }
        @{
            ToolId = 'reinstall'
            DisplayName = 'Reinstall'
            Stage = 'Refresh'
            StageOrder = 2
            ToolOrder = 1
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Windows 11 source branch downloads and launches the source-defined Media Creation Tool after explicit confirmation; Windows 10 branch remains unsupported by product scope.'
            YazanFinalException = $false
            YazanAcceptedNearParity = $true
            FinalProgressStatus = 'DoneYazanAcceptedNearParity'
            NextParityAction = 'Next ordered pending parity target: unattended.'
        }
        @{
            ToolId = 'unattended'
            DisplayName = 'Unattended'
            Stage = 'Refresh'
            StageOrder = 2
            ToolOrder = 2
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Source-equivalent Windows 11 unattended payload generation is implemented with safer GUI confirmation, removable-media validation, backup/state capture, and verification; no source branch is omitted.'
            YazanFinalException = $false
            YazanAcceptedNearParity = $true
            FinalProgressStatus = 'DoneYazanAcceptedNearParity'
            NextParityAction = 'Next ordered pending parity target: updates-drivers-block.'
        }
        @{
            ToolId = 'updates-drivers-block'
            DisplayName = 'Updates Drivers Block'
            Stage = 'Refresh'
            StageOrder = 2
            ToolOrder = 3
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ControlledSubset'
            UltimateParity = 'Partial'
            GapSummary = 'Yazan-selected final scope is Driver Updates Block Bootable USB only; Unblock, live local default/unblock, broad Updates branches, and custom update-server behavior are intentionally excluded.'
            YazanFinalException = $true
            YazanAcceptedNearParity = $false
            FinalProgressStatus = 'YazanFinalException'
            NextParityAction = 'Skip; Yazan final scope exception accepted.'
        }
        @{
            ToolId = 'to-bios'
            DisplayName = 'To BIOS'
            Stage = 'Refresh'
            StageOrder = 2
            ToolOrder = 4
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Yazan-approved GUI confirmation before source-equivalent restart-to-firmware action; the underlying firmware restart capability remains available.'
            YazanFinalException = $false
            YazanAcceptedNearParity = $true
            FinalProgressStatus = 'DoneYazanAcceptedNearParity'
            NextParityAction = 'Skip; accepted near-parity.'
        }
        @{
            ToolId = 'memory-compression'
            DisplayName = 'Memory Compression'
            Stage = 'Setup'
            StageOrder = 3
            ToolOrder = 3
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Apply and Default preserve source-defined MMAgent behavior.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required.'
        }
        @{
            ToolId = 'date-language-region-time'
            DisplayName = 'Date Language Region Time'
            Stage = 'Setup'
            StageOrder = 3
            ToolOrder = 4
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Open-only launcher behavior is preserved.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required.'
        }
        @{
            ToolId = 'startup-apps-settings'
            DisplayName = 'Startup Apps (Settings)'
            Stage = 'Setup'
            StageOrder = 3
            ToolOrder = 5
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Open-only Settings launcher behavior is preserved.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required.'
        }
        @{
            ToolId = 'startup-apps-task-manager'
            DisplayName = 'Startup Apps (Task Manager)'
            Stage = 'Setup'
            StageOrder = 3
            ToolOrder = 6
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Open-only Task Manager launcher behavior is preserved.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required.'
        }
        @{
            ToolId = 'background-apps'
            DisplayName = 'Background Apps'
            Stage = 'Setup'
            StageOrder = 3
            ToolOrder = 7
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Apply and Default preserve the source-defined registry behavior.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required.'
        }
        @{
            ToolId = 'edge-settings'
            DisplayName = 'Edge Settings'
            Stage = 'Setup'
            StageOrder = 3
            ToolOrder = 8
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Yazan-approved safer BoostLab confirmation and test-safe mechanics around source-equivalent Edge Settings behavior: Edge policies, uBlock force-install policy, Active Setup cleanup, RunOnce cleanup, Edge service stop/delete, Edge scheduled-task removal, IE-to-Edge BHO cleanup, Edge stop/start/stop, source-defined edge.exe download, and edge.exe start.'
            YazanFinalException = $false
            YazanAcceptedNearParity = $true
            FinalProgressStatus = 'DoneYazanAcceptedNearParity'
            NextParityAction = 'Skip; accepted near-parity.'
        }
        @{
            ToolId = 'store-settings'
            DisplayName = 'Store Settings'
            Stage = 'Setup'
            StageOrder = 3
            ToolOrder = 9
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Apply and Default preserve source-defined behavior.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required.'
        }
        @{
            ToolId = 'updates-pause'
            DisplayName = 'Updates Pause'
            Stage = 'Setup'
            StageOrder = 3
            ToolOrder = 10
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Apply and Default preserve source-defined pause policy behavior.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required.'
        }
        @{
            ToolId = 'bitlocker'
            DisplayName = 'BitLocker'
            Stage = 'Setup'
            StageOrder = 3
            ToolOrder = 1
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Yazan-approved GUI confirmation and test-safe execution mechanics around source-equivalent BitLocker Off and On/status behavior; Default and Restore remain unavailable because the source defines no captured-state semantics.'
            YazanFinalException = $false
            YazanAcceptedNearParity = $true
            FinalProgressStatus = 'DoneYazanAcceptedNearParity'
            NextParityAction = 'Skip; accepted near-parity.'
        }
        @{
            ToolId = 'convert-home-to-pro'
            DisplayName = 'Convert Home To Pro'
            Stage = 'Setup'
            StageOrder = 3
            ToolOrder = 2
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            SourceType = 'YazanProvidedForgottenScript'
            GapSummary = 'Yazan-provided forgotten script imported as source-extra; Apply preserves the generic Pro setup key clipboard copy plus Windows Activation/product-key UI flow, while documenting that activation requires a valid Windows Pro license.'
            YazanFinalException = $false
            FinalProgressStatus = 'DoneParity'
            NextParityAction = 'No ordered Ultimate parity work required; source-extra behavior is implemented directly and ordered parity remains complete.'
        }
        @{
            ToolId = 'installers'
            DisplayName = 'Installers'
            Stage = 'Installers'
            StageOrder = 4
            ToolOrder = 1
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ControlledSubset'
            UltimateParity = 'Partial'
            GapSummary = 'Yazan excluded source menu entries 11 Frame View, 12 GOG launcher, 15 Notepad ++, 16 Nvidia App, 18 Onboard Memory Manager, and 19 Pot Player; retained apps use source-equivalent selected-app sequential install flows.'
            YazanFinalException = $true
            YazanAcceptedNearParity = $true
            FinalProgressStatus = 'YazanFinalException'
            NextParityAction = 'Skip; Yazan final app-list scope exception accepted.'
        }
        @{
            ToolId = 'driver-clean'
            DisplayName = 'Driver Clean'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 1
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Yazan-approved BoostLab GUI confirmation and test-safe mechanics around exact source-equivalent Driver Clean DDU Auto/Manual behavior.'
            YazanFinalException = $false
            YazanAcceptedNearParity = $true
            FinalProgressStatus = 'DoneYazanAcceptedNearParity'
            NextParityAction = 'Skip; accepted near-parity.'
        }
        @{
            ToolId = 'driver-install-debloat-settings'
            DisplayName = 'Driver Install Debloat & Settings'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 2
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Yazan-approved BoostLab GUI confirmation/test-safe mechanics around exact source-equivalent NVIDIA, AMD, and INTEL Driver Install Debloat & Settings behavior.'
            BranchScopeDecision = 'Phase 122: Yazan approved all source-defined NVIDIA, AMD, and INTEL branches for Driver Install Debloat & Settings only. This does not expand project-wide AMD/Intel GPU scope.'
            ApprovedSourceBranches = @('NVIDIA', 'AMD', 'INTEL')
            YazanFinalException = $false
            YazanAcceptedNearParity = $true
            FinalProgressStatus = 'DoneYazanAcceptedNearParity'
            NextParityAction = 'Skip; accepted near-parity.'
        }
        @{
            ToolId = 'nvidia-app-install'
            DisplayName = 'Install NVIDIA App'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 3
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            SourceType = 'UltimateInstallerOptionPromotedToGraphics'
            SourceScriptPath = 'source-ultimate/4 Installers/1 Installers.ps1'
            SourceSha256 = '1065D64183457D4E7B28EA78DDE41525EC8F7C4A4BCA12D29B70D991141C0C67'
            SourceCanonicalSha256 = '268C1EFE627FADDA17892223D4C35E4845833506C22AADD3240C894ED046A6F8'
            GapSummary = 'Phase 173E promotes only the source-defined old Installers NVIDIA App option into Graphics: download the official NVIDIA App installer, run it with /s, move the Start Menu shortcut, and remove the NVIDIA Corporation Start Menu folder after confirmation.'
            YazanFinalException = $false
            FinalProgressStatus = 'DoneParity'
            NextParityAction = 'No ordered Ultimate parity work required; this is an approved Graphics-stage placement of the source-defined NVIDIA App installer option.'
        }
        @{
            ToolId = 'directx'
            DisplayName = 'DirectX'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 4
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Yazan-approved BoostLab GUI confirmation/test-safe mechanics around source-equivalent DirectX behavior: 7-Zip download/install/configuration, Start Menu shortcut adjustment, DirectX package download/extraction, and DXSETUP launch.'
            YazanFinalException = $false
            YazanAcceptedNearParity = $true
            FinalProgressStatus = 'DoneYazanAcceptedNearParity'
            NextParityAction = 'Skip; accepted near-parity.'
        }
        @{
            ToolId = 'visual-cpp'
            DisplayName = 'Visual C++'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 5
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Yazan-approved GUI confirmation and test-safe executor mechanics around source-equivalent Visual C++ behavior: twelve source-defined downloads and twelve waited installer launches in exact source order.'
            YazanFinalException = $false
            YazanAcceptedNearParity = $true
            FinalProgressStatus = 'DoneYazanAcceptedNearParity'
            NextParityAction = 'Skip; accepted near-parity.'
        }
        @{
            ToolId = 'graphics-configuration-center'
            DisplayName = 'Graphics Configuration Center'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 6
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Open-only Windows advanced graphics Settings launcher behavior is source-equivalent.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required.'
        }
        @{
            ToolId = 'start-menu-taskbar'
            DisplayName = 'Start Menu Taskbar'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 1
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Yazan accepted the source-equivalent Clean and Default implementation with BoostLab confirmations, safe routing, logging, action labels, and test-safe adapters preserved.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required; advance ordered cursor to start-menu-layout.'
        }
        @{
            ToolId = 'start-menu-layout'
            DisplayName = 'Start Menu Layout'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 2
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Yazan accepted the verified source-equivalent Apply and Default implementation as complete for ordered parity.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required; advance ordered cursor to context-menu.'
        }
        @{
            ToolId = 'context-menu'
            DisplayName = 'Context Menu'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 3
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Apply and Default preserve the exact Ultimate registry operation order, including Default deletion of the complete Shell Extensions\Blocked key.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required; advance ordered cursor to theme-black.'
        }
        @{
            ToolId = 'theme-black'
            DisplayName = 'Theme Black'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 4
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Apply and Default preserve the exact Ultimate registry payloads, temp file names, import order, and Default HKLM Themes Personalize key deletion.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required; advance ordered cursor to signout-lockscreen-wallpaper-black.'
        }
        @{
            ToolId = 'signout-lockscreen-wallpaper-black'
            DisplayName = 'Signout LockScreen Wallpaper Black'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 5
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Apply and Default preserve the exact Ultimate image generation, PersonalizationCSP/Desktop registry writes, wallpaper refresh, complete PersonalizationCSP key deletion, and C:\Windows\Black.jpg deletion.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required; advance ordered cursor to user-account-pictures-black.'
        }
        @{
            ToolId = 'user-account-pictures-black'
            DisplayName = 'User Account Pictures Black'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 6
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Apply and Default preserve the exact Ultimate account-picture backup, recursive PNG/BMP black image generation, and legacy backup copy-back behavior.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required; advance ordered cursor to widgets.'
        }
        @{
            ToolId = 'widgets'
            DisplayName = 'Widgets'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 7
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Apply and Default preserve source-defined registry policy writes, Dsh policy deletion behavior, and Widgets/WidgetService process stop behavior with BoostLab confirmation and verification.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required; advance ordered cursor to copilot.'
        }
        @{
            ToolId = 'copilot'
            DisplayName = 'Copilot'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 8
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Apply preserves the approved source Copilot Off branch: all source named process stops, wildcard *edge* process stop, AppX package removal matching *Copilot*, and HKCU/HKLM TurnOffWindowsCopilot DWORD 1. Default preserves AppX re-registration matching *Copilot* and HKCU/HKLM WindowsCopilot policy key deletion.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required; advance ordered cursor to gamemode.'
        }
        @{
            ToolId = 'game-mode'
            DisplayName = 'GameMode'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 9
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Open preserves the exact Ultimate GameMode launcher: Start-Process "ms-settings:gaming-gamemode". The source contains no Apply, Default, Restore, registry, file, service, task, process, download, installer, or reboot behavior.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required; advance ordered cursor to pointer-precision.'
        }
        @{
            ToolId = 'pointer-precision'
            DisplayName = 'Pointer Precision'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 10
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Open preserves the exact Ultimate Pointer Precision launcher: Start-Process "control.exe" -ArgumentList "main.cpl ,2". The source contains no Apply, Default, Restore, registry, file, service, task, process, download, installer, or reboot behavior.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required; advance ordered cursor to bloatware.'
        }
        @{
            ToolId = 'bloatware'
            DisplayName = 'Bloatware'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 11
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Yazan approved full exact Ultimate parity for all non-Exit source Bloatware branches. BoostLab preserves the source admin/internet preflight, AppX removal/re-registration, Windows capability and optional feature operations, service/task/process/file/registry/hive/MSI/installer/download behavior, and Windows 10/Windows 11 source branches through a single selected branch Apply model.'
            YazanFinalException = $false
            FinalProgressStatus = 'DoneParity'
            ApprovedSourceBranches = @(
                'Remove : All Bloatware (Recommended)'
                'Install: Store'
                'Install: All UWP Apps'
                'Install: UWP Features'
                'Install: Legacy Features'
                'Install: One Drive'
                'Install: Remote Desktop Connection'
                'Install: Snipping Tool'
            )
            DownloadArtifactClassification = 'UltimateAuthorHostedArtifact; NeedsBoostLabMirror; no artifact provenance or production allowlist entry added.'
            NextParityAction = 'No parity work required; advance ordered cursor to game-bar.'
        }
        @{
            ToolId = 'game-bar'
            DisplayName = 'GameBar'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 12
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Yazan approved complete exact Ultimate parity for Gamebar. Apply preserves the source Gamebar Xbox Off branch; Default preserves the source Gamebar Xbox Default branch, including AppX removal/re-registration, GameInput service/process handling, Microsoft GameInput MSI uninstall, registry payload import, TrustedInstaller PresenceWriter command, and source repair downloads/launches.'
            YazanFinalException = $false
            FinalProgressStatus = 'DoneParity'
            ApprovedSourceBranches = @(
                'Gamebar Xbox: Off (Recommended)'
                'Gamebar Xbox: Default'
            )
            DownloadArtifactClassification = 'UltimateAuthorHostedArtifact; NeedsBoostLabMirror; no artifact provenance or production allowlist entry added.'
            NextParityAction = 'No parity work required; advance ordered cursor to edge-webview.'
        }
        @{
            ToolId = 'edge-webview'
            DisplayName = 'Edge & WebView'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 13
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Exact source Apply/Uninstall and Default repair branches are implemented with explicit confirmation.'
            YazanFinalException = $false
            FinalProgressStatus = 'DoneParity'
            NextParityAction = 'DoneParity'
        }
        @{
            ToolId = 'notepad-settings'
            DisplayName = 'Notepad Settings'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 14
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Exact source Apply and Default branches are implemented: Stop-Process Notepad, two-second delay, source notepadsettings.reg hive import when reg load succeeds, and source settings.dat deletion.'
            YazanFinalException = $false
            FinalProgressStatus = 'DoneParity'
            NextParityAction = 'DoneParity'
        }
        @{
            ToolId = 'control-panel-settings'
            DisplayName = 'Control Panel Settings'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 15
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Exact source Optimize and Default branches are represented through checksum-verified source-backed execution with explicit confirmation and test-safe script runner injection.'
            YazanFinalException = $false
            FinalProgressStatus = 'DoneParity'
            NextParityAction = 'DoneParity'
        }
        @{
            ToolId = 'sound'
            DisplayName = 'Sound'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 16
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Open-only launcher behavior is preserved.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required.'
        }
        @{
            ToolId = 'device-manager-power-savings-wake'
            DisplayName = 'Device Manager Power Savings & Wake'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 17
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Exact source Off and Default registry operation sets, device classes, value names, source spelling asymmetry, and verification are preserved.'
            YazanFinalException = $false
            FinalProgressStatus = 'DoneParity'
            NextParityAction = 'DoneParity'
        }
        @{
            ToolId = 'network-adapter-power-savings-wake'
            DisplayName = 'Network Adapter Power Savings & Wake'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 18
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Exact source Off and Default adapter registry operation sets, adapter key filter, repeated Modern Standby operation, and verification are preserved.'
            YazanFinalException = $false
            FinalProgressStatus = 'DoneParity'
            NextParityAction = 'DoneParity'
        }
        @{
            ToolId = 'write-cache-buffer-flushing'
            DisplayName = 'Write Cache Buffer Flushing'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 19
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Apply preserves source CacheIsPowerProtected REG_DWORD 1 writes under SCSI/NVME Device Parameters Disk paths; Default preserves source SCSI/NVME Disk key deletion with confirmation, capture, and verification.'
            YazanFinalException = $false
            FinalProgressStatus = 'DoneParity'
            NextParityAction = 'DoneParity'
        }
        @{
            ToolId = 'power-plan'
            DisplayName = 'Power Plan'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 20
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Apply and Default preserve the source-defined powercfg scheme duplication, activation, deletion, hibernation, registry operations, 72 setting commands, and Power Options launch. Source-defined unsupported settings are reported as structured warnings while unexpected failures remain errors.'
            YazanFinalException = $false
            FinalProgressStatus = 'DoneParity'
            NextParityAction = 'DoneParity'
        }
        @{
            ToolId = 'cleanup'
            DisplayName = 'Cleanup'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 21
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Apply preserves the complete source cleanup branch: user Temp contents, Windows Temp contents, inetpub, PerfLogs, Windows.old, DumpStack.log, and cleanmgr.exe launch. No Default, Restore, download, registry, service, task, process-stop, or reboot behavior exists in the source.'
            YazanFinalException = $false
            FinalProgressStatus = 'DoneParity'
            NextParityAction = 'DoneParity'
        }
        @{
            ToolId = 'timer-resolution-assistant'
            DisplayName = 'Timer Resolution Assistant'
            Stage = 'Advanced'
            StageOrder = 7
            ToolOrder = 1
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Apply and Default preserve the exact source-defined Timer Resolution On and Default workflows with generated C# service source, source compiler invocation, service create/start/disable/stop/delete behavior, GlobalTimerResolutionRequests registry add/delete, protected generated file cleanup, and Task Manager launch.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required; advance ordered cursor to defender-optimize-assistant.'
        }
        @{
            ToolId = 'defender-optimize-assistant'
            DisplayName = 'Defender Optimize Assistant'
            Stage = 'Advanced'
            StageOrder = 7
            ToolOrder = 2
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Apply and Default preserve the exact source-defined Defender Optimize and Defender Default Safe Mode workflows with generated scripts, RunOnce, normal-boot SmartScreen and scheduled-task commands, BCD safeboot, TrustedInstaller and Administrator execution of the Defender/security command lists, safeboot removal, and restart requests.'
            YazanFinalException = $false
            FinalProgressStatus = 'DoneParity'
            NextParityAction = 'DoneParity; ordered Ultimate parity cursor is complete.'
        }
    )
}
