# AXIS AutoUnattend Step Blueprint

Date: 2026-07-02
Scope: owner-approved Arabic content record and input-window design contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `unattended` Refresh-stage step.

This phase is documentation-only. It does not implement UI behavior, run Apply, create or write `autounattend.xml`, touch USB devices, wire the step into `ui/MainWindow.ps1`, or change runtime contracts.

English customer-facing copy is pending future translation after Arabic approval. Do not treat any English implementation text as final customer-facing copy for this step.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `unattended` |
| Customer-facing step title | `AutoUnattend` |
| Stage | `Refresh` |
| Visible stage label | `Refresh` |
| Customer-facing primary action | `إنشاء الملف` |
| Future internal action mapping | customer-facing `إنشاء الملف` maps later to internal `Apply` for `unattended` |

Internal available actions may include Apply according to config/runtime state, but the customer-facing AXIS first-use wizard exposes only the owner-approved action recorded here.

The real `Apply` behavior must not execute in this docs/prototype phase. Final integrated behavior is pending a later approved implementation phase.

## Owner-Approved Arabic Copy

Record the following Arabic copy exactly as owner-approved.

| Surface | Owner-approved value |
| --- | --- |
| Title | `AutoUnattend` |
| Subtitle/body | `إنشاء ملف XML لإعداد تثبيت Windows تلقائيًا.` |
| Information card title | `ملف إعداد تلقائي لتثبيت Windows` |
| Information card bullet 1 | `يساعد ملف AutoUnattend على تخطي مرحلة OOBE أثناء تثبيت Windows.` |
| Information card bullet 2 | `يتجاوز خطوات الإعداد الأولى مثل إعدادات الخصوصية، تسجيل الدخول بحساب Microsoft، واختيار بعض إعدادات البداية.` |
| Information card bullet 3 | `يتم إنشاء الملف داخل USB تثبيت Windows ليتم استخدامه أثناء عملية التثبيت.` |
| Requirements card title | `المتطلبات` |
| Requirement 1 | `اختيار اسم الحساب.` |
| Requirement 2 | `اختيار USB الصحيح.` |
| Input window title | `نافذة إنشاء الملف` |
| Input field 1 | `أدخل اسم الحساب بدون مسافات.` |
| Input field 2 | `اختر USB.` |
| Primary button | `إنشاء الملف` |
| Documentation button | `التعليمات` |
| Input window create button | `إنشاء الملف` |
| Input window return button | `رجوع` |
| Footer Back button | `السابق` |
| Footer Next button | `التالي` |
| Running state | `جاري الإنشاء` |
| Completed state | `تم الإنشاء` |
| Support panel title | `مساعدة` |
| Support panel body | `تحتاج مساعدة؟ يمكنك التواصل مع أخصائي الدعم عبر خادم Discord الخاص بالمتجر.` |

English copy is pending future translation after Arabic approval. Do not add final English copy in this phase.

## Customer-Facing Action Exposure

Only the customer-facing primary action appears for this step.

The visible action is `إنشاء الملف`.

Internally, this maps later to `Apply` for `unattended`.

Do not show internal action names to the customer:

- Analyze
- Apply
- Default
- Restore

Do not show any unapproved runtime labels or technical labels.

## Input Window Behavior

Pressing the customer-facing primary button `إنشاء الملف` opens an AXIS-style input window or overlay.

This is not a confirmation checkbox window.

No confirmation checkbox is required for this step.

The window collects:

1. Account name
2. USB selection

The window must show:

- Text/input label: `أدخل اسم الحساب بدون مسافات.`
- USB selection label: `اختر USB.`
- Primary button: `إنشاء الملف`
- Return button: `رجوع`

`رجوع` closes only the input window and returns to the main AutoUnattend step.

`رجوع` is not Cancel.

The global no-Cancel rule remains active.

The input-window `إنشاء الملف` button should remain disabled until the required fields are valid.

Account name validation should follow the technical runtime requirement later: no spaces and Windows-safe account name rules.

USB selection must be from detected removable installation media later.

In prototype phases, use mock/input-only simulation and do not touch USB.

## Prototype Safety Boundary

In the isolated prototype:

- Do not run `Apply`.
- Do not create `autounattend.xml`.
- Do not write to USB.
- Do not detect real removable media.
- Do not create backups.
- Do not open directories.
- Do not mutate the host.
- The prototype may simulate the input window and show `جاري الإنشاء` then `تم الإنشاء`.

## Real Integrated Behavior Contract

Final integrated `إنشاء الملف` must map to internal `Apply` for `unattended`.

Final integrated behavior must use the selected account name and selected USB.

Final integrated behavior must stay controlled and owner-approved before being connected.

If an existing `autounattend.xml` exists, backup and verification behavior remains a technical implementation detail and not normal customer-facing text unless Yazan approves copy.

Technical result details, verification, warnings, and errors belong in diagnostics/developer reporting unless Yazan approves customer copy.

## Customer State Behavior

`التالي` starts disabled or inactive.

After valid input and starting the simulated or future flow, show:

`جاري الإنشاء`

After simulated or proper completion, show:

`تم الإنشاء`

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
- input window appears after pressing `إنشاء الملف`
- input window has fields for account name and USB selection
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
- `autounattend.xml` creation
- USB detection
- USB formatting
- USB file operations
- backup creation
- persistence implementation
- MainWindow integration
- English translation
- localization implementation
- website/command-launch implementation
