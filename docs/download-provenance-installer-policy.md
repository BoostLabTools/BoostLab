# Download Provenance and Installer Execution Policy

## Purpose

Several deferred BoostLab tools depend on downloaded executables, archives, setup programs, repair packages, or redistributables. Running those sources directly would make mutable URLs and unverified temporary files part of BoostLab's trusted execution path.

Phase 35 creates a deny-by-default contract before any such tool is implemented. It approves no real third-party artifact, performs no download, launches no installer, and changes no existing tool behavior.

## Production Files

* `config/ArtifactProvenance.psd1` is the centralized artifact allowlist.
* `core/DownloadProvenance.psm1` validates manifest records and local artifacts.
* `core/InstallerExecution.psm1` validates installer requests and exposes an inert execution boundary.

The production manifest is intentionally empty in Phase 35.

## Artifact Record Contract

Every future artifact record must contain:

* `Id`: stable artifact identifier.
* `DisplayName`: user-facing artifact name.
* `SourceUrl`: reviewed HTTPS origin.
* `ExpectedSha256`: exact 64-character SHA-256.
* `ExpectedFileName`: exact local file name without a path.
* `ExpectedSizeBytes`: exact size when stable, or zero when bounds are used.
* `MinimumSizeBytes`: lower size bound, or zero when not used.
* `MaximumSizeBytes`: upper size bound, or zero when not used.
* `ArtifactType`: `NonExecutable`, `Archive`, `Executable`, or `Installer`.
* `ExpectedPublisher`: required signer/publisher text for executable content allowed to run.
* `SourceToolIds`: approved future consumer tool ids.
* `LicenseNote`: known license or redistributability information, including an explicit unknown note when unresolved.
* `AllowExecution`: whether a future policy may consider execution.
* `RequiresAdmin`: whether the approved artifact execution requires Administrator rights.
* `CanReboot`: whether execution can request or cause restart.
* `VerificationRequirements`: required checks such as `FileName`, `SHA256`, `FileSize`, and `AuthenticodeSigner`.
* `ApprovalStatus`: `Proposed`, `Approved`, or `Revoked`.

An artifact record describes evidence and policy. It does not implement a tool and does not grant generic execution permission.

## Deny By Default

The following conditions block use:

* Unknown artifact id is blocked.
* Artifact is not listed in the production manifest.
* Manifest record is malformed.
* Approval status is not `Approved`.
* Source URL is not HTTPS.
* SHA-256 is missing, malformed, or mismatched.
* File name is mismatched.
* Required size constraint is mismatched.
* Executable content lacks a signer/publisher requirement.
* Authenticode status or publisher does not match.
* Artifact is explicitly non-executable.
* Artifact is requested by an unapproved tool id.
* Local path is missing or is a network URL.

Missing signer policy is acceptable only when `AllowExecution = false`. Such content may be verified for non-executing use but cannot enter installer execution.

## Installer Execution Contract

A future installer execution request must provide:

* A successful provenance result for the exact local file.
* An artifact with `ApprovalStatus = Approved`.
* `AllowExecution = true`.
* `ArtifactType = Executable` or `Installer`.
* A consumer tool id listed in `SourceToolIds`.
* A matching Action Plan tool id and action id.
* `NeedsExplicitConfirmation = true`.
* Explicit user confirmation.
* The exact local command line and source-approved switches.
* A bounded timeout.

A future executing implementation must also:

* Log process start and finish.
* Capture process id, exit code, and timeout.
* Never execute directly from a URL.
* Never execute an unverified temporary file.
* Never execute unsigned or hash-mismatched executable content.
* Never add unrelated cleanup.
* Never infer or silently add switches.
* Never treat silent installation as approved unless the source switches and rationale are documented.

`Invoke-BoostLabInstallerExecution` is intentionally inert in Phase 35. A valid request returns `NotImplemented`; a bad request returns `Blocked`. Both report `ProcessStarted = false`.

## Future Approval Workflow

1. Add a proposed artifact record to the provenance manifest.
2. Manually verify the authoritative source URL, file name, SHA-256, size, Authenticode signer, publisher, license, redistributability, privilege needs, and reboot behavior.
3. Obtain Yazan's approval and mark the exact reviewed artifact `Approved`.
4. Add static and mocked tests for valid, mismatched, revoked, unsigned, and wrong-consumer cases.
5. Update the tool migration record with the exact command line, switches, side effects, verification, timeout, and rollback behavior.
6. Only then wire the approved tool to a future execution implementation.

Changing an upstream binary requires a new hash and a fresh review. A mutable "latest" URL does not bypass this process.

## Deferred Tools Affected

This foundation is required by, but does not yet implement:

* Reinstall
* Edge Settings
* Installers
* Driver Install Debloat & Settings
* DirectX
* Visual C++
* GameBar
* Edge & WebView
* Resizable BAR Assistant
* Timer Resolution Assistant, for any distributed or built executable provenance

Many of these tools remain blocked by additional foundations such as installer rollback, service state capture, driver rollback, AppX restoration, destructive cleanup governance, or reboot recovery.
