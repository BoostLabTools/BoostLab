# BoostLab Migration Records

Every tool must have an approved migration record before production behavior is added or expanded. The record is the review boundary between the historical Ultimate implementation and approved BoostLab behavior.

Migration records live under `docs/migrations/` and use the tool ID as the filename where practical.

## Required Record

Each record must contain:

* **Tool name**
* **Stage**
* **Source script path**
* **Source checksum** using SHA-256
* **Original Ultimate behavior summary**
* **Approved BoostLab behavior**
* **Preserved commands**
* **Intentional deviations**
* **Side effects**
* **Required privileges**
* **Capabilities**
* **Risk level**
* **Confirmation requirements**
* **Rollback/default behavior**
* **Restart behavior**
* **Verification strategy**
* **Expected Apply/Default/Restore state**, where applicable
* **Test requirements**
* **Yazan approval status**

## Governance Rules

The source checksum identifies the exact legacy material reviewed for the migration. A changed source checksum requires another review.

Preserved commands must identify operationally important commands, arguments, paths, registry keys, service names, policies, and execution order. Summaries such as "same behavior" are insufficient for action tools.

Required privileges must identify the source evidence for Administrator, TrustedInstaller, Safe Mode, RunOnce, or other privileged execution. A record must distinguish BoostLab's global Administrator process from a tool's `RequiresAdmin` capability.

If `UsesTrustedInstaller = true`, the record must identify the exact approved source behavior that requires it, the centralized runtime path, confirmation text, logging requirements, and the commands that may run at that privilege. Modules may not add their own TrustedInstaller launcher.

Intentional deviations must explain why the behavior differs, how the effective result changes, and whether the deviation fixes a defect, replaces console interaction, adds safety, or redesigns an assistant. Deviations require explicit Yazan approval.

Capabilities must match `config/Stages.psd1`. Setting a capability does not authorize implementation; it declares the maximum reviewed operational scope.

Default behavior must identify the approved tool default. Restore behavior may be claimed only when BoostLab captures the prior state needed to reverse the action.

For file or registry mutations, a future migration record must identify:

* The exact `config/RollbackPolicy.psd1` scope id.
* Every file path, directory root, registry key, and registry value permitted by that scope.
* The intended mutation type for each target.
* Required backup, hash, metadata, and post-mutation verification.
* Whether rollback restores a captured original or removes a proven operation-created item.
* Directory file-count and byte limits where directory capture is approved.
* Why the scope excludes unrelated files, user data, registry values, and protected hives.

Adding a scope does not itself implement Restore. The module must still expose an approved Restore action, use the capture record before mutation, record post-mutation state, and verify rollback.

For service mutations, a future migration record must identify:

* The exact `config/ServiceRollbackPolicy.psd1` scope id.
* Every exact service name and approved mutation type.
* Original source order for startup-type and start/stop operations.
* Whether delayed auto-start is read or changed.
* Binary path, account, dependencies, description, and failure-action fields that must remain unchanged.
* Which captured fields are rollback eligible.
* Whether the source creates, deletes, or recreates services.
* Whether protected/core services are targeted and the separate approval supporting that scope.
* Read-only verification checks for existence, status, startup type, delayed auto-start, and configuration where available.
* Required Action Plan warnings, Administrator/TrustedInstaller requirements, interruption handling, and rollback limitations.

Adding a service scope does not authorize service execution. The tool phase must still implement the exact approved behavior, record post-mutation state, and prove rollback or explicitly document why rollback is unavailable.

For destructive file cleanup, a future migration record must identify:

* The exact `config/CleanupPolicy.psd1` scope id.
* Every bounded root and exact file or directory target.
* Cleanup type for every target: delete, quarantine, empty directory, or remove generated artifact.
* Why BoostLab owns or is authorized to remove each target.
* Whether recursion is required and the approved file-count/byte limits.
* Whether user data, AppData, package content, system paths, or reparse points are involved.
* Whether Phase 36 state capture is mandatory and the matching rollback scope.
* Whether permanent delete or quarantine is approved.
* Quarantine hash, metadata, record, restore, and expiration requirements.
* Confirmation text and Action Plan details.
* Read-only post-cleanup verification and failure behavior.

Adding a cleanup scope does not authorize broad cleanup. A future tool must preserve approved source behavior while proving that every target remains exact, owned, bounded, confirmed, and verifiable.

For AppX package mutations, a future migration record must identify:

* The exact `config/AppxPackagePolicy.psd1` scope id.
* Every exact package family and approved user scope.
* Package full-name and provisioned-identity discovery rules.
* Whether the package is a framework, dependency, protected Windows package, or system-critical component.
* The exact mutation type for each action: current-user removal, all-user removal, provisioned removal, re-registration, provisioned restore, or registration repair.
* Required pre-mutation inventory fields and record age.
* Source-approved operation order across package, process, service, policy, file, and repair steps.
* Separate approval for all-user or provisioned-image removal.
* Rollback eligibility and the exact captured manifest, install location, or provisioned identity required for restore.
* Behavior when package content or registration manifests are missing.
* Action Plan warnings, confirmation text, verification checks, and persisted post-mutation state.
* Additional download, installer, service, cleanup, file/registry, TrustedInstaller, or reboot foundations required by the source.

Adding an AppX package scope does not authorize mutation. A future tool phase
must still implement the exact approved package behavior, use the centralized
inventory and execution boundaries, and prove that restore is record-based
rather than broad package re-registration.

For reboot-capable or post-reboot workflows, a future migration record must identify:

* The exact `config/RebootRecoveryPolicy.psd1` scope id.
* Exact tool/action identities and approved reboot type.
* Whether reboot is immediate, manual, firmware, Safe Mode, or followed by resume.
* Every required pre-reboot checkpoint and its evidence source.
* Every required file, registry, service, package, driver, cleanup, or other state record.
* Exact ordered resume handler ids and trusted artifact paths.
* Why no resume step contains arbitrary commands, scripts, arguments, URLs, or untrusted paths.
* Workflow expiration, cancellation eligibility, warning text, and recovery instructions.
* Expected machine-state conditions before resume.
* Post-reboot verification checks and failure behavior.
* How interrupted, cancelled, expired, mismatched, and failed workflows are surfaced.
* Additional download, installer, driver, TrustedInstaller, Safe Mode, BCD, service, security, or rollback governance required by the source.

Adding a reboot scope does not authorize reboot or scheduling. A future tool
phase must separately implement the exact approved runtime boundary and prove
that interrupted or failed continuation cannot run silently.

For driver, device, package, or vendor-profile mutations, a future migration
record must identify:

* The exact `config/DriverStatePolicy.psd1` scope id.
* Exact tool/action, device class, device instance, hardware id, vendor, and driver package identities.
* The exact allowed mutation type and source-defined operation order.
* Pre-mutation inventory fields, source-store/package requirements, and rollback eligibility.
* Whether the behavior is GPU-specific and proof that only the supported NVIDIA branch is active.
* Required Phase 35 artifact provenance for install/update.
* Required Phase 40 reboot workflow for reboot-capable mutations.
* Associated service, file, registry, AppX, cleanup, installer, and state-capture references.
* Exact verification checks for device identity, provider, version, INF/package, status, and problem code where applicable.
* Behavior for missing packages, missing source content, identity drift, unsupported hardware, and failed verification.
* Rollback limitations and confirmation/recovery requirements.

Adding a driver scope does not authorize driver execution. A future tool phase
must separately approve the exact NVIDIA-supported source behavior, execution
callbacks or runtime implementation, artifact/package sources, verification,
and rollback. AMD and Intel GPU branches remain unsupported.

For TrustedInstaller-level operations, a future migration record must identify:

* The exact `config/TrustedInstallerPolicy.psd1` scope id.
* Exact tool, action, requested identity, command id, executable/helper id, structured argument tokens, and working directory.
* Every exact file, registry, service, package, driver, or other affected target.
* Why TrustedInstaller is required by the approved Ultimate source and why Administrator is insufficient.
* Required file/registry, service, AppX, cleanup, reboot, driver, and provenance references.
* Action Plan warning and confirmation text.
* Administrator host validation, timeout, logging, cancellation, and recovery behavior.
* Structured verification checks and failure behavior.
* Why no raw command, external elevation utility, network path, service hijack, Scheduled Task, ACL, or ownership workaround is used.

Adding a TrustedInstaller scope does not authorize execution. A future phase
must separately approve the exact implementation and prove that the privileged
operation cannot escape its recorded command and target scope.

For Safe Mode entry, continuation, exit, or recovery, a future migration record
must identify:

* The exact `config/SafeModeRecoveryPolicy.psd1` scope id.
* Exact tool/action identity and approved Safe Mode type.
* The matching verified Phase 40 reboot workflow scope and record.
* Every required pre-Safe-Mode checkpoint and evidence source.
* Every required file/registry, service, AppX, cleanup, driver, provenance, installer, TrustedInstaller, or other state reference.
* Exact ordered resume handler ids and trusted local artifact paths.
* The complete Safe Mode exit strategy, handler id, expected conditions, verification, and recovery instructions.
* Why no record contains arbitrary commands, scripts, executables, arguments, URLs, network paths, or dynamic shell content.
* Expiration, cancellation eligibility, user warning, and technician recovery guidance.
* Machine-state conditions required before resume and exit.
* Post-resume verification checks and structured failure behavior.
* Behavior for missing, corrupt, stale, expired, mismatched, cancelled, incomplete, or state-drifted records.

Adding a Safe Mode scope does not authorize BCD changes, reboot, scheduling,
service work, TrustedInstaller, or tool execution. A future phase must
separately approve the exact runtime implementation and prove that the machine
cannot enter Safe Mode without a known bounded resume and exit path.

Real Apply, Default, and Restore migrations should document post-action verification whenever the resulting state can be detected safely. The record must distinguish command completion from detected-state verification and describe:

* Read-only checks used
* Expected state for each real action
* Conditions that produce `Passed`, `Warning`, or `Failed`
* Known UI, policy refresh, sign-out, or restart caveats

Verification must not add writes, retries, restarts, or side effects that are absent from the approved behavior.

The approval status must be one of:

* `Draft`
* `Review required`
* `Approved by Yazan`
* `Rejected`

Approval applies only to the behavior and source checksum recorded in that document.
