# DirectX Artifact Source Review

## Phase 45 Decision

Phase 45 refused automated DirectX implementation because the source workflow
could not pass the artifact provenance and installer execution policy as a
production-approved artifact chain.

## Phase 129 Runtime Decision

Phase 129 implements DirectX as a source-equivalent controlled runtime while
keeping the artifact-source distinction explicit:

- the source URLs remain unchanged,
- no binaries are committed,
- no entry is added to `config/ArtifactProvenance.psd1`,
- no production allowlist entry is added,
- both author-hosted downloads are classified in
  `config/ExternalArtifactSources.psd1` as `UltimateAuthorHostedArtifact` with
  `NeedsBoostLabMirror`.

This means DirectX can preserve the Ultimate workflow behind explicit BoostLab
confirmation, but the downloads are still tracked as author-hosted sources that
need a future BoostLab mirror and hash/signature approval before any mirror
substitution or artifact-provenance approval exists.

## Source Reference

* Tool id: `directx`
* Source path: `source-ultimate/5 Graphics/2 DirectX.ps1`
* Source SHA-256:
  `B944AE03DE0AFDD7329B84BBF53FF5624739465CBB7130A021E097A6723B1B27`

## Ultimate Behavior Reviewed

The source performs these operations in order:

1. Requires Administrator rights and an internet connection.
2. Sets `$ProgressPreference` to `silentlycontinue`.
3. Downloads `7zip.exe` from:
   `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/7zip.exe`
4. Runs the downloaded executable with `/S` and waits for it.
5. Writes the 7-Zip `ContextMenu` and `CascadedMenu` HKCU values.
6. Moves the 7-Zip File Manager Start Menu shortcut and removes the original
   7-Zip Start Menu folder.
7. Downloads `directx.exe` from:
   `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/directx.exe`
8. Uses the installed `7z.exe` to extract `directx.exe` into
   `%SystemRoot%\Temp\directx`.
9. Launches the extracted `DXSETUP.exe` without waiting.

## Remaining Artifact Evidence Gap

The source URLs use `refs/heads/main`. They are mutable branch references, not
immutable release or commit-pinned artifact URLs.

The following evidence is still not approved:

* Exact SHA-256 for `7zip.exe`.
* Exact SHA-256 for `directx.exe`.
* Exact file size or reviewed size bounds for both downloads.
* Verified Authenticode publisher and signer requirements for `7zip.exe`.
* Verified provenance for the installed `7z.exe` later used to extract content.
* Exact extraction inventory and expected SHA-256 for `DXSETUP.exe`.
* Verified Authenticode publisher and signer requirements for `DXSETUP.exe`.
* Authoritative source, license, and redistributability evidence for the
  mirrored binaries.
* Reusable production installer descriptors for `7zip.exe /S` and `DXSETUP.exe`.
* A reusable production cleanup/restore scope for downloaded, extracted, and
  installer-created state.

## Production State

* `config/ArtifactProvenance.psd1` remains empty.
* No real DirectX or 7-Zip artifact is approved.
* `config/ExternalArtifactSources.psd1` records DirectX `7zip.exe` and
  `directx.exe` as author-hosted sources requiring a future BoostLab mirror.
* `modules/Graphics/directx.psm1` implements the source-equivalent runtime with
  explicit confirmation and mockable operation execution.
* `docs/migrations/directx.md` records the Phase 129 migration.

## Future Mirror Approval Package

A future source-substitution phase would need all of the following before
changing the DirectX runtime URLs to a BoostLab-controlled mirror:

1. Immutable authoritative or commit-pinned source URLs for every downloaded
   artifact.
2. Exact expected file names, SHA-256 values, sizes, publishers, signer
   statuses, licenses, and redistributability notes.
3. Independent provenance requirements for executable extraction output,
   including `DXSETUP.exe`.
4. Exact source-approved command lines and switches for 7-Zip installation,
   extraction, and DirectX setup.
5. Exact tool-specific file, registry, shortcut, and temp-path scopes with
   state capture, ownership, verification, and cleanup rules.
6. Mocked tests covering mismatched hashes, invalid signers, unexpected
   extraction output, installer failure, and bounded cleanup.
