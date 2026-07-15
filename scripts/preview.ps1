[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Source
)

$ErrorActionPreference = 'Stop'
$sourceFile = Get-Item -LiteralPath $Source
if ($sourceFile.Extension -ne '.tex') {
    throw "Die Vorschau erwartet eine .tex-Datei: $Source"
}

$current = $sourceFile.Directory
$customerRoot = $null
while ($current) {
    if (Test-Path -LiteralPath (Join-Path $current.FullName 'Tectonic.toml') -PathType Leaf) {
        $customerRoot = $current.FullName
        break
    }
    $current = $current.Parent
}

if (-not $customerRoot) {
    throw "Oberhalb von $Source wurde kein Tectonic.toml gefunden."
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $customerRoot)
$templates = Join-Path $repoRoot 'templates'
$sourceRoot = Join-Path $customerRoot 'src'
$outputDirectory = $sourceFile.Directory.FullName

$tectonicCommand = Get-Command tectonic -ErrorAction SilentlyContinue
if ($tectonicCommand) {
    $tectonic = $tectonicCommand.Source
} else {
    $tectonic = Join-Path $env:LOCALAPPDATA 'Programs\Tectonic\tectonic.exe'
}

if (-not (Test-Path -LiteralPath $tectonic -PathType Leaf)) {
    throw 'Tectonic wurde nicht gefunden. Starte VS Code nach der Installation neu.'
}

Push-Location $customerRoot
try {
    & $tectonic -X compile `
        --synctex `
        --keep-logs `
        --outdir $outputDirectory `
        -Z "search-path=$sourceRoot" `
        -Z "search-path=$templates" `
        $sourceFile.FullName

    if ($LASTEXITCODE -ne 0) {
        throw "Vorschau-Build fehlgeschlagen: $Source"
    }
} finally {
    Pop-Location
}

