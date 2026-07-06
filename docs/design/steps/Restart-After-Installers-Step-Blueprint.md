# AXIS Restart After Installers Step Blueprint

Date: 2026-07-07
Scope: owner-approved Installers-stage custom restart blueprint only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the future `restart-after-installers` Installers-stage step.

This phase is documentation-only. It does not implement UI behavior, restart the computer, call shutdown, call `Restart-Computer`, wire the step into `ui/MainWindow.ps1`, edit the isolated prototype, edit tests, edit config, edit modules, or change runtime contracts.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `restart-after-installers` |
| Customer-facing step title | `إعادة تشغيل الجهاز` |
| Stage | `Installers` |
| Visible stage label | `Installers` |
| Tool origin | AXIS custom step |
| Future production action mapping | AXIS custom `Restart` action |
| Prototype behavior | Simulation only. Do not restart the computer. |

This step does not currently exist as a BoostLab tool and is not mapped to an existing BoostLab module/tool. Future production implementation should create a small AXIS-controlled restart action only.

Do not pretend this exists in BoostLab today.

## Owner-Approved Customer-Facing Copy

| Surface | Owner-approved value |
| --- | --- |
| Title | `إعادة تشغيل الجهاز` |
| Subtitle | `إعادة تشغيل الجهاز بعد تثبيت البرامج ومراجعة بدء التشغيل.` |
| Primary action button | `إعادة التشغيل` |
| Information card title | `إعادة تشغيل الجهاز` |
| Information card bullet 1 | `بعد تثبيت البرامج ومراجعة تطبيقات بدء التشغيل، أعد تشغيل الجهاز لتطبيق الترتيب الجديد.` |
| Information card bullet 2 | `تساعد إعادة التشغيل على إغلاق العمليات الجديدة وبدء النظام بشكل نظيف.` |
| Information card bullet 3 | `بعد اكتمال هذه الخطوة، يمكنك متابعة إعداد AXIS.` |
| Requirements card | Not shown |
| Confirmation overlay | Not shown |
| Confirmation checkbox | Not shown |
| Running state | `جاري إعادة التشغيل` |
| Completed state | `مكتمل` |

## Requirements Card

No requirements card should be shown.

No requirements text is owner-approved for the normal customer-facing restart-after-installers step.

## Confirmation Overlay

No confirmation overlay should be shown.

No checkbox should be shown.

## Runtime Status And Completion

During simulated action, show `جاري إعادة التشغيل`.

After simulated completion, show `مكتمل`.

After completion, show no additional customer-facing text. Only enable the Next button.

Do not auto-advance.

## Customer-Facing Restrictions

Do not show PowerShell commands, `shutdown.exe`, `Restart-Computer`, system/restart internals, diagnostics, logs, file names, Registry names, Services names, Tasks names, modules, command output, validation results, or implementation details.

Do not show Error, Failed, Warning, Needs attention, Stopped, Restart needed, Waiting for confirmation, Not available, Skipped, Completed with notes, or Arabic equivalents in the normal customer UI.

## Prototype Safety Restrictions

The prototype must not restart the computer, call `shutdown.exe`, call `Restart-Computer`, create any real restart action, mutate host state, or run Apply, Default, Restore, Open, Analyze, or Restart.

## Future Production Boundary

Future production implementation must be separately approved before any restart behavior is connected.

The final implementation should create only a small AXIS-controlled restart action for this step.

This blueprint does not authorize real reboot, resume scheduling, RunOnce, Scheduled Tasks, BCD changes, recovery settings, services, registry writes, file writes, or host mutation.

## Installers UI Layout Contract

Future implementation should preserve `900 x 650`, normal Windows chrome/titlebar, dark premium UI, no sidebar, no icons, no PNG/SVG/WPF vector placeholders, Arabic-first copy, RTL layout with physical right-edge anchoring, and the stage strip logical order Check, Refresh, Setup, Installers, Graphics, Windows, Advanced.

Installers is active for this step. Previous Check, Refresh, and Setup stages are completed green. Active Installers uses a full white line. There is no partial progress line.

The support card appears in every step and remains separate from runtime status:

| Surface | Owner-approved value |
| --- | --- |
| Support card title | `مساعدة` |
| Support card body | `تحتاج مساعدة؟ يمكنك التواصل مع أخصائي الدعم عبر خادم Discord الخاص بالمتجر.` |

Runtime status stays near the primary action button. Next is disabled until action simulation completes, then enabled and blue. Previous returns to the previous step.

Enabled buttons use hand cursor. Disabled buttons do not hover, do not press, and do not use hand cursor. Hover must be crisp and readable, with no grow, scale, or blur. Pressed state should be a subtle pressed-in effect.

## BiDi And Layout Notes

Arabic title and body must be physically right-anchored.

`AXIS` inside Arabic lines must render safely.

Support card must remain fully visible.

Runtime status must stay near the primary action row.

Wrapped Arabic lines must remain physically right-aligned and must not float left.

No accidental replacement glyphs like `ï¿½`.

## Non-Goals

This phase does not include UI implementation, runtime implementation, prototype changes, tests, config, modules, source changes, real Apply/Open/Default/Restore/Analyze/Restart actions, computer restart, host mutation, staging, committing, or pushing.
