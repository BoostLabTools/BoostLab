# AXIS Intro Welcome Page Blueprint

Date: 2026-07-07
Scope: documentation-only owner-approved blueprint for a future first-use wizard intro page

## Owner-Control Notice

This document records owner-approved Arabic-only customer-facing content and layout requirements for the future `intro-welcome` AXIS first-use wizard page.

This phase is documentation-only. It does not implement UI behavior, edit the isolated prototype, edit tests, wire the page into `ui/MainWindow.ps1`, add website links, add instruction links, run a tool, or create runtime behavior.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Page Identity

| Field | Value |
| --- | --- |
| Internal page ID | `intro-welcome` |
| Placement | Before `bios-information` |
| Purpose | First page shown before the tool steps begin |
| Language | Arabic-only |
| Runtime behavior | None |
| Stage strip | Not shown |
| Support card | Not shown |
| Requirements card | Not shown |
| Instruction links | Not shown |
| Website links | Not shown |

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `مرحبًا بك في AXIS` |
| Subtitle | `سيقودك AXIS خطوة بخطوة لإعداد الجهاز بالشكل المناسب.` |
| Primary button | `بدء` |
| Information card title | `قبل أن تبدأ` |
| Information card bullet 1 | `يساعدك AXIS على إعداد الجهاز خطوة بخطوة.` |
| Information card bullet 2 | `اتبع الخطوات بالترتيب حتى يكتمل الإعداد بشكل صحيح.` |
| Information card bullet 3 | `كل خطوة ستوضح لك الإجراء المطلوب قبل المتابعة.` |

## Future Behavior Contract

- No Previous button.
- No Next button.
- Show one clear primary button: `بدء`.
- Pressing `بدء` moves the customer to the first wizard tool step, `bios-information`.
- No runtime status.
- No support card.
- No requirements card.
- No stage strip.
- No instruction links.
- No website links.
- No dashboard mention.

Do not implement this behavior in this docs-only phase.

## Future Layout Contract

Future implementation should preserve:

- Same AXIS dark premium wizard visual design.
- Arabic-only customer-facing UI.
- Fixed `900 x 650` prototype target unless a later approved implementation phase changes it.
- Normal Windows chrome/titlebar when implemented in the isolated WPF prototype.
- No sidebar.
- No icons, PNG, SVG, WPF vector icons, or placeholders.
- No stage strip on this intro page.
- No support card on this intro page.
- Single primary button visible and not clipped.
- Information card visible and not clipped.
- Arabic text physically right-aligned.
- Title and body lines containing `AXIS` must use BiDi-safe rendering so `AXIS` does not visually jump to the beginning of the line.

## Customer-Facing Restrictions

Do not show:

- BoostLab.
- Script names.
- PowerShell commands.
- Technical details.
- Website links.
- Instruction links.
- Dashboard wording.
- Diagnostics, logs, validation results, command output, internal modules, implementation details, file paths, Registry, Services, Tasks, AppX, package names, hashes, or URLs.
- Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents of those problem states.
- Cancel button.

AXIS is the customer-facing product name. BoostLab remains internal repository/code branding only.

## Relationship To Final Wizard Flow

Future first-use wizard flow after implementation should begin with:

1. `intro-welcome`
2. `bios-information`
3. the remaining existing tool steps

This document records the blueprint only. The next implementation phase may add the page to the isolated prototype.

## Non-Goals

This phase does not include:

- UI implementation.
- Runtime implementation.
- Prototype edits.
- Test edits.
- MainWindow integration.
- Website work.
- Instruction button linking.
- Language switching.
- English copy.
- Dashboard implementation.
- Tool execution.
- Host mutation.
- Staging, committing, or pushing.
