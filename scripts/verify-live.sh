#!/usr/bin/env bash
# SmartMirror.hk — post-deploy live verifier.
# Usage: bash scripts/verify-live.sh [commit-sha]
#   default sha = local HEAD
# Checks, against the deployed copy:
#   1) raw.githubusercontent.com/<sha>/index.html  == local index.html (byte-identical)
#   2) https://loolento.github.io/smartmirror.hk/index.html == local index.html
#   3) live page HTTP 200 and no leftover marker/placeholder
# Uses the commit-SHA raw URL on purpose: the /main/ raw URL has 1-5 min CDN lag.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2

REPO_SLUG="Loolento/smartmirror.hk"
PAGES_URL="https://loolento.github.io/smartmirror.hk/index.html"
SHA="${1:-$(git rev-parse HEAD)}"
LOCAL_MD5=$(md5sum index.html | awk '{print $1}')
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
rc=0

echo "== SmartMirror live verify (sha=$SHA) =="
echo "   local index.html md5 = $LOCAL_MD5"

# 1) SHA-pinned raw
RAW_URL="https://raw.githubusercontent.com/$REPO_SLUG/$SHA/index.html"
code=$(curl -sS -o "$TMP/raw.html" -w '%{http_code}' "$RAW_URL" || echo 000)
raw_md5=$(md5sum "$TMP/raw.html" | awk '{print $1}')
if [ "$code" = "200" ] && [ "$raw_md5" = "$LOCAL_MD5" ]; then
  echo "  PASS  raw@$SHA matches local (http=$code md5=$raw_md5)"
else
  echo "  FAIL  raw@$SHA mismatch (http=$code md5=$raw_md5)"; rc=1
fi

# 2) GitHub Pages
code=$(curl -sS -o "$TMP/pages.html" -w '%{http_code}' "$PAGES_URL" || echo 000)
pages_md5=$(md5sum "$TMP/pages.html" | awk '{print $1}')
if [ "$code" = "200" ] && [ "$pages_md5" = "$LOCAL_MD5" ]; then
  echo "  PASS  GitHub Pages live matches local (http=$code md5=$pages_md5)"
else
  echo "  FAIL  Pages live mismatch (http=$code md5=$pages_md5) — deploy pending or CDN lag"; rc=1
fi

# 3) live endpoint sanity on the real domain + pages root
for u in "https://loolento.github.io/smartmirror.hk/" "https://smartmirror.hk/"; do
  c=$(curl -sS -o /dev/null -w '%{http_code}' -L --max-time 20 "$u" || echo 000)
  echo "  INFO  $u -> http=$c"
done

# 4) placeholder / TODO leak guard on the deployed copy
if grep -nE 'TODO|FIXME|Lorem ipsum|占位' "$TMP/pages.html" >/dev/null 2>&1; then
  echo "  FAIL  placeholder text found in deployed page"; rc=1
else
  echo "  PASS  no TODO/FIXME/placeholder text in deployed page"
fi

echo "== verify-live exit=$rc =="
exit $rc
