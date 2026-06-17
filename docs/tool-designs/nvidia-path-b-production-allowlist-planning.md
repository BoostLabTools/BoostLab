# NVIDIA Path B Production Allowlist Planning

## Purpose And Status

Phase 75 creates planning notes for future production allowlists that would be
needed before NVIDIA App Path B could ever be implemented.

This is planning only.

No production allowlist is approved. No production scope is approved. No
artifact, download, installer, driver operation, NVIDIA profile write, registry
write, file mutation, process action, reboot workflow, Default behavior, or
Restore behavior is approved.

No implementation, placeholder, tool card, executable module, runtime workflow
config, or runtime behavior change is added.

Every candidate entry in this document is one of:

* `DraftCandidate`
* `NeedsProvenance`
* `NeedsDriverRollback`
* `NeedsRegistryRollback`
* `NeedsProcessPolicy`
* `NeedsRebootPolicy`
* `NeedsSecurityReview`
* `Rejected`
* `NotApproved`

Do not treat any candidate in this document as executable permission.

NVIDIA App Path B order remains:

`Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`

Path relationship:

* Path A: `Driver Install Debloat & Settings`
* Path B: `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`

Path B is for users who want to keep or use NVIDIA App features such as
recording or related NVIDIA App features. Path A and Path B remain mutually
guided workflows, and accidental mixing remains blocked until a later explicit
design approves otherwise.

## Source Reference Table

| Step | Script | Source mirror path | SHA-256 |
|---:|---|---|---|
| 1 | Driver Install Latest | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1` | `41C9DEA9AA5D208C9ED1EB7F1512B24251FBF4DC01C6DE2858B5B1A26C631A2F` |
| 2 | Nvidia Settings | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1` | `903F2C1E9965795E3B5C60ABD123A1B4F364A33F783BFFC681FBCB37BCE9E6D5` |
| 3 | Hdcp | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/5 Hdcp.ps1` | `5C350D28F795D678051E6088F34968DF8D90B3D9024F558C5FAFB2899D1A906A` |
| 4 | P0 State | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/6 P0 State.ps1` | `382DFEC45B5C8F1D00388CFEFF38187517188EC0139DA751B42DEB1BEA4358EC` |
| 5 | Msi Mode | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/7 Msi Mode.ps1` | `94F5A99232333985F6855C9000BD94FA1067D9152885AF84FBECB6E0C1807BF7` |

## Source-To-Allowlist Inventory

The inventory below records candidate registry paths, candidate registry value names, candidate file paths, candidate generated files, candidate downloaded artifacts, candidate external executables, candidate installer commands, candidate NVIDIA driver/profile operations, candidate process actions, candidate service or scheduled task actions, candidate reboot/session implications, candidate verification checks, candidate Default/Restore concerns, and unresolved questions.

| Step | Script | Candidate registry paths | Candidate registry value names | Candidate file paths | Candidate generated files | Candidate downloaded artifacts | Candidate external executables | Candidate installer commands | Candidate NVIDIA driver/profile operations | Candidate process actions | Candidate service/task actions | Candidate reboot/session implications | Candidate verification checks | Candidate Default/Restore concerns | Unresolved questions |
|---:|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Driver Install Latest | None in NVIDIA branch | None in NVIDIA branch | `%SystemRoot%\Temp\nvidiadriver.exe` | None | NVIDIA latest-driver executable resolved from NVIDIA driver lookup service; AMD and Intel source branches remain unsupported | NVIDIA driver installer executable | `Start-Process "%SystemRoot%\Temp\nvidiadriver.exe"` | NVIDIA driver download and installer handoff | Installer process launch/handoff | None directly in script | Installer may require reboot or session interruption; source does not explicitly reboot | Source mirror checksum; artifact provenance; signer/hash; downloaded file path; installer handoff result; driver version/device state before and after | No source Default or Restore path | Can a dynamic "latest" NVIDIA driver ever satisfy exact hash/signature provenance? Which driver versions are allowed? How is rollback supported? |
| 2 | Nvidia Settings | `HKCU\Software\7-Zip\Options`; `HKLM\System\ControlSet001\Services\nvlddmkm\Parameters\Global\NVTweak`; display class `{4d36e968-e325-11ce-bfc1-08002be10318}` instances; `HKCU\Software\NVIDIA Corporation\NvTray`; `HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\FTS`; `HKLM\SYSTEM\ControlSet001\Services\nvlddmkm\Parameters\FTS`; `HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Parameters\FTS` | `ContextMenu`; `CascadedMenu`; `NvCplPhysxAuto`; `NvDevToolsVisible`; `RmProfilingAdminOnly`; `StartOnLogin`; `EnableGR535` | `%SystemRoot%\Temp\7zip.exe`; `%SystemRoot%\Temp\inspector.exe`; `%SystemRoot%\Temp\inspector.nip`; `C:\ProgramData\NVIDIA Corporation\Drs`; `%ProgramData%\Microsoft\Windows\Start Menu\Programs\7-Zip\7-Zip File Manager.lnk`; `%ProgramData%\Microsoft\Windows\Start Menu\Programs\7-Zip` | `%SystemRoot%\Temp\inspector.nip` | 7-Zip executable; NVIDIA Profile Inspector executable | 7-Zip installer; NVIDIA Profile Inspector; NVIDIA Control Panel app URI | `Start-Process -Wait "%SystemRoot%\Temp\7zip.exe" -ArgumentList "/S"`; `Start-Process -Wait "%SystemRoot%\Temp\inspector.exe" -ArgumentList "-silentImport -silent ..."` | NVIDIA registry tuning; DRS/profile unblock; generated `.nip` profile import; NVIDIA Control Panel launch | 7-Zip installer launch; Inspector import process; Control Panel launch | None directly in script | No explicit reboot; driver/profile state may require session/app restart to reflect | Registry pre/post values; file existence/hash; generated `.nip` hash; Inspector artifact provenance; profile import result; NVIDIA Control Panel launch result if preserved | Source Default deletes some registry values, deletes an HKCU key, sets `EnableGR535=1`, and imports empty profile data. This is not captured-state Restore. | Can NVIDIA profile state be captured precisely? Should 7-Zip install remain part of the preserved behavior? How are `.nip` settings validated? |
| 3 | Hdcp | `HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\*` excluding `*Configuration` | `RMHdcpKeyglobZero` | None | None | None | `reg.exe` | None | NVIDIA display-class HDCP-related registry mutation | Registry command invocation only | None | No explicit reboot; display/content-protection behavior may need app/display restart | NVIDIA target discovery; registry capture exists; expected `RMHdcpKeyglobZero` data; unsupported/non-NVIDIA target report | Source Default writes `RMHdcpKeyglobZero=0`; Restore requires captured prior state | Is HDCP behavior security-sensitive? Which display-class subkeys are truly NVIDIA-owned? |
| 4 | P0 State | `HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\*` excluding `*Configuration` | `DisableDynamicPstate` | None | None | None | `reg.exe` | None | NVIDIA display-class performance-state registry mutation | Registry command invocation only | None | No explicit reboot; power/thermal behavior may need app/driver/session refresh | NVIDIA target discovery; registry capture exists; expected `DisableDynamicPstate` data; power/thermal warning acknowledged | Source Default writes `DisableDynamicPstate=0`; Restore requires captured prior state | What warnings are required for power, thermals, stability, and battery behavior? Which targets are NVIDIA-owned? |
| 5 | Msi Mode | `HKLM\SYSTEM\ControlSet001\Enum\<InstanceId>\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties` | `MSISupported` | None | None | None | `reg.exe` | None | Display device interrupt-mode registry mutation | `Get-PnpDevice -Class Display`; registry command invocation | None | Source does not reboot, but MSI interrupt changes may require device restart or system reboot | NVIDIA device identity; exact instance path; registry capture exists; expected `MSISupported` data; reboot/device restart requirement decision | Source Off writes `MSISupported=0`; Restore requires captured prior state | How should NVIDIA-only targeting be enforced? Is reboot/device restart required? How are ambiguous display devices handled? |

## Driver Install Latest Planning

Candidate future allowlist needs:

* NVIDIA driver lookup/download/source provenance.
* Exact downloaded artifact path: `%SystemRoot%\Temp\nvidiadriver.exe`.
* Exact checksum, size, version, and signer requirements before execution.
* Installer execution descriptor for the driver installer handoff.
* Driver state capture and rollback references before launch.
* Process handoff policy for the installer process.
* Reboot/session policy because the installer may reboot or require restart even
  though the source script does not call reboot directly.
* Verification that NVIDIA device/driver state changed as expected, or that
  user handoff completed without BoostLab claiming more than it can verify.

Unresolved approval questions:

* Can a dynamic latest-driver URL be pinned enough for Phase 35 artifact
  provenance, or must future phases approve specific driver versions only?
* What installer switches, if any, preserve Ultimate behavior?
* How should failed or cancelled NVIDIA installer handoff be reported?
* What is the rollback/support boundary after the NVIDIA installer takes over?

## Nvidia Settings Planning

Candidate future allowlist needs:

* 7-Zip artifact provenance and installer descriptor if preserving source 7-Zip
  behavior.
* NVIDIA Profile Inspector artifact provenance and execution descriptor.
* Generated `.nip` file ownership, exact content hash, cleanup rule, and profile
  import verification.
* Exact registry scopes for 7-Zip and NVIDIA values.
* File scopes for `%SystemRoot%\Temp\7zip.exe`,
  `%SystemRoot%\Temp\inspector.exe`, `%SystemRoot%\Temp\inspector.nip`,
  `C:\ProgramData\NVIDIA Corporation\Drs`, and the 7-Zip Start Menu paths.
* Process policy for 7-Zip installer, Profile Inspector import, and NVIDIA
  Control Panel launch.
* Driver/profile state capture requirements for NVIDIA Control Panel and DRS
  state.
* Verification of registry values, generated `.nip` content, profile import
  result, and Control Panel launch if preserved.

Unresolved approval questions:

* Should BoostLab preserve source 7-Zip installation exactly, or is that outside
  acceptable future scope?
* Can NVIDIA Profile Inspector and generated `.nip` imports be verified without
  weakening the source behavior?
* What does source Default mean versus captured-state Restore?
* How should the empty Default `.nip` import be represented and verified?

## Hdcp Planning

Candidate future allowlist needs:

* Exact HDCP-related registry scope:
  `HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\*`
  with value `RMHdcpKeyglobZero`.
* Target discovery constrained to verified NVIDIA display-class instances.
* Security/content-protection review because HDCP behavior can affect protected
  media/display behavior.
* Registry capture and rollback references before mutation.
* Verification that only intended NVIDIA targets were changed and that the value
  matches expected data.

Unresolved approval questions:

* Is HDCP handling security-sensitive enough to require additional approval?
* Should non-NVIDIA display instances be skipped, blocked, or surfaced as
  NotApplicable?
* Should Default be exposed as source-defined Default, and how should Restore be
  kept distinct?

## P0 State Planning

Candidate future allowlist needs:

* Exact P0/performance-state registry scope:
  `HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\*`
  with value `DisableDynamicPstate`.
* NVIDIA-only targeting rules for display-class instances.
* Action Plan warning text for power, thermal, stability, fan, battery, and
  performance implications.
* Registry capture and rollback references before mutation.
* Verification that only intended NVIDIA targets were changed and that the value
  matches expected data.

Unresolved approval questions:

* What warning text should Yazan approve for forced/high-performance state?
* Does the setting require driver reload, app restart, or reboot to take effect?
* How should Default be represented without implying captured-state Restore?

## Msi Mode Planning

Candidate future allowlist needs:

* Exact MSI interrupt registry scope:
  `HKLM\SYSTEM\ControlSet001\Enum\<InstanceId>\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties`
  with value `MSISupported`.
* Device instance/path discovery constraints using verified NVIDIA device
  identity, hardware ids, and vendor ids.
* NVIDIA-only targeting rules and explicit AMD/Intel exclusion.
* Registry capture and rollback references before mutation.
* Reboot/device restart policy decision before implementation.
* Verification that only intended NVIDIA display devices were changed and that
  the value matches expected data.

Unresolved approval questions:

* Is reboot required, optional, or explicitly not handled?
* How should hybrid-GPU systems be handled?
* How should devices with missing or protected interrupt registry paths be
  reported?
* Is source Off a Default action, a separate Off action, or neither in BoostLab?

## Candidate Allowlist Table

| Step | Script name | Candidate scope type | Candidate target | Candidate operation | Source evidence | Required foundation | Approval status | Reason not approved now | Future validator requirement |
|---:|---|---|---|---|---|---|---|---|---|
| 1 | Driver Install Latest | DownloadArtifact | NVIDIA driver installer resolved from NVIDIA driver lookup service | Download to `%SystemRoot%\Temp\nvidiadriver.exe` | `Invoke-WebRequest` / `IWR` and NVIDIA driver URL construction | Download Provenance and Installer Execution Policy | NeedsProvenance | Dynamic latest artifact has no exact approved hash, size, version, or signer record | Validate exact URL, expected filename, SHA-256, size, signer, consumer tool id, and approval state |
| 1 | Driver Install Latest | InstallerExecution | `%SystemRoot%\Temp\nvidiadriver.exe` | `Start-Process` driver installer | Source launches downloaded driver executable | Download Provenance and Installer Execution Policy; Process Handling Policy; Driver State Capture and Rollback | NeedsProvenance | Installer cannot run until artifact and execution descriptor are approved | Validate verified artifact, command descriptor, confirmation, timeout, exit/handoff handling, and process started only through approved path |
| 1 | Driver Install Latest | Driver | NVIDIA display adapter current driver state | Capture before installer handoff; verify after handoff where possible | Source driver installer branch | Driver State Capture and Rollback | NeedsDriverRollback | No exact NVIDIA driver scope or rollback/support model exists | Validate device identity, hardware ids, driver package, old/new versions, rollback eligibility, and support boundary |
| 2 | Nvidia Settings | DownloadArtifact | 7-Zip executable from source URL | Download to `%SystemRoot%\Temp\7zip.exe` | Source `IWR ... 7zip.exe` | Download Provenance and Installer Execution Policy | NeedsProvenance | Artifact URL/hash/signer/license are not approved | Validate artifact provenance, signer, file name, size, hash, and consumer tool |
| 2 | Nvidia Settings | InstallerExecution | `%SystemRoot%\Temp\7zip.exe` | Silent install `/S` | Source `Start-Process -Wait ... /S` | Download Provenance and Installer Execution Policy | NeedsProvenance | Installer descriptor and side effects are not approved | Validate command, switches, exit-code rules, confirmation, and post-install verification |
| 2 | Nvidia Settings | DownloadArtifact | NVIDIA Profile Inspector executable from source URL | Download to `%SystemRoot%\Temp\inspector.exe` | Source `IWR ... inspector.exe` | Download Provenance and Installer Execution Policy | NeedsProvenance | Artifact URL/hash/signer/license are not approved | Validate artifact provenance, signer, file name, size, hash, and consumer tool |
| 2 | Nvidia Settings | GeneratedScript | `%SystemRoot%\Temp\inspector.nip` | Generate NVIDIA Profile Inspector import file | Source `Set-Content ... inspector.nip` | Production Allowlist Governance; File/Registry State Capture and Rollback | DraftCandidate | Generated profile content and ownership are not approved | Validate exact content hash, path ownership, cleanup rule, and no unrelated generated files |
| 2 | Nvidia Settings | Registry | NVIDIA and 7-Zip registry values listed in source inventory | Add/delete/set values | Source `reg add` / `reg delete` commands | File/Registry State Capture and Rollback | NeedsRegistryRollback | Exact registry scopes and capture rules are not approved | Validate exact hives, keys, value names, types, data, capture records, and verification |
| 2 | Nvidia Settings | File | NVIDIA DRS path and 7-Zip Start Menu paths | `Unblock-File`, `Move-Item`, `Remove-Item` | Source file operations | File/Registry State Capture and Rollback; Destructive Cleanup Policy | DraftCandidate | File scopes, cleanup ownership, and rollback are not approved | Validate exact paths, item types, ownership, capture/quarantine if needed, and no broad deletion |
| 2 | Nvidia Settings | Process | Profile Inspector import and NVIDIA Control Panel launch | `Start-Process` | Source `Start-Process` commands | Process Handling Policy | NeedsProcessPolicy | Process targets and handoff rules are not approved | Validate exact process target, args, publisher/path requirements, timeout, and result reporting |
| 2 | Nvidia Settings | DriverProfile | NVIDIA DRS/profile state | Profile import and settings changes | Generated `.nip` and Profile Inspector import | Driver State Capture and Rollback; future NVIDIA profile/state capture model | NeedsDriverRollback | No NVIDIA profile state capture model exists | Validate profile inventory, import result, rollback feasibility, and Default/Restore distinction |
| 3 | Hdcp | Registry | Display class NVIDIA registry instances | Set `RMHdcpKeyglobZero` to source-defined values | Source `reg add` for `RMHdcpKeyglobZero` | File/Registry State Capture and Rollback; Driver State Capture and Rollback | NeedsRegistryRollback | Exact NVIDIA target scopes and capture rules are not approved | Validate target identity, value type/data, capture, verification, and skipped non-NVIDIA devices |
| 3 | Hdcp | SecurityReview | HDCP/content-protection behavior | Review risk before mutation | HDCP source wording and value name | Security-Sensitive Change Approval if classified sensitive | NeedsSecurityReview | Security/content-protection impact is unresolved | Validate approved risk text, confirmation, and support boundaries |
| 4 | P0 State | Registry | Display class NVIDIA registry instances | Set `DisableDynamicPstate` to source-defined values | Source `reg add` for `DisableDynamicPstate` | File/Registry State Capture and Rollback; Driver State Capture and Rollback | NeedsRegistryRollback | Exact NVIDIA target scopes and capture rules are not approved | Validate target identity, value type/data, capture, verification, and skipped non-NVIDIA devices |
| 4 | P0 State | Driver | NVIDIA power/performance behavior | Require warning and verification plan | Source "Always Force Max Boost Clock" text | Driver State Capture and Rollback | NeedsDriverRollback | Power/thermal/stability verification and support model are unresolved | Validate Action Plan warning, NVIDIA target, detected value, and rollback feasibility |
| 5 | Msi Mode | Registry | `HKLM\SYSTEM\ControlSet001\Enum\<InstanceId>\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties` | Set `MSISupported` to source-defined values | Source `Get-PnpDevice -Class Display` and `reg add` | File/Registry State Capture and Rollback; Driver State Capture and Rollback | NeedsRegistryRollback | Exact device targeting and capture rules are not approved | Validate NVIDIA instance id, hardware id, registry path, value type/data, capture, and verification |
| 5 | Msi Mode | Driver | NVIDIA display device interrupt mode | NVIDIA-only targeting and device identity validation | Source targets all display devices | Driver State Capture and Rollback | NeedsDriverRollback | AMD/Intel exclusion and hybrid-GPU behavior are unresolved | Validate vendor/device identity, non-NVIDIA NotApplicable behavior, and no broad display writes |
| 5 | Msi Mode | RebootWorkflow | Possible device restart or reboot need | Determine and gate any required restart | Interrupt mode changes may require restart even though source does not reboot | Reboot/Recovery Workflow | NeedsRebootPolicy | Reboot/device restart requirement is unresolved | Validate reboot requirement decision, confirmation, and no restart unless future workflow is approved |

## Workflow-Level Planning Rules

Path B allowlists must be step-scoped and order-aware.

Later steps must not receive broad approval just because previous steps are approved.

Path A and Path B remain mutually guided workflows. Mixing Path A and Path B requires later explicit approval.

NVIDIA-only targeting must be explicit for every GPU, driver, profile, display
device, or device-registry operation.

AMD and Intel GPU-specific behavior remains unsupported.

Every future implementation must define:

* Action Plan requirements
* explicit confirmation requirements
* Activity Log messages
* Latest Result fields
* preflight checks
* post-action verification
* failure policy
* Default status
* Restore status

## Future Validation Requirements

Future phases must add validators for:

* checksum validation for source mirror files
* provenance validation for downloaded artifacts
* signer/hash validation for external executables
* exact registry path/value allowlist validation
* device instance validation for Msi Mode
* NVIDIA vendor targeting validation
* rollback capture validation
* Default/Restore status validation
* reboot/session gating validation
* workflow order gating validation
* Path A/Path B mutual exclusion validation

## Required Future Phase Sequence

Recommended future implementation-prep sequence:

1. **NVIDIA Path B Artifact Provenance Review**
   Review whether the dynamic driver installer, 7-Zip, and NVIDIA Profile
   Inspector artifacts can satisfy exact URL, hash, size, signer, license, and
   redistributability requirements.
2. **NVIDIA Profile State Capture Model**
   Define how NVIDIA DRS/profile state, `.nip` imports, Profile Inspector
   effects, and NVIDIA Control Panel state can be captured and verified.
3. **NVIDIA Path B Draft Allowlist Proposal**
   Draft non-approved candidate entries for exact registry, file, driver,
   process, and generated-artifact scopes. Keep all entries Draft/NotApproved
   until Yazan explicitly approves them.
4. **NVIDIA Path B UI Workflow Design**
   Define the guided Path A/Path B choice, ordered step gating, user warnings,
   non-mixing behavior, and result display.
5. **Individual Per-Step Implementation Attempts Later**
   Attempt implementation one step at a time only after the required artifacts,
   scopes, validators, Action Plan behavior, and verification rules are
   approved.

## Explicit Non-Actions

Phase 75 is planning only.

* No source mirror files were changed.
* No intake files were changed.
* No legacy source-ultimate files were changed.
* No executable module was created.
* No tool or placeholder was enabled.
* No runtime behavior changed.
* No production allowlist, scope, artifact, download, installer, driver,
  profile write, AppX, service, task, process, cleanup, reboot,
  TrustedInstaller, Safe Mode, Default, or Restore approval was added.
* No production config or allowlist config was created for Path B.
* No DDU execution, DDU download, or DDU artifact approval was added.
* Standalone DDU was not introduced.
* Loudness EQ and NVME Faster Driver remain deleted.
* Counts remain unchanged: 48 active tools, 30 implemented tools, 18
  deferred/placeholders, and 7 source-promoted intake candidates separate from
  official counts.

## Recommended Next Phase

Recommended next phase: **NVIDIA Path B Artifact Provenance Review**.

That phase should remain review-only unless Yazan explicitly allows proposed
artifact records. It should determine whether the dynamic NVIDIA driver
installer flow, 7-Zip artifact, and NVIDIA Profile Inspector artifact can ever
meet BoostLab's provenance requirements without weakening the Ultimate source
behavior.

Phase 76 records that review in
`docs/tool-designs/nvidia-path-b-artifact-provenance-review.md`. It approves no
artifacts, downloads, installers, production scopes, or production provenance
config changes.

Phase 77 records the inert NVIDIA profile state capture model in
`docs/nvidia-profile-state-capture-model.md`. It approves no profile capture,
restore, import, export, Profile Inspector execution, `.nip` operation, runtime
behavior, or production scope.

Phase 78 records future Path A / Path B UI workflow design in
`docs/nvidia-path-b-ui-workflow-design.md`. It remains design-only and enables
no Path B behavior.
