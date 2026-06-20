@{
    SchemaVersion = 1
    Purpose = 'Phase 107 Ordered Ultimate Parity Execution Reset'
    DesignSystemReady = $false

    Counts = @{
        ActiveTools = 55
        RuntimeImplementedTools = 45
        DeferredPlaceholders = 10
        SourcePromotedMirrorFiles = 7
        RemainingSourcePromotedIntakeCandidates = 0
        UltimateParityImplemented = 16
        NearParityControlled = 25
        ControlledSubset = 3
        ManualHandoffOnly = 1
        SecurityAssistantOnly = 0
        DeferredForParityWork = 10
        RefusedOrDeletedOutsideActiveCatalog = 19
    }

    CurrentOrderedParityTarget = 'start-menu-taskbar'

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
            ToolOrder = 2
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
            ToolOrder = 3
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
            ToolOrder = 4
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
            ToolOrder = 5
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
            ToolOrder = 6
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
            ToolOrder = 7
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
            ToolOrder = 8
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
            ToolOrder = 9
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
            ToolId = 'driver-install-latest'
            DisplayName = 'Driver Install Latest'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 3
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Yazan-approved BoostLab GUI confirmation/test-safe mechanics around exact source-equivalent Driver Install Latest behavior.'
            YazanFinalException = $false
            YazanAcceptedNearParity = $true
            FinalProgressStatus = 'DoneYazanAcceptedNearParity'
            NextParityAction = 'Skip; accepted near-parity.'
        }
        @{
            ToolId = 'nvidia-settings'
            DisplayName = 'Nvidia Settings'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 4
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Yazan-approved BoostLab GUI confirmation/test-safe mechanics around exact source-equivalent Nvidia Settings On (Recommended) and Default behavior, including 7-Zip prelude, NVIDIA registry/profile operations, Profile Inspector .nip import, and Control Panel launch.'
            YazanFinalException = $false
            YazanAcceptedNearParity = $true
            FinalProgressStatus = 'DoneYazanAcceptedNearParity'
            NextParityAction = 'Skip; accepted near-parity.'
        }
        @{
            ToolId = 'hdcp'
            DisplayName = 'HDCP'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 5
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Yazan-approved BoostLab GUI confirmation/test-safe mechanics around exact source-equivalent HDCP Off (Recommended) and Default behavior: every non-Configuration display-class subkey is written and read back.'
            YazanFinalException = $false
            YazanAcceptedNearParity = $true
            FinalProgressStatus = 'DoneYazanAcceptedNearParity'
            NextParityAction = 'Skip; accepted near-parity.'
        }
        @{
            ToolId = 'p0-state'
            DisplayName = 'P0 State'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 6
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Yazan-approved BoostLab GUI confirmation/test-safe mechanics around exact source-equivalent P0 State On (Recommended) and Default behavior: every non-Configuration display-class subkey is written and read back.'
            YazanFinalException = $false
            YazanAcceptedNearParity = $true
            FinalProgressStatus = 'DoneYazanAcceptedNearParity'
            NextParityAction = 'Skip; accepted near-parity.'
        }
        @{
            ToolId = 'msi-mode'
            DisplayName = 'Msi Mode'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 7
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Yazan-accepted BoostLab GUI confirmation/test-safe mechanics around exact source-equivalent Msi Mode On and Off behavior for every display device returned by Get-PnpDevice -Class Display.'
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
            ToolId = 'directx'
            DisplayName = 'DirectX'
            Stage = 'Graphics'
            StageOrder = 5
            ToolOrder = 8
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
            ToolOrder = 9
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
            ToolOrder = 10
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
            RuntimeStatus = 'DeferredPlaceholder'
            ImplementationLevel = 'DeferredForParityWork'
            UltimateParity = 'No'
            GapSummary = 'Source replaces layout files, deletes user state, writes policies, and handles Explorer without approved capture/restore scope.'
            YazanFinalException = $false
            NextParityAction = 'Approve exact file/registry/cleanup scopes and Explorer process handling, then implement in source order.'
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
            GapSummary = 'Apply and Default preserve source-defined behavior.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required.'
        }
        @{
            ToolId = 'context-menu'
            DisplayName = 'Context Menu'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 3
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Broad shared-key deletion is replaced with Yazan-approved owned-value removal.'
            YazanFinalException = $false
            NextParityAction = 'Record whether the approved Default deviation is final parity or final exception.'
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
            GapSummary = 'Apply and Default preserve source-defined behavior.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required.'
        }
        @{
            ToolId = 'signout-lockscreen-wallpaper-black'
            DisplayName = 'Signout LockScreen Wallpaper Black'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 5
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Source-defined behavior is preserved with additional backup and ownership safeguards.'
            YazanFinalException = $false
            NextParityAction = 'Confirm safety mechanics are accepted as final parity.'
        }
        @{
            ToolId = 'user-account-pictures-black'
            DisplayName = 'User Account Pictures Black'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 6
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Source-defined file behavior is preserved with backup and ownership tracking.'
            YazanFinalException = $false
            NextParityAction = 'Confirm safety mechanics are accepted as final parity.'
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
            GapSummary = 'Apply and Default preserve source-defined registry/process behavior.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required.'
        }
        @{
            ToolId = 'copilot'
            DisplayName = 'Copilot'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 8
            RuntimeStatus = 'DeferredPlaceholder'
            ImplementationLevel = 'DeferredForParityWork'
            UltimateParity = 'No'
            GapSummary = 'Registry-only subset would weaken source; full source requires AppX and broad process handling.'
            YazanFinalException = $false
            NextParityAction = 'Approve package/process scopes or explicitly accept a final non-parity exception.'
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
            GapSummary = 'Open-only launcher behavior is preserved.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required.'
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
            GapSummary = 'Open-only launcher behavior is preserved.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required.'
        }
        @{
            ToolId = 'bloatware'
            DisplayName = 'Bloatware'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 11
            RuntimeStatus = 'DeferredPlaceholder'
            ImplementationLevel = 'DeferredForParityWork'
            UltimateParity = 'No'
            GapSummary = 'Source includes broad AppX/package/service/cleanup/download/repair behavior without approved restore model.'
            YazanFinalException = $false
            NextParityAction = 'Approve exact AppX/package, service, cleanup, artifact, and restore scopes before implementation.'
        }
        @{
            ToolId = 'game-bar'
            DisplayName = 'GameBar'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 12
            RuntimeStatus = 'DeferredPlaceholder'
            ImplementationLevel = 'DeferredForParityWork'
            UltimateParity = 'No'
            GapSummary = 'Source requires AppX, GameInput, service/protocol, download/repair, and TrustedInstaller behavior.'
            YazanFinalException = $false
            NextParityAction = 'Approve package, TrustedInstaller, service, repair artifact, and registry scopes.'
        }
        @{
            ToolId = 'edge-webview'
            DisplayName = 'Edge & WebView'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 13
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ManualHandoffOnly'
            UltimateParity = 'No'
            GapSummary = 'Removal/repair automation remains blocked; manual handoff only.'
            YazanFinalException = $false
            NextParityAction = 'Approve repair artifacts, installer descriptors, package/process/service/task/file/registry cleanup scopes, rollback, and support contract.'
        }
        @{
            ToolId = 'notepad-settings'
            DisplayName = 'Notepad Settings'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 14
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Source behavior is preserved on systems with the exact settings.dat; unsupported Notepad builds return NotApplicable.'
            YazanFinalException = $false
            NextParityAction = 'Confirm compatibility-gated behavior is accepted as final parity.'
        }
        @{
            ToolId = 'control-panel-settings'
            DisplayName = 'Control Panel Settings'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 15
            RuntimeStatus = 'DeferredPlaceholder'
            ImplementationLevel = 'DeferredForParityWork'
            UltimateParity = 'No'
            GapSummary = 'Very broad source needs decomposition across registry, service, cleanup, security, and TrustedInstaller behavior.'
            YazanFinalException = $false
            NextParityAction = 'Decompose into ordered implementable slices with exact scopes before parity work.'
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
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Source operations and spelling asymmetry are preserved with idempotent Default and verification.'
            YazanFinalException = $false
            NextParityAction = 'Confirm idempotent safety mechanics are accepted as final parity.'
        }
        @{
            ToolId = 'network-adapter-power-savings-wake'
            DisplayName = 'Network Adapter Power Savings & Wake'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 18
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Source-defined adapter values and repeated operation are preserved with unsupported-value warnings.'
            YazanFinalException = $false
            NextParityAction = 'Confirm warning-based unsupported adapter handling is accepted as final parity.'
        }
        @{
            ToolId = 'write-cache-buffer-flushing'
            DisplayName = 'Write Cache Buffer Flushing'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 19
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ControlledSubset'
            UltimateParity = 'Partial'
            GapSummary = 'Apply preserves source value write with capture; unsafe source Default broad key deletion is refused.'
            YazanFinalException = $false
            NextParityAction = 'Resolve Default via captured-state Restore path or obtain final exception for omitted Default.'
        }
        @{
            ToolId = 'power-plan'
            DisplayName = 'Power Plan'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 20
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'All source-defined commands are represented; unsupported settings become structured warnings rather than silent suppression.'
            YazanFinalException = $false
            NextParityAction = 'Confirm warning classification and idempotency mechanics are accepted as final parity.'
        }
        @{
            ToolId = 'cleanup'
            DisplayName = 'Cleanup'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 21
            RuntimeStatus = 'DeferredPlaceholder'
            ImplementationLevel = 'DeferredForParityWork'
            UltimateParity = 'No'
            GapSummary = 'Source performs broad recursive deletion without approved bounded cleanup/quarantine/restore scopes.'
            YazanFinalException = $false
            NextParityAction = 'Approve exact cleanup targets, limits, quarantine/delete decisions, and restore selection before implementation.'
        }
        @{
            ToolId = 'restore-point'
            DisplayName = 'Restore Point'
            Stage = 'Windows'
            StageOrder = 6
            ToolOrder = 22
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Apply/Open preserve source-defined restore point behavior and System Protection UI access.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required.'
        }
        @{
            ToolId = 'spectre-meltdown-assistant'
            DisplayName = 'Spectre / Meltdown Assistant'
            Stage = 'Advanced'
            StageOrder = 7
            ToolOrder = 1
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Source-defined security registry Apply/Default is preserved with assistant warnings and confirmation.'
            YazanFinalException = $false
            NextParityAction = 'Confirm assistant/confirmation mechanics are accepted as final parity.'
        }
        @{
            ToolId = 'mmagent-assistant'
            DisplayName = 'MMAgent Assistant'
            Stage = 'Advanced'
            StageOrder = 7
            ToolOrder = 2
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Source-defined MMAgent Apply/Default profile is preserved with assistant layer and verification.'
            YazanFinalException = $false
            NextParityAction = 'Confirm assistant/verification mechanics are accepted as final parity.'
        }
        @{
            ToolId = 'resizable-bar-assistant'
            DisplayName = 'Resizable BAR Assistant'
            Stage = 'Advanced'
            StageOrder = 7
            ToolOrder = 3
            RuntimeStatus = 'DeferredPlaceholder'
            ImplementationLevel = 'DeferredForParityWork'
            UltimateParity = 'No'
            GapSummary = 'Source requires NVIDIA Profile Inspector artifact, generated .nip import, driver profile mutation, and firmware restart path.'
            YazanFinalException = $false
            NextParityAction = 'Approve artifact, NVIDIA profile, generated-file, driver state, and firmware restart scopes.'
        }
        @{
            ToolId = 'smt-ht-assistant'
            DisplayName = 'SMT / HT Assistant'
            Stage = 'Advanced'
            StageOrder = 7
            ToolOrder = 4
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Source affinity behavior is preserved through selected process UX and explicit confirmation.'
            YazanFinalException = $false
            NextParityAction = 'Confirm selected-process UX and temporary-affinity behavior are accepted as final parity.'
        }
        @{
            ToolId = 'services-optimizer'
            DisplayName = 'Services Optimizer'
            Stage = 'Advanced'
            StageOrder = 7
            ToolOrder = 5
            RuntimeStatus = 'DeferredPlaceholder'
            ImplementationLevel = 'DeferredForParityWork'
            UltimateParity = 'No'
            GapSummary = 'Source includes Safe Mode, TrustedInstaller, service/security changes, generated scripts, RunOnce, BCD, and reboot workflow.'
            YazanFinalException = $false
            NextParityAction = 'Approve exact service, Safe Mode, TrustedInstaller, RunOnce, BCD, reboot, file, and registry scopes.'
        }
        @{
            ToolId = 'timer-resolution-assistant'
            DisplayName = 'Timer Resolution Assistant'
            Stage = 'Advanced'
            StageOrder = 7
            ToolOrder = 6
            RuntimeStatus = 'DeferredPlaceholder'
            ImplementationLevel = 'DeferredForParityWork'
            UltimateParity = 'No'
            GapSummary = 'Source generates and compiles C#, creates/removes service, edits protected timer registry, and deletes protected-path files.'
            YazanFinalException = $false
            NextParityAction = 'Approve generated artifact/compiler, service, protected file, registry, and cleanup scopes.'
        }
        @{
            ToolId = 'defender-optimize-assistant'
            DisplayName = 'Defender Optimize Assistant'
            Stage = 'Advanced'
            StageOrder = 7
            ToolOrder = 7
            RuntimeStatus = 'DeferredPlaceholder'
            ImplementationLevel = 'DeferredForParityWork'
            UltimateParity = 'No'
            GapSummary = 'Source includes security-sensitive Safe Mode, TrustedInstaller, Defender registry, scheduled task, RunOnce, BCD, generated script, and reboot behavior.'
            YazanFinalException = $false
            NextParityAction = 'Approve security-sensitive scopes, TrustedInstaller, Safe Mode, task, RunOnce, BCD, reboot, and verification plan.'
        }
    )
}
