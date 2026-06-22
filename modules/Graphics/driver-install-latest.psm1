Set-StrictMode -Version Latest

if (-not (Get-Command -Name 'Invoke-BoostLabOfficialVendorDownload' -ErrorAction SilentlyContinue)) {
    Import-Module (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\DownloadProvenance.psm1') -Force
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'driver-install-latest'
    Title = 'Driver Install Latest'
    Stage = 'Graphics'
    Order = 3
    Type = 'assistant'
    RiskLevel = 'high'
    Description = 'Run the source-equivalent NVIDIA, AMD, or INTEL latest driver workflow for one selected branch after explicit confirmation.'
    Actions     = @('Analyze', 'Open', 'Apply', 'Default', 'Restore')
    Capabilities = [ordered]@{
        RequiresAdmin             = $true
        RequiresInternet          = $true
        CanReboot                 = $true
        CanModifyRegistry         = $false
        CanModifyServices         = $false
        CanInstallSoftware        = $true
        CanDownload               = $true
        CanModifyDrivers          = $true
        CanModifySecurity         = $false
        CanDeleteFiles            = $false
        UsesTrustedInstaller      = $false
        UsesSafeMode              = $false
        SupportsDefault           = $false
        SupportsRestore           = $false
        NeedsExplicitConfirmation = $true
    }
}

$script:BoostLabImplementedActions = @('Analyze', 'Open', 'Apply', 'Default', 'Restore')
$script:BoostLabExpectedSourceHash = '41C9DEA9AA5D208C9ED1EB7F1512B24251FBF4DC01C6DE2858B5B1A26C631A2F'
$script:BoostLabExpectedCanonicalSourceHash = '41C9DEA9AA5D208C9ED1EB7F1512B24251FBF4DC01C6DE2858B5B1A26C631A2F'
$script:BoostLabSourceRelativePath = 'source-ultimate/_intake-promoted/Ultimate/5 Graphics/2 Driver Install Latest.ps1'
$script:BoostLabApprovedBranches = @('NVIDIA', 'AMD', 'INTEL')

function Get-BoostLabDriverInstallLatestSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    return Join-Path $projectRoot ($script:BoostLabSourceRelativePath -replace '/', '\')
}

function Get-BoostLabDriverInstallLatestSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourcePath = Get-BoostLabDriverInstallLatestSourcePath
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $sourceVerificationModulePath = Join-Path $projectRoot 'core\SourceVerification.psm1'
    if (-not (Get-Command -Name 'Test-BoostLabSourceChecksum' -ErrorAction SilentlyContinue)) {
        Import-Module -Name $sourceVerificationModulePath -Scope Local -Force -ErrorAction Stop
    }

    $verification = Test-BoostLabSourceChecksum -LiteralPath $sourcePath -ExpectedSha256 $script:BoostLabExpectedSourceHash -ExpectedCanonicalSha256 $script:BoostLabExpectedCanonicalSourceHash

    [pscustomobject]@{
        SourcePath                = $sourcePath
        SourceRelativePath        = $script:BoostLabSourceRelativePath
        Exists                    = [bool]$verification.Exists
        ExpectedSha256            = $script:BoostLabExpectedSourceHash
        DetectedSha256            = [string]$verification.DetectedSha256
        ExpectedCanonicalSha256   = $script:BoostLabExpectedCanonicalSourceHash
        DetectedCanonicalSha256   = [string]$verification.DetectedCanonicalSha256
        ChecksumStatus            = [string]$verification.ChecksumStatus
        RawChecksumStatus         = [string]$verification.RawChecksumStatus
        CanonicalChecksumStatus   = [string]$verification.CanonicalChecksumStatus
        VerificationMode          = [string]$verification.VerificationMode
    }
}

function Test-BoostLabDriverInstallLatestAdministrator {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-BoostLabDriverInstallLatestInternet {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    return [bool](Test-Connection -ComputerName '8.8.8.8' -Count 1 -Quiet -ErrorAction SilentlyContinue)
}

function ConvertTo-BoostLabDriverInstallLatestBranch {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [AllowNull()]
        [string]$Branch,

        [AllowNull()]
        [string[]]$SelectedAppIds = @()
    )

    if ([string]::IsNullOrWhiteSpace($Branch) -and @($SelectedAppIds).Count -eq 1) {
        $Branch = [string]@($SelectedAppIds)[0]
    }

    if ([string]::IsNullOrWhiteSpace($Branch)) {
        return ''
    }

    $normalized = $Branch.Trim().ToUpperInvariant()
    switch ($normalized) {
        '1' { return 'NVIDIA' }
        'NVIDIA' { return 'NVIDIA' }
        '2' { return 'AMD' }
        'AMD' { return 'AMD' }
        '3' { return 'INTEL' }
        'INTEL' { return 'INTEL' }
        default { return $normalized }
    }
}

function New-BoostLabDriverInstallLatestResult {
    param(
        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$CommandStatus,

        [Parameter(Mandatory)]
        [string]$VerificationStatus,

        [Parameter(Mandatory)]
        [string]$Message,

        [AllowNull()]
        [object]$Data = $null,

        [string[]]$Warnings = @(),

        [string[]]$Errors = @(),

        [bool]$Cancelled = $false,

        [bool]$ChangesExecuted = $false,

        [bool]$RestartRequired = $false
    )

    [pscustomobject]@{
        Success            = $Success
        ToolId             = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle          = [string]$script:BoostLabToolMetadata['Title']
        Action             = $Action
        Status             = $Status
        CommandStatus      = $CommandStatus
        VerificationStatus = $VerificationStatus
        Message            = $Message
        RestartRequired    = $RestartRequired
        Cancelled          = $Cancelled
        ChangesExecuted    = $ChangesExecuted
        Timestamp          = Get-Date
        Data               = $Data
        Warnings           = @($Warnings | Select-Object -Unique)
        Errors             = @($Errors)
    }
}

function Get-BoostLabDriverInstallLatestPaths {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $systemRoot = if ([string]::IsNullOrWhiteSpace($env:SystemRoot)) { 'C:\Windows' } else { $env:SystemRoot }

    @{
        SystemRoot       = $systemRoot
        Temp             = Join-Path $systemRoot 'Temp'
        NvidiaDriverExe  = Join-Path $systemRoot 'Temp\nvidiadriver.exe'
        AmdDriverExe     = Join-Path $systemRoot 'Temp\amddriver.exe'
        IntelDriverPage  = 'https://www.intel.com/content/www/us/en/search.html#sortCriteria=%40lastmodifieddt%20descending&f-operatingsystem_en=Windows%2011%20Family*&f-downloadtype=Drivers&cf-tabfilter=Downloads&cf-downloadsppth=Graphics'
        NvidiaLookupUri  = 'https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&psid=120&pfid=929&osID=57&languageCode=1033&isWHQL=1&dch=1&sort1=0&numberOfResults=1'
        AmdSupportPage   = 'https://www.amd.com/en/support/download/drivers.html'
        AmdDownloadRegex = 'drivers\.amd\.com/drivers/installer/.*/whql/amd-software-adrenalin-edition-.*-minimalsetup-.*_web\.exe'
    }
}

function New-BoostLabDriverInstallLatestOperation {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [int]$Order,

        [Parameter(Mandatory)]
        [string]$Branch,

        [Parameter(Mandatory)]
        [string]$Category,

        [Parameter(Mandatory)]
        [string]$Type,

        [Parameter(Mandatory)]
        [string]$Label,

        [Parameter(Mandatory)]
        [string]$SourceCommand,

        [AllowNull()]
        [System.Collections.IDictionary]$Parameters = $null
    )

    if ($null -eq $Parameters) {
        $Parameters = [ordered]@{}
    }

    [pscustomobject]@{
        Order         = $Order
        Branch        = $Branch
        Category      = $Category
        Type          = $Type
        Label         = $Label
        SourceCommand = $SourceCommand
        Parameters    = [ordered]@{} + $Parameters
    }
}

function Add-BoostLabDriverInstallLatestOperation {
    param(
        [System.Collections.Generic.List[object]]$Operations,

        [Parameter(Mandatory)]
        [ref]$Order,

        [Parameter(Mandatory)]
        [string]$Branch,

        [Parameter(Mandatory)]
        [string]$Category,

        [Parameter(Mandatory)]
        [string]$Type,

        [Parameter(Mandatory)]
        [string]$Label,

        [Parameter(Mandatory)]
        [string]$SourceCommand,

        [AllowNull()]
        [System.Collections.IDictionary]$Parameters = $null
    )

    $Operations.Add((New-BoostLabDriverInstallLatestOperation `
        -Order $Order.Value `
        -Branch $Branch `
        -Category $Category `
        -Type $Type `
        -Label $Label `
        -SourceCommand $SourceCommand `
        -Parameters $Parameters))
    $Order.Value++
}

function Add-BoostLabDriverInstallLatestCommonOperations {
    param(
        [System.Collections.Generic.List[object]]$Operations,

        [Parameter(Mandatory)]
        [ref]$Order,

        [Parameter(Mandatory)]
        [string]$Branch
    )

    Add-BoostLabDriverInstallLatestOperation $Operations $Order $Branch 'Environment' 'RequireAdministrator' 'Require Administrator execution' '# SCRIPT RUN AS ADMIN'
    Add-BoostLabDriverInstallLatestOperation $Operations $Order $Branch 'Environment' 'RequireInternet' 'Require internet connectivity' 'Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet'
}

function Get-BoostLabDriverInstallLatestNvidiaOperations {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Paths
    )

    $operations = [System.Collections.Generic.List[object]]::new()
    $order = 1
    $orderRef = [ref]$order
    $branch = 'NVIDIA'
    Add-BoostLabDriverInstallLatestCommonOperations $operations $orderRef $branch
    Add-BoostLabDriverInstallLatestOperation $operations $orderRef $branch 'Guidance' 'Message' 'Display NVIDIA App guidance' 'Write-Host "Unless recording or using replay buffer..."' ([ordered]@{
        Lines = @(
            'Unless recording or using replay buffer, avoid installing the NVIDIA App.'
            'Game Filter (ALT+F3) and Statistics (ALT+R) will significantly reduce FPS when enabled.'
            "In the NVIDIA App turn off 'Automatically optimize newly added games and apps'."
        )
    })
    Add-BoostLabDriverInstallLatestOperation $operations $orderRef $branch 'DriverLookup' 'QueryNvidiaLatestDriver' 'Find latest NVIDIA driver version' '$response = Invoke-WebRequest -Uri $uri -Method GET -UseBasicParsing; $payload = $response.Content | ConvertFrom-Json' ([ordered]@{
        Uri = $Paths.NvidiaLookupUri
        DownloadUrlTemplate = 'https://international.download.nvidia.com/Windows/{0}/{0}-desktop-{1}-{2}-international-dch-whql.exe'
        WindowsVersionRule = '$windowsVersion = if ([Environment]::OSVersion.Version -ge (new-object ''Version'' 9, 1)) {"win10-win11"} else {"win8-win7"}'
        ArchitectureRule = '$windowsArchitecture = if ([Environment]::Is64BitOperatingSystem) {"64bit"} else {"32bit"}'
    })
    Add-BoostLabDriverInstallLatestOperation $operations $orderRef $branch 'Download' 'DownloadResolvedNvidiaDriver' 'Download latest NVIDIA driver installer' 'IWR $url -OutFile "$env:SystemRoot\Temp\nvidiadriver.exe"' ([ordered]@{
        Destination = $Paths.NvidiaDriverExe
    })
    Add-BoostLabDriverInstallLatestOperation $operations $orderRef $branch 'Installer' 'StartProcess' 'Launch NVIDIA driver installer' 'Start-Process "$env:SystemRoot\Temp\nvidiadriver.exe"' ([ordered]@{
        FilePath = $Paths.NvidiaDriverExe
        Wait = $false
    })

    return $operations.ToArray()
}

function Get-BoostLabDriverInstallLatestAmdOperations {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Paths
    )

    $operations = [System.Collections.Generic.List[object]]::new()
    $order = 1
    $orderRef = [ref]$order
    $branch = 'AMD'
    Add-BoostLabDriverInstallLatestCommonOperations $operations $orderRef $branch
    Add-BoostLabDriverInstallLatestOperation $operations $orderRef $branch 'DriverLookup' 'QueryAmdDriverInstaller' 'Find AMD web installer link from support page' 'Invoke-WebRequest "https://www.amd.com/en/support/download/drivers.html" -UseBasicParsing | Select-Object -ExpandProperty Links | Where-Object { $_.href -match "drivers\.amd\.com/drivers/installer/.*/whql/amd-software-adrenalin-edition-.*-minimalsetup-.*_web\.exe" } | Select-Object href' ([ordered]@{
        Uri = $Paths.AmdSupportPage
        HrefRegex = $Paths.AmdDownloadRegex
    })
    Add-BoostLabDriverInstallLatestOperation $operations $orderRef $branch 'Download' 'DownloadResolvedAmdDriver' 'Download AMD Driver Web Installer' 'IWR $DownloadAmd.href -UseBasicParsing -Headers $spoofwebbrowser -OutFile "$env:SystemRoot\Temp\amddriver.exe" -ErrorAction SilentlyContinue | Out-Null' ([ordered]@{
        Destination = $Paths.AmdDriverExe
        Headers = [ordered]@{
            'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36'
            'Accept' = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
            'Referer' = 'https://www.amd.com/'
        }
    })
    Add-BoostLabDriverInstallLatestOperation $operations $orderRef $branch 'Installer' 'StartProcess' 'Launch AMD web driver installer' 'Start-Process "$env:SystemRoot\Temp\amddriver.exe"' ([ordered]@{
        FilePath = $Paths.AmdDriverExe
        Wait = $false
    })

    return $operations.ToArray()
}

function Get-BoostLabDriverInstallLatestIntelOperations {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Paths
    )

    $operations = [System.Collections.Generic.List[object]]::new()
    $order = 1
    $orderRef = [ref]$order
    $branch = 'INTEL'
    Add-BoostLabDriverInstallLatestCommonOperations $operations $orderRef $branch
    Add-BoostLabDriverInstallLatestOperation $operations $orderRef $branch 'DriverPage' 'StartProcess' 'Open Intel Windows 11 graphics driver search page' 'Start-Process "https://www.intel.com/content/www/us/en/search.html#sortCriteria=%40lastmodifieddt%20descending&f-operatingsystem_en=Windows%2011%20Family*&f-downloadtype=Drivers&cf-tabfilter=Downloads&cf-downloadsppth=Graphics"' ([ordered]@{
        FilePath = $Paths.IntelDriverPage
        Wait = $false
    })

    return $operations.ToArray()
}

function Get-BoostLabDriverInstallLatestOperationPlan {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('NVIDIA', 'AMD', 'INTEL')]
        [string]$Branch
    )

    $paths = Get-BoostLabDriverInstallLatestPaths
    $operations = switch ($Branch) {
        'NVIDIA' { Get-BoostLabDriverInstallLatestNvidiaOperations -Paths $paths }
        'AMD' { Get-BoostLabDriverInstallLatestAmdOperations -Paths $paths }
        'INTEL' { Get-BoostLabDriverInstallLatestIntelOperations -Paths $paths }
    }

    [pscustomobject]@{
        Branch        = $Branch
        OperationMode = 'SourceEquivalentLatestDriverWorkflow'
        OperationCount = @($operations).Count
        Operations    = @($operations)
        Paths         = $paths
    }
}

function Get-BoostLabDriverInstallLatestAllOperationPlans {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param()

    foreach ($branch in $script:BoostLabApprovedBranches) {
        Get-BoostLabDriverInstallLatestOperationPlan -Branch $branch
    }
}

function New-BoostLabDriverInstallLatestOperationResult {
    param(
        [Parameter(Mandatory)]
        [object]$Operation,

        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [string]$Message,

        [AllowNull()]
        [object]$Data = $null
    )

    [pscustomobject]@{
        Success   = $Success
        Order     = [int]$Operation.Order
        Branch    = [string]$Operation.Branch
        Category  = [string]$Operation.Category
        Type      = [string]$Operation.Type
        Label     = [string]$Operation.Label
        Target    = if ($Operation.Parameters.Contains('Destination')) {
            [string]$Operation.Parameters['Destination']
        }
        elseif ($Operation.Parameters.Contains('FilePath')) {
            [string]$Operation.Parameters['FilePath']
        }
        elseif ($Operation.Parameters.Contains('Uri')) {
            [string]$Operation.Parameters['Uri']
        }
        else {
            ''
        }
        Message   = $Message
        Data      = $Data
        Timestamp = Get-Date
    }
}

function Invoke-BoostLabDriverInstallLatestRealOperation {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [object]$Operation,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Context
    )

    try {
        $parameters = $Operation.Parameters
        switch ([string]$Operation.Type) {
            'RequireAdministrator' {
                if (-not (Test-BoostLabDriverInstallLatestAdministrator)) {
                    return New-BoostLabDriverInstallLatestOperationResult -Operation $Operation -Success $false -Message 'Administrator execution is required.'
                }
                return New-BoostLabDriverInstallLatestOperationResult -Operation $Operation -Success $true -Message 'Administrator execution confirmed.'
            }
            'RequireInternet' {
                if (-not (Test-BoostLabDriverInstallLatestInternet)) {
                    return New-BoostLabDriverInstallLatestOperationResult -Operation $Operation -Success $false -Message 'Internet connectivity is required.'
                }
                return New-BoostLabDriverInstallLatestOperationResult -Operation $Operation -Success $true -Message 'Internet connectivity confirmed.'
            }
            'Message' {
                return New-BoostLabDriverInstallLatestOperationResult -Operation $Operation -Success $true -Message 'Source guidance represented in BoostLab result.'
            }
            'QueryNvidiaLatestDriver' {
                $lookupSource = Get-BoostLabApprovedOfficialVendorRuntimeSource `
                    -ArtifactId 'driver-install-latest-nvidia-lookup' `
                    -Purpose Lookup `
                    -SourceUrl ([string]$parameters['Uri'])
                if (-not $lookupSource.Allowed) {
                    return New-BoostLabDriverInstallLatestOperationResult -Operation $Operation -Success $false -Message "NVIDIA lookup source blocked: $(@($lookupSource.Errors) -join '; ')"
                }

                $response = Invoke-WebRequest -Uri ([string]$lookupSource.SourceUrl) -Method GET -UseBasicParsing
                $payload = $response.Content | ConvertFrom-Json
                $version = [string]$payload.IDS[0].downloadInfo.Version
                if ([string]::IsNullOrWhiteSpace($version)) {
                    return New-BoostLabDriverInstallLatestOperationResult -Operation $Operation -Success $false -Message 'NVIDIA latest driver version was not found in the lookup response.'
                }

                $windowsVersion = if ([Environment]::OSVersion.Version -ge ([Version]::new(9, 1))) { 'win10-win11' } else { 'win8-win7' }
                $windowsArchitecture = if ([Environment]::Is64BitOperatingSystem) { '64bit' } else { '32bit' }
                $url = [string]::Format([string]$parameters['DownloadUrlTemplate'], $version, $windowsVersion, $windowsArchitecture)
                $Context['NvidiaDriverVersion'] = $version
                $Context['NvidiaDriverUrl'] = $url
                return New-BoostLabDriverInstallLatestOperationResult -Operation $Operation -Success $true -Message "NVIDIA latest driver resolved: $version" -Data ([pscustomobject]@{
                    NvidiaDriverVersion = $version
                    NvidiaDriverUrl = $url
                    WindowsVersion = $windowsVersion
                    WindowsArchitecture = $windowsArchitecture
                })
            }
            'DownloadResolvedNvidiaDriver' {
                if (-not $Context.Contains('NvidiaDriverUrl') -or [string]::IsNullOrWhiteSpace([string]$Context['NvidiaDriverUrl'])) {
                    return New-BoostLabDriverInstallLatestOperationResult -Operation $Operation -Success $false -Message 'NVIDIA driver URL was not resolved before download.'
                }

                Invoke-BoostLabOfficialVendorDownload `
                    -ArtifactId 'driver-install-latest-nvidia-driver-template' `
                    -SourceUrl ([string]$Context['NvidiaDriverUrl']) `
                    -Destination ([string]$parameters['Destination']) | Out-Null
                return New-BoostLabDriverInstallLatestOperationResult -Operation $Operation -Success $true -Message "Downloaded NVIDIA driver installer to $($parameters['Destination'])." -Data ([pscustomobject]@{
                    Url = [string]$Context['NvidiaDriverUrl']
                    Destination = [string]$parameters['Destination']
                })
            }
            'QueryAmdDriverInstaller' {
                $lookupSource = Get-BoostLabApprovedOfficialVendorRuntimeSource `
                    -ArtifactId 'driver-install-latest-amd-support-page' `
                    -Purpose Lookup `
                    -SourceUrl ([string]$parameters['Uri'])
                if (-not $lookupSource.Allowed) {
                    return New-BoostLabDriverInstallLatestOperationResult -Operation $Operation -Success $false -Message "AMD lookup source blocked: $(@($lookupSource.Errors) -join '; ')"
                }

                $downloadAmd = Invoke-WebRequest ([string]$lookupSource.SourceUrl) -UseBasicParsing |
                    Select-Object -ExpandProperty Links |
                    Where-Object { $_.href -match ([string]$parameters['HrefRegex']) } |
                    Select-Object -First 1 -ExpandProperty href
                if ([string]::IsNullOrWhiteSpace([string]$downloadAmd)) {
                    return New-BoostLabDriverInstallLatestOperationResult -Operation $Operation -Success $false -Message 'AMD web installer link was not found on the support page.'
                }

                $Context['AmdDriverUrl'] = [string]$downloadAmd
                return New-BoostLabDriverInstallLatestOperationResult -Operation $Operation -Success $true -Message 'AMD web installer link resolved.' -Data ([pscustomobject]@{
                    AmdDriverUrl = [string]$downloadAmd
                })
            }
            'DownloadResolvedAmdDriver' {
                if (-not $Context.Contains('AmdDriverUrl') -or [string]::IsNullOrWhiteSpace([string]$Context['AmdDriverUrl'])) {
                    return New-BoostLabDriverInstallLatestOperationResult -Operation $Operation -Success $false -Message 'AMD driver URL was not resolved before download.'
                }

                $headers = @{}
                foreach ($header in $parameters['Headers'].GetEnumerator()) {
                    $headers[[string]$header.Key] = [string]$header.Value
                }

                Invoke-BoostLabOfficialVendorDownload `
                    -ArtifactId 'driver-install-latest-amd-support-page' `
                    -SourceUrl ([string]$Context['AmdDriverUrl']) `
                    -Destination ([string]$parameters['Destination']) `
                    -Headers $headers | Out-Null
                return New-BoostLabDriverInstallLatestOperationResult -Operation $Operation -Success $true -Message "Requested AMD driver installer download to $($parameters['Destination'])." -Data ([pscustomobject]@{
                    Url = [string]$Context['AmdDriverUrl']
                    Destination = [string]$parameters['Destination']
                })
            }
            'StartProcess' {
                if ([string]$parameters['FilePath'] -like 'https://www.intel.com/*') {
                    $lookupSource = Get-BoostLabApprovedOfficialVendorRuntimeSource `
                        -ArtifactId 'driver-install-latest-intel-driver-page' `
                        -Purpose Lookup `
                        -SourceUrl ([string]$parameters['FilePath'])
                    if (-not $lookupSource.Allowed) {
                        return New-BoostLabDriverInstallLatestOperationResult -Operation $Operation -Success $false -Message "INTEL driver page source blocked: $(@($lookupSource.Errors) -join '; ')"
                    }
                }
                $startParameters = @{
                    FilePath = [string]$parameters['FilePath']
                }
                if ($parameters.Contains('Wait') -and [bool]$parameters['Wait']) {
                    $startParameters['Wait'] = $true
                }
                Start-Process @startParameters
                return New-BoostLabDriverInstallLatestOperationResult -Operation $Operation -Success $true -Message "Started process or URL: $($parameters['FilePath'])."
            }
            default {
                return New-BoostLabDriverInstallLatestOperationResult -Operation $Operation -Success $false -Message "Unsupported operation type '$($Operation.Type)'."
            }
        }
    }
    catch {
        return New-BoostLabDriverInstallLatestOperationResult -Operation $Operation -Success $false -Message $_.Exception.Message
    }
}

function Invoke-BoostLabDriverInstallLatestWorkflow {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('NVIDIA', 'AMD', 'INTEL')]
        [string]$Branch,

        [scriptblock]$OperationExecutor = $null,

        [bool]$SkipEnvironmentChecks = $false
    )

    $plan = Get-BoostLabDriverInstallLatestOperationPlan -Branch $Branch
    $context = [ordered]@{
        Branch = $Branch
    }
    $operationResults = [System.Collections.Generic.List[object]]::new()
    $changesStarted = $false

    foreach ($operation in @($plan.Operations)) {
        if ($SkipEnvironmentChecks -and [string]$operation.Type -in @('RequireAdministrator', 'RequireInternet')) {
            $skipResult = New-BoostLabDriverInstallLatestOperationResult -Operation $operation -Success $true -Message 'Skipped by test-safe executor option.'
            $operationResults.Add($skipResult)
            continue
        }

        if ($null -ne $OperationExecutor) {
            $result = & $OperationExecutor $operation $Branch $context
        }
        else {
            $result = Invoke-BoostLabDriverInstallLatestRealOperation -Operation $operation -Context $context
        }
        if ($null -eq $result) {
            $result = New-BoostLabDriverInstallLatestOperationResult -Operation $operation -Success $false -Message 'Operation executor returned no result.'
        }

        $operationResults.Add($result)
        if ([string]$operation.Type -notin @('RequireAdministrator', 'RequireInternet', 'Message')) {
            $changesStarted = $true
        }

        if ($null -ne $result.Data) {
            foreach ($property in @($result.Data.PSObject.Properties)) {
                $context[$property.Name] = $property.Value
            }
        }

        if (-not [bool]$result.Success) {
            return [pscustomobject]@{
                Success = $false
                Branch = $Branch
                Plan = $plan
                OperationResults = $operationResults.ToArray()
                FailedOperation = $operation
                ChangesStarted = $changesStarted
                Message = "Operation failed: $($operation.Label). $($result.Message)"
            }
        }
    }

    [pscustomobject]@{
        Success = $true
        Branch = $Branch
        Plan = $plan
        OperationResults = $operationResults.ToArray()
        FailedOperation = $null
        ChangesStarted = $changesStarted
        Message = "Driver Install Latest $Branch workflow completed."
    }
}

function Get-BoostLabDriverInstallLatestAnalysis {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabDriverInstallLatestSourceStatus
    $plans = Get-BoostLabDriverInstallLatestAllOperationPlans
    [pscustomobject]@{
        Mode                            = 'SourceEquivalentThreeBranchRuntime'
        AutoMode                        = 'BranchSelectedSourceEquivalentApply'
        Source                          = $sourceStatus
        PathBWorkflow                   = 'Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode'
        PathBStepNumber                 = 1
        PathBStepTotal                  = 5
        PathBStep                       = '1 of 5'
        SourceBehaviorSummary           = @(
            'Preserves the source Administrator requirement.'
            'Preserves the source internet check to 8.8.8.8.'
            'Preserves the NVIDIA branch: user guidance, NVIDIA driver lookup API, dynamic latest NVIDIA driver URL construction, download to %SystemRoot%\Temp\nvidiadriver.exe, and installer launch.'
            'Preserves the AMD branch: AMD support page scrape, web-installer link selection, spoofed browser headers, download to %SystemRoot%\Temp\amddriver.exe, and installer launch.'
            'Preserves the INTEL branch: Intel Windows 11 graphics driver search page launch.'
        )
        SupportedScope                  = 'NVIDIA, AMD, and INTEL source-defined Driver Install Latest branches are mapped for this tool only by Phase 124 source-equivalent parity work.'
        ProjectWideAmdIntelScopeExpanded = $false
        ApprovedSourceBranches          = @($script:BoostLabApprovedBranches)
        ApplyRequiresBranchSelection    = $true
        OperationPlans                  = $plans
        ArtifactDescriptors             = @(
            'NVIDIA driver lookup API response'
            'dynamic NVIDIA latest driver installer URL'
            '%SystemRoot%\Temp\nvidiadriver.exe'
            'AMD support page response'
            'dynamic AMD minimal setup web installer URL'
            '%SystemRoot%\Temp\amddriver.exe'
            'Intel Windows 11 graphics driver search URL'
        )
        NoMutationOccurred              = $true
        NoDownloadOccurred              = $true
        NoInstallerExecutionOccurred    = $true
        NoExternalProcessStarted        = $true
        NoDriverMutationOccurred        = $true
        NoRegistryMutationOccurred      = $true
        NoFileCleanupOccurred           = $true
        NoRebootOrSessionChangeOccurred = $true
        PathASeparation                 = 'Driver Install Latest remains separate from Driver Install Debloat & Settings.'
        PathBSeparation                 = 'Path B remains separate and ordered: Driver Install Latest -> Nvidia Settings -> Hdcp -> P0 State -> Msi Mode.'
    }
}

function Get-BoostLabToolInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    [pscustomobject]@{
        Id                          = [string]$script:BoostLabToolMetadata['Id']
        Title                       = [string]$script:BoostLabToolMetadata['Title']
        Stage                       = [string]$script:BoostLabToolMetadata['Stage']
        Order                       = [int]$script:BoostLabToolMetadata['Order']
        Type                        = [string]$script:BoostLabToolMetadata['Type']
        RiskLevel                   = [string]$script:BoostLabToolMetadata['RiskLevel']
        Description                 = [string]$script:BoostLabToolMetadata['Description']
        Actions                     = @($script:BoostLabToolMetadata['Actions'])
        Capabilities                = $script:BoostLabToolMetadata['Capabilities']
        ImplementedActions          = @($script:BoostLabImplementedActions)
        ConfirmationRequiredActions = @('Open', 'Apply')
        ConfirmationText            = 'Driver Install Latest executes the source-equivalent NVIDIA, AMD, or INTEL latest-driver workflow for the selected branch only after confirmation. It can query vendor pages/APIs, download driver installers, launch installers or driver pages, and hand off to driver installation that may affect display/session/reboot state. Continue only if this exact selected branch operation is intended.'
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceStatus = Get-BoostLabDriverInstallLatestSourceStatus
    [pscustomobject]@{
        Supported            = $true
        ToolId               = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle            = [string]$script:BoostLabToolMetadata['Title']
        Reason               = 'Driver Install Latest source-equivalent NVIDIA/AMD/INTEL branch runtime is available after explicit confirmation and branch selection.'
        SourceChecksumStatus = [string]$sourceStatus.ChecksumStatus
        Timestamp            = Get-Date
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    [pscustomobject]@{
        ToolId          = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
        Status          = 'SourceEquivalentThreeBranchRuntime'
        LastAction      = $null
        LastResult      = $null
        RestartRequired = $false
        Timestamp       = Get-Date
    }
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ActionName,

        [bool]$Confirmed = $false,

        [string]$Branch = '',

        [string[]]$SelectedAppIds = @(),

        [scriptblock]$OperationExecutor = $null,

        [bool]$SkipEnvironmentChecks = $false
    )

    $canonicalActionName = switch ($ActionName) {
        'Prepare Manual Handoff' { 'Open' }
        'Manual Handoff' { 'Open' }
        'Apply Auto' { 'Apply' }
        default { $ActionName }
    }

    if ($canonicalActionName -notin @($script:BoostLabImplementedActions)) {
        return New-BoostLabDriverInstallLatestResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'Unsupported' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Unsupported Driver Install Latest action. Only Analyze, Open, Apply, Default, and Restore are exposed.'
    }

    if ($canonicalActionName -eq 'Analyze') {
        $analysis = Get-BoostLabDriverInstallLatestAnalysis
        $sourceOk = [string]$analysis.Source.ChecksumStatus -eq 'Passed'
        return New-BoostLabDriverInstallLatestResult `
            -Success $sourceOk `
            -Action 'Analyze' `
            -Status $(if ($sourceOk) { 'Analyzed' } else { 'SourceVerificationFailed' }) `
            -CommandStatus 'No execution performed' `
            -VerificationStatus ([string]$analysis.Source.ChecksumStatus) `
            -Message $(if ($sourceOk) { 'Driver Install Latest analyzed. NVIDIA, AMD, and INTEL source-equivalent branch plans are mapped; no mutation occurred.' } else { 'Driver Install Latest source checksum verification failed or source file is missing.' }) `
            -Data $analysis `
            -Errors $(if ($sourceOk) { @() } else { @('Driver Install Latest source checksum did not match the expected value or the source file is missing.') })
    }

    $sourceStatus = Get-BoostLabDriverInstallLatestSourceStatus
    if ([string]$sourceStatus.ChecksumStatus -ne 'Passed') {
        return New-BoostLabDriverInstallLatestResult `
            -Success $false `
            -Action $canonicalActionName `
            -Status 'SourceVerificationFailed' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus ([string]$sourceStatus.ChecksumStatus) `
            -Message 'Driver Install Latest blocked because source checksum verification failed or the source file is missing.' `
            -Data $sourceStatus `
            -Errors @('Driver Install Latest source checksum did not match the expected value or the source file is missing.')
    }

    if ($canonicalActionName -eq 'Open') {
        if (-not $Confirmed) {
            return New-BoostLabDriverInstallLatestResult `
                -Success $false `
                -Action 'Open' `
                -Status 'Cancelled' `
                -CommandStatus 'Cancelled before execution' `
                -VerificationStatus 'NotApplicable' `
                -Message 'Driver Install Latest Open cancelled by user. No vendor page, driver download, installer launch, external process, driver mutation, reboot, or session change occurred.' `
                -Cancelled $true
        }

        $normalizedBranch = ConvertTo-BoostLabDriverInstallLatestBranch -Branch $Branch -SelectedAppIds $SelectedAppIds
        if ($normalizedBranch -notin $script:BoostLabApprovedBranches) {
            return New-BoostLabDriverInstallLatestResult `
                -Success $false `
                -Action 'Open' `
                -Status 'NeedsBranchSelection' `
                -CommandStatus 'Blocked before execution' `
                -VerificationStatus 'NotApplicable' `
                -Message 'Open requires selecting exactly one source branch: NVIDIA, AMD, or INTEL. No external process was opened.'
        }
        if ($normalizedBranch -ne 'INTEL') {
            return New-BoostLabDriverInstallLatestResult `
                -Success $false `
                -Action 'Open' `
                -Status 'OpenUnavailableForBranch' `
                -CommandStatus 'Refused before execution' `
                -VerificationStatus 'NotApplicable' `
                -Message "Open is unavailable for the $normalizedBranch Driver Install Latest branch because the source $normalizedBranch branch performs download/install workflow through Apply rather than a standalone browser/page handoff. No external process was opened."
        }

        $operation = @((Get-BoostLabDriverInstallLatestOperationPlan -Branch 'INTEL').Operations | Where-Object { [string]$_.Type -eq 'StartProcess' })[0]
        $context = [ordered]@{ Branch = 'INTEL' }
        if ($null -ne $OperationExecutor) {
            $result = & $OperationExecutor $operation 'INTEL' $context
        }
        else {
            $result = Invoke-BoostLabDriverInstallLatestRealOperation -Operation $operation -Context $context
        }
        if (-not [bool]$result.Success) {
            return New-BoostLabDriverInstallLatestResult `
                -Success $false `
                -Action 'Open' `
                -Status 'OpenFailed' `
                -CommandStatus 'Completed with errors' `
                -VerificationStatus 'Failed' `
                -Message "Open failed for INTEL driver page operation: $($result.Message)" `
                -Data ([pscustomobject]@{ Branch = 'INTEL'; Operation = $operation; OperationResult = $result }) `
                -Errors @($result.Message) `
                -ChangesExecuted $true
        }

        return New-BoostLabDriverInstallLatestResult `
            -Success $true `
            -Action 'Open' `
            -Status 'IntelDriverPageOpened' `
            -CommandStatus 'Completed' `
            -VerificationStatus 'Passed' `
            -Message 'Opened the source-defined INTEL Windows 11 graphics driver search page. No NVIDIA/AMD download, installer launch, file mutation, registry mutation, driver mutation, cleanup, or reboot operation ran.' `
            -Data ([pscustomobject]@{ Branch = 'INTEL'; Operation = $operation; OperationResult = $result }) `
            -ChangesExecuted $true
    }

    if ($canonicalActionName -eq 'Apply') {
        if (-not $Confirmed) {
            return New-BoostLabDriverInstallLatestResult `
                -Success $false `
                -Action 'Apply' `
                -Status 'Cancelled' `
                -CommandStatus 'Cancelled before execution' `
                -VerificationStatus 'NotApplicable' `
                -Message 'Driver Install Latest Apply cancelled by user. No branch operation executed.' `
                -Cancelled $true
        }

        $normalizedBranch = ConvertTo-BoostLabDriverInstallLatestBranch -Branch $Branch -SelectedAppIds $SelectedAppIds
        if ($normalizedBranch -notin $script:BoostLabApprovedBranches) {
            return New-BoostLabDriverInstallLatestResult `
                -Success $false `
                -Action 'Apply' `
                -Status 'NeedsBranchSelection' `
                -CommandStatus 'Blocked before execution' `
                -VerificationStatus 'NotApplicable' `
                -Message 'Apply requires selecting exactly one source branch: NVIDIA, AMD, or INTEL. No vendor query, download, installer, browser/page launch, external process, driver mutation, reboot, or session operation executed.'
        }

        $workflow = Invoke-BoostLabDriverInstallLatestWorkflow `
            -Branch $normalizedBranch `
            -OperationExecutor $OperationExecutor `
            -SkipEnvironmentChecks:$SkipEnvironmentChecks

        if (-not [bool]$workflow.Success) {
            return New-BoostLabDriverInstallLatestResult `
                -Success $false `
                -Action 'Apply' `
                -Status 'OperationFailed' `
                -CommandStatus 'Completed with errors' `
                -VerificationStatus 'Failed' `
                -Message ([string]$workflow.Message) `
                -Data $workflow `
                -Errors @([string]$workflow.Message) `
                -ChangesExecuted ([bool]$workflow.ChangesStarted)
        }

        return New-BoostLabDriverInstallLatestResult `
            -Success $true `
            -Action 'Apply' `
            -Status ("{0}WorkflowCompleted" -f $normalizedBranch) `
            -CommandStatus 'Completed' `
            -VerificationStatus 'Passed' `
            -Message "Driver Install Latest $normalizedBranch source-equivalent workflow completed. Any driver-installer reboot or session behavior is vendor-installer controlled and represented by the operation plan." `
            -Data $workflow `
            -ChangesExecuted $true `
            -RestartRequired $false
    }

    if ($canonicalActionName -eq 'Default') {
        return New-BoostLabDriverInstallLatestResult `
            -Success $false `
            -Action 'Default' `
            -Status 'DefaultUnavailable' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Default is unavailable for Driver Install Latest because the source does not define a Default branch. Default is not Restore.'
    }

    if ($canonicalActionName -eq 'Restore') {
        return New-BoostLabDriverInstallLatestResult `
            -Success $false `
            -Action 'Restore' `
            -Status 'RestoreUnavailable' `
            -CommandStatus 'Refused before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Restore is unavailable without approved selected captured driver/download/installer/session state and a Restore contract. No restore mutation is planned.'
    }
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    Invoke-BoostLabToolAction -ActionName 'Default'
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
    'Get-BoostLabDriverInstallLatestSourceStatus'
    'Get-BoostLabDriverInstallLatestAnalysis'
    'Get-BoostLabDriverInstallLatestOperationPlan'
    'Get-BoostLabDriverInstallLatestAllOperationPlans'
    'Invoke-BoostLabDriverInstallLatestWorkflow'
)
