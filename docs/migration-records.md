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
