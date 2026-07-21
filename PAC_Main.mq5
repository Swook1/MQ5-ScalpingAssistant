//+------------------------------------------------------------------+
//| PAC_Main.mq5 — PAC (Pivot and Control) Expert Advisor — MT5      |
//| Author: RayyanGanteng                                             |
//+------------------------------------------------------------------+
#property copyright "RayyanGanteng"
#property version   "1.0"
#property strict

#include "Include/PAC_PivotDetector.mqh"
#include "Include/PAC_ControlZone.mqh"
#include "Include/PAC_ZoneValidator.mqh"
#include "Include/PAC_OrderManager.mqh"
#include "Include/PAC_CutLoss.mqh"
#include "Include/PAC_Display.mqh"

//--- Inputs (restricted to M1, M2, M5 only — validated in OnInit)
input ENUM_TIMEFRAMES Timeframe             = PERIOD_M5;   // Trading timeframe (M1/M2/M5 only)
input int             MaxLayers            = 5;            // Max limit order layers (4–6)
input bool            AggressiveMode       = false;        // WARNING: allows entry after 3+ bounces if base < 70% consumed
input double          BaseConsumeThreshold = 70.0;         // % of base consumed before blocking aggressive entries
input int             MaxPivotBounces      = 3;            // Max bounces before entry blocked
input int             MinPivotBounces      = 1;            // Min bounces required before entry allowed
input double          LotSize              = 0.01;         // Lot size per layer
input int             MagicNumber          = 202500;       // EA magic number
input int             Slippage             = 3;            // Max slippage in points
input double          PivotTailRatio       = 2.0;          // Pivot: range >= N × body
input double          BaseFraction         = 0.30;         // Base body < N × avg impulse body
input double          BaseRangePips        = 5.0;          // Base zone max width in pips

//--- EA globals
ControlZone g_zone;
int         g_bounceCount;
bool        g_ordersPlaced;
bool        g_inZone;
datetime    g_lastBar;
EAState     g_state;

//--- GlobalVariable key prefix
string GK(const string s) { return "PAC_" + IntegerToString(MagicNumber) + "_" + s; }

void SavePACState()
{
   GlobalVariableSet(GK("state"),   (double)g_state);
   GlobalVariableSet(GK("ztype"),   (double)g_zone.type);
   GlobalVariableSet(GK("ceil"),    g_zone.ceiling);
   GlobalVariableSet(GK("floor"),   g_zone.floor);
   GlobalVariableSet(GK("active"),  g_zone.active ? 1 : 0);
   GlobalVariableSet(GK("bounces"), (double)g_bounceCount);
   GlobalVariableSet(GK("placed"),  g_ordersPlaced ? 1 : 0);
   GlobalVariableSet(GK("inZone"),  g_inZone ? 1 : 0);
}

void LoadPACState()
{
   if(!GlobalVariableCheck(GK("state"))) return;
   g_state         = (EAState)(int)GlobalVariableGet(GK("state"));
   g_zone.type     = (PAC_ZoneType)(int)GlobalVariableGet(GK("ztype"));
   g_zone.ceiling  = GlobalVariableGet(GK("ceil"));
   g_zone.floor    = GlobalVariableGet(GK("floor"));
   g_zone.active   = (GlobalVariableGet(GK("active")) != 0);
   g_bounceCount   = (int)GlobalVariableGet(GK("bounces"));
   g_ordersPlaced  = (GlobalVariableGet(GK("placed")) != 0);
   g_inZone        = (GlobalVariableGet(GK("inZone")) != 0);
}

void ResetZone()
{
   g_zone.active   = false;
   g_zone.type     = ZONE_NONE;
   g_zone.ceiling  = 0;
   g_zone.floor    = 0;
   g_bounceCount   = 0;
   g_ordersPlaced  = false;
   g_inZone        = false;
   PAC_ClearDisplay(MagicNumber);
}

void InvalidateZone(bool closeTrades)
{
   if(closeTrades)
      PAC_CloseAllPositions(MagicNumber);
   PAC_DeleteAllPending(MagicNumber);
   ResetZone();
   g_state = STATE_SCAN;
}

//---
void ScanForSetup()
{
   PivotInfo piv;
   piv.confirmed = false;
   if(!PAC_FindPivot(Timeframe, 100, PivotTailRatio, piv)) return;

   ControlZone zone;
   zone.active = false;
   if(!PAC_DetectZone(Timeframe, 1, 100, BaseFraction, BaseRangePips, zone)) return;

   // Pivot direction must match zone type
   if(piv.isBullish && zone.type != ZONE_RBR) return;
   if(!piv.isBullish && zone.type != ZONE_DBD) return;

   // Pivot must be related to the zone (its extreme within ±50% zone height of zone boundary)
   double tol = (zone.ceiling - zone.floor) * 0.5;
   if(zone.type == ZONE_RBR && MathAbs(piv.low - zone.floor)    > tol) return;
   if(zone.type == ZONE_DBD && MathAbs(piv.high - zone.ceiling)  > tol) return;

   g_zone = zone;
   g_state = STATE_WAIT_BOUNCE;
   PAC_DrawZone(MagicNumber, Timeframe, g_zone, g_bounceCount, MaxLayers);
   SavePACState();
}

void CheckBounces()
{
   int result = PAC_CheckBounce(Timeframe, g_zone, g_inZone);

   if(result == -1)
   {
      // Zone broken — cancel pending, close positions, reset
      InvalidateZone(true);
      return;
   }
   if(result == 1)
   {
      g_bounceCount++;
      PAC_DrawZone(MagicNumber, Timeframe, g_zone, g_bounceCount, MaxLayers);
      SavePACState();
   }

   // Check if entry is now allowed
   if(!g_ordersPlaced &&
      PAC_EntryAllowed(g_bounceCount, MinPivotBounces, MaxPivotBounces,
                       AggressiveMode, BaseConsumeThreshold, g_zone))
   {
      bool placed = false;
      if(g_zone.type == ZONE_RBR)
         placed = PAC_PlaceBuyLayers(MagicNumber, MaxLayers, LotSize, Slippage, g_zone);
      else
         placed = PAC_PlaceSellLayers(MagicNumber, MaxLayers, LotSize, Slippage, g_zone);

      if(placed)
      {
         g_ordersPlaced = true;
         g_state = STATE_TRADE_ACTIVE;
      }
      else
      {
         Print("PAC: order placement failed — check journal");
      }
      SavePACState();
   }
}

void ManageActiveZone()
{
   // 1. Cut loss check (candle-close based)
   if(PAC_MonitorCutLoss(MagicNumber, Timeframe, g_zone))
   {
      // Cut loss triggered: orders cleared, reset zone
      ResetZone();
      g_state = STATE_SCAN;
      SavePACState();
      return;
   }

   // 2. Zone invalidation checks (rules 2–4)
   if(PAC_IsZoneInvalidated(g_bounceCount, MaxPivotBounces,
                             AggressiveMode, BaseConsumeThreshold, g_zone))
   {
      InvalidateZone(false);  // cancel pending, leave open positions
      return;
   }

   // 3. Opposing zone inside corridor? (Rule 4 — checked via TP adjustment scan)
   PAC_AdjustTP(MagicNumber, Timeframe, g_zone, BaseFraction, BaseRangePips);

   // 4. Continue monitoring bounces (increments counter, may trigger additional entries)
   CheckBounces();

   // 5. If all orders gone (all filled + closed or all cancelled), reset zone
   if(g_ordersPlaced &&
      PAC_CountPositions(MagicNumber) == 0 &&
      PAC_CountPending(MagicNumber)   == 0)
   {
      ResetZone();
      g_state = STATE_SCAN;
      SavePACState();
   }
}

//+------------------------------------------------------------------+
int OnInit()
{
   if(Timeframe != PERIOD_M1 && Timeframe != PERIOD_M2 && Timeframe != PERIOD_M5)
   {
      Alert("PAC EA: Timeframe input must be M1, M2, or M5. Remove and reconfigure.");
      return INIT_PARAMETERS_INCORRECT;
   }

   g_state        = STATE_SCAN;
   g_bounceCount  = 0;
   g_ordersPlaced = false;
   g_inZone       = false;
   g_lastBar      = 0;
   g_zone.active  = false;
   g_zone.type    = ZONE_NONE;

   LoadPACState();

   if(g_zone.active)
      PAC_DrawZone(MagicNumber, Timeframe, g_zone, g_bounceCount, MaxLayers);

   EventSetTimer(1);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   SavePACState();
   // Orders intentionally NOT cancelled on detach (spec requirement)
}

void OnTick()
{
   datetime curBar = iTime(_Symbol, Timeframe, 0);
   if(curBar == g_lastBar || curBar == 0) return;

   bool firstTick = (g_lastBar == 0);
   g_lastBar = curBar;
   if(firstTick) return;  // skip very first bar to avoid partial data

   switch(g_state)
   {
      case STATE_SCAN:
         ScanForSetup();
         break;

      case STATE_WAIT_BOUNCE:
         // Check zone still valid (invalidation rules)
         if(PAC_IsZoneInvalidated(g_bounceCount, MaxPivotBounces,
                                   AggressiveMode, BaseConsumeThreshold, g_zone))
         {
            InvalidateZone(false);
            break;
         }
         CheckBounces();
         break;

      case STATE_TRADE_ACTIVE:
         ManageActiveZone();
         break;

      case STATE_INVALIDATED:
         ResetZone();
         g_state = STATE_SCAN;
         SavePACState();
         break;
   }
}

void OnTimer()
{
   // Refresh chart label anchors periodically
   if(g_zone.active)
      PAC_RefreshLabels(MagicNumber, Timeframe, g_zone, g_bounceCount, MaxLayers);
}
