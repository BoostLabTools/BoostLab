# Installers Scope and Provenance Design

## Purpose

This document records the Installers source scope and the Phase 119 selected-app
implementation boundary.

Phase 172C supersedes the Phase 119 multi-select boundary for retained apps.
BoostLab now implements a Yazan-scoped single-app Apply flow for retained
source app choices only. It does not approve any global artifact
provenance entry, production allowlist entry, removed app, Default, Restore, or
parallel installer workflow.

## Source Reference

* Tool id: `installers`
* Tool title: `Installers`
* Stage: `Installers`
* Current module: `modules/Installers/installers.psm1`
* Source path: `source-ultimate/4 Installers/1 Installers.ps1`
* Source SHA-256: `1065D64183457D4E7B28EA78DDE41525EC8F7C4A4BCA12D29B70D991141C0C67`

## Product Scope Decision

The source is mostly GPU-neutral application installation behavior. GPU-neutral
installer behavior may be designed later only if provenance and execution
policy can support each artifact and side effect.

NVIDIA-specific installer/profile/vendor behavior may be documented only where
otherwise approved. In this source that includes `Frame View` and `Nvidia App`.
Explicit AMD/Intel GPU-specific behavior is not present in the inspected
source and must remain unsupported if added later.

## Source Behavior Summary

The Ultimate source is an administrator-only interactive installer menu. It
checks internet with `Test-Connection -ComputerName "8.8.8.8"` and then offers
these menu options:

1. Exit
2. Discord
3. Roblox
4. 7-Zip
5. Battle.net
6. Brave
7. Electronic Arts
8. Epic Games
9. Escape From Tarkov
10. Firefox
11. Frame View
12. GOG launcher
13. Google Chrome
14. League Of Legends
15. Notepad ++
16. Nvidia App
17. OBS Studio
18. Onboard Memory Manager
19. Pot Player
20. Rockstar Games
21. Spotify
22. Steam
23. Ubisoft Connect
24. Valorant

The source downloads 24 unique external artifacts, launches installer or helper
executables, writes app configs, writes browser policies, deletes service
entries and scheduled tasks, reshapes Start Menu shortcuts, creates desktop
shortcuts, uninstalls selected components, and performs one portable tool
download.

## Current Decision

Installers is implemented as a Yazan-scoped single-app Apply flow as of
Phase 172C, with Escape From Tarkov removed from active product scope in
Phase 173B.

No production download/installer/executable/registry/file/service/task/shortcut/config/uninstall/reboot scopes
are approved as reusable/global allowlists in this phase. The implemented
Installers module contains source-derived retained-app descriptors and executes
only selected retained app operations after explicit confirmation.

Yazan excluded exactly these source menu entries from the visible/selectable
catalog: 9 Escape From Tarkov, 11 Frame View, 12 GOG launcher, 15 Notepad ++,
16 Nvidia App, 18 Onboard Memory Manager, and 19 Pot Player. Google Chrome,
OBS Studio, and Rockstar Games remain retained. Because these omissions are
intentional, the parity record uses `YazanFinalException` rather than
`ParityImplemented`.

Retained selected apps preserve source-defined URLs, destinations,
installer/helper commands, arguments, and post-install operation families in
source order. Apply runs exactly one selected app per invocation; to install
another retained app, the user runs Installers again and selects that app.

Migration record: `docs/migrations/installers.md`.

## Behavior Groups

### 1. Downloaded Installer Artifacts

Exact source targets:

* `https://discord.com/api/downloads/distributions/app/installers/latest?channel=stable&platform=win&arch=x64` -> `$tempDir\Discord.exe`
* `https://www.roblox.com/download/client?os=win` -> `$env:SystemRoot\Temp\Roblox.exe`
* `https://www.7-zip.org/a/7z2301-x64.exe` -> `$env:SystemRoot\Temp\7 Zip.exe`
* `https://downloader.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe` -> `$env:SystemRoot\Temp\Battle.net.exe`
* `https://brave-browser-downloads.s3.brave.com/latest/brave_installer-x64.exe` -> `$env:SystemRoot\Temp\BraveInstaller.exe`
* `https://origin-a.akamaihd.net/EA-Desktop-Client-Download/installer-releases/EAappInstaller.exe` -> `$env:SystemRoot\Temp\Electronic Arts.exe`
* `https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.msi` -> `$env:SystemRoot\Temp\Epic Games.msi`
* `https://prod.escapefromtarkov.com/launcher/download` -> `$env:SystemRoot\Temp\Escape From Tarkov.exe`
* `https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US` -> `$env:SystemRoot\Temp\Firefox.exe`
* `https://images.nvidia.com/content/geforce/technologies/frameview/FrameView_1.8.1/FrameViewSetup.exe` -> `$env:SystemRoot\Temp\FrameView.exe`
* `https://webinstallers.gog-statics.com/download/GOG_Galaxy_2.0.exe` -> `$env:SystemRoot\Temp\GOG launcher.exe`
* `https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi` -> `$env:SystemRoot\Temp\Chrome.msi`
* `https://lol.secure.dyn.riotcdn.net/channels/public/x/installer/current/live.na.exe` -> `$env:SystemRoot\Temp\League Of Legends.exe`
* `https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.9.3/npp.8.9.3.Installer.x64.exe` -> `$env:SystemRoot\Temp\Notepad ++.exe`
* `https://us.download.nvidia.com/nvapp/client/11.0.6.383/NVIDIA_app_v11.0.6.383.exe` -> `$env:SystemRoot\Temp\NvidiaApp.exe`
* `https://cdn-fastly.obsproject.com/downloads/OBS-Studio-32.1.0-Windows-x64-Installer.exe` -> `$env:SystemRoot\Temp\OBS Studio.exe`
* `https://t1.daumcdn.net/potplayer/PotPlayer/Version/Latest/PotPlayerSetup64.exe` -> `$env:SystemRoot\Temp\Pot Player.exe`
* `https://gamedownloads.rockstargames.com/public/installer/Rockstar-Games-Launcher.exe` -> `$env:SystemRoot\Temp\Rockstar Games.exe`
* `https://download.scdn.co/SpotifySetup.exe` -> `$tempDir\Spotify.exe`
* `https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe` -> `$env:SystemRoot\Temp\Steam.exe`
* `https://static3.cdn.ubi.com/orbit/launcher_installer/UbisoftConnectInstaller.exe` -> `$env:SystemRoot\Temp\Ubisoft Connect.exe`
* `https://valorant.secure.dyn.riotcdn.net/channels/public/x/installer/current/live.live.ap.exe` -> `$env:SystemRoot\Temp\Valorant.exe`

Intended mutation or launch type:

* Network download of executable or MSI installer artifacts.

Required foundation:

* Phase 35 download provenance and installer execution policy.
* Phase 36 file state capture for generated installer paths if overwrite is
  possible.

Required future production allowlist:

* One artifact record per installer with exact source URL, expected file name,
  version if available, size or size bounds, SHA-256, signer/publisher,
  consumer tool id, execution permission, admin requirement, reboot possibility,
  and approval status.

Required provenance before download/launch:

* Exact filename, stable source URL, expected SHA-256, signer/publisher for
  executables/MSIs, and license or redistributability note.

Required inventory/capture before mutation:

* Existing generated file state for the target download path.

Required confirmation level:

* Explicit high-risk Action Plan confirmation before each selected download and
  before each launch.

Required verification:

* Artifact exists in provenance manifest.
* Downloaded file name, hash, size, and signer match the approved artifact.
* The installer launch request is approved before execution.

Rollback/restore feasibility:

* Downloaded installer cleanup can be considered only for BoostLab-owned
  generated files with exact cleanup scope. Installed applications are not
  reversible without app-specific uninstall and state capture design.

Risk level:

* High.

Later implementation decision:

* Can be implemented later only one approved artifact group at a time.

### 2. Portable Tool Downloads If Present

Exact source targets:

* `https://download01.logi.com/web/ftp/pub/techsupport/gaming/OnboardMemoryManager_2.6.1749.exe`
* `$env:SystemDrive\Program Files (x86)\Onboard Memory Manager\Onboard Memory Manager.exe`
* `$env:SystemDrive\Program Files (x86)\Onboard Memory Manager`

Intended mutation or launch type:

* Creates a program directory and downloads a portable executable directly into
  that directory.

Required foundation:

* Phase 35 artifact provenance.
* Phase 36 file state capture.
* Phase 38 cleanup policy if future removal is claimed.

Required future production allowlist:

* Exact executable artifact.
* Exact program directory scope.
* Exact shortcut scopes.

Required provenance before download/launch:

* Expected SHA-256, signer/publisher, file size, and URL stability.

Required inventory/capture before mutation:

* Prior existence and identity of target directory and executable path.

Required confirmation level:

* Explicit confirmation before creating a Program Files directory and writing an
  executable.

Required verification:

* Directory is exact and local.
* Existing file state is captured before overwrite.
* Downloaded executable passes provenance checks.
* Shortcuts point only to the approved executable.

Rollback/restore feasibility:

* Possible only with exact captured state and a cleanup/restore design.

Risk level:

* High.

Later implementation decision:

* Must remain refused until exact file scopes are approved.

### 3. Installer Executable Launches

Exact source targets:

* `Start-Process "$tempDir\Discord.exe"`
* `Start-Process "$env:SystemRoot\Temp\Roblox.exe" -ArgumentList "/S"`
* `Start-Process -Wait "$env:SystemRoot\Temp\7 Zip.exe" -ArgumentList "/S"`
* `Start-Process "$env:SystemRoot\Temp\Battle.net.exe" -ArgumentList '--lang=enUS --installpath="C:\Program Files (x86)\Battle.net"'`
* `Start-Process "$env:SystemRoot\Temp\BraveInstaller.exe" -ArgumentList "--system-level" -Wait`
* `Start-Process "$env:SystemRoot\Temp\Electronic Arts.exe"`
* `Start-Process -Wait "$env:SystemRoot\Temp\Epic Games.msi" -ArgumentList "/quiet"`
* `Start-Process -Wait "$env:SystemDrive\Program Files\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe"`
* `Start-Process "msiexec.exe" -ArgumentList "/x $guid /qn" -Wait -NoNewWindow`
* `Start-Process -Wait "$env:SystemRoot\Temp\Escape From Tarkov.exe" -ArgumentList "/VERYSILENT /NORESTART"`
* `Start-Process -Wait "$env:SystemRoot\Temp\Firefox.exe" -ArgumentList "/S"`
* `Start-Process -FilePath "C:\Program Files (x86)\Mozilla Maintenance Service\uninstall.exe" -ArgumentList "/S" -WindowStyle Hidden -Wait`
* `Start-Process -FilePath "$env:SystemDrive\Program Files\Mozilla Firefox\firefox.exe" -ArgumentList "--headless"`
* `Start-Process -Wait "$env:SystemRoot\Temp\FrameView.exe" -ArgumentList "/s"`
* `Start-Process "$env:SystemRoot\Temp\GOG launcher.exe"`
* `Start-Process -Wait "$env:SystemRoot\Temp\Chrome.msi" -ArgumentList "/quiet"`
* `Start-Process "$env:SystemRoot\Temp\League Of Legends.exe" -ArgumentList "--skip-to-install"`
* `Start-Process -Wait "$env:SystemRoot\Temp\Notepad ++.exe" -ArgumentList "/S"`
* `Start-Process -Wait "$env:SystemRoot\Temp\NvidiaApp.exe" -ArgumentList "/s"`
* `Start-Process -Wait "$env:SystemRoot\Temp\OBS Studio.exe" -ArgumentList "/S"`
* `Start-Process -Wait "$env:SystemRoot\Temp\Pot Player.exe" -ArgumentList "/S /allusers"`
* `Start-Process -Wait "$env:SystemRoot\Temp\Rockstar Games.exe" -ArgumentList "/s /f"`
* `Start-Process "explorer.exe" -ArgumentList "$tempDir\Spotify.exe"`
* `Start-Process -Wait "$env:SystemRoot\Temp\Steam.exe" -ArgumentList "/S"`
* `Start-Process -Wait "$env:SystemRoot\Temp\Ubisoft Connect.exe" -ArgumentList "/S"`
* `Start-Process "$env:SystemRoot\Temp\Valorant.exe" -ArgumentList "--skip-to-install"`

Intended mutation or launch type:

* Launches installers, installed application updaters, uninstallers, and helper
  executables.

Required foundation:

* Phase 35 installer execution policy.
* Phase 40 reboot/recovery policy if an installer can hand off to restart.

Required future production allowlist:

* Exact execution descriptor per app, including executable path, argument
  tokens, wait behavior, expected exit codes, timeout, and whether visible
  launch is required.

Required provenance before download/launch:

* Verified artifact provenance before launching downloaded files.
* Verified local installed path identity before launching installed app or
  uninstaller.

Required inventory/capture before mutation:

* Installed app state and target side-effect state where post-install actions
  mutate registry, services, tasks, shortcuts, or config.

Required confirmation level:

* Explicit confirmation before any launch.

Required verification:

* Process start result.
* Exit code when `-Wait` is used.
* Post-install app-specific verification if the source applies additional
  settings.

Rollback/restore feasibility:

* Not available globally. Each app would need its own uninstall, restore, and
  state capture plan.

Risk level:

* High.

Later implementation decision:

* Must remain refused until exact execution descriptors are approved.

### 4. Silent Install Arguments

Exact source targets:

* `/S`
* `/quiet`
* `/VERYSILENT /NORESTART`
* `/s`
* `/S /allusers`
* `/s /f`
* `--system-level`
* `--skip-to-install`
* `--lang=enUS --installpath="C:\Program Files (x86)\Battle.net"`
* `/x $guid /qn`

Intended mutation or launch type:

* Silent or semi-silent installation/uninstallation.

Required foundation:

* Phase 35 installer execution policy.

Required future production allowlist:

* Exact argument-token allowlist per artifact and action.

Required provenance before download/launch:

* The artifact and the switches must both be source-approved and documented.

Required inventory/capture before mutation:

* App-specific install and side-effect targets.

Required confirmation level:

* Explicit confirmation must explain silent arguments, EULAs, bundled
  components, network dependency, and uninstall limitations.

Required verification:

* Exit code capture and app-specific installed-state checks.

Rollback/restore feasibility:

* Not globally feasible. Each app needs separate uninstall semantics.

Risk level:

* High.

Later implementation decision:

* Can be considered per app only.

### 5. Registry Policy/Settings Changes

Exact source targets:

* `HKEY_CURRENT_USER\Software\7-Zip\Options` value `ContextMenu` = `REG_DWORD 259`
* `HKEY_CURRENT_USER\Software\7-Zip\Options` value `CascadedMenu` = `REG_DWORD 0`
* `HKLM\SOFTWARE\Policies\BraveSoftware\Brave\ExtensionInstallForcelist` value `1`
* `HKLM\SOFTWARE\Policies\BraveSoftware\Brave` values `HardwareAccelerationModeEnabled`, `BackgroundModeEnabled`, `HighEfficiencyModeEnabled`
* `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` value `EpicGamesLauncher`
* `HKLM\SOFTWARE\Policies\Mozilla\Firefox` value `AppAutoUpdate`
* `HKLM\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist` value `1`
* `HKLM\SOFTWARE\Policies\Google\Chrome` values `HardwareAccelerationModeEnabled`, `BackgroundModeEnabled`, `HighEfficiencyModeEnabled`
* `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` value `Steam`
* `HKLM:\Software\Microsoft\Active Setup\Installed Components` dynamic removal for entries whose default value matches `*Brave*`
* `HKLM:\Software\Microsoft\Active Setup\Installed Components` dynamic removal for entries whose default value matches `*Chrome*`

Intended mutation or launch type:

* Registry value writes and dynamic registry key deletion.

Required foundation:

* Phase 36 registry state capture and rollback.

Required future production allowlist:

* Exact HKCU/HKLM paths and values for each app.
* Separate decision on whether dynamic Active Setup key deletion is allowed.

Required provenance before download/launch:

* Browser extension force-install URLs and ids must be approved as source
  side-effect data, not invented.

Required inventory/capture before mutation:

* Prior value existence, type, and data.
* For dynamic key deletion, exact discovered key identity before deletion.

Required confirmation level:

* Explicit confirmation for policy and run-key changes.

Required verification:

* Each value equals expected data or each deleted value/key is absent.
* Dynamic deletion must prove it touched only app-matching keys.

Rollback/restore feasibility:

* Possible only if exact pre-mutation registry state is captured.

Risk level:

* High.

Later implementation decision:

* Static value writes can be considered later. Dynamic Active Setup deletion
  should remain refused until exact scope and restore rules exist.

### 6. Service Changes If Present

Exact source targets:

* Brave services discovered with `Get-Service | Where-Object { $_.Name -match 'Brave' }`
* Google services discovered with `Get-Service | Where-Object { $_.Name -match 'Google' }`
* `sc stop "$($service.Name)"`
* `sc delete "$($service.Name)"`
* Mozilla Maintenance Service uninstaller:
  `C:\Program Files (x86)\Mozilla Maintenance Service\uninstall.exe`

Intended mutation or launch type:

* Dynamic service stop/delete and maintenance-service uninstall.

Required foundation:

* Phase 37 service state capture and rollback.
* Phase 35 installer execution for the Mozilla uninstaller.

Required future production allowlist:

* Exact service names. Wildcard or regex service discovery is not acceptable
  for production execution.

Required provenance before download/launch:

* Local uninstaller identity must be verified before launch.

Required inventory/capture before mutation:

* Full service state before stop/delete.

Required confirmation level:

* Explicit confirmation for service deletion.

Required verification:

* Target service identity matches allowlist.
* Service stopped/deleted or uninstaller exit code captured.

Rollback/restore feasibility:

* Service deletion restore is not currently approved. Must remain refused until
  exact recreate/rollback design exists.

Risk level:

* High.

Later implementation decision:

* Dynamic service deletion must remain refused unless decomposed into exact
  approved service targets.

### 7. Scheduled Task Changes If Present

Exact source targets:

* Brave tasks: `Get-ScheduledTask | Where-Object { $_.TaskName -like '*Brave*' } | Unregister-ScheduledTask`
* Firefox tasks: `Get-ScheduledTask | Where-Object {$_.Taskname -match 'Firefox'} | Unregister-ScheduledTask`
* Google tasks: `Get-ScheduledTask | Where-Object { $_.TaskName -like '*Google*' } | Unregister-ScheduledTask`

Intended mutation or launch type:

* Dynamic scheduled task deletion.

Required foundation:

* Future scheduled task inventory/capture policy. Existing foundations do not
  yet approve production task deletion.

Required future production allowlist:

* Exact task path and task name list. Wildcard task removal is refused.

Required provenance before download/launch:

* Not applicable.

Required inventory/capture before mutation:

* Full scheduled task XML and state before unregister.

Required confirmation level:

* Explicit confirmation.

Required verification:

* Exact task identity absent after unregister.

Rollback/restore feasibility:

* Not available until task capture and restore exist.

Risk level:

* High.

Later implementation decision:

* Must remain refused until exact task governance exists.

### 8. Shortcut Creation/Deletion Behavior

Exact source targets:

* Desktop shortcuts: `7-Zip File Manager.lnk`, `Battle.net.lnk`, `Battlestate Games Launcher.lnk`, `Notepad++.lnk`, `Onboard Memory Manager.lnk`
* Start Menu shortcuts: `Battle.net.lnk`, `Onboard Memory Manager.lnk`
* Start Menu move/delete folders for `7-Zip`, `Battlestate Games`, `NVIDIA FrameView`, `NVIDIA Corporation`, `PotPlayer`, `Steam`, `Ubisoft`
* AppData Start Menu move/delete folders for `Rockstar Games` and `Ubisoft`

Intended mutation or launch type:

* Creates shortcuts, moves installer-created shortcuts, and deletes shortcut
  folders.

Required foundation:

* Phase 36 file state capture.
* Phase 38 cleanup policy.

Required future production allowlist:

* Exact shortcut path and folder scopes per app.

Required provenance before download/launch:

* Not applicable, but target executable identity must be verified before
  shortcut creation.

Required inventory/capture before mutation:

* Prior shortcut/folder existence and identity.

Required confirmation level:

* Included in app Action Plan.

Required verification:

* Shortcut target and working directory match approved paths.
* Deleted folders are exact approved installer-created folders only.

Rollback/restore feasibility:

* Possible only with file capture or quarantine records.

Risk level:

* Medium to high.

Later implementation decision:

* Can be considered after exact shortcut scopes are approved.

### 9. Config File Creation/Modification Behavior

Exact source targets:

* `$env:APPDATA\discord\settings.json`
* `$env:APPDATA\Spotify\prefs`
* `$env:AppData\Notepad++\config.xml`
* `$env:APPDATA\Mozilla\Firefox\Profiles\*.default-release\user.js`
* `C:\Program Files\Mozilla Firefox\distribution\extensions\uBlock0@raymondhill.net.xpi`

Intended mutation or launch type:

* Creates or overwrites user/app configuration files and browser extension
  files.

Required foundation:

* Phase 36 file state capture.
* Phase 35 artifact provenance for the Firefox extension XPI.

Required future production allowlist:

* Exact config file paths and profile-discovery rule.
* Exact Firefox extension artifact.

Required provenance before download/launch:

* XPI artifact hash, size, and source approval.

Required inventory/capture before mutation:

* Prior file existence, content hash, and backup where overwrite is possible.

Required confirmation level:

* Explicit confirmation in selected app plan.

Required verification:

* Config file exists and contains exact approved content.
* Extension file matches approved artifact hash.

Rollback/restore feasibility:

* Possible only with captured prior file state.

Risk level:

* Medium to high.

Later implementation decision:

* Can be considered per app after exact file scopes and artifact approvals.

### 10. Uninstall/Removal Behavior If Present

Exact source targets:

* Epic Online Services uninstall via registry discovery under
  `HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*`
  and `msiexec.exe /x $guid /qn`
* Mozilla Maintenance Service uninstall via
  `C:\Program Files (x86)\Mozilla Maintenance Service\uninstall.exe /S`
* Brave and Google service deletion.
* Browser scheduled task removal.
* Start Menu shortcut folder deletion.

Intended mutation or launch type:

* Removes components, services, scheduled tasks, and shortcut folders.

Required foundation:

* Installer execution policy.
* Service state capture.
* Future scheduled task capture.
* File cleanup policy.

Required future production allowlist:

* Exact uninstall target, service names, task names, and shortcut folders.

Required provenance before download/launch:

* Local uninstaller identity and MSI product identity must be verified.

Required inventory/capture before mutation:

* Component identity and state before removal.

Required confirmation level:

* Explicit confirmation.

Required verification:

* Removed component is absent and no unrelated targets were touched.

Rollback/restore feasibility:

* Generally unavailable unless exact restore/install state is captured and
  approved.

Risk level:

* High.

Later implementation decision:

* Must remain refused until exact removal and restore rules exist.

### 11. NVIDIA App / FrameView Behavior If Present

Exact source targets:

* `https://images.nvidia.com/content/geforce/technologies/frameview/FrameView_1.8.1/FrameViewSetup.exe`
* `$env:SystemRoot\Temp\FrameView.exe`
* `Start-Process -Wait "$env:SystemRoot\Temp\FrameView.exe" -ArgumentList "/s"`
* `https://us.download.nvidia.com/nvapp/client/11.0.6.383/NVIDIA_app_v11.0.6.383.exe`
* `$env:SystemRoot\Temp\NvidiaApp.exe`
* `Start-Process -Wait "$env:SystemRoot\Temp\NvidiaApp.exe" -ArgumentList "/s"`
* Start Menu cleanup for `NVIDIA FrameView` and `NVIDIA Corporation`

Intended mutation or launch type:

* NVIDIA-specific application installation and shortcut cleanup.

Required foundation:

* Phase 35 artifact provenance and installer execution.
* Phase 36/38 file and cleanup scopes for shortcuts.

Required future production allowlist:

* Exact NVIDIA artifact records and execution descriptors.
* Exact shortcut cleanup scopes.

Required provenance before download/launch:

* Exact NVIDIA source URL, expected SHA-256, size, version, signer/publisher,
  and license/redistributability note.

Required inventory/capture before mutation:

* Shortcut and generated-file state.

Required confirmation level:

* Explicit confirmation.

Required verification:

* Artifact verified, process exit captured, shortcut cleanup bounded.

Rollback/restore feasibility:

* Not available without NVIDIA-specific uninstall and file restore design.

Risk level:

* High.

Later implementation decision:

* NVIDIA-specific behavior may be considered later because it is inside product
  scope, but only after artifact and side-effect approvals.

### 12. Reboot/Restart Behavior If Present

Exact source targets:

* No direct `shutdown`, `Restart-Computer`, `bcdedit`, RunOnce, or Scheduled
  Task reboot workflow was found in this source.
* Some third-party installers may still request or require restart outside the
  script's direct control.

Intended mutation or launch type:

* Reboot-capable installer handoff risk.

Required foundation:

* Phase 40 reboot/recovery workflow if any installer is allowed to trigger,
  request, or require restart.

Required future production allowlist:

* Per-installer reboot possibility and expected handoff behavior.

Required provenance before download/launch:

* Artifact must declare `CanReboot`.

Required inventory/capture before mutation:

* App-specific side effects before launch where applicable.

Required confirmation level:

* If installer may reboot, confirmation must state restart risk.

Required verification:

* Exit code and restart-required signal where available.

Rollback/restore feasibility:

* Not available globally.

Risk level:

* High.

Later implementation decision:

* No reboot workflow is approved in this phase.

### 13. Default/Restore Behavior If Present

Exact source targets:

* The source exposes no Default action.
* The source exposes no Restore action.
* The source does not capture install, registry, service, task, shortcut, or
  config state before mutation.

Intended mutation or launch type:

* None.

Required foundation:

* Exact installer provenance, inventory, file/registry/service/task capture,
  uninstall semantics, and restore selection would be required before any
  Default or Restore claim.

Required future production allowlist:

* None approved.

Required provenance before download/launch:

* Not applicable.

Required inventory/capture before mutation:

* Not present in source.

Required confirmation level:

* Not applicable.

Required verification:

* Confirm Installers does not expose working Default or Restore.

Rollback/restore feasibility:

* Current Default/Restore must remain unavailable.

Risk level:

* High if incorrectly exposed.

Later implementation decision:

* Do not expose Default or Restore unless each selected app has exact restore
  capability.

### 14. Unsupported Unverified Artifacts or Broad Installer Targets

Exact source targets:

* Any artifact without exact SHA-256, size, signer, and approval.
* Any mutable `latest` or redirect URL without pinning and provenance.
* Any dynamic service/task/key deletion.
* Any broad or app-discovered uninstall target.

Intended mutation or launch type:

* Unsupported until explicitly approved.

Required foundation:

* Phase 35, Phase 36, Phase 37, Phase 38, and future scheduled task governance
  as applicable.

Required future production allowlist:

* Exact artifact, execution, registry, file, service, task, shortcut, config,
  uninstall, cleanup, and reboot scopes.

Required provenance before download/launch:

* Complete provenance must exist before any external download or executable
  launch.

Required inventory/capture before mutation:

* Required for every mutable system/user target.

Required confirmation level:

* Explicit high-risk confirmation.

Required verification:

* Full before/after verification per selected installer.

Rollback/restore feasibility:

* Unavailable until app-specific restore design exists.

Risk level:

* High.

Later implementation decision:

* Must remain refused until exact approvals exist.

## Exact Source Target Inventory

Download URL count: `24`.

Source menu options:

* `Write-Host " 2. Discord"`
* `Write-Host " 3. Roblox"`
* `Write-Host " 4. 7-Zip"`
* `Write-Host " 5. Battle.net"`
* `Write-Host " 6. Brave"`
* `Write-Host " 7. Electronic Arts"`
* `Write-Host " 8. Epic Games"`
* `Write-Host " 9. Escape From Tarkov"`
* `Write-Host "10. Firefox"`
* `Write-Host "11. Frame View"`
* `Write-Host "12. GOG launcher"`
* `Write-Host "13. Google Chrome"`
* `Write-Host "14. League Of Legends"`
* `Write-Host "15. Notepad ++"`
* `Write-Host "16. Nvidia App"`
* `Write-Host "17. OBS Studio"`
* `Write-Host "18. Onboard Memory Manager"`
* `Write-Host "19. Pot Player"`
* `Write-Host "20. Rockstar Games"`
* `Write-Host "21. Spotify"`
* `Write-Host "22. Steam"`
* `Write-Host "23. Ubisoft Connect"`
* `Write-Host "24. Valorant`n"`

Installer and tool URLs:

* `https://discord.com/api/downloads/distributions/app/installers/latest?channel=stable&platform=win&arch=x64`
* `https://www.roblox.com/download/client?os=win`
* `https://www.7-zip.org/a/7z2301-x64.exe`
* `https://downloader.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe`
* `https://brave-browser-downloads.s3.brave.com/latest/brave_installer-x64.exe`
* `https://origin-a.akamaihd.net/EA-Desktop-Client-Download/installer-releases/EAappInstaller.exe`
* `https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.msi`
* `https://prod.escapefromtarkov.com/launcher/download`
* `https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US`
* `https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi`
* `https://images.nvidia.com/content/geforce/technologies/frameview/FrameView_1.8.1/FrameViewSetup.exe`
* `https://webinstallers.gog-statics.com/download/GOG_Galaxy_2.0.exe`
* `https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi`
* `https://lol.secure.dyn.riotcdn.net/channels/public/x/installer/current/live.na.exe`
* `https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.9.3/npp.8.9.3.Installer.x64.exe`
* `https://us.download.nvidia.com/nvapp/client/11.0.6.383/NVIDIA_app_v11.0.6.383.exe`
* `https://cdn-fastly.obsproject.com/downloads/OBS-Studio-32.1.0-Windows-x64-Installer.exe`
* `https://download01.logi.com/web/ftp/pub/techsupport/gaming/OnboardMemoryManager_2.6.1749.exe`
* `https://t1.daumcdn.net/potplayer/PotPlayer/Version/Latest/PotPlayerSetup64.exe`
* `https://gamedownloads.rockstargames.com/public/installer/Rockstar-Games-Launcher.exe`
* `https://download.scdn.co/SpotifySetup.exe`
* `https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe`
* `https://static3.cdn.ubi.com/orbit/launcher_installer/UbisoftConnectInstaller.exe`
* `https://valorant.secure.dyn.riotcdn.net/channels/public/x/installer/current/live.live.ap.exe`

Policy and registry paths:

* `HKEY_CURRENT_USER\Software\7-Zip\Options`
* `HKLM\SOFTWARE\Policies\BraveSoftware\Brave\ExtensionInstallForcelist`
* `HKLM\SOFTWARE\Policies\BraveSoftware\Brave`
* `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`
* `HKLM\SOFTWARE\Policies\Mozilla\Firefox`
* `HKLM\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist`
* `HKLM\SOFTWARE\Policies\Google\Chrome`
* `HKLM:\Software\Microsoft\Active Setup\Installed Components`
* `HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*`

Service and task patterns:

* `Get-Service | Where-Object { $_.Name -match 'Brave' }`
* `Get-Service | Where-Object { $_.Name -match 'Google' }`
* `sc stop`
* `sc delete`
* `Get-ScheduledTask | Where-Object { $_.TaskName -like '*Brave*' }`
* `Get-ScheduledTask | Where-Object {$_.Taskname -match 'Firefox'}`
* `Get-ScheduledTask | Where-Object { $_.TaskName -like '*Google*' }`

Representative file/config/shortcut targets:

* `$env:APPDATA\discord\settings.json`
* `$env:APPDATA\Spotify\prefs`
* `$env:AppData\Notepad++\config.xml`
* `$env:APPDATA\Mozilla\Firefox\Profiles`
* `C:\Program Files\Mozilla Firefox\distribution\extensions`
* `$env:ProgramData\Microsoft\Windows\Start Menu\Programs`
* `$Desktop\7-Zip File Manager.lnk`
* `$Desktop\Battle.net.lnk`
* `$Desktop\Battlestate Games Launcher.lnk`
* `$Desktop\Notepad++.lnk`
* `$Desktop\Onboard Memory Manager.lnk`

## Future Safe Apply/Open/Install Requirements

A future implementation must be selection-based. Each app must have:

1. Exact artifact provenance for every download.
2. Exact execution descriptor for every launch.
3. Exact side-effect inventory for registry, service, task, shortcut, config,
   file, uninstall, cleanup, and reboot behavior.
4. Capture before every mutable target.
5. Explicit Action Plan confirmation.
6. Verification before and after download/install.
7. Clear user warnings about third-party installation, bundled components,
   silent arguments, EULAs, network dependency, system changes, and uninstall
   limitations.

Potential future actions:

* `Analyze`: list installer readiness and missing approvals.
* `Open`: only if a future app entry has a safe built-in UI or vendor page
  launch that does not download or execute.
* `Apply` or `Install`: only for individually approved app selections.

## Default and Restore Boundary

Current Default/Restore must remain unavailable.

The Ultimate source provides installation and post-install mutation behavior
only. It does not provide a reliable global uninstall/default/restore model.
BoostLab must not expose Default or Restore for Installers unless a future
phase approves exact installer provenance, inventory, file/registry/service/task
capture, uninstall semantics, generated-file ownership, and restore selection
for each selected application.

## Production Approval State

Current approved production scopes for Installers:

* Artifact approvals: none.
* Download approvals: none.
* Installer execution approvals: none.
* Executable launch approvals: none.
* Registry scopes: none.
* File scopes: none.
* Service scopes: none.
* Scheduled task scopes: none.
* Shortcut scopes: none.
* Config scopes: none.
* Uninstall scopes: none.
* Cleanup scopes: none.
* Reboot/recovery scopes: none.
* Default/Restore scopes: none.

Installers Auto must remain blocked until these approvals are supplied in
future explicit implementation phases. The Phase 105 surface remains controlled
manual handoff only.
