# User Account Pictures Black Migration Record

* **Tool name:** User Account Pictures Black
* **Stage:** Windows
* **Source script path:** `source-ultimate/6 Windows/6 User Account Pictures Black.ps1`
* **Source checksum:** `8B978374BC9D5AE51858FC71BE02D0DFFAE29AADFEFAF8662D8654D735443710`
* **Risk level:** Medium
* **Required privileges:** Administrator
* **Yazan approval status:** Approved by Yazan for Phase 27

## Original Ultimate Behavior

Ultimate exposes two console choices:

* `Black`
* `Default`

The Black branch:

1. Uses `C:\ProgramData\Microsoft\User Account Pictures` as the account-picture root.
2. Copies that folder to `C:\ProgramData\User Account Pictures` only when the destination does not already exist.
3. Recursively enumerates only `.png` and `.bmp` files beneath the account-picture root.
4. Reads each image's width and height.
5. creates a new black bitmap with the same dimensions.
6. Saves the black bitmap over the original file.

The Default branch recursively copies `C:\ProgramData\User Account Pictures` back to `C:\ProgramData\Microsoft\User Account Pictures`.

The source performs no registry, service, process, driver, AppX, download, installer, TrustedInstaller, Safe Mode, security-policy, or reboot behavior.

## Approved BoostLab Behavior

* `Apply` preserves Ultimate's Black branch.
* `Default` preserves Ultimate's Default intent by restoring the originals captured before Apply.
* The target root remains exactly `%ProgramData%\Microsoft\User Account Pictures`.
* Only recursive `.png` and `.bmp` files are eligible.
* Each black replacement preserves the original image dimensions.
* No additional Windows account-picture target is introduced.

Before changing any target, BoostLab creates and verifies a versioned tool-owned backup under the existing BoostLab ProgramData state boundary. It records target paths, backup paths, original hashes, generated hashes, dimensions, and ownership dispositions in `user-account-pictures-black.json`.

## Source-to-BoostLab Mapping

| Ultimate operation | BoostLab operation | Mapping |
|---|---|---|
| `%ProgramData%\Microsoft\User Account Pictures` | The same target root | Exact |
| Recursive `Get-ChildItem` for `*.png,*.bmp` | Recursive enumeration restricted to `.png` and `.bmp` | Exact scope |
| Read original bitmap width and height | Read original bitmap width and height | Exact |
| Create a new black bitmap | Create a new black bitmap | Exact |
| Save over each source image | Save over the same tracked image after verified backup | Exact operational effect |
| Backup before first Apply | Versioned, hash-verified BoostLab backup before any overwrite | Strengthened safety |
| Copy backup to the Microsoft account-picture directory for Default | Restore each verified backup to its exact captured relative path | Same intended result with ownership enforcement |

Every production target maps to the single Ultimate account-picture root. BoostLab does not add user profile pictures, documents, avatars, registry paths, or other image directories.

## Backup and Ownership Policy

BoostLab must finish backup preparation and save the ownership manifest before overwriting an image.

For each tracked file, the manifest records:

* Relative and full target path
* Tool-owned backup path
* Original SHA-256
* Backup SHA-256
* Generated black-image SHA-256
* Original dimensions
* Last ownership disposition

Apply is idempotent for files whose generated hash is still present. A tracked file changed outside BoostLab is left intact with a warning.

Default restores a file only when:

* Its backup exists and matches the captured original hash; and
* The target is absent, already original, or still matches the BoostLab-generated hash.

Unknown or externally modified files are never overwritten or deleted by Default. Untracked files beneath the approved directory are left intact and reported as warnings.

The manifest records this protected disposition as `LeftIntactUnknownOwnership`.

Tool-owned backup files are removed only after every tracked target verifies as restored. The ownership manifest remains as the audit record. The legacy Ultimate backup directory `%ProgramData%\User Account Pictures` is not deleted or treated as BoostLab-owned.

## Intentional Deviations

Ultimate trusts a shared folder-level backup without verifying its completeness or ownership and silently suppresses image failures. BoostLab instead:

* Uses a versioned backup set under `%ProgramData%\BoostLab\State\Backups\UserAccountPicturesBlack`.
* Verifies every backup hash before changing any target.
* Tracks ownership and generated hashes.
* Leaves unknown file content intact.
* Reports every backup, write, restore, cleanup, and verification warning or error.

These deviations are required by the approved Phase 27 backup and ownership requirements. They preserve the intended black/default effect without allowing an unverified backup to overwrite unknown files.

## Capabilities

* `RequiresAdmin = true`
* `RequiresInternet = false`
* `CanReboot = false`
* `CanModifyRegistry = false`
* `CanModifyServices = false`
* `CanInstallSoftware = false`
* `CanDownload = false`
* `CanModifyDrivers = false`
* `CanModifySecurity = false`
* `CanDeleteFiles = true`
* `UsesTrustedInstaller = false`
* `UsesSafeMode = false`
* `SupportsDefault = true`
* `SupportsRestore = false`
* `NeedsExplicitConfirmation = true`

`CanDeleteFiles` covers cleanup of verified BoostLab-owned backup files only. The tool does not delete account-picture targets or unrelated files.

## Confirmation and Restart

Apply and Default require the Action Plan confirmation flow. The plan must show Administrator and file-change requirements.

The tool does not restart Windows, restart Explorer, sign out the user, or reboot. Windows may cache an account picture until a later sign-in or normal UI refresh.

## Verification

Verification is read-only and hash-based:

* Apply passes when each safely targeted image matches its recorded generated black-image hash.
* Default passes when each safely restored image matches its captured original hash.
* Unknown ownership, inaccessible files, and untracked images are warnings.
* Missing expected files, failed writes, failed restores, or readable contradictory hashes are failures.

Structured results include command status, verification status, expected and detected state, target and backup paths, targeted files, backups, changed files, restored files, skipped files, unknown files, warnings, errors, and timestamp.

## Test Requirements

Tests must be static or mocked and must not modify real account-picture files. They must validate:

* Source checksum and safety gate.
* Exact target root and `.png`/`.bmp` scope.
* Apply backs up every image before any overwrite.
* Black images preserve the original dimensions.
* Default restores verified backups.
* Unknown target content and untracked files remain intact with warnings.
* Only tool-owned backup files can be cleaned.
* Confirmation, capability metadata, runtime mapping, structured results, and verification contract.
* `source-ultimate` integrity and permanent Loudness EQ deletion.
