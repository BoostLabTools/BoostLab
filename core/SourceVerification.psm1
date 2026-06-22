Set-StrictMode -Version Latest

function Get-BoostLabSha256Hex {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [byte[]]$Bytes
    )

    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha256.ComputeHash($Bytes))).Replace('-', '')
    }
    finally {
        $sha256.Dispose()
    }
}

function ConvertTo-BoostLabCanonicalSourceTextBytes {
    [CmdletBinding()]
    [OutputType([byte[]])]
    param(
        [Parameter(Mandatory)]
        [byte[]]$Bytes
    )

    $offset = 0
    if (
        $Bytes.Length -ge 3 -and
        $Bytes[0] -eq 0xEF -and
        $Bytes[1] -eq 0xBB -and
        $Bytes[2] -eq 0xBF
    ) {
        $offset = 3
    }

    $contentLength = $Bytes.Length - $offset
    $contentBytes = [byte[]]::new($contentLength)
    if ($contentLength -gt 0) {
        [Array]::Copy($Bytes, $offset, $contentBytes, 0, $contentLength)
    }

    $strictUtf8 = [Text.UTF8Encoding]::new($false, $true)
    $text = $strictUtf8.GetString($contentBytes)
    $text = $text -replace "`r`n", "`n"
    $text = $text -replace "`r", "`n"

    return ,[Text.UTF8Encoding]::new($false).GetBytes($text)
}

function Test-BoostLabSourceChecksum {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$LiteralPath,

        [Parameter(Mandatory)]
        [string]$ExpectedSha256,

        [string]$ExpectedCanonicalSha256 = '',

        [bool]$TextNormalizationEnabled = $true
    )

    $exists = Test-Path -LiteralPath $LiteralPath -PathType Leaf
    $rawSha256 = ''
    $canonicalSha256 = ''
    $errors = [System.Collections.Generic.List[string]]::new()

    if ($exists) {
        try {
            $bytes = [IO.File]::ReadAllBytes($LiteralPath)
            $rawSha256 = Get-BoostLabSha256Hex -Bytes $bytes

            $extension = [IO.Path]::GetExtension($LiteralPath).ToLowerInvariant()
            $canUseCanonicalText = (
                $TextNormalizationEnabled -and
                -not [string]::IsNullOrWhiteSpace($ExpectedCanonicalSha256) -and
                $extension -in @('.ps1', '.psm1', '.psd1')
            )

            if ($canUseCanonicalText) {
                $canonicalBytes = ConvertTo-BoostLabCanonicalSourceTextBytes -Bytes $bytes
                $canonicalSha256 = Get-BoostLabSha256Hex -Bytes $canonicalBytes
            }
        }
        catch {
            $errors.Add($_.Exception.Message)
        }
    }

    $rawStatus = if (-not $exists) {
        'Missing'
    }
    elseif ($rawSha256 -eq $ExpectedSha256) {
        'Passed'
    }
    else {
        'Failed'
    }

    $canonicalStatus = if (-not $exists) {
        'Missing'
    }
    elseif ([string]::IsNullOrWhiteSpace($ExpectedCanonicalSha256)) {
        'NotConfigured'
    }
    elseif ([string]::IsNullOrWhiteSpace($canonicalSha256)) {
        'Unavailable'
    }
    elseif ($canonicalSha256 -eq $ExpectedCanonicalSha256) {
        'Passed'
    }
    else {
        'Failed'
    }

    $passed = ($rawStatus -eq 'Passed' -or $canonicalStatus -eq 'Passed')
    $status = if (-not $exists) {
        'Missing'
    }
    elseif ($passed) {
        'Passed'
    }
    else {
        'Failed'
    }

    $mode = if ($rawStatus -eq 'Passed') {
        'ExactRawSha256'
    }
    elseif ($canonicalStatus -eq 'Passed') {
        'CanonicalTextSha256'
    }
    elseif (-not $exists) {
        'Missing'
    }
    else {
        'Failed'
    }

    [pscustomobject]@{
        LiteralPath              = $LiteralPath
        Exists                   = $exists
        ExpectedSha256           = $ExpectedSha256
        DetectedSha256           = $rawSha256
        ExpectedCanonicalSha256  = $ExpectedCanonicalSha256
        DetectedCanonicalSha256  = $canonicalSha256
        RawChecksumStatus        = $rawStatus
        CanonicalChecksumStatus  = $canonicalStatus
        ChecksumStatus           = $status
        VerificationMode         = $mode
        TextNormalizationEnabled = $TextNormalizationEnabled
        Errors                   = $errors.ToArray()
    }
}

Export-ModuleMember -Function @(
    'Get-BoostLabSha256Hex'
    'ConvertTo-BoostLabCanonicalSourceTextBytes'
    'Test-BoostLabSourceChecksum'
)
