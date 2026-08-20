# FIELD — Implementation Plan

**A dense, monochrome analog dashboard watch face for Amanda's Garmin Venu 4 (45 mm).**

This plan turns the design handoff into a concrete Connect IQ build. It is organized so you can work top-to-bottom: finish the toolchain, scaffold the project, lay down the geometry, then add complications in the order the design doc specifies. Where an API detail needs live confirmation in the simulator, it's flagged as **⚠ confirm**.

---

## 1. Target device & hard constraints

| Property | Value | Why it matters |
|---|---|---|
| Device | Venu 4, 45 mm (SDK id `venu4`) | Amanda's watch. The 41 mm 4S is `venu4s` at 390×390 — not our target. |
| Resolution | **454 × 454 px**, round | Every coordinate in this plan is computed for this. Center is **(227, 227)**. |
| Display | AMOLED, 2000 nits, Gorilla Glass | Blacks are true off-pixels — perfect for the near-black background (saves power too). |
| Always-on mode | Supported | Requires a low-power render path (§6). Second hand and rings behave differently here. |
| Firmware platform | Unified with Fenix 8 / FR 570 / 970 | Modern Connect IQ (System 8 / API 5.x). Newer graphics features (anti-aliasing) are available. |
| Connect IQ | Up to 4 CIQ data fields | Not directly relevant to a watch face, but confirms it's a current-gen CIQ device. |

**Radius budget** (from center, 227 px available to the edge). These are starting values — you'll tune them in the simulator:

| Element | Radius (px) | Notes |
|---|---|---|
| Screen edge | 227 | Leave ~4–6 px safe margin; round bezels clip corners. |
| Minute-tick ring | ~215–222 | Outermost. Ticks point inward. |
| Outer data ring (weather/sun/battery labels) | ~185–205 | Radial text clusters at 12/3/6/9. |
| Step-progress arc | ~150–165 | Thin arc, sweeps clockwise from 12. |
| Hour-tick ring | ~140–155 | Inside the step arc. |
| Hand sweep (minute) | ~130 | Minute hand tip. |
| Hand sweep (hour) | ~85 | Hour hand tip (shorter). |
| Inner label cluster (HR, steps, mi) | 0–70 | Text stacked near center, below/around the hands. |

---

## 2. Finish the toolchain (SDK is installed ✅)

You've got the SDK. Remaining setup before you can build:

1. **VS Code + Monkey C extension.** Install VS Code, then the official **Monkey C** extension (publisher: Garmin) from the marketplace. It provides the New Project / Edit Products / Build for Device commands referenced in the Garmin guide.
2. **Point the extension at the SDK.** First time you run a Monkey C command it asks for the SDK path — point it at the SDK you installed (or use the **Connect IQ SDK Manager** to set the active SDK).
3. **Confirm the Venu 4 device files are present.** The Venu 4 shipped Sept 2025, so it only exists in recent SDKs. Open the **SDK Manager → Devices** and make sure `venu4` (and `venu4s`) are downloaded. If they're missing, update to the latest SDK — otherwise the device won't appear in the simulator or in Edit Products.
4. **Generate a developer key.** Watch faces must be signed. Create one with:
   ```
   openssl genrsa -out developer_key.der -outform DER 4096
   ```
   Then in VS Code run **Monkey C: Verify Installation** / set the key path in settings (`monkeyC.developerKeyPath`). Keep this key file safe and backed up — re-signing with a different key later makes it a "different" app.
5. **(Optional, only if publishing) Connect IQ developer account** at apps.garmin.com. Not needed for sideloading to Amanda's watch.

---

## 3. Scaffold the project

Use **Monkey C: New Project** (`Cmd+Shift+P`):

- **Name:** `FIELD`
- **Type:** Watch Face
- **Template:** Simple (gives you an `App` + `View` skeleton to gut)
- **Minimum API level:** The Garmin tutorial defaults to 3.2.0. Since we target **only** the Venu 4, set this higher (e.g. **5.0.0** if the wizard offers it) so you can freely use current graphics APIs like anti-aliased drawing. There's no compatibility cost because we're not supporting older watches. **⚠ confirm** which levels the wizard lists; pick the highest the Venu 4 supports.
- **Parent directory:** `/Users/moarwaffles/dev/FIELD`

Then **Monkey C: Edit Products** → select **Venu 4** only (uncheck everything else). This keeps builds fast and the simulator honest to the real screen.

---

## 4. File & code structure

```
FIELD/
├─ manifest.xml            # app id, type=watchface, products=[venu4], min-api
├─ monkey.jungle           # build config (source/resource paths)
├─ developer_key.der       # signing key (git-ignore this)
├─ resources/
│  ├─ drawables/
│  │  └─ launcher_icon.png # store/menu icon
│  ├─ fonts/               # optional custom numeric font (see §8)
│  ├─ layouts/             # we'll mostly draw in code, not layout XML
│  └─ strings/strings.xml
└─ source/
   ├─ FieldApp.mc          # AppBase — entry point, returns the view
   ├─ FieldView.mc         # WatchFace — all rendering lives here
   ├─ Geometry.mc          # polar→cartesian helpers, tick/hand math
   ├─ Palette.mc           # the grayscale constants + state accents
   └─ data/
      ├─ DataProvider.mc   # pulls steps/HR/battery/weather/etc. once per draw
      └─ Complications.mc  # small draw routines per metric
```

Rationale: because the design is heavily custom radial drawing (not boxes), you'll get almost nothing from layout XML. Draw everything imperatively in `FieldView.onUpdate(dc)` using `dc` primitives and trig. Keeping geometry math and the palette in their own files keeps `onUpdate` readable.

---

## 5. Geometry: the math you'll reuse everywhere

Center `cx = cy = 227`. For any element at clock angle, convert "clock units" to screen coordinates. Screen angle 0° is 3 o'clock and increases counter-clockwise, so for a **12-o'clock-up clock** use:

```
// minuteOrHourFraction in [0,1) where 0 = 12 o'clock, 0.25 = 3 o'clock
function polar(cx, cy, radius, fraction) {
    var theta = (fraction * 2 * Math.PI) - (Math.PI / 2); // rotate so 0 = top
    return [ cx + radius * Math.cos(theta),
             cy + radius * Math.sin(theta) ];
}
```

Use this single helper for: the 60 minute ticks (`fraction = i/60`), the 12 hour ticks (`i/12`), radial label anchor points at 12/3/6/9 (`0, .25, .5, .75`), the step-progress arc endpoints, and each hand tip.

**Hands** are best drawn as filled polygons (a tapered quad + a small counterweight past center), rotated to the hand's fraction, then `dc.fillPolygon(points)`. Enable `dc.setAntiAlias(true)` for clean edges (**⚠ confirm** supported on Venu 4 — it is on modern devices). Compute hand fractions from `Time.Gregorian.info`:

- hour hand fraction = `((hour % 12) + minute/60) / 12`
- minute hand fraction = `(minute + second/60) / 60`
- second hand fraction = `second / 60`

**Step-progress arc:** `dc.drawArc(cx, cy, radius, Graphics.ARC_CLOCKWISE, startDegrees, endDegrees)`. Start at 90° (top) and sweep by `360 * min(steps/stepGoal, 1)`. Note `drawArc` uses its own degree convention (0 = 3 o'clock, CCW positive) — **⚠ confirm** direction in the sim and adjust the start/sweep signs.

---

## 6. Rendering strategy & power (the part that makes or breaks it)

Connect IQ gives a `WatchFace` three key hooks:

- **`onUpdate(dc)`** — full redraw. Called once per minute in normal (high-power) view, plus once per second while the watch is "awake" (wrist raised). Draw *everything* here: background, ticks, rings, complications, all three hands.
- **`onPartialUpdate(dc)`** — called ~once per second in **low-power/always-on** mode. This is the *only* place a live second hand can move when the wrist is down. It runs under a strict **power budget**; exceed it and the system throws `PowerBudgetExceeded` and disables partial updates. So in `onPartialUpdate` you must:
  - Set a tight clip region around just the second-hand sweep (`dc.setClip`) so you repaint the smallest possible area.
  - Redraw only the second hand (and restore the pixels it previously covered).
  - Keep pixel count minimal — a thin second hand, not the rings.
- **`onEnterSleep()` / `onExitSleep()`** — toggle a `mInLowPower` flag. Use it to decide what `onUpdate` draws.

**Always-on / burn-in design (Venu is AMOLED):**

- Check `System.getDeviceSettings().requiresBurnInProtection`. When true (always-on displays), the design doc's dense face must **simplify**: draw a dimmer, thinner variant — e.g. hide the sweeping second hand, drop the fine 1-minute ticks, render text in a darker gray, and keep lit-pixel coverage low. Consider a 1–2 px positional jitter each minute to avoid static burn-in.
- True-black `#000000` background is free power on AMOLED — lean into it (matches the design anyway).

**Recommended two-mode plan:**

| Mode | Trigger | What's drawn |
|---|---|---|
| **Full** | wrist up / high-power | Everything: rings, all complications, sweeping second hand, fine ticks. |
| **Ambient** | `mInLowPower` / burn-in required | Hour + minute hands, hour ticks, HR + steps + time-critical labels only, dimmed grays, no second hand (or a minimal ticking one via `onPartialUpdate`). |

Decide early whether Amanda wants a live sweeping second hand in always-on. It's the single biggest power/complexity cost. A good default: **sweeping second hand when awake, hidden when ambient.**

---

## 7. Data source → API map

Pull all of these once per `onUpdate` into a small struct, then let the draw routines read from it. Every getter can return `null` — guard each one and draw a placeholder (e.g. `--`) when data is unavailable.

| Complication | API | Notes / units |
|---|---|---|
| Time / date | `Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM)` | `.hour .min .sec .day .month .day_of_week`. Format as `18 AUG`. |
| Steps, step goal | `ActivityMonitor.getInfo()` → `.steps`, `.stepGoal` | Drives the step arc + numeric label. |
| Distance | `ActivityMonitor.getInfo().distance` | Value is **cm** → convert to mi (`/160934.4`). Respect `System.getDeviceSettings().distanceUnits` for mi vs km. |
| Heart rate (live) | `Activity.getActivityInfo().currentHeartRate` | Often `null` between reads; fall back to `ActivityMonitor.getHeartRateHistory(1,true)` latest sample. |
| Battery | `System.getSystemStats()` → `.battery` (Float %), `.charging` | Round to int for `87%`. |
| Weather (temp/hi/lo/condition) | `Toybox.Weather.getCurrentConditions()` → `.temperature`, `.highTemperature`, `.lowTemperature`, `.condition` | Temps in **°C** → convert to °F. Data comes from phone/Garmin Connect; may be `null` if not synced. **⚠ confirm** fields. |
| Sunrise / sunset | `Toybox.Weather.getSunrise(pos, time)` / `getSunset(...)` | Needs a `Position.Location`; get it from `Activity.getActivityInfo().currentLocation` or last known. **⚠ confirm** signature; otherwise compute from lat/long. |
| Floors | `ActivityMonitor.getInfo().floorsClimbed` | Tier 3. |
| Calories | `ActivityMonitor.getInfo().calories` | Tier 3. |
| Move bar | `ActivityMonitor.getInfo().moveBarLevel` | Tier 3. |
| Body Battery / Stress | via `Toybox.SensorHistory` / `ActivityMonitor` where exposed | **⚠ confirm** availability on Venu 4; may need `Toybox.UserProfile` or history iterators. Treat as stretch. |

**Permissions:** Weather and (some) sensor history require declaring permissions in `manifest.xml` (e.g. weather). Add them when you wire each feature, and re-test — the simulator can inject fake weather/HR via its **Simulation** menu.

---

## 8. Design → code translation

**Palette** (`Palette.mc`) straight from the handoff:

```
Background   0x000000
Primary      0xF0F0F0   // time-support numbers, current temp, steps
Secondary    0xB0B0B0   // heart rate, date, battery
Tertiary     0x666666   // labels, hi/lo, sunrise/sunset, fine ticks
Accent       (single reserved color, e.g. 0xFF3B30) // ONLY for alert states
```

Note AMOLED + the sim will quantize some grays; verify `0x666666` reads as intended tertiary and isn't crushed to black.

**Typography.** Built-in system fonts (`Graphics.FONT_TINY/XTINY/SMALL/MEDIUM/LARGE/NUMBER_*`) are the fast path and cover the three-weight hierarchy loosely (size ≈ weight). For the "beautiful analog + dense data" look you'll likely want a **custom bitmap font** for the numerics (one clean condensed family, a couple of sizes) placed in `resources/fonts/` and referenced from `resources/fonts.xml`. Start with system fonts for the MVP; swap to a custom font during the §later refinement pass. Avoid all-caps labels except at the smallest sizes (per the doc).

**The five layers**, drawn back-to-front in `onUpdate`:

1. Fill background `#000000`.
2. Minute + hour tick system (60 minute ticks; every 5th heavier; 12 hour ticks heaviest; optional stronger 12/3/6/9).
3. Data rings + radial label clusters: step-progress arc, and the radial text at 12 (weather), 3 (battery), 6 (date), 9 (sunrise/sunset).
4. Inner label cluster near center: `♥ 72`, `8,421`, `3.8 mi` — stacked so they don't collide with the hands.
5. Hands last, on top of everything: hour, minute, then thin second hand + small counterweight + center cap.

---

## 9. MVP build order (mapped to milestones)

Follow the handoff's order — get the clock + radial geometry beautiful first, then treat complications as data placement. Each milestone should compile and run in the sim before moving on.

1. **M0 — Skeleton:** black background, prints time as text. Confirms build/sign/sim loop works on `venu4`.
2. **M1 — Tick system:** 60 minute + 12 hour ticks via `polar()`. Tune radii/weights.
3. **M2 — Hands:** hour/minute/second polygons, correct fractions, center cap. This is the "looks like a real analog watch" moment.
4. **M3 — Heart-rate + step ring:** step-progress arc + `♥ HR` and `steps` labels wrapped around center.
5. **M4 — Steps + distance** numeric cluster (5–7 o'clock).
6. **M5 — Date** at 6 o'clock (`18 AUG`).
7. **M6 — Weather:** current temp at 12 o'clock; then hi/lo beneath.
8. **M7 — Battery** at 3 o'clock.
9. **M8 — Sunrise/sunset** at 9 o'clock (with tiny sun/moon glyphs).
10. **M9 — Additional metrics** (floors/calories/Body Battery/stress) — only if geometry still reads calmly.
11. **M10 — Dynamic activity arc** states (progress fill, goal-complete pulse/invert — subtle).
12. **M11 — Ambient/always-on variant** (§6) + power-budget tuning for the second hand.
13. **M12 — Refinement pass:** custom font, pixel spacing, symmetry, grayscale tuning, burn-in jitter.

---

## 10. Testing & verification

- **Simulator first.** Run **Run Without Debugging** → pick Venu 4. Use the sim's **Simulation** menu to inject heart rate, steps, battery %, weather, time-of-day, and to toggle **low-power/always-on** so you actually exercise `onPartialUpdate` and the ambient variant.
- **Check the power budget.** In the sim, watch for `PowerBudgetExceeded` when the second hand runs in low power. If it fires, shrink the clip region / thin the hand.
- **Round-screen clipping.** Verify nothing important lands in the corners the round bezel eats.
- **Null-data pass.** Force weather/HR/location to null in the sim and confirm every complication degrades gracefully (`--`), no crashes.
- **On-device sideload.** **Monkey C: Build for Device** → `venu4` → copy the generated `.PRG` to the watch's `GARMIN/APPS` directory over USB. Confirm real HR/steps/weather populate and check battery drain over a day (especially with always-on).

---

## 11. Risks & things to confirm early

- **Second hand in always-on** is the main power/complexity risk. Decide the default behavior before M2 so the architecture accounts for it.
- **Weather/sunrise APIs** (`Toybox.Weather` fields, `getSunrise/getSunset` signatures) — confirm in the API docs for the installed SDK; they've evolved. Sunrise/sunset may require computing from position if the direct getters aren't present.
- **Body Battery / stress / training readiness** exposure to watch faces is inconsistent across devices/SDKs — treat all Tier-3 metrics as stretch goals, not MVP.
- **Custom font licensing** — if you ship a non-system font, make sure it's licensed for redistribution (relevant only if you ever publish to the store).
- **Legibility of dense grayscale** — the "ridiculous amount of data" goal fights glanceability. Lean on the Tier-1/2/3 hierarchy hard; it's easy to make it noisy.

---

## 12. Distribution

For Amanda's watch you only need **sideloading** (§10) — no store account required. If you later want over-the-air install / updates, you'd publish to the Connect IQ Store (needs a developer account and the same signing key). Keep `developer_key.der` backed up; losing it means you can't push updates to the same app id.

---

*Sources: Garmin Connect IQ developer docs (Toybox.Weather, WatchFace class, compatible devices), Garmin Venu 4 specifications (garminrumors wiki / Garmin product pages), and Connect IQ developer forum threads on onPartialUpdate power budgets and always-on rendering.*
