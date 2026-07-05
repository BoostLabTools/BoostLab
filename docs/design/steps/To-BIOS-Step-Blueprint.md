# AXIS To BIOS Step Blueprint

Date: 2026-07-05
Scope: owner-approved Arabic content record and future confirmation-flow contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `to-bios` Refresh-stage step.

This phase is documentation-only. It does not implement UI behavior, run Open, restart the device, enter BIOS/UEFI, execute the original To BIOS tool, wire the step into `ui/MainWindow.ps1`, or change runtime contracts.

English customer-facing copy is pending future translation after Arabic approval. Do not treat any English implementation text as final customer-facing copy for this step.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `to-bios` |
| Customer-facing step title | `الانتقال إلى BIOS` |
| Stage | `Refresh` |
| Visible stage label | `Refresh` |
| Customer-facing primary action | `إعادة التشغيل إلى BIOS` |
| Future internal action mapping | customer-facing `إعادة التشغيل إلى BIOS` maps later to internal `Open` for `to-bios` |

The `to-bios` step is the next Refresh-stage first-use wizard step after Updates Drivers Block.

Internal available actions may include Open according to config/runtime state, but the customer-facing AXIS first-use wizard exposes only the owner-approved action recorded here.

The real `Open` behavior must not execute in this docs/prototype phase. Final integrated behavior is pending a later approved implementation phase.

## Owner-Approved Arabic Copy

Record the following Arabic copy exactly as owner-approved.

| Surface | Owner-approved value |
| --- | --- |
| Title | `الانتقال إلى BIOS` |
| Subtitle/body | `إعادة التشغيل والدخول إلى إعدادات BIOS.` |
| Information card title | `الدخول إلى إعدادات BIOS` |
| Information card bullet 1 | `سيتم إعادة تشغيل الجهاز والدخول إلى شاشة BIOS.` |
| Information card bullet 2 | `يمكنك بعدها اختيار الإقلاع من USB تثبيت Windows الذي تم تجهيزه مسبقًا.` |
| Information card bullet 3 | `بعد الإقلاع من USB، يمكنك بدء تثبيت Windows على الجهاز.` |
| Requirements card | Not shown |
| Primary button | `إعادة التشغيل إلى BIOS` |
| Documentation button | `التعليمات` |
| Confirmation checkbox | `لقد قرأت التعليمات` |
| Confirmation primary button | `إعادة التشغيل` |
| Confirmation return button | `رجوع` |
| Footer Back button | `السابق` |
| Footer Next button | `التالي` |
| Running state | `جاري إعادة التشغيل` |
| Completed state | `مكتمل` |
| Support panel title | `مساعدة` |
| Support panel body | `تحتاج مساعدة؟ يمكنك التواصل مع أخصائي الدعم عبر خادم Discord الخاص بالمتجر.` |

English copy is pending future translation after Arabic approval. Do not add final English copy in this phase.

## Requirements Card

No requirements card should be shown for this step.

No requirements text is owner-approved for the normal customer-facing To BIOS step.

## Customer-Facing Action Exposure

Only the customer-facing primary action appears for this step.

The visible action is `إعادة التشغيل إلى BIOS`.

Internally, this maps later to `Open` for `to-bios`.

Do not show internal action names to the customer:

- Analyze
- Apply
- Default
- Restore
- Open

Do not show any unapproved runtime labels, technical labels, commands, logs, diagnostics, file names, registry names, implementation details, or the real execution method of `to-bios` in the normal customer UI.

## Confirmation Overlay Behavior

Use the same confirmation overlay pattern as the previous BIOS-related prototype steps.

Pressing customer-facing `إعادة التشغيل إلى BIOS` opens a confirmation overlay.

The overlay contains the checkbox text:

`لقد قرأت التعليمات`

The overlay contains only:

- primary button `إعادة التشغيل`
- return button `رجوع`

The confirmation primary button stays disabled until the checkbox is checked.

The checked checkbox visual uses the approved blue filled square with no checkmark, matching the existing AXIS confirmation pattern.

`رجوع` closes only the overlay and returns to the main To BIOS step.

`رجوع` is not Cancel.

No Cancel button appears.

In prototype phases, confirming the overlay must simulate only. It must not restart the device, run real Open, execute the original To BIOS tool, or mutate the host.

## Prototype Safety Boundary

In the isolated prototype:

- Do not run `Open`.
- Do not run Apply, Default, or Restore.
- Do not restart the device.
- Do not enter BIOS/UEFI.
- Do not execute the original To BIOS tool.
- Do not call shutdown, firmware, boot, BCD, registry, service, scheduled-task, driver, Defender, USB, system-file, Windows-settings, or boot-settings behavior.
- Do not mutate the host.
- The prototype may simulate the confirmation flow and show `جاري إعادة التشغيل` then `مكتمل`.

## Real Integrated Behavior Contract

Final integrated `إعادة التشغيل إلى BIOS` must map to internal `Open` for `to-bios`.

Final integrated behavior must stay controlled and owner-approved before being connected.

Technical result details, verification, warnings, rollback records, and errors belong in diagnostics/developer reporting unless Yazan approves customer copy.

## Customer State Behavior

`التالي` starts disabled or inactive.

During the simulated or future action, show:

`جاري إعادة التشغيل`

After simulated or proper completion, show:

`مكتمل`

After completion, do not show any additional customer-facing text.

Then enable `التالي`.

Do not auto-advance.

Wait for the customer to press `التالي`.

No result details or notes are shown to the customer for this step unless Yazan later approves them.

## Customer Problem-State Policy

For normal customer-facing first-use UI, do not show:

- Error
- Failed
- Warning
- Needs attention
- Stopped
- Restart needed
- Waiting for confirmation
- Not available
- Skipped
- Completed with notes
- Arabic equivalents of those problem states

Technical truth remains diagnostics-only.

## Future UI Layout Mapping

Future implementation should preserve:

- `900 x 650`
- normal Windows chrome/titlebar
- dark premium UI
- Arabic-first content
- RTL layout with physical right-edge anchoring where needed
- no sidebar
- no icons
- no image assets
- stage-only progress strip
- logical stage order: Check, Refresh, Setup, Installers, Graphics, Windows, Advanced
- mirrored Arabic visual order while preserving the logical stage order
- Refresh active for this step
- previous Check stage completed green
- active Refresh stage using a full white line
- no partial progress line
- information card shown
- requirements card not shown
- support panel separate from runtime status
- runtime status near the primary action row, not inside the support card
- `التالي` disabled until the simulated action completes
- enabled `التالي` blue after completion
- no auto-advance; wait for the customer to press `التالي`
- `السابق` returns to the previous step
- no Cancel anywhere

The support panel remains unchanged:

| Surface | Default value |
| --- | --- |
| Support panel title | `مساعدة` |
| Support panel body | `تحتاج مساعدة؟ يمكنك التواصل مع أخصائي الدعم عبر خادم Discord الخاص بالمتجر.` |

## Mixed Arabic/English BiDi Contract

The To BIOS information text contains mixed Arabic/English technical terms:

- `BIOS`
- `USB`
- `Windows`

Future UI implementation must avoid mixed Arabic/English BiDi jumps.

Requirements:

- Arabic text blocks must be physically right-aligned, not merely readable RTL.
- Use safe rendering, explicit LTR runs, or manual line breaks where needed.
- Mixed Arabic/English words must not jump to the wrong side of the card.
- No text clipping.
- No words jumping to the physical left edge incorrectly.
- Use the accepted AutoUnattend and Updates Drivers Block BiDi-safe lessons when implementing this step.

## Global Resume Contract

AXIS must always remember where the customer stopped, for every step and every script, especially when a step may restart the device.

Global resume requirements are recorded in [AXIS-Restart-Resume-Contract.md](../AXIS-Restart-Resume-Contract.md).

Exact persistence implementation is deferred to a later approved phase.

Do not implement persistence in this phase. Do not create files, registry keys, services, scheduled tasks, startup entries, or boot settings.

## Customer-Visible Copy Contract

Only owner-approved content appears to the customer.

Global customer-visible copy rules are recorded in [AXIS-Customer-Visible-Copy-Contract.md](../AXIS-Customer-Visible-Copy-Contract.md).

Normal customer UI should show only the exact approved copy for each step.

Anything not explicitly owner-approved in this document must not appear in the normal AXIS customer UI.

## Non-Goals

This phase does not include:

- UI implementation
- runtime implementation
- real Open execution
- real Apply, Default, or Restore execution
- real restart
- BIOS/UEFI opening
- original To BIOS tool execution
- Registry mutation
- service mutation
- task mutation
- driver mutation
- Defender mutation
- USB behavior
- system file mutation
- Windows settings mutation
- boot settings mutation
- persistence implementation
- MainWindow integration
- tests or validators
- icons, PNGs, SVGs, vector icons, or placeholders
- customer-facing diagnostics
- English translation
- localization implementation
