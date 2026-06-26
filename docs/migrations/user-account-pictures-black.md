# User Account Pictures Black Migration Record

* **Tool name:** User Account Pictures Black
* **Stage:** Windows
* **Source script path:** `source-ultimate/6 Windows/6 User Account Pictures Black.ps1`
* **Source checksum:** `F4BFE40640F6825F288535332CD97FBB69E0C22137FD53985A4D04ED7210E73F`
* **Risk level:** Medium
* **Required privileges:** Administrator
* **Parity status:** Exact Ultimate parity implemented and accepted in Phase 140

## Original Ultimate Behavior

Ultimate exposes two console choices:

* `Black`
* `Default`

The Black branch performs these source-defined operations:

1. If `C:\ProgramData\User Account Pictures` does not exist, copy `C:\ProgramData\Microsoft\User Account Pictures` to `C:\ProgramData`.
2. Set the account-picture root to `C:\ProgramData\Microsoft\User Account Pictures`.
3. Recursively enumerate `*.png` and `*.bmp` files under that root with `Get-ChildItem -Include *.png,*.bmp -Recurse`.
4. Load `System.Drawing`.
5. For each discovered image, read the original width and height, create a new black bitmap with the same dimensions, and save it over the same file.
6. Silently continue per-image failures.

The Default branch copies:

```text
C:\ProgramData\User Account Pictures
```

to:

```text
C:\ProgramData\Microsoft
```

The source performs no registry, service, process, driver, AppX, download, installer, TrustedInstaller, Safe Mode, ACL, ownership, security-policy, Explorer, sign-out, or reboot behavior.

## Preserved BoostLab Behavior

BoostLab preserves the source target paths, legacy backup path, recursive PNG/BMP enumeration, image read/write method, black fill, same-dimension bitmap generation, and Default copy-back behavior.

The Ultimate console menu, self-elevation, output, pause, and exit flow are replaced by BoostLab GUI actions, application-level Administrator enforcement, Action Plan confirmation, structured logging, and mocked validator seams. These GUI mechanics do not remove any source capability.

There is no BoostLab manifest or captured-state restore wrapper in the exact parity implementation.

## Exact Apply Behavior

Apply maps to the Ultimate `Black` branch:

```text
Source backup path: C:\ProgramData\User Account Pictures
Target root:        C:\ProgramData\Microsoft\User Account Pictures
Included files:     *.png, *.bmp recursively
Image fill:         Black
```

If the legacy backup directory is absent, Apply requests the source-defined folder copy before enumerating images. It then loads `System.Drawing` and writes black images back to the same files.

Apply does not create a BoostLab-owned backup directory, manifest, restore record, hash inventory, ACL change, ownership change, or quarantine record.

## Exact Default Behavior

Default maps to the Ultimate `Default` branch:

```text
Copy from: C:\ProgramData\User Account Pictures
Copy to:   C:\ProgramData\Microsoft
```

Default is not Restore. It does not restore selected captured state, verify BoostLab ownership, or remove tool-owned backup files. It performs the source-defined copy-back operation only.

## Commands, Paths, and Files

The implementation preserves these source paths and operations:

```text
C:\ProgramData\Microsoft\User Account Pictures
C:\ProgramData\User Account Pictures
Copy-Item ... -Recurse -Force -ErrorAction SilentlyContinue
Get-ChildItem ... -Include *.png,*.bmp -Recurse
System.Drawing.Bitmap::FromFile(...)
System.Drawing.Graphics::FromImage(...)
System.Drawing.Color::Black
Bitmap.Save(...)
```

The tool has no registry paths, no registry value names, no registry value types, no scheduled tasks, no services, no process handling, no Open action, and no Restore action.

## Capabilities

`RequiresAdmin = true`; `CanDeleteFiles = true`; `SupportsDefault = true`; `NeedsExplicitConfirmation = true`.

Internet, reboot, registry, service, installer, download, driver, security, TrustedInstaller, Safe Mode, and Restore capabilities are false.

`CanDeleteFiles` remains true as the conservative existing file-risk flag for overwriting account-picture files. The source does not delete account-picture targets or unrelated files.

## Confirmation and Restart

Apply and Default require visible Action Plan confirmation.

Neither action restarts Windows, restarts Explorer, signs out the user, downloads content, launches installers, or opens external tools. Windows may cache account-picture imagery until a later sign-in or normal shell refresh.

## Verification Strategy

BoostLab reports:

* target root
* legacy backup root
* copy request result
* targeted PNG/BMP files
* black-image write results
* operation order
* warnings and errors

`Passed` means the mocked or production adapter reported the source-defined operation path without warnings. `Warning` means the source-defined operation completed with adapter warnings, such as a suppressed backup or per-image write warning. `Failed` means an unexpected runtime error prevented completion.

## Test Requirements

Automated tests must use static inspection and injected mocks only. They must not copy, overwrite, or delete real account-picture files; mutate registry; change ACLs or ownership; stop Explorer; sign out; download; install; or reboot.

Tests must validate the source checksum, exact source paths, PNG/BMP scope, backup-before-enumeration order, same-file black-image write behavior, Default copy-back behavior, absence of Open/Restore, absence of BoostLab manifest/ownership wrapper behavior, capability metadata, runtime mapping, parity acceptance, cursor advancement, source-ultimate integrity, and deleted-tool exclusion.
