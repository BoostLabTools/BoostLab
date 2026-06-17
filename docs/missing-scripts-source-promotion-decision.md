# Missing Scripts Source Promotion Decision

## Purpose

Phase 71 records the source-promotion decision for the seven missing Ultimate scripts currently held in:

`intake/missing-ultimate-scripts/Ultimate/`

Phase 72 completed the approved source-promotion mirror copy under `source-ultimate/_intake-promoted/Ultimate/`.

This phase was source-reference promotion only. Phase 92 later promoted Driver
Clean into an active controlled manual-handoff implementation without approving
DDU/7-Zip artifacts, downloads, execution, Safe Mode, RunOnce, reboot, or
driver cleanup behavior. Phase 93 later promoted Driver Install Latest into an
active controlled manual-handoff implementation, and Phase 94 promoted Nvidia
Settings into an active controlled manual-handoff implementation. Neither phase
approved NVIDIA driver downloads, installer execution, 7-Zip download/install,
NVIDIA Profile Inspector download/execution, `.nip` import/export, external
process launch, registry/profile/system mutation, Control Panel launch, reboot,
or session change. Phase 95 promoted HDCP as Path B step 3 with controlled
NVIDIA-only registry targeting, pre-change registry state capture, verification,
and source-defined Apply/Default behavior only.

## Counts

Current BoostLab counts after Phase 95:

* Active tools: **52**
* Implemented tools: **34**
* Deferred/placeholders: **18**
* Intake files: **7**
* Source-promoted mirror files: **7**
* Remaining unimplemented source-promoted intake candidates: **3 separate from official counts**

## Phase 72 Mirror Promotion Status

Strategy C mirror promotion is completed.

The approved mirror now exists under:

`source-ultimate/_intake-promoted/Ultimate/`

Promoted mirror paths:

* `source-ultimate/_intake-promoted/Ultimate/5 Graphics/1 Driver Clean.ps1`
* `source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1`
* `source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1`
* `source-ultimate/_intake-promoted/Ultimate/5 Graphics/5 Hdcp.ps1`
* `source-ultimate/_intake-promoted/Ultimate/5 Graphics/6 P0 State.ps1`
* `source-ultimate/_intake-promoted/Ultimate/5 Graphics/7 Msi Mode.ps1`
* `source-ultimate/_intake-promoted/Ultimate/3 Setup/1 BitLocker.ps1`

Driver Clean was promoted in Phase 92 as a controlled manual-handoff tool.
Driver Install Latest was promoted in Phase 93 as Path B step 1 controlled
manual handoff only. Nvidia Settings was promoted in Phase 94 as Path B step 2
controlled manual handoff only. HDCP was promoted in Phase 95 as Path B step 3
controlled registry behavior with NVIDIA-only targeting and capture before
mutation. The remaining three source-promoted scripts remain separate from official
active/deferred BoostLab tools until a future catalog/placeholder phase
explicitly changes `config/Stages.psd1` and module scaffolding.

## Promotion Decision Table

| Intake script | Current SHA-256 | Current classification | Source-promotion decision | Future proposed `source-ultimate` destination | Preserve original filename | Numbering conflict exists | Promotion allowed now | Required future design/review before implementation |
|---|---|---|---|---|---|---|---|---|
| `intake/missing-ultimate-scripts/Ultimate/5 Graphics/1 Driver Clean.ps1` | `CF9E1C55ACAFD8A52D2200AC3E6C3AFDF9823837C7B68101C2D4B83E074D325A` | Yazan-approved intake exception for future source promotion | Source-promoted into mirror; Phase 92 implemented controlled manual handoff only | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/1 Driver Clean.ps1` | Yes | Yes, conflicts with previous Graphics slot 1 | Implemented as active controlled manual handoff | Auto remains blocked until DDU/7-Zip artifact/download/execution policy, driver cleanup scope, Safe Mode/RunOnce/reboot workflow, process handling, and file/registry/cleanup/driver state capture and rollback approvals exist |
| `intake/missing-ultimate-scripts/Ultimate/5 Graphics/2 Driver Install Latest.ps1` | `41C9DEA9AA5D208C9ED1EB7F1512B24251FBF4DC01C6DE2858B5B1A26C631A2F` | Intake accepted for future source promotion | Implemented as controlled manual handoff only in Phase 93; Auto blocked | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1` | Yes | Yes, resolved by adding an explicit Graphics order 2 tool and moving Path A to order 3 | Active manual handoff only; no automated NVIDIA download/install behavior approved | NVIDIA-only branch design; download provenance; installer execution policy; driver operation scope; AMD/Intel branch exclusion; Path B workflow design |
| `intake/missing-ultimate-scripts/Ultimate/5 Graphics/4 Nvidia Settings.ps1` | `903F2C1E9965795E3B5C60ABD123A1B4F364A33F783BFFC681FBCB37BCE9E6D5` | Intake accepted for future source promotion | Implemented as controlled manual handoff only in Phase 94; Auto blocked | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1` | Yes | Yes, resolved by adding an explicit Graphics order 3 tool and moving Path A to order 4 | Active manual handoff only; no automated 7-Zip/Profile Inspector/.nip/registry/profile behavior approved | NVIDIA profile/settings design; NVIDIA Profile Inspector provenance; `.nip` generated artifact policy; registry/file capture; Default/Restore distinction; Path B workflow design |
| `intake/missing-ultimate-scripts/Ultimate/5 Graphics/5 Hdcp.ps1` | `5C350D28F795D678051E6088F34968DF8D90B3D9024F558C5FAFB2899D1A906A` | Intake accepted for future source promotion | Implemented as controlled NVIDIA-only registry behavior in Phase 95 | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/5 Hdcp.ps1` | Yes | No direct current file conflict; active Graphics order 4 is now HDCP and Path A shifted to order 5 | Active controlled registry implementation; no external process/download/reboot behavior approved | Restore remains unavailable without selected captured state; P0 State and Msi Mode remain unimplemented |
| `intake/missing-ultimate-scripts/Ultimate/5 Graphics/6 P0 State.ps1` | `382DFEC45B5C8F1D00388CFEFF38187517188EC0139DA751B42DEB1BEA4358EC` | Intake accepted for future source promotion | Source-promoted into mirror, not implemented | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/6 P0 State.ps1` | Yes | No direct current file conflict, but Graphics catalog has no official slot 6 today | Completed in mirror only; catalog promotion still separate | NVIDIA display-class registry target discovery; registry state capture; verification; Default/Restore distinction; Path B workflow design |
| `intake/missing-ultimate-scripts/Ultimate/5 Graphics/7 Msi Mode.ps1` | `94F5A99232333985F6855C9000BD94FA1067D9152885AF84FBECB6E0C1807BF7` | Intake accepted for future source promotion | Source-promoted into mirror, not implemented | `source-ultimate/_intake-promoted/Ultimate/5 Graphics/7 Msi Mode.ps1` | Yes | No direct current file conflict, but Graphics catalog has no official slot 7 today | Completed in mirror only; catalog promotion still separate | NVIDIA-only device targeting design; display-device registry state capture; verification; AMD/Intel exclusion; Default/Restore distinction; Path B workflow design |
| `intake/missing-ultimate-scripts/Ultimate/3 Setup/1 BitLocker.ps1` | `1678E97FB5AFF851F1491A2D96C82A5716B1FA07CB4E3A4A5E0F3FB1B086FBA1` | Intake accepted for future source promotion | Source-promoted into mirror, not implemented | `source-ultimate/_intake-promoted/Ultimate/3 Setup/1 BitLocker.ps1` | Yes | Yes, conflicts with current Setup slot 1 | Completed in mirror only; catalog promotion still separate | Security-sensitive design; BitLocker state/volume analysis; explicit confirmation; recovery-key warning; no mutation without approved security workflow; Default/Restore distinction |

## Driver Clean Decision

Driver Clean is accepted for future source promotion as a Yazan-approved intake exception despite DDU usage.

This does not approve standalone DDU, DDU execution, DDU download, or DDU artifact provenance.

This decision does not approve:

* standalone DDU as an independent BoostLab tool
* DDU execution
* DDU download
* DDU artifact provenance
* DDU installer/tool execution policy
* Driver Clean implementation
* driver cleanup behavior
* Safe Mode, RunOnce, reboot, process, file, registry, cleanup, driver, Default, or Restore production scopes

Phase 92 implemented Driver Clean manual handoff only. Auto still requires
dedicated Driver Clean scope/provenance/safety design before implementation.
That future design must explicitly address DDU provenance, DDU execution, Safe
Mode, RunOnce, reboot, downloaded artifacts, driver cleanup scope, AMD/Intel
exclusions, state capture, verification, and rollback/support limits.

## NVIDIA App Path B Decision

The following five scripts form **NVIDIA App Path B** and must preserve their exact methodological order:

1. `Driver Install Latest`
2. `Nvidia Settings`
3. `Hdcp`
4. `P0 State`
5. `Msi Mode`

Path relationship:

* Path A: `Driver Install Debloat & Settings`
* Path B: `Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode`

Path B is an alternate NVIDIA workflow for users who want to keep or use NVIDIA App features such as recording or related NVIDIA App features.

Future UI must present Path A and Path B as mutually guided workflows. Future UI must warn against and prevent accidental workflow mixing unless a later explicit design approves a safe mixed workflow. The five Path B scripts must not be treated as unordered graphics tools.

## BitLocker Decision

BitLocker is accepted as a future source-promotion candidate.

BitLocker requires security-sensitive design before implementation. This phase does not approve BitLocker mutation, encryption/decryption, suspend/resume, registry changes, service changes, policy operations, or any live BitLocker command execution.

Future BitLocker design must address volume state detection, recovery-key risk, technician warnings, user confirmation, logging, verification, support boundaries, and the distinction between source-defined On/Off behavior and BoostLab `Default` or `Restore` semantics.

## Source-Order Reconciliation Strategy

Current `source-ultimate` layout creates numbering conflicts:

* `source-ultimate/5 Graphics/1 Driver Install Debloat & Settings.ps1` already occupies Graphics slot 1.
* `source-ultimate/5 Graphics/2 DirectX.ps1` already occupies Graphics slot 2.
* `source-ultimate/5 Graphics/4 Graphics Configuration Center.ps1` already occupies Graphics slot 4.
* `source-ultimate/3 Setup/1 Memory Compression.ps1` already occupies Setup slot 1.

Reviewed strategies:

| Strategy | Description | Result |
|---|---|---|
| A | Preserve intake original numbers directly in existing `source-ultimate` stage folders and later renumber existing files. | Not recommended. This has high breakage risk for docs/tests and makes existing approved source paths unstable. |
| B | Assign new non-conflicting numbers directly inside current stage folders while preserving workflow metadata separately. | Not recommended. This minimizes path conflicts but weakens the original Ultimate source identity and makes Path B source order less obvious. |
| C | Preserve original filenames in a source-promotion mirror subfolder under `source-ultimate`. | Recommended. This preserves the intake filenames and Path B order without renumbering existing approved source files. |
| D | Keep scripts permanently in `intake/` only. | Not recommended as the final state if Yazan wants them treated as official legacy source references later. Useful only until a source-promotion phase occurs. |

Recommended strategy: **Strategy C**.

Future source promotion should preserve original filenames inside:

`source-ultimate/_intake-promoted/Ultimate/`

This minimizes breakage to existing docs/tests because current approved source paths remain stable. It also preserves the mandatory NVIDIA Path B order through original filenames and future metadata, without forcing the active BoostLab catalog to adopt conflicting source numbers.

Phase 72 created that folder and copied the seven source-promoted mirror files with exact hash verification. Existing approved source files outside `_intake-promoted` remain protected by the legacy source manifest validators.

## Future Promotion Mechanics

Phase 72 promoted these seven scripts as source references only:

* `Driver Clean`
* `Driver Install Latest`
* `Nvidia Settings`
* `Hdcp`
* `P0 State`
* `Msi Mode`
* `BitLocker`

No script is excluded from future source promotion by this decision. Driver Clean remains an explicit intake exception, not a DDU approval.

Proposed future destination paths:

* `source-ultimate/_intake-promoted/Ultimate/5 Graphics/1 Driver Clean.ps1`
* `source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1`
* `source-ultimate/_intake-promoted/Ultimate/5 Graphics/4 Nvidia Settings.ps1`
* `source-ultimate/_intake-promoted/Ultimate/5 Graphics/5 Hdcp.ps1`
* `source-ultimate/_intake-promoted/Ultimate/5 Graphics/6 P0 State.ps1`
* `source-ultimate/_intake-promoted/Ultimate/5 Graphics/7 Msi Mode.ps1`
* `source-ultimate/_intake-promoted/Ultimate/3 Setup/1 BitLocker.ps1`

Docs/tests updated for this mirror phase:

* legacy source manifest validators continue to protect the original 49-file tree outside `_intake-promoted`
* `tests/Test-MissingScriptsSourcePromotionMirror.ps1` validates all seven mirror files and intake originals by SHA-256
* intake and source-promotion decision validators recognize the mirror as source-reference promotion only
* `docs/missing-ultimate-scripts-intake-review.md`
* `docs/deferred-tools-execution-plan.md`
* `docs/deferred-tool-readiness-review.md`
* `docs/final-deferred-tools-readiness-matrix.md`
* `CODEX_INSTRUCTIONS.md` and `BOOSTLAB_BLUEPRINT.md` if the promoted source layout becomes official policy

Count handling:

* Active/implemented/deferred tool counts should not change from source promotion alone.
* Counts should change only if a later catalog phase adds active tools/placeholders to `config/Stages.psd1` and modules.
* Intake candidate count should either become promoted-source-reference count or remain separately documented until catalog promotion.

Rollback plan if source promotion mapping is wrong:

1. Do not implement or enable any promoted script in the same phase as source promotion.
2. Keep original intake copies unchanged until the promoted-source mapping is validated.
3. If mapping is wrong, remove only the newly promoted mirror files from the source-promotion branch before commit.
4. Re-run source manifest, intake, deleted-tool, module, and count validators.
5. Do not alter existing approved `source-ultimate` files to repair a promotion mapping mistake.

## Explicit Non-Actions

This phase made source-promotion mirror filesystem changes only under `source-ultimate/_intake-promoted/Ultimate/`.

* No existing `source-ultimate` files outside `_intake-promoted` were modified.
* Seven mirror files were created under `source-ultimate/_intake-promoted/Ultimate/`.
* No intake files were renamed or moved.
* No tool was implemented.
* No placeholder was enabled.
* No runtime behavior changed.
* No production approval was added.
* No DDU execution, DDU download, or DDU artifact approval was added.
* Standalone DDU was not introduced.
* Loudness EQ and NVME Faster Driver remain deleted.

## Recommended Next Phase

Recommended next phase: **NVIDIA Path B Catalog Design**.

That phase should decide whether and how Path B appears in the BoostLab catalog/UI as guided, non-mixed workflow planning. It should still avoid implementation, runtime changes, downloads, driver operations, and production approvals unless Yazan explicitly expands the phase.

Phase 73 records that catalog/UI planning in `docs/nvidia-path-b-catalog-design.md`. It preserves the required five-step Path B order as catalog metadata only and does not implement or enable any source-promoted script.

Phase 74 records the corresponding non-executing Path B scope design in `docs/tool-designs/nvidia-path-b-scope-design.md`.

