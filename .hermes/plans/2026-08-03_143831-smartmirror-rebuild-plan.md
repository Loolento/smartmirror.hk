# SmartMirror.hk Rebuild Plan

> **For Hermes:** Use this as the execution plan for the new site replacing the old Wix site.

**Goal:** Rebuild the new smartmirror.hk experience on GitHub Pages so it can replace the old site before **2026-08-05 12:00 HKT**.

**Architecture:** Static single-page-first site with role-based entry points, trilingual content, and text-first SEO/GEO structure. Blog/latest news will be migrated from the old Wix site, curated, then rewritten.

**Current facts:**
- Old site: `smartmirror.hk` currently redirects to `https://www.smartmirror.com.hk/` (Wix)
- New site: `https://loolento.github.io/smartmirror.hk/`
- Repo cloned locally: `/home/hermes/smartmirror.hk`
- Current repo has 8 HTML pages: `index.html`, `about.html`, `products.html`, 4 role pages, `blog/index.html`
- `blog/index.html` already lists 3 posts, but the article files are missing in the repo
- Old Wix blog feed found: `https://www.smartmirror.com.hk/blog-feed.xml`
- Old Wix blog sitemap found: `https://www.smartmirror.com.hk/blog-posts-sitemap.xml`

---

## What is already done
- New repo cloned and inspected
- Existing page inventory completed
- Old site confirmed as Wix and located
- Blog feed discovered and first-pass extraction completed
- Visual direction for About Us infographic reviewed: good concept, but should be split into web sections, not inserted as one long image

## What is not done yet
1. Blog migration from old Wix site
2. Blog article pages creation in new repo
3. Content rewrite / curation for migrated posts
4. Consistency pass on numbers, naming, and claims
5. SEO / GEO completion pass
6. Deployment / domain replacement plan for `smartmirror.hk`

---

## Blog inventory from old site (top 20 from RSS)
1. No Login. Just Cast.
2. Oolaa Way Vs Old Way Mirror TV (Hotel)
3. Oolaa at Bangkok 5-Star Hotel – The Waldorf Astoria Bangkok
4. Oolaa 首個公營房屋工程項目 : 洪水橋 樂翹軒 (Eminence Terrace I) 電梯大堂Oolaa 智能鏡
5. Cullinan Harbour (天璽·海) - Smart Voice Power Switch by Oolaa
6. 天璽·海 (Cullinan Harbour) 的 智能創新方案
7. Oolaa Ai-Play Mirror: Hong Kong-Innovated Relief Mirror with AR/VR Interactive Gaming (Part 2/6 - Kung Fung Game)
8. Oolaa Ai-Play Mirror: Hong Kong-Innovated Relief Mirror with AR/VR Interactive Gaming (Part 1/6 - Boxing)
9. Skin Moisture Analyser - battery replacement
10. 澐璟 智能鏡 配件使用說明 (視頻)
11. 破天荒方案｜智能語音開關器革新香港豪宅浴室體驗 為發展商攻克痛點
12. OJOP - One JEPG, Oneness Possibility
13. Stay Tuned to the New Era of Smart Homes by Matter!
14. Oolaa Mirror TV in Heartland Residence, Wuhan (武漢恆隆府)
15. Oolaa ai-Play Mirror unveils its first project
16. Catch a Glimpse of Innovation: Spot Our Oolaa Smart Mirror at Building 11, HSITP
17. Oolaa Smart Mirror Brings Hi-Tech Innovation to Royal Garden, HK
18. Luxury Living at Villa La Plage (瑧譽)
19. Elevate Your Lifestyle with Oolaa Smart Mirror in Luxury Serviced Apartments in Central, Hong Kong
20. Experience the Innovation of Oolaa Mirror TV at Park Hyatt Niseko

---

## Immediate execution priorities

### Phase 1 — Blog migration triage
**Objective:** decide what to migrate first, what to rewrite, what to skip.

**Files:**
- Create: `.hermes/plans/...-blog-migration-notes.md`
- Modify: `blog/index.html`

**Steps:**
1. Extract full RSS + sitemap list from old Wix blog
2. Classify each post into: migrate now / rewrite then migrate / archive
3. Prioritize posts already referenced in new `blog/index.html`
4. Produce final slug map from old URLs to new local blog pages

**Validation:** every link in `blog/index.html` must resolve to a local file.

### Phase 2 — Create missing blog pages
**Objective:** make the current blog index functional.

**Files:**
- Create: `blog/no-login-just-cast.html`
- Create: `blog/oolaa-vs-old-way.html`
- Create: `blog/waldorf-astoria-bangkok.html`

**Steps:**
1. Draft new article templates using site styling
2. Rewrite titles/descriptions for clarity and SEO/GEO
3. Add article structured data if needed

**Validation:** open each file locally and confirm all links render.

### Phase 3 — Content consistency pass
**Objective:** remove contradictions across the site.

**Files:**
- Modify: `index.html`
- Modify: `about.html`
- Modify: `products.html`
- Modify: `project-team.html`
- Modify: `design-team.html`
- Modify: `buying-team.html`
- Modify: `consultant.html`

**Steps:**
1. Align installation numbers (`30,000+` vs `31,000+`)
2. Align product naming and brand spelling
3. Review CTA labels and page titles
4. Ensure trilingual tone is natural, not literal translation

**Validation:** one terminology sheet + no obvious contradictions remain.

### Phase 4 — SEO / GEO hardening
**Objective:** make the site easy for Google and AI engines to parse.

**Files:**
- Modify: `index.html`
- Modify: `sitemap.xml`
- Modify: `robots.txt`
- Modify: `llms.txt`
- Create/Modify: article schema in blog pages

**Steps:**
1. Expand sitemap beyond home + blog index if new pages are added
2. Ensure each page has title/description/canonical/OG data
3. Keep entity naming consistent for Viewdex / Oolaa / smartmirror.hk
4. Keep key content text-based, not image-only

**Validation:** crawl key pages and confirm metadata + internal links resolve.

### Phase 5 — Replacement readiness
**Objective:** prepare for domain cutover from old Wix site to new GitHub Pages site.

**Files:**
- Create: `CNAME` if proceeding with GitHub Pages custom domain
- Modify: repo deployment settings externally on GitHub / DNS

**Steps:**
1. Confirm whether `smartmirror.hk` should point directly to GitHub Pages
2. Add `CNAME` when cutover is approved
3. Test `https://loolento.github.io/smartmirror.hk/` and later `https://smartmirror.hk/`

**Validation:** DNS + HTTPS + canonical URLs all agree.

---

## Risks / open questions
- Do we migrate all old posts, or only the top 10–20 most relevant ones?
- Should the About Us infographic be treated as a visual reference only, or should some sections be rebuilt as actual HTML blocks first?
- Who approves final copy rewrites for blog posts before publish?
- When exactly will DNS/domain cutover be approved?

---

## Deadline strategy
To hit **2026-08-05 12:00 HKT**:
- Finish blog migration triage first
- Then complete missing article pages
- Then do consistency and SEO/GEO pass
- Leave DNS/cutover for the final step after content is stable
