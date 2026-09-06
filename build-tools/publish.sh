#!/usr/bin/bash
# Rebuild the self-contained Artifact copies and wire cross-page links.
# URLs of already-published artifacts:
HOME_URL="https://claude.ai/code/artifact/f1783a12-3f47-4b8b-8845-7b6af8f8ed43"
FLUIDAY_URL="https://claude.ai/code/artifact/804bc8d1-c207-43ee-bc19-e9afa9800256"
set -e
cd "$(dirname "$0")"
mkdir -p dist

perl build-artifact.pl index.html dist/home.html "" "Sky Global Holding" "سكاي جلوبال القابضة"
perl build-artifact.pl companies/fluiday-auto.html dist/fluiday.html "fl" "Fluiday Auto" "فلوداي أوتو"

# --- home: company links ---
perl -i -pe 's{href="companies/(nheroes|talawin-marha|sky-global-real-estate|sky-global-financial-consulting)\.html"}{href="#companies" data-soon="1"}g' dist/home.html
perl -i -pe "s{href=\"companies/fluiday-auto\\.html\"}{href=\"$FLUIDAY_URL\"}g" dist/home.html
cat >> dist/home.html <<'EOF'
<style>
.co-panel[data-soon]{cursor:default}
.co-panel[data-soon] .c-go{opacity:.6}
.co-panel[data-soon] .c-go svg{display:none}
.co-panel[data-soon] .c-go span::after{content:" · preview soon";font-weight:600;color:var(--gray)}
html[dir="rtl"] .co-panel[data-soon] .c-go span::after{content:" · المعاينة قريبًا"}
</style>
<script>document.querySelectorAll('.co-panel[data-soon]').forEach(function(a){a.addEventListener('click',function(e){e.preventDefault()})});</script>
EOF

# --- fluiday: links back to the group home ---
perl -i -pe "s{href=\"\\.\\./index\\.html#companies\"}{href=\"$HOME_URL#companies\"}g; s{href=\"\\.\\./index\\.html\"}{href=\"$HOME_URL\"}g" dist/fluiday.html

echo "built dist/home.html  ($(wc -c < dist/home.html) bytes)"
echo "built dist/fluiday.html ($(wc -c < dist/fluiday.html) bytes)"
