# File and Registry State Capture and Rollback

## Purpose

Future BoostLab tools may overwrite or delete files, create scoped artifacts, or change registry values. Command success alone does not provide a safe inverse. A useful Restore action needs evidence of what existed before the operation, where it belonged, and whether the current state is still the state created by that operation.

Phase 36 establishes that evidence and restore boundary. It does not add a Restore action to any tool and approves no production capture scope.

## Production Files

* `config/RollbackPolicy.psd1` contains future exact file and registry scopes.
* `core/StateCapture.psm1` validates scope, captures state, creates verified backups, and stores integrity-protected records.
* `core/Rollback.psm1` validates records, backups, current state, and exact target identity before restore.

Production `FileScopes` and `RegistryScopes` are empty in Phase 36. Nothing is capturable or restorable until a future approved tool phase adds a bounded scope.

## Rollback Record Contract

Every record contains:

* `OperationId`
* `ToolId`
* `ActionId`
* `Timestamp`
* `SchemaVersion`
* `BoostLabVersion`
* `ScopeId`
* `SourcePath` or `RegistryPath`
* `ValueName` when applicable
* `ItemType`: `File`, `Directory`, `RegistryKey`, or `RegistryValue`
* `OriginalExists`
* `OriginalMetadata`
* `OriginalHash` for file content or a directory manifest
* `BackupLocation`
* `BackupHash`
* `IntendedMutation`
* `RollbackEligible`
* `VerificationRequirement`
* `RiskClassification`
* Post-mutation existence, hash, or registry metadata
* Rollback completion state

Records are saved as JSON envelopes containing the record JSON and its SHA-256. A missing, corrupt, moved-out-of-scope, or hash-mismatched record is blocked.

## File Capture

File capture requires:

* Exact tool id and action id.
* Exact approved scope id.
* Absolute literal path.
* Target inside the approved root.
* Explicit item type and intended mutation.

Before overwrite or delete, an existing file is copied into the operation-specific BoostLab backup directory. The original and backup SHA-256 values must match before capture succeeds.

Directory capture is allowed only by a scope that explicitly enables directories and declares file-count and byte limits. Directory manifests contain relative paths, hashes, lengths, and available timestamps/attributes. Reparse points are rejected so capture cannot traverse junctions or links into unrelated locations.

The following are denied:

* Wildcards.
* Drive roots.
* Windows root.
* Program Files roots.
* User-profile root.
* System32 root.
* Paths outside the exact approved root.
* Reparse-point targets.
* Missing scope or tool identity.

## Registry Capture

Registry capture requires:

* Exact tool id and action id.
* Exact approved scope id.
* Exact HKCU or HKLM key path.
* Explicit value name for `RegistryValue`.
* Value name present in the scope allowlist.

Value capture records prior existence, value type, and value data. Key capture must be explicitly enabled by its scope.

Broad hive roots are denied. Protected `HKLM\SYSTEM` paths are denied unless a future tool-specific scope explicitly approves protected access. Phase 36 provides no such scope.

Tests use callbacks and local in-memory state. They do not access HKLM or protected registry areas.

## Rollback Gates

Rollback runs only when all checks pass:

1. Record exists under the BoostLab rollback records directory.
2. Envelope and record schema are valid.
3. Record hash matches.
4. Tool id and action id match the caller.
5. Scope still approves the exact target.
6. Record is rollback eligible.
7. Post-mutation state was recorded.
8. Current target still matches that post-mutation state.
9. File backup exists inside the operation backup directory.
10. Backup hash matches both the original hash and recorded backup hash.

If any check fails, no restore step is attempted and the structured result is `Blocked`.

File rollback restores the verified captured backup, or removes an operation-created target only when its current hash matches the recorded post-mutation hash. Registry rollback restores the captured value type/data or removes an operation-created value/key through explicit bounded callbacks.

Every attempted restore returns structured `Success`, `Status`, target, errors, verification, and timestamp fields. Restore failures are never silently ignored.

## Default Versus Restore

`Default` applies the approved default behavior defined by the tool and Ultimate migration record. It may be idempotent and does not require a previous BoostLab capture unless that specific implementation says otherwise.

`Restore` returns the exact prior state captured before a specific BoostLab operation. Restore requires a valid rollback record and must not infer previous state.

Adding this foundation does not convert existing `Default` actions into `Restore` actions.

## Deferred Tools Helped Later

This foundation can support future work on:

* Updates Drivers Block
* Start Menu Taskbar
* Edge Settings
* Edge & WebView
* Write Cache Buffer Flushing
* Control Panel Settings
* Cleanup

Those tools remain blocked by their other requirements. Phase 36 does not approve broad cleanup, AppX changes, services, TrustedInstaller, downloads, installers, drivers, reboot workflows, or destructive source behavior.
