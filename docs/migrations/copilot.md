# Copilot Migration Record

## Source

* Source path: `source-ultimate/6 Windows/8 Copilot.ps1`
* SHA-256: `21B58212B241A6C0B74582063E3E74F746014E9137194B58B088CC6692F22A90`

## Phase 142B Result

Copilot is implemented as exact Ultimate parity after Yazan approved the full
source scope. This is not a final exception and not a weakened subset.

## Implemented Behavior

Apply maps to the source `Copilot: Off (Recommended)` branch:

* Stop all source-defined named processes.
* Stop all running processes whose process name matches `*edge*`.
* Remove all-users AppX packages whose name matches `*Copilot*`.
* Set `HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot`
  `TurnOffWindowsCopilot` to `REG_DWORD 1`.
* Set `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot`
  `TurnOffWindowsCopilot` to `REG_DWORD 1`.

Default maps to the source `Copilot: Default` branch:

* Re-register all-users AppX packages whose name matches `*Copilot*` from each
  package `AppXManifest.xml`.
* Delete the HKCU WindowsCopilot policy key.
* Delete the HKLM WindowsCopilot policy key.

## Boundaries

Copilot exposes only `Apply` and `Default`. It does not expose `Open` or
`Restore`, and `Default` is not captured-state `Restore`.

The implementation adds no downloads, installers, services, scheduled tasks,
drivers, TrustedInstaller flow, Safe Mode flow, file cleanup, or reboot
behavior. Tests use mocked adapters and do not stop processes, mutate AppX
packages, or write registry policy state.
