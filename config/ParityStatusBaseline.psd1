@{
    SchemaVersion = 1
    Purpose = 'Phase 107 Ordered Ultimate Parity Execution Reset'
    DesignSystemReady = $false

    Counts = @{
        ActiveTools = 55
        RuntimeImplementedTools = 44
        DeferredPlaceholders = 11
        SourcePromotedMirrorFiles = 7
        RemainingSourcePromotedIntakeCandidates = 0
        UltimateParityImplemented = 16
        NearParityControlled = 17
        ControlledSubset = 2
        ManualHandoffOnly = 8
        SecurityAssistantOnly = 1
        DeferredForParityWork = 11
        RefusedOrDeletedOutsideActiveCatalog = 19
    }

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
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Preserves firmware restart command path with explicit confirmation.'
            YazanFinalException = $false
            NextParityAction = 'Confirm confirmation-gated restart is accepted as final parity.'
        }
        @{
            ToolId = 'memory-compression'
            DisplayName = 'Memory Compression'
            Stage = 'Setup'
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
            RuntimeStatus = 'DeferredPlaceholder'
            ImplementationLevel = 'DeferredForParityWork'
            UltimateParity = 'No'
            GapSummary = 'Source is not open-only and includes policy, Active Setup, RunOnce, services, and repair download behavior.'
            YazanFinalException = $false
            NextParityAction = 'Implement only after exact Edge repair artifacts, service scopes, RunOnce/Active Setup handling, and registry/file rollback are approved.'
        }
        @{
            ToolId = 'store-settings'
            DisplayName = 'Store Settings'
            Stage = 'Setup'
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
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'SecurityAssistantOnly'
            UltimateParity = 'No'
            GapSummary = 'Security-sensitive mutation branches remain blocked; tool provides analysis and manual guidance only.'
            YazanFinalException = $false
            NextParityAction = 'Obtain Yazan-approved BitLocker mutation, recovery-key, protector, and restore policy or final advisory-only exception.'
        }
        @{
            ToolId = 'installers'
            DisplayName = 'Installers'
            Stage = 'Installers'
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ManualHandoffOnly'
            UltimateParity = 'No'
            GapSummary = 'Source downloads and runs installers; Auto remains blocked.'
            YazanFinalException = $false
            NextParityAction = 'Approve per-app artifacts, installer descriptors, side-effect scopes, cleanup, rollback, and support policy.'
        }
        @{
            ToolId = 'driver-clean'
            DisplayName = 'Driver Clean'
            Stage = 'Graphics'
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ManualHandoffOnly'
            UltimateParity = 'No'
            GapSummary = 'DDU and 7-Zip automation remain blocked despite Yazan intake exception.'
            YazanFinalException = $false
            NextParityAction = 'Resolve controlled DDU/7-Zip artifact, Safe Mode, process, reboot, and recovery approvals.'
        }
        @{
            ToolId = 'driver-install-latest'
            DisplayName = 'Driver Install Latest'
            Stage = 'Graphics'
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ManualHandoffOnly'
            UltimateParity = 'No'
            GapSummary = 'NVIDIA driver download and installer execution remain blocked.'
            YazanFinalException = $false
            NextParityAction = 'Approve driver artifact/provenance, installer execution, driver rollback, and reboot/session handling.'
        }
        @{
            ToolId = 'nvidia-settings'
            DisplayName = 'Nvidia Settings'
            Stage = 'Graphics'
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ManualHandoffOnly'
            UltimateParity = 'No'
            GapSummary = '7-Zip, Profile Inspector, profile import, registry/profile mutation, and Control Panel launch remain blocked.'
            YazanFinalException = $false
            NextParityAction = 'Approve artifacts, generated .nip ownership, NVIDIA profile/registry scopes, and process execution path.'
        }
        @{
            ToolId = 'hdcp'
            DisplayName = 'HDCP'
            Stage = 'Graphics'
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Source-defined NVIDIA registry value behavior is implemented with safer NVIDIA target filtering and capture.'
            YazanFinalException = $false
            NextParityAction = 'Confirm safer NVIDIA filtering/capture is accepted as final parity; Restore remains captured-state only.'
        }
        @{
            ToolId = 'p0-state'
            DisplayName = 'P0 State'
            Stage = 'Graphics'
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Source-defined NVIDIA registry behavior is implemented with safer target filtering and capture.'
            YazanFinalException = $false
            NextParityAction = 'Confirm safer NVIDIA filtering/capture is accepted as final parity; Restore remains captured-state only.'
        }
        @{
            ToolId = 'msi-mode'
            DisplayName = 'Msi Mode'
            Stage = 'Graphics'
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'NearParityControlled'
            UltimateParity = 'Partial'
            GapSummary = 'Source-defined NVIDIA device registry behavior is implemented with safer target filtering and capture.'
            YazanFinalException = $false
            NextParityAction = 'Confirm safer NVIDIA filtering/capture is accepted as final parity; Restore remains captured-state only.'
        }
        @{
            ToolId = 'driver-install-debloat-settings'
            DisplayName = 'Driver Install Debloat & Settings'
            Stage = 'Graphics'
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ManualHandoffOnly'
            UltimateParity = 'No'
            GapSummary = 'NVIDIA Auto path remains blocked; AMD/Intel branches are unsupported by product scope.'
            YazanFinalException = $false
            NextParityAction = 'Approve NVIDIA artifact, driver/package, profile, AppX, cleanup, registry, and reboot scopes or accept final manual exception.'
        }
        @{
            ToolId = 'directx'
            DisplayName = 'DirectX'
            Stage = 'Graphics'
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ManualHandoffOnly'
            UltimateParity = 'No'
            GapSummary = 'Download, extraction, 7-Zip install/config, and DXSETUP execution remain blocked.'
            YazanFinalException = $false
            NextParityAction = 'Approve immutable artifacts, extracted DXSETUP provenance, installer descriptors, and temp/file cleanup scopes.'
        }
        @{
            ToolId = 'visual-cpp'
            DisplayName = 'Visual C++'
            Stage = 'Graphics'
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ManualHandoffOnly'
            UltimateParity = 'No'
            GapSummary = 'Twelve redistributable downloads and installer executions remain blocked.'
            YazanFinalException = $false
            NextParityAction = 'Approve all redistributable artifacts, signer/hash/size evidence, installer descriptors, exit codes, and temp scopes.'
        }
        @{
            ToolId = 'graphics-configuration-center'
            DisplayName = 'Graphics Configuration Center'
            Stage = 'Graphics'
            RuntimeStatus = 'RuntimeImplemented'
            ImplementationLevel = 'ParityImplemented'
            UltimateParity = 'Yes'
            GapSummary = 'Open-only launcher behavior is preserved.'
            YazanFinalException = $false
            NextParityAction = 'No parity work required.'
        }
        @{
            ToolId = 'start-menu-taskbar'
            DisplayName = 'Start Menu Taskbar'
            Stage = 'Windows'
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
            RuntimeStatus = 'DeferredPlaceholder'
            ImplementationLevel = 'DeferredForParityWork'
            UltimateParity = 'No'
            GapSummary = 'Source includes security-sensitive Safe Mode, TrustedInstaller, Defender registry, scheduled task, RunOnce, BCD, generated script, and reboot behavior.'
            YazanFinalException = $false
            NextParityAction = 'Approve security-sensitive scopes, TrustedInstaller, Safe Mode, task, RunOnce, BCD, reboot, and verification plan.'
        }
    )
}
