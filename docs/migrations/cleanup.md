# Cleanup Migration Record

## Source Reference

- Tool id: `cleanup`
- Tool name: Cleanup
- Stage: Windows
- Source script path: `source-ultimate/6 Windows/22 Cleanup.ps1`
- Source SHA-256: `13C3933AC95A9817E48C0FFA4971FB2CC2234F9783831C34675F9F529F2D507E`

## Phase 154 Acceptance

Yazan approved complete exact Ultimate parity for Cleanup in Phase 154.
BoostLab preserves the source as one `Apply` action. The source has no
`Default`, `Open`, or `Restore` branch.

## Source Behavior

Ultimate requires Administrator rights, then runs these operations in order:

1. `Remove-Item -Path "$env:USERPROFILE\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue`
2. `Remove-Item -Path "$env:SystemDrive\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue`
3. `Remove-Item "$env:SystemDrive\inetpub" -Recurse -Force -ErrorAction SilentlyContinue`
4. `Remove-Item "$env:SystemDrive\PerfLogs" -Recurse -Force -ErrorAction SilentlyContinue`
5. `Remove-Item "$env:SystemDrive\Windows.old" -Recurse -Force -ErrorAction SilentlyContinue`
6. `Remove-Item "$env:SystemDrive\DumpStack.log" -Force -ErrorAction SilentlyContinue`
7. `Start-Process cleanmgr.exe`

There are no registry writes, policy writes, services, scheduled tasks,
process stops, downloads, installers, packages, drivers, TrustedInstaller
flows, Safe Mode flows, or reboots in the source.

## BoostLab Mapping

BoostLab maps the source to `Apply` only. Runtime deletion and `cleanmgr.exe`
launch are implemented through injectable adapters so validators can prove the
operation order and verification contract without touching host cleanup state.

The action requires explicit confirmation, verifies the immutable source
checksum before mutation, requires Administrator rights, records every target
attempt, launches Disk Cleanup, and verifies each source target is absent or
has no matching wildcard contents.

## Default And Restore Boundary

Cleanup has no source-defined Default branch. BoostLab does not invent one.
Cleanup also has no captured-state Restore contract and no quarantine path.
Deleted files and directories are not restored by this tool.

## Validator Safety

Automated tests use static inspection and injected mocks only. They must not
delete files or directories, clear Temp, remove Windows.old, mutate caches,
launch `cleanmgr.exe`, change registry/policy/services/tasks/processes, run
downloads/installers, or reboot.
