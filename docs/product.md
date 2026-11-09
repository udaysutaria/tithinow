# 📱 TithiNow v2 — Product Specification & Architecture

## 1. Vision & Core Philosophy
**TithiNow** transforms the ancient Vedic Panchang into an intuitive, living, action-first companion. While traditional Hindu calendar apps overwhelm users with dense, static Sanskrit tables, TithiNow bridges the generational gap:
- **For Gen Y & Gen Z:** An actionable, instant decision compass (*"Can I sign this contract right now?"*, *"What's the best time to take vehicle delivery today?"*) powered by living celestial animations and one-tap alarms.
- **For Pandits, Jyotishis & Traditionalists:** Deep astronomical precision powered by Swiss Ephemeris (`swisseph`) calculating exact Tithi end times, Nakshatra Padas, planetary Horas, and daytime/nighttime Choghadiyas down to the second.

---

## 2. The Dual-Mode Experience

### ✨ Basic Mode (Action & Decision First)
- **Primary Persona:** Gen Y / Gen Z, young professionals, business owners, modern families.
- **Hero Centerpiece: The Luminous Chandra (Living Moon):**
  - Unbounded high-resolution Moon rendering (utilizing all 30 custom 512x512 Vedic Moon phase assets).
  - Dynamic atmospheric glow and breathing aura reflecting the active moment:
    - 🟢 **Emerald-Gold Halo:** Auspicious (Amrit / Shubh / Labh) — *"Safe to Act"*.
    - 🔴 **Obsidian-Crimson Pulse:** Inauspicious (Rahu Kaal / Rog / Kaal) — *"Avoid Major Decisions"*.
    - 🔵 **Sapphire Halo:** Neutral / Moving (Char) — *"Favorable for Travel"*.
  - **Orbital Astrolabe Ring:** Circular time track around the Moon showing the Sun's position and current Choghadiya segment with live countdown.
  - **Interactive Time Seeker:** Dragging the dial lets users inspect any hour of the day (*"What about 6:00 PM tonight?"*).
- **Life Decision Chips (1-Tap Answers):**
  - ✍️ *Sign Paperwork & Contracts*
  - 🚘 *Buy Vehicle / Electronics Delivery*
  - ✈️ *Start Journey / Travel*
  - 💰 *Financial Deals & Big Investments*
  - 🪔 *Puja & Auspicious Beginnings*
- **1-Tap Alarms:** Immediate one-tap reminder buttons directly on active/upcoming windows.

### 🕉️ Pro Mode (Deep Vedic Ephemeris)
- **Primary Persona:** Astrologers, Pandits, Brahmins, Vedic scholars, elders.
- **Data Matrix:**
  - Tithi name, Paksha (Shukla/Krishna), exact end-time down to seconds, next Tithi start.
  - Nakshatra with Pada/Charan and planetary lord.
  - Yoga, Karana, Ayanamsha (Lahiri / Chitrapaksha degrees).
  - Rahu Kaal, Yamaganda, Gulika Kaal, Abhijit Muhurat, Brahma Muhurat, Godhuli.
  - Complete 8-fold Daytime and 8-fold Nighttime Choghadiya schedule with active countdown.
  - 24-hour Planetary Hora schedule (Surya, Shukra, Budha, Chandra, Shani, Guru, Mangal).
  - Lunar Calendar Toggle: **Purnimanta** (North Indian) vs **Amanta** (Gujarati / South Indian).

### Seamless Switching
- Persistent header switch pill: `[ ✨ Basic  |  🕉️ Pro ]` allows instant toggle without page reload.
- In Basic Mode, tapping the Moon or any decision card reveals an *"Inspect Vedic Logic"* drawer showing the exact astronomical reasons behind the recommendation.

---

## 3. Information Architecture & Navigation

The app uses **Material 3 BottomNavigationBar** with 3 primary destinations:

```
┌────────────────────────────────────────────────────────┐
│                      TITHINOW                          │
│  [📍 City Switcher]            [✨ Basic | 🕉️ Pro]   [⚙️]│
├────────────────────────────────────────────────────────┤
│                                                        │
│                     [ ACTIVE TAB ]                     │
│                                                        │
├────────────────────────────────────────────────────────┤
│      [ ☀️ Today ]        [ 📅 Tithi ]      [ ⏰ Alarms ] │
└────────────────────────────────────────────────────────┘
```

### 1. Tab 1: `Today` (The Daily Living Dashboard)
- Mode switcher in top bar.
- Luminous Floating Moon & Astrolabe Ring.
- Live countdown timer for active Choghadiya & Muhurat.
- Interactive Time Seeker (Scrubber).
- Action Intent Chips & Verdict cards (Basic Mode) OR Full Panchang & Hora Table (Pro Mode).
- Upcoming Rahu Kaal / Inauspicious alert banner.

### 2. Tab 2: `Tithi` (Vedic Calendar & Festival Explorer)
- Monthly / Weekly browseable Vedic calendar.
- Each date tile displays its exact high-res Moon Phase graphic, Hindu date (Month + Tithi + Paksha), and festival tags.
- Filter chips: *All*, *Ekadashi*, *Purnima / Amavasya*, *Vrats*, *Festivals*.
- Date detail modal: Tap any day to preview its complete daytime/nighttime Choghadiya and Muhurats.

### 3. Tab 3: `Alarms` (One-Tap Panchang Reminders)
- Central hub for active and scheduled alerts.
- Quick Panchang presets:
  - 🔔 *Daily Sunrise / Sunset chime*
  - ⚠️ *Rahu Kaal warning (15 mins before it starts)*
  - 🌟 *Next Shubh/Amrit Choghadiya alert*
  - 🪔 *Ekadashi & Vrat reminder (day prior + day of)*
- Custom alarm sound picker (shankh, temple bells, flute, soft singing bowl).

### 4. Secondary Views
- **Settings:**
  - City search (7,100+ cities with instant search & coordinates).
  - Language selection (English, Gujarati, Hindi).
  - Lunar Calendar System (Purnimanta vs Amanta).
  - Notification & Alarm volume preferences.
- **About TithiNow:**
  - Swiss Ephemeris AGPLv3 legal attribution.
  - App version & changelog.
  - Privacy policy link.

---

## 4. Key Architectural Pillars for v2

1. **Decoupled Ephemeris Engine (`sweph`):**
   - Pure Dart calculation service operating offline.
   - High performance: Panchang and Choghadiya calculations take < 15ms.
2. **Offline-First SQLite Cache (`sqflite`):**
   - 7,100+ Indian cities indexed for sub-millisecond autocomplete.
   - Cached festival rules and user alarm preferences.
3. **State Management & Reactive UI:**
   - Single source of truth for active location, date, language, and mode.
   - Zero-lag transitions between Basic and Pro modes.
4. **Motion & Visual Craft (`flutter-animations`):**
   - CustomPainter shaders for celestial breathing aura and glowing astrolabe ring.
   - Physics-based spring sliders for time seeking.
   - Seamless shared-axis transitions between calendar days and detail sheets.
