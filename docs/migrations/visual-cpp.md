# Visual C++ Migration Record

## Identity

- Tool name: Visual C++
- Tool id: `visual-cpp`
- Stage: Graphics
- Module: `modules/Graphics/visual-cpp.psm1`
- Source script path: `source-ultimate/5 Graphics/3 C++.ps1`
- Source SHA-256: `01D6A5FAFD5E7C1FB9DA1913BD17C543EE0F8A4A7E2A7DF5583A50AEF1D82374`

## Original Ultimate Behavior

The Ultimate script requires Administrator rights and internet access, sets
`$progresspreference = 'silentlycontinue'`, prints `Downloading: C++...`,
downloads twelve Visual C++ redistributable executables from
`https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/` into
`%SystemRoot%\Temp`, prints `Installing: C++...`, then launches each installer
with `Start-Process -Wait`.

Download order:

1. `vcredist2005_x64.exe`
2. `vcredist2005_x86.exe`
3. `vcredist2008_x64.exe`
4. `vcredist2008_x86.exe`
5. `vcredist2010_x64.exe`
6. `vcredist2010_x86.exe`
7. `vcredist2012_x64.exe`
8. `vcredist2012_x86.exe`
9. `vcredist2013_x64.exe`
10. `vcredist2013_x86.exe`
11. `vcredist2015_2017_2019_2022_x64.exe`
12. `vcredist2015_2017_2019_2022_x86.exe`

Installer order and arguments:

1. `vcredist2005_x86.exe` `/q`
2. `vcredist2005_x64.exe` `/q`
3. `vcredist2008_x86.exe` `/qb`
4. `vcredist2008_x64.exe` `/qb`
5. `vcredist2010_x86.exe` `/passive /norestart`
6. `vcredist2010_x64.exe` `/passive /norestart`
7. `vcredist2012_x86.exe` `/passive /norestart`
8. `vcredist2012_x64.exe` `/passive /norestart`
9. `vcredist2013_x86.exe` `/passive /norestart`
10. `vcredist2013_x64.exe` `/passive /norestart`
11. `vcredist2015_2017_2019_2022_x86.exe` `/passive /norestart`
12. `vcredist2015_2017_2019_2022_x64.exe` `/passive /norestart`

The source defines no standalone Open branch, no Default branch, no Restore
branch, no cleanup, and no reboot command.

## Approved BoostLab Behavior

Phase 130 replaces the earlier manual-handoff implementation with a
source-equivalent controlled runtime:

- `Analyze`: read-only source identity, artifact-source classification, and
  operation-plan analysis.
- `Apply`: after explicit Action Plan confirmation, verifies the source
  checksum, verifies Administrator and internet requirements, downloads all
  twelve source-defined installers to `%SystemRoot%\Temp`, and runs all twelve
  installers sequentially with the exact source switches.
- `Open`: not exposed; unsupported if called internally.
- `Default`: unavailable because the source defines no Default branch.
- `Restore`: unavailable until a future selected captured-state restore
  contract exists.

## Artifact Source Policy

All twelve source URLs remain unchanged at runtime. They are recorded in
`config/ExternalArtifactSources.psd1` as `UltimateAuthorHostedArtifact` with
`NeedsBoostLabMirror`.

No binary was added to the repository. No `config/ArtifactProvenance.psd1`
approval, production allowlist entry, BoostLab mirror, hash approval, or URL
substitution was added.

## Safety And Execution

The GUI Action Plan requires confirmation before Apply. Long-running execution
uses the shared async dispatcher. Tests use injected operation executors and do
not download, install, launch external processes, mutate registry/package state,
or reboot.

## Default And Restore

Default is unavailable because the source does not define a Default branch.
Restore is unavailable until BoostLab has selected captured prior state and an
approved restore contract. Default is not Restore.

## Yazan Approval Status

Phase 130 marks Visual C++ as `NearParityControlled` /
`DoneYazanAcceptedNearParity`: BoostLab preserves the practical Ultimate
workflow behind GUI confirmation and test-safe seams, while leaving reusable
artifact provenance, BoostLab mirror substitution, and Restore unapproved.
