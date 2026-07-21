# iScalp — MetaTrader 5 Expert Advisor Specification

A layered scalping EA for MT5 with a draggable floating control panel, automatic indicator-line placement, and magic-number isolation per symbol+timeframe.

---

## 1. Overview

The EA places multi-layer **BUY LIMIT** or **SELL LIMIT** pending orders inside a user-defined price zone bounded by a **Floor** (bottom) and a **Ceiling** (top). The user controls everything from a floating panel attached to the chart, and from draggable horizontal lines on the chart itself.

Each instance of the EA is scoped to the chart it is attached to: it must never touch orders or objects belonging to a different symbol or timeframe.

---

## 2. EA Input Configuration (set when attaching the EA)

| Input | Type | Description |
|---|---|---|
| `CutLossBuffer` | double (percent) | Buffer added beyond Floor (BUY) or Ceiling (SELL) to compute the Cut Loss line. Expressed as a percentage of the total area (Ceiling − Floor). E.g. `10` = 10% of area. |
| `StopLossMultiplier` | double | Stop Loss distance from Floor/Ceiling, expressed as a multiplier of the total area. E.g. `1.0` = 1× area beyond Floor/Ceiling. |
| `DefaultLayers` | int | Default number of layers shown in the floating panel. |
| `DefaultLotSize` | double | Default lot size per layer shown in the floating panel. |
| `MagicNumber` | long (auto) | Auto-generated from the chart's Symbol + Timeframe (see §7). Not user-editable. |

---

## 3. Floating Window (Control Panel)

Title bar: `iScalp — {Symbol} | {Timeframe}`

### 3.1 First Div — Layer Configuration

| Field | Description |
|---|---|
| **Layers** | Total number of layers (e.g. `4`). |
| **Lot/Layer** | Base lot size per layer (e.g. `0.05`). |
| **Mult/Layer** | Per-layer multiplier sequence as a dot-separated string (e.g. `1.1.2.2`). Each token applies to the corresponding layer in order. So with Lot/Layer = 0.05 and Mult = `1.1.2.2`: Layer 1 = 0.05, Layer 2 = 0.05, Layer 3 = 0.10, Layer 4 = 0.10. |
| **Total: X.XX Lot** | Read-only computed total of all layers. |

Validation: the number of multiplier tokens in `Mult/Layer` must equal `Layers`. If not, panel highlights the field red and disables the order buttons.

### 3.2 Second Div — Buy / Sell Setup

Two side-by-side columns. Both columns share the same **TP** value, which is the midpoint of the Floor↔Ceiling range (50% of area).

**BUY LIMIT column** (green theme)

| Field | Source / Formula |
|---|---|
| Floor | User input (or dragged from chart). |
| Entry | Auto-set on Floor change to `Floor + 0.25 × (Ceiling − Floor)` (default 25%). User-editable & draggable. |
| Cut Loss | `Floor − (CutLossBuffer% × area)` |
| Stop Loss | `Floor − (StopLossMultiplier × area)` |
| TP | `Floor + 0.5 × area` (midpoint) |
| **BUY LIMIT** button | Places all layer orders. |

**SELL LIMIT column** (red theme)

| Field | Source / Formula |
|---|---|
| Ceiling | User input (or dragged from chart). |
| Entry | Auto-set on Ceiling change to `Ceiling − 0.25 × area` (default 25%). User-editable & draggable. |
| Cut Loss | `Ceiling + (CutLossBuffer% × area)` |
| Stop Loss | `Ceiling + (StopLossMultiplier × area)` |
| TP | `Floor + 0.5 × area` (same midpoint) |
| **SELL LIMIT** button | Places all layer orders. |

> `area = Ceiling − Floor`. All formulas above mirror around Floor for BUY and Ceiling for SELL.

### 3.3 Third Div — Order Management Buttons

| Button | Action |
|---|---|
| **CLOSE ALL POSITIONS ({n})** | Closes every open market position with this magic number. `{n}` = current count. |
| **DELETE PO BUY ({n})** | Deletes all pending BUY (limit/stop) orders with this magic number. `{n}` = current count. |
| **DELETE PO SELL ({n})** | Deletes all pending SELL orders with this magic number. `{n}` = current count. |
| **DELETE ALL PENDING ORDERS ({n})** | Deletes every pending order with this magic number. `{n}` = total. |

Counts must refresh live (on `OnTick` and `OnTimer`).

---

## 4. Order Placement Logic

When the user presses **BUY LIMIT** (or **SELL LIMIT**):

1. Validate the panel state (Floor < Entry < TP < Ceiling for BUY; mirrored for SELL).
2. Compute lot size per layer: `lot[i] = LotPerLayer × Mult[i]`.
3. Compute layer prices spread **evenly between Floor and Entry** for BUY (or Entry and Ceiling for SELL):
   - Let `N = Layers`.
   - `step = (Entry − Floor) / (N − 1)` (BUY) or `(Ceiling − Entry) / (N − 1)` (SELL).
   - Layer 1 = Entry, Layer N = Floor (BUY); reverse for SELL.
   - Edge case: if `N == 1`, place a single layer at Entry.
4. Submit `N` `ORDER_TYPE_BUY_LIMIT` (or `SELL_LIMIT`) orders, each with the panel's TP and Stop Loss.
5. All orders carry the chart-derived magic number (§7).

Cut Loss is **not** sent to the broker — it is a soft, EA-monitored level (see §6).

---

## 5. Chart Indicator Lines

The EA must draw and maintain these horizontal chart objects (`OBJ_HLINE` or `OBJ_TREND` with horizontal anchors):

| Line | Color | Style | Selectable (draggable) |
|---|---|---|---|
| BUY Floor | Green | Solid | ✅ |
| BUY Entry | Green | Solid | ✅ |
| BUY Cut Loss | Red | Dotted | ❌ (auto-derived) |
| BUY Stop Loss | Red | Solid | ❌ (auto-derived) |
| BUY TP | Green | Dashed | ❌ (auto-derived) |
| SELL Ceiling | Red | Solid | ✅ |
| SELL Entry | Red | Solid | ✅ |
| SELL Cut Loss | Red | Dotted | ❌ (auto-derived) |
| SELL Stop Loss | Red | Solid | ❌ (auto-derived) |
| SELL TP | Red | Dashed | ❌ (auto-derived) |

### 5.1 Drag-to-update

Floor, Ceiling, and Entry lines are user-draggable. On `CHARTEVENT_OBJECT_DRAG`:

1. Read the new price from the dragged object.
2. Update the floating panel field accordingly.
3. **Recompute** dependent fields (Entry default, Cut Loss, Stop Loss, TP) and redraw their lines.
4. If Floor or Ceiling is dragged, re-apply the 25% rule to Entry **only if the user has not manually moved Entry** (otherwise preserve their custom Entry; track this with a flag).

### 5.2 First-input behavior

When the user types a Floor price and presses Enter (and Ceiling is already set, or vice versa), the EA auto-fills Entry using the 25% default and draws all dependent lines.

---

## 6. Cut Loss vs Stop Loss

Two distinct exit mechanisms. **Both must respect the magic number.**

### Stop Loss
- Sent to the broker as the order's native SL.
- Triggers immediately on touch (broker-side execution).
- Applies to both pending and active positions.

### Cut Loss
- **Not** sent to the broker — managed entirely by the EA.
- Evaluated only on **bar close** (use `iTime(_Symbol, _Period, 0)` change detection in `OnTick`, or run logic in `OnTimer` after detecting a new bar).
- For each open position with this magic number:
  - BUY: if `Close[1] <= CutLoss`, close the position at market.
  - SELL: if `Close[1] >= CutLoss`, close the position at market.
- For pending orders: optionally cancel them on bar close if price has crossed Cut Loss (confirm desired behavior).

---

## 7. Magic Number Strategy

Magic number is auto-derived from `_Symbol` + `_Period` so two iScalp instances on different charts never interfere.

Recommended deterministic formula:

```
magic = 79000000 + (CRC16(_Symbol) << 8) + PeriodCode(_Period)
```

Where:
- `79000000` is a fixed iScalp prefix to avoid collisions with other EAs.
- `CRC16(_Symbol)` is a 16-bit hash of the symbol string (deterministic, collision-resistant within a single broker's symbol list).
- `PeriodCode` maps M1=1, M2=2, M5=5, M15=15, ... H1=60, etc. (matches MT5 enum values).

**Every** order operation (place, modify, close, delete) and **every** chart object name created by the EA must include or filter by this magic number. Object names should be prefixed, e.g. `iScalp_{magic}_BUY_FLOOR`.

---

## 8. Behavior Notes & Edge Cases

- **Multi-instance safety**: never read or modify orders/objects whose magic number doesn't match. Use `PositionGetInteger(POSITION_MAGIC)` and `OrderGetInteger(ORDER_MAGIC)` filtering.
- **Layer = 1**: place a single order at Entry, ignore Floor for layer pricing (still draw the Floor line).
- **Invalid zones**: if Floor >= Ceiling (or any inversion), disable order buttons and show a red border on the panel.
- **Symbol stops level**: validate that Stop Loss respects `SYMBOL_TRADE_STOPS_LEVEL` before sending; show a panel warning if too tight.
- **Lot rounding**: round each layer lot to `SYMBOL_VOLUME_STEP` and clamp to `SYMBOL_VOLUME_MIN`/`MAX`.
- **Persistence**: panel field values should survive timeframe changes (save to global variables keyed by magic number, restore on `OnInit`).
- **Cleanup on detach**: `OnDeinit` should remove all chart objects belonging to this magic, but **not** close orders (user may want them to live on).

---

## 9. Suggested File Structure

```
iScalp/
├── iScalp.mq5                   # Main EA entry (OnInit, OnTick, OnDeinit, OnChartEvent, OnTimer)
├── Include/
│   ├── iScalp_Panel.mqh         # Floating panel UI (CDialog-based)
│   ├── iScalp_Lines.mqh         # Chart line draw/update/drag handlers
│   ├── iScalp_Orders.mqh        # Layer calculation + order placement + management
│   ├── iScalp_Risk.mqh          # Cut Loss monitor + Stop Loss validation
│   └── iScalp_Magic.mqh         # Magic number derivation + filters
└── README.md
```

Use the standard MT5 `<Controls/Dialog.mqh>` library for the panel, or build directly with `OBJ_BUTTON` + `OBJ_EDIT` if the standard library feels too rigid.

---

## 10. Open Items to Confirm in Implementation

These were not fully nailed down — re-check during build:

1. **Cut Loss formula on screenshot reverse-check**: With Floor=4695.67, area=13.03, BUY CL=4694.37 → buffer ≈ 10%. Confirm `CutLossBuffer` default in EA inputs.
2. **Stop Loss formula on screenshot reverse-check**: BUY SL=4683.13 → ≈ 0.96× area. Likely `StopLossMultiplier = 1.0` default with rounding. Confirm.
3. **Pending-order behavior on Cut Loss bar close**: cancel pending orders too, or only close active positions?
4. **Entry "manual override" flag persistence**: after user drags Entry, does dragging Floor/Ceiling later reset Entry to 25% default, or keep the user's custom offset proportionally?
5. **TP behavior**: TP is shared between BUY and SELL columns — confirm both order sides target the same midpoint, or whether each side should have its own TP that just defaults to midpoint.
6. **Multiple BUY/SELL setups**: can the user place BUY and SELL layered orders simultaneously on the same chart? (Spec assumes yes — they share area but use independent magic-suffixed object names like `BUY_*` and `SELL_*`.)

---

## 11. Quick Reference — Formulas

```
area            = Ceiling - Floor

BUY:
  Entry         = Floor + 0.25 * area      (default; user-draggable)
  CutLoss       = Floor - (CutLossBuffer/100) * area
  StopLoss      = Floor - StopLossMultiplier * area
  TP            = Floor + 0.5 * area

SELL:
  Entry         = Ceiling - 0.25 * area    (default; user-draggable)
  CutLoss       = Ceiling + (CutLossBuffer/100) * area
  StopLoss      = Ceiling + StopLossMultiplier * area
  TP            = Floor + 0.5 * area

Layers (BUY):
  step          = (Entry - Floor) / (Layers - 1)
  price[i]      = Entry - i * step          for i = 0..Layers-1

Layers (SELL):
  step          = (Ceiling - Entry) / (Layers - 1)
  price[i]      = Entry + i * step          for i = 0..Layers-1

Lot per layer:
  lot[i]        = LotPerLayer * Mult[i]
```