Set-StrictMode -Version Latest

$script:BoostLabTestProjectRoot = (Resolve-Path -LiteralPath (Split-Path -Parent $PSScriptRoot) -ErrorAction Stop).Path.TrimEnd('\')
$script:BoostLabTestSourceVerificationPath = Join-Path $script:BoostLabTestProjectRoot 'core\SourceVerification.psm1'

Import-Module -Name $script:BoostLabTestSourceVerificationPath -Force -ErrorAction Stop

$script:BoostLabTestCanonicalTextExtensions = @(
    '.bat'
    '.cmd'
    '.config'
    '.csv'
    '.json'
    '.jsonc'
    '.md'
    '.ps1'
    '.ps1xml'
    '.psd1'
    '.psm1'
    '.reg'
    '.txt'
    '.xaml'
    '.xml'
    '.yaml'
    '.yml'
)

$script:BoostLabTestCanonicalTextFileNames = @(
    '.gitattributes'
    '.gitignore'
    'LICENSE'
)

function Test-BoostLabTestPathUnderProjectRoot {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$LiteralPath
    )

    $resolvedPath = (Resolve-Path -LiteralPath $LiteralPath -ErrorAction Stop).Path
    if ($resolvedPath -eq $script:BoostLabTestProjectRoot) {
        return $true
    }

    return $resolvedPath.StartsWith($script:BoostLabTestProjectRoot + '\', [StringComparison]::OrdinalIgnoreCase)
}

function Test-BoostLabTestCanonicalTextPath {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$LiteralPath
    )

    if (-not (Test-BoostLabTestPathUnderProjectRoot -LiteralPath $LiteralPath)) {
        return $false
    }

    $resolvedPath = (Resolve-Path -LiteralPath $LiteralPath -ErrorAction Stop).Path
    if ($resolvedPath.StartsWith((Join-Path $script:BoostLabTestProjectRoot '.git') + '\', [StringComparison]::OrdinalIgnoreCase)) {
        return $false
    }

    $fileName = [IO.Path]::GetFileName($resolvedPath)
    if ($fileName -in $script:BoostLabTestCanonicalTextFileNames) {
        return $true
    }

    $extension = [IO.Path]::GetExtension($resolvedPath).ToLowerInvariant()
    return ($extension -in $script:BoostLabTestCanonicalTextExtensions)
}

function Get-BoostLabTestCanonicalTextHash {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$LiteralPath
    )

    $bytes = [IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $LiteralPath -ErrorAction Stop).Path)
    $canonicalBytes = ConvertTo-BoostLabCanonicalSourceTextBytes -Bytes $bytes
    return Get-BoostLabSha256Hex -Bytes $canonicalBytes
}

function Get-BoostLabTestRawFileHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$LiteralPath,

        [string]$Algorithm = 'SHA256'
    )

    return Microsoft.PowerShell.Utility\Get-FileHash -LiteralPath $LiteralPath -Algorithm $Algorithm
}

function Get-BoostLabTestGitExecutable {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $gitCommand = Get-Command -Name 'git' -ErrorAction SilentlyContinue
    if ($null -ne $gitCommand) {
        return [string]$gitCommand.Source
    }

    $githubDesktopRoot = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'GitHubDesktop'
    if (Test-Path -LiteralPath $githubDesktopRoot -PathType Container) {
        $githubDesktopGit = @(
            Get-ChildItem -LiteralPath $githubDesktopRoot -Directory -Filter 'app-*' -ErrorAction SilentlyContinue |
                Sort-Object -Property Name -Descending |
                ForEach-Object { Join-Path $_.FullName 'resources\app\git\cmd\git.exe' } |
                Where-Object { Test-Path -LiteralPath $_ -PathType Leaf }
        ) | Select-Object -First 1

        if (-not [string]::IsNullOrWhiteSpace($githubDesktopGit)) {
            return [string]$githubDesktopGit
        }
    }

    return ''
}

function Assert-BoostLabTestProtectedPathsClean {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot,

        [Parameter(Mandatory)]
        [string[]]$ProtectedPath,

        [string]$Message = 'Protected paths have working-tree modifications.'
    )

    $gitPath = Get-BoostLabTestGitExecutable
    if ([string]::IsNullOrWhiteSpace($gitPath)) {
        throw 'Git executable was not found for protected path working-tree guard.'
    }

    $normalizedPaths = @($ProtectedPath | ForEach-Object { ([string]$_).Replace('\', '/') })
    $changes = @(& $gitPath -C $ProjectRoot status --short -- $normalizedPaths)
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to inspect protected path working-tree status.'
    }
    if ($changes.Count -ne 0) {
        throw ('{0}: {1}' -f $Message, ($changes -join '; '))
    }
}

function Get-FileHash {
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Path')]
        [string[]]$Path,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'LiteralPath')]
        [Alias('PSPath')]
        [string[]]$LiteralPath,

        [Parameter(Mandatory, ParameterSetName = 'InputStream')]
        [IO.Stream]$InputStream,

        [ValidateSet('SHA1', 'SHA256', 'SHA384', 'SHA512', 'MACTripleDES', 'MD5', 'RIPEMD160')]
        [string]$Algorithm = 'SHA256'
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'InputStream') {
            return Microsoft.PowerShell.Utility\Get-FileHash -InputStream $InputStream -Algorithm $Algorithm
        }

        if ($Algorithm -ne 'SHA256') {
            if ($PSCmdlet.ParameterSetName -eq 'LiteralPath') {
                return Microsoft.PowerShell.Utility\Get-FileHash -LiteralPath $LiteralPath -Algorithm $Algorithm
            }

            return Microsoft.PowerShell.Utility\Get-FileHash -Path $Path -Algorithm $Algorithm
        }

        if ($PSCmdlet.ParameterSetName -eq 'LiteralPath') {
            foreach ($candidatePath in $LiteralPath) {
                $resolvedPath = (Resolve-Path -LiteralPath $candidatePath -ErrorAction Stop).Path
                if (Test-BoostLabTestCanonicalTextPath -LiteralPath $resolvedPath) {
                    [pscustomobject]@{
                        Algorithm = 'SHA256'
                        Hash      = Get-BoostLabTestCanonicalTextHash -LiteralPath $resolvedPath
                        Path      = $resolvedPath
                    }
                    continue
                }

                Microsoft.PowerShell.Utility\Get-FileHash -LiteralPath $resolvedPath -Algorithm $Algorithm
            }
            return
        }

        foreach ($candidatePath in $Path) {
            $resolvedPaths = @(Resolve-Path -Path $candidatePath -ErrorAction Stop)
            foreach ($resolvedPathInfo in $resolvedPaths) {
                $resolvedPath = $resolvedPathInfo.Path
                if (Test-BoostLabTestCanonicalTextPath -LiteralPath $resolvedPath) {
                    [pscustomobject]@{
                        Algorithm = 'SHA256'
                        Hash      = Get-BoostLabTestCanonicalTextHash -LiteralPath $resolvedPath
                        Path      = $resolvedPath
                    }
                    continue
                }

                Microsoft.PowerShell.Utility\Get-FileHash -LiteralPath $resolvedPath -Algorithm $Algorithm
            }
        }
    }
}
