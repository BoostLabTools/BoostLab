# DirectX Migration Record

## Tool

- Tool name: DirectX
- Tool id: `directx`
- Stage: Graphics
- Module: `modules/Graphics/directx.psm1`

## Source

- Source script path: `source-ultimate/5 Graphics/2 DirectX.ps1`
- Source SHA-256:
  `B944AE03DE0AFDD7329B84BBF53FF5624739465CBB7130A021E097A6723B1B27`

## Original Ultimate Behavior Summary

The Ultimate source requires Administrator rights and internet connectivity,
sets `$ProgressPreference` to `silentlycontinue`, downloads `7zip.exe`,
silently installs and configures 7-Zip, changes the 7-Zip Start Menu shortcut
location, downloads `directx.exe`, extracts it with 7-Zip into the Windows Temp
DirectX folder, and launches the extracted DirectX setup executable.

## Approved BoostLab Behavior

Phase 129 upgrades DirectX from controlled manual handoff to
source-equivalent controlled runtime:

- `Analyze`: read-only source/checksum/artifact-source/status analysis.
- `Apply`: runs the source-equivalent DirectX workflow after explicit Action
  Plan confirmation.
- `Open`: not exposed; the source defines no standalone Open branch.
- `Default`: not exposed; the source defines no Default branch.
- `Restore`: not exposed; no captured-state Restore contract exists.

## Preserved Operation Order

`Apply` preserves the source order:

1. Verify Administrator rights.
2. Verify internet connectivity with `8.8.8.8`.
3. Set progress preference to `silentlycontinue`.
4. Download `7zip.exe` to `%SystemRoot%\Temp\7zip.exe`.
5. Install 7-Zip by running `7zip.exe /S` and waiting.
6. Set `HKCU\Software\7-Zip\Options\ContextMenu = DWORD 259`.
7. Set `HKCU\Software\7-Zip\Options\CascadedMenu = DWORD 0`.
8. Move the 7-Zip File Manager Start Menu shortcut.
9. Remove the source-defined 7-Zip Start Menu folder.
10. Download `directx.exe` to `%SystemRoot%\Temp\directx.exe`.
11. Extract it with `%SystemDrive%\Program Files\7-Zip\7z.exe`.
12. Launch `%SystemRoot%\Temp\directx\DXSETUP.exe` without waiting.

## Artifact Source Policy

The runtime URLs remain source-defined and unchanged:

- `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/7zip.exe`
- `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/directx.exe`

Both are classified in `config/ExternalArtifactSources.psd1` as
`UltimateAuthorHostedArtifact` with `NeedsBoostLabMirror`. This classification
does not approve a binary, no artifact provenance record is approved or added,
and no BoostLab mirror is substituted.

## Intentional Safety Mechanics

BoostLab adds GUI confirmation, structured results, visible failure reporting,
and test-safe executor injection. These mechanics do not remove the practical
source result: the confirmed workflow still installs/configures 7-Zip, extracts
DirectX, and launches `DXSETUP.exe`.

## Side Effects

Confirmed `Apply` can download files, run installers/external processes, write
HKCU 7-Zip values, move/remove the source-defined Start Menu shortcut folder,
extract files under Windows Temp, and launch the DirectX setup UI. The source
does not request a reboot.

## Required Privileges

The source expects Administrator rights and internet access. BoostLab verifies
both before running the mutating workflow.

## Capabilities

- RequiresAdmin: true
- RequiresInternet: true
- CanReboot: false
- CanModifyRegistry: true
- CanModifyServices: false
- CanInstallSoftware: true
- CanDownload: true
- CanModifyDrivers: false
- CanModifySecurity: false
- CanDeleteFiles: true
- UsesTrustedInstaller: false
- UsesSafeMode: false
- SupportsDefault: false
- SupportsRestore: false
- NeedsExplicitConfirmation: true

## Rollback, Default, and Restore Behavior

Default remains unavailable because the source does not define a DirectX default
branch. Restore remains unavailable because this phase does not introduce a
captured-state restore contract for downloaded artifacts, installer side
effects, HKCU values, Start Menu changes, extracted files, or DirectX setup
state.

## Restart Behavior

BoostLab does not request a reboot. The launched DirectX setup UI may present
its own prompts; that behavior is outside BoostLab's reboot workflow.

## Test Requirements

Tests must verify source identity, read-only Analyze, the exact source operation
order, confirmed Apply with mocked operations, fail-closed operation errors,
unavailable Open/Default/Restore surface, external artifact source
classification, no production artifact approval, no production allowlist entry,
unchanged protected sources, async UI coverage, and ordered parity advancement
to Visual C++.

## Yazan Approval Status

Phase 129 treats DirectX as Yazan-accepted near parity: the source-equivalent
workflow is available behind BoostLab confirmation and test-safe mechanics, with
artifact sources still tracked as author-hosted `NeedsBoostLabMirror` entries.
