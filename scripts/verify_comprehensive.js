#!/usr/bin/env node
/* SmartMirror.hk — comprehensive i18n / CSS / structure verifier.
   Repairs the lost scripts/verify-comprehensive.sh behaviour.
   Exit 0 = all PASS, 1 = any FAIL.  Manual review items print as NOTE. */
'use strict';
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const file = path.join(root, 'index.html');
const html = fs.readFileSync(file, 'utf8');

const fails = [], notes = [], passes = [];
const ok = (m) => passes.push(m);
const bad = (m) => fails.push(m);
const note = (m) => notes.push(m);

/* ---------- 1. parse i18n ---------- */
const anchor = html.indexOf('const i18n = {');
if (anchor < 0) { bad('i18n object not found'); report(); }
const start = html.indexOf('{', anchor);
let d = 0, end = -1;
for (let p = start; p < html.length; p++) {
  const c = html[p];
  if (c === '{') d++; else if (c === '}') { d--; if (d === 0) { end = p; break; } }
}
const i18n = eval('(' + html.slice(start, end + 1) + ')');
const LANGS = ['en', 'zh', 'zh-HK'];
const ROLES = ['project', 'design', 'purchasing', 'consultant'];

const got = Object.keys(i18n);
const missLang = LANGS.filter(l => !got.includes(l));
missLang.length ? bad(`missing language(s): ${missLang}`) : ok(`3 languages present: ${LANGS.join(', ')}`);

/* 2. per-key sync + type consistency (i18n key collision guard) */
const keys = new Set();
for (const l of LANGS) if (i18n[l]) Object.keys(i18n[l]).forEach(k => keys.add(k));
const syncIssues = [], typeIssues = [];
for (const k of [...keys].sort()) {
  const types = {}, missing = [];
  for (const l of LANGS) {
    const v = i18n[l] ? i18n[l][k] : undefined;
    if (v === undefined) { missing.push(l); continue; }
    types[l] = Array.isArray(v) ? 'array' : typeof v;
  }
  if (missing.length) syncIssues.push(`${k} (missing: ${missing.join(',')})`);
  const uniq = new Set(Object.values(types));
  if (uniq.size > 1) typeIssues.push(`${k} -> ${Object.entries(types).map(([l, t]) => l + ':' + t).join(' ')}`);
}
typeIssues.length
  ? bad(`i18n key collision (same key, different type): ${typeIssues.join(' | ')}`)
  : ok('no i18n key collision (type consistent across all languages)');

/* sync gaps are only hard failures when the key is actually rendered */
const rendered = (k) => new RegExp(`data\\.${k}\\b|data\\['${k}'\\]`).test(html);
const hardGaps = syncIssues.filter(s => rendered(s.split(' ')[0]));
const softGaps = syncIssues.filter(s => !rendered(s.split(' ')[0]));
hardGaps.length
  ? bad(`rendered key missing in some language: ${hardGaps.join(' | ')}`)
  : ok('every rendered key exists in all 3 languages');
if (softGaps.length) note(`unrendered/fallback keys not synced: ${softGaps.join(' | ')}`);

/* 3. role field matrix */
for (const r of ROLES) {
  for (const sfx of ['Pain', 'Solutions', 'PainImage', 'Title', 'Quote', 'PainPoints', 'HowWeHelp']) {
    const k = r + sfx;
    for (const l of LANGS) if (i18n[l] && i18n[l][k] === undefined) {
      note(`role field ${k} absent in ${l} (renderer fallback applies)`);
    }
  }
}

/* 4. duplicate HTML ids */
const ids = [...html.matchAll(/\sid="([^"]+)"/g)].map(m => m[1]);
const dup = ids.filter((v, i) => ids.indexOf(v) !== i);
[...new Set(dup)].length ? bad(`duplicate HTML id(s): ${[...new Set(dup)].join(', ')}`) : ok(`no duplicate HTML id (${ids.length} ids)`);

/* 5. assets referenced actually exist */
const refs = [...new Set([...html.matchAll(/src="([^"]+\.(?:jpg|jpeg|png|webp|svg))"/gi)].map(m => m[1]))];
const missAssets = refs.filter(r => !/^https?:/i.test(r) && !fs.existsSync(path.join(root, r)));
missAssets.length ? bad(`referenced asset missing on disk: ${missAssets.join(', ')}`) : ok(`${refs.length} referenced local asset(s) exist on disk`);

/* 6. CSS / layout spec */
const spec = [
  ['.container max-width 1340px', /\.container\s*\{[^}]*max-width:\s*1340px/s],
  ['.container padding 0 48px', /\.container\s*\{[^}]*padding:\s*0\s+48px/s],
  ['grid-template-columns: 240px 1fr 280px', /grid-template-columns:\s*240px\s+1fr\s+280px/],
  ['mobile breakpoint @media (max-width: 860px)', /@media\s*\(max-width:\s*860px\)/],
  ['PingFang font stack', /'PingFang TC'/],
];
for (const [name, re] of spec) re.test(html) ? ok(`CSS spec: ${name}`) : bad(`CSS spec missing: ${name}`);

/* 7. copywriting rules */
const banned = [[/font-weight:\s*300/g, 'font-weight:300'], [/We feel you/gi, '"We feel you"'], [/font-family:[^;}]*\bArial\b/gi, 'Arial in font-family']];
for (const [re, label] of banned) {
  const hits = [...html.matchAll(re)].length;
  hits ? bad(`copywriting/style violation: ${label} x${hits}`) : ok(`no ${label}`);
}
if (/CJK|cjk/.test(html)) note('CJK font-weight:300 check above covers it');

/* 8. noscript present & substantive */
const ns = html.match(/<noscript>([\s\S]*?)<\/noscript>/);
if (!ns) bad('<noscript> fallback missing');
else ns[1].replace(/<[^>]+>/g, '').trim().length > 300
  ? ok(`<noscript> fallback present (${ns[1].replace(/<[^>]+>/g, '').trim().length} chars of text)`)
  : bad('<noscript> fallback too thin for crawlers');

/* 9. modal wiring: 4 role buttons -> showRoleModal */
for (const r of ROLES) {
  new RegExp(`showRoleModal\\('${r}'\\)`).test(html) ? ok(`role button wired: showRoleModal('${r}')`) : bad(`role button missing: showRoleModal('${r}')`);
}
/function showRoleModal/.test(html) ? ok('showRoleModal() defined') : bad('showRoleModal() not defined');

/* ---------- report ---------- */
function report() {
  console.log('== SmartMirror comprehensive verify ==');
  passes.forEach(p => console.log('  PASS  ' + p));
  notes.forEach(n => console.log('  NOTE  ' + n));
  fails.forEach(f => console.log('  FAIL  ' + f));
  console.log(`-- ${passes.length} PASS / ${notes.length} NOTE / ${fails.length} FAIL --`);
  process.exit(fails.length ? 1 : 0);
}
report();
