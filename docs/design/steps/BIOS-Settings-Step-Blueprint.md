# AXIS BIOS Settings Step Blueprint

Date: 2026-06-29
Scope: owner-approved Arabic content record and design contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `bios-settings` Check-stage step.

This phase is documentation-only. It does not implement UI behavior, query hardware, open BIOS/UEFI, reboot, wire the step into `ui/MainWindow.ps1`, or change runtime contracts.

English customer-facing copy is pending future translation after Arabic approval. Do not treat any English implementation text as final customer-facing copy for this step.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `bios-settings` |
| Customer-facing step title | `BIOS Settings` |
| Stage | `Check` |
| Visible stage label | `Check` |
| Customer-facing primary action | `إعادة التشغيل` |
| Future internal action mapping | customer-facing `إعادة التشغيل` maps later to internal `Open` for `bios-settings` |

Internal available actions may include Analyze/Open according to config, but the customer-facing AXIS first-use wizard exposes only the owner-approved action recorded here.

The real `Open` behavior must not execute in this docs/prototype phase. Final integrated behavior is pending a later approved implementation phase.

## Owner-Approved Arabic Copy

Record the following Arabic copy exactly as owner-approved.

| Surface | Owner-approved value |
| --- | --- |
| Title | `BIOS Settings` |
| Subtitle/body | `اضبط إعدادات BIOS/UEFI الخاصة باللوحة الأم لتجهيز الجهاز للخطوات التالية.` |
| Information card title | `الإعدادات المقترحة لجهازك` |
| Information card intro | Removed from the normal customer-facing prototype in Phase 178D |
| Requirements card title | Not shown in the normal customer-facing prototype as of Phase 178E |
| Primary button | `إعادة التشغيل` |
| Documentation button | `التعليمات` |
| Confirmation overlay return button | `رجوع` |
| Next button | `التالي` |
| Confirmation checkbox | `لقد قرأت التعليمات` |
| Running state | `جاري إعادة التشغيل` |
| Completed state | `مكتمل` |
| Support panel title | `مساعدة` |
| Support panel body | `تحتاج مساعدة؟ يمكنك التواصل مع أخصائي الدعم عبر خادم Discord الخاص بالمتجر.` |

Important: `رجوع` is the confirmation overlay return button for this step blueprint. Do not infer that it replaces the global footer Back label unless Yazan explicitly approves that later.

## Phase 178E Prototype-Visible Settings

The isolated prototype uses a local mock profile only:

- CPU: Intel
- Motherboard: MSI

The Phase 178D customer-facing prototype shows the settings directly without processor or motherboard group headings.

Default prototype-visible settings:

- `تفعيل ram profile: XMP / DOCP / EXPO`
- `تعطيل C-States`
- `تفعيل Resizable BAR: REBAR / C.A.M`
- `تعطيل iGPU`
- `تعطيل MSI Driver Utility`

Do not show the following labels or explanatory lines in the normal customer-facing BIOS Settings prototype:

- `يعرض AXIS الإعدادات المناسبة فقط حسب نوع المعالج واللوحة الأم في جهازك.`
- `معالج Intel`
- `معالج AMD`
- `إعدادات اللوحة الأم driver installer software :`
- `يعرض AXIS الخيار المناسب حسب الشركة المصنعة للوحة الأم فقط:`

Vendor-specific items remain hardware-aware. The Phase 178D prototype mock profile shows only:

- `تعطيل MSI Driver Utility`

The normal customer-facing prototype must not show non-matching vendor items:

- `تعطيل ASUS Armoury Crate`
- `تعطيل Gigabyte Update Utility`
- `تعطيل ASRock Motherboard Utility`

## Requirements

Phase 178E removes the requirements card from the normal customer-facing BIOS Settings prototype.

The following previous requirement copy is superseded and is not owner-approved visible UI for BIOS Settings:

- `١. تأكد من فهم طريقة التنقل داخل شاشة BIOS/UEFI قبل المتابعة.`
- `٢. إذا لم تكن متأكدًا من طريقة ضبط الإعدادات حتى بعد قراءة التعليمات، تواصل مع الدعم ليتم إرشادك خطوة بخطوة.`

## Hardware-Aware Display Contract

AXIS must not show all BIOS settings to every customer.

AXIS should detect the customer's hardware and show only the relevant settings for their device.

Detection categories:

- CPU vendor: Intel, AMD
- Motherboard vendor: ASUS, MSI, Gigabyte, ASRock

Customer-facing display rules:

- If CPU vendor is Intel, show only the Intel processor group.
- If CPU vendor is AMD, show only the AMD processor group.
- Do not show both Intel and AMD groups to the customer at the same time unless a later owner-approved fallback design explicitly allows it.
- For motherboard driver installer software, show only the matching motherboard vendor item.
- ASUS maps to `تعطيل ASUS Armoury Crate`.
- MSI maps to `تعطيل MSI Driver Utility`.
- Gigabyte maps to `تعطيل Gigabyte Update Utility`.
- ASRock maps to `تعطيل ASRock Motherboard Utility`.
- Do not show all motherboard vendor utility items to the customer at the same time unless a later owner-approved fallback design explicitly allows it.

Diagnostics boundary:

- Raw detection values, manufacturer strings, WMI values, unknown vendor data, and detection uncertainty belong in diagnostics/developer reporting.
- Normal customer-facing first-use UI must stay simple.
- Do not show error/warning/problem labels in the normal customer UI.

Pending fallback decision:

If AXIS cannot detect CPU or motherboard vendor confidently, the customer-facing fallback content is pending Yazan approval. Do not invent fallback copy in this phase.

## Hardware Correctness Contract

The isolated first-use wizard prototype may use a mock hardware profile only for visual review.

The final integrated AXIS implementation must remove static vendor assumptions before showing vendor-specific BIOS guidance.

Final integrated AXIS must detect CPU and motherboard vendor from reliable system data before displaying vendor-specific guidance.

AXIS must not show a vendor-specific motherboard utility item unless the motherboard vendor is confidently detected.

If motherboard vendor detection is unknown, unavailable, ambiguous, or low-confidence, the customer-facing fallback remains pending Yazan approval.

AXIS must not guess ASUS, MSI, Gigabyte, or ASRock when detection is not reliable.

Vendor detection values, raw manufacturer strings, WMI/system data, and uncertainty details belong in diagnostics/developer reporting, not the normal customer UI.

## Restart And Resume Contract

AXIS must remember where the customer stopped if a step triggers a restart.

This applies especially to `bios-settings`, because the primary action restarts the device into BIOS/UEFI.

Before a restart-capable step runs, AXIS should persist enough state to resume the same step later, including:

- current stage
- current step ID
- current visible customer step
- whether the step was started
- whether the primary action was triggered
- whether the step should return as completed or ready for continuation
- any customer navigation state required to avoid restarting the entire flow

After the customer returns to Windows and launches AXIS again:

- AXIS should resume at the same step instead of starting from the beginning.
- AXIS should not force the customer to repeat previous completed steps.
- For BIOS Settings specifically, after returning from BIOS/UEFI, the intended future behavior is to return to the BIOS Settings step, show `مكتمل` when appropriate, enable `التالي`, and wait for the customer to press `التالي`.

Exact persistence implementation is pending a later phase.

The global restart/resume design contract is also recorded in [AXIS-Restart-Resume-Contract.md](../AXIS-Restart-Resume-Contract.md).

Do not implement this persistence in this phase. Do not create files, registry keys, scheduled tasks, or startup entries in this phase.

## Confirmation Overlay Behavior

- Pressing customer-facing `إعادة التشغيل` opens a confirmation overlay.
- The overlay contains the checkbox text `لقد قرأت التعليمات`.
- The overlay contains a primary confirm button using `إعادة التشغيل`.
- The overlay contains a return button `رجوع`.
- `رجوع` closes only the overlay.
- `رجوع` is not Cancel.
- The global no-Cancel rule remains active.
- The confirm button remains disabled until the checkbox is checked.
- When confirmed in the final integrated version, the action maps to the real internal Open behavior for `bios-settings`.
- In prototype phases, this must be simulated and must not reboot.

## Customer State Policy

For normal customer-facing first-use UI, allowed visible states are:

- `جاري إعادة التشغيل`
- `مكتمل`

The support panel remains:

- `مساعدة`
- `تحتاج مساعدة؟ يمكنك التواصل مع أخصائي الدعم عبر خادم Discord الخاص بالمتجر.`

Do not show customer-facing:

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

Technical truth can remain in diagnostics/developer logs only.

## Future UI Layout Mapping

Future implementation should preserve:

- Arabic RTL
- same AXIS first-use wizard shell
- no decorative icons
- information card with dynamic hardware-aware content
- requirements card not shown for BIOS Settings unless Yazan approves new visible requirement copy later
- support panel separate from runtime status
- runtime status near the primary action row
- `التالي` disabled until the step flow completes
- no auto-advance; wait for the customer to press `التالي`
- no Cancel anywhere

## Non-Goals

This phase does not include:

- UI implementation
- runtime implementation
- real reboot
- BIOS/UEFI opening
- hardware query execution
- persistence implementation
- MainWindow integration
- English translation
- localization implementation
- website/command-launch implementation
