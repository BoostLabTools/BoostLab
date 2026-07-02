# AXIS Updates Drivers Block Step Blueprint

Date: 2026-07-02
Scope: owner-approved Arabic content record, USB input-window contract, and documentation-color decision only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `updates-drivers-block` Refresh-stage step.

This phase is documentation-only. It does not implement UI behavior, run Apply, create or write `setupcomplete.cmd`, detect or touch USB devices, create backups, open directories, wire the step into `ui/MainWindow.ps1`, or change runtime contracts.

English customer-facing copy is pending future translation after Arabic approval. Do not treat any English implementation text as final customer-facing copy for this step.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `updates-drivers-block` |
| Customer-facing step title | `Updates Drivers Block` |
| Stage | `Refresh` |
| Visible stage label | `Refresh` |
| Customer-facing primary action | `إنشاء ملف منع التعريفات` |
| Future internal action mapping | customer-facing `إنشاء ملف منع التعريفات` maps later to internal `Apply` for `updates-drivers-block` |

Internal available actions may include Apply according to config/runtime state, but the customer-facing AXIS first-use wizard exposes only the owner-approved action recorded here.

The real `Apply` behavior must not execute in this docs/prototype phase. Final integrated behavior is pending a later approved implementation phase.

## Owner-Approved Arabic Copy

Record the following Arabic copy exactly as owner-approved.

| Surface | Owner-approved value |
| --- | --- |
| Title | `Updates Drivers Block` |
| Subtitle/body | `منع تحديثات التعريفات من Windows Update.` |
| Information card title | `حظر تحديثات التعريفات غير الضرورية` |
| Information card bullet 1 | `إنشاء ملف setupcomplete.cmd داخل USB تثبيت Windows.` |
| Information card bullet 2 | `يمنع Windows Update من تثبيت التعريفات تلقائيًا أثناء إعداد النظام.` |
| Requirements card title | `المتطلبات` |
| Requirement 1 | `اختيار USB الصحيح.` |
| Input window title | `نافذة إنشاء الملف` |
| Input field 1 | `اختر USB.` |
| Primary button | `إنشاء ملف منع التعريفات` |
| Documentation button | `التعليمات` |
| Input window create button | `إنشاء الملف` |
| Input window return button | `رجوع` |
| Footer Back button | `السابق` |
| Footer Next button | `التالي` |
| Running state | `جاري التجهيز` |
| Completed state | `جاهز` |
| Support panel title | `مساعدة` |
| Support panel body | `تحتاج مساعدة؟ يمكنك التواصل مع أخصائي الدعم عبر خادم Discord الخاص بالمتجر.` |

English copy is pending future translation after Arabic approval. Do not add final English copy in this phase.

## Customer-Facing Action Exposure

Only the customer-facing primary action appears for this step.

The visible action is `إنشاء ملف منع التعريفات`.

Internally, this maps later to `Apply` for `updates-drivers-block`.

Do not show internal action names to the customer:

- Analyze
- Apply
- Default
- Restore

Do not show `Default` or `Restore` customer-facing for this step.

Do not show any unapproved runtime labels or technical labels.

## Input Window Behavior

Pressing `إنشاء ملف منع التعريفات` opens an AXIS-style input window or overlay.

This is not a confirmation checkbox window.

No confirmation checkbox is required for this step.

The window collects only:

1. USB selection

The window must show:

- USB selection label: `اختر USB.`
- Primary button: `إنشاء الملف`
- Return button: `رجوع`

`رجوع` closes only the input window and returns to the main Updates Drivers Block step.

`رجوع` is not Cancel.

The global no-Cancel rule remains active.

The input-window `إنشاء الملف` button should remain disabled until a USB option is selected.

USB selection must later be from detected removable/bootable USB media.

In prototype phases, use mock/input-only simulation and do not touch USB.

## USB Selector Visual Clarity Contract

Yazan's global requirement: AXIS USB selection windows must be clear, readable, and visually consistent with the dark AXIS UI.

This applies to:

- AutoUnattend
- Updates Drivers Block
- any future step that asks the customer to choose USB media

Rules:

- USB selector should not look like a harsh plain white system control.
- Options must be easy to read.
- Selected USB value must be clearly visible.
- Dropdown/selector should fit the dark AXIS style.
- Selector must be visually obvious as an interactive input.
- Labels must be clear and right-aligned in Arabic.
- Input window buttons remain consistent: primary action and `رجوع`.
- No Cancel appears.
- Future real USB detection must not guess or show unsafe/unclear targets.
- Technical drive details belong in diagnostics unless Yazan approves customer-facing copy.

## Mixed Arabic/English BiDi Contract

The Updates Drivers Block information text contains mixed Arabic/English technical terms:

- `setupcomplete.cmd`
- `USB`
- `Windows`
- `Windows Update`

Future UI implementation must use BiDi-safe rendering, deterministic line breaks, or explicit LTR runs so English terms do not jump to the wrong side of the card.

Requirements:

- Information card text must remain right-aligned and readable.
- Mixed Arabic/English lines must not visually break like the previous AutoUnattend wrapping issue.
- No text clipping.
- No words jumping to the physical left edge incorrectly.
- Use the accepted AutoUnattend BiDi-safe lesson when implementing this step.

## Prototype Safety Boundary

In the isolated prototype:

- Do not run `Apply`.
- Do not write `setupcomplete.cmd`.
- Do not detect real removable media.
- Do not create the `sources\$OEM$\$$\Setup\Scripts` path.
- Do not create backups.
- Do not open directories.
- Do not mutate the host.
- The prototype may simulate the input window and show `جاري التجهيز` then `جاهز`.

## Real Integrated Behavior Contract

Final integrated `إنشاء ملف منع التعريفات` must map to internal `Apply` for `updates-drivers-block`.

Final integrated behavior must use the selected USB target.

Final integrated behavior must stay controlled and owner-approved before being connected.

The real tool writes `setupcomplete.cmd` to selected USB media only.

The real tool must not execute the generated script on the current host.

Technical result details, verification, warnings, rollback records, and errors belong in diagnostics/developer reporting unless Yazan approves customer copy.

## Documentation Button Color Decision

Documentation button `التعليمات` returns to its previous/default normal button text color.

Do not keep `#E65F2B` for documentation button text.

Do not use a custom documentation accent color unless Yazan approves a new one later.

Preserve previous rejected accent decisions:

- acknowledgement text is not `#E65F2B`
- information card titles are not `#8A2BE2`
- requirements card titles are not `#D9A74A`

This phase documents the decision only. UI implementation comes in the next prototype phase.

## Global Support Panel Rule

Do not ask again in future step questionnaires whether the support panel uses the same text.

Default support panel for all future AXIS first-use wizard steps:

| Surface | Default value |
| --- | --- |
| Support panel title | `مساعدة` |
| Support panel body | `تحتاج مساعدة؟ يمكنك التواصل مع أخصائي الدعم عبر خادم Discord الخاص بالمتجر.` |

Only ask about support text again if Yazan explicitly says he wants a different support message for a specific step.

## Customer State Behavior

`التالي` starts disabled or inactive.

After valid USB selection and starting the simulated or future flow, show:

`جاري التجهيز`

After simulated or proper completion, show:

`جاهز`

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

- Arabic RTL
- same AXIS first-use wizard shell
- no decorative icons
- information card shown
- requirements card shown
- support panel separate from runtime status
- runtime status near the primary action row
- `التالي` disabled until the step flow completes
- no auto-advance; wait for the customer to press `التالي`
- no Cancel anywhere
- input window appears after pressing `إنشاء ملف منع التعريفات`
- input window has USB selection only
- input window has `إنشاء الملف` and `رجوع`

## Global Resume Contract

AXIS must always remember where the customer stopped, for every step and every script, even if the step does not reboot.

This is broader than restart-only behavior.

Global resume requirements are recorded in [AXIS-Restart-Resume-Contract.md](../AXIS-Restart-Resume-Contract.md).

Exact persistence implementation is deferred to a later approved phase.

Do not implement persistence in this phase. Do not create files, registry keys, services, scheduled tasks, or startup entries.

## Customer-Visible Copy Contract

Only owner-approved content appears to the customer.

Global customer-visible copy rules are recorded in [AXIS-Customer-Visible-Copy-Contract.md](../AXIS-Customer-Visible-Copy-Contract.md).

Normal customer UI should show only the exact approved copy for each step.

## Non-Goals

This phase does not include:

- UI implementation
- runtime implementation
- real Apply execution
- `setupcomplete.cmd` creation
- USB detection
- USB formatting
- USB file operations
- backup creation
- persistence implementation
- MainWindow integration
- English translation
- localization implementation
- website/command-launch implementation
