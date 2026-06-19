# Driver Install Latest Migration

## Source

- Source path: `source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1`
- SHA-256: `41C9DEA9AA5D208C9ED1EB7F1512B24251FBF4DC01C6DE2858B5B1A26C631A2F`
- Phase: 124

## Original Ultimate Behavior

The Ultimate script requires Administrator rights, checks internet connectivity
with `Test-Connection` to `8.8.8.8`, then prompts for one GPU branch:

- NVIDIA: prints NVIDIA App guidance, queries NVIDIA's driver lookup API,
  resolves the latest driver version, builds the dynamic
  `international.download.nvidia.com` installer URL, downloads it to
  `%SystemRoot%\Temp\nvidiadriver.exe`, and launches that installer.
- AMD: scrapes `https://www.amd.com/en/support/download/drivers.html`,
  finds the minimal setup web installer link matching the source regex,
  downloads it with the source browser-spoof headers to
  `%SystemRoot%\Temp\amddriver.exe`, and launches that installer.
- INTEL: opens the source-defined Intel Windows 11 graphics driver search page.

The source defines no Default or Restore branch.

## Preserved BoostLab Behavior

BoostLab preserves the same practical branch behavior behind the GUI/runtime
wrapper:

- `Analyze` verifies source identity and reports all three source branch plans
  without mutation.
- `Apply` requires explicit confirmation and exactly one selected source branch:
  NVIDIA, AMD, or INTEL.
- `Open` is source-equivalent only for the branch with standalone page behavior:
  INTEL. NVIDIA and AMD report Open unavailable because their source behavior is
  the Apply download/install workflow.
- `Default` is unavailable because no source Default branch exists.
- `Restore` is unavailable because no selected captured driver/download/
  installer/session restore contract exists.

## Commands And Paths Preserved

- Administrator requirement from `# SCRIPT RUN AS ADMIN`.
- Internet check: `Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet`.
- NVIDIA lookup API:
  `https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&psid=120&pfid=929&osID=57&languageCode=1033&isWHQL=1&dch=1&sort1=0&numberOfResults=1`
- NVIDIA dynamic installer URL pattern:
  `https://international.download.nvidia.com/Windows/<version>/<version>-desktop-<windowsVersion>-<architecture>-international-dch-whql.exe`
- NVIDIA download target: `%SystemRoot%\Temp\nvidiadriver.exe`.
- AMD support page: `https://www.amd.com/en/support/download/drivers.html`.
- AMD link regex:
  `drivers\.amd\.com/drivers/installer/.*/whql/amd-software-adrenalin-edition-.*-minimalsetup-.*_web\.exe`.
- AMD download target: `%SystemRoot%\Temp\amddriver.exe`.
- INTEL page:
  `https://www.intel.com/content/www/us/en/search.html#sortCriteria=%40lastmodifieddt%20descending&f-operatingsystem_en=Windows%2011%20Family*&f-downloadtype=Drivers&cf-tabfilter=Downloads&cf-downloadsppth=Graphics`

## Intentional Deviations

- Console `Read-Host`, `Write-Host`, `Clear-Host`, `Pause`, and `Exit` are
  replaced by GUI branch selection, Action Plan confirmation, structured
  results, and Activity Log output.
- Validators use injected operation mocks and never perform real downloads,
  browser launches, installer launches, driver mutation, file mutation, or
  reboot/session changes.
- No reusable/global artifact provenance or production allowlist entry is added
  in Phase 124. The source-derived descriptors live in the tool runtime plan.

## Capabilities

- RequiresAdmin: true
- RequiresInternet: true
- CanDownload: true
- CanInstallSoftware: true
- CanModifyDrivers: true
- CanReboot: true, because vendor driver installer handoff can affect
  session/reboot state even though the source does not call a reboot command
- CanModifyRegistry: false
- CanModifyServices: false
- CanDeleteFiles: false
- CanModifySecurity: false
- UsesTrustedInstaller: false
- UsesSafeMode: false
- SupportsDefault: false
- SupportsRestore: false
- NeedsExplicitConfirmation: true

## Parity Status

- ImplementationLevel: `NearParityControlled`
- UltimateParity: `Partial`
- FinalProgressStatus: `DoneYazanAcceptedNearParity`
- YazanAcceptedNearParity: true
- YazanFinalException: false
- Gap summary: Yazan-approved BoostLab GUI confirmation/test-safe mechanics
  around exact source-equivalent Driver Install Latest behavior.

## Test Requirements

- Verify source path and checksum.
- Verify `Analyze` is read-only.
- Verify NVIDIA, AMD, and INTEL operation plans map the source commands, URLs,
  paths, and launch behavior.
- Verify `Apply` requires branch selection and confirmation.
- Verify mocked branch execution runs every mapped operation without host
  mutation.
- Verify `Open`, `Default`, and `Restore` remain truthful.
- Verify protected source paths, deleted tools, artifact provenance, and
  production allowlists remain unchanged.
