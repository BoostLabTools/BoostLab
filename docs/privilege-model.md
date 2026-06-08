# BoostLab Privilege Model

BoostLab preserves the Administrator expectations of approved Ultimate scripts at the application and runtime boundary. `bootstrap.ps1` is the normal entry point and requests elevation before starting the WPF application. Direct execution of `Start-BoostLab.ps1` performs the same check and cannot silently continue without Administrator rights.

## Administrator Model

BoostLab runs as Administrator globally so approved tools can preserve their original execution strength without duplicating self-elevation code in every module.

* `bootstrap.ps1` requests elevation with `RunAs` when needed.
* `Start-BoostLab.ps1` independently enforces elevation for direct launches.
* An elevation-attempt marker prevents repeated relaunch loops.
* `core/Execution.psm1` blocks an implemented action that declares `RequiresAdmin = true` if the runtime is not elevated.
* Modules must not silently self-elevate unless a future migration is explicitly approved to do so.

`RequiresAdmin` remains a tool-level capability. It records whether the approved tool behavior itself requires Administrator rights. A safe launcher can declare `RequiresAdmin = false` even though the BoostLab application process is globally elevated.

## TrustedInstaller Model

Administrator and TrustedInstaller are different privilege levels. BoostLab must never run the entire application as TrustedInstaller.

TrustedInstaller may be used only by a specific approved tool whose reviewed Ultimate source requires it. Such a tool must declare:

* `UsesTrustedInstaller = true`
* `RequiresAdmin = true`
* `NeedsExplicitConfirmation = true`

Its Action Plan must identify the TrustedInstaller requirement, show an elevated execution warning, and receive explicit confirmation. Usage must be logged clearly.

`core/TrustedInstaller.psm1` is the only intended runtime boundary for future TrustedInstaller execution. In Phase 14.5 it is deliberately inert: it can report support status and construct a structured plan, but it cannot start services, modify services, invoke utilities, or execute commands.

## Migration Requirements

Future migrations must:

* Record source privilege markers and privileged commands in the migration record.
* Replace Ultimate per-script console elevation with BoostLab application/runtime elevation.
* Preserve an approved source privilege requirement rather than weakening behavior to avoid elevation.
* Use the centralized TrustedInstaller path only when the approved source requires it.
* Document any intentional privilege deviation and obtain Yazan approval.

## Read-Only Source Audit

The Phase 14.5 audit found:

* 42 source scripts with an Administrator marker
* 4 scripts referencing TrustedInstaller
* 2 scripts referencing Safe Mode
* 5 scripts referencing RunOnce
* 7 scripts with reboot-related commands
* 11 scripts with service manipulation

The catalog was corrected only where source evidence was clear. No source file was changed and no privileged behavior was implemented.
