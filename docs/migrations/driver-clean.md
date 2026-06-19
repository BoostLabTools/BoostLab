# Driver Clean Migration Record

* **Tool name:** Driver Clean
* **Stage:** Graphics
* **Source script path:** `source-ultimate/_intake-promoted/Ultimate/5 Graphics/1 Driver Clean.ps1`
* **Source checksum:** `CF9E1C55ACAFD8A52D2200AC3E6C3AFDF9823837C7B68101C2D4B83E074D325A`
* **Risk level:** High
* **Required privileges:** Administrator
* **Yazan approval status:** Phase 120 approved Driver Clean-specific source-equivalent Auto and Manual behavior

## Original Ultimate Behavior

The source self-elevates, requires internet access, then offers two menu choices:

* `1. DDU: Auto`
* `2. DDU: Manual`

Both branches download `7zip.exe`, install 7-Zip silently, configure 7-Zip HKCU options, move/remove the 7-Zip Start Menu folder, download `ddu.exe`, extract it with 7-Zip, write the source-defined DDU `Settings.xml`, mark that file read-only, and set:

```powershell
HKLM\Software\Microsoft\Windows\CurrentVersion\DriverSearching
SearchOrderConfig = REG_DWORD 0
```

Auto writes `%SystemRoot%\Temp\ddu.ps1`, creates RunOnce value `*ddu`, enables Safe Mode with `bcdedit /set {current} safeboot minimal`, sleeps 5 seconds, and runs `shutdown -r -t 00`. The RunOnce script removes Safe Mode and launches:

```powershell
Start-Process "$env:SystemRoot\Temp\ddu\Display Driver Uninstaller.exe" -ArgumentList "-CleanSoundBlaster -CleanRealtek -CleanAllGpus -Restart" -Wait
```

Manual writes `%SystemRoot%\Temp\ddumanual.ps1`, creates RunOnce value `*ddumanual`, enables Safe Mode, sleeps 5 seconds, and restarts. The RunOnce script removes Safe Mode and launches DDU manually:

```powershell
Start-Process -Wait "$env:SystemRoot\Temp\ddu\Display Driver Uninstaller.exe"
```

## Preserved BoostLab Behavior

BoostLab maps the source branches to canonical actions:

* `Analyze`: read-only source identity and workflow analysis.
* `Apply`: source Auto branch.
* `Open`: source Manual branch.

BoostLab preserves the source URLs, file paths, DDU settings XML, registry value, generated script content, RunOnce value names, Safe Mode command, restart command, and Auto DDU arguments.

## Commands Preserved

```powershell
IWR "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/7zip.exe" -OutFile "$env:SystemRoot\Temp\7zip.exe"
Start-Process -Wait "$env:SystemRoot\Temp\7zip.exe" -ArgumentList "/S"
cmd /c "reg add `"HKEY_CURRENT_USER\Software\7-Zip\Options`" /v `"ContextMenu`" /t REG_DWORD /d `"259`" /f >nul 2>&1"
cmd /c "reg add `"HKEY_CURRENT_USER\Software\7-Zip\Options`" /v `"CascadedMenu`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
Move-Item -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\7-Zip\7-Zip File Manager.lnk" -Destination "$env:ProgramData\Microsoft\Windows\Start Menu\Programs" -Force -ErrorAction SilentlyContinue | Out-Null
Remove-Item "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\7-Zip" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
IWR "https://github.com/FR33THYFR33THY/Ultimate-Files/raw/refs/heads/main/ddu.exe" -OutFile "$env:SystemRoot\Temp\ddu.exe"
& "$env:SystemDrive\Program Files\7-Zip\7z.exe" x "$env:SystemRoot\Temp\ddu.exe" -o"$env:SystemRoot\Temp\ddu" -y | Out-Null
Set-Content -Path "$env:SystemRoot\Temp\ddu\Settings\Settings.xml" -Value $DduConfig -Force
Set-ItemProperty -Path "$env:SystemRoot\Temp\ddu\Settings\Settings.xml" -Name IsReadOnly -Value $true
cmd /c "reg add `"HKLM\Software\Microsoft\Windows\CurrentVersion\DriverSearching`" /v `"SearchOrderConfig`" /t REG_DWORD /d `"0`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce`" /v `"*ddu`" /t REG_SZ /d `"powershell.exe -nop -ep bypass -WindowStyle Maximized -f $env:SystemRoot\Temp\ddu.ps1`" /f >nul 2>&1"
cmd /c "reg add `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce`" /v `"*ddumanual`" /t REG_SZ /d `"powershell.exe -nop -ep bypass -WindowStyle Maximized -f $env:SystemRoot\Temp\ddumanual.ps1`" /f >nul 2>&1"
cmd /c "bcdedit /set {current} safeboot minimal >nul 2>&1"
Start-Sleep -Seconds 5
shutdown -r -t 00
```

## Intentional Deviations

BoostLab replaces the console menu and per-script self-elevation with the application-level Administrator model and GUI Action Plan confirmation. This does not remove source capability.

BoostLab captures the source-defined driver-search policy value before mutation through the state-capture foundation. This adds safety around the exact registry value without changing the source effect.

Automated tests use a mocked operation executor and never download artifacts, install 7-Zip, run DDU, write registry state, create RunOnce, call `bcdedit`, enter Safe Mode, or reboot.

Default remains unavailable because the source does not define a default branch. Restore remains unavailable until a selected captured-state restore contract is explicitly approved.

## Capabilities

`RequiresAdmin = true`; `RequiresInternet = true`; `CanReboot = true`; `CanModifyRegistry = true`; `CanInstallSoftware = true`; `CanDownload = true`; `CanModifyDrivers = true`; `CanDeleteFiles = true`; `UsesSafeMode = true`; `NeedsExplicitConfirmation = true`.

No service, security, TrustedInstaller, Default, or Restore capability is declared.

## Confirmation Behavior

`Apply` and `Open` require explicit Action Plan confirmation. `Analyze` is read-only.

The Action Plan must disclose downloads, installer execution, registry mutation, generated scripts, RunOnce, Safe Mode, `bcdedit`, restart, and DDU Auto/Manual launch behavior.

## Test Requirements

Automated tests must be static or mocked. They must validate the exact source URLs, operation order, registry policy value, generated scripts, RunOnce names, Safe Mode command, restart command, and Auto DDU arguments without performing real side effects.

Tests must confirm:

* `source-ultimate/` and source-promoted mirror files remain unchanged.
* Standalone DDU is not introduced.
* Loudness EQ and NVME Faster Driver remain deleted.
* No production artifact provenance or Driver Clean allowlist config is added.
* Next ordered parity target advances to `driver-install-debloat-settings`.
