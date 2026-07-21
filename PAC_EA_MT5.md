# PAC (Pivot and Control) Expert Advisor — MT5 Development Specification

## Overview

**Strategy Name:** PAC — Pivot and Control
**Best Timeframes:** M1, M2, M5 (configurable via input)
**Order Type:** Limit Orders (layered)
**Core Logic:** Identify a "Pivot" candle that validates a "Control" zone (Rally Base Rally or Drop Base Drop), then place layered limit orders within the base area.

---

## Input Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `Timeframe` | ENUM_TIMEFRAMES | PERIOD_M5 | Trading timeframe (M1, M2, M5) |
| `MaxLayers` | int | 5 | Max limit order layers (4–6) |
| `AggressiveMode` | bool | false | Allow entry even after 3+ pivot bounces if base < 70% consumed |
| `BaseConsumeThreshold` | double | 70.0 | % of base area consumed before blocking aggressive entries |
| `MaxPivotBounces` | int | 3 | Max bounces allowed before entry is blocked (default: 3) |
| `MinPivotBounces` | int | 1 | Min bounces required before entry is allowed |
| `LotSize` | double | 0.01 | Lot size per layer |
| `MagicNumber` | int | 202500 | Unique EA magic number |
| `Slippage` | int | 3 | Max slippage in points |

---

## Core Concepts

### 1. Pivot Candle

A **Pivot** is a single candle with the **longest tail/body ratio** (the most dominant wick relative to body) in a local swing.

**Validation rules:**
- The pivot candle must be **followed by 3 candles moving in the same direction** (e.g., bullish pivot → 3 net-bullish candles after it).
- The 3 following candles **do not need to be consecutive** in color. Example: `Green, Red, Green, Green` is valid — as long as the net direction continues and the pivot candle remains the highest/lowest point.
- The pivot acts as **proof** that a Control zone (base) is valid.

**Pivot detection logic (pseudocode):**
```
For each candle[i]:
  tailRatio = (High[i] - Low[i]) / Max(Body[i], 1 pip)
  if tailRatio > threshold AND isLocalExtreme(i):
    candidatePivot = candle[i]
    count = 0
    for j = i+1 to i+10:  // look ahead window
      if direction(candle[j]) == pivotDirection:
        count++
      if count >= 3:
        confirmPivot(candidatePivot)
        break
```

---

### 2. Control Zone (Base)

A **Control** is a consolidation base between two impulse legs. It forms one of two patterns:

#### Rally Base Rally (RBR) — Bullish Setup
```
  ↑ Impulse Up (Rally)
  ───────────────────  ← Ceiling  (top of base)
  │   Base / Consolidation        │
  ───────────────────  ← Floor    (bottom of base = BUY ENTRY START)
  ↑ Impulse Up (Rally)
```

- **Ceiling** = top of the base candles
- **Floor** = bottom of the base candles
- Entry direction: **BUY**
- Limit orders placed from Floor upward in layers

#### Drop Base Drop (DBD) — Bearish Setup
```
  ↓ Impulse Down (Drop)
  ───────────────────  ← Ceiling  (top of base = SELL ENTRY START)
  │   Base / Consolidation        │
  ───────────────────  ← Floor    (bottom of base)
  ↓ Impulse Down (Drop)
```

- **Ceiling** = top of the base candles (SELL ENTRY START)
- **Floor** = bottom of the base candles
- Entry direction: **SELL**
- Limit orders placed from Ceiling downward in layers

**Base detection logic (pseudocode):**
```
Scan for 2+ consecutive candles with:
  - Small body relative to surrounding impulse candles
  - Low ATR / low volatility
  - Bounded within a defined price range

Preceding impulse direction == Following impulse direction → valid RBR or DBD
```

---

### 3. Pivot Bounce Count

Each time price returns to the Control zone and **reacts (bounces) without breaking through**, the bounce counter increments.

| Bounce Count | Status | Entry Allowed? |
|---|---|---|
| 0 | Unvalidated | ❌ No |
| 1–2 | Valid | ✅ Yes |
| 3 | Aggressive | ⚠️ Only if `AggressiveMode = true` AND base < 70% consumed |
| 4+ | Exhausted | ❌ No (zone invalidated) |

**Zone Consumed % formula:**
```
For RBR (BUY):
  consumed% = (Ceiling - CurrentPrice) / (Ceiling - Floor) * 100

For DBD (SELL):
  consumed% = (CurrentPrice - Floor) / (Ceiling - Floor) * 100
```

If `consumed% >= BaseConsumeThreshold (70%)` AND bounce count >= 3 → **block new orders** regardless of AggressiveMode.

---

## Order Placement

### Layer Distribution

Limit orders are spread **evenly across the entry zone**:

**RBR (BUY) — Entry zone: Floor to Ceiling**
```
Layer 1 (lowest): at Floor
Layer 2: Floor + (Ceiling - Floor) / (MaxLayers - 1) * 1
Layer 3: Floor + (Ceiling - Floor) / (MaxLayers - 1) * 2
...
Layer N: at Ceiling (topmost BUY limit)
```

**DBD (SELL) — Entry zone: Floor to Ceiling**
```
Layer 1 (highest): at Ceiling
Layer 2: Ceiling - (Ceiling - Floor) / (MaxLayers - 1) * 1
...
Layer N: at Floor (lowest SELL limit)
```

### Take Profit (TP)

- **TP location** = 50% of the total zone height, measured from the entry side outward (beyond the base, into profit territory).
- Formula for RBR BUY:
  ```
  ZoneHeight = Ceiling - Floor
  TP = Ceiling + (ZoneHeight * 0.50)
  ```
- Formula for DBD SELL:
  ```
  ZoneHeight = Ceiling - Floor
  TP = Floor - (ZoneHeight * 0.50)
  ```

**TP Adjustment Rule:**
- If a **new RBR or DBD** pattern forms between the current entry area and the initial TP target, **move TP** to the near edge of the new pattern (do not overshoot into the new base).

### Stop Loss (SL)

- SL is placed at a **1:1 ratio** relative to the TP distance:
  ```
  For RBR BUY:
    TPDistance = TP - Ceiling
    SL = Floor - TPDistance        // 1:1 from ceiling to TP, mirrored below floor
  
  For DBD SELL:
    TPDistance = Floor - TP
    SL = Ceiling + TPDistance      // 1:1 from floor to TP, mirrored above ceiling
  ```

### Cut Loss (Emergency Close)

- Triggered **only after candle close** (based on configured timeframe).
- Cut Loss trigger level:
  ```
  For RBR BUY:
    CutLossLevel = Ceiling + (Ceiling - Floor) * 0.20
    // 20% above Ceiling — if candle CLOSES above this, zone is invalid, close all BUY orders

  For DBD SELL:
    CutLossLevel = Floor - (Ceiling - Floor) * 0.20
    // 20% below Floor — if candle CLOSES below this, zone is invalid, close all SELL orders
  ```
- This is a **candle-close confirmation** check, not a hard stop — prevents premature exits from wicks.

---

## Zone Invalidation Rules

A Control zone is **invalidated** and all pending orders must be cancelled when:

1. Candle closes beyond the Cut Loss level (20% past the opposing edge of base).
2. Pivot bounce count exceeds `MaxPivotBounces` (default 3) AND `AggressiveMode = false`.
3. Base consumed% exceeds `BaseConsumeThreshold` (70%) with bounce count >= 3.
4. A new opposing pattern (e.g., DBD forming inside an RBR zone) invalidates the bias.

---

## EA Workflow (State Machine)

```
[SCAN] → Detect Pivot Candle
           ↓
       Valid Pivot?
       /         \
     No           Yes
      ↓             ↓
   [WAIT]      Detect Control Zone (RBR / DBD)
                    ↓
              Control Found?
              /           \
            No              Yes
             ↓               ↓
          [WAIT]      Count Pivot Bounces in Zone
                            ↓
                    Bounces >= MinPivotBounces (1)?
                    /                        \
                  No                          Yes
                   ↓                            ↓
                [WAIT]              Bounces > MaxPivotBounces (3)?
                                    /                         \
                                  No                          Yes
                                   ↓                            ↓
                              [PLACE ORDERS]          AggressiveMode ON
                                                      AND Base < 70% consumed?
                                                       /              \
                                                     Yes               No
                                                      ↓                 ↓
                                               [PLACE ORDERS]       [WAIT / CANCEL]

[MANAGE ORDERS]
  → Check TP adjustment (new RBR/DBD between entry and TP)
  → Check Cut Loss trigger on candle close
  → Check zone invalidation
  → Update bounce count on each return to zone
```

---

## File Structure for Claude Code

The following `.mq5` tool files are expected to support this EA:

| File | Purpose |
|---|---|
| `PAC_Main.mq5` | Main EA file — OnInit, OnDeinit, OnTick |
| `PAC_PivotDetector.mqh` | Pivot candle detection logic |
| `PAC_ControlZone.mqh` | RBR / DBD zone detection and storage |
| `PAC_OrderManager.mqh` | Limit order placement, layering, TP/SL management |
| `PAC_ZoneValidator.mqh` | Bounce counting, consumed%, invalidation checks |
| `PAC_CutLoss.mqh` | Candle-close cut loss trigger logic |
| `PAC_Display.mqh` | Chart drawing — zones, layers, labels (optional visual) |

---

## Visual Reference on Chart

The EA should draw the following objects on the MT5 chart:

- **Base Zone Rectangle** — shaded box covering Ceiling to Floor
- **Ceiling Line** — horizontal line at Ceiling price (labeled "Ceiling")
- **Floor Line** — horizontal line at Floor price (labeled "Floor")
- **TP Line** — horizontal dashed line at TP price
- **SL Line** — horizontal dashed line at SL price
- **Cut Loss Line** — horizontal dotted line at Cut Loss trigger level
- **Layer Markers** — small markers at each limit order price
- **Bounce Count Label** — text label on zone showing current bounce count (e.g., "Bounces: 2")
- **Zone Status Label** — "VALID", "AGGRESSIVE", or "EXHAUSTED"

---

## Notes for Claude Code Implementation

1. **Timeframe input** must restrict to M1, M2, M5 only — reject other values on `OnInit()` with an alert.
2. **Pivot tail ratio threshold** should be tunable — suggested default: tail >= 2× body size.
3. **Base candle criteria** — suggested: body < 30% of average surrounding impulse candle bodies, and range contained within a ±5 pip band (adjustable).
4. **Bounce detection** — price must enter the zone AND close back out (not break through) to count as a bounce.
5. **Cut Loss is NOT the same as SL** — SL is a hard order-level stop; Cut Loss is a candle-close logic check in `OnTick()` watching for confirmed closed candles.
6. **AggressiveMode toggle** should be clearly visible in the EA input panel with a warning comment.
7. All pending orders placed by the EA must carry the `MagicNumber` for identification.
8. On EA removal or terminal restart, existing orders should persist (do not auto-cancel on deinit unless explicitly toggled).

---

*This document is intended as the strategy specification input for Claude Code to generate the corresponding `.mq5` implementation files.*
