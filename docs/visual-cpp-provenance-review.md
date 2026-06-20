# Visual C++ Artifact Provenance Review

## Source Reference

* Tool id: `visual-cpp`
* Source path: `source-ultimate/5 Graphics/3 C++.ps1`
* Source SHA-256:
  `7ACB1F25ECFEEAD83FA389E2D0C1FEEF12232C4E9A740CB5DE64A326FFD38C09`

## Current Decision

Phase 46 refused reusable artifact-provenance approval because the source
downloads twelve redistributables from mutable Ultimate-author mirror URLs and
the repository had no exact hashes, sizes, signers, package versions, license
evidence, or installer execution descriptors.

Phase 101 implemented controlled manual handoff only.

Phase 130 supersedes the manual-handoff-only runtime with
source-equivalent controlled behavior accepted by Yazan as near parity. Visual
C++ Apply now preserves the source workflow behind explicit BoostLab
confirmation and test-safe executor injection. This does not approve reusable
artifact provenance, a BoostLab mirror, or URL substitution.

## Ultimate Package Set And Order

The source requires Administrator rights and internet connectivity. It
downloads all twelve executables to `%SystemRoot%\Temp` before launching any
installer:

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

Every source URL uses:

`https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/<file>`

The source then waits for each installer in this exact order:

1. 2005 x86 with `/q`
2. 2005 x64 with `/q`
3. 2008 x86 with `/qb`
4. 2008 x64 with `/qb`
5. 2010 x86 with `/passive /norestart`
6. 2010 x64 with `/passive /norestart`
7. 2012 x86 with `/passive /norestart`
8. 2012 x64 with `/passive /norestart`
9. 2013 x86 with `/passive /norestart`
10. 2013 x64 with `/passive /norestart`
11. 2015/2017/2019/2022 x86 with `/passive /norestart`
12. 2015/2017/2019/2022 x64 with `/passive /norestart`

The source does not remove the downloaded executables afterward.

## External Source Classification

`config/ExternalArtifactSources.psd1` records all twelve Visual C++ installer
URLs as:

* `SourceClassification = UltimateAuthorHostedArtifact`
* `MirrorStatus = NeedsBoostLabMirror`
* `ExpectedSha256 = $null`
* `IntendedBoostLabMirrorUrl = $null`

These entries classify source URLs only. They are not artifact approvals.

## Production State

* `config/ArtifactProvenance.psd1` remains empty.
* No real Visual C++ redistributable is approved as a reusable BoostLab
  artifact.
* No binary file is committed.
* No production allowlist entry is added.
* Runtime URLs remain the exact source URLs.
* BoostLab does not invent package substitutions, `winget`, alternate Microsoft
  pages, alternate switches, cleanup, Default, Restore, or reboot behavior.

## Future Mirror Or Restore Work

A future mirror/provenance phase would still need exact SHA-256, size, package
version, Authenticode signer, redistributability evidence, BoostLab mirror
approval, installer exit-code rules, timeout behavior, and generated-temp-path
ownership for every package.

A future Restore phase would require selected captured package/file/registry
state and an approved restore contract. Phase 130 does not enable Restore.
