# Power Plan Migration Record

* **Tool name:** Power Plan
* **Stage:** Windows
* **Source script path:** `source-ultimate/6 Windows/21 Power Plan.ps1`
* **Source checksum:** `BC0CA2C442CE74CA07ECDA0FE6F52DDD50C86D9E5F1A9DD420943AA08D9D1285`
* **Risk level:** Medium
* **Required privileges:** Administrator
* **Yazan approval status:** Approved by Yazan for Phase 24

## Original Ultimate Behavior

Apply duplicates Ultimate Performance scheme `e9a42b02-d5df-448d-aa00-03f14749eb61` to `99999999-9999-9999-9999-999999999999`, activates it, enumerates every power scheme, and attempts to delete every enumerated scheme. The active BoostLab scheme cannot normally be deleted, so the effective result is that the custom BoostLab scheme remains active while other enumerated schemes are removed.

Ultimate then disables hibernation, changes ten source-defined registry values, applies 36 AC/DC power-setting pairs, and opens `powercfg.cpl`.

Default runs `powercfg -restoredefaultschemes`, enables hibernation, applies the source Default registry operations, restores four hidden-setting `Attributes` values to `1`, and opens `powercfg.cpl`.

Default restores Windows built-in schemes. It does not restore custom power schemes deleted by Apply.

## Preserved BoostLab Behavior

BoostLab preserves the source GUIDs, `powercfg` commands, registry paths, value names, value types, values, setting GUIDs, AC/DC indexes, broad key deletions, and execution order.

BoostLab does not run the Ultimate script. Console elevation and menu behavior are replaced by the application Administrator model, Action Plan confirmation, structured command reporting, read-only verification, and Latest Result rendering.

The source attempt to delete the active `99999999-9999-9999-9999-999999999999` plan is still issued. Its expected active-plan deletion failure is reported as a warning instead of being silently suppressed.

## Compatibility Note

Some source-defined vendor-specific graphics and battery saver power settings do not exist on every Windows build, GPU driver, desktop, or laptop. Ultimate still attempts these commands and suppresses their command errors.

BoostLab preserves every source-defined command attempt. When `powercfg` specifically reports that the power scheme, subgroup, or setting does not exist, or otherwise identifies that source-defined power setting as unavailable or unsupported, BoostLab records a structured Warning instead of failing the whole action. Unreadable AC/DC indexes are also reported as verification warnings. Unexpected command failures remain errors.

## Apply Idempotency

If the source-defined target scheme GUID `99999999-9999-9999-9999-999999999999` already exists, `powercfg /duplicatescheme` reports that the specified GUID already exists. BoostLab treats only that exact target-GUID collision as a Warning and reuses the detected existing target scheme.

Activation remains mandatory, every source-defined registry operation and power-setting command is still attempted, and final verification must confirm the expected active GUID and setting states. If the target scheme is not detected after duplicate/reuse handling, activation fails, or verification contradicts the expected state, Apply still fails. This preserves Ultimate behavior while making repeated Apply runs idempotent.

## Source-to-BoostLab Mapping Audit

`Invoke-BoostLabPowerPlanAction` performs execution. `Test-BoostLabPowerPlanState` performs read-only verification. Every hard-coded command or write below originates in the approved Ultimate source.

### Scheme and Hibernation Commands

| Ultimate source | Command or target | Apply | Default | BoostLab implementation | Verification | Mapping |
|---|---|---|---|---|---|---|
| Lines 21-22 | Ultimate Performance GUID | `/duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 99999999-9999-9999-9999-999999999999` | `restoredefaultschemes` removes custom schemes | `Invoke-BoostLabPowerPlanAction` | Active plan and custom-plan absence checks | Exact |
| Lines 24-25 | BoostLab plan GUID | `/setactive 99999999-9999-9999-9999-999999999999` | Balanced `381b4222-f694-41f0-9685-ff5bb260df2e` expected after reset | Same | `Active power plan GUID` | Preserved |
| Lines 27-44 | Every enumerated scheme | `/list`, then `/delete <guid>` in enumeration order | Windows schemes recreated by reset | Same | Per-GUID absence checks | Exact; expected active-plan deletion failure is surfaced as Warning |
| Lines 46-47 and 242-243 | Hibernation | `/hibernate off` | `/hibernate on` | Same | Hibernate registry state | Exact |
| Lines 229-230 and 268-269 | Power Options | Open `powercfg.cpl` | Open `powercfg.cpl` | `UiLauncher` | Structured launch status | Exact |

### Registry Operations

| Ultimate source | Registry path / value | Apply | Default | BoostLab implementation | Verification check | Mapping |
|---|---|---|---|---|---|---|
| 48, 244 | `HKLM\SYSTEM\CurrentControlSet\Control\Power\HibernateEnabled` | DWORD `0` | Delete value | Apply/Default registry operation arrays | `Registry \| ...\HibernateEnabled` | Exact |
| 49, 245 | `HKLM\SYSTEM\CurrentControlSet\Control\Power\HibernateEnabledDefault` | DWORD `0` | DWORD `1` | Same | `Registry \| ...\HibernateEnabledDefault` | Exact |
| 52, 248 | `HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings\ShowLockOption` | DWORD `0` | Delete complete `FlyoutMenuSettings` key | Same | `Registry \| ...\ShowLockOption` | Exact |
| 55, 248 | `HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings\ShowSleepOption` | DWORD `0` | Deleted with complete key | Same | `Registry \| ...\ShowSleepOption` | Exact |
| 58, 251 | `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power\HiberbootEnabled` | DWORD `0` | DWORD `1` | Same | `Registry \| ...\HiberbootEnabled` | Exact |
| 61, 254 | `HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling\PowerThrottlingOff` | DWORD `1` | Delete complete `PowerThrottling` key | Same | `Registry \| ...\PowerThrottlingOff` | Exact |
| 95, 257 | USB hub timeout `Attributes` | DWORD `0` | DWORD `1` | Setting `AttributePath` | `Registry \| ...0853a681...\Attributes` | Exact |
| 106, 260 | USB 3 link power management `Attributes` | DWORD `0` | DWORD `1` | Setting `AttributePath` | `Registry \| ...d4e98f31...\Attributes` | Exact |
| 134, 263 | Core parking minimum `Attributes` | DWORD `0` | DWORD `1` | Setting `AttributePath` | `Registry \| ...0cc5b647...\Attributes` | Exact |
| 142, 266 | Core parking maximum `Attributes` | DWORD `0` | DWORD `1` | Setting `AttributePath` | `Registry \| ...ea062031...\Attributes` | Exact |

### Power Setting Commands

Every row maps to one source `/setacvalueindex` command followed immediately by its `/setdcvalueindex` command. Default uses the source `-restoredefaultschemes`; it does not invent inverse indexes.

| Source lines | Setting | Subgroup GUID | Setting GUID | Apply AC / DC | Default | Verification |
|---|---|---|---|---|---|---|
| 65-66 | Turn off hard disk after | `0012ee47-9041-4b5d-9b77-535fba8b1442` | `6738e2c4-e8a5-4a42-b16a-e040e769756e` | `0x00000000` / `0x00000000` | Restore defaults | `Power setting \| Turn off hard disk after` |
| 69-70 | Desktop slideshow | `0d7dbae2-4294-402a-ba8e-26777e8488cd` | `309dce9b-bef4-4119-9921-a851fb12f0f4` | `001` / `001` | Restore defaults | `Power setting \| Desktop slideshow` |
| 73-74 | Wireless adapter power saving | `19cbb8fa-5279-450e-9fac-8a3d5fedd0c1` | `12bbebe6-58d6-4636-95bb-3217ef867c1a` | `000` / `000` | Restore defaults | `Power setting \| Wireless adapter power saving` |
| 78-79 | Sleep after | `238c9fa8-0aad-41ed-83f4-97be242c8f20` | `29f6c1db-86da-48c5-9fdb-f2b67b1f44da` | `0x00000000` / `0x00000000` | Restore defaults | `Power setting \| Sleep after` |
| 82-83 | Allow hybrid sleep | `238c9fa8-0aad-41ed-83f4-97be242c8f20` | `94ac6d29-73ce-41a6-809f-6363ba21b47e` | `000` / `000` | Restore defaults | `Power setting \| Allow hybrid sleep` |
| 86-87 | Hibernate after | `238c9fa8-0aad-41ed-83f4-97be242c8f20` | `9d7815a6-7ee4-497e-8888-515a05f02364` | `0x00000000` / `0x00000000` | Restore defaults | `Power setting \| Hibernate after` |
| 90-91 | Allow wake timers | `238c9fa8-0aad-41ed-83f4-97be242c8f20` | `bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d` | `000` / `000` | Restore defaults | `Power setting \| Allow wake timers` |
| 98-99 | USB hub selective suspend timeout | `2a737441-1930-4402-8d77-b2bebba308a3` | `0853a681-27c8-4100-a2fd-82013e970683` | `0x00000000` / `0x00000000` | Restore defaults | `Power setting \| USB hub selective suspend timeout` |
| 102-103 | USB selective suspend | `2a737441-1930-4402-8d77-b2bebba308a3` | `48e6b7a6-50f5-4782-a5d4-53bb8f07e226` | `000` / `000` | Restore defaults | `Power setting \| USB selective suspend` |
| 109-110 | USB 3 link power management | `2a737441-1930-4402-8d77-b2bebba308a3` | `d4e98f31-5ffe-4ce1-be31-1b38b384c009` | `000` / `000` | Restore defaults | `Power setting \| USB 3 link power management` |
| 113-114 | Start menu power button | `4f971e89-eebd-4455-a8de-9e59040e7347` | `a7066653-8d6c-40a8-910e-a1f54b84c7e5` | `002` / `002` | Restore defaults | `Power setting \| Start menu power button` |
| 117-118 | PCI Express link state | `501a4d13-42af-4429-9fd1-a8218c268e20` | `ee12f906-d277-404b-b6da-e5fa1a576df5` | `000` / `000` | Restore defaults | `Power setting \| PCI Express link state power management` |
| 122-123 | Minimum processor state | `54533251-82be-4824-96c1-47b60b740d00` | `893dee8e-2bef-41e0-89c6-b55d0929964c` | `0x00000064` / `0x00000064` | Restore defaults | `Power setting \| Minimum processor state` |
| 126-127 | System cooling policy | `54533251-82be-4824-96c1-47b60b740d00` | `94d3a615-a899-4ac5-ae2b-e4d8f634367f` | `001` / `001` | Restore defaults | `Power setting \| System cooling policy` |
| 130-131 | Maximum processor state | `54533251-82be-4824-96c1-47b60b740d00` | `bc5038f7-23e0-4960-96da-33abaf5935ec` | `0x00000064` / `0x00000064` | Restore defaults | `Power setting \| Maximum processor state` |
| 138-139 | Core parking minimum | `54533251-82be-4824-96c1-47b60b740d00` | `0cc5b647-c1df-4637-891a-dec35c318583` | `0x00000064` / `0x00000064` | Restore defaults | `Power setting \| Processor core parking minimum cores` |
| 146-147 | Core parking maximum | `54533251-82be-4824-96c1-47b60b740d00` | `ea062031-0e34-4ff1-9b6d-eb1059334028` | `0x00000064` / `0x00000064` | Restore defaults | `Power setting \| Processor core parking maximum cores` |
| 151-152 | Display timeout | `7516b95f-f776-4464-8c53-06167f40cc99` | `3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e` | `600` / `600` | Restore defaults | `Power setting \| Turn off display after` |
| 155-156 | Display brightness | `7516b95f-f776-4464-8c53-06167f40cc99` | `aded5e82-b909-4619-9949-f5d71dac0bcb` | `0x00000064` / `0x00000064` | Restore defaults | `Power setting \| Display brightness` |
| 159-160 | Dimmed display brightness | `7516b95f-f776-4464-8c53-06167f40cc99` | `f1fbfde2-a960-4165-9f88-50667911ce96` | `0x00000064` / `0x00000064` | Restore defaults | `Power setting \| Dimmed display brightness` |
| 163-164 | Adaptive brightness | `7516b95f-f776-4464-8c53-06167f40cc99` | `fbd9aa66-9553-4097-ba44-ed6e9d65eab8` | `000` / `000` | Restore defaults | `Power setting \| Adaptive brightness` |
| 167-168 | Video playback quality bias | `9596fb26-9850-41fd-ac3e-f7c3c00afd4b` | `10778347-1370-4ee0-8bbd-33bdacaade49` | `001` / `001` | Restore defaults | `Power setting \| Video playback quality bias` |
| 171-172 | When playing video | `9596fb26-9850-41fd-ac3e-f7c3c00afd4b` | `34c7b99f-9a6d-4b3c-8dc7-b6693b78cef4` | `000` / `000` | Restore defaults | `Power setting \| When playing video` |
| 176-177 | Intel graphics power plan | `44f3beca-a7c0-460e-9df2-bb8b99e0cba6` | `3619c3f2-afb2-4afc-b0e9-e7fef372de36` | `002` / `002` | Restore defaults | `Power setting \| Intel graphics power plan` |
| 180-181 | AMD power slider overlay | `c763b4ec-0e50-4b6b-9bed-2b92a6ee884e` | `7ec1751b-60ed-4588-afb5-9819d3d77d90` | `003` / `003` | Restore defaults | `Power setting \| AMD power slider overlay` |
| 184-185 | ATI PowerPlay | `f693fb01-e858-4f00-b20f-f30e12ac06d6` | `191f65b5-d45c-4a4f-8aae-1ab8bfd980e6` | `001` / `001` | Restore defaults | `Power setting \| ATI PowerPlay` |
| 188-189 | Switchable dynamic graphics | `e276e160-7cb0-43c6-b20b-73f5dce39954` | `a1662ab2-9d34-4e53-ba8b-2639b9e20857` | `003` / `003` | Restore defaults | `Power setting \| Switchable dynamic graphics` |
| 193-194 | Critical battery notification | `e73a048d-bf27-4f12-9731-8b2076e8891f` | `5dbb7c9f-38e9-40d2-9749-4f8a0e9f640f` | `000` / `000` | Restore defaults | `Power setting \| Critical battery notification` |
| 197-198 | Critical battery action | `e73a048d-bf27-4f12-9731-8b2076e8891f` | `637ea02f-bbcb-4015-8e2c-a1c7b9c0b546` | `000` / `000` | Restore defaults | `Power setting \| Critical battery action` |
| 201-202 | Low battery level | `e73a048d-bf27-4f12-9731-8b2076e8891f` | `8183ba9a-e910-48da-8769-14ae6dc1170a` | `0x00000000` / `0x00000000` | Restore defaults | `Power setting \| Low battery level` |
| 205-206 | Critical battery level | `e73a048d-bf27-4f12-9731-8b2076e8891f` | `9a66d8d7-4ff7-4ef9-b5a2-5a326ca2a469` | `0x00000000` / `0x00000000` | Restore defaults | `Power setting \| Critical battery level` |
| 209-210 | Low battery notification | `e73a048d-bf27-4f12-9731-8b2076e8891f` | `bcded951-187b-4d05-bccc-f7e51960c258` | `000` / `000` | Restore defaults | `Power setting \| Low battery notification` |
| 213-214 | Low battery action | `e73a048d-bf27-4f12-9731-8b2076e8891f` | `d8742dcb-3e6a-4b3c-b3fe-374623cdcf06` | `000` / `000` | Restore defaults | `Power setting \| Low battery action` |
| 217-218 | Reserve battery level | `e73a048d-bf27-4f12-9731-8b2076e8891f` | `f3c5027d-cd16-4930-aa6b-90db844a8f00` | `0x00000000` / `0x00000000` | Restore defaults | `Power setting \| Reserve battery level` |
| 222-223 | Battery saver screen brightness | `de830923-a562-41af-a086-e3a2c6bad2da` | `13d09884-f74e-474a-a852-b6bde8ad03a8` | `0x00000064` / `0x00000064` | Restore defaults | `Power setting \| Battery saver screen brightness` |
| 226-227 | Battery saver threshold | `de830923-a562-41af-a086-e3a2c6bad2da` | `e69653ca-cf7f-4f05-aa73-cb833fa90ad4` | `0x00000000` / `0x00000000` | Restore defaults | `Power setting \| Battery saver threshold` |

## Mapping Proof

The module contains exactly 36 source-derived setting definitions, producing exactly 72 ordered `/setacvalueindex` and `/setdcvalueindex` commands. It contains ten Apply registry writes, five explicit Default registry operations, and four Default `Attributes = 1` writes.

No registry path, value name, GUID, AC/DC index, scheme operation, hibernation operation, or UI launch exists outside the Ultimate source.

## Intentional Deviations

* Ultimate suppresses every command error. BoostLab records each command failure, classifies unavailable source-defined settings as structured warnings, and preserves unexpected failures as errors.
* A duplicate-target-GUID response for the approved `99999999-9999-9999-9999-999999999999` scheme is treated as an idempotent reuse warning. Activation, source-defined writes, and verification remain required.
* Ultimate attempts to delete the active BoostLab scheme and suppresses the expected failure. BoostLab preserves the attempt but reports that failure as a warning.
* Power setting verification parses hexadecimal indexes without depending on localized output labels. Unsupported or unavailable settings become Warning checks.
* Console elevation, `Read-Host`, `Clear-Host`, and `Exit` are replaced by BoostLab runtime elevation, confirmation, logging, and result objects.

No operational power behavior is weakened or supplemented.

## Capabilities

`RequiresAdmin = true`; `CanModifyRegistry = true`; `SupportsDefault = true`; `NeedsExplicitConfirmation = true`.

Internet, reboot, services, installers, downloads, drivers, security changes, file deletion, TrustedInstaller, Safe Mode, and Restore are false.

Power scheme deletion is not represented as file deletion. The confirmation explicitly warns that custom schemes are permanently removed and not captured.

## Confirmation and Default Behavior

Apply confirmation names scheme deletion, hibernation changes, all 36 AC/DC setting pairs, the ten registry values, and the battery warning/action impact.

Default means the approved Ultimate Default: `powercfg -restoredefaultschemes` plus the source registry operations. It is not a captured-state Restore and cannot recover custom schemes removed by Apply.

The complete `FlyoutMenuSettings` and `PowerThrottling` key deletions are preserved and disclosed. No restart occurs.

## Verification Strategy

Apply verifies:

* `99999999-9999-9999-9999-999999999999` is active.
* Enumerated non-active schemes targeted for deletion are absent.
* All 36 setting GUID pairs expose the expected AC and DC indexes.
* All ten registry states match the source Apply branch.

Default verifies:

* Balanced `381b4222-f694-41f0-9685-ff5bb260df2e` is active.
* The custom BoostLab plan is absent.
* All ten registry states match the source Default branch.

Unsupported settings, localized/unreadable output, and inaccessible registry values become Warning checks. Contradictory readable values become Failed checks.

## Test Requirements

Automated tests must use static inspection and injected mocks only. They must not change the active plan, run real mutating `powercfg` commands, modify the registry, or launch Power Options.

Tests must validate the source checksum, exact GUIDs, all 36 setting definitions, 72 setting commands, registry mappings, execution order, explicit Default, unsupported-setting warnings, contradictory-value failures, structured results, Action Plan warnings, runtime mapping, UI rendering, source integrity, deleted-tool exclusion, protected-module hashes, and implemented/placeholder counts.
