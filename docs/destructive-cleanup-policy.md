# Destructive Cleanup Policy Foundation

## Purpose

Cleanup tools can remove large amounts of data quickly. A source script that names a directory does not by itself prove that every future file under that directory belongs to BoostLab, is safe to remove, or can be recovered.

Phase 38 establishes a centralized deny-by-default contract for future bounded deletion, quarantine, generated-artifact removal, and directory cleanup. It does not enable Cleanup or any other deferred tool, approve a production cleanup target, or delete a real file.

## Production Files

* `config/CleanupPolicy.psd1` contains future exact cleanup scopes.
* `core/CleanupPolicy.psm1` validates scopes and targets, inspects bounded state, builds cleanup plans, validates state-capture evidence, and manages integrity-protected quarantine records.
* `core/CleanupExecution.psm1` validates confirmation and execution requests, then exposes callback-only cleanup and quarantine-restore boundaries.

Production `CleanupScopes` are empty in Phase 38. Every production cleanup request is blocked until a future approved migration adds an exact bounded scope.

The execution module contains no built-in delete, move, recursive cleanup, or quarantine command. Future operations must pass all policy gates before a caller-supplied executor can be invoked.

## Cleanup Model

Every cleanup plan includes:

* Operation id
* Tool id and action id
* Timestamp
* Schema version and BoostLab version
* Original target path
* Normalized resolved path
* Target type: file or directory
* Cleanup type: delete, quarantine, empty directory, or remove generated artifact
* Explicit cleanup reason
* Risk classification
* Required confirmation level
* Rollback eligibility
* State-capture requirement
* Verification requirement
* Exact allowlist scope id
* Recursive flag and file-count/byte limits
* Original read-only target snapshot

Cleanup plans are dry-run objects. Creating a plan does not delete, move, or modify the target.

## Exact Bounded Scopes

A future scope must declare:

* Exact tool ids
* One bounded root
* Exact target paths
* Allowed target types
* Allowed cleanup types
* Whether recursive processing is allowed
* Positive file-count and byte limits for recursive cleanup
* Whether reparse points are allowed
* Whether user document locations are allowed
* Whether pre-mutation state capture is required
* Whether permanent deletion or quarantine is allowed

The following are denied:

* Missing or unknown scopes
* Wildcards and wildcard-only paths
* Relative paths
* Path traversal
* Unresolved environment-variable paths
* Targets outside the exact approved root
* Targets not present in the exact allowlist
* Drive roots
* Windows and System32 roots
* Program Files roots
* ProgramData root
* User-profile root
* Desktop, Documents, and Downloads roots
* AppData roots
* Temp root
* Symlinks, junctions, and reparse points unless a future explicit scope permits them
* Recursive cleanup without explicit limits

User documents remain denied unless a future tool-specific scope explicitly identifies the exact bounded target and receives separate approval. A scope must never treat an entire user library as a cleanup target.

## State Capture and Confirmation

Every destructive operation requires a matching Action Plan with explicit confirmation.

When cleanup is rollback eligible, or the scope requires capture, execution is blocked until valid Phase 36 file state-capture evidence is supplied. The evidence must match:

* Tool id
* Action id
* Exact normalized source path
* File or directory type
* Rollback eligibility

This connects cleanup governance to the file state-capture foundation without automatically wiring either foundation into a tool.

## Permanent Delete

Permanent delete is allowed only when the scope explicitly sets `AllowPermanentDelete = true`.

The Phase 38 helper does not implement deletion. A future tool must provide a narrow executor after validation and must return a structured result. A separate verifier must report `Passed`; missing or contradictory verification returns a structured failure.

Permanent deletion is not a substitute for quarantine and must not be selected merely because a source script used broad recursive deletion.

## Quarantine

Quarantine is a future alternative to permanent deletion for exact approved targets. The planned destination is operation-specific under:

```text
$env:ProgramData\BoostLab\State\Cleanup\Quarantine
```

Every quarantine record contains:

* Tool/action/operation identity
* Original and normalized paths
* Original content or manifest hash
* Original metadata
* Quarantine path and hash
* Reason and risk
* Restore eligibility
* Verification requirements

The quarantined hash must match the captured original hash. Records are stored in SHA-256 integrity-protected JSON envelopes.

Quarantine restore requires:

* A valid non-stale BoostLab quarantine record
* Matching tool and action identity
* Explicit confirmation
* Exact scope approval
* An absent original target, so unrelated data is not overwritten
* A quarantined target with the recorded hash
* No reparse point
* Structured post-restore verification

Phase 38 performs no real quarantine or restore operation.

## Relationship to File Rollback

Phase 36 captures original file state and can restore a verified backup for approved tool-specific scopes.

Phase 38 decides whether a destructive cleanup request is bounded and authorized. It requires Phase 36 evidence when rollback is claimed. Cleanup policy does not broaden the Phase 36 file allowlist and does not infer that every deleted item is rollback eligible.

`Default`, `Restore`, permanent delete, and quarantine are distinct:

* `Default` applies source-approved default behavior.
* `Restore` returns to a captured prior state.
* Permanent delete removes an approved target with no quarantine copy.
* Quarantine moves an approved target into BoostLab-owned storage with a verified restore record.

## Why Deferred Tools Remain Blocked

This foundation is relevant to:

* Cleanup
* Bloatware
* Edge & WebView
* Control Panel Settings
* GameBar
* Driver Install Debloat & Settings
* Write Cache Buffer Flushing
* Timer Resolution Assistant

They remain deferred because exact cleanup scopes have not been approved and their source behavior also depends on AppX/package handling, services, installers, downloads, drivers, TrustedInstaller, Safe Mode, registry rollback, reboot recovery, or broad multi-target ownership decisions.

Phase 38 does not authorize partial implementations that silently weaken Ultimate behavior. Future migrations must define each exact target, ownership rule, rollback/quarantine decision, verification strategy, and remaining infrastructure dependency.
