# Cool Doc Flow

Ein kleiner, lokaler Report-Workflow mit handgeschriebenem LaTeX, gemeinsamen
Templates, PDF-Vorschau und mehreren Reports pro Kunde.

## Installiert

- Tectonic als LaTeX-Engine und reproduzierbares Build-System
- VS Code mit der Erweiterung LaTeX Workshop
- Node.js und ImageMagick (`magick`) für die automatische SVG-Konvertierung

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
  convert-svg.cjs            automatische SVG-zu-PDF-Konvertierung aus LaTeX
```

## Einen Kunden anlegen

1. `customers/example-ag` kopieren und den Ordner umbenennen.
2. In `Tectonic.toml` den Kundennamen und die gewünschten `[[output]]`-Blöcke
   anpassen. Jeder Output, der SVGs verwendet, muss diese beiden Zeilen enthalten:

```toml
shell_escape = true
shell_escape_cwd = ".."
```

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

SVG-Dateien werden nicht manuell vorkonvertiert. Das SVG bleibt unter
`src/assets`; der Report löst die Konvertierung beim LaTeX-Lauf selbst aus:

```latex
\reportsvg[width=\linewidth,keepaspectratio]{assets/architektur.svg}
```

`\reportsvg` ruft `scripts/convert-svg.cjs` auf. Der Konverter entfernt einen
alten Zwischenstand, prüft Quelle, ImageMagick-Exit-Code und Zieldatei und
bricht bei Problemen mit einer Meldung `[SVG-FEHLER]` ab. Die erzeugte
`*.generated.pdf` ist nur ein Build-Artefakt und wird nicht eingecheckt.

## Verbindliche Build- und Fehlerrückmeldung

Nach dem Erstellen oder Ändern einer Report-Root-Datei unter `src/reports`
muss der passende Build ausgeführt werden:

```powershell
.\scripts\build.ps1 -Customer example-ag -Target overview
```

Ein Build gilt nur dann als erfolgreich, wenn die erwartete, nicht leere PDF
existiert und `[BUILD-OK] PDF erstellt: ...` ausgegeben wird. Der Build entfernt
vorherige Ziel-PDFs vor dem Lauf, damit eine alte Datei keinen Erfolg vortäuscht.
Fehler werden als `[BUILD-FEHLER]`, Konvertierungsfehler zusätzlich als
`[SVG-FEHLER]` ausgegeben und der Prozess endet mit Exit-Code 1.

Beim Speichern in VS Code gilt dasselbe für die Vorschau: Erfolg wird mit
`[VORSCHAU-OK]` gemeldet; bei `[VORSCHAU-FEHLER]` wurde keine gültige neue PDF
gebaut. Das Terminal wird für Build-Aufgaben automatisch eingeblendet.

## Templates ändern

Das gemeinsame Layout liegt in `templates/coolreport.cls`. Jeder Kunde bindet
es über `extra_paths = ["../../templates"]` in seiner `Tectonic.toml` ein.
Dadurch bleibt das Branding an einer Stelle, während Kundeninhalte getrennt
bleiben.
