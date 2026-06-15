# TrustedInstaller Execution Foundation

## Purpose

Phase 42 defines how a future BoostLab tool may request a narrowly scoped
TrustedInstaller-level sub-operation.

It does not implement TrustedInstaller execution. It approves no production
scope, starts no process, changes no service, ACL, ownership, registry, file,
package, driver, task, or boot state, and enables no tool.

## TrustedInstaller in BoostLab

TrustedInstaller is a Windows servicing identity with access beyond a normal
Administrator process for some protected resources.

BoostLab runs globally as Administrator. The whole application must never run
as TrustedInstaller because that would give unrelated UI, logging, module
loading, and runtime code unnecessary privileged access.

Only a future explicitly approved sub-operation may request
`NT SERVICE\TrustedInstaller`, and only through the centralized policy and
execution boundary.

## Deny-by-Default Policy

`config/TrustedInstallerPolicy.psd1` contains an empty
`TrustedInstallerScopes` collection.

Every production request is therefore blocked until a future phase adds an
exact reviewed scope. A scope must define:

* Tool, action, and scope ids
* Requested identity
* Known command ids
* Exact executable paths or approved helper ids
* Structured argument tokens
* Exact working directories
* Exact file, registry, service, and package targets
* Required adjacent foundations
* Confirmation and Administrator-host requirements
* Required state capture and verification
* High risk classification
* Timeout and logging requirements
* Cancellation and recovery behavior

Unknown tools, actions, commands, targets, and argument tokens are denied.

## Structured Commands

Requests must use a command descriptor. They may not contain:

* Raw command lines
* Shell strings
* Script blocks
* Editable executable arguments
* URLs or network paths
* Wildcards or broad target scopes

PsExec, NSudo, PowerRun, AdvancedRun, service hijacking, temporary services,
Scheduled Task elevation, COM elevation, token theft, ACL changes, and
ownership changes are not approved Phase 42 mechanisms.

Executable paths must be exact local paths in the command allowlist. External
elevation binaries are denied by default even when present locally.

## Request Model

A structured request records:

* Operation, tool, action, timestamp, schema, and BoostLab version
* Requested identity and command id
* Executable/helper identity and argument tokens
* Working directory
* File, registry, service, and package targets
* Required foundations and verified state references
* Matching Action Plan and confirmation
* Verified Administrator host
* Verification plan
* Risk, timeout, logging, cancellation, and recovery metadata

Missing or stale information blocks the request.

## Target Safety

All targets must exactly match a future policy scope.

Drive roots, registry hive roots, wildcard services/packages, network paths,
and unknown targets are blocked. Protected Windows files, registry areas,
services, and packages require a future explicit tool-specific scope and do
not become approved merely because TrustedInstaller is requested.

## Adjacent Foundations

TrustedInstaller privilege does not replace other governance:

* File and registry rollback: Phase 36
* Service rollback: Phase 37
* Cleanup and quarantine: Phase 38
* AppX inventory and restore: Phase 39
* Reboot and recovery: Phase 40
* Driver state and rollback: Phase 41
* Download provenance and installer policy: Phase 35

A future scope lists the foundations it requires, and the request must contain
verified matching references.

## Verification and Logging

Every request requires a structured verification plan with named checks,
approved method ids, target references, and expected values.

Execution results must log the requested identity, command id, target scope,
status, and refusal reason. Failures must remain visible and structured.

`Test-BoostLabTrustedInstallerMockResult` can validate local mocked result
objects without requiring TrustedInstaller access or starting a process.

## Execution Boundary

`core/TrustedInstallerExecution.psm1` validates a request again immediately
before the future execution boundary.

In Phase 42:

* Invalid requests return `Blocked`.
* Valid future-shaped requests return `NotImplemented`.
* `ProcessStarted` is always `false`.
* `CommandExecuted` is always `false`.

There is no built-in process launcher or privileged command.

## Deferred Tools

Services Optimizer, Defender Optimize Assistant, Control Panel Settings,
GameBar, Edge & WebView, and other heavy tools remain blocked.

Phase 42 provides only one prerequisite. Those tools still need exact
tool-specific scopes, source-preserving command design, and all adjacent
foundations required by their Ultimate behavior.
