//+------------------------------------------------------------------+
//| Personal Scalping Tool — layered scalping EA with floating panel |
//| Author: RayyanGanteng                                            |
//+------------------------------------------------------------------+
#property copyright "RayyanGanteng"
#property version   "1.2"
#property strict

#include "Include/iScalp_Panel.mqh"

//--- Inputs
input double CutLossBuffer     = 10.0;  // Cut Loss buffer (% of area beyond Floor/Ceiling)
input double StopLossMultiplier = 1.0;  // Stop Loss distance (× area beyond Floor/Ceiling)
input int    DefaultLayers     = 4;     // Default number of layers
input double DefaultLotSize    = 0.05;  // Default lot size per layer

//--- EA globals
long       g_magic;
PanelState g_state;
datetime   g_lastBar = 0;

int OnInit()
{
   g_magic = DeriveMagic();

   // Enable mouse move events for this chart
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, 1);

   // Start 1-second timer for live count updates
   EventSetTimer(1);

   // Load persisted state (or init with defaults)
   LoadState(g_magic, g_state, DefaultLayers, DefaultLotSize,
             CutLossBuffer, StopLossMultiplier);

   // Draw panel at loaded position
   PanelDraw(g_magic, g_state);

   // Restore chart lines if we have prices
   if(g_state.buyFloor > 0 || g_state.buyEntry > 0)
      LinesUpdateBuy(g_magic,
                     g_state.buyFloor, g_state.buyEntry,
                     g_state.buyCutLoss, g_state.buyStopLoss, g_state.buyTP);
   if(g_state.sellCeil > 0 || g_state.sellEntry > 0)
      LinesUpdateSell(g_magic,
                      g_state.sellCeil, g_state.sellEntry,
                      g_state.sellCutLoss, g_state.sellStopLoss, g_state.sellTP);

   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   SaveState(g_magic, g_state);
   PanelDestroy(g_magic);
   LinesDeleteAll(g_magic);
   // Note: orders are intentionally NOT closed on detach (user may want them live)
   ChartRedraw(0);
}

void OnTick()
{
   datetime curBar = iTime(_Symbol, _Period, 0);
   if(curBar != g_lastBar && g_lastBar != 0)
   {
      // New bar — evaluate cut loss on the just-closed bar
      MonitorCutLoss(g_magic, g_state.buyCutLoss, g_state.sellCutLoss);
      RefreshCounts(g_magic, g_state);
      PanelDraw(g_magic, g_state);
   }
   g_lastBar = curBar;
}

void OnTimer()
{
   RefreshCounts(g_magic, g_state);
   PanelDraw(g_magic, g_state);
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   PanelHandleEvent(g_magic, g_state, CutLossBuffer, StopLossMultiplier,
                    id, lparam, dparam, sparam);
}
