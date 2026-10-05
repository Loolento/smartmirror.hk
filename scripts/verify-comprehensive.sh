#!/usr/bin/env bash
# SmartMirror.hk — comprehensive pre-push verifier (i18n + CSS + structure).
# Usage: bash scripts/verify-comprehensive.sh
# Exit 0 = all PASS. Run this BEFORE commit/push.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2

command -v node >/dev/null 2>&1 || { echo "FAIL: node not found (i18n parse needs node)"; exit 2; }
node scripts/verify_comprehensive.js
rc=$?

# extra grep-level guards (cheap, catch regressions the JS pass may not)
echo "-- structural guards --"
if grep -q 'id="mainModal"' index.html && grep -q 'id="modalBody"' index.html; then echo "  PASS  modal skeleton (mainModal + modalBody) present"; else echo "  FAIL  modal skeleton missing"; rc=1; fi
if [ "$(grep -c '<html' index.html)" = "1" ] && [ "$(grep -c '</html>' index.html)" = "1" ]; then
  echo "  PASS  single <html> document"; else echo "  FAIL  html tag count != 1"; rc=1; fi
if grep -q 'const i18n' index.html; then echo "  PASS  const i18n present"; else echo "  FAIL  const i18n missing"; rc=1; fi

echo "== verify-comprehensive exit=${rc} =="
exit $rc
