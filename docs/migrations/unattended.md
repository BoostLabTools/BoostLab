# Unattended Migration Record

## Identity

* **Tool:** Unattended
* **Stage:** Refresh
* **Source:** `source-ultimate/2 Refresh/2 Unattended.ps1`
* **Source SHA-256:** `0974CFCC4FFC4B21BF4EB62172C0C1C31FF32AB147878A4610FC19C95DF74338`
* **Yazan approval status:** Phase 111 accepted as `DoneYazanAcceptedNearParity`; the source-equivalent Windows 11 payload behavior is preserved with safer GUI confirmation, removable-media validation, backup/state capture, and verification.

## Original Ultimate Behavior

Ultimate creates `C:\Windows\Temp\autounattendtemplate.xml`, replaces every account placeholder with a required technician-entered account name, writes `C:\Windows\Temp\autounattend.xml` as UTF-8, deletes the template, moves `autounattend.xml` to a technician-entered USB drive root with overwrite enabled, and opens that drive.

The XML:

* Uses English (United States) locale settings and Central Standard Time.
* Skips EULA, local-account, online-account, wireless, machine OOBE, and user OOBE pages.
* Creates the selected local account in the Administrators group with a blank password.
* Sets unlimited password age, enables the account, and disables password-required behavior.
* Skips automatic activation and joins `WORKGROUP`.
* Accepts the Windows EULA and disables Dynamic Update.
* Adds `BypassTPMCheck`, `BypassRAMCheck`, `BypassSecureBootCheck`, `BypassCPUCheck`, and `BypassStorageCheck` as `REG_DWORD 1` commands during Windows Setup.

The source does not partition disks, format media, start Windows Setup, reboot, download content, or provide Default/Restore behavior.

## Approved BoostLab Behavior

BoostLab implements:

* `Analyze`: read-only Windows 11 compatibility, removable-media availability, and exact payload behavior.
* `Apply`: confirmed creation of the source-defined `autounattend.xml` on selected removable media.

The catalog's former `Default` action is removed because the approved source has no Default branch. No Restore action is claimed.

The source contains one shared Windows 11-targeted payload rather than separate Windows 10 and Windows 11 optimization branches. BoostLab permits Windows 10 or Windows 11 to host this preparation workflow because its output and goal remain Windows 11. Windows 10 optimization, performance, service, and settings-improvement branches remain unsupported.

## Preserved Operations

BoostLab preserves:

* The complete XML payload.
* Account placeholder substitution.
* The source temporary filenames under `C:\Windows\Temp`.
* UTF-8 final artifact creation.
* Template deletion.
* Move to the selected removable-media root as `autounattend.xml`.
* Opening the selected media root after successful generation.
* All account, OOBE, locale, setup, Dynamic Update, workgroup, and hardware-bypass behavior.

## Approved Safety Additions

Before changing any source-targeted file, BoostLab:

* Requires explicit Action Plan confirmation.
* Requires a Windows 10 or Windows 11 host and always identifies the generated payload as Windows 11-targeted.
* Accepts only a currently detected removable-media root.
* Validates the account name before writing XML.
* Captures and hash-verifies backups of pre-existing:
  * `C:\Windows\Temp\autounattendtemplate.xml`
  * `C:\Windows\Temp\autounattend.xml`
  * `<selected removable root>\autounattend.xml`
* Persists destination, backup, ownership, source checksum, and action state under `%ProgramData%\BoostLab\State`.
* Blocks all writes if inspection, backup, or initial state persistence fails.

Backups are retained as recovery material and evidence. BoostLab does not expose Restore because no approved automatic restore behavior exists.

## Capabilities

* `RequiresAdmin = true`
* `RequiresInternet = false`
* `CanReboot = false`
* `CanModifyRegistry = true`
* `CanModifyServices = false`
* `CanInstallSoftware = true`
* `CanDownload = false`
* `CanModifyDrivers = false`
* `CanModifySecurity = true`
* `CanDeleteFiles = true`
* `UsesTrustedInstaller = false`
* `UsesSafeMode = false`
* `SupportsDefault = false`
* `SupportsRestore = false`
* `NeedsExplicitConfirmation = true`

Registry, software, and security capabilities describe the behavior encoded for a future Windows Setup run. BoostLab does not execute those setup commands while generating the file.

## Verification

Apply verifies:

* The destination file exists at the selected removable-media root.
* The temporary template was deleted after account substitution.
* The temporary `autounattend.xml` no longer remains under Windows Temp after the move.
* Every detected pre-existing source-targeted file has a recorded verified backup.
* The destination content exactly matches the generated source payload.
* The document parses as XML.
* All three account placeholders contain the selected account name.
* All five hardware requirement bypass commands are present.
* Destination SHA-256 and backup count are recorded.

Opening the destination directory is secondary. A failure to open Explorer is reported as a warning after a verified artifact has been created.

## Test Requirements

Automated tests must be static or mocked only. They must not write to `C:\Windows\Temp`, removable media, or a real setup drive.

Tests must validate:

* Source checksum and source payload preservation.
* Windows 10 and Windows 11 host compatibility for Windows 11 preparation.
* Windows 10 optimization branches remain unsupported.
* Analyze is read-only.
* Apply and confirmation behavior.
* Account and removable-media validation.
* Backup-before-write ordering.
* State capture before mutation.
* Exact XML/account/bypass verification.
* No Default or Restore claim.
* No download, setup launch, disk partitioning, formatting, or reboot behavior.
* Runtime mapping, Action Plan text, source integrity, and deleted-tool exclusion.

## Ordered Parity Status

Phase 111 outcome: `DoneYazanAcceptedNearParity`.

BoostLab preserves the practical Ultimate Unattended capability: it creates the
same Windows 11-targeted unattended payload, performs the same account
substitution, uses the same temporary file names, moves the final
`autounattend.xml` to selected installation media, and opens the destination
root after generation.

The differences are accepted safety mechanics: explicit GUI confirmation,
removable-media selection instead of raw drive-letter input, account-name
validation, verified backups, persisted state, and structured verification.
The source has no Default or Restore branch, and BoostLab does not claim one.
