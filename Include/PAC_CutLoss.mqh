//+------------------------------------------------------------------+
//| PAC_CutLoss.mqh — Candle-close cut loss trigger logic            |
//+------------------------------------------------------------------+
#ifndef PAC_CUTLOSS_MQH
#define PAC_CUTLOSS_MQH

#include "PAC_OrderManager.mqh"

// Called on each new bar (checks bar 1 = just-closed bar).
// Cut loss levels per spec:
//   RBR BUY:  CL = Ceiling + zone_height * 0.20  — trigger if close > CL
//   DBD SELL: CL = Floor   - zone_height * 0.20  — trigger if close < CL
// On trigger: close all EA positions + cancel all EA pending orders.
// Returns true if cut loss was triggered.
bool PAC_MonitorCutLoss(long magic, ENUM_TIMEFRAMES tf, const ControlZone &z)
{
   if(!z.active) return false;

   double close1 = iClose(_Symbol, tf, 1);
   if(close1 <= 0) return false;

   double clLevel = PAC_CalcCutLoss(z);
   bool   triggered = false;

   if(z.type == ZONE_RBR && close1 > clLevel)
      triggered = true;
   else if(z.type == ZONE_DBD && close1 < clLevel)
      triggered = true;

   if(triggered)
   {
      PAC_CloseAllPositions(magic);
      PAC_DeleteAllPending(magic);
   }
   return triggered;
}

#endif
