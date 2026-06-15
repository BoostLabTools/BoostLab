# Visual C++ Artifact Provenance Review

## Phase 46 Decision

Visual C++ remains a refused placeholder. Phase 46 does not add artifact
records, implement `Analyze` or `Apply`, enable downloads, launch installers,
or change the current Visual C++ module.

The complete Ultimate workflow cannot pass the Phase 35 provenance and
installer execution policy with the evidence available in the repository.

## Source Reference

* Tool id: `visual-cpp`
* Source path: `source-ultimate/5 Graphics/3 C++.ps1`
* Source SHA-256:
  `7ACB1F25ECFEEAD83FA389E2D0C1FEEF12232C4E9A740CB5DE64A326FFD38C09`

## Ultimate Package Set and Order

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

Every source URL uses this mutable mirror pattern:

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

## Why Implementation Was Refused

All twelve source URLs use `refs/heads/main`. They are mutable branch
references, not immutable Microsoft release URLs, immutable GitHub release
assets, or commit-pinned content URLs. A hash measured from one response would
not establish that the same URL remains bound to those bytes.

The repository does not provide the required evidence for any package:

* Exact SHA-256.
* Exact file size or reviewed size bounds.
* Verified Authenticode status and expected Microsoft publisher/signer.
* Authoritative source and package-version evidence.
* License and redistributability evidence for the mirrored executable.
* An approved artifact record tied to `visual-cpp`.
* An approved installer request containing the exact source switch.
* Approved exit-code interpretation for success, already installed,
  reboot-required, and failure outcomes.
* Approved ownership and cleanup rules for each generated temp file.

The Phase 35 installer helper is intentionally inert. A valid request returns
`NotImplemented` and `ProcessStarted = false`. The Visual C++ module must not
bypass that boundary with direct `Start-Process` calls.

Approving only newer redistributables, replacing the workflow with `winget`,
using different Microsoft download pages, changing package names or switches,
or omitting architectures would not preserve the approved Ultimate package
list and operation order.

## Production State

* `config/ArtifactProvenance.psd1` remains empty.
* No real Visual C++ redistributable is approved.
* `modules/Graphics/visual-cpp.psm1` remains a placeholder.
* No Visual C++ migration record is created because the tool is not
  implemented.
* No download, installer launch, registry change, temp-file cleanup, or Visual
  C++ installation-state change is enabled by Phase 46.

## Required Approval Package for a Future Retry

A future phase must provide all of the following for every one of the twelve
source-defined packages:

1. An immutable authoritative or commit-pinned source URL.
2. Exact file name, SHA-256, size, package version, architecture, Authenticode
   signer, publisher, license, and redistributability evidence.
3. A reviewed artifact record with `SourceToolIds = @('visual-cpp')` and an
   explicit approval status.
4. An exact installer request preserving the source-defined switch and
   operation order.
5. Explicit Action Plan confirmation and bounded timeout behavior.
6. Exit-code capture and approved interpretation for each package.
7. Exact generated-temp-path ownership, state, verification, and cleanup
   rules.
8. Mocked tests for missing or mismatched artifacts, invalid signatures,
   installer failures, reboot-required exit codes, and partial completion.
9. A separately approved installer execution implementation that does not
   weaken the Phase 35 verified-path and confirmation requirements.

Until the complete twelve-artifact approval package exists, Visual C++ remains
disabled and visual-only.
