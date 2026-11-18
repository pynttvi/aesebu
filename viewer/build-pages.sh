#!/bin/sh
set -eu

cd "$(dirname "$0")/.."
destination="${1:-_site}"
mkdir -p "$destination/docs"
touch "$destination/.nojekyll"

cp viewer/index.html viewer/workshop.css viewer/workshop.mjs "$destination/"
cp -R viewer/lib viewer/playground "$destination/"
cp viewer/marked.LICENSE "$destination/"
cp 0[0-5]_*.md 0[0-5]_*.scad xu316_cs8406_usb_aesebu_plan.md "$destination/docs/"
