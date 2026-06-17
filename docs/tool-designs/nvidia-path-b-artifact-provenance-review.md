# NVIDIA Path B Artifact Provenance Review

## Purpose And Status

Phase 76 reviews artifact provenance for the five NVIDIA App Path B scripts.

This is provenance review only.

No artifact is approved. No download is approved. No installer execution is approved.
No production provenance config was changed. No implementation, placeholder,
tool card, executable module, runtime workflow config, or runtime behavior
change was added.

NVIDIA App Path B order remains:

`Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`

Path relationship:

* Path A: `Driver Install Debloat & Settings`
* Path B: `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`

Path B is for users who want to keep or use NVIDIA App features such as
recording or related NVIDIA App features. Path A and Path B remain mutually
guided workflows, and accidental mixing remains blocked unless a later explicit
design approves otherwise.

## Provenance Status Values

This review uses only non-approved statuses:

* `NotApproved`
* `NeedsOfficialSource`
* `NeedsPinnedVersion`
* `NeedsImmutableURL`
* `NeedsSHA256`
* `NeedsSignerValidation`
* `NeedsSizeBounds`
* `NeedsDestinationBounds`
* `NeedsExtractionPolicy`
* `NeedsInstallerDescriptor`
* `NeedsProfileImportModel`
* `NeedsGeneratedArtifactPolicy`
* `RejectedMutableSource`
* `RejectedUnknownSource`

Do not use `Approved` for Path B artifacts in this phase.

## Source Files Reviewed

| Step | Script name | Source mirror path | Intake source path | SHA-256 |
|---:|---|---|---|---|
| 1 | Driver Install Latest | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1` | `intake/missing-ultimate-scripts/Ultimate/5 Graphics/2 Driver Install Latest.ps1` | `41C9DEA9AA5D208C9ED1EB7F1512B24251FBF4DC01C6DE2858B5B1A26C631A2F` |
| 2 | Nvidia Settings | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1` | `intake/missing-ultimate-scripts/Ultimate/5 Graphics/4 Nvidia Settings.ps1` | `903F2C1E9965795E3B5C60ABD123A1B4F364A33F783BFFC681FBCB37BCE9E6D5` |
| 3 | Hdcp | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/5 Hdcp.ps1` | `intake/missing-ultimate-scripts/Ultimate/5 Graphics/5 Hdcp.ps1` | `5C350D28F795D678051E6088F34968DF8D90B3D9024F558C5FAFB2899D1A906A` |
| 4 | P0 State | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/6 P0 State.ps1` | `intake/missing-ultimate-scripts/Ultimate/5 Graphics/6 P0 State.ps1` | `382DFEC45B5C8F1D00388CFEFF38187517188EC0139DA751B42DEB1BEA4358EC` |
| 5 | Msi Mode | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/7 Msi Mode.ps1` | `intake/missing-ultimate-scripts/Ultimate/5 Graphics/7 Msi Mode.ps1` | `94F5A99232333985F6855C9000BD94FA1067D9152885AF84FBECB6E0C1807BF7` |

## Source Artifact Inventory

| Step | Script name | Artifact label | Source evidence | URL or source locator | Source type | Artifact type | Expected file type | Source appears | Version pinned | Hash pinned | Signer/publisher specified | Size bounded | Destination path bounded | Extraction required | Execution required | Import/profile application required | Provenance status | Reason not approved | Future approval requirements |
|---:|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Driver Install Latest | NVIDIA driver lookup API | `Invoke-WebRequest -Uri $uri`; `ConvertFrom-Json` | `https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?...` | HTTPS API | Metadata/source locator | JSON response | Official NVIDIA-looking dynamic API | No; latest result is dynamic | No | No | No | Not applicable | No | No | No | NeedsPinnedVersion; NeedsOfficialSource | API may be official but produces dynamic latest metadata without pinned artifact evidence | Authoritative source proof, stable schema expectations, version pinning or reviewed dynamic-update policy, failure handling |
| 1 | Driver Install Latest | NVIDIA driver installer | `$url = "https://international.download.nvidia.com/Windows/$version/..."`; `IWR $url -OutFile "$env:SystemRoot\Temp\nvidiadriver.exe"` | `https://international.download.nvidia.com/Windows/$version/$version-desktop-$windowsVersion-$windowsArchitecture-international-dch-whql.exe` | HTTPS download | Installer | `.exe` | Official NVIDIA-looking dynamic download | No; version comes from live API | No | No | No | Yes, `%SystemRoot%\Temp\nvidiadriver.exe` | No | Yes | No | NeedsPinnedVersion; NeedsSHA256; NeedsSignerValidation; NeedsSizeBounds; NeedsInstallerDescriptor | Dynamic latest installer cannot satisfy current deny-by-default provenance without exact reviewed version/hash/signer/size and execution descriptor | Pinned version or approved dynamic provenance model, SHA-256, signer/publisher, size, destination, installer command, exit/handoff behavior, rollback/reboot plan |
| 1 | Driver Install Latest | AMD driver web installer branch | Source AMD branch `Invoke-WebRequest` and `IWR $DownloadAmd.href` | `https://www.amd.com/en/support/download/drivers.html` and `drivers.amd.com/...minimalsetup..._web.exe` | HTTPS page scrape/download | Installer | `.exe` | Official AMD-looking but outside product scope | No | No | No | No | Yes, `%SystemRoot%\Temp\amddriver.exe` | No | Yes | No | RejectedUnknownSource; NotApproved | AMD GPU-specific branch is outside BoostLab NVIDIA-only product scope for this workflow | No future Path B approval unless Yazan expands GPU scope |
| 1 | Driver Install Latest | Intel driver page branch | Source Intel branch `Start-Process "https://www.intel.com/..."` | Intel driver search page URL | Browser handoff | Web page | URL | Official Intel-looking but outside product scope | No | No | No | No | Not applicable | No | Browser handoff only | No | NotApproved | Intel GPU-specific branch is outside BoostLab NVIDIA-only product scope for this workflow | No future Path B approval unless Yazan expands GPU scope |
| 2 | Nvidia Settings | 7-Zip installer | `IWR ".../7zip.exe" -OutFile "$env:SystemRoot\Temp\7zip.exe"`; `Start-Process -Wait ... /S` | `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/7zip.exe` | GitHub raw branch URL | Installer | `.exe` | Third-party mirror, mutable branch | No | No | No | No | Yes, `%SystemRoot%\Temp\7zip.exe` | No | Yes | No | RejectedMutableSource; NeedsSHA256; NeedsSignerValidation; NeedsInstallerDescriptor | Mutable `refs/heads/main` URL has no pinned hash, size, signer, license, or installer descriptor | Immutable authoritative source or approved mirror evidence, SHA-256, signer, size, license, execution descriptor, exit-code policy, destination bounds |
| 2 | Nvidia Settings | NVIDIA Profile Inspector executable | `IWR ".../inspector.exe" -OutFile "$env:SystemRoot\Temp\inspector.exe"`; `Start-Process -wait ... -silentImport` | `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/inspector.exe` | GitHub raw branch URL | Executable/tool | `.exe` | Third-party mirror, mutable branch | No | No | No | No | Yes, `%SystemRoot%\Temp\inspector.exe` | No | Yes | Yes | RejectedMutableSource; NeedsSHA256; NeedsSignerValidation; NeedsProfileImportModel | Mutable `refs/heads/main` URL has no pinned hash, size, signer, license, or profile-import verification model | Immutable authoritative source or approved mirror evidence, SHA-256, signer, size, license, execution descriptor, timeout, profile state capture, import verification |
| 2 | Nvidia Settings | Generated NVIDIA Profile Inspector profile | `Set-Content -Path "$env:SystemRoot\Temp\inspector.nip" -Value $nipfile -Force` | Generated locally from embedded XML | Generated payload | Profile import file | `.nip` XML | Generated local file | Content is source-defined but not separately versioned | Source checksum exists, but generated output hash is not separately declared | Not applicable | Not declared | Yes, `%SystemRoot%\Temp\inspector.nip` | No | No direct execution; consumed by Inspector | Yes | NeedsGeneratedArtifactPolicy; NeedsProfileImportModel | Generated profile ownership, hash, retention/cleanup, and import effects are not approved | Exact generated content hash, destination bounds, ownership metadata, profile capture, rollback/restoration model, import verification |
| 2 | Nvidia Settings | NVIDIA Control Panel launch | `Start-Process "shell:appsFolder\NVIDIACorp.NVIDIAControlPanel_..."` | `shell:appsFolder\NVIDIACorp.NVIDIAControlPanel_56jybvy8sckqj!NVIDIACorp.NVIDIAControlPanel` | Local app URI | Local UI launcher | App URI | Local NVIDIA app package reference | Package version not pinned | No | Package identity partially specified | Not applicable | Not applicable | No | Launch required by source | No | NotApproved; NeedsProfileImportModel | Local UI launch is not an external artifact, but still needs process/UI handoff policy if preserved | Exact app identity expectations, launch result handling, NotApplicable behavior if missing, Activity Log/Latest Result reporting |
| 3 | Hdcp | External artifact dependency | Source contains no URL, download, archive, external executable download, installer, or generated payload | None | None | None | None | No external artifact dependency detected from source text | Not applicable | Not applicable | Not applicable | Not applicable | Not applicable | No | No | No | NotApproved | Non-artifact registry scope is handled by registry/driver design, not artifact provenance | Future registry/driver allowlist and capture review, not artifact approval |
| 4 | P0 State | External artifact dependency | Source contains no URL, download, archive, external executable download, installer, or generated payload | None | None | None | None | No external artifact dependency detected from source text | Not applicable | Not applicable | Not applicable | Not applicable | Not applicable | No | No | No | NotApproved | Non-artifact registry scope is handled by registry/driver design, not artifact provenance | Future registry/driver allowlist and capture review, not artifact approval |
| 5 | Msi Mode | External artifact dependency | Source contains no URL, download, archive, external executable download, installer, or generated payload | None | None | None | None | No external artifact dependency detected from source text | Not applicable | Not applicable | Not applicable | Not applicable | Not applicable | No | No | No | NotApproved | Non-artifact device registry scope is handled by registry/driver design, not artifact provenance | Future registry/driver allowlist and capture review, not artifact approval |

## Driver Install Latest Provenance Review

Detected source references:

* NVIDIA driver lookup API:
  `https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?...`
* Dynamic NVIDIA driver installer URL:
  `https://international.download.nvidia.com/Windows/$version/$version-desktop-$windowsVersion-$windowsArchitecture-international-dch-whql.exe`
* Destination:
  `%SystemRoot%\Temp\nvidiadriver.exe`
* Execution:
  `Start-Process "%SystemRoot%\Temp\nvidiadriver.exe"`
* Unsupported source branches:
  AMD web installer download and Intel driver-page launch.

The NVIDIA URLs appear to use NVIDIA-controlled domains, but the source uses a
dynamic latest-driver flow. Version, URL, SHA-256, signer, and file size are
not pinned in the source. The source does not specify expected Authenticode
publisher, installer switches, exit codes, timeout, rollback, or reboot
behavior.

Future artifact approval would require:

* official source proof for the lookup API and download domain
* pinned driver version or an approved dynamic-provenance policy
* exact expected file name
* SHA-256
* signer/publisher validation
* file size bounds
* bounded destination path
* installer execution descriptor
* expected exit codes or handoff result model
* driver state capture and rollback/support plan
* reboot/session handling

No artifact, download, or install approval is added now because the current
source does not satisfy BoostLab's deny-by-default artifact provenance model.

## Nvidia Settings Provenance Review

Detected source references:

* 7-Zip installer:
  `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/7zip.exe`
* 7-Zip destination:
  `%SystemRoot%\Temp\7zip.exe`
* 7-Zip execution:
  `Start-Process -Wait "%SystemRoot%\Temp\7zip.exe" -ArgumentList "/S"`
* NVIDIA Profile Inspector executable:
  `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/inspector.exe`
* Inspector destination:
  `%SystemRoot%\Temp\inspector.exe`
* Generated profile:
  `%SystemRoot%\Temp\inspector.nip`
* Inspector import:
  `Start-Process -wait "%SystemRoot%\Temp\inspector.exe" -ArgumentList "-silentImport -silent %SystemRoot%\Temp\inspector.nip"`
* NVIDIA Control Panel launch:
  `shell:appsFolder\NVIDIACorp.NVIDIAControlPanel_56jybvy8sckqj!NVIDIACorp.NVIDIAControlPanel`

The 7-Zip and NVIDIA Profile Inspector downloads use GitHub raw
`refs/heads/main` URLs from a third-party mirror. These are mutable branch URLs,
not pinned immutable artifact references. The source does not provide
SHA-256 hashes, file sizes, signer/publisher requirements, license evidence,
or a provenance record for either executable.

The `.nip` profile is generated from embedded XML, but future BoostLab would
still need generated artifact ownership, content hashing, cleanup/retention
rules, profile state capture before import, profile import verification, and
rollback/restoration design.

No artifact, download, install, profile import, or NVIDIA Control Panel launch
approval is added now because the external executable sources are mutable and
the profile import model is not approved.

## Hdcp Provenance Review

No external artifact dependency detected from source text.

The script contains no URL, `Invoke-WebRequest`, `IWR`, `Start-BitsTransfer`,
`curl`, `wget`, `winget`, `choco`, archive download, external executable
download, installer launch, generated profile file, or artifact import.

The remaining behavior is non-artifact registry/driver scope:
`RMHdcpKeyglobZero` under NVIDIA display-class registry instances. That scope
belongs to future registry, driver, and possible security-sensitive review, not
to artifact approval.

## P0 State Provenance Review

No external artifact dependency detected from source text.

The script contains no URL, `Invoke-WebRequest`, `IWR`, `Start-BitsTransfer`,
`curl`, `wget`, `winget`, `choco`, archive download, external executable
download, installer launch, generated profile file, or artifact import.

The remaining behavior is non-artifact registry/driver scope:
`DisableDynamicPstate` under NVIDIA display-class registry instances. That
scope belongs to future registry, driver, power/thermal warning, and rollback
review, not to artifact approval.

## Msi Mode Provenance Review

No external artifact dependency detected from source text.

The script contains no URL, `Invoke-WebRequest`, `IWR`, `Start-BitsTransfer`,
`curl`, `wget`, `winget`, `choco`, archive download, external executable
download, installer launch, generated profile file, or artifact import.

The remaining behavior is non-artifact device registry scope:
`MSISupported` under display-device interrupt-management registry paths. That
scope belongs to future registry, driver/device identity, NVIDIA-only
targeting, and reboot-effect review, not to artifact approval.

## Artifact Approval Requirements

Before any Path B artifact can be approved, a future phase must document:

* immutable source URL or official source mechanism
* pinned version
* SHA-256
* signer/publisher validation
* file size bounds
* destination path bounds
* extraction destination bounds
* installer descriptor
* execution arguments
* expected exit codes
* preflight checks
* post-install verification
* rollback/recovery/handoff plan
* offline behavior
* UI disclosure
* Action Plan text
* Activity Log text
* Latest Result fields
* failure behavior

Missing any required artifact field keeps the artifact `NotApproved`.

## NVIDIA Profile Inspector And `.nip` Model Requirements

The source indicates NVIDIA Profile Inspector and `.nip` usage.

Future approval requires:

* approved Inspector provenance
* approved profile file provenance or generated profile ownership
* profile state capture before import
* rollback/restoration model
* verification after profile import
* user-visible warning
* no approval in this phase

The generated `.nip` content must be treated as a generated artifact with exact
content identity and ownership. The Profile Inspector import must be treated as
an external executable operation plus NVIDIA profile mutation.

## Generated Artifact And Temporary File Requirements

Future generated `.nip`, extracted archives, or temporary installer files must
be governed by:

* generated ownership metadata
* bounded temporary directory
* cleanup policy
* quarantine/retention rule
* hash/signature verification where applicable
* no broad temp cleanup
* no execution from untracked paths

Temporary paths such as `%SystemRoot%\Temp\nvidiadriver.exe`,
`%SystemRoot%\Temp\7zip.exe`, `%SystemRoot%\Temp\inspector.exe`, and
`%SystemRoot%\Temp\inspector.nip` must not become generic temp execution
permission.

## Relationship To Existing Foundations

This review connects to:

* Download Provenance and Installer Execution Policy
* Production Allowlist Governance
* Driver State Capture and Rollback
* File/Registry State Capture and Rollback
* Process Handling Policy
* Reboot/Recovery Workflow
* Restore Selection UI / Runtime
* NVIDIA Path B Production Allowlist Planning

The artifact review does not replace any of those foundations. It only records
which artifact and provenance questions must be resolved before future Path B
implementation can be considered.

## Explicit Non-Actions

Phase 76 is provenance review only.

* No source mirror files were changed.
* No intake files were changed.
* No legacy source-ultimate files were changed.
* No executable module was created.
* No tool or placeholder was enabled.
* No runtime behavior changed.
* No production provenance config was changed.
* No production allowlist, scope, artifact, download, installer, driver,
  profile write, AppX, service, task, process, cleanup, reboot,
  TrustedInstaller, Safe Mode, Default, or Restore approval was added.
* No production config or artifact approval config was created for Path B.
* No DDU execution, DDU download, or DDU artifact approval was added.
* Standalone DDU was not introduced.
* Loudness EQ and NVME Faster Driver remain deleted.
* Counts remain unchanged: 48 active tools, 30 implemented tools, 18
  deferred/placeholders, and 7 source-promoted intake candidates separate from
  official counts.

## Recommended Next Phase

Recommended next phase: **NVIDIA Profile State Capture Model**.

That phase should remain foundation/design-only unless Yazan explicitly
authorizes a narrower scope. It should define whether NVIDIA profile/DRS state
can be captured, verified, and restored well enough for future `Nvidia
Settings` and related Path B steps.

Phase 77 records that model in `docs/nvidia-profile-state-capture-model.md`.
It approves no profile capture, restore, import, export, Profile Inspector
execution, `.nip` operation, runtime behavior, or production scope.

Phase 78 records future Path A / Path B UI workflow design in
`docs/nvidia-path-b-ui-workflow-design.md`. It adds no UI implementation or
production approval.

Phase 79 records non-approved draft allowlist proposals in
`docs/tool-designs/nvidia-path-b-draft-allowlist-proposal.md`. Artifact-related
entries remain NeedsProvenance or other non-approved statuses.

Phase 80 records production approval gate design in
`docs/tool-designs/nvidia-path-b-production-approval-gate-design.md`. Artifact
entries remain unapproved until a later explicit artifact approval phase.
