[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Level,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$Event,

    [Parameter(Mandatory = $true, Position = 2)]
    [string]$Action,

    [Parameter(Position = 3, ValueFromRemainingArguments = $true)]
    [string[]]$ExtraPairs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function New-UString {
    param([int[]]$CodePoints)
    $chars = New-Object char[] $CodePoints.Count
    for ($i = 0; $i -lt $CodePoints.Count; $i++) {
        $chars[$i] = [char]$CodePoints[$i]
    }
    return -join $chars
}

$K_LEVEL = New-UString @(0x7B49, 0x7EA7)
$K_TIME = New-UString @(0x65F6, 0x95F4)
$K_EVENT = New-UString @(0x4E8B, 0x4EF6)
$K_ACTION = New-UString @(0x884C, 0x4E3A)

$V_LOW = New-UString @(0x4F4E)
$V_MEDIUM = New-UString @(0x4E2D)
$V_HIGH = New-UString @(0x9AD8)

$E_MOVE = New-UString @(0x79FB, 0x52A8)
$E_COPY = New-UString @(0x590D, 0x5236)
$E_MODIFY = New-UString @(0x4FEE, 0x6539)
$E_OVERWRITE = New-UString @(0x8986, 0x76D6)
$E_DL_UPDATE = New-UString @(0x4E0B, 0x8F7D, 0x2F, 0x66F4, 0x65B0)
$E_COMMAND = New-UString @(0x6307, 0x4EE4)
$E_DELETE = New-UString @(0x5220, 0x9664)

$REDACTED = "<" + (New-UString @(0x5DF2, 0x8131, 0x654F)) + ">"

$CN_HINTS = @(
    (New-UString @(0x5BC6, 0x7801)),
    (New-UString @(0x53E3, 0x4EE4)),
    (New-UString @(0x5BC6, 0x94A5)),
    (New-UString @(0x79C1, 0x94A5)),
    (New-UString @(0x51ED, 0x8BC1)),
    (New-UString @(0x8BBF, 0x95EE, 0x5BC6, 0x94A5)),
    (New-UString @(0x53D8, 0x91CF, 0x503C))
)

function Convert-ToSingleLine {
    param([string]$Value)
    if ($null -eq $Value) {
        return ""
    }

    $normalized = $Value -replace "`r`n", "`n"
    $normalized = $normalized -replace "`r", "`n"
    return ($normalized -replace "`n", "\\n")
}

function Mask-SensitiveFragments {
    param([string]$Value)
    if ($null -eq $Value) {
        return ""
    }

    $masked = $Value
    $masked = [regex]::Replace($masked, '(?i)(--?(?:token|password|passwd|pwd|secret|api[-_]?key)\s+)([^\s"''=]+)', '$1<redacted>')
    $masked = [regex]::Replace($masked, '(?i)(--?(?:token|password|passwd|pwd|secret|api[-_]?key)=)([^\s"''=]+)', '$1<redacted>')
    $masked = [regex]::Replace($masked, '(?i)(authorization\s*:\s*bearer\s+)([^\s"''=]+)', '$1<redacted>')
    $masked = [regex]::Replace($masked, '(?i)(token|password|passwd|pwd|secret|api[-_]?key)\s*=\s*([^\s"'';,.]+)', '$1=<redacted>')
    $masked = [regex]::Replace($masked, '(?i)\b(token|password|passwd|pwd|secret|api[-_]?key)\b(\s+)([^\s"'';,.]+)', '$1$2<redacted>')
    return $masked.Replace('<redacted>', $REDACTED)
}

function Is-SensitiveKey {
    param([string]$Key)
    if ([string]::IsNullOrWhiteSpace($Key)) {
        return $false
    }

    if ($Key -match '(?i)(password|passwd|pwd|token|secret|api[-_]?key|authorization|cookie|session|private[-_]?key)') {
        return $true
    }

    foreach ($hint in $CN_HINTS) {
        if ($Key.Contains($hint)) {
            return $true
        }
    }

    return $false
}

function Convert-ToQuoted {
    param([string]$Value)
    $singleLine = Convert-ToSingleLine -Value $Value
    $escaped = $singleLine -replace '"', '\\"'
    return '"' + $escaped + '"'
}

function Parse-ExtraPair {
    param([string]$Pair)
    if ($Pair -notmatch '^(?<k>[^=]+)=(?<v>.*)$') {
        throw "Extra field must use key=value format: $Pair"
    }

    $key = $Matches['k'].Trim()
    $value = $Matches['v']

    if ([string]::IsNullOrWhiteSpace($key)) {
        throw "Extra field key cannot be empty."
    }

    return @{ Key = $key; Value = $value }
}

$allowedLevels = @($V_LOW, $V_MEDIUM, $V_HIGH)
if ($allowedLevels -notcontains $Level) {
    $joined = $allowedLevels -join ", "
    throw "Invalid level: $Level. Allowed: $joined"
}

$allowedEvents = @($E_MOVE, $E_COPY, $E_MODIFY, $E_OVERWRITE, $E_DL_UPDATE, $E_COMMAND, $E_DELETE)
if ($allowedEvents -notcontains $Event) {
    $joined = $allowedEvents -join ", "
    throw "Invalid event: $Event. Allowed: $joined"
}

if ([string]::IsNullOrWhiteSpace($Action)) {
    throw "Action cannot be empty."
}

$reservedKeys = @($K_LEVEL, $K_TIME, $K_EVENT, $K_ACTION)
$seenKeys = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
$extraSegments = New-Object System.Collections.Generic.List[string]

if ($ExtraPairs) {
    foreach ($pair in $ExtraPairs) {
        $parsed = Parse-ExtraPair -Pair $pair
        $key = $parsed.Key
        $value = $parsed.Value

        if ($reservedKeys -contains $key) {
            throw "Extra field uses reserved key: $key"
        }

        if (-not $seenKeys.Add($key)) {
            throw "Duplicate extra field key: $key"
        }

        if (Is-SensitiveKey -Key $key) {
            $safeValue = $REDACTED
        } else {
            $safeValue = Mask-SensitiveFragments -Value $value
        }

        $extraSegments.Add($key + "=" + (Convert-ToQuoted -Value $safeValue))
    }
}

$safeAction = Mask-SensitiveFragments -Value $Action
$now = Get-Date
$datePart = $now.ToString("yyyy-MM-dd")
$timePart = $now.ToString("yyyy-MM-dd HH:mm:ss")

$workDir = (Get-Location).Path
$logDir = Join-Path -Path $workDir -ChildPath "AIlog"
$logFile = Join-Path -Path $logDir -ChildPath ("$datePart.log")

if (-not (Test-Path -Path $logDir -PathType Container)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}

$segments = New-Object System.Collections.Generic.List[string]
$segments.Add($K_LEVEL + "=" + (Convert-ToQuoted -Value $Level))
$segments.Add($K_TIME + "=" + (Convert-ToQuoted -Value $timePart))
$segments.Add($K_EVENT + "=" + (Convert-ToQuoted -Value $Event))
$segments.Add($K_ACTION + "=" + (Convert-ToQuoted -Value $safeAction))

foreach ($segment in $extraSegments) {
    $segments.Add($segment)
}

$line = [string]::Join(" ", $segments)

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::AppendAllText($logFile, $line + [Environment]::NewLine, $utf8NoBom)
