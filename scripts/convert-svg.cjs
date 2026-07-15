#!/usr/bin/env node

'use strict';

const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

function fail(message, detail) {
  console.error(`[SVG-FEHLER] ${message}`);
  if (detail) {
    console.error(detail.trim());
  }
  process.exit(1);
}

const [inputArgument, outputArgument] = process.argv.slice(2);

if (!inputArgument || !outputArgument) {
  fail(
    'Ungueltiger Aufruf.',
    'Erwartet: node scripts/convert-svg.cjs <quelle.svg> <ziel.pdf>'
  );
}

const inputPath = path.resolve(inputArgument);
const outputPath = path.resolve(outputArgument);

if (!fs.existsSync(inputPath)) {
  fail(`SVG-Quelldatei nicht gefunden: ${inputPath}`);
}

if (path.extname(inputPath).toLowerCase() !== '.svg') {
  fail(`Quelldatei ist kein SVG: ${inputPath}`);
}

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.rmSync(outputPath, { force: true });

const conversion = spawnSync(
  process.env.IMAGEMAGICK_COMMAND || 'magick',
  ['-background', 'none', '-density', '144', inputPath, outputPath],
  { encoding: 'utf8', shell: false }
);

if (conversion.error) {
  fail(
    'ImageMagick konnte nicht gestartet werden. Installiere ImageMagick und stelle sicher, dass "magick" im PATH liegt.',
    conversion.error.message
  );
}

if (conversion.status !== 0) {
  fs.rmSync(outputPath, { force: true });
  fail(
    `SVG-Konvertierung fehlgeschlagen (Exit-Code ${conversion.status}).`,
    conversion.stderr || conversion.stdout
  );
}

if (!fs.existsSync(outputPath) || fs.statSync(outputPath).size === 0) {
  fail(`ImageMagick meldete Erfolg, hat aber keine gueltige PDF erzeugt: ${outputPath}`);
}

console.log(`[SVG-OK] ${inputArgument} -> ${outputArgument}`);
