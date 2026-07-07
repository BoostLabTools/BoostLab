# AXIS Product Direction Lock

## Purpose

This document records the owner-final AXIS product direction after completion of the isolated AXIS first-use wizard prototype.

This is a documentation-only lock. It does not implement UI, runtime behavior, website work, licensing, Discord bots, instruction linking, or production wiring.

Related completion record:

- `docs/design/AXIS-First-Use-Wizard-Prototype-Completion-Record.md`

Older AXIS design notes that mention English support, language switching, dashboards, free-control mode, or later dashboard entry are historical only. This document supersedes those directions.

## 1. Product Language Direction

Owner decision: AXIS is Arabic-only.

- AXIS customer-facing UI is Arabic-only.
- AXIS website will also be Arabic-only.
- No English product version is planned now or in the future.
- Do not plan language switching.
- Do not plan `/en` routes.
- Do not plan English website pages.
- Do not plan English customer copy.

Product and technology names may remain in English when they are actual names, including:

- Windows
- NVIDIA
- DirectX
- Visual C++
- BitLocker
- Microsoft Edge
- Microsoft Store
- Defender
- Timer Resolution
- Epic Games
- Discord
- Cloudflare

## 2. Dashboard Cancellation

Owner decision: the post-wizard dashboard/free-control idea is permanently cancelled.

- AXIS should not transition to a dashboard after the wizard.
- Do not implement a post-completion dashboard.
- Do not implement free-control mode.
- Do not implement a dashboard-style tool picker after wizard completion.
- The guided wizard design is the long-term customer flow.
- The customer completes the guided flow and reaches a final completion page.

## 3. Future Intro And Final Pages

Owner decision: add these pages later, not in this phase.

Future intro/welcome page:

- Appears before the existing first tool step.
- Gives a short overview of AXIS.
- Explains that AXIS guides the customer step by step.
- Uses the same current wizard visual design.
- Arabic-only.

Future final completion page:

- Appears after the last tool step.
- Tells the customer that setup is complete.
- Does not transition to a dashboard.
- Uses the same current wizard visual design.
- Arabic-only.

Do not implement these pages in this phase.

## 4. Instructions Website And Linking

Owner decision: instruction button linking is deferred.

- The AXIS customer/store/instruction website does not exist yet.
- The AXIS website will be built later from scratch on a Cloudflare-based platform.
- Do not link Instructions buttons until the website and per-step instruction pages exist.
- Do not add placeholder URLs.
- Do not add temporary links.
- Do not add English instruction pages.

Future work after the website exists:

- Define per-step Arabic instruction pages.
- Map each AXIS step/tool id to an instruction URL.
- Then implement Instructions button linking.

## 5. Branding Rule

- AXIS is the customer-facing product name.
- BoostLab remains internal repository/code branding for now.
- Normal AXIS customer UI must not show BoostLab.
- Customer-facing website should use AXIS, not BoostLab.
- Internal docs may mention BoostLab only when clearly internal.

## 6. Owner-Approved Roadmap

The owner-approved roadmap order is locked as follows.

1. Product Direction Lock
   - This phase.
   - Documentation-only.
   - Locks Arabic-only, no dashboard, deferred instructions website/linking, and future roadmap.

2. Add intro/welcome and final completion pages
   - Add first intro page before the existing wizard flow.
   - Add final completion page after the last Advanced step.
   - Keep the same guided wizard design.
   - No dashboard.

3. Persistence/resume system
   - Save customer position globally.
   - Resume after restart.
   - Track current stage/step and expected restart flows.
   - Important for BIOS, To BIOS, Driver Clean, Defender Optimize, and Restart After Installers.

4. Convert prototype simulation to real runtime
   - Wire every agreed button/action exactly.
   - Convert Apply/Open/Restart simulations to real approved behavior.
   - Create future AXIS custom restart action for `restart-after-installers`.
   - Do not weaken or change original BoostLab script behavior unless the owner explicitly requests it.
   - This is the production wiring phase.

5. Full user testing on second computer
   - Owner will test AXIS from start to finish on a second PC.
   - Owner will record all notes, bugs, performance issues, UI issues, and functional issues.
   - Fixes will follow from that test report.

6. Build full AXIS website/platform on Cloudflare
   - Build the Arabic AXIS customer/store/instruction website from scratch.
   - Include product website, purchase flow, access flow, per-step instruction content, and license/key system.
   - Prompt the owner at the start of this phase:
     - "يزن، الآن راح نبدأ مرحلة الموقع. اطرح أفكارك كاملة عشان نرتبها وننفذها صح."
   - This phase will include many decisions and must not be rushed.

7. Link Instructions buttons to website
   - Only after the website and instruction pages exist.
   - Add per-step URL mapping.
   - Link AXIS instruction buttons to the correct Arabic pages.

8. Discord store/server bot systems
   - Build Discord bots for store/support/server workflows.
   - This may be tied to the website phase or separated later.
   - Details will be decided later by the owner.

## 7. Website And Platform Future Notes

These notes are future planning only, not implementation.

- Website/platform will be Cloudflare-based.
- Likely components may include Cloudflare Pages, Workers, D1, and R2, subject to future planning.
- Site and instruction content will be Arabic-only.
- The website phase may include purchase/access workflow.
- The owner wants a launch/install pattern similar to `irm <AXIS-site-url> | iex`.
- The customer should receive a personal key after purchase.
- When AXIS/bootstrapper runs, it should request the customer key before allowing use.
- The key/license system should be smart, not a simple/basic key check.
- Exact licensing, payment, and security design is not decided in this phase.
- Do not implement any website, payment, license, bootstrapper, or key validation in this phase.

## 8. Removed From Roadmap

The following are removed or cancelled as standalone future directions:

- English version.
- English website.
- Language switcher.
- Post-wizard dashboard.
- Free-control dashboard.
- Instruction button linking before the website exists.
- Standalone "Runtime safety and diagnostics" phase.

Do not create a standalone phase named Runtime safety and diagnostics. Normal validation and testing required during production wiring may still happen as part of the conversion phase, but it must not be listed as a separate roadmap phase.
