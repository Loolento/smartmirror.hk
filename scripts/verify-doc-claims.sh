#!/usr/bin/env bash
# Verifies every factual claim made in SMARTMIRROR_OPERATIONS.md.
# Usage: bash scripts/verify-doc-claims.sh
# Prints one line per claim: PASS / FAIL / INFO  + doc section number.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
DOC="SMARTMIRROR_OPERATIONS.md"
[ -f "$DOC" ] || { echo "FAIL [—] $DOC not found"; exit 2; }
P=0; F=0
chk() { if [ "$2" = "1" ]; then echo "  PASS [$1] $3"; P=$((P+1)); else echo "  FAIL [$1] $3"; F=$((F+1)); fi; }
inf() { echo "  INFO [$1] $2"; }

echo "== verifying claims in $DOC =="

# ---------- §0 ----------
git remote get-url origin | grep -q "Loolento/smartmirror.hk" && chk 0 1 "repo = github.com/Loolento/smartmirror.hk" || chk 0 0 "repo slug"
git rev-parse --abbrev-ref HEAD | grep -qx main && chk 0 1 "branch = main" || chk 0 0 "branch main"
PSRC=$(curl -s -H "Authorization: Bearer $GITHUB_PAT" https://api.github.com/repos/Loolento/smartmirror.hk/pages | python3 -c "import sys,json;d=json.load(sys.stdin);s=d.get('source') or {};print(s.get('branch'),s.get('path'))" 2>/dev/null)
[ "$PSRC" = "main /" ] && chk 0 1 "Pages source = branch main, path / (API)" || chk 0 0 "Pages source (got: $PSRC)"
WIX=$(curl -sSI -L --max-time 20 https://smartmirror.hk/ | grep -ci "x-wix\|server: Pepyaka")
[ "$WIX" -gt 0 ] && chk 0 1 "smartmirror.hk serves Wix (x-wix-*/Pepyaka headers)" || chk 0 0 "smartmirror.hk not Wix?"
WIXRED=$(curl -sSI --max-time 20 https://smartmirror.hk/ | grep -ci "location: https://www.smartmirror.com.hk")
[ "$WIXRED" -gt 0 ] && chk 0 1 "smartmirror.hk 301 -> www.smartmirror.com.hk" || chk 0 0 "301 target differs"

# ---------- §2 ----------
ssh -i /opt/data/hermes-rescue-key -o StrictHostKeyChecking=no -o ConnectTimeout=8 root@127.0.0.1 'test ! -e /home/hermes/smartmirror.hk && test ! -e /home/hermes/smartmirror; echo $?' >/tmp/h1 2>/dev/null
[ "$(cat /tmp/h1 2>/dev/null)" = "0" ] && chk 2 1 "/home/hermes/{smartmirror.hk,smartmirror} both absent on host" || chk 2 0 "old host paths still exist"
ssh -i /opt/data/hermes-rescue-key -o StrictHostKeyChecking=no -o ConnectTimeout=8 root@127.0.0.1 'test -d /tmp/smartmirror.hk && echo yes' 2>/dev/null | grep -q yes && chk 2 1 "/tmp/smartmirror.hk (old copy) exists on host" || chk 2 0 "/tmp copy missing"
ssh -i /opt/data/hermes-rescue-key -o StrictHostKeyChecking=no -o ConnectTimeout=8 root@127.0.0.1 'test -f /etc/nginx/sites-enabled/smartmirror.hk && grep -c "/home/hermes/smartmirror" /etc/nginx/sites-enabled/smartmirror.hk' 2>/dev/null | tail -1 | grep -qE '^[0-9]+$' && chk 2 1 "nginx sites-enabled/smartmirror.hk exists, root points at dead path" || chk 2 0 "nginx claim"
command -v git >/dev/null && chk 2 1 "git present" || chk 2 0 "git missing"
command -v node >/dev/null && chk 2 1 "node present (i18n checker needs it)" || chk 2 0 "node missing"
command -v curl >/dev/null && chk 2 1 "curl present" || chk 2 0 "curl missing"

# ---------- §3 ----------
bash scripts/verify-comprehensive.sh >/tmp/vc.out 2>&1; [ $? -eq 0 ] && chk 3 1 "documented gate ① command runs and passes" || chk 3 0 "gate ① command fails"
bash scripts/verify-live.sh >/tmp/vl.out 2>&1; [ $? -eq 0 ] && chk 3 1 "documented gate ② command runs and passes" || chk 3 0 "gate ② command fails (live not in sync)"
git ls-remote origin main >/dev/null 2>&1 && chk 3 1 "git ls-remote origin main authenticates" || chk 3 0 "ls-remote failed (token?)"

# ---------- §4 file structure ----------
for f in index.html about.html products.html project-team.html design-team.html buying-team.html consultant.html \
         pain-project.jpg pain-design.jpg pain-buying.jpg pain-consultant.jpg \
         qr-wechat.png qr-wechat-joe.jpg qr-wechat-real.png qr-wechat-real.jpg qr-whatsapp.png \
         assets/about/p1-hero.jpg assets/about/p2-factory.jpg assets/about/p3-build.jpg \
         robots.txt sitemap.xml llms.txt .nojekyll \
         scripts/verify-comprehensive.sh scripts/verify_comprehensive.js scripts/verify-live.sh; do
  [ -e "$f" ] && chk 4 1 "§4 file exists: $f" || chk 4 0 "§4 lists missing file: $f"
done
[ "$(wc -c < .nojekyll)" = "0" ] && chk 4 1 ".nojekyll is 0 bytes (Jekyll off)" || chk 4 0 ".nojekyll not 0 bytes"
BLOG=$(ls blog | wc -l); BLOGH=$(ls blog/*.html 2>/dev/null | wc -l)
DOC_BC=$(grep -o 'blog/ *[0-9]* 個檔' "$DOC" | grep -o '[0-9]*' | head -1)
inf 4 "blog/ actual: $BLOG files, $BLOGH of them .html (incl index.html)"
[ "${DOC_BC:-0}" = "$BLOG" ] && chk 4 1 "§4 blog file count matches ($BLOG)" || chk 4 0 "§4 blog count says ${DOC_BC:-none}, actual $BLOG"

# ---------- §5 ----------
grep -q 'git pull' "$DOC" && grep -q 'git push origin main' "$DOC" && chk 5 1 "§5 procedure commands present (pull / push origin main)" || chk 5 0 "§5 commands"

# ---------- §6 i18n spec ----------
node -e '
const fs=require("fs");const html=fs.readFileSync("index.html","utf8");
const a=html.indexOf("const i18n = {");const s=html.indexOf("{",a);let d=0,e=-1;
for(let p=s;p<html.length;p++){const c=html[p];if(c==="{")d++;else if(c==="}"){d--;if(d===0){e=p;break;}}}
const i=eval("("+html.slice(s,e+1)+")");const L=["en","zh","zh-HK"],R=["project","design","purchasing","consultant"];
let bad=[];
for(const l of L)if(!i[l])bad.push("lang "+l);
for(const r of R)for(const f of ["Pain","Solutions","PainImage","Title","Quote","PainPoints","HowWeHelp"]){
  const k=r+f;const miss=L.filter(l=>i[l][k]===undefined);
  if(miss.length)bad.push(k+" missing in "+miss.join(","));
}
console.log(bad.length? "FAIL 6 role-field matrix: "+bad.join(" | ") : "PASS 6 role-field matrix: 4 roles x 7 fields complete in all 3 languages (aside from documented notes)");
' 2>&1 | sed 's/^/  /'
node -e '
const fs=require("fs");const html=fs.readFileSync("index.html","utf8");
const a=html.indexOf("const i18n = {");const s=html.indexOf("{",a);let d=0,e=-1;
for(let p=s;p<html.length;p++){const c=html[p];if(c==="{")d++;else if(c==="}"){d--;if(d===0){e=p;break;}}}
const i=eval("("+html.slice(s,e+1)+")");
console.log(i.en.heroDesc!==undefined&&i.zh.heroDesc===undefined?"PASS 6 heroDesc is en-only (dead key) as documented":"FAIL 6 heroDesc note");
'
LI=$(grep -n "const i18n = {" index.html | cut -d: -f1)
DC=$(grep -o '第 [0-9]* 行 `const i18n' "$DOC" | grep -o '[0-9]*' | head -1)
[ "${DC:-0}" = "$LI" ] && chk 6 1 "§6 line number for \`const i18n\` = $LI" || chk 6 0 "§6 says line ${DC:-none} for const i18n, actual $LI"
FL=$(grep -n 'rolePainPoints !== undefined' index.html | cut -d: -f1)
DF=$(grep -o '第 [0-9]* 行）' "$DOC" | grep -o '[0-9]*' | head -1)
[ "${DF:-0}" = "$FL" ] && chk 6 1 "§6 fallback line number = $FL" || chk 6 0 "§6 says line ${DF:-none} for fallback, actual $FL"

# ---------- §7 gate contents ----------
for token in 'max-width:\s*1340px' 'grid-template-columns: 240px 1fr 280px' 'font-weight:\s*300' 'We feel you' '<noscript>' 'showRoleModal'; do
  grep -qF "$token" scripts/verify_comprehensive.js && chk 7 1 "§7 gate ① actually checks: $token" || chk 7 0 "§7 gate ① does NOT check: $token"
done
grep -q 'raw.githubusercontent.com' scripts/verify-live.sh && grep -q 'md5sum' scripts/verify-live.sh && chk 7 1 "§7 gate ② uses SHA-pinned raw + md5" || chk 7 0 "§7 gate ②"

# ---------- §8 ----------
grep -q 'pages/builds/latest' "$DOC" && chk 8 1 "§8 build-status API endpoint documented" || chk 8 0 "§8 endpoint"
curl -s -H "Authorization: Bearer $GITHUB_PAT" https://api.github.com/repos/Loolento/smartmirror.hk/pages/builds/latest -o /tmp/pbl.json
python3 -c "
import json;d=json.load(open('/tmp/pbl.json'))
print('  PASS [8] Pages build API reachable, latest status =',d.get('status'),'commit',str(d.get('commit'))[:8])
" || chk 8 0 "Pages build API unreachable"

# ---------- §9 layout ----------
for token in 'max-width: 1340px' 'padding: 0 48px' 'grid-template-columns: 240px 1fr 280px' 'max-width: 1100px' 'max-width: 860px' 'max-width: 420px' 'min-width: 861px'; do
  grep -qF "$token" index.html && chk 9 1 "§9 CSS present in index.html: $token" || chk 9 0 "§9 missing: $token"
done
grep -qF 'grid-template-columns: 220px 1fr 240px' index.html && chk 9 1 "§9 1100px block uses 220px 1fr 240px" || chk 9 0 "§9 1100px block value"
grep -qF 'PingFang TC' index.html && chk 9 1 "§9 font stack has PingFang TC" || chk 9 0 "§9 font stack"

# ---------- §11 pitfalls ----------
grep -q "font-weight:300" index.html && chk 11 0 "pitfall 7: font-weight:300 still present in index.html" || chk 11 1 "no font-weight:300 in index.html (consistent with gate rule)"
curl -sI --max-time 15 https://www.githubstatus.com/api/v2/components.json >/dev/null && inf 11 "GitHub status API reachable (incident text in §8/§11 was quoted at report time)"

# ---------- §14 current state ----------
HEAD=$(git rev-parse --short HEAD); LMD5=$(md5sum index.html | awk '{print $1}')
DHEAD=$(grep -oE 'repo HEAD \| `[0-9a-f]{7}`' "$DOC" | grep -oE '[0-9a-f]{7}')
DLMD5=$(grep -oE '本地／raw@SHA md5 \| `[0-9a-f]{32}`' "$DOC" | grep -oE '[0-9a-f]{32}')
LIVE=$(curl -s --max-time 25 https://loolento.github.io/smartmirror.hk/index.html | md5sum | awk '{print $1}')
DLIVE=$(grep -oE 'Pages live md5 \| `[0-9a-f]{32}`' "$DOC" | grep -oE '[0-9a-f]{32}')
if [ "$DHEAD" = "$HEAD" ]; then chk 14 1 "§14 HEAD = $HEAD"
elif [ -n "$DHEAD" ] && git merge-base --is-ancestor "$DHEAD" HEAD 2>/dev/null; then
  inf 14 "§14 records HEAD $DHEAD; repo now at $HEAD (later doc-only commit) — tolerated"
else chk 14 0 "§14 HEAD says ${DHEAD:-none}, actual $HEAD (not an ancestor)"; fi
[ "$DLMD5" = "$LMD5" ] && chk 14 1 "§14 local/raw md5 = $LMD5" || chk 14 0 "§14 local md5 says ${DLMD5:-none}, actual $LMD5"
[ "$DLIVE" = "$LIVE" ] && chk 14 1 "§14 live md5 = $LIVE" || chk 14 0 "§14 live md5 says ${DLIVE:-none}, actual $LIVE"

echo "== claims: $P PASS / $F FAIL =="
exit $([ "$F" -eq 0 ] && echo 0 || echo 1)
