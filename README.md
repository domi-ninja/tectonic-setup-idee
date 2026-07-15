# Cool Doc Flow

Ein kleiner, lokaler Report-Workflow mit handgeschriebenem LaTeX, gemeinsamen
Templates, PDF-Vorschau und mehreren Reports pro Kunde.

## Installiert

- Tectonic als LaTeX-Engine und reproduzierbares Build-System
- VS Code mit der Erweiterung LaTeX Workshop

Tectonic liegt unter `%LOCALAPPDATA%\Programs\Tectonic` und wurde dem
Benutzer-`PATH` hinzugefügt. Nach einem bereits geöffneten Terminal ist unter
Umständen ein Neustart des Terminals nötig.

## Schnellstart

Alle Reports des Beispielkunden bauen:

```powershell
.\scripts\build.ps1 -Customer example-ag
```

Nur einen Report bauen:

```powershell
.\scripts\build.ps1 -Customer example-ag -Target overview
```

Alle Kunden bauen:

```powershell
.\scripts\build.ps1 -All
```

Kontinuierlich neu bauen:

```powershell
.\scripts\build.ps1 -Customer example-ag -Watch
```

Die fertigen PDFs landen hier:

```text
customers/example-ag/build/overview/overview.pdf
customers/example-ag/build/audit/audit.pdf
```

## Vorschau in VS Code

1. Den Repository-Ordner neu in VS Code öffnen, damit der aktualisierte `PATH`
   übernommen wird.
2. Eine Root-Datei wie
   `customers/example-ag/src/reports/overview.tex` öffnen.
3. Speichern. LaTeX Workshop baut automatisch eine Vorschau-PDF direkt neben
   der `.tex`-Datei.
4. `Ctrl+Alt+V` öffnet die PDF rechts im integrierten Viewer.
5. `Ctrl+Alt+J` springt von der Quelle zur PDF; `Ctrl+Klick` in der PDF springt
   zurück zur Quelle.

Alternativ steht in VS Code `Terminal > Run Task > Docs: Demo-Kunde bauen` zur
Verfügung.

## Struktur

```text
templates/
  coolreport.cls             gemeinsames Layout und Bild-Makros
customers/
  example-ag/
    Tectonic.toml            Reports/Outputs dieses Kunden
    src/
      customer.tex           gemeinsame Kundendaten
      assets/                Bilder, Diagramme, externe PDFs
      sections/              wiederverwendete Textbausteine
      reports/               eigenständige Report-Root-Dateien
scripts/
  build.ps1                  Produktions- und Watch-Build
  preview.ps1                Build des aktiven Reports für VS Code
```

## Einen Kunden anlegen

1. `customers/example-ag` kopieren und den Ordner umbenennen.
2. In `Tectonic.toml` den Kundennamen und die gewünschten `[[output]]`-Blöcke
   anpassen.
3. `src/customer.tex` und die Reports bearbeiten.
4. Bilder nach `src/assets` legen und beispielsweise so referenzieren:

```latex
\reportfigure{assets/architektur.png}{Architekturübersicht}
```

PNG, JPEG und PDF funktionieren direkt. Das Makro beschränkt Bilder automatisch
auf Seitenbreite und Seitenhöhe, ohne das Seitenverhältnis zu verzerren.
Mehrseitige PDFs können angehängt werden:

```latex
\reportattachment{assets/anhang.pdf}
```

SVG-Dateien sollten vor dem Build nach PDF konvertiert werden. Das vermeidet
Shell-Escape und externe Programme während des LaTeX-Laufs.

## Templates ändern

Das gemeinsame Layout liegt in `templates/coolreport.cls`. Jeder Kunde bindet
es über `extra_paths = ["../../templates"]` in seiner `Tectonic.toml` ein.
Dadurch bleibt das Branding an einer Stelle, während Kundeninhalte getrennt
bleiben.

