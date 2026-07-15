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

function Get-ManifestOutputNames {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Manifest
    )

    $content = Get-Content -LiteralPath $Manifest -Raw
    $matches = [regex]::Matches($content, '(?ms)^\[\[output\]\]\s*.*?^name\s*=\s*"([^"]+)"')
    return @($matches | ForEach-Object { $_.Groups[1].Value })
}

function Get-SvgBuildArtifacts {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CustomerPath,

        [string]$BuildTarget
    )

    $sourceRoot = Join-Path $CustomerPath 'src'
    if ($BuildTarget) {
        $targetSource = Join-Path $sourceRoot "reports\$BuildTarget.tex"
        if (-not (Test-Path -LiteralPath $targetSource -PathType Leaf)) {
            throw "Zum Build-Ziel '$BuildTarget' fehlt die erwartete Report-Datei: $targetSource"
        }
        $texFiles = @(Get-Item -LiteralPath $targetSource)
    } else {
        $texFiles = Get-ChildItem -LiteralPath $sourceRoot -Filter '*.tex' -File -Recurse
    }
    $svgReferences = [System.Collections.Generic.List[string]]::new()
    foreach ($texFile in $texFiles) {
        $content = Get-Content -LiteralPath $texFile.FullName -Raw
        foreach ($match in [regex]::Matches($content, '\\reportsvg(?:\[[^\]]*\])?\{([^}]+\.svg)\}')) {
            $svgReferences.Add($match.Groups[1].Value)
        }
    }

    if ($svgReferences.Count -eq 0) {
        return @()
    }

    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        throw 'Node.js wurde nicht gefunden. Die automatische SVG-Konvertierung benoetigt "node" im PATH.'
    }

    if (-not (Get-Command magick -ErrorAction SilentlyContinue)) {
        throw 'ImageMagick wurde nicht gefunden. Die automatische SVG-Konvertierung benoetigt "magick" im PATH.'
    }

    $generatedPdfs = [System.Collections.Generic.List[string]]::new()
    foreach ($reference in $svgReferences | Select-Object -Unique) {
        $svgPath = [System.IO.Path]::GetFullPath((Join-Path $sourceRoot $reference))
        if (-not (Test-Path -LiteralPath $svgPath -PathType Leaf)) {
            throw "Referenziertes SVG wurde nicht gefunden: $svgPath"
        }

        $generatedPdfs.Add([System.IO.Path]::ChangeExtension($svgPath, '.generated.pdf'))
    }

    return @($generatedPdfs)
}

function Remove-PreviousPdf {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PdfPath,

        [Parameter(Mandatory = $true)]
        [string]$CustomerPath
    )

    $resolvedCustomer = [System.IO.Path]::GetFullPath($CustomerPath).TrimEnd('\') + '\'
    $resolvedPdf = [System.IO.Path]::GetFullPath($PdfPath)
    if (-not $resolvedPdf.StartsWith($resolvedCustomer, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Unsicherer PDF-Ausgabepfad ausserhalb des Kundenordners: $resolvedPdf"
    }

    if (Test-Path -LiteralPath $resolvedPdf -PathType Leaf) {
        Remove-Item -LiteralPath $resolvedPdf -Force
    }
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

    $outputNames = Get-ManifestOutputNames -Manifest $manifest
    if (-not $outputNames) {
        throw "Keine [[output]]-Bloecke in $manifest gefunden."
    }

    if ($BuildTarget -and $BuildTarget -notin $outputNames) {
        throw "Unbekanntes Build-Ziel '$BuildTarget'. Verfuegbar: $($outputNames -join ', ')"
    }

    $requestedOutputs = if ($BuildTarget) { @($BuildTarget) } else { @($outputNames) }
    $expectedPdfs = @($requestedOutputs | ForEach-Object {
        Join-Path $CustomerPath "build\$_\$_.pdf"
    })

    if (-not $Continuous) {
        foreach ($pdf in $expectedPdfs) {
            Remove-PreviousPdf -PdfPath $pdf -CustomerPath $CustomerPath
        }
    }

    $svgBuildArtifacts = @(Get-SvgBuildArtifacts -CustomerPath $CustomerPath -BuildTarget $BuildTarget)

    if (-not $Continuous) {
        foreach ($pdf in $svgBuildArtifacts) {
            Remove-PreviousPdf -PdfPath $pdf -CustomerPath $CustomerPath
        }
    }

    $tectonic = Get-TectonicCommand
    $sourceRoot = Join-Path $CustomerPath 'src'
    $oldRepoRoot = $env:COOL_DOC_FLOW_ROOT
    $oldSourceRoot = $env:COOL_DOC_FLOW_SOURCE_ROOT
    $env:COOL_DOC_FLOW_ROOT = $repoRoot
    $env:COOL_DOC_FLOW_SOURCE_ROOT = $sourceRoot
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
            throw "Tectonic meldete Exit-Code $LASTEXITCODE fuer Kunde '$([IO.Path]::GetFileName($CustomerPath))'."
        }
    } finally {
        Pop-Location
        $env:COOL_DOC_FLOW_ROOT = $oldRepoRoot
        $env:COOL_DOC_FLOW_SOURCE_ROOT = $oldSourceRoot
    }

    if (-not $Continuous) {
        foreach ($pdf in $expectedPdfs) {
            if (-not (Test-Path -LiteralPath $pdf -PathType Leaf)) {
                throw "Build meldete Erfolg, aber die erwartete PDF fehlt: $pdf"
            }

            $pdfFile = Get-Item -LiteralPath $pdf
            if ($pdfFile.Length -eq 0) {
                throw "Build erzeugte eine leere PDF-Datei: $pdf"
            }

        }

        foreach ($pdf in $svgBuildArtifacts) {
            if (-not (Test-Path -LiteralPath $pdf -PathType Leaf)) {
                throw "SVG-Konvertierung meldete keinen harten Abbruch, aber das Build-Artefakt fehlt: $pdf"
            }
            if ((Get-Item -LiteralPath $pdf).Length -eq 0) {
                throw "SVG-Konvertierung erzeugte eine leere PDF-Datei: $pdf"
            }
        }

        foreach ($pdf in $expectedPdfs) {
            $pdfFile = Get-Item -LiteralPath $pdf
            Write-Host "[BUILD-OK] PDF erstellt: $($pdfFile.FullName)" -ForegroundColor Green
        }
    }
}

try {
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
} catch {
    Write-Host ''
    Write-Host "[BUILD-FEHLER] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Der Build wurde abgebrochen; eine alte oder fehlende PDF wird nicht als Erfolg behandelt.' -ForegroundColor Yellow
    exit 1
}
