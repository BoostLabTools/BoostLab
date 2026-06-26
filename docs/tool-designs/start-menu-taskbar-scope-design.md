# Start Menu Taskbar Scope Design

## Purpose

This Phase 49 document defines the future implementation scope for the
`Start Menu Taskbar` tool. It is design-only.

No tool behavior is implemented by this document. No runtime behavior changes,
module behavior changes, production allowlists, file scopes, registry scopes,
cleanup scopes, Explorer process scopes, or rollback scopes are approved here.

`Start Menu Taskbar` remains a refused placeholder until a later approved phase
adds exact production scopes and implementation.

## Source Reference

* Source path: `source-ultimate/6 Windows/1 Start Menu Taskbar.ps1`
* Source SHA-256: `D53678CE91FE8ADE6D28F221A2E4153188597D850149F87227B26E0B821EFFF4`
* Current BoostLab module path: `modules/Windows/start-menu-taskbar.psm1`
* Current status: refused placeholder
* Current implemented actions: none

Relevant foundations:

* Phase 36: file and registry state capture and rollback
* Phase 38: destructive cleanup policy
* Phase 40: reboot/recovery workflow

## Product Scope Decision

Phase 48 clarified that BoostLab product scope is branch-level scope.

Shared Windows behavior may be preserved later if it is otherwise safe and has
approved exact scopes. Windows 10-only branches/options must remain unsupported,
disabled, visual-only, or `NotApplicable`. Windows 11-specific behavior may be
designed for future implementation.

The Ultimate source includes behavior labeled or structured as Windows 10 start
layout import behavior and separate Windows 11 `start2.bin` behavior. A future
BoostLab implementation must not expose Windows 10-only start-layout branches
as active optimization behavior.

## Current Decision

Do not implement Apply, Default, or Restore yet.

The source mutates user-visible shell state, policy state, Start layout files,
Quick Launch state, NotifyIconSettings, folder attributes, and Explorer process
state. It also contains broad Default behavior that deletes policy keys and
user layout state. This requires exact allowlists and captured-state decisions
before it can be safely implemented without weakening Ultimate behavior or
damaging unrelated user state.

## Behavior Groups

### 1. Start Layout Files

* Exact source paths:
  * `%SystemDrive%\Windows\StartMenuLayout.xml`
  * `C:\Windows\StartMenuLayout.xml`
* Target type: file
* Intended mutation type:
  * Apply deletes an existing layout XML, writes a minimal layout XML, assigns
    it through policy registry values, then deletes the XML again.
  * Default deletes an existing layout XML, writes the default-style layout XML,
    assigns it through policy registry values, then deletes the XML again.
* Required foundation:
  * Phase 36 file state capture and rollback
  * Phase 38 destructive cleanup policy for delete operations
* Required production allowlist:
  * Exact file scope for `C:\Windows\StartMenuLayout.xml`
  * Exact generated-file ownership rule for BoostLab-created layout XML
* Required state capture:
  * Pre-delete file existence, attributes, hash, timestamps, and owner metadata
  * Post-write hash and deletion verification
* Required verification:
  * Layout XML content hash before policy assignment
  * Confirm only the exact scoped file was created and removed
  * Confirm no other Windows directory files were touched
* Rollback feasibility:
  * Possible only if the original file was captured and current state still
    matches the BoostLab post-mutation record.
* Risk level: high
* Later implementation decision:
  * Windows 10-only layout import behavior must remain unsupported.
  * Any Windows 11-supported use of this path requires explicit design review
    because the source labels this block as Windows 10 import behavior.

### 2. start2.bin Behavior

* Exact source paths:
  * `%USERPROFILE%\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\start2.bin`
  * `%SystemRoot%\Temp\start2.txt`
  * `%SystemRoot%\Temp\start2.bin`
* Target type: file
* Intended mutation type:
  * Apply deletes the existing user `start2.bin`, writes encoded source content
    to `%SystemRoot%\Temp\start2.txt`, decodes it with `certutil.exe` to
    `%SystemRoot%\Temp\start2.bin`, copies the decoded file into the
    StartMenuExperienceHost `LocalState` directory, and sets
    `AllAppsViewMode=2`.
  * Default deletes the user `start2.bin` and sets `AllAppsViewMode=0`.
* Required foundation:
  * Phase 36 file and registry state capture and rollback
  * Phase 38 destructive cleanup policy for user layout deletion and temp files
* Required production allowlist:
  * Exact user `start2.bin` path under the current user's
    `Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState`
    package directory
  * Exact generated temp paths `%SystemRoot%\Temp\start2.txt` and
    `%SystemRoot%\Temp\start2.bin`
  * Exact registry value scope for `AllAppsViewMode`
* Required state capture:
  * Existing `start2.bin` hash and metadata before deletion/overwrite
  * Generated temp-file ownership and hash records
  * Registry value previous existence, type, and data for `AllAppsViewMode`
* Required verification:
  * Confirm decoded `start2.bin` matches the source-approved payload hash
  * Confirm copied file hash matches the decoded payload
  * Confirm `AllAppsViewMode` equals the source-defined expected value
  * Confirm generated temp files are removed only if owned by BoostLab
* Rollback feasibility:
  * Restore is feasible only from a valid captured `start2.bin` backup and
    registry record. Default is not equivalent to Restore.
* Risk level: high
* Later implementation decision:
  * Can be considered for a future Windows 11-specific Apply only after exact
    payload hash, file scopes, temp ownership, and Explorer handling are
    approved.

### 3. Taskband Registry Behavior

* Exact source path:
  * `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband`
  * `HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Taskband\AuxilliaryPins`
* Target type: registry key and registry value
* Intended mutation type:
  * Apply deletes the entire `Taskband` key using `reg delete`.
  * Default sets `MailPin=1` under `AuxilliaryPins`.
* Required foundation:
  * Phase 36 registry state capture and rollback
  * Phase 38 destructive cleanup policy for broad key deletion
* Required production allowlist:
  * Exact key scope for `Taskband`, including whether broad key capture and
    delete are allowed.
  * Exact value scope for `AuxilliaryPins\MailPin`.
* Required state capture:
  * Complete Taskband key snapshot before any deletion if key deletion is ever
    approved.
  * Previous existence, type, and data for `MailPin`.
* Required verification:
  * Confirm the key deletion affected only the approved Taskband key.
  * Confirm `MailPin` has expected `REG_DWORD 1` if Default is ever implemented.
* Rollback feasibility:
  * Broad Taskband restore is risky and requires key-level capture, identity
    checks, and a user-selected captured-state restore flow.
* Risk level: high
* Later implementation decision:
  * Must remain refused until exact key-level rollback and user-visible restore
    semantics are approved.

### 4. Quick Launch Directory Behavior

* Exact source path:
  * `%USERPROFILE%\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch`
* Target type: directory
* Intended mutation type:
  * Apply recursively deletes the Quick Launch directory.
  * Default does not recreate it directly.
* Required foundation:
  * Phase 36 directory state capture
  * Phase 38 destructive cleanup policy
* Required production allowlist:
  * Exact current-user Quick Launch directory scope
  * Recursive directory cleanup limits, maximum file count, and maximum byte
    count
* Required state capture:
  * Directory manifest, file hashes, attributes, timestamps, and reparse-point
    checks before deletion.
* Required verification:
  * Confirm target path resolves inside the exact current user's profile.
  * Confirm no reparse points are followed.
  * Confirm deletion touches only captured entries.
* Rollback feasibility:
  * Possible only as Restore from a captured directory backup. Default cannot
    safely reconstruct unknown user Quick Launch contents.
* Risk level: high
* Later implementation decision:
  * Must remain refused until exact recursive cleanup ownership and restore
    policy are approved.

### 5. Layout XML Behavior

* Exact registry paths:
  * `HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer`
  * `HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer`
* Exact values:
  * `LockedStartLayout`
  * `StartLayoutFile`
* Target type: registry values and generated layout XML file
* Intended mutation type:
  * Apply and Default set `LockedStartLayout=1`, set
    `StartLayoutFile=C:\Windows\StartMenuLayout.xml`, restart Explorer, sleep,
    then set `LockedStartLayout=0` and delete the layout XML.
* Required foundation:
  * Phase 36 registry and file state capture
  * Phase 38 cleanup policy for generated XML deletion
* Required production allowlist:
  * Exact HKLM/HKCU Explorer policy values
  * Exact generated layout XML file path
* Required state capture:
  * Prior value existence, type, and data for both values in both hives
  * Prior layout XML file state
* Required verification:
  * Confirm temporary policy assignment and final policy state.
  * Confirm layout XML removal touches only the approved generated file.
* Rollback feasibility:
  * Feasible only with captured previous registry and file state. Default is not
    Restore.
* Risk level: high
* Later implementation decision:
  * Windows 10-only layout XML branch must remain unsupported unless Yazan
    explicitly expands scope.

### 6. Policy Registry Behavior

* Exact source paths and values:
  * `HKLM\Software\Policies\Microsoft\Dsh\AllowNewsAndInterests`
  * `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarAl`
  * `HKCU\Software\Microsoft\Windows\CurrentVersion\Search\SearchboxTaskbarMode`
  * `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ShowTaskViewButton`
  * `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarMn`
  * `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ShowCopilotButton`
  * `HKLM\Software\Policies\Microsoft\Windows\Windows Feeds\EnableFeeds`
  * `HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\HideSCAMeetNow`
  * `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run\SecurityHealth`
  * `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\EnableAutoTray`
  * `HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Start\HideRecommendedSection`
  * `HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Education\IsEducationEnvironment`
  * `HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer\HideRecommendedSection`
  * `HKLM\SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\14\2792562829\EnabledState`
  * `HKLM\SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\14\3036241548\EnabledState`
  * `HKLM\SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\14\734731404\EnabledState`
  * `HKLM\SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\14\762256525\EnabledState`
  * `HKCU\Software\Microsoft\Windows\CurrentVersion\Start\AllAppsViewMode`
* Target type: registry values and, in source Default, registry keys
* Intended mutation type:
  * Apply sets source-defined DWORD and binary values.
  * Default deletes several values and entire policy keys, and sets
    `SecurityHealth` and `AllAppsViewMode`.
* Required foundation:
  * Phase 36 registry state capture and rollback
  * Phase 38 destructive cleanup policy for key deletions
* Required production allowlist:
  * Exact value-level scopes for every supported value
  * Separate explicit key-level scopes if any full key deletion is ever
    approved
* Required state capture:
  * Previous existence, type, and data for every changed value
  * Key inventory before any key deletion
* Required verification:
  * Verify every source-defined value equals expected Apply value.
  * Verify any Default deletion removes only approved values/keys.
  * Verify unsupported Windows 10-only values such as `EnableAutoTray` remain
    disabled or visual-only if treated as Windows 10-only.
* Rollback feasibility:
  * Value-level Restore is feasible from captured records.
  * Key-level Default deletion remains refused until exact key ownership and
    captured-state restore are approved.
* Risk level: high
* Later implementation decision:
  * A future Apply may be split into value-level scopes first. Broad Default key
    deletion must remain unavailable until explicitly approved.

### 7. NotifyIconSettings Behavior

* Exact source path:
  * `HKCU\Control Panel\NotifyIconSettings`
* Target type: recursively discovered registry subkeys and `IsPromoted` values
* Intended mutation type:
  * Apply enumerates all subkeys and sets `IsPromoted=1` where the current value
    is not `0`.
  * Default enumerates all subkeys and sets `IsPromoted=0` where the current
    value is not `0`.
* Required foundation:
  * Phase 36 registry state capture and rollback
* Required production allowlist:
  * Exact recursive scope under `HKCU\Control Panel\NotifyIconSettings`
  * Explicit dynamic-discovery rule for discovered subkeys
  * Explicit value-only allowlist for `IsPromoted`
* Required state capture:
  * Previous value existence, type, and data for each discovered `IsPromoted`.
  * Discovery manifest for every subkey touched.
* Required verification:
  * Confirm all changed discovered values equal the expected source value.
  * Confirm no values other than `IsPromoted` were changed.
  * Confirm no keys outside the NotifyIconSettings root were touched.
* Rollback feasibility:
  * Possible from captured per-value records only. Default is not equivalent to
    Restore because it forces `IsPromoted=0` rather than returning the previous
    state.
* Risk level: medium-high
* Later implementation decision:
  * Can be considered only after dynamic registry discovery scope rules are
    approved for this tool.

### 8. Hidden-Folder Attribute Behavior

* Exact source paths:
  * `%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Accessibility`
  * `%ProgramData%\Microsoft\Windows\Start Menu\Programs\Accessibility`
  * `%ProgramData%\Microsoft\Windows\Start Menu\Programs\Accessories`
* Target type: directories and recursive directory contents
* Intended mutation type:
  * Apply runs `attrib +h` on each directory and recursively on each directory's
    contents.
  * Default runs `attrib -h` on the same directories and contents.
* Required foundation:
  * Phase 36 file/directory state capture
* Required production allowlist:
  * Exact directory scopes
  * Recursive attribute-only mutation rule
  * Reparse-point denial rule
* Required state capture:
  * Directory and child-item attributes before mutation
  * Manifest of every item whose hidden attribute is changed
* Required verification:
  * Confirm hidden attribute changed only for scoped paths.
  * Confirm no file content changed.
* Rollback feasibility:
  * Restore is feasible only from captured attribute state. Default can only
    remove hidden attributes and may not match prior user state.
* Risk level: medium-high
* Later implementation decision:
  * Can be considered after exact recursive attribute scopes and restore rules
    are approved.

### 9. Explorer Process Handling

* Exact source process action:
  * `Stop-Process -Force -Name explorer -ErrorAction SilentlyContinue`
* Target type: process
* Intended mutation type:
  * Apply and Default force-stop Explorer after layout/policy changes.
* Required foundation:
  * Phase 40 reboot/recovery workflow is relevant because Explorer restart is a
    session-disruptive continuation point, though it is not a machine reboot.
  * A future Explorer process-handling policy must be explicit before use.
* Required production allowlist:
  * Exact process target: `explorer`
  * Exact allowed operation: controlled restart or force-stop fallback
  * Explicit user confirmation text
* Required state capture:
  * Pre-action Explorer process presence
  * Whether shell restart is expected
  * Associated mutation operation id
* Required verification:
  * Confirm Explorer returns or provide clear recovery guidance.
  * Confirm the shell state reflects the intended settings after restart.
* Rollback feasibility:
  * Process state itself is not restorable; the underlying file/registry state
    must be restorable.
* Risk level: high
* Later implementation decision:
  * No force-stop without explicit confirmation.
  * Prefer a controlled restart plan if approved.
  * If force-stop is preserved for Ultimate strength, it must be visibly
    disclosed, logged, and verified.

### 10. Default Behavior

* Exact source behavior:
  * Imports `taskbardefault.reg`.
  * Deletes policy keys such as `HKLM\Software\Policies\Microsoft\Dsh`,
    `HKLM\Software\Policies\Microsoft\Windows\Windows Feeds`, and
    `HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer`.
  * Removes multiple taskbar and Start values.
  * Sets `SecurityHealth`, `MailPin`, and `AllAppsViewMode`.
  * Sets NotifyIconSettings `IsPromoted=0`.
  * Unhides scoped Start Menu folders recursively.
  * Runs Windows 10 layout XML behavior.
  * Removes Windows 11 `start2.bin`.
  * Force-stops Explorer.
* Target type: registry keys, registry values, files, directories, attributes,
  and process
* Intended mutation type: broad default/reset behavior
* Required foundation:
  * Phase 36 file and registry capture
  * Phase 38 cleanup policy
  * Phase 40 Explorer handling design
* Required production allowlist:
  * Exact per-value scopes for safe default values
  * Explicit key-deletion scopes before any full key delete
  * Exact file/directory scopes and generated-file ownership rules
* Required state capture:
  * Every file, directory, registry value, and registry key before mutation
* Required verification:
  * Verify each approved default mutation.
  * Verify no unapproved values, keys, files, directories, or processes were
    touched.
* Rollback feasibility:
  * Current Default/Restore must remain unavailable unless exact captured-state
    restore selection is implemented. Source Default is not a safe inverse for
    all user states because it deletes keys and forces values rather than
    restoring captured prior state.
* Risk level: high
* Later implementation decision:
  * Do not expose Default until the exact Default scope is approved.
  * Do not expose Restore until BoostLab has captured state and a user-visible
    restore selection flow exists.

### 11. Unsupported Windows 10-Only Branches

* Exact source areas:
  * Commented source marker: `show all taskbar icons w10 only`
  * `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\EnableAutoTray`
  * Commented source marker: `windows 10 import start menu`
  * `C:\Windows\StartMenuLayout.xml`
  * HKLM/HKCU Explorer policy values `LockedStartLayout` and
    `StartLayoutFile`
* Target type: registry values and layout XML file
* Intended mutation type:
  * Windows 10 taskbar icon and Start layout behavior.
* Required foundation:
  * Not sufficient by itself; product-scope approval is also required.
* Required production allowlist:
  * None approved in this phase.
* Required state capture:
  * Not applicable while unsupported.
* Required verification:
  * A future validator must prove Windows 10-only branches remain disabled,
    visual-only, or `NotApplicable`.
* Rollback feasibility:
  * Not applicable while unsupported.
* Risk level: high
* Later implementation decision:
  * Must remain unsupported unless Yazan explicitly expands product scope.

## Future Safe Apply Requirements

A future safe Apply would require all of the following before implementation:

1. A tool-specific Action Plan listing every registry value, file, directory,
   generated temp file, and Explorer process action.
2. Explicit user confirmation before any shell-disruptive or destructive step.
3. Exact production file scopes and registry scopes added to the Phase 36
   policy.
4. Exact cleanup scopes added to the Phase 38 policy for generated files and
   any deletion.
5. Exact dynamic discovery rules for NotifyIconSettings if that behavior is
   preserved.
6. Exact generated-file ownership rules for `%SystemRoot%\Temp` artifacts.
7. Exact source payload hash approval for the decoded Windows 11 `start2.bin`.
8. Pre-mutation state capture before any file, directory, registry, or
   attribute mutation.
9. Verification after every mutation group.
10. Clear product-scope gating so Windows 10-only branches remain disabled.
11. Explicit Explorer handling confirmation, logging, and post-action recovery
    guidance.

## Default and Restore Boundary

Default must remain unavailable until its exact source behavior is approved
value by value and key by key.

Restore must remain unavailable until BoostLab has captured a previous state
for the exact affected files, directories, registry values, registry keys, and
attributes, and until the UI/runtime can let the technician select and verify
that captured state.

Do not treat the source Default option as Restore. The source Default writes
new values, deletes keys, deletes `start2.bin`, changes folder attributes, and
force-stops Explorer. It does not reconstruct arbitrary previous user state.

## Explorer Handling Requirements

Any future Explorer handling must satisfy these requirements:

* No `Stop-Process -Force -Name explorer` without explicit confirmation.
* The Action Plan must show the exact process name, reason, expected impact,
  and recovery guidance.
* The runtime must log when Explorer restart is requested, attempted, and
  verified.
* If a controlled Explorer restart path is approved, it must be preferred unless
  preserving Ultimate behavior explicitly requires force-stop.
* If force-stop is approved, the UI must clearly state that Explorer may close
  and restart.
* Verification must confirm either Explorer returned or the technician received
  clear recovery instructions.

## Production Approval State

No production allowlists or scopes are approved by this document.

Specifically, this document does not approve:

* File scopes
* Directory scopes
* Registry value scopes
* Registry key deletion scopes
* Cleanup scopes
* Generated temp-file scopes
* NotifyIconSettings dynamic discovery scopes
* Explorer process scopes
* Windows 10-only branches
* Default behavior
* Restore behavior

Start Menu Taskbar remains refused and disabled as a placeholder until a future
phase explicitly approves the required scopes and implements the tool.
