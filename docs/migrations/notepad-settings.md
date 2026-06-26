# Notepad Settings Migration Record

* **Tool name:** Notepad Settings
* **Stage:** Windows
* **Source script path:** `source-ultimate/6 Windows/14 Notepad Settings.ps1`
* **Source checksum:** `CF139B4C5C96F57A2031F0CB9EDAC04E0F3CF86691BDC47F78DF5B45B76C1BA1`
* **Risk level:** Medium
* **Yazan approval status:** Approved by Yazan for Phase 32

## Original Ultimate Behavior

Apply, labeled **On (Recommended)** by Ultimate:

1. Requires Administrator.
2. Stops only `Notepad` with `-Force -ErrorAction SilentlyContinue`.
3. Waits two seconds.
4. Writes `%SystemRoot%\Temp\notepadsettings.reg`.
5. Loads `%LocalAppData%\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\Settings\settings.dat` at `HKLM\Settings`.
6. Imports three `HKLM\Settings\LocalState` values:
   * `OpenFile`
   * `GhostFile`
   * `RewriteEnabled`
7. Forces garbage collection, waits two seconds, and unloads `HKLM\Settings`.

Default stops Notepad, waits two seconds, and deletes only the same `settings.dat`.

## Approved BoostLab Behavior

`Apply` preserves the process stop, delays, registry file payload, hive mount, import, and unload order. `Default` preserves deletion of the exact source-defined `settings.dat`. An already-absent file is accepted as already default.

Applicability is checked before any process, backup, registry, hive, or file operation. If the exact source-targeted `settings.dat` is absent, Apply returns a structured `NotApplicable` result and performs no changes. This can occur with classic Notepad or Notepad builds that do not expose the source-targeted packaged settings hive. Default remains idempotent and reports already default without stopping Notepad or touching files.

Before either action mutates or deletes an existing `settings.dat`, BoostLab:

* creates a unique backup under `ProgramData\BoostLab\State\Backups\NotepadSettings`;
* verifies the backup SHA-256 against the source file;
* records the exact target, original hash and length, backup path and hash, action, and outcome in `ProgramData\BoostLab\State\notepad-settings.json`;
* blocks the action if backup or state capture fails.

These safety steps do not weaken Ultimate’s resulting Apply or Default behavior.

## Preserved Commands and Paths

* Process target: `Notepad`
* Target: `%LocalAppData%\Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\Settings\settings.dat`
* Temporary registry file: `%SystemRoot%\Temp\notepadsettings.reg`
* Hive mount: `HKLM\Settings`
* Commands: `reg load`, `reg import`, `reg unload`
* Default deletion scope: the exact Notepad `settings.dat` only

No unrelated AppX package, file, process, service, registry path, download, or restart behavior is added.

## Intentional Deviations

BoostLab adds explicit Action Plan confirmation, verified backup, persistent state capture, structured errors, and post-action verification. It does not expose `Restore`: retained backups are safety evidence and recovery material, but no approved automatic restore action exists yet.

## Capabilities

* `RequiresAdmin = true`
* `CanModifyRegistry = true`
* `CanDeleteFiles = true`
* `SupportsDefault = true`
* `SupportsRestore = false`
* `NeedsExplicitConfirmation = true`
* Internet, reboot, service, installer, download, driver, security, TrustedInstaller, and Safe Mode capabilities are false.

## Verification

Apply verifies:

* a hash-matching backup existed before mutation;
* `settings.dat` remains present;
* `OpenFile`, `GhostFile`, and `RewriteEnabled` match the exact source payload while the hive is mounted.

Default verifies:

* a hash-matching backup existed before deletion when the file was initially present;
* the exact `settings.dat` is absent afterward.

Automated tests use injected mocks and must not stop Notepad, mount a hive, write or delete the real file, or change the registry.
