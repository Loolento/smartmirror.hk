# SmartMirror — 操作程序（OPERATION PROCEDURE）

> 呢份係接手用嘅唯一操作文件。所有數字／路徑都係 2026-10-05 實測得出，唔係估計。
> 舊版 `SMARTMIRROR.md` 有兩個錯（repo 路徑已消失、冇寫兩個「站」嘅分別），本版取代佢。

---

## 0. 一句話講清

- **代碼來源（source of truth）** = GitHub repo `Loolento/smartmirror.hk`，分支 `main`。
- **改嘢方式** = 改 `index.html` → `git push origin main` → GitHub Pages 自動 rebuild。
- **⚠️ 有兩個「站」，唔好混淆：**

| 站 | 係乜 | 邊個控制 | push 改得動？ |
|---|---|---|---|
| `https://loolento.github.io/smartmirror.hk/` | GitHub Pages，由呢個 repo 部署 | 呢個 repo | ✅ 會 |
| `https://smartmirror.hk` → `https://www.smartmirror.com.hk/` | **客戶真正睇嘅正式站 = Wix** | Wix 後台 | ❌ **完全唔會** |

實測證據：`smartmirror.hk` DNS = `185.230.63.107 / .171 / .186`（Wix 機房），HTTP 301 去 `www.smartmirror.com.hk`，response header 有 `server: Pepyaka` + `x-wix-*`，標題 `Smart Mirror | Oolaa | Kowloon`。
→ **push 只會更新 Pages 預覽站，唔會更新正式 .hk 站。** 要改正式站，要去 Wix，唔喺呢個 repo 範圍。

---

## 1. 30 秒上手（要記嘅就係呢 6 樣）

1. Repo：`https://github.com/Loolento/smartmirror.hk.git`（branch `main`）
2. 改嘅檔：**只有 `index.html`**（單頁 app，i18n 全部喺入面，第 2239 行 `const i18n = {`）
3. 推上去：`git push origin main`（需要 PAT，見 §3）
4. 推之前必跑：`bash scripts/verify-comprehensive.sh` → **必須 0 FAIL**
5. 推之後必跑：`bash scripts/verify-live.sh` → **必須 PASS 才算交貨**
6. 鐵律：i18n 任何新 field **必須 3 語同步**（`en` / `zh` / `zh-HK`），缺一語 = 不合格

---

## 2. 環境（實測狀態，唔准照舊文件做）

| 項目 | 現況 |
|---|---|
| 舊工作目錄 `/home/hermes/smartmirror.hk/`、`/home/hermes/smartmirror/` | **已經唔存在**（該 user 已刪）。舊文件寫嘅路徑係死嘅 |
| host `/tmp/smartmirror.hk` | 有一個 2026-08-03 嘅**舊 copy**（比 repo 舊），**唔准用**，唔准當 source |
| host nginx `sites-enabled/smartmirror.hk` | 死配置（root 指向唔存在嘅目錄；DNS 亦唔指去呢部機）→ **唔關部署事，唔好改** |
| 工作副本建議位置 | clone 去接手者自己嘅 home，例：`~/smartmirror.hk` |
| 需要嘅工具 | `git`、`node`（i18n 檢查器用）、`curl`、`python3`（可選） |

---

## 3. 第一次接手：建立工作副本（照抄逐步做）

```bash
# 1) clone（repo 可公開讀；push 要 PAT）
git clone https://github.com/Loolento/smartmirror.hk.git ~/smartmirror.hk
cd ~/smartmirror.hk

# 2) 身分（commit 顯示用；用返 repo 慣例）
git config user.name  "Loolento"
git config user.email "loolento@users.noreply.github.com"

# 3) 認證：用環境變數 GITHUB_PAT，唔好將 token 寫死落檔
git config credential.helper '!f() { echo username=x-access-token; echo password=$GITHUB_PAT; }; f'

# 4) 認證測試：應該回一個 40 字 SHA，唔係就要停手查 token
git ls-remote origin main

# 5) 開工前基線：兩個閘都要過
bash scripts/verify-comprehensive.sh    # 期望：0 FAIL
bash scripts/verify-live.sh             # 期望：raw 對到 byte；Pages 可能滯後（見 §7）

# 6) 記住基線 HEAD，出事可回滾
git rev-parse HEAD
```

**注意**：如果你係 root 身分去 `git` 一個由另一個 user 擁有嘅目錄，git 會報 `dubious ownership` 而拒讀 —— 唔好加 `safe.directory` 硬闖，改成用正確 user 身分操作。

---

## 4. 檔案結構（實測）

```
index.html          單頁 app：HTML + CSS + i18n + JS 全部喺一個檔（2877 行 / ~120KB）
about.html          舊獨立頁 — 已 redirect 返 index.html，唔係主線
products.html       同上
project-team.html / design-team.html / buying-team.html / consultant.html   同上（已 redirect）
pain-project.jpg / pain-design.jpg / pain-buying.jpg / pain-consultant.jpg  4 張 role 圖
qr-wechat.png / qr-wechat-joe.jpg / qr-wechat-real.png|jpg / qr-whatsapp.png  聯絡 QR
assets/about/p1-hero.jpg / p2-factory.jpg / p3-build.jpg                     About Us 三張圖
blog/               57 個檔（58 篇舊文章頁 + index.html）
robots.txt          允許全站索引 + 指向 sitemap
sitemap.xml         只列 / 同 /blog/
llms.txt            給 AI 引擎讀嘅站點摘要
.nojekyll           0 byte —— 存在 = 關閉 Jekyll，Pages 直接原樣出檔
scripts/            驗證儀器（本版新補回，舊工作目錄消失時一齊唔見咗）
  ├─ verify-comprehensive.sh   推之前跑：i18n／CSS／結構
  ├─ verify_comprehensive.js   上面個 .sh 叫嘅檢查器（node）
  └─ verify-live.sh            推之後跑：部署對數
```

---

## 5. 日常改動程序（A → G，逐步唔可以跳）

| 步 | 做乜 | 指令／做法 | 唔過點算 |
|---|---|---|---|
| **A** | 同步最新 | `cd ~/smartmirror.hk && git pull` | 有 conflict 就停手，唔好亂 merge |
| **B** | 改嘢 | 只改 `index.html`。i18n 新 field **3 語一次過加齊**；加 key 前先 `grep` 確認冇撞名 | — |
| **C** | 機器驗 | `bash scripts/verify-comprehensive.sh` | 有 FAIL = 唔准 push，改到 0 FAIL |
| **D** | 真人睇 | 瀏覽器開 `file:///…/index.html`：切 3 語 × 開 4 個 role modal，逐個睇標題／圖／清單／「How We Help」 | 見到亂碼、缺字、錯字 → 返 B |
| **E** | commit | `git add -A && git commit -m "fix: …"`（訊息講清改咗乜，唔好寫「update」） | — |
| **F** | 部署 | `git push origin main` | 被拒 = token／權限問題，唔好 force push |
| **G** | 部署驗 | `bash scripts/verify-live.sh`（build 未完成就等，見 §7） | 未 PASS = 未交貨 |

---

## 6. i18n 規格（權威，唔准靠自己演繹）

- **3 個語言 key**：`en`、`zh`（簡體，中性）、`zh-HK`（繁體廣東話）
- **4 個 role**：`project`、`design`、`purchasing`、`consultant`
- **每個 role 固定 7 個 field**（實測齊全，除特別註明）：

| field | 類型 | 用途 |
|---|---|---|
| `<role>Pain` | array | 痛點 bullet（→ `<li>`） |
| `<role>Solutions` | array | How We Help bullet（→ `<li>`） |
| `<role>PainImage` | string | modal 圖檔名 |
| `<role>Title` | string | modal 大標題 |
| `<role>Quote` | string | 引言（可含 HTML） |
| `<role>PainPoints` | string | 「痛點」小標 |
| `<role>HowWeHelp` | string | 「我哋點幫你」小標 |

- **通用 key**（非 role）：`heroTitle` / `heroSub` / `brandTagline` / `ifYouAre` / `projectTeam` / `designTeam` / `purchasingTeam` / `consultant` / `journal` / `latestNews` / `proven` / `products` / `productList` / `productTitle` / `productTag` / `jobReference` / `factSheets` / `downloadFactSheet` / `downloadJobRef` / `talkToUs` / `smartMirrorDemo` / `guestExperience` / `painPoints` / `howWeHelp` / `about*` / `companyBackground` / `background` 等（全部 3 語齊）
- **渲染規則（重要）**：`rolePainPoints === undefined` 時會**靜靜跌落通用** `painPoints`（`index.html` 第 2650 行）。所以漏 key **唔會爆頁**，只會令該角色標題同其他角色唔一致 → 呢種「睇落冇事」嘅缺漏最易走甩，一定要靠 §7 閘① 捉。
- **已知實例**：`consultantPainPoints` 曾只有 `zh-HK`，EN／ZH 跌落通用標題；已於 commit `41ddd13` 補齊（en `PAIN POINTS` / zh `痛点：`）。
- **`heroDesc`**：只有 `en`、而且冇任何地方 render（死 key）。可以不理，但唔算「已同步」。
- **禁止**：同一個 key 一時做 string 一時做 array（會撞爛 i18n）。

---

## 7. 驗證儀器（兩個閘，逐項講清）

### 閘① `bash scripts/verify-comprehensive.sh`（推之前）
檢查項目（全部要 PASS / NOTE 唔算錯，FAIL 一定要處理）：
1. 3 個語言齊全
2. key collision：同 key 3 語類型一致
3. 有 render 嘅 key，3 語都有
4. 冇重複 HTML `id`（`getElementById` 只回第一個，重複 id 會令內容「睇落舊咗」）
5. 所有本地引用圖檔真實存在
6. CSS 規格：`.container` 1340px / `padding 0 48px`、`.content` `240px 1fr 280px`、有 860px 斷點、PingFang 字體
7. 禁用：`font-weight:300`、`We feel you`、`Arial`
8. `<noscript>` 內容夠長（crawler 睇）
9. 4 個 role 按鈕都駁 `showRoleModal('<role>')`
10. 結構守衛：`mainModal` + `modalBody` 存在、單一 `<html>`、`const i18n` 存在

判讀：尾行 `-- N PASS / M NOTE / K FAIL --`，**K 必須 = 0**。

### 閘② `bash scripts/verify-live.sh [sha]`（推之後）
1. `raw.githubusercontent.com/<repo>/<sha>/index.html` 同本地 `index.html` **md5 完全一致**（用 commit-SHA URL，唔用 `/main/`，因為 `/main/` 有 1–5 分鐘 CDN 滯後）
2. `https://loolento.github.io/smartmirror.hk/index.html` 同本地 **md5 完全一致**
3. 兩條 live URL 出 HTTP 200
4. 部署版冇 `TODO` / `FIXME` / `Lorem ipsum`

判讀：**4 項都要 PASS**，第 2 項唔 PASS = 部署未完成（見 §8）。

### 閘③ 真人驗（唔可以省）
瀏覽器開本地 `file://` → 切 3 語 → 4 個 role modal 逐個開 → 睇標題／圖／bullet／小標。文字類改動一定要做（機器只驗結構同對數，驗唔到「讀落怪唔怪」）。

---

## 8. 部署流程同判定（GitHub Pages）

- Pages 設定：source = branch `main`，path `/`（`.nojekyll` 已存在，所以係原樣出檔，唔經 Jekyll）
- push 之後 GitHub 會自動開一個 run（`pages build and deployment`）。
- **判定次序**：
  1. `bash scripts/verify-live.sh` → 第 1 項（raw@SHA）通常**即刻**對到；第 2 項（Pages）要等 build。
  2. 查 build 狀態（要 PAT）：
     `curl -s -H "Authorization: Bearer $GITHUB_PAT" https://api.github.com/repos/Loolento/smartmirror.hk/pages/builds/latest`
     → 要見到 `"status": "built"`。
  3. 再查 run 狀態（`/actions/runs`）睇 `status` / `conclusion`。
- **三種非成功情況點處理（唔准靠估）**：
  | 見到 | 意思 | 做法 |
  |---|---|---|
  | `queued`（長時間） | GitHub 自己嘅 build worker 冇容量。查 `https://www.githubstatus.com/api/v2/summary.json`，見到 `Actions -> degraded_performance` + incident「delays when assigning GitHub-hosted runners」= 就係佢 | **等**。唔係你冇權限、唔係 push 失敗，冇任何方法插隊 |
  | `cancelled` | 後一次 build 請求頂走咗前一次（例如再 push 或手動 `POST /pages/builds`） | 睇最新一次 run 就夠 |
  | `errored` / `Page build failed` | 真錯，要查 | 睇 run log；常見原因：檔案結構怪、單檔過大、`_` 開頭路徑 |
- **未見到 `built` + Pages md5 對到之前 = 未交貨。** 唔可以用「應該 deploy 咗」交差。

---

## 9. Layout 規格（V2 Final，user-approved）

```
.container  max-width: 1340px ; padding: 0 48px
.content    display: grid ; grid-template-columns: 240px 1fr 280px ; gap: 20px
```

| 欄 | 寬 | 內容 |
|---|---|---|
| 左 (A) | 240px | Pain Points hero + 4 個 role 按鈕 + Talk to us |
| 中 | 1fr | YouTube video（max-width 420px） |
| 右 (B) | 280px | Blog + About Us + Product cards |

斷點（實測，全部喺 `index.html`）：`min-width:861px`（桌面加強）、`max-width:1100px`（`220px 1fr 240px` + `padding 0 24px`）、`max-width:860px`（手機）、`max-width:420px`（細機）。
→ 講「手機專用」改動 = **只改 `@media (max-width:860px){}` 區塊**，唔准掂共用 class 定義。

---

## 10. Copywriting 規則（嚴格）

- **EN**：自然 American English。「We've been there」✅；「We feel you」❌（閘會捉）。名人引言用西方（da Vinci / Jobs / Buffett / Drucker）。
- **zh**：中性簡體，對象係新加坡／馬來西亞讀者 —— **要重寫，唔係逐字由 zh-HK 換簡體**。
- **zh-HK**：自然廣東話，用馬雲引言 OK。
- **Emoji**：每個 bullet 最多 1–2 個，放句首；唔好 double-stack、唔好塞喺關鍵字中間（會破壞 SEO）。
- **CJK `font-weight` = 400**（唔好用 300，粗幼線會唔均；閘會捉）。
- **font-family**：`'Inter','PingFang TC','PingFang SC','Noto Sans TC',sans-serif`。
- **術語**：半透玻璃／單向透視玻璃 → `one-way mirror`；淘寶射頻 → `generic RF switch`；天璽海 = `Cullinan Harbour`。

---

## 11. Pitfalls（血淚教訓，全部要記）

**原有 6 條**
1. **i18n key collision**：同一個 key 唔可以又 string 又 array（例：`products` 係 heading string、`productList` 係 array）。加 key 前先 `grep`。
2. **Mobile / desktop scope**：有啲 class 係共用。講「mobile only」→ 只改 `@media (max-width:860px){}`，唔好掂 shared 定義。
3. **Cache / CDN 疑雲**：人話「睇唔到變更」→ **先 `curl` live 查 server-side**，再查有冇重複 HTML id。唔好一開口就賴 cache。
4. **`<noscript>`**：i18n 改完要同步改 `<noscript>`（crawler 睇嗰份），最易漏。
5. **圖片**：AI 生成圖可能 baked-in 亂碼文字；commit 前要 `vision_analyze` 睇清楚。
6. **重複 HTML id**：`getElementById` 只回第一個 → 內容「睇落舊咗」（唔係 cache 問題）。

**新增（2026-10-05 實測）**
7. **舊路徑／舊 copy 陷阱**：`/home/hermes/…` 已死、`/tmp/smartmirror.hk` 係 8 月舊 copy。一律由 GitHub clone，唔准用散落嘅舊檔。
8. **正式站唔喺呢個 repo**：`smartmirror.hk` 係 Wix。push 只改 Pages。搞清楚呢點，否則改完以為官網變咗。
9. **漏 i18n key 唔會爆頁**：有 fallback（§6），所以「睇落正常」但其實唔一致 → 靠閘①。
10. **驗證腳本會失蹤**：舊工作目錄一刪就冇。所以腳本已入 repo（`scripts/`），改嘢前先確認佢哋喺度。
11. **Pages build 可能長時間 `queued`**：GitHub 自己 infra 問題，唔係你權限或 push 出事（§8 有處理表）。
12. **`git` 跨 user 擁有權**：唔同 user 擁有嘅目錄會報 `dubious ownership` —— 用正確 user 身分做，唔好硬加 `safe.directory`。

---

## 12. 禁區（唔准掂）

- ❌ `smartmirror.hk` / Wix 後台（唔喺呢個 repo 範圍）
- ❌ host nginx 設定（`/etc/nginx/sites-*/smartmirror.hk` 係死配置，改佢只會製造混亂）
- ❌ `/tmp/smartmirror.hk` 舊 copy 當 source
- ❌ `git push --force` / 改寫歷史
- ❌ 未經授權嘅視覺改動（歷史上曾有「未授權改 button styling」事故 —— 改樣式前要有人明確批准）
- ❌ 4 個 role 改返做獨立 `.html` 頁（已 redirect，留返 modal 一條路）

---

## 13. 交接簽收 Checklist

接手者逐項打勾，全部 ✅ 才算接手完成：

- [ ] clone 到本機，`git log --oneline -1` 見到 HEAD
- [ ] `git ls-remote origin main` 回 SHA（= 有 push 權）
- [ ] `bash scripts/verify-comprehensive.sh` → **0 FAIL**
- [ ] `bash scripts/verify-live.sh` → **4 項 PASS**
- [ ] 瀏覽器開本地 `index.html`，切 3 語、開 4 個 role modal，內容正常、console 冇 error
- [ ] 明白 §0 表格：Pages（push 改得）vs Wix 正式站（push 改唔到）
- [ ] 明白 §7 兩個閘做乜、§8 部署判定、§11 全部 pitfalls

---

## 14. 現況（2026-10-05 19:45 UTC，實測）

| 項目 | 值 |
|---|---|
| repo HEAD | `41ddd13`（fix: sync consultantPainPoints across en/zh + chore: 補回 scripts/） |
| 本地／raw@SHA md5 | `8bf7284ca90d4f1c7ed3e65bdf123fb5` |
| Pages live md5 | `558e494e3c41d97da777cd8b4ed59728`（**舊版，未追上**） |
| Pages build | run `37364153832` = `queued` 自 19:33:19 UTC 冇動過。原因已查實：**GitHub 官方 incident**（2026-10-05 19:11:58Z 開，「delays when assigning GitHub-hosted runners to Actions jobs」），`Actions` 元件 = `degraded_performance` |
| 未完成事項 | 等 build `built` → 補跑 `bash scripts/verify-live.sh` 對 byte 一致，才算收尾 |

**接手第一件事**：跑 `bash scripts/verify-live.sh`，如果 live md5 已經等於 `8bf7284c…`，§14 呢單就自動完成。
