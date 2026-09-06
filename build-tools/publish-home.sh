#!/usr/bin/bash
# Rebuild the self-contained home Artifact (dist/home.html) from index.html.
# Republish the result to the SAME artifact URL:
#   https://claude.ai/code/artifact/f1783a12-3f47-4b8b-8845-7b6af8f8ed43
#
# This is the CURRENT home build. The old publish.sh is stale (wrong company
# selectors, data-soon placeholders) — do not use it for the home page.
set -e
cd "$(dirname "$0")"
mkdir -p dist

# 1. inline css/js + base64 every referenced local image (incl. the Jeddah hero photo)
perl build-artifact.pl index.html dist/home.html "" "Sky Global Holding" "سكاي جلوبال القابضة"

# 2. point the 5 company cards / nav / footer links at the live company artifacts
perl -i -pe '
  s{href="companies/fluiday-auto\.html"}{href="https://claude.ai/code/artifact/804bc8d1-c207-43ee-bc19-e9afa9800256"}g;
  s{href="companies/nheroes\.html"}{href="https://claude.ai/code/artifact/b12be412-ea5c-4d6e-a3ad-c9dd2c309801"}g;
  s{href="companies/talawin-marha\.html"}{href="https://claude.ai/code/artifact/79519b50-b279-4841-b176-7f450f0c471c"}g;
  s{href="companies/sky-global-contracting\.html"}{href="https://claude.ai/code/artifact/6b5085d1-1bf0-4474-a7b8-57dce87457e6"}g;
  s{href="companies/sky-global-financial-consulting\.html"}{href="https://claude.ai/code/artifact/6648091c-b8a8-4356-9983-ff84f403249d"}g;
' dist/home.html

echo "built dist/home.html ($(wc -c < dist/home.html) bytes)"
