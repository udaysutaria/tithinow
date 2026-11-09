# 🎨 TithiNow — Design System & UI Architecture (v2)

## 1. Design Philosophy
- **Actionable over Informational:** Instead of passive charts, emphasize "What is happening right now?" and "What do I need to do?"
- **Calm Vedic Modernism:** Clean, uncluttered, contemporary dark aesthetic with warm sacred accents (saffron, gold, copper) rather than overwhelming bright reds and yellows.
- **Glanceable Hierarchy:** Live countdowns, clear status pills, and prominent single-action buttons.

---

## 2. Typography
- **Primary Display & Headings:** `Sora` (Weights: 400 Regular, 600 SemiBold)
- **Body & Secondary Data:** `Inter` (Weights: 400 Regular, 600 SemiBold)

---

## 3. Color Palette
- **Background (Dark Default):** `#121414` / `#1A1D1E`
- **Surface / Card Background:** `#222627` / `#2A2F30`
- **Primary Accent (Saffron/Gold):** `#FF9933` / `#E5A93C`
- **Secondary Accent (Divine Glow / Moonlight):** `#FFE082` / `#ECEFF1`
- **Text Primary:** `#FFFFFF` (High emphasis)
- **Text Secondary:** `#A0A6A8` (Medium emphasis)
- **Status Indicators:**
  - *Shubh / Auspicious (Amrit, Shubh, Labh):* `#4CAF50` (Green)
  - *Samanya / Neutral (Char):* `#2196F3` (Blue)
  - *Ashubh / Inauspicious (Rahu Kaal, Rog, Kaal, Udveg):* `#E57373` (Soft Red)

---

## 4. Key Components (Atomic Design)
- **Molecules:**
  - `CardPanchang` — Current day summary card.
  - `CardCountdown` — Live active Muhurat / Choghadiya progress bar and timer.
  - `ListItemTithi` — Date, Tithi name, Paksha, start/end time.
  - `ModalSetAlarm` — Time picker and sound preview for one-tap reminder.
- **Organisms:**
  - `AppHeader` — Location switcher, date picker, search.
  - `ListTithis` — Filterable scrollable list of tithis and festivals.

---

## 5. Screen Flow
1. **Splash Screen:** Fast warmup & location load.
2. **Today (Home Screen):** Live countdown timer, current Tithi, ongoing Choghadiya.
3. **Panchang / Calendar View:** Monthly & weekly browseable calendar.
4. **Detail Views:** Deep dive into specific Muhurat, Festival, or Vrat.
5. **Settings & Location:** City search (7,100+ cities), alarm sounds, language selection.
