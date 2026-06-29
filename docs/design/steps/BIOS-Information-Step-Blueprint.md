# AXIS BIOS Drivers & Downloads Step Content Record

Date: 2026-06-29
Scope: owner-approved Arabic content record only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the first AXIS first-use wizard script.

The approved customer-facing Arabic content in this document may be used only in a later explicitly approved UI implementation phase.

English customer-facing copy is not approved in this phase. English copy must be translated later from the approved Arabic content and remain reviewable before final implementation.

BoostLab config and module data may be used only for internal implementation mapping, such as technical IDs, stage order, runtime action mapping, capability metadata, diagnostics mapping, and implementation references.

This phase does not implement UI behavior, query BIOS data, wire the wizard into production UI, or change runtime contracts.

## Localization and Direction

This is Arabic-first AXIS content.

Arabic layout must be RTL and mirrored when implemented. English layout must be LTR.

Keep the mixed English technical title `BIOS Drivers & Downloads` readable in RTL context.

No customer-facing copy from BoostLab config or module descriptions is approved automatically.

## Global First-Use Wizard Interaction Decisions

Yazan's Phase 177C owner decisions apply globally to the AXIS first-use wizard:

- `Cancel` must not appear anywhere in the first-use wizard.
- No `Cancel` button may appear in any script, step, footer, or confirmation dialog.
- `Cancel` must not remain as a disabled or hidden customer-facing placeholder.
- Running/checking status must use a real runtime animation or effect when implemented.
- The `جاري التحقق` state must not use a static icon, static PNG, or static SVG.
- Runtime checking/completed visuals are allowed only as state animations/effects.
- The global no-script-icons decision remains active.

## Purpose

This document records the owner-approved Arabic customer content and interaction rules for the current first AXIS script.

The internal BoostLab tool remains `bios-information`, but the customer-facing step identity is owner-approved as `BIOS Drivers & Downloads`.

## Source Inspection

Static inspection only:

- `config/Stages.psd1`
- `modules/Check/BIOSInformation.psm1`
- `tests/Test-BIOSInformation.ps1`
- `ui/AxisFirstUseWizardPrototype.ps1`
- current AXIS design notes under `docs/design/`

No runtime BIOS query, Apply action, Open action, browser launch, firmware query, or host mutation was run for this document.

## Internal Implementation Mapping

These are technical facts from current BoostLab config/module state. They are not approved customer-facing copy unless explicitly listed in the owner-approved content sections below.

| Field | Internal value |
| --- | --- |
| Step ID | `bios-information` |
| Config title | `BIOS Information` |
| Internal stage | `Check` |
| Stage order | Stage 1 |
| Tool order in stage | 1 |
| Runtime tool ID | `bios-information` |
| Runtime module | `modules/Check/BIOSInformation.psm1` |
| Runtime type | `assistant` |
| Risk level | `low` |
| Config actions | `Analyze`, `Open` |
| Implemented module actions | `Analyze`, `Open` |
| Default support | No |
| Restore support | No |
| Reboot behavior | None |

Current config capability mapping:

- `RequiresAdmin = true`
- `RequiresInternet = true`
- all modification, download, install, driver, security, delete, reboot, Safe Mode, and TrustedInstaller capabilities are false
- `NeedsExplicitConfirmation = false`

## Technical Action Mapping

The runtime may retain the existing internal action shape, but the customer-facing AXIS UI for this step exposes only the owner-approved visible action.

| Runtime action | Current technical meaning | Customer-facing exposure |
| --- | --- | --- |
| `Analyze` | Runs read-only BIOS/motherboard/system analysis | Not customer-facing for this step |
| `Open` | Opens a motherboard-model-only web search when allowed by runtime | Customer-facing primary action, label `افتح` |

Do not expose `Analyze` as a customer-facing button for this step, even if it exists internally.

## Owner-Approved Arabic Customer Content

The following Arabic-first customer content is owner-approved by Yazan for this step.

| Surface | Owner-approved value |
| --- | --- |
| Visible step title | `BIOS Drivers & Downloads` |
| Visible stage label | `Check` |
| Arabic short subtitle/body | `تحميل التعريفات من صفحة اللوحة الام الرسمي` |
| Primary visible button label | `افتح` |
| Documentation button label | `التعليمات` |
| Arabic Continue/Next label | `التالي` |

Primary purpose:

- The customer is guided to open the official motherboard page and download the required motherboard drivers.

## Owner-Approved Information Panel

Show first information card: yes.

| Surface | Owner-approved value |
| --- | --- |
| Card title | `ما هو عليك تحميله كالاتي` |
| Card bullet 1 | `تعريف كرت الشبكة` |
| Card bullet 2 | `تعريف كرت الصوت` |

## Requirements Panel

Show requirements card: no.

No requirements panel text is approved or needed for this step.

## Owner-Approved Visible Actions

Only expose the `Open` customer action for this step.

The visible `افتح` button maps to the internal `Open` behavior for this step.

Do not expose `Analyze` as a customer-facing button.

The documentation button visible label is `التعليمات`.

The final documentation route, page, or behavior remains `PENDING_YAZAN_APPROVAL`.

## Back and Continue Behavior

Back button appears on this step.

Back is allowed because a separate simple introductory page will be designed later before the scripts.

Continue/Next appears on every script.

Arabic visible Continue label should be `التالي` when implemented.

Continue/Next must be disabled or visually inactive before the customer completes the step primary action flow.

After the primary action flow completes, Continue/Next becomes enabled and takes the customer to the next script.

After completion, do not auto-advance. Wait for the customer to press Continue/Next.

The exact Arabic Back label remains `PENDING_YAZAN_APPROVAL`.

## Global No-Cancel Rule

Cancel must not appear in this step.

Cancel must not appear in any future first-use wizard script or step.

Cancel must not appear in the customer-facing wizard footer.

Cancel must not appear in confirmation dialogs.

Later UI implementation must remove Cancel from the customer-facing wizard footer. Any older prototype or design note that described `Cancel` as part of the footer or button set is superseded by this owner decision.

## Documentation Acknowledgement Behavior

This step requires a checkbox, but not inline on the main screen.

The checkbox appears only inside a small confirmation dialog after the customer presses the primary button `افتح`.

The customer cannot continue the primary action from that dialog until checking the checkbox.

Checkbox text exactly as provided by Yazan:

`لقد قرات التعليمات`

The confirmation dialog must not include a Cancel button when implemented.

The dialog should provide only the minimum required continue/confirm path after acknowledgement.

The exact confirm/continue wording inside that dialog remains `PENDING_YAZAN_APPROVAL` unless Yazan separately approves it.

## Owner-Approved Support Panel

The previous Ready/status area becomes a reusable support panel for all scripts.

For this step, the visible support panel content is:

| Surface | Owner-approved value |
| --- | --- |
| Support panel title | `مساعدة` |
| Support panel body | `يمكنك التواصل مع اخصائي الدعم من خلال خادم الدسكورد الخاص بالمتجر` |

Do not show the old visible `Ready` wording to the customer in Arabic for this step.

Internally, the system may still have a ready state, but the visible customer panel is the support panel above.

## Owner-Approved Running and Completed State Behavior

When the customer confirms and starts the primary action:

- show a real animated loading/checking effect
- the animation must be a true moving animation/effect, not a static icon
- visible Arabic status title: `جاري التحقق`
- no description/body text for this state
- final placement is pending implementation, but it should be visually close to the primary action/status flow and must fit the approved `900 x 650` layout

When the primary action flow completes:

- replace the checking animation with a completed state indicator/effect
- the completed state may use a green completion-style effect or check-style completion motion when implemented
- it must be treated as a runtime completion status, not a decorative tool icon
- visible Arabic status title: `مكتمل`
- no description/body text for this state

`مكتمل` is the only customer-facing end state for this step.

Running/completed visuals are runtime status animations/effects. They are not static script icons, decorative step icons, PNG icons, SVG icons, WPF vector tool icons, or icon columns.

## Owner-Controlled Fields Still Pending

These fields remain pending owner approval:

| Field | Status |
| --- | --- |
| English title | `PENDING_YAZAN_APPROVAL` |
| English subtitle/body | Pending future translation after Arabic approval |
| English panel text | Pending future translation after Arabic approval |
| English button labels | Pending future translation after Arabic approval |
| English state titles | Pending future translation after Arabic approval |
| Arabic Back label | `PENDING_YAZAN_APPROVAL` |
| Confirmation dialog confirm/continue label | `PENDING_YAZAN_APPROVAL` |
| Documentation route/page/behavior | `PENDING_YAZAN_APPROVAL` |
| Final checking/completed animation placement | Pending later UI implementation |

## Runtime Data Mapping

Do not show device/system results to the customer for this step.

Do not show BIOS version, motherboard model, vendor, boot mode, raw command output, or diagnostics in the normal customer-facing wizard.

The customer only sees the checking/completed flow.

| Data item | Current source or status | First-use visibility decision |
| --- | --- | --- |
| BIOS/UEFI version | `BiosVersion` from `Win32_BIOS.SMBIOSBIOSVersion` | Diagnostics-only |
| BIOS release date | `BiosReleaseDate` from `Win32_BIOS.ReleaseDate` | Diagnostics-only |
| BIOS manufacturer | `BiosManufacturer` from `Win32_BIOS.Manufacturer` | Diagnostics-only |
| Motherboard vendor | `MotherboardManufacturer` from `Win32_BaseBoard.Manufacturer` | Diagnostics-only |
| Motherboard model | `MotherboardModel` from `Win32_BaseBoard.Product` | Diagnostics-only |
| System manufacturer | `SystemManufacturer` from `Win32_ComputerSystem.Manufacturer` | Diagnostics-only |
| System model | `SystemModel` from `Win32_ComputerSystem.Model` | Diagnostics-only |
| Windows boot mode | Not currently a direct `BIOSInformation.psm1` output field | Diagnostics-only unless Yazan later approves otherwise |
| Basic firmware readiness signals | Not a single current field | Diagnostics-only unless Yazan later approves otherwise |
| Secure Boot status | `SecureBootStatus` from `Confirm-SecureBootUEFI` when available | Diagnostics-only |
| TPM status | `TpmStatus` from `Get-Tpm` or `Win32_Tpm` when available | Diagnostics-only |
| CPU name | `CpuName` from `Win32_Processor.Name` | Diagnostics-only |
| Windows version | `WindowsVersion` from BoostLab environment helper | Diagnostics-only |
| Windows build | `WindowsBuild` from BoostLab environment helper | Diagnostics-only |
| Analysis timestamp | `Timestamp` | Diagnostics-only |
| Raw command output | Not exposed as customer copy | Diagnostics-only |
| Raw technical status | Structured result fields and messages | Diagnostics-only |
| Exceptions or query failures | Handled by module as structured result data/messages | Diagnostics-only |
| Verification/status fields | Structured result fields | Diagnostics-only |
| Search query for Open | Motherboard model only via `Get-BoostLabBiosInformationSearchQuery` | Not shown in first-use UI unless Yazan approves otherwise |
| Search URL for Open | Web search URL after `Open` | Not shown in first-use UI unless Yazan approves otherwise |

No live data display is implemented by this phase.

## Customer vs Diagnostics Boundary

Normal customer UI may only use owner-approved content.

Diagnostics or developer-only reports may preserve:

- raw technical status
- command status
- verification details
- raw data values
- logs
- copyable report content
- structured result messages and data fields
- exceptions

Diagnostics are not normal first-use wizard customer copy.

## Customer Problem-State Policy

Normal customer-facing first-use UI must not show:

- `Error`
- `Failed`
- `Warning`
- `Needs attention`
- `Stopped`
- `Restart needed`
- `Waiting for confirmation`
- `Not available`
- `Skipped`
- `Completed with notes`

Technical truth, failures, diagnostics, logs, command status, and verification details may remain available in diagnostics/developer reporting only.

The normal customer-facing flow for this step shows only the owner-approved checking/completed experience.

## UI Layout Mapping

Map the eventual owner-approved content into the approved text-only first-use wizard shell:

- normal Windows titlebar/chrome
- `900 x 650` window
- stage-only progress strip
- content card
- visible title/subtitle region
- information panel region
- no requirements panel for this step
- primary action button
- documentation button
- reusable support panel before action
- runtime checking/completed animation area during and after the primary action flow
- bottom navigation with Back and Continue/Next only
- no Cancel button

No icons:

- no image icon
- no SVG icon
- no WPF vector icon
- no icon placeholder
- no icon column
- no status icon next to the state text

Runtime checking/completed animations are allowed only as state effects, not decorative script icons.

## Acceptance Criteria

- Owner-approved Arabic content is recorded exactly for this step.
- English copy remains pending future translation after Arabic approval.
- The visible customer step title is `BIOS Drivers & Downloads`.
- The visible customer stage label is `Check`.
- The customer-facing primary action is only `Open`, labeled `افتح`.
- `Analyze` is not customer-facing for this step.
- The support panel replaces the old visible Arabic Ready panel for this step.
- The documentation acknowledgement checkbox appears only in a confirmation dialog after `افتح`.
- The checkbox text is `لقد قرات التعليمات`.
- The confirmation dialog has no Cancel button.
- Continue/Next is disabled or visually inactive until the step primary action flow completes.
- Continue/Next does not auto-advance after completion.
- `مكتمل` is the only customer-facing end state for this step.
- Cancel is globally disallowed in the first-use wizard.
- Checking/completed visuals must be true runtime animations/effects when implemented.
- No static icons are introduced for checking/completed status.
- No script icons are reintroduced.
- No customer-facing device/system results appear for this step.
- No customer text is pulled directly from BoostLab config or module descriptions.
- Technical config is used only for internal mapping.
- No problem/failure labels appear in normal customer UI.
- No raw technical status appears in normal customer UI.
- No runtime behavior changes.
- No UI implementation in this phase.
- No `ui/MainWindow.ps1` integration.
- No source-ultimate, source-extra, or intake changes.

## Future Implementation Notes

A later implementation phase should:

- implement the owner-approved Arabic content exactly
- keep English text pending until translation is approved
- keep runtime behavior untouched unless separately approved
- keep the first-use wizard text-only except for runtime checking/completed animations
- remove Cancel from all customer-facing first-use wizard surfaces
- keep diagnostics separate from normal customer UI
- ensure RTL mirroring for Arabic mode
- keep the mixed English title readable in RTL context
- add exact visible-copy tests after UI implementation is approved

## Non-Goals

This phase does not:

- implement UI changes
- run a BIOS query
- run an Analyze or Open action
- wire the wizard into `ui/MainWindow.ps1`
- change runtime modules
- change action plans
- change diagnostics or result contracts
- implement localization
- implement English translation
- implement the documentation website
- add icons
- add animations
- rename technical IDs or runtime contracts
