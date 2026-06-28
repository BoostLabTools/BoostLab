# AXIS BIOS Information Step Content Template

Date: 2026-06-29
Scope: owner-controlled content template only

## Owner-Control Notice

This document does not approve final customer-facing copy.

All visible customer-facing text and button labels are pending Yazan approval before implementation.

BoostLab config and module data may be used only for internal implementation mapping, such as technical IDs, stage order, runtime action mapping, capability metadata, and diagnostics mapping.

Final AXIS customer-facing copy must be supplied or explicitly approved by Yazan before any implementation phase uses it.

## Localization and Direction

BIOS Information follows the AXIS Arabic-first localization workflow.

Arabic copy is pending Yazan approval. English copy is pending future translation after Arabic approval.

Arabic layout must be RTL and mirrored. English layout must be LTR.

No customer-facing copy from BoostLab config or module descriptions is approved automatically.

## Purpose

This document converts the BIOS Information first-use wizard blueprint into an owner-controlled content template.

It does not implement UI behavior, query BIOS data, wire the wizard into production UI, or change runtime contracts.

## Source Inspection

Static inspection only:

- `config/Stages.psd1`
- `modules/Check/BIOSInformation.psm1`
- `tests/Test-BIOSInformation.ps1`
- `ui/AxisFirstUseWizardPrototype.ps1`
- current AXIS design notes under `docs/design/`

No runtime BIOS query, Apply action, Open action, browser launch, firmware query, or host mutation was run for this document.

## Internal Implementation Mapping

These are technical facts from current BoostLab config/module state. They are not approved customer-facing copy.

| Field | Internal value |
| --- | --- |
| Step ID | `bios-information` |
| Config title | `BIOS Information` |
| Stage | `Check` |
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

Technical action mapping:

| Runtime action | Current technical meaning | Customer-facing label |
| --- | --- | --- |
| `Analyze` | Runs read-only BIOS/motherboard/system analysis | `PENDING_YAZAN_APPROVAL` |
| `Open` | Opens a motherboard-model-only web search when allowed by runtime | `PENDING_YAZAN_APPROVAL` |

## Owner-Controlled Customer Content Template

No row in this section is approved final copy. Every visible field remains pending Yazan approval.

| Surface | Owner-approved copy |
| --- | --- |
| Customer title | `PENDING_YAZAN_APPROVAL` |
| Customer subtitle | `PENDING_YAZAN_APPROVAL` |
| Main explanation | `PENDING_YAZAN_APPROVAL` |
| Section 1 title | `PENDING_YAZAN_APPROVAL` |
| Section 1 bullets | `PENDING_YAZAN_APPROVAL` |
| Section 2 title | `PENDING_YAZAN_APPROVAL` |
| Section 2 bullets | `PENDING_YAZAN_APPROVAL` |
| Primary button label | `PENDING_YAZAN_APPROVAL` |
| Documentation button label | `PENDING_YAZAN_APPROVAL` |
| Documentation body/helper text | `PENDING_YAZAN_APPROVAL` |
| Acknowledgement checkbox text | `PENDING_YAZAN_APPROVAL` |

## Owner-Controlled State Text Template

Allowed normal customer-facing states remain:

- `Ready`
- `Checking`
- `Completed`

`Completed` is the only customer-facing end state.

Exact title/body copy remains pending Yazan approval:

| State key | Customer title | Customer body |
| --- | --- | --- |
| `Ready` | `PENDING_YAZAN_APPROVAL` | `PENDING_YAZAN_APPROVAL` |
| `Checking` | `PENDING_YAZAN_APPROVAL` | `PENDING_YAZAN_APPROVAL` |
| `Completed` | `PENDING_YAZAN_APPROVAL` | `PENDING_YAZAN_APPROVAL` |

Do not show these labels in the normal customer-facing first-use wizard:

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

## Yazan Content Decision Checklist

Before implementation, Yazan must approve:

- [ ] Exact visible step title
- [ ] Exact short subtitle
- [ ] Exact explanation text
- [ ] Whether to show one or two information panels
- [ ] Exact panel titles
- [ ] Exact bullets in each panel
- [ ] Exact primary button label
- [ ] Exact documentation button label
- [ ] Whether the Documentation button opens a future docs page or remains visual-only for now
- [ ] Whether documentation acknowledgement checkbox is required
- [ ] Exact Ready title and body text
- [ ] Exact Checking title and body text
- [ ] Exact Completed title and body text
- [ ] Whether any runtime data values should be shown to the customer
- [ ] What must remain diagnostics-only

## Documentation Button Decision

Documentation behavior is not approved by this document.

Pending owner decisions:

| Decision | Status |
| --- | --- |
| Documentation button visible label | `PENDING_YAZAN_APPROVAL` |
| Whether the button opens a future docs page | `PENDING_YAZAN_APPROVAL` |
| Future documentation path or slug | `PENDING_YAZAN_APPROVAL` |
| Whether the button remains visual-only in the prototype | `PENDING_YAZAN_APPROVAL` |

No URL or route should be implemented from this template.

## Documentation Acknowledgement Decision

The current technical template keeps BIOS Information acknowledgement unset for implementation.

| Decision | Status |
| --- | --- |
| Whether this step requires documentation acknowledgement | `PENDING_YAZAN_APPROVAL` |
| Acknowledgement checkbox text if required | `PENDING_YAZAN_APPROVAL` |
| Whether the primary action is disabled until acknowledgement | `PENDING_YAZAN_APPROVAL` |

Future high-risk steps may use acknowledgement patterns, but BIOS Information customer behavior must still be owner-approved before implementation.

## Runtime Data Mapping

The current module can collect or expose richer read-only data later. No customer-visible runtime data is approved by this phase.

| Data item | Current source or status | First-use visibility decision |
| --- | --- | --- |
| BIOS/UEFI version | `BiosVersion` from `Win32_BIOS.SMBIOSBIOSVersion` | `Pending Yazan approval` |
| BIOS release date | `BiosReleaseDate` from `Win32_BIOS.ReleaseDate` | Diagnostics-only |
| BIOS manufacturer | `BiosManufacturer` from `Win32_BIOS.Manufacturer` | Diagnostics-only |
| Motherboard vendor | `MotherboardManufacturer` from `Win32_BaseBoard.Manufacturer` | `Pending Yazan approval` |
| Motherboard model | `MotherboardModel` from `Win32_BaseBoard.Product` | `Pending Yazan approval` |
| System manufacturer | `SystemManufacturer` from `Win32_ComputerSystem.Manufacturer` | Diagnostics-only |
| System model | `SystemModel` from `Win32_ComputerSystem.Model` | Diagnostics-only |
| Windows boot mode | Not currently a direct `BIOSInformation.psm1` output field | `Pending Yazan approval` after a separately approved read-only mapping |
| Basic firmware readiness signals | Not a single current field | `Pending Yazan approval` after a separately approved read-only mapping |
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

Diagnostics are not normal first-use wizard customer copy.

## UI Layout Mapping

Map the eventual owner-approved content into the approved text-only first-use wizard shell:

- normal Windows titlebar/chrome
- `900 x 650` window
- stage-only progress strip
- content card
- customer title/subtitle/explanation region
- information panel region or regions
- primary action
- documentation button
- status panel
- bottom navigation

Actual visible text inside each region is pending Yazan approval.

No icons:

- no image icon
- no SVG icon
- no WPF vector icon
- no icon placeholder
- no icon column
- no status icon next to the state text

## Acceptance Criteria

- No customer-facing copy is implemented from this document until Yazan approves it.
- No customer text is pulled directly from BoostLab config or module descriptions.
- Technical config is used only for internal mapping.
- Customer title, body copy, section labels, bullets, button labels, documentation text, acknowledgement text, and state body text remain pending owner approval.
- No icons are introduced.
- Normal customer-facing states remain Ready, Checking, and Completed only.
- Completed remains the only customer-facing end state.
- No problem/failure labels appear in normal customer UI.
- No raw technical status appears in normal customer UI.
- No runtime behavior changes.
- No `ui/MainWindow.ps1` integration.
- No source-ultimate, source-extra, or intake changes.

## Future Implementation Notes

A later implementation phase should:

- wait for owner-approved copy before changing visible wizard text
- keep runtime behavior untouched unless separately approved
- keep the first-use wizard text-only
- add exact visible-copy tests after copy is approved
- keep diagnostics separate from normal customer UI
- show real BIOS result summaries only after Yazan approves the exact fields and wording
- avoid adding boot-mode or readiness-summary display until a future approved read-only mapping exists

## Non-Goals

This phase does not:

- approve customer-facing copy
- implement UI changes
- run a BIOS query
- run an Analyze or Open action
- wire the wizard into `ui/MainWindow.ps1`
- change runtime modules
- change action plans
- change diagnostics or result contracts
- implement localization
- implement the documentation website
- add icons
- rename technical IDs or runtime contracts
