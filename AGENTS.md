# Arbeitsregeln für Reports

Diese Regeln gelten für alle Änderungen in diesem Repository.

## PDF-Build ist verpflichtend

- Nach dem Erstellen oder Ändern einer Report-Root-Datei unter
  `customers/*/src/reports/*.tex` muss der konkrete Report mit
  `scripts/build.ps1 -Customer <kunde> -Target <report>` gebaut werden.
- Arbeit an einem Report ist erst abgeschlossen, wenn das Skript
  `[BUILD-OK] PDF erstellt: ...` ausgibt und mit Exit-Code 0 endet.
- Eine vorhandene alte PDF ist kein Build-Nachweis. Das Build-Skript entfernt
  die bisherige Ziel-PDF und prüft danach Existenz und Dateigröße der neuen.
- Bei einem Fehler muss die konkrete Meldung `[BUILD-FEHLER]`,
  `[VORSCHAU-FEHLER]` oder `[SVG-FEHLER]` behoben und der Build erneut ausgeführt
  werden. Ein fehlgeschlagener Build darf nicht als erledigt gemeldet werden.

## SVGs werden automatisch aus LaTeX gebaut

- SVG-Dateien bleiben als Quelle unter `src/assets`. Keine manuell erzeugte
  PDF-Kopie eines SVGs einchecken.
- SVGs in Reports ausschließlich mit `\reportsvg[...]{assets/datei.svg}`
  einbinden. Dieser Aufruf im `.tex` startet `scripts/convert-svg.cjs` während
  des LaTeX-Builds.
- Jeder `[[output]]`-Block eines Reports mit SVG muss in `Tectonic.toml`
  `shell_escape = true` und `shell_escape_cwd = ".."` enthalten.
- `node` und `magick` sind Build-Abhängigkeiten. Die Build- und Preview-Skripte
  müssen bei einer fehlenden Abhängigkeit mit einer handlungsorientierten
  Fehlermeldung und Exit-Code 1 abbrechen.

## Neue Kunden

- Als Ausgangspunkt `customers/example-ag` kopieren. Diese Vorlage muss stets
  vollständig baubar bleiben.
- Kundenname, Output-Namen, `customer.tex` und Report-Inhalte anpassen; die
  Shell-Escape-Konfiguration für automatische SVGs beibehalten.
- Zum Abschluss erst den neuen Kundenreport gezielt und danach alle Kunden mit
  `scripts/build.ps1 -All` bauen.
