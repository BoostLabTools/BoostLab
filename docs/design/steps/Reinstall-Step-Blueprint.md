# AXIS Reinstall Step Blueprint

Date: 2026-07-01
Scope: owner-approved Arabic content record and design contract only

## Owner-Control Notice

This document records Yazan-approved Arabic-first customer-facing content for the `reinstall` Refresh-stage step.

This phase is documentation-only. It does not implement UI behavior, run Apply, download Windows Media Creation Tool, create installation media, touch USB devices, wire the step into `ui/MainWindow.ps1`, or change runtime contracts.

English customer-facing copy is pending future translation after Arabic approval. Do not treat any English implementation text as final customer-facing copy for this step.

## Step Identity

| Field | Value |
| --- | --- |
| Internal tool ID | `reinstall` |
| Customer-facing step title | `تجهيز تثبيت Windows` |
| Stage | `Refresh` |
| Visible stage label | `Refresh` |
| Customer-facing primary action | `إنشاء وسائط تثبيت Windows 11` |
| Future internal action mapping | customer-facing `إنشاء وسائط تثبيت Windows 11` maps later to internal `Apply` for `reinstall` |

Internal available actions may include Apply according to config/runtime state, but the customer-facing AXIS first-use wizard exposes only the owner-approved action recorded here.

The real `Apply` behavior must not execute in this docs/prototype phase. Final integrated behavior is pending a later approved implementation phase.

## Owner-Approved Arabic Copy

Record the following Arabic copy exactly as owner-approved.

| Surface | Owner-approved value |
| --- | --- |
| Title | `تجهيز تثبيت Windows` |
| Subtitle/body | `تجهيز USB باستخدام حزمة Windows 11 الرسمية.` |
| Information card title | `إجراء إعادة تثبيت لنظام التشغيل Windows 11` |
| Information card bullet | `تنزيل أداة إنشاء الوسائط الرسمية لإنشاء USB قابل للتمهيد.` |
| Requirements card title | `المتطلبات` |
| Requirement 1 | `استخدام USB بسعة لا تقل عن 8GB.` |
| Requirement 2 | `التأكد من عدم وجود بيانات مهمة داخل الـ USB.` |
| Primary button | `إنشاء وسائط تثبيت Windows 11` |
| Documentation button | `التعليمات` |
| Footer Back button | `السابق` |
| Footer Next button | `التالي` |
| Running state | `جاري التجهيز` |
| Completed state | `جاهز` |
| Support panel title | `مساعدة` |
| Support panel body | `تحتاج مساعدة؟ يمكنك التواصل مع أخصائي الدعم عبر خادم Discord الخاص بالمتجر.` |

English copy is pending future translation after Arabic approval. Do not add final English copy in this phase.

## Customer-Facing Action Exposure

Only the customer-facing primary action appears for this step.

The visible action is `إنشاء وسائط تثبيت Windows 11`.

Internally, this maps later to `Apply` for `reinstall`.

Do not show internal action names to the customer:

- Analyze
- Open
- Apply
- Default
- Restore

Do not show any unapproved runtime labels or technical labels.

## No Confirmation Behavior

Pressing the primary button should start the customer-facing flow directly.

No confirmation overlay appears for this step.

No checkbox appears for this step.

No overlay `رجوع` button appears for this step.

No Cancel appears.

In the isolated prototype, the action is simulated only.

In the final integrated implementation, this button maps to the real controlled `Apply` behavior after a later approved integration phase.

## Customer State Behavior

`التالي` starts disabled or inactive.

When the customer presses `إنشاء وسائط تثبيت Windows 11`, show:

`جاري التجهيز`

After simulated or proper completion, show:

`جاهز`

Then enable `التالي`.

Do not auto-advance.

Wait for the customer to press `التالي`.

No result details or notes are shown to the customer for this step.

## USB Safety Boundary

The customer-facing step requires a USB of at least 8GB.

The customer-facing copy warns to ensure there is no important data on the USB.

This documentation phase does not touch USB devices.

The isolated prototype must not create, format, erase, or modify any USB device.

The real integrated implementation must remain controlled and owner-approved before any USB/media behavior is connected.

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
- no confirmation overlay for this step

## Non-Goals

This phase does not include:

- UI implementation
- runtime implementation
- real Apply execution
- Windows Media Creation Tool download
- USB detection
- USB formatting
- USB file operations
- persistence implementation
- MainWindow integration
- English translation
- localization implementation
- website/command-launch implementation
