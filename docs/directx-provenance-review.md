# DirectX Artifact Provenance Review

## Phase 45 Decision

DirectX remains a refused placeholder. Phase 45 does not add artifact records,
implement `Analyze` or `Apply`, enable downloads, extract files, launch an
installer, or change the current DirectX module.

The Ultimate workflow cannot pass the Phase 35 provenance and installer
execution policy with the evidence currently available in the repository.

## Source Reference

* Tool id: `directx`
* Source path: `source-ultimate/5 Graphics/2 DirectX.ps1`
* Source SHA-256:
  `17051A2F0F7A0CF16BE525121720406E8F1630C94E5977A7CD4C18652A87EE05`

## Ultimate Behavior Reviewed

The source performs these operations in order:

1. Requires Administrator rights and an internet connection.
2. Downloads `7zip.exe` from:
   `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/7zip.exe`
3. Runs the downloaded executable with `/S` and waits for it.
4. Writes the 7-Zip `ContextMenu` and `CascadedMenu` HKCU values.
5. Moves the 7-Zip File Manager Start Menu shortcut and removes the original
   7-Zip Start Menu folder.
6. Downloads `directx.exe` from:
   `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/directx.exe`
7. Uses the installed `7z.exe` to extract `directx.exe` into
   `%SystemRoot%\Temp\directx`.
8. Launches the extracted `DXSETUP.exe`.

The source does not provide hashes, expected sizes, Authenticode signer
requirements, an extraction inventory, installer completion handling, or
cleanup after launching `DXSETUP.exe`.

## Why Implementation Was Refused

The two source URLs use `refs/heads/main`. They are mutable branch references,
not immutable release or commit-pinned artifact URLs. Approving their current
contents would not approve what those URLs may serve later.

The following required evidence is missing:

* Exact SHA-256 for `7zip.exe`.
* Exact SHA-256 for `directx.exe`.
* Exact file size or reviewed size bounds for both downloads.
* Verified Authenticode publisher and signer requirements for `7zip.exe`.
* Verified provenance for the installed `7z.exe` later used to extract content.
* Exact extraction inventory and expected SHA-256 for `DXSETUP.exe`.
* Verified Authenticode publisher and signer requirements for `DXSETUP.exe`.
* Authoritative source, license, and redistributability evidence for the
  mirrored binaries.
* An approved installer request for `7zip.exe /S`.
* An approved installer request for the extracted `DXSETUP.exe`.
* Exact file, shortcut, registry, and generated-temp-path scopes for the
  source-defined side effects.

The Phase 35 installer helper is also intentionally inert. Even a fully valid
mock request returns `NotImplemented` with `ProcessStarted = false`. DirectX
must not bypass that boundary by calling `Start-Process` from its tool module.

Adding guessed hashes, trusting the mutable mirror, substituting another
DirectX workflow, omitting 7-Zip side effects, or launching the extracted setup
without independent verification would either violate provenance policy or
weaken the approved Ultimate behavior.

## Production State

* `config/ArtifactProvenance.psd1` remains empty.
* No real DirectX or 7-Zip artifact is approved.
* `modules/Graphics/DirectX.psm1` remains a placeholder.
* No DirectX migration record is created because the tool is not implemented.
* No download, extraction, installer launch, registry write, shortcut change,
  cleanup, or DirectX system change is enabled by Phase 45.

## Required Approval Package for a Future Retry

A future DirectX phase must provide and approve all of the following before
implementation:

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
6. A separately approved installer execution implementation that preserves the
   Phase 35 confirmation, logging, timeout, exit-code, and verified-path rules.
7. Mocked tests covering mismatched hashes, invalid signers, unexpected
   extraction output, installer failure, and bounded cleanup.

Until that package exists, DirectX remains disabled and visual-only.
