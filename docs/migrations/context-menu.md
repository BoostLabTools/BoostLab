# Context Menu Migration Record

* **Tool name:** Context Menu
* **Stage:** Windows
* **Source script path:** `source-ultimate/6 Windows/3 Context Menu.ps1`
* **Source checksum:** `33DA36782CF6416A2FAE98829ADF0913B0E54DC53DE454AB0C5210A79754B6F2`
* **Risk level:** Medium
* **Required privileges:** Administrator
* **Yazan approval status:** Approved by Yazan for Phase 21, including the narrow Default deviation

## Original Ultimate Behavior

The source provides `Context Menu: Clean (Recommended)` and `Context Menu: Default`.

Apply enables the classic context menu, sets `NoCustomizeThisFolder = 1`, hides selected shell handlers, adds three values under the shared `Shell Extensions\Blocked` key, sets `NoPreviousVersionsPage = 1`, and removes two Send To handlers. The three blocked GUIDs are:

```text
{9F156763-7844-4DC4-B2B1-901F640F5155}  Open in Terminal
{09A47860-11B0-4DA5-AFA5-26D86198A780}  Scan with Microsoft Defender
{f81e9010-6ea4-11ce-a7ff-00aa003ca9f6}  Give access to
```

Default removes the classic context-menu override and `NoCustomizeThisFolder`, writes `%SystemRoot%\Temp\contextmenudefault.reg`, imports the Pin to Quick access and Add to favorites handlers, and restores the Compatibility, Library, Sharing, Previous Versions, and Send To states.

The original Default also deletes the entire shared key:

```text
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked
```

That broad deletion can remove entries unrelated to Context Menu.

## Preserved BoostLab Behavior

Apply preserves the source registry paths, names, value types, data, delete targets, and execution order. It does not add Explorer restart behavior or any unrelated shell changes.

Default preserves the source order and all source restoration behavior around the approved deviation. BoostLab writes and imports the exact `contextmenudefault.reg` payload before restoring the remaining handlers.

The Ultimate console menu, self-elevation, `Clear-Host`, `Write-Host`, loop, and `exit` are replaced by BoostLab GUI actions, runtime Administrator enforcement, Action Plan confirmation, structured logging, and verification.

## Yazan-Approved Default Deviation

BoostLab Default does not delete the complete shared `Shell Extensions\Blocked` key.

At the same point in the source execution order, BoostLab will remove only these three Context Menu-owned values:

```text
{9F156763-7844-4DC4-B2B1-901F640F5155}
{09A47860-11B0-4DA5-AFA5-26D86198A780}
{f81e9010-6ea4-11ce-a7ff-00aa003ca9f6}
```

The shared key is left in place even when those values were its final entries. Any unrelated values remain untouched.

**Reason:** avoid deleting unrelated shell-extension block entries not owned by this tool.

This is an intentional safety correction approved by Yazan. It does not weaken the Context Menu tool's intended result because it removes every Blocked value that Apply creates.

## Commands, Registry Paths, and File

The source `reg add` and `reg delete` effects are represented as hard-coded runtime operations and executed through the Windows command processor. No path or command is accepted from config or user input.

Principal paths include:

```text
HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer
HKCR\Folder\shell\pintohome
HKCR\*\shell\pintohomefile
HKCR\exefile\shellex\ContextMenuHandlers\Compatibility
HKCR\Folder\ShellEx\ContextMenuHandlers\Library Location
HKCR\AllFilesystemObjects\shellex\ContextMenuHandlers\ModernSharing
HKCR\AllFilesystemObjects\shellex\ContextMenuHandlers\SendTo
HKCR\UserLibraryFolder\shellex\ContextMenuHandlers\SendTo
```

Default preserves:

```powershell
Set-Content -Path "$env:SystemRoot\Temp\contextmenudefault.reg" -Value $ContextMenuDefault -Force
Regedit.exe /S "$env:SystemRoot\Temp\contextmenudefault.reg"
```

The temporary file remains in place because the source does not delete it.

## Capabilities

`RequiresAdmin = true`; `CanModifyRegistry = true`; `CanModifySecurity = true`; `SupportsDefault = true`; `NeedsExplicitConfirmation = true`.

The security capability is declared because Apply hides the Microsoft Defender scan context-menu handler. Internet, reboot, service, installer, download, driver, file deletion, TrustedInstaller, Safe Mode, and Restore capabilities are false.

## Confirmation and Restart

Apply and Default require visible Action Plan confirmation. The confirmation states that Apply hides the Defender scan entry and that Default preserves unrelated Blocked values.

Neither action restarts Windows, signs out, restarts Explorer, stops processes, changes services, removes AppX packages, downloads content, or reboots.

## Default Behavior

Default restores every source-defined handler and policy state, except that shared-key deletion is replaced with removal of the exact three owned values. Missing owned values are accepted when verification confirms the approved default state.

## Verification Strategy

Apply verifies 13 registry key/value states. Default verifies 23 states, including every value in the source `contextmenudefault.reg` payload and absence of only the three owned Blocked GUID values.

* `Passed`: every expected value or key state matches.
* `Warning`: one or more registry states cannot be read.
* `Failed`: a detected value or key state contradicts the approved state.

Command completion and verification status remain separate. A delete command can report an already-absent target; if verification proves the expected state, the action succeeds with the command warning exposed in structured results.

## Test Requirements

Automated tests must use static inspection and mocks only. Validate source checksum, exact Apply operations, exact Default restoration values, the source `.reg` payload, execution order, the three owned GUID removals, absence of broad shared-key deletion in the module, verification Passed/Warning/Failed behavior, runtime mapping, Action Plan confirmation, Latest Result rendering, source-ultimate integrity, deleted-tool exclusion, and protected module hashes. Tests must not write the real registry, launch regedit, stop Explorer, sign out, or reboot.
