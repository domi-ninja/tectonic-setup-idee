[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Source
)

$ErrorActionPreference = 'Stop'
try {
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

    $baseName = $sourceFile.BaseName
    $expectedPdf = Join-Path $outputDirectory "$baseName.pdf"
    foreach ($extension in '.pdf', '.aux', '.log', '.synctex.gz') {
        $artifact = Join-Path $outputDirectory "$baseName$extension"
        if (Test-Path -LiteralPath $artifact -PathType Leaf) {
            Remove-Item -LiteralPath $artifact -Force
        }
    }

    $svgReferences = [System.Collections.Generic.List[string]]::new()
    foreach ($texFile in @($sourceFile)) {
        $content = Get-Content -LiteralPath $texFile.FullName -Raw
        foreach ($match in [regex]::Matches($content, '\\reportsvg(?:\[[^\]]*\])?\{([^}]+\.svg)\}')) {
            $svgReferences.Add($match.Groups[1].Value)
        }
    }
    $usesSvgConversion = $svgReferences.Count -gt 0
    if ($usesSvgConversion -and -not (Get-Command node -ErrorAction SilentlyContinue)) {
        throw 'Node.js wurde nicht gefunden. Die automatische SVG-Konvertierung benoetigt "node" im PATH.'
    }
    if ($usesSvgConversion -and -not (Get-Command magick -ErrorAction SilentlyContinue)) {
        throw 'ImageMagick wurde nicht gefunden. Die automatische SVG-Konvertierung benoetigt "magick" im PATH.'
    }

    $svgBuildArtifacts = [System.Collections.Generic.List[string]]::new()
    foreach ($reference in $svgReferences | Select-Object -Unique) {
        $svgPath = [System.IO.Path]::GetFullPath((Join-Path $sourceRoot $reference))
        if (-not (Test-Path -LiteralPath $svgPath -PathType Leaf)) {
            throw "Referenziertes SVG wurde nicht gefunden: $svgPath"
        }
        $svgBuildArtifacts.Add([System.IO.Path]::ChangeExtension($svgPath, '.generated.pdf'))
    }

    $tectonicCommand = Get-Command tectonic -ErrorAction SilentlyContinue
    if ($tectonicCommand) {
        $tectonic = $tectonicCommand.Source
    } else {
        $tectonic = Join-Path $env:LOCALAPPDATA 'Programs\Tectonic\tectonic.exe'
    }

    if (-not (Test-Path -LiteralPath $tectonic -PathType Leaf)) {
        throw 'Tectonic wurde nicht gefunden. Starte VS Code nach der Installation neu.'
    }

    foreach ($artifact in $svgBuildArtifacts) {
        if (Test-Path -LiteralPath $artifact -PathType Leaf) {
            Remove-Item -LiteralPath $artifact -Force
        }
    }

    $oldRepoRoot = $env:COOL_DOC_FLOW_ROOT
    $oldSourceRoot = $env:COOL_DOC_FLOW_SOURCE_ROOT
    $env:COOL_DOC_FLOW_ROOT = $repoRoot
    $env:COOL_DOC_FLOW_SOURCE_ROOT = $sourceRoot
    Push-Location $customerRoot
    try {
        & $tectonic -X compile `
            --synctex `
            --keep-logs `
            --outdir $outputDirectory `
            -Z "search-path=$sourceRoot" `
            -Z "search-path=$templates" `
            -Z "shell-escape-cwd=$sourceRoot" `
            $sourceFile.FullName

        if ($LASTEXITCODE -ne 0) {
            throw "Tectonic meldete Exit-Code $LASTEXITCODE fuer die Vorschau von '$Source'."
        }
    } finally {
        Pop-Location
        $env:COOL_DOC_FLOW_ROOT = $oldRepoRoot
        $env:COOL_DOC_FLOW_SOURCE_ROOT = $oldSourceRoot
    }

    if (-not (Test-Path -LiteralPath $expectedPdf -PathType Leaf)) {
        throw "Vorschau-Build meldete Erfolg, aber die erwartete PDF fehlt: $expectedPdf"
    }

    $pdfFile = Get-Item -LiteralPath $expectedPdf
    if ($pdfFile.Length -eq 0) {
        throw "Vorschau-Build erzeugte eine leere PDF-Datei: $expectedPdf"
    }

    foreach ($artifact in $svgBuildArtifacts) {
        if (-not (Test-Path -LiteralPath $artifact -PathType Leaf)) {
            throw "SVG-Konvertierung meldete keinen harten Abbruch, aber das Build-Artefakt fehlt: $artifact"
        }
        if ((Get-Item -LiteralPath $artifact).Length -eq 0) {
            throw "SVG-Konvertierung erzeugte eine leere PDF-Datei: $artifact"
        }
    }

    Write-Host "[VORSCHAU-OK] PDF erstellt: $($pdfFile.FullName)" -ForegroundColor Green
} catch {
    Write-Host ''
    Write-Host "[VORSCHAU-FEHLER] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Die alte Vorschau-PDF wurde entfernt und wird nicht als erfolgreicher Build angezeigt.' -ForegroundColor Yellow
    exit 1
}
