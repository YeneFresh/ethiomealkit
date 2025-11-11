# ⚔️ YeneFresh Pitch Week — Proof of Readiness Command Board
**Timeline:** Monday → Saturday Night  
**Goal:** Investor-ready demo that convinces skeptics, delights users, and radiates polish.

---

## 🧭 Meta
- **Daily Work Rhythm:** 2 × 90-min deep-work blocks
- **Tools:** Cursor, Supabase, Flutter, GitHub
- **Core Rule:** No "almost done" commits — only visible proof
- **CEO Mantra:** Compress confidence. Ship presence.

---

## 🜂 Phase 1 – Monday Night · Identity & Stability
**Objective:** Make the app *look, load, and feel* premium.

**Tasks**
- [ ] Integrate `BrandLogo` + Splash with gold monogram  
- [ ] Regenerate launcher icons & native splash (Android/iOS)  
- [ ] Add 1200×630 OG image for PR/links  
- [ ] Add subtle tagline on welcome: *“Where freshness meets heritage.”*  
- [ ] Test cold start on emulator + real device  
- [ ] Commit → `feat(brand): lock app identity`

**Investor Proof:** Brand cohesion → Market readiness

---

## 🜃 Phase 2 – Tuesday · Flow of Trust
**Objective:** Intuitive navigation that feels effortless.

**Tasks**
- [ ] Map navigation: Box → Recipes → Delivery → Checkout → Confirm  
- [ ] Add transitions & hero animation  
- [ ] Implement Home / BottomNav entry point  
- [ ] Add GitHub Action → `flutter analyze && flutter test`  
- [ ] Commit → `feat(flow): golden funnel established`

**Investor Proof:** UX clarity → Timelessness

---

## 🜄 Phase 3 – Wednesday · Data Comes Alive
**Objective:** Connect Supabase + show scale readiness.

**Tasks**
- [ ] Seed `recipes`, `weekly_menu`, `delivery_windows` with mock data  
- [ ] Enable anonymous read mode for demo  
- [ ] Add shimmer loaders + pull-to-refresh  
- [ ] Add offline JSON fallback toggle (`useMockData = true`)  
- [ ] Commit → `feat(data): live Supabase + fallback ready`

**Investor Proof:** Scale-capable tech structure

---

## 🜁 Phase 4 – Thursday · One-Tap Order & Admin
**Objective:** Close the loop and display operational backbone.

**Tasks**
- [ ] Checkout → mock payment → confirmation animation  
- [ ] Create `/admin` view listing orders + status toggle  
- [ ] Add timestamps + delivery notes  
- [ ] Commit → `feat(order): loop + admin ops`

**Investor Proof:** End-to-end operation demonstrated

---

## 🜇 Phase 5 – Friday · Investor Readiness & Creative Polish
**Objective:** Tune perception — premium, stable, human.

**Tasks**
- [ ] Replace demo images with real YeneFresh visuals  
- [ ] Refine typography hierarchy (Playfair/Inter)  
- [ ] Add subtle entrance animations + haptics  
- [ ] Profile load time (<3 s)  
- [ ] Commit → `chore(QA): investor polish`

**Investor Proof:** Marketability + Timelessness

---

## 🜏 Phase 6 – Saturday Morning · Demo Armour
**Objective:** Prepare for skepticism; bulletproof the build.

**Tasks**
- [ ] Finalize 1-minute demo path  
- [ ] Add backend status metrics overlay (speed/data count)  
- [ ] Build release APK/IPA  
- [ ] Screenshot 4 hero moments (splash, home, order, admin)  
- [ ] Commit → `release(pitch-build): demo-armour`

**Investor Proof:** Engineering discipline + confidence

---

## 🜨 Phase 7 – Saturday Night · Predatory Demo
**Objective:** Deliver the emotional and logical strike.

**Tasks**
- [ ] 60-second investor narrative rehearsed (value → market → proof)  
- [ ] 3-minute technical deep-dive backup ready  
- [ ] Record demo walkthrough video  
- [ ] Folder `/demo/` includes  
  - [ ] `pitch_build.apk`  
  - [ ] `investor_script.txt`  
  - [ ] `screenshots/`  
  - [ ] `supabase_schema.sql`  
- [ ] Tag → `release/pitch-v1`

**Investor Proof:** “Small team, serious company.”

---

## 📊 Progress Tracker
| Phase | Done ✅ | Energy ⚡ | Confidence 🔥 | Proof 📸 |
|:--|:--:|:--:|:--:|:--|
| 1 Identity & Stability | ☐ | ☐ | ☐ |  |
| 2 Flow of Trust | ☐ | ☐ | ☐ |  |
| 3 Data Comes Alive | ☐ | ☐ | ☐ |  |
| 4 Order & Admin | ☐ | ☐ | ☐ |  |
| 5 Investor Polish | ☐ | ☐ | ☐ |  |
| 6 Demo Armour | ☐ | ☐ | ☐ |  |
| 7 Predatory Demo | ☐ | ☐ | ☐ |  |

---

## 🧩 Nightly CEO Log


Phase: [ ]
Shipped: ___________________________
Proof Demonstrated: ________________
Energy (1-5): ___
Investor Feeling if shown now: ______
Tomorrow’s Predatory Move: _________

Optional Automation

In Cursor, you can attach a simple task:

cursor task watch "docs/pitchweek.md" --pattern "Commit →"


It will mark tasks complete when commits reference that phrase.

Would you like me to include a short Cursor automation JSON (so Cursor auto-updates your progress table and CEO log via commit parsing)?

