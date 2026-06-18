# Driver Install Debloat and Settings Scope Provenance Design

## Purpose

This document defines the exact future scope and provenance requirements before
the BoostLab `Driver Install Debloat & Settings` tool can be safely
implemented.

This is documentation and planning only. It approves no production download,
installer, executable launch, driver, driver-profile, AppX, registry, file,
service, task, cleanup, reboot, Default, or Restore scope.

## Source Reference

* Tool id: `driver-install-debloat-settings`
* Tool title: `Driver Install Debloat & Settings`
* Stage: `Graphics`
* Current module: `modules/Graphics/driver-install-debloat-settings.psm1`
* Source path: `source-ultimate/5 Graphics/1 Driver Install Debloat & Settings.ps1`
* Source SHA-256: `E69EFF538E7CE6108233C525A2BB88BA2D549CE6954AE751BE7BED778271C26F`

## Product Scope Decision

GPU-specific tooling is NVIDIA-only.

For this tool:

* The NVIDIA branch is the only branch that may be considered for future
  implementation.
* The AMD branch is unsupported and must remain disabled, visual-only, or
  NotApplicable.
* The Intel branch is unsupported and must remain disabled, visual-only, or
  NotApplicable.
* Shared post-branch behavior must be reviewed carefully. Even if it is
  GPU-neutral, it follows driver install/debloat work and includes registry
  writes plus an unconditional restart, so it is not approved in this phase.

## Source Behavior Summary

The Ultimate source:

* Requires Administrator.
* Checks internet with `Test-Connection -ComputerName "8.8.8.8"`.
* Downloads and installs 7-Zip from a mutable GitHub raw URL.
* Presents a GPU vendor menu:
  * `Write-Host " 1.  NVIDIA"`
  * `Write-Host " 2.  AMD"`
  * `Write-Host " 3.  INTEL`n"`
* Opens a vendor driver download page.
* Lets the user select a downloaded driver executable with `OpenFileDialog`.
* Extracts the selected package with 7-Zip.
* Debloats extracted driver content.
* Runs a driver installer.
* Applies vendor-specific registry, AppX, service, task, file, process, and
  profile changes.
* Opens display, NVIDIA Control Panel, and sound UI pages.
* Writes shared display/MSI/notification registry settings.
* Calls `shutdown -r -t 00`.

Observed inventory counts from the source:

* Unique URL count: `5`
* Non-elevation `Start-Process` command count: `15`
* `Remove-Item` command count: `41`
* `reg add` command count: `33`
* `reg delete` command count: `4`
* `sc stop` command count: `11`
* `sc delete` command count: `11`
* NVIDIA profile setting count in `inspector.nip`: `31`

## Current Decision

Driver Install Debloat & Settings was implemented in Phase 99 as controlled
manual handoff only. Auto remains refused until exact production approvals
exist.

No production download/installer/executable/driver/profile/AppX/registry/file/service/task/cleanup/reboot scopes
are approved in this phase.

Partial registry-only, NVIDIA-page-only, or "install without debloat" behavior
would weaken Ultimate behavior. The supported future NVIDIA path must preserve
the source intent only when artifact provenance, driver inventory, rollback,
cleanup, profile, registry, AppX, reboot, and verification requirements are all
approved.

## Behavior Groups

### 1. GPU/Vendor Detection Behavior

Exact source targets:

* `Write-Host "INSTALL GRAPHICS DRIVERS"`
* `Write-Host "SELECT YOUR SYSTEM'S GPU"`
* `Write-Host " 1.  NVIDIA"`
* `Write-Host " 2.  AMD"`
* `Write-Host " 3.  INTEL`n"`
* `Read-Host " "`
* Input validation: `^[1-3]$`

Intended mutation or launch type:

* Console branch selection only.

Required foundation:

* Product-scope gating and Action Plan framework.

Required future production allowlist:

* NVIDIA branch only.

Required artifact provenance before download/launch:

* Not applicable to branch selection.

Required driver inventory/capture before mutation:

* Not applicable to selection, but required before any driver work.

Required file/registry/AppX/service capture before mutation:

* Not applicable to selection.

Required confirmation level:

* NVIDIA branch selection must lead to high-risk confirmation before any
  download, driver extraction, installer launch, profile import, cleanup, or
  reboot.

Required verification:

* Confirm selected branch is NVIDIA before any future executable behavior.

Rollback/restore feasibility:

* Not applicable.

Risk level:

* High once a branch proceeds to mutation.

Later implementation decision:

* NVIDIA-only selection can be designed later. AMD/Intel selection must remain
  unsupported.

### 2. NVIDIA-Supported Branch Behavior

Exact source targets:

* `Start-Process "https://www.nvidia.com/en-us/drivers"`
* `OpenFileDialog` selection of `$InstallFile`
* `& "$env:SystemDrive\Program Files\7-Zip\7z.exe" x "$InstallFile" -o"$env:SystemRoot\Temp\nvidiadriver" -y`
* `Start-Process "$env:SystemRoot\Temp\nvidiadriver\setup.exe" -ArgumentList "-s -noreboot -noeula -clean" -Wait -NoNewWindow`
* `Start-Process "winget" -ArgumentList "install `"9NF8H0H7WMLT`" --silent --accept-package-agreements --accept-source-agreements --disable-interactivity --no-upgrade" -Wait -WindowStyle Hidden`
* `Get-AppxPackage -allusers *Microsoft.Winget.Source* | Remove-AppxPackage -ErrorAction SilentlyContinue`
* `Start-Process -wait "$env:SystemRoot\Temp\inspector.exe" -ArgumentList "-silentImport -silent $env:SystemRoot\Temp\inspector.nip"`

Intended mutation or launch type:

* User-assisted NVIDIA driver download, driver extraction, component deletion,
  silent driver install, NVIDIA Control Panel AppX install through winget,
  AppX removal, registry tuning, NVIDIA Inspector profile import, cleanup, and
  restart.

Required foundation:

* Phase 35 download/installer policy.
* Phase 41 driver state capture and rollback policy.
* Phase 39 AppX package inventory and restore policy.
* Phase 36 file/registry state capture.
* Phase 38 cleanup policy.
* Phase 40 reboot/recovery workflow.

Required future production allowlist:

* Exact NVIDIA driver package provenance/selection rule.
* Exact extracted-driver directory scope.
* Exact debloat component allowlist.
* Exact NVIDIA setup execution descriptor.
* Exact winget/AppX package scope for `9NF8H0H7WMLT`.
* Exact NVIDIA Inspector artifact and profile scope.
* Exact registry and cleanup scopes.
* Exact reboot workflow.

Required artifact provenance before download/launch:

* 7-Zip artifact provenance.
* NVIDIA driver package provenance or approved user-selected-driver validation.
* NVIDIA Inspector artifact provenance.
* NVIDIA Control Panel package identity and source approval.

Required driver inventory/capture before mutation:

* Current display device identity, vendor, hardware ids, driver version/date,
  INF/package identity, associated services/files, and rollback eligibility.

Required file/registry/AppX/service capture before mutation:

* Extracted driver directory ownership.
* Existing NVIDIA registry values.
* DRS/profile state before import.
* AppX state before winget install/remove.
* Cleanup targets before deletion where rollback is claimed.

Required confirmation level:

* High-risk explicit confirmation warning about display loss, black screen,
  driver rollback limits, Safe Mode recovery possibility, network dependency,
  installer failure, NVIDIA Control Panel/AppX side effects, and reboot
  requirements.

Required verification:

* Driver package verified before extraction.
* Extraction output exists.
* Debloat touched only approved components.
* Setup launch and exit code captured.
* Driver version/device state verified after install.
* AppX/package state verified.
* Registry values verified.
* Profile import request and result verified.
* Reboot requirement recorded.

Rollback/restore feasibility:

* Unavailable until exact driver rollback, file restore, registry restore,
  AppX restore, profile backup, cleanup, and reboot workflow selection are
  approved.

Risk level:

* High.

Later implementation decision:

* Can be considered later only after NVIDIA-specific approvals exist.

### 3. Unsupported AMD Branch Behavior If Present

Exact source targets:

* `Start-Process "https://www.amd.com/en/support/download/drivers.html"`
* `& "$env:SystemDrive\Program Files\7-Zip\7z.exe" x "$InstallFile" -o"$env:SystemRoot\Temp\amddriver" -y`
* `Start-Process -Wait "$env:SystemRoot\Temp\amddriver\Bin64\ATISetup.exe" -ArgumentList "-INSTALL -VIEW:2" -WindowStyle Hidden`
* AMD XML edits under `$env:SystemRoot\Temp\amddriver\Config`
* AMD JSON edits under `$env:SystemRoot\Temp\amddriver\Config` and `Bin64`
* AMD registry writes under `HKCU\Software\AMD\CN`
* AMD service/driver deletion for `AMD Crash Defender Service`, `amdfendr`,
  `amdfendrmgr`, `amdacpbus`, `AMDSAFD`, and `AtiHDAudioService`

Intended mutation or launch type:

* AMD driver extraction, debloat, install, service/driver deletion, registry
  settings, process handling, and cleanup.

Required foundation:

* Not applicable under current product scope.

Required future production allowlist:

* None. AMD GPU-specific behavior is unsupported.

Required artifact provenance before download/launch:

* Not applicable because the branch is refused.

Required driver inventory/capture before mutation:

* Not applicable because no AMD driver mutation is approved.

Required file/registry/AppX/service capture before mutation:

* Not applicable because no AMD branch mutation is approved.

Required confirmation level:

* Branch must remain disabled, visual-only, or NotApplicable.

Required verification:

* Verify no AMD branch command can execute.

Rollback/restore feasibility:

* Not applicable.

Risk level:

* High.

Later implementation decision:

* Must remain refused unless Yazan expands GPU product scope.

### 4. Unsupported Intel Branch Behavior If Present

Exact source targets:

* `Start-Process "https://www.intel.com/content/www/us/en/search.html#sortCriteria=%40lastmodifieddt%20descending&f-operatingsystem_en=Windows%2011%20Family*&f-downloadtype=Drivers&cf-tabfilter=Downloads&cf-downloadsppth=Graphics"`
* `& "$env:SystemDrive\Program Files\7-Zip\7z.exe" x "$InstallFile" -o"$env:SystemDrive\inteldriver" -y`
* `Start-Process "cmd.exe" -ArgumentList "/c `"$env:SystemDrive\inteldriver\Installer.exe`" -f --noExtras --terminateProcesses -s" -WindowStyle Hidden -Wait`
* `Start-Process "$env:SystemDrive\inteldriver\Resources\Extras\$IntelGraphicsSoftware" -ArgumentList "/s" -Wait -NoNewWindow`
* Intel service/driver deletion for `IntelGFXFWupdateTool`, `cplspcon`,
  `CtaChildDriver`, `GSCAuxDriver`, and `GSCx64`
* Intel process stop for `IntelGraphicsSoftware` and `PresentMonService`

Intended mutation or launch type:

* Intel driver extraction, install, extra software install, service/driver
  deletion, process stop, file deletion, registry settings, cleanup, and
  restart.

Required foundation:

* Not applicable under current product scope.

Required future production allowlist:

* None. Intel GPU-specific behavior is unsupported.

Required artifact provenance before download/launch:

* Not applicable because the branch is refused.

Required driver inventory/capture before mutation:

* Not applicable because no Intel driver mutation is approved.

Required file/registry/AppX/service capture before mutation:

* Not applicable because no Intel branch mutation is approved.

Required confirmation level:

* Branch must remain disabled, visual-only, or NotApplicable.

Required verification:

* Verify no Intel branch command can execute.

Rollback/restore feasibility:

* Not applicable.

Risk level:

* High.

Later implementation decision:

* Must remain refused unless Yazan expands GPU product scope.

### 5. NVIDIA Driver Download Behavior

Exact source targets:

* `Start-Process "https://www.nvidia.com/en-us/drivers"`
* User-selected `$InstallFile` from `OpenFileDialog`

Intended mutation or launch type:

* Browser handoff to NVIDIA driver page, then user-selected local driver
  executable.

Required foundation:

* Phase 35 artifact provenance.
* Phase 41 driver state policy.

Required future production allowlist:

* Approved NVIDIA driver artifact policy or a strict user-selected file
  validation contract.

Required artifact provenance before download/launch:

* Expected NVIDIA signer, package metadata, supported device ids, and local
  hash/version validation.

Required driver inventory/capture before mutation:

* Current NVIDIA device and driver inventory before extraction or install.

Required file/registry/AppX/service capture before mutation:

* Local selected file identity and planned extraction target.

Required confirmation level:

* High-risk confirmation before accepting or extracting a selected driver.

Required verification:

* File is local, signed by expected publisher, hash recorded, and compatible
  with detected NVIDIA hardware.

Rollback/restore feasibility:

* Requires driver rollback design and original package/source availability.

Risk level:

* High.

Later implementation decision:

* Possible only with exact user-selected driver validation.

### 6. External Helper/Tool Download Behavior

Exact source targets:

* `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/7zip.exe`
* `$env:SystemRoot\Temp\7zip.exe`
* `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/inspector.exe`
* `$env:SystemRoot\Temp\inspector.exe`

Intended mutation or launch type:

* Downloads helper executables from mutable GitHub raw branch URLs.

Required foundation:

* Phase 35 download provenance and installer execution policy.

Required future production allowlist:

* Exact 7-Zip artifact record.
* Exact NVIDIA Inspector artifact record.

Required artifact provenance before download/launch:

* Stable source URL, expected filename, version, size, SHA-256, signer if
  executable, license/redistributability note, and allowed consumer.

Required driver inventory/capture before mutation:

* Not directly, but helper use is part of driver mutation workflow.

Required file/registry/AppX/service capture before mutation:

* Existing temp file state before overwrite.

Required confirmation level:

* Explicit confirmation before download and execution.

Required verification:

* Hash/signature/provenance verification before install or launch.

Rollback/restore feasibility:

* Generated helper cleanup only if exact cleanup scope exists.

Risk level:

* High.

Later implementation decision:

* Current mutable helper URLs remain refused.

### 7. Driver Extraction Behavior

Exact source targets:

* `& "$env:SystemDrive\Program Files\7-Zip\7z.exe" x "$InstallFile" -o"$env:SystemRoot\Temp\nvidiadriver" -y`
* AMD extraction to `$env:SystemRoot\Temp\amddriver` is unsupported.
* Intel extraction to `$env:SystemDrive\inteldriver` is unsupported.

Intended mutation or launch type:

* Extracts driver packages to writable folders for mutation before install.

Required foundation:

* Phase 35 artifact/executable policy.
* Phase 36 file state capture.
* Phase 38 cleanup policy.

Required future production allowlist:

* Exact NVIDIA extraction root.
* Exact extracted inventory and cleanup rules.

Required artifact provenance before download/launch:

* 7-Zip and selected NVIDIA driver package must be verified.

Required driver inventory/capture before mutation:

* Current NVIDIA driver state before extraction/install.

Required file/registry/AppX/service capture before mutation:

* Extraction root ownership and any prior content must be captured or blocked.

Required confirmation level:

* High-risk confirmation.

Required verification:

* Extraction output exists and matches expected NVIDIA package structure.

Rollback/restore feasibility:

* Cleanup only for BoostLab-owned extraction root with bounded cleanup scope.

Risk level:

* High.

Later implementation decision:

* Possible only with exact NVIDIA extraction and cleanup scope.

### 8. Driver Install Behavior

Exact source targets:

* NVIDIA: `Start-Process "$env:SystemRoot\Temp\nvidiadriver\setup.exe" -ArgumentList "-s -noreboot -noeula -clean" -Wait -NoNewWindow`
* AMD: `Start-Process -Wait "$env:SystemRoot\Temp\amddriver\Bin64\ATISetup.exe" -ArgumentList "-INSTALL -VIEW:2" -WindowStyle Hidden`
* Intel: `Start-Process "cmd.exe" -ArgumentList "/c `"$env:SystemDrive\inteldriver\Installer.exe`" -f --noExtras --terminateProcesses -s" -WindowStyle Hidden -Wait`

Intended mutation or launch type:

* Silent driver installer execution.

Required foundation:

* Phase 35 installer execution policy.
* Phase 41 driver state capture and rollback policy.
* Phase 40 reboot/recovery workflow.

Required future production allowlist:

* NVIDIA setup execution descriptor only. AMD/Intel descriptors remain refused.

Required artifact provenance before download/launch:

* Verified NVIDIA package and extracted `setup.exe` identity.

Required driver inventory/capture before mutation:

* Exact NVIDIA device, package, driver version, INF, files, services, and
  rollback eligibility before execution.

Required file/registry/AppX/service capture before mutation:

* Setup side-effect scopes and state references where known.

Required confirmation level:

* High-risk confirmation before install.

Required verification:

* Installer exit code, device state, driver version, package identity, and
  restart requirement.

Rollback/restore feasibility:

* Unavailable until driver rollback and reboot/recovery design are approved.

Risk level:

* High.

Later implementation decision:

* NVIDIA only, and only after exact approvals.

### 9. Driver Debloat/Removal Behavior

Exact source targets:

NVIDIA debloat removes extracted components including:

* `$env:SystemRoot\Temp\nvidiadriver\Display.Nview`
* `$env:SystemRoot\Temp\nvidiadriver\FrameViewSDK`
* `$env:SystemRoot\Temp\nvidiadriver\HDAudio`
* `$env:SystemRoot\Temp\nvidiadriver\MSVCRT`
* `$env:SystemRoot\Temp\nvidiadriver\NvApp.MessageBus`
* `$env:SystemRoot\Temp\nvidiadriver\NvBackend`
* `$env:SystemRoot\Temp\nvidiadriver\NvContainer`
* `$env:SystemRoot\Temp\nvidiadriver\NvCpl`
* `$env:SystemRoot\Temp\nvidiadriver\NvDLISR`
* `$env:SystemRoot\Temp\nvidiadriver\NVPCF`
* `$env:SystemRoot\Temp\nvidiadriver\NvTelemetry`
* `$env:SystemRoot\Temp\nvidiadriver\NvVAD`
* `$env:SystemRoot\Temp\nvidiadriver\PhysX`
* `$env:SystemRoot\Temp\nvidiadriver\PPC`
* `$env:SystemRoot\Temp\nvidiadriver\ShadowPlay`
* `$env:SystemRoot\Temp\nvidiadriver\NvApp\CEF`
* `$env:SystemRoot\Temp\nvidiadriver\NvApp\osc`
* `$env:SystemRoot\Temp\nvidiadriver\NvApp\Plugins`
* `$env:SystemRoot\Temp\nvidiadriver\NvApp\UpgradeConsent`
* `$env:SystemRoot\Temp\nvidiadriver\NvApp\www`
* `$env:SystemRoot\Temp\nvidiadriver\NvApp\7z.dll`
* `$env:SystemRoot\Temp\nvidiadriver\NvApp\7z.exe`
* `$env:SystemRoot\Temp\nvidiadriver\NvApp\DarkModeCheck.exe`
* `$env:SystemRoot\Temp\nvidiadriver\NvApp\InstallerExtension.dll`
* `$env:SystemRoot\Temp\nvidiadriver\NvApp\NvApp.nvi`
* `$env:SystemRoot\Temp\nvidiadriver\NvApp\NvAppApi.dll`
* `$env:SystemRoot\Temp\nvidiadriver\NvApp\NvAppExt.dll`
* `$env:SystemRoot\Temp\nvidiadriver\NvApp\NvConfigGenerator.dll`

Intended mutation or launch type:

* Deletes selected extracted NVIDIA driver components before running setup.

Required foundation:

* Phase 38 destructive cleanup policy.
* Phase 36 file state capture if restore is claimed.

Required future production allowlist:

* Exact component deletion allowlist under the NVIDIA extraction root.

Required artifact provenance before download/launch:

* Verified NVIDIA package before modifying extracted contents.

Required driver inventory/capture before mutation:

* Current driver inventory before install.

Required file/registry/AppX/service capture before mutation:

* Extracted component identity and ownership.

Required confirmation level:

* High-risk confirmation describing driver component removal and support risk.

Required verification:

* Only approved extracted components were deleted.
* Required setup files still exist.

Rollback/restore feasibility:

* Re-extraction may be possible only if original package remains verified and
  available. Restore is not approved.

Risk level:

* High.

Later implementation decision:

* Possible only after exact extracted component allowlists exist.

### 10. NVIDIA App / FrameView / GeForce Experience Behavior If Present

Exact source targets:

* The NVIDIA driver debloat list removes `FrameViewSDK`.
* The NVIDIA driver debloat list removes many `NvApp` components.
* `Start-Process "winget" -ArgumentList "install `"9NF8H0H7WMLT`" --silent --accept-package-agreements --accept-source-agreements --disable-interactivity --no-upgrade" -Wait -WindowStyle Hidden`
* The source comments include NVIDIA Control Panel app shell references.

Intended mutation or launch type:

* Removes selected bundled NVIDIA components from the extracted package and
  installs NVIDIA Control Panel through winget/AppX source.

Required foundation:

* Phase 35 installer/download policy.
* Phase 39 AppX package policy.
* Phase 38 cleanup policy.

Required future production allowlist:

* Exact NVIDIA App/FrameView component decisions.
* Exact package id `9NF8H0H7WMLT` and source approval.

Required artifact provenance before download/launch:

* Winget source/package provenance and allowed consumer.

Required driver inventory/capture before mutation:

* NVIDIA package and device state.

Required file/registry/AppX/service capture before mutation:

* AppX state and extracted component state.

Required confirmation level:

* High-risk confirmation.

Required verification:

* Package installed or refused with clear status.
* Removed components are exact approved targets.

Rollback/restore feasibility:

* Not available without AppX restore and component restore design.

Risk level:

* High.

Later implementation decision:

* Must remain refused until exact AppX/package and component scopes exist.

### 11. NVIDIA Control Panel / AppX Behavior If Present

Exact source targets:

* `winget install "9NF8H0H7WMLT"`
* `Get-AppxPackage -allusers *Microsoft.Winget.Source* | Remove-AppxPackage -ErrorAction SilentlyContinue`
* `Start-Process shell:appsFolder\NVIDIACorp.NVIDIAControlPanel_56jybvy8sckqj!NVIDIACorp.NVIDIAControlPanel`

Intended mutation or launch type:

* Installs NVIDIA Control Panel package and removes Winget source package.

Required foundation:

* Phase 39 AppX inventory and restore.
* Phase 35 installer/execution policy for winget command.

Required future production allowlist:

* Exact package family, source, command descriptor, and mutation scope.

Required artifact provenance before download/launch:

* Winget package/source provenance must be defined.

Required driver inventory/capture before mutation:

* Driver state reference if package install is tied to NVIDIA branch.

Required file/registry/AppX/service capture before mutation:

* Package inventory before install/remove.

Required confirmation level:

* High-risk confirmation.

Required verification:

* NVIDIA Control Panel package is installed.
* Winget source removal target is exact and approved.

Rollback/restore feasibility:

* Not available until AppX restore rules and package source rules are approved.

Risk level:

* High.

Later implementation decision:

* Must remain refused until exact AppX and winget policy exists.

### 12. NVIDIA Profile Import or Driver-Profile Settings Behavior If Present

Exact source targets:

* `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/inspector.exe`
* `$env:SystemRoot\Temp\inspector.exe`
* `$env:SystemRoot\Temp\inspector.nip`
* `Start-Process -wait "$env:SystemRoot\Temp\inspector.exe" -ArgumentList "-silentImport -silent $env:SystemRoot\Temp\inspector.nip"`
* Profile setting count: `31`
* Example settings: `Frame Rate Limiter V3`, `GSYNC - Application Mode`,
  `Maximum Pre-Rendered Frames`, `Ultra Low Latency - Enabled`,
  `Vertical Sync`, `CUDA - Force P2 State`, `Power Management - Mode`,
  `Shader Cache - Cache Size`, `Threaded Optimization`, `Preferred OpenGL GPU`

Intended mutation or launch type:

* Writes a generated `.nip` profile and silently imports NVIDIA driver profile
  settings.

Required foundation:

* Phase 35 artifact provenance.
* Phase 36 file state capture.
* Phase 41 driver profile/driver state capture.

Required future production allowlist:

* Exact NVIDIA Inspector artifact.
* Exact generated `.nip` content hash.
* Exact approved profile setting ids and values.

Required artifact provenance before download/launch:

* Inspector executable hash, size, signer/publisher if applicable, and license.

Required driver inventory/capture before mutation:

* Current DRS/profile state and driver version before import.

Required file/registry/AppX/service capture before mutation:

* Generated `.nip` file path and DRS file state.

Required confirmation level:

* High-risk confirmation.

Required verification:

* `.nip` file content matches approved hash.
* Inspector command descriptor is exact.
* Profile import result is captured.
* Relevant profile settings are verified where possible.

Rollback/restore feasibility:

* Not available until profile backup and restore design exist.

Risk level:

* High.

Later implementation decision:

* Must remain refused until exact artifact and profile scopes exist.

### 13. Registry Settings Behavior

Exact source targets:

* `HKEY_CURRENT_USER\Software\7-Zip\Options`
* `HKLM\System\ControlSet001\Services\nvlddmkm\Parameters\Global\NVTweak`
* `HKCU\Software\NVIDIA Corporation\NvTray`
* `HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\FTS`
* `HKLM\SYSTEM\ControlSet001\Services\nvlddmkm\Parameters\FTS`
* `HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Parameters\FTS`
* Dynamic display adapter class keys under `HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}`
* Shared display/MSI settings under `HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\MonitorDataStore` and `HKLM\SYSTEM\ControlSet001\Enum\$instanceID\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties`

Intended mutation or launch type:

* Writes NVIDIA registry settings and shared graphics/display settings.

Required foundation:

* Phase 36 registry state capture.
* Phase 41 driver state policy for driver-owned keys.

Required future production allowlist:

* Exact NVIDIA registry values and exact dynamic discovery rules.

Required artifact provenance before download/launch:

* Not directly, but tied to verified driver workflow.

Required driver inventory/capture before mutation:

* NVIDIA adapter identity before dynamic class-key mutation.

Required file/registry/AppX/service capture before mutation:

* Prior value existence, type, and data for every value.

Required confirmation level:

* High-risk confirmation.

Required verification:

* Each approved value is present with expected type/data.
* Dynamic keys match NVIDIA adapter identity.

Rollback/restore feasibility:

* Possible only with exact captured registry state and a future Restore UI.

Risk level:

* High.

Later implementation decision:

* NVIDIA registry subset can be considered later. Shared post-branch writes
  still need separate approval.

### 14. File/Directory Cleanup or Deletion Behavior

Exact source targets:

* NVIDIA: extracted component deletions under `$env:SystemRoot\Temp\nvidiadriver`
* NVIDIA: `Remove-Item "$InstallFile"`
* NVIDIA: `Remove-Item "$env:SystemDrive\NVIDIA" -Recurse -Force`
* 7-Zip Start Menu folder cleanup.
* Unsupported AMD cleanup under `$env:SystemDrive\AMD` and AMD Start Menu paths.
* Unsupported Intel cleanup under `$env:SystemDrive\Intel`, `$env:SystemDrive\inteldriver`, Intel Start Menu paths, and `PresentMonService.exe`.

Intended mutation or launch type:

* Deletes selected extracted components, selected downloaded driver package,
  old driver folders, and vendor shortcut folders.

Required foundation:

* Phase 38 destructive cleanup policy.
* Phase 36 file state capture where restore is claimed.

Required future production allowlist:

* Exact NVIDIA cleanup scopes only.

Required artifact provenance before download/launch:

* Verified selected driver package before deleting `$InstallFile`.

Required driver inventory/capture before mutation:

* Driver state before deleting old driver folders.

Required file/registry/AppX/service capture before mutation:

* Exact file/folder state and ownership before deletion.

Required confirmation level:

* High-risk confirmation.

Required verification:

* Deleted paths are exact approved targets and stay within bounded roots.

Rollback/restore feasibility:

* Not available unless quarantine/state capture is approved.

Risk level:

* High.

Later implementation decision:

* Must remain refused until bounded cleanup scopes exist.

### 15. Service or Scheduled Task Behavior If Present

Exact source targets:

Unsupported AMD/Intel service targets:

* `AMD Crash Defender Service`
* `amdfendr`
* `amdfendrmgr`
* `amdacpbus`
* `AMDSAFD`
* `AtiHDAudioService`
* `IntelGFXFWupdateTool`
* `cplspcon`
* `CtaChildDriver`
* `GSCAuxDriver`
* `GSCx64`

Unsupported task target:

* `Unregister-ScheduledTask -TaskName "StartCN" -Confirm:$false`

Intended mutation or launch type:

* Stops/deletes AMD and Intel services/drivers and unregisters AMD task.

Required foundation:

* Phase 37 service state capture and rollback.
* Future scheduled task governance.

Required future production allowlist:

* None under current product scope because these are AMD/Intel branch targets.

Required artifact provenance before download/launch:

* Not applicable.

Required driver inventory/capture before mutation:

* Not applicable because AMD/Intel branches are unsupported.

Required file/registry/AppX/service capture before mutation:

* Not applicable unless product scope expands.

Required confirmation level:

* Unsupported and non-executing.

Required verification:

* Verify no AMD/Intel service/task mutation can execute.

Rollback/restore feasibility:

* Not applicable.

Risk level:

* High.

Later implementation decision:

* Must remain refused under current NVIDIA-only scope.

### 16. Process Stop Behavior If Present

Exact source targets:

* AMD: `Stop-Process -Name "RadeonSoftware" -Force -ErrorAction SilentlyContinue`
* Intel: `$stop = "IntelGraphicsSoftware", "PresentMonService"`
* Intel: `$stop | ForEach-Object { Stop-Process -Name $_ -Force -ErrorAction SilentlyContinue }`

Intended mutation or launch type:

* Force-stops vendor processes.

Required foundation:

* Future process-handling governance.

Required future production allowlist:

* None under current scope because these are AMD/Intel branch targets.

Required artifact provenance before download/launch:

* Not applicable.

Required driver inventory/capture before mutation:

* Not applicable.

Required file/registry/AppX/service capture before mutation:

* Not applicable.

Required confirmation level:

* Unsupported and non-executing.

Required verification:

* Verify no AMD/Intel process stop can execute.

Rollback/restore feasibility:

* Not applicable.

Risk level:

* High.

Later implementation decision:

* Must remain refused unless product scope expands and process governance
  exists.

### 17. Reboot/Restart Behavior

Exact source targets:

* `shutdown -r -t 00`

Intended mutation or launch type:

* Immediate restart after the driver branch and shared settings complete.

Required foundation:

* Phase 40 reboot/recovery workflow.

Required future production allowlist:

* Exact driver-install reboot workflow scope.

Required artifact provenance before download/launch:

* All preceding artifacts and driver package must be verified.

Required driver inventory/capture before mutation:

* Driver state and expected post-reboot verification plan.

Required file/registry/AppX/service capture before mutation:

* All mutable targets must have relevant state records before restart.

Required confirmation level:

* High-risk explicit reboot confirmation. No silent immediate restart.

Required verification:

* Pre-reboot checkpoints, pending workflow record, post-reboot device and
  driver verification.

Rollback/restore feasibility:

* Requires reboot/recovery workflow and driver rollback design.

Risk level:

* High.

Later implementation decision:

* No reboot is approved in this phase.

### 18. Default/Restore Behavior

Exact source targets:

* The source has no Default option.
* The source has no Restore option.
* The source does not capture driver, AppX, registry, file, service, profile,
  cleanup, or reboot state before mutation.

Intended mutation or launch type:

* None.

Required foundation:

* Exact artifact provenance, driver inventory, driver rollback, file/registry
  capture, AppX capture, service capture, NVIDIA profile backup, reboot
  workflow, and restore selection.

Required future production allowlist:

* None approved.

Required artifact provenance before download/launch:

* Not applicable.

Required driver inventory/capture before mutation:

* Required before any future Restore can be claimed.

Required file/registry/AppX/service capture before mutation:

* Required before any future Restore can be claimed.

Required confirmation level:

* Not applicable.

Required verification:

* Confirm current module does not expose working Restore.

Rollback/restore feasibility:

* Current Default/Restore must remain unavailable.

Risk level:

* High if incorrectly exposed.

Later implementation decision:

* Do not expose Default or Restore until full captured-state restore exists.

### 19. Unsupported Broad Driver/File/Registry/Package Targets

Exact source targets:

* AMD and Intel branches.
* Mutable GitHub raw helper URLs.
* User-selected driver package without provenance validation.
* Dynamic display class registry traversal.
* `Get-PnpDevice -Class Display` applied to all display devices.
* Broad deletion of `$env:SystemDrive\NVIDIA`, `$env:SystemDrive\AMD`,
  `$env:SystemDrive\Intel`, and `$env:SystemDrive\inteldriver`.
* AppX wildcard removal: `Get-AppxPackage -allusers *Microsoft.Winget.Source* | Remove-AppxPackage`

Intended mutation or launch type:

* Unsupported or currently over-broad mutation.

Required foundation:

* Phase 35, 36, 38, 39, 40, and 41 as applicable.

Required future production allowlist:

* Exact NVIDIA-only scopes. AMD/Intel scopes remain refused.

Required artifact provenance before download/launch:

* Required for every executable or driver package.

Required driver inventory/capture before mutation:

* Required before any driver mutation.

Required file/registry/AppX/service capture before mutation:

* Required for every mutable target.

Required confirmation level:

* High-risk confirmation, but confirmation alone cannot approve unsupported
  targets.

Required verification:

* Verify unsupported branches and broad targets remain blocked.

Rollback/restore feasibility:

* Not available.

Risk level:

* High.

Later implementation decision:

* Must remain refused until exact scopes exist.

## Exact Source Target Inventory

URLs:

* `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/7zip.exe`
* `https://www.nvidia.com/en-us/drivers`
* `https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/inspector.exe`
* `https://www.amd.com/en/support/download/drivers.html`
* `https://www.intel.com/content/www/us/en/search.html#sortCriteria=%40lastmodifieddt%20descending&f-operatingsystem_en=Windows%2011%20Family*&f-downloadtype=Drivers&cf-tabfilter=Downloads`

Key NVIDIA paths and commands:

* `$env:SystemRoot\Temp\nvidiadriver`
* `$env:SystemRoot\Temp\nvidiadriver\setup.exe`
* `$env:SystemRoot\Temp\inspector.exe`
* `$env:SystemRoot\Temp\inspector.nip`
* `C:\ProgramData\NVIDIA Corporation\Drs`
* `Start-Process "$env:SystemRoot\Temp\nvidiadriver\setup.exe" -ArgumentList "-s -noreboot -noeula -clean" -Wait -NoNewWindow`
* `Start-Process -wait "$env:SystemRoot\Temp\inspector.exe" -ArgumentList "-silentImport -silent $env:SystemRoot\Temp\inspector.nip"`

Unsupported AMD paths and commands:

* `$env:SystemRoot\Temp\amddriver`
* `$env:SystemRoot\Temp\amddriver\Bin64\ATISetup.exe`
* `HKCU\Software\AMD\CN`
* `Unregister-ScheduledTask -TaskName "StartCN" -Confirm:$false`

Unsupported Intel paths and commands:

* `$env:SystemDrive\inteldriver`
* `$env:SystemDrive\inteldriver\Installer.exe`
* `$env:SystemDrive\inteldriver\Resources\Extras\$IntelGraphicsSoftware`
* `$env:SystemDrive\Program Files\Intel\Intel Graphics Software\PresentMonService.exe`

Shared post-branch targets:

* `Start-Process "ms-settings:display"`
* `Start-Process shell:appsFolder\NVIDIACorp.NVIDIAControlPanel_56jybvy8sckqj!NVIDIACorp.NVIDIAControlPanel`
* `Start-Process mmsys.cpl`
* `HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\MonitorDataStore`
* `HKLM\SYSTEM\ControlSet001\Enum\$instanceID\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties`
* `registry::HKEY_CURRENT_USER\Control Panel\NotifyIconSettings`
* `shutdown -r -t 00`

## Future Safe Apply/Open/Install Requirements

A future implementation can be considered only for the NVIDIA branch and only
after:

1. 7-Zip and NVIDIA Inspector artifacts have exact provenance approvals.
2. NVIDIA driver package selection has an approved local-file validation model.
3. Exact NVIDIA device and driver inventory is captured before mutation.
4. Exact extraction, debloat, setup, registry, AppX, profile, cleanup, and
   reboot scopes are approved.
5. Generated `inspector.nip` content is approved by hash and setting inventory.
6. NVIDIA setup and Inspector execution descriptors are approved.
7. AppX/winget package behavior is scoped or removed only with explicit Yazan
   approval.
8. A reboot/recovery workflow is approved before any restart.
9. The UI shows high-risk warnings about display loss, black screen, driver
   rollback, Safe Mode recovery, network dependency, installer failure, NVIDIA
   Control Panel/AppX side effects, and reboot requirements.

Potential future actions:

* `Analyze`: detect GPU vendor, show NVIDIA eligibility, list missing
  approvals, and report AMD/Intel as unsupported.
* `Open`: may open the NVIDIA driver page only if scoped as guidance and does
  not imply download/install approval.
* `Apply` or `Install`: NVIDIA only, and only after all production scopes and
  provenance approvals exist.

## Default and Restore Boundary

Current Default/Restore must remain unavailable.

The source provides no Default and no Restore behavior. BoostLab must not claim
restore capability for driver installation, profile import, AppX mutation,
registry writes, file cleanup, service changes, or reboot workflow unless a
future phase approves exact artifact provenance, driver inventory, driver
rollback, file/registry/AppX/service capture, NVIDIA profile backup, reboot
workflow, and restore selection.

## Production Approval State

Current approved production scopes for Driver Install Debloat & Settings:

* Artifact approvals: none.
* Installer/tool execution entries: none.
* Driver scopes: none.
* Driver-profile scopes: none.
* AppX package scopes: none.
* Registry scopes: none.
* File scopes: none.
* Service scopes: none.
* Scheduled task scopes: none.
* Cleanup scopes: none.
* Reboot/recovery scopes: none.
* Default/Restore scopes: none.

Driver Install Debloat & Settings Auto must remain refused until these
approvals are supplied in future explicit implementation phases.
