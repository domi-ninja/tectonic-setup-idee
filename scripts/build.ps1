[CmdletBinding(DefaultParameterSetName = 'One')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'One')]
    [string]$Customer,

    [Parameter(Mandatory = $true, ParameterSetName = 'All')]
    [switch]$All,

    [Parameter(ParameterSetName = 'One')]
    [string]$Target,

    [Parameter(ParameterSetName = 'One')]
    [switch]$Watch
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$customersRoot = Join-Path $repoRoot 'customers'

function Get-TectonicCommand {
    $command = Get-Command tectonic -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $fallback = Join-Path $env:LOCALAPPDATA 'Programs\Tectonic\tectonic.exe'
    if (Test-Path -LiteralPath $fallback -PathType Leaf) {
        return $fallback
    }

    throw 'Tectonic wurde nicht gefunden. Starte das Terminal nach der Installation neu.'
}

function Invoke-CustomerBuild {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CustomerPath,

        [string]$BuildTarget,

        [switch]$Continuous
    )

    $manifest = Join-Path $CustomerPath 'Tectonic.toml'
    if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
        throw "Kein Tectonic.toml gefunden: $CustomerPath"
    }

    $tectonic = Get-TectonicCommand
    Push-Location $CustomerPath
    try {
        if ($Continuous) {
            if ($BuildTarget) {
                & $tectonic -X watch '-x=build' '-x=--target' "-x=$BuildTarget"
            } else {
                & $tectonic -X watch
            }
        } elseif ($BuildTarget) {
            & $tectonic -X build --target $BuildTarget
        } else {
            & $tectonic -X build
        }

        if ($LASTEXITCODE -ne 0) {
            throw "Tectonic-Build fehlgeschlagen: $CustomerPath"
        }
    } finally {
        Pop-Location
    }
}

if ($All) {
    $customerManifests = Get-ChildItem -LiteralPath $customersRoot -Filter 'Tectonic.toml' -File -Recurse
    if (-not $customerManifests) {
        throw "Keine Kundenprojekte unter $customersRoot gefunden."
    }

    foreach ($manifest in $customerManifests) {
        Write-Host "Baue Kunde: $($manifest.Directory.Name)" -ForegroundColor Cyan
        Invoke-CustomerBuild -CustomerPath $manifest.Directory.FullName
    }
    exit 0
}

$customerPath = Join-Path $customersRoot $Customer
if (-not (Test-Path -LiteralPath $customerPath -PathType Container)) {
    throw "Kunde nicht gefunden: $Customer"
}

Invoke-CustomerBuild -CustomerPath $customerPath -BuildTarget $Target -Continuous:$Watch
