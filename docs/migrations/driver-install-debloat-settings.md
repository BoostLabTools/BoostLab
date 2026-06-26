# Driver Install Debloat & Settings Migration Record

## Tool

- Tool name: `Driver Install Debloat & Settings`
- Tool id: `driver-install-debloat-settings`
- Stage: `Graphics`
- Module: `modules/Graphics/driver-install-debloat-settings.psm1`
- Source script path: `source-ultimate/5 Graphics/1 Driver Install Debloat & Settings.ps1`
- Source SHA-256: `00D7EA2C941DF776F729CD35A9386FE18D59D02717DCB3CF43282714E345A6D3`
- Phase: `Phase 99 - Driver Install Debloat & Settings Controlled Manual Handoff Implementation`; `Phase 122 - Driver Install Debloat Settings Branch Scope Decision`; `Phase 123 - Driver Install Debloat Settings Three Branch Exact Runtime Implementation`
- Yazan approval status: Phase 122 approves all source-defined NVIDIA/AMD/INTEL branches for this tool only; Phase 123 implements those branches with BoostLab confirmation, operation planning, logging, and test-safe executor injection.

## Original Ultimate Behavior Summary

The source installs/configures 7-Zip, offers NVIDIA/AMD/Intel GPU branches, opens
vendor driver pages, expects a downloaded driver installer, extracts driver
packages, deletes source-defined driver components, launches vendor installers,
uses winget/AppX behavior, writes driver/profile registry settings, imports
NVIDIA Profile Inspector data, opens display/NVIDIA/sound interfaces, and
restarts the PC.

Phase 122 branch-scope decision: Yazan approved NVIDIA, AMD, and INTEL source
branches for this tool only. This does not expand project-wide AMD/Intel GPU
scope and does not approve unrelated AMD/Intel behavior elsewhere.

## Approved BoostLab Behavior

BoostLab implements this tool as a source-equivalent controlled assistant:

- `Analyze`: verifies source identity and reports source behavior plus exact
  NVIDIA, AMD, and INTEL operation plans without mutation.
- `Open`: opens only the selected branch source-defined vendor driver page flow
  after confirmation.
- `Apply`: requires explicit branch selection and confirmation, then runs the
  selected source-equivalent NVIDIA, AMD, or INTEL workflow through operation
  descriptors.
- `Default`: fails closed with `DefaultUnavailable`.
- `Restore`: fails closed with `RestoreUnavailable`.

## Preserved Commands

Phase 123 preserves the source-defined admin/internet checks, 7-Zip
download/install/config, vendor driver page handoff, installer selection,
7-Zip extraction, branch-specific installer commands, component cleanup,
winget/AppX behavior, NVIDIA Profile Inspector `.nip` import, AMD XML/JSON
edits, AMD/Intel service/task/process cleanup, driver registry/profile writes,
shared monitor color registry writes, NotifyIconSettings writes, MSI mode
writes, display/NVIDIA/sound UI launches, and final restart operation.

## Intentional Deviations

BoostLab adds explicit GUI confirmation, structured operation-plan preview,
structured results, and test-safe executor injection. These mechanics do not
remove the source-defined NVIDIA, AMD, or INTEL branch behavior. Default and
Restore remain unavailable because the source defines no safe overall Default
branch and BoostLab has no selected captured-state Restore contract for the
full driver/profile/package/registry/file/service/task/process/reboot surface.

## Side Effects

Apply can download tools, open vendor pages, run installers, extract driver
packages, delete source-defined driver components/files, mutate packages/AppX
or winget source state, write registry/profile settings, stop processes,
remove services/drivers/tasks, open display/NVIDIA/sound interfaces, and
restart. Validators use mocks and do not perform these host mutations.

## Required Privileges

Administrator rights and internet access are required for the source-equivalent
Apply runtime.

## Capabilities

- RequiresAdmin: true
- RequiresInternet: true
- CanReboot: true
- CanModifyRegistry: true
- CanModifyServices: true
- CanInstallSoftware: true
- CanDownload: true
- CanModifyDrivers: true
- CanModifySecurity: false
- CanDeleteFiles: true
- UsesTrustedInstaller: false
- UsesSafeMode: false
- SupportsDefault: false
- SupportsRestore: false
- NeedsExplicitConfirmation: true

## Risk Level

High. The source-equivalent Apply path is driver, installer, cleanup, profile,
package, registry, service/task/process, UI, and reboot sensitive.

## Confirmation Requirements

`Open` and `Apply` require visible confirmation through the Action Plan runtime.
Apply also requires selecting exactly one branch: NVIDIA, AMD, or INTEL.

## Default And Restore Behavior

Default is unavailable because the source does not define a safe overall default
mutation.

Restore is unavailable because no captured driver/profile/package/registry/file
or reboot state restore contract exists. Default is not Restore.

## Test Requirements

Tests must verify source checksum, canonical actions, separation from NVIDIA
Path B, read-only Analyze, exact NVIDIA/AMD/INTEL operation-plan mapping,
mocked Apply execution for each branch, branch selection, Default/Restore
unavailability, the Phase 122 branch-scope decision, no project-wide AMD/Intel
expansion, no production approvals, protected source immutability, and updated
parity counts.
