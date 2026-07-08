# AXIS Final Completion Page Blueprint

Date: 2026-07-07
Scope: owner-approved blueprint and isolated prototype behavior contract for the first-use wizard final completion page

## Owner-Control Notice

This document records owner-approved Arabic-only customer-facing content and layout requirements for the future `final-completion` AXIS first-use wizard page.

The original blueprint phase was documentation-only. A later isolated-prototype phase may implement only the explicitly approved safe prototype behavior recorded here, without wiring `ui/MainWindow.ps1`, adding website links, adding instruction links, running a tool, or creating production runtime behavior.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Page Identity

| Field | Value |
| --- | --- |
| Internal page ID | `final-completion` |
| Placement | After `defender-optimize-assistant` |
| Purpose | Final page shown after all wizard tool steps are completed |
| Language | Arabic-only |
| Future production final button behavior | `إنهاء` closes the AXIS window later |
| Current isolated prototype behavior | Pressing the final button closes only the prototype WPF window safely; saved progress remains. |
| Stage strip | Shown with all stages completed green |
| Support card | Not shown |
| Requirements card | Not shown |
| Instruction links | Not shown |
| Website links | Not shown |

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `اكتمل إعداد AXIS` |
| Subtitle | `تم إكمال جميع خطوات إعداد الجهاز بنجاح.` |
| Final button | `إنهاء` |
| Information card title | `الجهاز جاهز` |
| Information card bullet 1 | `تم إكمال جميع خطوات الإعداد.` |
| Information card bullet 2 | `يمكنك الآن استخدام الجهاز بعد اكتمال إعداد AXIS.` |
| Information card bullet 3 | `عند الحاجة للمساعدة، يمكنك التواصل مع الدعم.` |

## Future Behavior Contract

- Previous button appears.
- Previous returns to `defender-optimize-assistant`.
- No Next button.
- Show final button: `إنهاء`.
- In production later, `إنهاء` closes the AXIS window.
- Pressing the final button in the isolated prototype closes only the prototype WPF window safely.
- It does not clear saved progress.
- It does not reset wizard progress.
- It does not navigate to a dashboard.
- It does not open links or external processes.
- Reopening the isolated prototype after completion still shows the approved start-over prompt.
- No runtime status.
- No support card.
- No requirements card.
- Stage strip appears, with all stages completed green.
- No dashboard transition.
- No instruction links.
- No website links.

This safe close behavior is prototype-only. No runtime action, restart, Scheduled Task, RunOnce, Registry write, Service change, process termination, or host mutation is allowed.

## Future Layout Contract

Future implementation should preserve:

- Same AXIS dark premium wizard visual design.
- Arabic-only customer-facing UI.
- Fixed `900 x 650` prototype target unless a later approved implementation phase changes it.
- Normal Windows chrome/titlebar when implemented in the isolated WPF prototype.
- No sidebar.
- No icons, PNG, SVG, WPF vector icons, or placeholders.
- Stage strip visible with all stages completed green.
- No support card on this final page.
- No requirements card on this final page.
- Final button visible and not clipped.
- Previous button visible and not clipped.
- Information card visible and not clipped.
- Arabic text physically right-aligned.
- Title and body lines containing `AXIS` must use BiDi-safe rendering so `AXIS` does not visually jump to the beginning of the line.

## Customer-Facing Restrictions

Do not show:

- BoostLab.
- Logs.
- Diagnostics.
- Technical details.
- Dashboard.
- Control panel after wizard completion.
- Website links.
- Instruction links.
- PowerShell commands.
- Validation results, command output, internal modules, implementation details, file paths, Registry, Services, Tasks, AppX, package names, hashes, or URLs.
- Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents of those problem states.
- Cancel button.

AXIS is the customer-facing product name. BoostLab remains internal repository/code branding only.

## Relationship To Final Wizard Flow

Future first-use wizard flow after implementation should become:

1. `intro-welcome`
2. existing 50 tool steps, from `bios-information` through `defender-optimize-assistant`
3. `final-completion`

This document records the owner-approved page contract. The isolated prototype may represent this page, but production wiring remains outside this blueprint.

## Non-Goals

This blueprint and isolated prototype behavior do not include:

- Runtime implementation.
- MainWindow integration.
- Website work.
- Instruction button linking.
- Language switching.
- English copy.
- Dashboard implementation.
- Production window close behavior.
- Tool execution.
- Host mutation.
- Staging, committing, or pushing.
