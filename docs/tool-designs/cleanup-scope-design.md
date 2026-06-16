# Cleanup Scope Design

## Purpose

This Phase 50 document defines the future implementation scope for the
`Cleanup` tool. It is design-only.

No cleanup behavior is implemented by this document. No runtime behavior,
module behavior, production cleanup allowlist, file scope, registry scope,
quarantine scope, or restore scope is approved here.

Cleanup remains a refused placeholder until a later approved phase adds exact
bounded production scopes and implementation.

## Source Reference

* Source path: `source-ultimate/6 Windows/22 Cleanup.ps1`
* Source SHA-256: `3419A995AD4483A145999B659268302F02BE982733DE831554ADA1C40F07CCAA`
* Current BoostLab module path: `modules/Windows/cleanup.psm1`
* Current status: refused placeholder
* Current implemented actions: none

Relevant foundations:

* Phase 38: destructive cleanup policy
* Phase 36: file and registry state capture and rollback
* Phase 40: reboot/recovery workflow

## Source Behavior Summary

The Ultimate source performs one cleanup path:

1. Recursively deletes all children under the current user's local temp folder.
2. Recursively deletes all children under the Windows temp folder.
3. Recursively deletes `inetpub`.
4. Recursively deletes `PerfLogs`.
5. Recursively deletes `Windows.old`.
6. Deletes `DumpStack.log`.
7. Opens `cleanmgr.exe`.

The source has no explicit Default or Restore behavior.

## Current Decision

Do not implement Analyze, Apply, Default, or Restore yet.

The source cleanup is broad and recursive. It uses wildcard child deletion under
temp directories, deletes root-level system folders, deletes a root-level log
file, and launches Disk Cleanup. Phase 38 requires exact bounded scopes,
limits, state-capture evidence when rollback is claimed, confirmation, and
verification before any cleanup action may execute.

## Behavior Groups

### 1. User Temp Paths

* Exact source path or pattern:
  * `%USERPROFILE%\AppData\Local\Temp\*`
* Target type: directory children under a user temp directory
* Intended cleanup type:
  * Recursive permanent deletion of all child files and directories under the
    current user's local temp directory.
* Required foundation:
  * Phase 38 destructive cleanup policy
  * Phase 36 directory/file state capture if rollback or quarantine is claimed
* Required production cleanup allowlist:
  * Exact current-user temp root
  * Explicit child-target rule, not a wildcard-only scope
  * Recursive cleanup permission
  * Reparse-point denial
* State capture or quarantine requirement:
  * Prefer quarantine for deletions that are not known generated artifacts.
  * If permanent deletion is ever approved, the scope must say why temp
    children are non-restorable and must not claim Restore.
* Required file-count/size limits:
  * Positive maximum file count
  * Positive maximum total byte count
  * Maximum traversal depth
  * Per-item path length and item count reporting
* Required confirmation level:
  * Explicit Action Plan confirmation before Apply
* Required verification:
  * Confirm only children under the exact current-user temp root were targeted.
  * Confirm no reparse points were followed.
  * Confirm skipped locked files are reported as warnings, not hidden.
* Rollback feasibility:
  * Feasible only through quarantine or Phase 36 captured-state restore for
    exact items. Not feasible for permanent deletion without capture.
* Risk level: high
* Later implementation decision:
  * Can be considered later with bounded child cleanup, limits, and quarantine
    or explicit no-restore messaging.

### 2. System Temp Paths

* Exact source path or pattern:
  * `%SystemDrive%\Windows\Temp\*`
* Target type: directory children under Windows temp
* Intended cleanup type:
  * Recursive permanent deletion of all child files and directories under
    Windows temp.
* Required foundation:
  * Phase 38 destructive cleanup policy
  * Phase 36 state capture where rollback/quarantine is claimed
* Required production cleanup allowlist:
  * Exact `%SystemDrive%\Windows\Temp` child scope
  * Explicit recursive cleanup permission
  * Reparse-point denial
  * Locked-file and access-denied handling
* State capture or quarantine requirement:
  * Quarantine should be preferred unless a future scope explicitly approves
    permanent delete for generated temp children.
* Required file-count/size limits:
  * Positive maximum file count
  * Positive maximum total byte count
  * Maximum traversal depth
  * Maximum individual file size if quarantine is used
* Required confirmation level:
  * Explicit Action Plan confirmation before Apply
* Required verification:
  * Confirm every touched item is under the exact Windows temp root.
  * Confirm no Windows root, System32, or sibling folder was targeted.
  * Confirm skipped locked files and access-denied items are reported.
* Rollback feasibility:
  * Feasible only with quarantine or captured-state records. Permanent deletion
    has no safe Restore.
* Risk level: high
* Later implementation decision:
  * Can be considered later with exact bounded limits and generated/temp
    ownership rules.

### 3. Windows.old Behavior

* Exact source path:
  * `%SystemDrive%\Windows.old`
* Target type: directory
* Intended cleanup type:
  * Recursive permanent deletion of the Windows upgrade rollback directory.
* Required foundation:
  * Phase 38 destructive cleanup policy
  * Phase 36 directory capture if Restore is ever claimed
* Required production cleanup allowlist:
  * Exact `%SystemDrive%\Windows.old` directory scope
  * Explicit high-risk recursive deletion scope
  * Separate confirmation text explaining Windows rollback implications
* State capture or quarantine requirement:
  * Quarantine is likely impractical because `Windows.old` can be very large.
  * If permanent deletion is approved later, Restore must remain unavailable
    unless an exact captured/quarantined state exists.
* Required file-count/size limits:
  * Strict preflight inventory and size reporting
  * A dedicated maximum byte threshold, or an explicit policy exception with
    separate Yazan approval
  * Reparse-point denial
* Required confirmation level:
  * High-risk explicit confirmation
* Required verification:
  * Confirm exact path identity is `%SystemDrive%\Windows.old`.
  * Confirm no drive root or Windows root deletion is requested.
  * Confirm deletion result or partial deletion warnings.
* Rollback feasibility:
  * Not generally feasible after permanent deletion. Must not claim Restore.
* Risk level: high
* Later implementation decision:
  * Must remain refused until an exact high-risk policy decision is approved.

### 4. Dump/Log Artifacts

* Exact source path:
  * `%SystemDrive%\DumpStack.log`
* Target type: file
* Intended cleanup type:
  * Permanent deletion of a root-level dump/log file.
* Required foundation:
  * Phase 38 destructive cleanup policy
  * Phase 36 file capture if rollback/quarantine is claimed
* Required production cleanup allowlist:
  * Exact file scope for `%SystemDrive%\DumpStack.log`
  * File-only cleanup type
* State capture or quarantine requirement:
  * Quarantine is preferred for single-file deletion.
  * If permanent delete is approved, it must be documented as non-restorable.
* Required file-count/size limits:
  * File count exactly one
  * Maximum file size
* Required confirmation level:
  * Explicit confirmation as part of the Cleanup Action Plan
* Required verification:
  * Confirm exact file path identity.
  * Confirm no wildcard or sibling root files are targeted.
  * Confirm deletion or quarantine result.
* Rollback feasibility:
  * Feasible if quarantined or captured before deletion.
* Risk level: medium-high
* Later implementation decision:
  * Can be considered later as a narrow single-file target.

### 5. Prefetch/Cache Targets If Present

* Exact source paths or patterns:
  * None present in the Ultimate Cleanup source.
* Target type: not applicable
* Intended cleanup type: not applicable
* Required foundation: not applicable
* Required production cleanup allowlist:
  * No Prefetch or cache scope may be inferred from the Cleanup source.
* State capture or quarantine requirement: not applicable
* Required file-count/size limits: not applicable
* Required confirmation level: not applicable
* Required verification:
  * A future validator should reject any Cleanup implementation that adds
    Prefetch/cache targets not present in the source.
* Rollback feasibility: not applicable
* Risk level: not applicable
* Later implementation decision:
  * Must remain refused unless a future approved source or Yazan instruction
    explicitly adds these targets.

### 6. Browser/Cache Targets If Present

* Exact source paths or patterns:
  * None present in the Ultimate Cleanup source.
* Target type: not applicable
* Intended cleanup type: not applicable
* Required foundation: not applicable
* Required production cleanup allowlist:
  * No browser/cache scope may be inferred from the Cleanup source.
* State capture or quarantine requirement: not applicable
* Required file-count/size limits: not applicable
* Required confirmation level: not applicable
* Required verification:
  * A future validator should reject any browser cache deletion introduced by
    Cleanup unless separately approved.
* Rollback feasibility: not applicable
* Risk level: not applicable
* Later implementation decision:
  * Must remain refused unless a future approved source or Yazan instruction
    explicitly adds browser/cache targets.

### 7. Recycle Bin or cleanmgr Behavior If Present

* Exact source command:
  * `Start-Process cleanmgr.exe`
* Target type: built-in Windows UI launcher
* Intended cleanup type:
  * Open Disk Cleanup UI after source-defined deletion attempts.
* Required foundation:
  * Open-only launcher behavior can be safe by itself, but the source couples it
    with destructive cleanup.
  * Phase 38 is still required for any source-preserving Apply that includes
    deletions before launching Disk Cleanup.
* Required production cleanup allowlist:
  * None for opening `cleanmgr.exe` itself.
  * Exact cleanup scopes are required for the preceding deletions.
* State capture or quarantine requirement:
  * Not required for the UI launcher itself.
* Required file-count/size limits:
  * Not applicable to `cleanmgr.exe` launch.
* Required confirmation level:
  * No confirmation for a future standalone Open action, if Yazan approves a
    split Open action.
  * Explicit confirmation for any Apply that preserves the source deletion plus
    launcher sequence.
* Required verification:
  * For Open-only: verify the launcher request was attempted.
  * For Apply: verify cleanup results before reporting the UI launch.
* Rollback feasibility:
  * Not applicable to launcher.
* Risk level:
  * Low for Open-only.
  * High when included after destructive cleanup.
* Later implementation decision:
  * A standalone Open action could be considered only if it is documented as a
    deliberate UI-only assistant action. It must not be used to imply Cleanup
    Apply has been implemented.

### 8. Broad Recursive Deletion Behavior

* Exact source commands:
  * `Remove-Item -Path "$env:USERPROFILE\AppData\Local\Temp\*" -Recurse -Force`
  * `Remove-Item -Path "$env:SystemDrive\Windows\Temp\*" -Recurse -Force`
  * `Remove-Item "$env:SystemDrive\inetpub" -Recurse -Force`
  * `Remove-Item "$env:SystemDrive\PerfLogs" -Recurse -Force`
  * `Remove-Item "$env:SystemDrive\Windows.old" -Recurse -Force`
* Target type: wildcard child targets and root-level directories
* Intended cleanup type:
  * Recursive permanent deletion.
* Required foundation:
  * Phase 38 destructive cleanup policy
  * Phase 36 state capture where rollback/quarantine is claimed
* Required production cleanup allowlist:
  * Exact per-target scopes
  * No wildcard-only scopes
  * Explicit recursive limits
  * Reparse-point denial
  * Per-target ownership decision
* State capture or quarantine requirement:
  * Mandatory if Restore or rollback is claimed.
  * Quarantine should be preferred for bounded unknown content.
* Required file-count/size limits:
  * Positive per-scope maximum file count
  * Positive per-scope maximum byte count
  * Maximum traversal depth
  * Explicit behavior when limits are exceeded
* Required confirmation level:
  * High-risk explicit confirmation
* Required verification:
  * Dry-run inventory before cleanup.
  * Post-cleanup target existence/status for every scoped target.
  * Warning list for skipped, locked, denied, or out-of-scope items.
* Rollback feasibility:
  * Only feasible with quarantine or captured-state records. Not feasible for
    broad permanent deletion.
* Risk level: high
* Later implementation decision:
  * Must remain refused until exact bounded scopes and per-target ownership
    decisions are approved.

### 9. Windows/System/Root Path Behavior

* Exact source paths:
  * `%SystemDrive%\Windows\Temp\*`
  * `%SystemDrive%\inetpub`
  * `%SystemDrive%\PerfLogs`
  * `%SystemDrive%\Windows.old`
  * `%SystemDrive%\DumpStack.log`
* Target type: Windows temp children, root-level directories, and root-level file
* Intended cleanup type:
  * Permanent delete of child items, directories, and file.
* Required foundation:
  * Phase 38 destructive cleanup policy
  * Phase 36 file/directory capture where rollback/quarantine is claimed
* Required production cleanup allowlist:
  * Separate exact scope per root/system target
  * Drive-root denial must remain active.
  * Windows root denial must remain active except for exact child scope
    `%SystemDrive%\Windows\Temp`.
* State capture or quarantine requirement:
  * Required for any claimed rollback.
  * Per-target decision required for quarantine versus permanent delete.
* Required file-count/size limits:
  * Strict per-target limits and dry-run inventory
* Required confirmation level:
  * High-risk explicit confirmation
* Required verification:
  * Confirm path normalization did not resolve to drive root, Windows root,
    System32, Program Files, ProgramData root, user profile root, or user
    document locations.
* Rollback feasibility:
  * Varies by target; not generally feasible for permanent recursive deletion.
* Risk level: high
* Later implementation decision:
  * Must remain refused until exact root/system target scopes and path-identity
    checks are approved.

### 10. Default/Restore Behavior If Present

* Exact source behavior:
  * No Default option.
  * No Restore option.
* Target type: not applicable
* Intended cleanup type: not applicable
* Required foundation:
  * Phase 36 and Phase 38 would be required before Restore could be claimed.
* Required production cleanup allowlist:
  * None approved.
* State capture or quarantine requirement:
  * Restore would require valid captured or quarantined state for exact targets.
* Required file-count/size limits:
  * Same as the Apply cleanup scope if Restore is ever added.
* Required confirmation level:
  * Explicit confirmation before any restore from quarantine/capture.
* Required verification:
  * Verify restored target identity and hashes/manifests.
* Rollback feasibility:
  * Not available from source. Must not be claimed unless BoostLab captured the
    deleted/quarantined state and can restore it safely.
* Risk level: high if added later
* Later implementation decision:
  * Default and Restore must remain unavailable until exact captured-state or
    quarantine restore selection is implemented and approved.

## Phase 38 Policy Application

The Cleanup tool must obey these Phase 38 rules:

* Broad roots remain refused.
* Wildcard-only targets remain refused.
* User documents remain refused unless explicitly and narrowly scoped later.
* Recursive deletion requires exact bounded allowlists and limits.
* Reparse points, junctions, and symlinks remain refused unless a future policy
  explicitly allows a narrow target.
* Permanent deletion should be avoided where quarantine is practical.
* Cleanup must report skipped, locked, denied, out-of-scope, and limit-exceeded
  items instead of hiding them behind `SilentlyContinue`.

## Future Safe Apply Requirements

A future safe Apply would require all of the following:

1. A tool-specific Action Plan listing every cleanup target and whether it will
   be analyzed, quarantined, permanently deleted, or opened as a Windows UI.
2. Exact production cleanup scopes added to `config/CleanupPolicy.psd1`.
3. Exact file/directory capture scopes added to the Phase 36 policy for every
   target that claims Restore or quarantine restore.
4. Per-target file-count, byte-count, traversal-depth, and reparse-point rules.
5. Dry-run inventory before any cleanup execution.
6. Explicit confirmation after the dry-run inventory is visible.
7. Quarantine where practical, especially for single files or bounded unknown
   directory contents.
8. Permanent delete only when the exact scope explicitly approves it and the UI
   states that Restore is unavailable.
9. Post-cleanup verification for every scoped target.
10. Clean `NotApplicable`, `Warning`, or `Failed` results for missing,
    inaccessible, locked, or out-of-scope targets.
11. No hidden `SilentlyContinue`-style suppression of important cleanup
    failures.

## Default and Restore Boundary

The Ultimate source does not provide Default or Restore behavior.

BoostLab must not expose Default for Cleanup unless Yazan approves a separate
source-equivalent default behavior. BoostLab must not expose Restore unless it
has captured or quarantined exact prior state and the UI/runtime can let the
technician select and verify that state.

Quarantine restore and captured-state Restore are different from source Apply.
They require integrity-protected records, matching current target identity, and
post-restore verification.

## Production Approval State

No production cleanup allowlists or scopes are approved by this document.

Specifically, this document does not approve:

* User temp cleanup
* Windows temp cleanup
* `Windows.old` deletion
* `inetpub` deletion
* `PerfLogs` deletion
* `DumpStack.log` deletion
* Browser/cache cleanup
* Prefetch/cache cleanup
* Recycle Bin cleanup
* Recursive wildcard cleanup
* Quarantine scopes
* Permanent deletion scopes
* Default behavior
* Restore behavior

Cleanup remains refused and disabled as a placeholder until a future phase
explicitly approves exact bounded scopes and implements the tool.
