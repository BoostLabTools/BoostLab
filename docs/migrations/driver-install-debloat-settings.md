# Driver Install Debloat & Settings Migration Record

## Tool

- Tool name: `Driver Install Debloat & Settings`
- Tool id: `driver-install-debloat-settings`
- Stage: `Graphics`
- Module: `modules/Graphics/driver-install-debloat-settings.psm1`
- Source script path: `source-ultimate/5 Graphics/1 Driver Install Debloat & Settings.ps1`
- Source SHA-256: `E69EFF538E7CE6108233C525A2BB88BA2D549CE6954AE751BE7BED778271C26F`
- Phase: `Phase 99 - Driver Install Debloat & Settings Controlled Manual Handoff Implementation`; `Phase 122 - Driver Install Debloat Settings Branch Scope Decision`
- Yazan approval status: controlled manual handoff only at runtime; Phase 122 approves all source-defined NVIDIA/AMD/INTEL branches for this tool's future exact parity implementation

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

BoostLab implements this tool as a controlled assistant only:

- `Analyze`: verifies source identity and reports source behavior, approved
  source branches, blockers, and missing approvals.
- `Open`: prepares manual handoff instructions inside BoostLab only.
- `Apply`: fails closed with `AutoBlockedUntilArtifactApproval`.
- `Default`: fails closed with `DefaultUnavailable`.
- `Restore`: fails closed with `RestoreUnavailable`.

## Preserved Commands

No source commands are executed in this phase. The original source behavior is
preserved as operational intent and blocker documentation only.

## Intentional Deviations

The full source behavior is not executed because the exact source-equivalent
NVIDIA, AMD, and INTEL implementation has not yet been added and required
production approvals/descriptors do not exist for artifacts, downloads,
installer execution, process handling, driver state, profile import,
AppX/package actions, service/task operations, cleanup/debloat scopes,
registry/profile mutation, reboot/session handling, or recovery.

This remains an intentional fail-closed manual handoff implementation until the
three approved source branches are implemented. It must not be treated as a
weakened partial driver installer or as NVIDIA-only final parity.

## Side Effects

No download, installer execution, external process launch, driver mutation,
registry mutation, service mutation, package mutation, file cleanup, profile
import, display/sound launch, reboot, or session change is performed.

## Required Privileges

The current manual handoff implementation does not require Administrator rights.
Future automated behavior would require new approval and accurate privilege
metadata.

## Capabilities

- RequiresAdmin: false
- RequiresInternet: false
- CanReboot: false
- CanModifyRegistry: false
- CanModifyServices: true
- CanInstallSoftware: false
- CanDownload: false
- CanModifyDrivers: false
- CanModifySecurity: false
- CanDeleteFiles: false
- UsesTrustedInstaller: false
- UsesSafeMode: false
- SupportsDefault: false
- SupportsRestore: false
- NeedsExplicitConfirmation: true

## Risk Level

High. The original source behavior is driver, installer, cleanup, profile,
package, registry, and reboot sensitive, even though the current BoostLab
implementation is non-mutating.

## Confirmation Requirements

`Open` and `Apply` require visible confirmation through the Action Plan runtime.
Confirmation records only the manual handoff or blocked Auto result.

## Default And Restore Behavior

Default is unavailable because the source does not define a safe overall default
mutation.

Restore is unavailable because no captured driver/profile/package/registry/file
or reboot state restore contract exists. Default is not Restore.

## Test Requirements

Tests must verify source checksum, canonical actions, separation from NVIDIA
Path B, read-only Analyze, manual handoff-only Open, fail-closed Apply, blocked
Default/Restore, the Phase 122 NVIDIA/AMD/INTEL branch-scope decision, no
project-wide AMD/Intel expansion, no production approvals, no executable
command patterns, and updated inventory counts.
