# NVIDIA Path B Scope Design

## Purpose And Status

Phase 74 defines a scope design for the five NVIDIA App Path B scripts promoted
as source references under `source-ultimate/_intake-promoted/Ultimate/`.

This is scope design only.

This phase adds no implementation, no executable module, no tool card, no
placeholder enablement, no runtime workflow config, and no production approval.

Phase 94 current-state note: `Driver Install Latest` and `Nvidia Settings` are
now implemented only as controlled manual-handoff active tools for Path B steps
1 and 2. Auto remains blocked as `AutoBlockedUntilArtifactApproval`; no NVIDIA
driver download, installer execution, 7-Zip download/install, NVIDIA Profile
Inspector download/execution, `.nip` import/export, browser opening, Control
Panel launch, external process start, NVIDIA registry/profile mutation,
registry/system/driver mutation, reboot, session change, Default, Restore, or
remaining Path B step is approved.

NVIDIA App Path B order is mandatory and user-facing:

`Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`

Path B remains separate from Path A unless a later explicit design approves a
safe mixed workflow.

* Path A: `Driver Install Debloat & Settings`
* Path B: `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`

Path B is for users who want to keep or use NVIDIA App features such as
recording or related NVIDIA App features.

Future UI must prevent accidental mixing between Path A and Path B unless a
later explicit design approves a safe mixed workflow.

## Source Summary Table

The table below records the high-level source behavior inventory for each
Path B script, including command families, registry targets, file mutations,
downloads, external tools, process actions, NVIDIA settings operations,
session implications, Default/Restore implications, risk groups, and required
future foundations.

| Step | Display name | Source mirror path | SHA-256 | Source relative path | Stage | High-level source behavior | Detected command families | Detected registry paths or values | Detected file paths or mutations | Detected downloads/artifacts/installers | Detected external executables/tools | Detected services/tasks/process actions | Detected driver/profile/NVIDIA settings operations | Reboot/session/sign-out implications | Default/Restore implications | Major risk groups | Required future foundations | Future design requirement | Current status |
|---:|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Driver Install Latest | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1` | `41C9DEA9AA5D208C9ED1EB7F1512B24251FBF4DC01C6DE2858B5B1A26C631A2F` | `5 Graphics/2 Driver Install Latest.ps1` | Graphics | Prompts for GPU vendor; NVIDIA branch queries NVIDIA driver API, builds latest driver URL, downloads to `%SystemRoot%\Temp\nvidiadriver.exe`, then launches installer. AMD and Intel branches also exist in source but are outside BoostLab GPU scope. | `Invoke-WebRequest`/`IWR`, `ConvertFrom-Json`, `Start-Process`, `Read-Host`, console output, admin self-elevation. | None in the NVIDIA branch. | `%SystemRoot%\Temp\nvidiadriver.exe` download target. | NVIDIA driver API and NVIDIA driver installer URL; AMD web installer branch; Intel driver webpage branch. | NVIDIA driver installer executable; AMD installer branch; Intel browser handoff branch. | Process launch/handoff to driver installer. No service/task mutation directly in script. | NVIDIA driver download/install handoff. AMD/Intel branches must remain unsupported. | No explicit reboot, but driver installer can have reboot/session implications that must be planned before implementation. | No source Default or Restore path for the driver installer. | Download, installer, driver mutation, process handoff, admin, internet, reboot-capable installer, unsupported AMD/Intel branches. | Production Allowlist Governance; Download Provenance and Installer Execution Policy; Driver State Capture and Rollback; Process Handling Policy; Reboot/Recovery Workflow; Action Plan confirmation. | Scope + provenance design. | NotImplemented / ScopeDesignOnly |
| 2 | Nvidia Settings | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1` | `903F2C1E9965795E3B5C60ABD123A1B4F364A33F783BFFC681FBCB37BCE9E6D5` | `5 Graphics/4 Nvidia Settings.ps1` | Graphics | Downloads and installs 7-Zip, configures 7-Zip, changes Start Menu shortcut layout, unblocks NVIDIA DRS files, writes NVIDIA registry values, downloads NVIDIA Profile Inspector, writes `inspector.nip`, imports profile settings, and opens NVIDIA Control Panel. Default branch deletes or changes NVIDIA registry/profile state and imports an empty profile. | `IWR`, `Start-Process`, `cmd /c reg add/delete`, `Move-Item`, `Remove-Item`, `Get-ChildItem`, `Unblock-File`, `Set-Content`, `Read-Host`, admin self-elevation. | `HKCU\Software\7-Zip\Options` values `ContextMenu`, `CascadedMenu`; `HKLM\System\ControlSet001\Services\nvlddmkm\Parameters\Global\NVTweak` values `NvCplPhysxAuto`, `NvDevToolsVisible`, `RmProfilingAdminOnly`; display class registry value `RmProfilingAdminOnly`; `HKCU\Software\NVIDIA Corporation\NvTray`; `HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\FTS` value `EnableGR535`; `HKLM\SYSTEM\ControlSet001\Services\nvlddmkm\Parameters\FTS` value `EnableGR535`; `HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Parameters\FTS` value `EnableGR535`. | `%SystemRoot%\Temp\7zip.exe`; `%SystemRoot%\Temp\inspector.exe`; `%SystemRoot%\Temp\inspector.nip`; `C:\ProgramData\NVIDIA Corporation\Drs`; `%ProgramData%\Microsoft\Windows\Start Menu\Programs\7-Zip\7-Zip File Manager.lnk`; `%ProgramData%\Microsoft\Windows\Start Menu\Programs\7-Zip`. | 7-Zip executable from GitHub raw URL; NVIDIA Profile Inspector executable from GitHub raw URL; generated `.nip` profile file. | `Start-Process` for 7-Zip installer, Profile Inspector import, and NVIDIA Control Panel app URI. No services/tasks directly, but driver/profile state is affected. | NVIDIA Control Panel settings, NVIDIA DRS/profile import, NVIDIA service/driver registry values, performance counter access, PhysX/developer/settings/tray/legacy sharpen related values. | No explicit reboot or sign-out; profile import and driver setting changes may have session/application effects. | Source has On and Default branches. Default deletes some values, deletes `HKCU\Software\NVIDIA Corporation\NvTray`, changes `EnableGR535`, and imports empty profile data. No BoostLab Restore can be claimed without captured state. | Downloads, installer execution, registry mutation, file mutation/cleanup, generated artifact, profile import, external tool execution, driver/profile state, Default semantics, admin, internet. | Production Allowlist Governance; Download Provenance and Installer Execution Policy; Driver State Capture and Rollback; File/Registry State Capture and Rollback; Process Handling Policy; Restore Selection UI / Runtime; future NVIDIA profile/state capture model. | Driver/profile/settings design. | NotImplemented / ScopeDesignOnly |
| 3 | Hdcp | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/5 Hdcp.ps1` | `5C350D28F795D678051E6088F34968DF8D90B3D9024F558C5FAFB2899D1A906A` | `5 Graphics/5 Hdcp.ps1` | Graphics | Enumerates display class registry subkeys and writes `RMHdcpKeyglobZero` to `1` for Off or `0` for Default, skipping subkeys whose names match `*Configuration`. | `Get-ChildItem`, `reg add`, `Get-ItemProperty`, `Read-Host`, admin self-elevation. | `HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\*\RMHdcpKeyglobZero`. | None. | None. | `reg.exe`. | No services/tasks/process actions beyond registry command invocation. | NVIDIA display-class HDCP-related registry setting mutation. | No explicit reboot or sign-out; display/driver setting effect timing is unknown and must be verified in future design. | Source has Off and Default branches. Default writes `RMHdcpKeyglobZero=0`; it is not a captured-state Restore. | HKLM driver registry mutation, display/security/content-protection behavior, broad display-class enumeration, Default semantics, admin. | Production Allowlist Governance; Driver State Capture and Rollback; File/Registry State Capture and Rollback; Restore Selection UI / Runtime; future NVIDIA profile/state capture model if registry capture alone is not enough. | Driver/profile/settings design. | NotImplemented / ScopeDesignOnly |
| 4 | P0 State | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/6 P0 State.ps1` | `382DFEC45B5C8F1D00388CFEFF38187517188EC0139DA751B42DEB1BEA4358EC` | `5 Graphics/6 P0 State.ps1` | Graphics | Enumerates display class registry subkeys and writes `DisableDynamicPstate` to `1` for On or `0` for Default, skipping subkeys whose names match `*Configuration`. | `Get-ChildItem`, `reg add`, `Get-ItemProperty`, `Read-Host`, admin self-elevation. | `HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\*\DisableDynamicPstate`. | None. | None. | `reg.exe`. | No services/tasks/process actions beyond registry command invocation. | NVIDIA driver performance-state registry setting. | No explicit reboot or sign-out; power, thermal, stability, and driver-session effects are disclosed in the controlled implementation. | Source has On and Default branches. Default writes `DisableDynamicPstate=0`; it is not a captured-state Restore. | HKLM driver registry mutation, GPU power/performance behavior, thermal/stability risk, broad display-class enumeration, Default semantics, admin. | Production Allowlist Governance; Driver State Capture and Rollback; File/Registry State Capture and Rollback; Restore Selection UI / Runtime; future NVIDIA profile/state capture model if registry capture alone is not enough. | Controlled registry implementation active; future Restore selection remains pending. | ImplementedControlled / RestoreUnavailable |
| 5 | Msi Mode | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/7 Msi Mode.ps1` | `94F5A99232333985F6855C9000BD94FA1067D9152885AF84FBECB6E0C1807BF7` | `5 Graphics/7 Msi Mode.ps1` | Graphics | Uses `Get-PnpDevice -Class Display`, then writes `MSISupported` to `1` for On or `0` for Off under each display device interrupt-management registry path. | `Get-PnpDevice`, `reg add`, `Get-ItemProperty`, `Read-Host`, admin self-elevation. | `HKLM\SYSTEM\ControlSet001\Enum\<InstanceId>\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties\MSISupported`. | None. | None. | `reg.exe`. | Device enumeration through PnP; no services/tasks/process actions beyond registry command invocation. | Display device interrupt mode registry setting. Source targets all display devices, so future BoostLab design must constrain to NVIDIA or return NotApplicable for non-NVIDIA targets. | No explicit reboot, but interrupt-mode changes may require reboot or device restart to take effect. Future design must answer this before implementation. | Source has On and Off branches, not a captured-state Restore. Off writes `MSISupported=0`; Default semantics must be designed separately if exposed. | HKLM device registry mutation, interrupt-mode behavior, display device targeting, AMD/Intel product-scope risk, possible reboot/device restart effect, admin. | Production Allowlist Governance; Driver State Capture and Rollback; File/Registry State Capture and Rollback; Reboot/Recovery Workflow if reboot/device restart is required; Restore Selection UI / Runtime; future NVIDIA profile/state capture model if registry capture alone is not enough. | Driver/profile/settings design and NVIDIA-only targeting decision. | NotImplemented / ScopeDesignOnly |

## Driver Install Latest Scope Design

The source appears to select, download, launch, and hand off to GPU driver
installers. The NVIDIA branch queries NVIDIA's driver lookup service, builds a
driver installer URL, downloads the installer to
`%SystemRoot%\Temp\nvidiadriver.exe`, and launches it.

The source also contains AMD and Intel branches. Those branches are outside
BoostLab's NVIDIA-only GPU product scope and must remain disabled, visual-only,
or NotApplicable unless Yazan changes product scope later.

Artifact/provenance questions before implementation:

* Is the NVIDIA driver lookup API an approved source of truth?
* How will a dynamically selected "latest" driver be pinned to exact SHA-256,
  size, signer, and version before execution?
* Where is the driver stored, and who owns cleanup of
  `%SystemRoot%\Temp\nvidiadriver.exe`?
* What installer switches, if any, are source-approved?
* How are failed downloads, partial downloads, hash mismatches, and signer
  mismatches reported?

Driver state and rollback requirements:

* Capture current NVIDIA device identity, hardware ids, driver provider,
  version, INF/package identity, and related state before installer handoff.
* Define whether BoostLab can verify driver install success after a handoff.
* Define support boundaries if the installer changes components outside
  BoostLab control.
* Define whether rollback is possible, and do not expose Restore until exact
  captured-state rollback is approved.

Installer/process/reboot requirements:

* Installer execution must use the Phase 35 provenance and execution policy.
* Process launch must use a future approved process handoff plan.
* Any reboot request or reboot-capable installer behavior must be represented
  in Action Plan and, if necessary, the Reboot/Recovery Workflow foundation.

It cannot be implemented yet because there is no approved artifact provenance,
installer descriptor, NVIDIA driver state scope, process handoff policy, reboot
plan, or rollback/support model for this dynamic driver installer workflow.

## Nvidia Settings Scope Design

The source appears to apply NVIDIA Control Panel, NVIDIA profile, registry,
file, and command-line settings.

Detected behavior includes:

* Downloading `7zip.exe` and `inspector.exe` from GitHub raw URLs.
* Installing 7-Zip silently.
* Writing 7-Zip HKCU options and changing Start Menu shortcut layout.
* Unblocking files under `C:\ProgramData\NVIDIA Corporation\Drs`.
* Writing or deleting NVIDIA `nvlddmkm` registry values.
* Writing or deleting `HKCU\Software\NVIDIA Corporation\NvTray`.
* Creating `%SystemRoot%\Temp\inspector.nip`.
* Running `%SystemRoot%\Temp\inspector.exe` with silent import arguments.
* Opening NVIDIA Control Panel.

NVIDIA-only targeting requirements:

* Confirm NVIDIA GPU and NVIDIA driver presence before any plan.
* Block or mark NotApplicable on AMD/Intel-only systems.
* Ensure profile imports are tied to NVIDIA driver/profile state.

Driver/profile state capture requirements:

* Capture all exact registry values before mutation.
* Capture generated `.nip` ownership and content hash before use.
* Define whether NVIDIA DRS/profile state can be inventoried or backed up.
* Define how NVIDIA Profile Inspector import success is verified.

Default/Restore concerns:

* Source Default deletes several registry values and imports empty profile
  content.
* Source Default is not the same as captured-state Restore.
* BoostLab must not expose Restore unless it has exact captured registry,
  profile, file, and generated-artifact state.

It cannot be implemented yet because required artifact provenance, installer
execution approval, registry/file scopes, generated `.nip` policy, NVIDIA
profile state capture, process launch policy, Default semantics, and Restore
selection are not approved.

## Hdcp Scope Design

The source appears to mutate an HDCP-related NVIDIA display driver registry
setting by writing `RMHdcpKeyglobZero`.

Display/driver/security implications:

* The setting appears tied to High-bandwidth Digital Content Protection.
* It may affect protected media playback or display behavior.
* It writes under a display-class driver registry path and must be treated as
  driver/security-adjacent rather than a casual UI tweak.

NVIDIA-only targeting requirements:

* Future discovery must identify NVIDIA display-class instances exactly.
* AMD/Intel display devices must be excluded or reported NotApplicable.
* Broad writes to all display-class subkeys are not approved by this design.

Capture/rollback requirements:

* Capture existence, value type, and value data for `RMHdcpKeyglobZero` before
  writing.
* Verify each targeted value after mutation.
* Treat source Default (`RMHdcpKeyglobZero=0`) as source-defined Default, not
  Restore.
* Do not expose Restore without captured state and selection.

It cannot be implemented yet because exact NVIDIA display-class targeting,
production registry scopes, capture/verification rules, and Default/Restore
policy are not approved.

## P0 State Scope Design

The source appears to force or influence NVIDIA P0/performance-state behavior
by writing `DisableDynamicPstate`.

Driver/profile/registry requirements:

* Future design must map the source behavior to exact NVIDIA display-class
  registry targets.
* Registry writes require capture before mutation and post-write verification.
* If driver profile state outside the registry is affected, a future NVIDIA
  profile/state capture model may be needed.

Power/thermal/stability implications:

* The source text describes "Always Force Max Boost Clock."
* This can affect power draw, thermals, fan behavior, battery life, and system
  stability.
* Action Plan must explain those risks before any future execution.

Capture/rollback requirements:

* Capture existence, value type, and value data for `DisableDynamicPstate`.
* Source On writes `DisableDynamicPstate=1`.
* Source Default writes `DisableDynamicPstate=0`.
* Restore requires captured prior state and must not be implied by Default.

It cannot be implemented yet because exact NVIDIA target selection,
production registry scopes, thermal/power warnings, verification, and
Default/Restore policy are not approved.

## Msi Mode Scope Design

The source appears to modify Message Signaled Interrupt mode by writing
`MSISupported` under each display device's interrupt-management registry path.

NVIDIA-only targeting decision requirements:

* The source discovers all display devices with `Get-PnpDevice -Class Display`.
* BoostLab GPU-specific scope is NVIDIA-only.
* Future design must either narrow to verified NVIDIA display devices or report
  non-NVIDIA devices as NotApplicable.
* Broad display-device writes across AMD/Intel are not approved.

Device/driver identification requirements:

* Verify device vendor, instance id, hardware ids, and current driver package.
* Resolve the exact registry path for each target device.
* Avoid writes when device identity is ambiguous.

Reboot requirement questions:

* The source does not explicitly reboot.
* Interrupt-mode changes may require device restart or system reboot to take
  effect.
* A future implementation must document whether reboot is required, optional,
  or unsupported and must use Reboot/Recovery Workflow if reboot is involved.

Registry capture/rollback requirements:

* Capture existence, value type, and value data for `MSISupported`.
* Source On writes `MSISupported=1`.
* Source Off writes `MSISupported=0`.
* Source Off is not a captured-state Restore.

It cannot be implemented yet because exact NVIDIA device targeting, registry
scope approval, capture/verification, reboot-effect policy, and
Default/Restore semantics are not approved.

## Workflow-Level Constraints

If implemented later, Path B must execute in exact order:

`Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`

Future UI must guide users through the Path B steps. It must not show the five
Path B scripts as random unordered graphics tools.

Path A and Path B must be mutually guided workflows. Mixing Path A and Path B
requires a later explicit design decision.

Failure, refusal, NotApplicable, or cancellation at one Path B step should stop or clearly gate later steps unless a future design explicitly approves skip behavior.

Each future step must define:

* Action Plan requirements
* Explicit confirmation requirements
* Latest Result fields
* Activity Log messages
* Preflight checks
* Verification checks
* Failure policy
* Default status
* Restore status

## Required Future Metadata

Before future implementation, every Path B step must define:

* `WorkflowId`
* `StepId`
* `StepNumber`
* `SourceMirrorPath`
* `SourceChecksum`
* `DesignDocumentPath`
* `SourceBehaviorInventory`
* `ProductionScopeReferences`
* `ProvenanceReferences`
* `DriverRollbackReferences`
* `RegistryRollbackReferences`
* `FileRollbackReferences`
* `ProcessPolicyReferences`
* `RebootPolicyReferences`
* `NvidiaOnlyTargetingRule`
* `Prerequisites`
* `MutualExclusionWithPathA`
* `ConfirmationLevel`
* `RiskLevel`
* `DefaultStatus`
* `RestoreStatus`
* `VerificationCommandsOrChecks`
* `FailurePolicy`
* `UIWarningText`
* `ImplementationStatus`

## Required Future Foundations And Approvals

The workflow overall requires:

* Production Allowlist Governance
* Download Provenance and Installer Execution Policy
* Driver State Capture and Rollback
* File/Registry State Capture and Rollback
* Process Handling Policy
* Reboot/Recovery Workflow
* Restore Selection UI / Runtime
* Security-Sensitive Change Approval if HDCP or protected-content behavior is
  treated as security-sensitive in the future
* A future NVIDIA profile/state capture model if the existing driver
  foundation is not enough for NVIDIA Profile Inspector and DRS/profile state

Per-script foundation needs:

| Script | Required foundations and approvals |
|---|---|
| Driver Install Latest | Production allowlist; artifact provenance; installer execution; driver state capture; process handoff; reboot/recovery if installer can reboot; Action Plan confirmation. |
| Nvidia Settings | Production allowlist; artifact provenance for 7-Zip and Inspector; installer execution; registry/file capture; generated `.nip` ownership; process handling; NVIDIA profile/state capture; Restore selection if Restore is ever exposed. |
| Hdcp | Production registry allowlist; NVIDIA-only display target discovery; registry capture; driver/profile state capture if needed; security-sensitive review if HDCP behavior is classified that way; Restore selection for captured-state Restore only. |
| P0 State | Production registry allowlist; NVIDIA-only display target discovery; registry capture; driver/profile state capture if needed; power/thermal warnings; Restore selection for captured-state Restore only. |
| Msi Mode | Production registry allowlist; NVIDIA-only device identity; registry capture; driver/device state capture; reboot/recovery decision; Restore selection for captured-state Restore only. |

## Related Source-Promoted Scripts Outside This Scope

`Driver Clean` is related to graphics intake, but it is not part of the five-step NVIDIA Path B scope design. Driver Clean remains a Yazan-approved intake exception despite DDU usage and needs a separate Driver Clean
scope/provenance/safety design later.

`BitLocker` is not related to NVIDIA Path B. It remains pending future security-sensitive design.

## Non-Actions

Phase 74 is scope design only.

* No source mirror files were changed.
* No intake files were changed.
* No source-ultimate legacy files were changed.
* No implementation was added.
* No executable modules were created for Path B scripts.
* No placeholders or tool cards were enabled.
* No runtime behavior changed.
* No production scopes, allowlists, artifacts, downloads, installers, drivers,
  profile writes, AppX, services, tasks, process handling, cleanup, reboot,
  TrustedInstaller, Safe Mode, Default, or Restore approvals were added.
* No DDU execution, DDU download, or DDU artifact approval was added.
* Standalone DDU was not introduced.
* Loudness EQ and NVME Faster Driver remain deleted.
* Counts remain unchanged: 48 active tools, 30 implemented tools, 18
  deferred/placeholders, and 7 source-promoted intake candidates separate from
  official counts.

## Recommended Next Phase

Recommended next phase: **NVIDIA Path B Production Allowlist Planning**.

That phase should still remain non-executing unless Yazan explicitly approves
one exact production scope proposal. A cautious next step would be to draft
non-approved allowlist proposals for `Hdcp`, `P0 State`, and `Msi Mode` first,
because they are narrower than the download/installer/profile-import steps.

Phase 75 records non-approved candidate allowlist planning in
`docs/tool-designs/nvidia-path-b-production-allowlist-planning.md`. It creates
no production config and approves no scope.

Phase 76 records non-approved artifact provenance review in
`docs/tool-designs/nvidia-path-b-artifact-provenance-review.md`. It approves no
artifacts, downloads, installers, production scopes, or production provenance
config changes.

Phase 77 records the inert NVIDIA profile state capture model in
`docs/nvidia-profile-state-capture-model.md`. It keeps all profile capture,
restore, import, export, Profile Inspector execution, and `.nip` operations
unapproved.

Phase 78 records future Path A / Path B UI workflow design in
`docs/nvidia-path-b-ui-workflow-design.md`. It adds no visible UI controls,
runtime workflow config, or production approval.

Phase 79 records non-approved draft allowlist proposals in
`docs/tool-designs/nvidia-path-b-draft-allowlist-proposal.md`. It keeps every
candidate Draft/NotApproved and creates no production config.

Phase 80 records production approval gate design in
`docs/tool-designs/nvidia-path-b-production-approval-gate-design.md`. It creates
no production config and approves no Path B scope.

Phase 81 records runtime gating design in
`docs/tool-designs/nvidia-path-b-runtime-gating-design.md`. It creates no
runtime gate implementation, production config, production approval, UI
implementation, tool card, placeholder enablement, or Path B execution
behavior.

Phase 87 records documentation index/navigation design in
`docs/tool-designs/nvidia-path-b-documentation-index-navigation-design.md`. It
indexes this scope design without approving any scope or enabling any Path B
behavior.

Phase 88 records documentation backlink audit design in
`docs/tool-designs/nvidia-path-b-documentation-backlink-audit-design.md`. It
defines future backlink audit rules without creating a live backlink auditor,
active docs runtime, active config, production approval, or Path B execution
behavior.

Phase 89 records governance freeze review in
`docs/tool-designs/nvidia-path-b-governance-freeze-review.md`. It freezes the
Path B documentation set as design-only and non-executing without creating
active governance runtime, production approval, UI approval, runtime approval,
or Path B execution behavior.
