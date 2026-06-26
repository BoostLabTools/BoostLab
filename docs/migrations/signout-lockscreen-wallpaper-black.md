# Signout LockScreen Wallpaper Black Migration Record

* **Tool name:** Signout LockScreen Wallpaper Black
* **Stage:** Windows
* **Source script path:** `source-ultimate/6 Windows/5 Signout Lockscreen Wallpaper Black.ps1`
* **Source checksum:** `132C79401BE9CC2067FA97558AC28C03946B4D50BC2E895CF516A658332ECEB1`
* **Risk level:** Medium
* **Required privileges:** Administrator
* **Parity status:** Exact Ultimate parity implemented and accepted in Phase 139

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

BoostLab preserves the source image-generation method, target path, registry paths, value names, value types, value data, wallpaper refresh command, file deletion target, and operation order.

The Ultimate console menu, self-elevation, output, pause, and exit flow are replaced by BoostLab GUI actions, application-level Administrator enforcement, Action Plan confirmation, structured logging, and post-action verification. These GUI mechanics do not remove any source capability.

BoostLab does not restart Explorer, stop processes, sign out, reboot, modify services, remove AppX packages, download content, or add unrelated personalization changes.

## Exact Apply Behavior

Apply performs the source-defined sequence:

1. Load `System.Windows.Forms` and `System.Drawing`.
2. Read the primary monitor size.
3. Create a black bitmap at the primary monitor resolution.
4. Save it as `C:\Windows\Black.jpg`.
5. Set `LockScreenImagePath` to `C:\Windows\Black.jpg`.
6. Set `LockScreenImageStatus` to `REG_DWORD 1`.
7. Set `HKCU\Control Panel\Desktop\Wallpaper` to `C:\Windows\Black.jpg`.
8. Request `UpdatePerUserSystemParameters`.

There is no BoostLab backup or ownership-state wrapper in the exact parity implementation. An existing `C:\Windows\Black.jpg` is overwritten by the source-defined generated image.

## Exact Default Behavior

Default performs the source-defined sequence:

1. Delete the complete key:

```text
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP
```

2. Set `HKCU\Control Panel\Desktop\Wallpaper` to:

```text
C:\Windows\Web\Wallpaper\Windows\img0.jpg
```

3. Request `UpdatePerUserSystemParameters`.
4. Delete:

```text
C:\Windows\Black.jpg
```

Default is not Restore. It does not restore captured prior state and it does not keep unrelated values under the `PersonalizationCSP` key.

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

The source-defined file deletion remains limited to the exact `C:\Windows\Black.jpg` path.

## Capabilities

`RequiresAdmin = true`; `CanModifyRegistry = true`; `CanDeleteFiles = true`; `SupportsDefault = true`; `NeedsExplicitConfirmation = true`.

Internet, reboot, service, installer, download, driver, security, TrustedInstaller, Safe Mode, and Restore capabilities are false.

## Confirmation and Restart

Apply and Default require visible Action Plan confirmation.

The Apply plan identifies `C:\Windows\Black.jpg` generation, the two HKLM PersonalizationCSP values, the HKCU desktop wallpaper value, and the wallpaper refresh request.

The Default plan states that the complete `PersonalizationCSP` key and exact `C:\Windows\Black.jpg` path are deleted, the approved desktop wallpaper path is restored, and the wallpaper refresh request is made.

Neither action restarts Windows. Lock screen, sign-out, Settings, Explorer, or a later user session may be needed before every visual wallpaper change appears.

## Verification Strategy

Apply verifies:

* `LockScreenImagePath`
* `LockScreenImageStatus`
* `HKCU` desktop `Wallpaper`
* `C:\Windows\Black.jpg` exists

Default verifies:

* the complete `PersonalizationCSP` key is absent
* `HKCU` desktop `Wallpaper`
* `C:\Windows\Black.jpg` is absent

`Passed` means every detected registry and file state matches the requested action. `Warning` means commands completed but a value, key, file, or refresh state could not be fully detected. `Failed` means a detected state contradicts the requested action.

## Test Requirements

Automated tests must use static inspection and injected mocks only. They must not write the real registry, create or delete the real `C:\Windows\Black.jpg`, change wallpaper, stop processes, sign out, or reboot.

Tests must validate the source checksum, exact source paths and values, Apply order, complete PersonalizationCSP key deletion, exact `C:\Windows\Black.jpg` deletion, verification Passed/Warning/Failed outcomes, Action Plan confirmation, runtime mapping, Latest Result rendering, capability metadata, parity cursor advancement, source-ultimate integrity, deleted-tool exclusion, implemented and placeholder counts, and unchanged protected tools.
