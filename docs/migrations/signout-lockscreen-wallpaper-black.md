# Signout LockScreen Wallpaper Black Migration Record

* **Tool name:** Signout LockScreen Wallpaper Black
* **Stage:** Windows
* **Source script path:** `source-ultimate/6 Windows/5 Signout Lockscreen Wallpaper Black.ps1`
* **Source checksum:** `C5A3E791BB85EE166397748D95B0BD4725063B55DC50CAEA805DC212E485C64C`
* **Risk level:** Medium
* **Required privileges:** Administrator
* **Yazan approval status:** Approved by Yazan for Phase 22, including the scoped registry and file-ownership deviations

## Original Ultimate Behavior

Apply reads the primary monitor dimensions, creates a black `System.Drawing.Bitmap`, fills it black, and saves it as:

```text
C:\Windows\Black.jpg
```

It then performs these operations in order:

```text
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP
  LockScreenImagePath   REG_SZ    C:\Windows\Black.jpg
  LockScreenImageStatus REG_DWORD 1

HKCU\Control Panel\Desktop
  Wallpaper             REG_SZ    C:\Windows\Black.jpg
```

Finally, it runs:

```text
rundll32.exe user32.dll, UpdatePerUserSystemParameters
```

Default deletes the complete `PersonalizationCSP` key, sets the desktop wallpaper to `C:\Windows\Web\Wallpaper\Windows\img0.jpg`, requests the same wallpaper refresh, and deletes `C:\Windows\Black.jpg`.

## Preserved BoostLab Behavior

Apply preserves the source image-generation method, target path, registry paths, value names, value types, data, wallpaper refresh command, and operational order. BoostLab adds only the approved pre-overwrite backup and ownership-state steps around the source behavior.

The Ultimate console menu, self-elevation, output, pause, and exit flow are replaced by BoostLab GUI actions, application-level Administrator enforcement, Action Plan confirmation, structured logging, ownership state, and post-action verification.

BoostLab does not restart Explorer, stop processes, sign out, reboot, modify services, remove AppX packages, download content, or add unrelated personalization changes.

## Yazan-Approved Registry Deviation

BoostLab Default does not delete this shared key:

```text
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP
```

It removes only the exact values managed by this tool:

```text
LockScreenImagePath
LockScreenImageStatus
```

The key itself and all unrelated values remain intact.

**Reason:** the source key-wide deletion could remove personalization or lock-screen policy values owned by Windows, another administrator, or another tool. Removing the two owned values preserves the intended inverse of Apply without deleting unrelated policy state.

## Yazan-Approved File Ownership Deviation

Before Apply overwrites `C:\Windows\Black.jpg`, BoostLab checks the file and its recorded ownership hash.

* If the file is already proven to be the active BoostLab-generated file, Apply may replace it while retaining any existing backup record.
* If the file exists and is not proven to be BoostLab-owned, BoostLab copies it to:

```text
%ProgramData%\BoostLab\State\Backups\SignoutLockScreenWallpaperBlack
```

* Ownership and backup metadata are recorded in:

```text
%ProgramData%\BoostLab\State\signout-lockscreen-wallpaper-black.json
```

The metadata records the target, backup path, original SHA-256 when available, generated SHA-256, dimensions, active ownership state, and final file disposition.

Default restores the recorded backup when one exists. Without a backup, Default removes `Black.jpg` only when active BoostLab ownership and the generated-file hash prove that the current file is owned by this tool. If ownership is uncertain, the file is left intact and the result is `Warning`.

**Reason:** the original source deletes `C:\Windows\Black.jpg` without proving that the file was created by the tool. The approved policy prevents unrelated pre-existing files from being overwritten without backup or deleted during Default.

## Commands, Registry Paths, and Files

The implementation preserves these source paths and values:

```text
C:\Windows\Black.jpg
C:\Windows\Web\Wallpaper\Windows\img0.jpg
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP
HKCU\Control Panel\Desktop
LockScreenImagePath
LockScreenImageStatus
Wallpaper
```

Registry operations are hard-coded in the module and are not accepted from config or user input. The source wallpaper refresh remains:

```text
rundll32.exe user32.dll, UpdatePerUserSystemParameters
```

## Capabilities

`RequiresAdmin = true`; `CanModifyRegistry = true`; `CanDeleteFiles = true`; `SupportsDefault = true`; `NeedsExplicitConfirmation = true`.

File deletion is limited to the exact `C:\Windows\Black.jpg` target and occurs only when ownership is proven. Internet, reboot, service, installer, download, driver, security, TrustedInstaller, Safe Mode, and Restore capabilities are false.

## Confirmation and Restart

Apply and Default require visible Action Plan confirmation.

The Apply plan identifies the two HKLM PersonalizationCSP values, `C:\Windows\Black.jpg` creation or replacement, pre-existing-file backup behavior, desktop wallpaper value, refresh request, and ownership metadata.

The Default plan states that only the two tool-owned PersonalizationCSP values are removed, unrelated values and files remain, a recorded backup is restored, and deletion requires ownership proof.

Neither action restarts Windows. Lock screen, sign-out, Settings, Explorer, or a later user session may be needed before every visual wallpaper change appears.

## Default Behavior

Default performs the approved inverse in source order:

1. Remove only `LockScreenImagePath`.
2. Remove only `LockScreenImageStatus`.
3. Set `HKCU\Control Panel\Desktop\Wallpaper` to `C:\Windows\Web\Wallpaper\Windows\img0.jpg`.
4. Request `UpdatePerUserSystemParameters`.
5. Restore a recorded pre-existing `Black.jpg`, remove a proven BoostLab-owned generated file, accept an already-absent file, or leave an uncertain file intact with a warning.

Default never deletes the complete PersonalizationCSP key.

## Verification Strategy

Apply and Default verify:

* `LockScreenImagePath`
* `LockScreenImageStatus`
* `HKCU` desktop `Wallpaper`
* `C:\Windows\Black.jpg` existence
* generated or original file SHA-256 when available
* BoostLab ownership metadata
* backup path and final file disposition

`Passed` means every detected registry, file, and ownership state matches the requested action. `Warning` means commands completed but a value, file hash, refresh, backup, or ownership state could not be fully confirmed. `Failed` means a detected state contradicts the requested action or a required backup, restore, image, registry, or state operation failed.

## Test Requirements

Automated tests must use static inspection and injected mocks only. They must not write the real registry, create or delete the real `C:\Windows\Black.jpg`, change wallpaper, stop processes, sign out, or reboot.

Tests must validate the source checksum, exact source paths and values, Apply order, backup-before-overwrite behavior, scoped Default value deletion, absence of complete PersonalizationCSP key deletion, backup restoration, hash-proven owned-file deletion, unknown-ownership preservation, verification Passed/Warning/Failed outcomes, Action Plan confirmation, runtime mapping, Latest Result rendering, capability metadata, source-ultimate integrity, deleted-tool exclusion, implemented and placeholder counts, and unchanged protected tools.
