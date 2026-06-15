# Driver State Capture and Rollback Foundation

## Purpose

Phase 41 establishes the governance boundary required before BoostLab can
install, update, uninstall, disable, enable, debloat, profile-configure, remove,
or roll back a driver.

This phase does not implement a driver tool. It performs no real driver query
or mutation, approves no production device, and is not imported by the live
tool runtime.

## Production Policy

`config/DriverStatePolicy.psd1` contains:

* Schema version
* Maximum record age
* Exact future driver scopes

`DriverScopes` is empty in Phase 41. The production result is therefore
deny-by-default for every tool, device, package, and mutation.

Future scopes must explicitly declare:

* Scope, tool, and action ids
* Exact device classes, instance ids, and hardware ids
* Exact vendor ids and names
* Exact driver package identities
* Allowed mutation types
* Approved artifact ids
* Reboot-capable mutations
* Required related state foundations
* Provenance, reboot, package-removal, profile-import, component-removal, and confirmation permissions

Class-only, wildcard, partial, or unknown identities are invalid.

## Supported Product Scope

GPU-specific BoostLab behavior is NVIDIA-only.

That scope does not create an implicit NVIDIA allowlist. A future migration
must still add exact NVIDIA device, hardware, package, artifact, action, and
mutation identities.

AMD and Intel GPU-specific operations are blocked and must remain disabled or
visual-only unless Yazan changes the product scope.

## Inventory Contract

`New-BoostLabDriverInventoryRecord` accepts an injected read-only device
inspector. It records:

* Operation, tool, action, timestamp, schema, and BoostLab version
* Device class, instance id, and hardware ids
* Vendor id and name
* Driver provider, version, and date
* INF name, published name, and matching package identity
* Device status and problem code
* Associated services and files
* Source-store location
* Intended mutation type
* Rollback eligibility
* Artifact provenance evidence
* Reboot workflow reference
* Related state-capture references
* Verification requirements
* Risk classification

Inventory is mandatory before mutation. A mutation plan cannot be created
from an ad hoc device path or package name.

## Mutation Types

The foundation recognizes only:

* `Install`
* `Update`
* `Uninstall`
* `Rollback`
* `Disable`
* `Enable`
* `RemovePackage`
* `ProfileImport`
* `DebloatComponentRemoval`

Recognition is not authorization. Each type must appear in the exact future
scope.

Package removal additionally requires the exact captured device and package
identity. Broad driver-store cleanup is prohibited.

## Cross-Foundation Requirements

Install and update require verified Phase 35 artifact provenance. Missing or
mismatched provenance blocks the plan.

Reboot-capable mutations require a matching verified Phase 40 workflow
reference.

Associated changes remain separately governed:

* Services: Phase 37
* Files and registry: Phase 36
* Cleanup/quarantine: Phase 38
* AppX packages: Phase 39
* Downloads/installers: Phase 35
* Reboot/resume: Phase 40

A driver scope cannot authorize these side effects by itself.

## Rollback Contract

Rollback requires:

1. An integrity-verified record under the BoostLab driver state root.
2. A non-stale record matching the requested tool, action, scope, and device.
3. A recorded mutation with `Passed` or `Warning` verification.
4. Stable current device instance, vendor, and hardware identity.
5. Original INF, package identity, and source-store information.
6. Matching Action Plan confirmation.
7. Any required provenance, state, and reboot references.

Rollback is blocked when the record is missing, corrupt, stale, mismatched,
outside the state root, already used, not rollback eligible, or incomplete.
It is also blocked when current device identity drifted or required package
source information is unavailable.

Rollback never downloads or installs missing replacement content implicitly.

## Execution Boundary

`core/DriverExecution.psm1` exposes callback-only mutation and rollback
functions. Callbacks exist so tests and future narrowly approved runtime
implementations can be isolated and verified.

The foundation contains no built-in:

* `pnputil`
* DISM driver command
* PnP device enable/disable/uninstall command
* Installer launch
* Driver package removal
* Profile import
* Device enumeration
* Download
* Reboot

Both mutation and rollback require a validated dry-run plan, matching Action
Plan, explicit confirmation, structured verification, and persisted state.

## Deferred Tools

This foundation is required by:

* Driver Install Debloat & Settings
* Resizable BAR Assistant

Neither tool is enabled by Phase 41. Their remaining blockers include exact
NVIDIA scopes, artifact provenance, installer/profile approval, file/service
state handling, cleanup policy, reboot workflow, and tool-specific rollback
and verification decisions.
