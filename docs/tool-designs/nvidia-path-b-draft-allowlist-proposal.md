# NVIDIA Path B Draft Allowlist Proposal

## Purpose And Status

Phase 79 creates a draft allowlist proposal for the NVIDIA App Path B workflow.

This is a draft allowlist proposal only. No production allowlist is approved. No
production scope is approved. No artifact, download, installer, driver/profile
write, registry write, file mutation, process, reboot, Default, or Restore
operation is approved. No implementation, placeholder, tool card, or runtime
behavior change was added.

Every proposed entry in this document is `DraftOnly`, `NotApproved`, or another
non-production `Needs...` / `Rejected...` status. No proposed entry is approved.

Phase 79 status statements:

* No production allowlist is approved.
* No production scope is approved.
* No artifact, download, installer, driver/profile write, registry write, file mutation, process, reboot, Default, or Restore operation is approved.
* No implementation, placeholder, tool card, or runtime behavior change was added.
* Every proposed entry is DraftOnly / NotApproved / NeedsApproval or another non-production status.

NVIDIA App Path B exact required order:

`Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`

Path relationship:

* Path A: `Driver Install Debloat & Settings`
* Path B: `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`

Path B is for users who want to keep or use NVIDIA App features such as
recording or related NVIDIA App features. Future UI must preserve guided
separation between Path A and Path B and prevent accidental mixing unless later
explicitly approved.

## Draft Proposal Rules

Draft rules:

* Draft entries must be step-scoped.
* Draft entries must preserve the exact Path B order.
* Draft entries must not be broad.
* Draft entries must not use wildcards unless explicitly marked invalid or
  rejected.
* Draft entries must include source evidence.
* Draft entries must include required foundation references.
* Draft entries must include why they are not approved now.
* Draft entries must include what future validator would need to prove.
* Draft entries must not be copied into production config without a later
  approval phase.
* Draft entries must not be treated as execution permission.
* Draft entries must not be used to create visible tool cards or runtime
  workflow config.

Allowed draft approval status values:

* `DraftOnly`
* `NotApproved`
* `NeedsApproval`
* `NeedsProvenance`
* `NeedsInstallerDescriptor`
* `NeedsDriverRollback`
* `NeedsProfileStateModel`
* `NeedsRegistryRollback`
* `NeedsProcessPolicy`
* `NeedsRebootPolicy`
* `NeedsSecurityReview`
* `NeedsNvidiaOnlyTargeting`
* `RejectedBroadScope`
* `RejectedMutableSource`
* `RejectedUnknownTarget`

Do not use `Approved` in this proposal.

## Consolidated Draft Allowlist Table

| Draft id | Path B step number | Script name | Scope type | Candidate target | Candidate operation | Source evidence | Required foundation | Required future approval | Approval status | Reason not approved now | Future validation requirement | Implementation dependency |
|---|---:|---|---|---|---|---|---|---|---|---|---|---|
| NPB-DRAFT-001 | 1 | Driver Install Latest | DownloadArtifact | NVIDIA driver lookup API and resulting driver URL | Query API and resolve driver installer metadata | `$uri = 'https://gfwsl.geforce.com/...AjaxDriverService.php?...'`; `$url = "https://international.download.nvidia.com/Windows/$version/..."` | Download Provenance and Installer Execution Policy | Approved official source, pinned or approved dynamic provenance model | NeedsProvenance | Dynamic latest-driver source has no pinned version/hash/signer model | Verify source authority, response schema, resulting URL, version, file name, hash, signer, and size bounds | Artifact provenance approval |
| NPB-DRAFT-002 | 1 | Driver Install Latest | File | `%SystemRoot%\Temp\nvidiadriver.exe` | Download driver installer to bounded path | `IWR $url -OutFile "$env:SystemRoot\Temp\nvidiadriver.exe"` | Download Provenance and File/Registry State Capture and Rollback | Approved destination bounds and artifact identity | NeedsProvenance | Temp destination is source-defined but not yet bounded in production policy | Verify path bounds, ownership, file hash, size, and cleanup/retention rule | Artifact and file-scope proposal |
| NPB-DRAFT-003 | 1 | Driver Install Latest | InstallerExecution | `%SystemRoot%\Temp\nvidiadriver.exe` | Launch NVIDIA driver installer | `Start-Process "$env:SystemRoot\Temp\nvidiadriver.exe"` | Installer Execution Policy, Driver State Capture and Rollback, Reboot/Recovery Workflow | Exact execution descriptor and driver rollback design | NeedsInstallerDescriptor | No switches, exit model, timeout, reboot, or rollback approval exists | Verify descriptor, signer, command line, exit/handoff behavior, rollback plan, and reboot disclosure | Driver workflow design |
| NPB-DRAFT-004 | 1 | Driver Install Latest | Driver | NVIDIA display driver state | Capture pre-install and verify post-install state | Source installs NVIDIA driver installer | Driver State Capture and Rollback | Driver state capture/rollback production scope | NeedsDriverRollback | Driver mutation cannot be approved without capture/rollback model | Verify current driver identity, package, device, pre/post state, and rollback feasibility | Driver rollback scope |
| NPB-DRAFT-005 | 1 | Driver Install Latest | Process | Installer process handoff | Start and observe installer process | `Start-Process "$env:SystemRoot\Temp\nvidiadriver.exe"` | Process Handling Policy | Exact process handoff policy | NeedsProcessPolicy | Process launch/handoff is not approved | Verify process identity, expected child behavior, timeout, logging, and user handoff | Process policy scope |
| NPB-DRAFT-006 | 1 | Driver Install Latest | RebootWorkflow | NVIDIA driver install session | Disclose possible reboot/session impact | Driver installers can require reboot or session recovery | Reboot/Recovery Workflow | Reboot/session policy for driver install | NeedsRebootPolicy | Reboot/session behavior is not modeled for this step | Verify reboot possibility, resume behavior, pending reboot detection, and recovery messaging | Reboot workflow design |
| NPB-DRAFT-007 | 1 | Driver Install Latest | Verification | Driver installer artifact and install state | Verify downloaded file and resulting driver state | `$version = $payload.IDS[0].downloadInfo.Version` | Download Provenance, Driver State Capture and Rollback | Exact verification checks | NeedsApproval | Verification checks are not yet approved | Verify artifact hash/signer and detected NVIDIA driver version/device state | Verification validator |
| NPB-DRAFT-008 | 2 | Nvidia Settings | DownloadArtifact | 7-Zip installer from GitHub raw branch URL | Download 7-Zip installer | `IWR ".../7zip.exe" -OutFile "$env:SystemRoot\Temp\7zip.exe"` | Download Provenance and Installer Execution Policy | Immutable official/trusted source, hash, signer, license | RejectedMutableSource | Mutable `refs/heads/main` URL cannot satisfy provenance | Verify immutable URL/source, SHA-256, signer, size, license, and redistributability | Artifact provenance approval |
| NPB-DRAFT-009 | 2 | Nvidia Settings | InstallerExecution | `%SystemRoot%\Temp\7zip.exe` | Install 7-Zip with `/S` | `Start-Process -Wait "$env:SystemRoot\Temp\7zip.exe" -ArgumentList "/S"` | Installer Execution Policy | Exact installer descriptor and exit-code policy | NeedsInstallerDescriptor | 7-Zip installer execution is not approved | Verify signer/hash, command line, exit codes, timeout, install state, and cleanup | Installer policy scope |
| NPB-DRAFT-010 | 2 | Nvidia Settings | Registry | `HKCU\Software\7-Zip\Options` values `ContextMenu` and `CascadedMenu` | Configure 7-Zip shell menu behavior | `reg add "HKEY_CURRENT_USER\Software\7-Zip\Options" /v "ContextMenu" ...`; `CascadedMenu` | File/Registry State Capture and Rollback | Exact HKCU registry allowlist and capture | NeedsRegistryRollback | Registry writes are source-defined but not production-approved | Verify exact key/value/type/data, capture before mutation, post-state, and restore feasibility | Registry allowlist proposal |
| NPB-DRAFT-011 | 2 | Nvidia Settings | File | `%ProgramData%\Microsoft\Windows\Start Menu\Programs\7-Zip\7-Zip File Manager.lnk` and `%ProgramData%\...\7-Zip` | Move shortcut and remove 7-Zip folder | `Move-Item ...7-Zip File Manager.lnk`; `Remove-Item ...\7-Zip -Recurse` | File/Registry State Capture and Rollback, Destructive Cleanup Policy | Exact file/dir scope, capture/quarantine policy | NeedsApproval | File move/delete behavior is not approved | Verify exact path bounds, ownership, backup/quarantine, and no broad deletion | File/cleanup allowlist proposal |
| NPB-DRAFT-012 | 2 | Nvidia Settings | File | `C:\ProgramData\NVIDIA Corporation\Drs` | Unblock DRS files | `Get-ChildItem -Path $path -Recurse \| Unblock-File` | File/Registry State Capture and Rollback | Exact file scope and recursive bounds | NeedsApproval | Recursive file operation needs bounded allowlist | Verify path exists, no reparse traversal, file count/size limits, and pre/post state | File scope proposal |
| NPB-DRAFT-013 | 2 | Nvidia Settings | Registry | `HKLM\System\ControlSet001\Services\nvlddmkm\Parameters\Global\NVTweak` values `NvCplPhysxAuto`, `NvDevToolsVisible`, `RmProfilingAdminOnly` | Write or delete NVIDIA NVTweak values | `reg add/delete ...\NVTweak` | File/Registry State Capture and Rollback, Driver State Capture and Rollback | Exact NVIDIA registry allowlist and capture | NeedsRegistryRollback | Driver registry values are not production-approved | Verify exact values, data, capture, NVIDIA driver identity, and restore/default behavior | Registry/driver allowlist proposal |
| NPB-DRAFT-014 | 2 | Nvidia Settings | Registry | Display class key `{4d36e968-e325-11ce-bfc1-08002be10318}` value `RmProfilingAdminOnly` | Set/delete GPU performance counter access value | `Get-ChildItem ...Control\Class\{4d36e968...}` then `reg add/delete "$key" /v "RmProfilingAdminOnly"` | File/Registry State Capture and Rollback, Driver State Capture and Rollback | NVIDIA-only target discovery and exact value allowlist | NeedsNvidiaOnlyTargeting | Dynamic display-class enumeration is too broad without NVIDIA identity validation | Verify NVIDIA display instance, non-Configuration filter, capture, exact value, and post-state | NVIDIA target validator |
| NPB-DRAFT-015 | 2 | Nvidia Settings | Registry | `HKCU\Software\NVIDIA Corporation\NvTray` value/key | Set/delete tray icon startup behavior | `reg add ...\NvTray /v "StartOnLogin"`; `reg delete ...\NvTray` | File/Registry State Capture and Rollback | Exact HKCU NVIDIA registry allowlist | NeedsRegistryRollback | Key-level delete needs exact scope and restore design | Verify key/value capture, whether key existed, and no unrelated value loss | Registry rollback proposal |
| NPB-DRAFT-016 | 2 | Nvidia Settings | Registry | `HKLM\SYSTEM\...\Services\nvlddmkm\FTS` and `...\Parameters\FTS` value `EnableGR535` | Set legacy sharpen value on/default | `reg add ...\FTS /v "EnableGR535"` | File/Registry State Capture and Rollback, Driver State Capture and Rollback | Exact NVIDIA driver registry allowlist | NeedsRegistryRollback | Multiple control-set paths need exact approval and verification | Verify all exact paths, types/data, capture, and post-state | Registry/driver allowlist proposal |
| NPB-DRAFT-017 | 2 | Nvidia Settings | DownloadArtifact | NVIDIA Profile Inspector executable | Download Inspector from GitHub raw branch URL | `IWR ".../inspector.exe" -OutFile "$env:SystemRoot\Temp\inspector.exe"` | Download Provenance and Installer Execution Policy | Immutable trusted source, SHA-256, signer/publisher, size, license | RejectedMutableSource | Mutable third-party branch URL is not acceptable provenance | Verify immutable source, hash, signer if available, size, license, and execution permission | Artifact provenance approval |
| NPB-DRAFT-018 | 2 | Nvidia Settings | GeneratedArtifact | `%SystemRoot%\Temp\inspector.nip` | Generate source-defined `.nip` profile file | `Set-Content -Path "$env:SystemRoot\Temp\inspector.nip" -Value $nipfile -Force` | NVIDIA Profile State Capture Model, File/Registry State Capture and Rollback | Generated artifact ownership and bounded path policy | NeedsProfileStateModel | Generated profile artifact is not approved | Verify exact generated content hash, path bounds, ownership metadata, profile scope, and cleanup/quarantine | Profile/generated artifact policy |
| NPB-DRAFT-019 | 2 | Nvidia Settings | ProfileImport | `%SystemRoot%\Temp\inspector.nip` via Inspector | Import `.nip` profile silently | `Start-Process -wait "$env:SystemRoot\Temp\inspector.exe" -ArgumentList "-silentImport -silent ..."` | NVIDIA Profile State Capture Model, Process Handling Policy | Profile pre-capture, Inspector execution descriptor, import verification | NeedsProfileStateModel | Profile import without pre-capture/verification is denied | Verify pre-capture, Inspector provenance, import result, profile setting deltas, and restore eligibility | Profile state model |
| NPB-DRAFT-020 | 2 | Nvidia Settings | Process | NVIDIA Control Panel app URI | Launch NVIDIA Control Panel | `Start-Process "shell:appsFolder\NVIDIACorp.NVIDIAControlPanel_..."` | Process Handling Policy | Local app launch/handoff policy | NeedsProcessPolicy | App launch behavior is not approved | Verify package identity, missing-app behavior, launch handoff, and log/result fields | Process policy scope |
| NPB-DRAFT-021 | 2 | Nvidia Settings | Verification | NVIDIA profile, registry, file, and UI handoff state | Verify source-defined settings and imported profile | Source writes registry and imports `.nip` | NVIDIA Profile State Capture Model, Verification Contract | Exact checks for registry/profile/import state | NeedsApproval | Verification model is not approved | Verify every source-defined registry value, profile setting, generated file hash, and import result | Verification validator |
| NPB-DRAFT-022 | 3 | Hdcp | Registry | Display class key `{4d36e968-e325-11ce-bfc1-08002be10318}` value `RMHdcpKeyglobZero` | Set HDCP value to source-defined data | `reg add "$key" /v "RMHdcpKeyglobZero" /t REG_DWORD /d "1"` and `/d "0"` | File/Registry State Capture and Rollback, Driver State Capture and Rollback | Exact NVIDIA registry allowlist and capture | NeedsRegistryRollback | Dynamic display-class target is not production-approved | Verify exact key/value/type/data, capture, NVIDIA display identity, and post-state | Registry/driver allowlist proposal |
| NPB-DRAFT-023 | 3 | Hdcp | SecurityReview | HDCP/content protection behavior | Warn and classify content-protection impact | `Write-Host "NVIDIA High Bandwidth Digital Content Protection"` | Production Allowlist Governance | Content-protection/security review | NeedsSecurityReview | HDCP change may affect protected playback/display behavior | Verify warning text, risk level, confirmation, and user-visible effects | Security-sensitive review |
| NPB-DRAFT-024 | 3 | Hdcp | Verification | `RMHdcpKeyglobZero` detected value | Read back source-defined registry value | `Get-ItemProperty -Path "Registry::$key" -Name 'RMHdcpKeyglobZero'` | Verification Contract | Exact verification checks | NeedsApproval | Readback checks need structured validator | Verify every targeted NVIDIA display instance reports expected value | Verification validator |
| NPB-DRAFT-025 | 4 | P0 State | Registry | Display class key `{4d36e968-e325-11ce-bfc1-08002be10318}` value `DisableDynamicPstate` | Set P0 state value to source-defined data | `reg add "$key" /v "DisableDynamicPstate" /t REG_DWORD /d "1"` and `/d "0"` | File/Registry State Capture and Rollback, Driver State Capture and Rollback | Exact NVIDIA registry allowlist and capture | NeedsRegistryRollback | Dynamic display-class target is not production-approved | Verify exact key/value/type/data, capture, NVIDIA display identity, and post-state | Registry/driver allowlist proposal |
| NPB-DRAFT-026 | 4 | P0 State | Driver | NVIDIA performance/power behavior | Warn about P0/performance-state implications | `Write-Host "Always Force Max Boost Clock"` | Driver State Capture and Rollback | Driver/power risk review | NeedsDriverRollback | Power/thermal/stability effects need explicit design | Verify warning, confirmation, targeted driver, and rollback state | Driver risk design |
| NPB-DRAFT-027 | 4 | P0 State | Verification | `DisableDynamicPstate` detected value | Read back source-defined registry value | `Get-ItemProperty -Path "Registry::$key" -Name 'DisableDynamicPstate'` | Verification Contract | Exact verification checks | NeedsApproval | Readback checks need structured validator | Verify every targeted NVIDIA display instance reports expected value | Verification validator |
| NPB-DRAFT-028 | 5 | Msi Mode | Registry | `HKLM\SYSTEM\ControlSet001\Enum\<InstanceId>\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties\MSISupported` | Set MSI interrupt value to source-defined data | `Get-PnpDevice -Class Display`; `reg add "HKLM\SYSTEM\ControlSet001\Enum\$instanceID\...\MSISupported"` | File/Registry State Capture and Rollback, Driver State Capture and Rollback | Exact NVIDIA device targeting and registry allowlist | NeedsNvidiaOnlyTargeting | Source enumerates all display devices; BoostLab product scope requires NVIDIA-only targeting | Verify NVIDIA hardware ID/vendor, exact instance, capture, and post-state | NVIDIA device validator |
| NPB-DRAFT-029 | 5 | Msi Mode | RebootWorkflow | Display device interrupt mode state | Disclose reboot/device restart implications | MSI mode registry changes affect device behavior | Reboot/Recovery Workflow | Reboot/device restart policy | NeedsRebootPolicy | Reboot/device restart effect is not modeled | Verify disclosure, pending restart detection, and recovery guidance | Reboot workflow design |
| NPB-DRAFT-030 | 5 | Msi Mode | Verification | `MSISupported` detected value | Read back source-defined registry value | `Get-ItemProperty -Path $regPath -Name "MSISupported"` | Verification Contract | Exact verification checks | NeedsApproval | Readback checks need structured validator | Verify every approved NVIDIA display instance reports expected value | Verification validator |

## Driver Install Latest Draft Proposal

Draft entries proposed for future review:

* NVIDIA driver source/provenance mechanism:
  `NPB-DRAFT-001`, status `NeedsProvenance`.
* Downloaded driver artifact path and metadata:
  `NPB-DRAFT-002`, status `NeedsProvenance`.
* Installer execution descriptor:
  `NPB-DRAFT-003`, status `NeedsInstallerDescriptor`.
* Driver state capture/rollback dependency:
  `NPB-DRAFT-004`, status `NeedsDriverRollback`.
* Process handoff dependency:
  `NPB-DRAFT-005`, status `NeedsProcessPolicy`.
* Reboot/session dependency:
  `NPB-DRAFT-006`, status `NeedsRebootPolicy`.
* Verification checks:
  `NPB-DRAFT-007`, status `NeedsApproval`.

The AMD and Intel branches in the source are outside this NVIDIA-only Path B
proposal. They remain unsupported and unapproved for Path B.

## Nvidia Settings Draft Proposal

Draft entries proposed for future review:

* 7-Zip/archive handling:
  `NPB-DRAFT-008`, `NPB-DRAFT-009`, `NPB-DRAFT-010`, `NPB-DRAFT-011`.
* NVIDIA Profile Inspector artifact and execution descriptor:
  `NPB-DRAFT-017`, `NPB-DRAFT-019`.
* Generated `.nip` ownership and bounded path:
  `NPB-DRAFT-018`.
* Profile import operation:
  `NPB-DRAFT-019`.
* NVIDIA registry/file settings:
  `NPB-DRAFT-012` through `NPB-DRAFT-016`.
* NVIDIA Control Panel launch:
  `NPB-DRAFT-020`.
* Profile state capture dependency:
  `NPB-DRAFT-018`, `NPB-DRAFT-019`, `NPB-DRAFT-021`.
* Verification checks:
  `NPB-DRAFT-021`.

All Nvidia Settings entries remain non-approved because artifact provenance,
Profile Inspector execution, `.nip` import, registry/file capture, process
handoff, and profile state capture are not production-approved.

## Hdcp Draft Proposal

Draft entries proposed for future review:

* Exact `RMHdcpKeyglobZero` registry value scope:
  `NPB-DRAFT-022`.
* NVIDIA-only target constraint:
  required by `NPB-DRAFT-022`.
* Registry capture/rollback dependency:
  required by `NPB-DRAFT-022`.
* Content-protection/security review dependency:
  `NPB-DRAFT-023`.
* Verification checks:
  `NPB-DRAFT-024`.

All Hdcp entries remain non-approved because the dynamic display-class registry
targeting, rollback capture, and content-protection risk review are not yet
approved.

## P0 State Draft Proposal

Draft entries proposed for future review:

* Exact `DisableDynamicPstate` registry value scope:
  `NPB-DRAFT-025`.
* NVIDIA-only target constraint:
  required by `NPB-DRAFT-025`.
* Registry capture/rollback dependency:
  required by `NPB-DRAFT-025`.
* Power/thermal/stability warning dependency:
  `NPB-DRAFT-026`.
* Verification checks:
  `NPB-DRAFT-027`.

All P0 State entries remain non-approved because the dynamic display-class
registry targeting, rollback capture, and power/thermal/stability warning model
are not yet approved.

## Msi Mode Draft Proposal

Draft entries proposed for future review:

* Exact `MSISupported` interrupt registry value scope:
  `NPB-DRAFT-028`.
* Display device instance discovery constraint:
  required by `NPB-DRAFT-028`.
* NVIDIA-only device targeting constraint:
  required by `NPB-DRAFT-028`.
* Registry capture/rollback dependency:
  required by `NPB-DRAFT-028`.
* Reboot/device restart disclosure dependency:
  `NPB-DRAFT-029`.
* Verification checks:
  `NPB-DRAFT-030`.

All Msi Mode entries remain non-approved because source enumeration targets all
display devices, while BoostLab Path B requires NVIDIA-only device targeting and
reboot/device-restart disclosure before any future implementation.

## Rejected Draft Examples

These examples must remain rejected:

* Wildcard registry paths.
* All display devices without NVIDIA identity validation.
* Mutable branch URLs.
* Versionless external executable downloads.
* Executing tools from untracked temp paths.
* Broad process termination.
* Broad installer execution.
* Profile import without pre-capture.
* Registry write without rollback capture.
* Path A/Path B mixed execution without explicit design approval.
* Any AMD or Intel GPU-specific Path B branch.
* Any standalone DDU tool, download, execution, or artifact approval.

## Future Promotion Path

A draft entry could later become production-approved only in a separate future
approval phase after:

* Source evidence confirmed.
* Exact target approved under Production Allowlist Governance.
* Artifact provenance approved if applicable.
* Installer descriptor approved if applicable.
* Profile state capture/restore approved if applicable.
* Registry/driver rollback approved if applicable.
* Process/reboot policy approved if applicable.
* UI Action Plan and confirmation text approved.
* Verification validator added.
* Production config updated in a separate phase only.
* Yazan explicitly approves the exact production entry.

Draft entries in this document must not be copied into production config by
default.

## Relationship To Existing Documents

This proposal relates to:

* NVIDIA Path B Catalog Design
* NVIDIA Path B Scope Design
* NVIDIA Path B Production Allowlist Planning
* NVIDIA Path B Artifact Provenance Review
* NVIDIA Profile State Capture Model
* NVIDIA Path B UI Workflow Design
* Production Allowlist Governance
* Download Provenance and Installer Execution Policy
* Driver State Capture and Rollback
* File/Registry State Capture and Rollback
* Process Handling Policy
* Reboot/Recovery Workflow
* Restore Selection UI / Runtime

This document is not a production allowlist. It is a candidate map for later
review.

## Explicit Non-Actions

Phase 79 is draft proposal only.

* No production allowlist config was created or changed.
* No production scope was approved.
* No artifact, download, installer, driver, profile write, profile import,
  profile export, registry, file, AppX, service, task, process, cleanup, reboot,
  TrustedInstaller, Safe Mode, Default, or Restore approval was added.
* No source mirror files changed.
* No intake files changed.
* No legacy source-ultimate files changed.
* No executable module created.
* No tool or placeholder enabled.
* No runtime behavior changed.
* No DDU execution, DDU download, or DDU artifact approval was added.
* Standalone DDU was not introduced.
* Loudness EQ and NVME Faster Driver remain deleted.
* Counts remain unchanged: 48 active tools, 30 implemented tools, 18
  deferred/placeholders, and 7 source-promoted intake candidates separate from
  official counts.

## Recommended Next Phase

Recommended next phase: **NVIDIA Path B Production Approval Gate Design**.

That phase should remain governance/design-only unless Yazan explicitly
authorizes a narrow approval path. It should define how one draft entry could be
promoted to production approval, including required review evidence, owner
approval, validator coverage, and rollback gates.

Phase 80 records that gate design in
`docs/tool-designs/nvidia-path-b-production-approval-gate-design.md`. It grants
no production approval and creates no production allowlist config.

Phase 81 records runtime gating design in
`docs/tool-designs/nvidia-path-b-runtime-gating-design.md`. It creates no
runtime gate implementation, production config, production approval, UI
implementation, tool card, placeholder enablement, or Path B execution
behavior.

Phase 87 records documentation index/navigation design in
`docs/tool-designs/nvidia-path-b-documentation-index-navigation-design.md`. It
indexes this draft proposal as non-approved documentation only.
