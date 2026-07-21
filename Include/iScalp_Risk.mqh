//+------------------------------------------------------------------+
//| iScalp_Risk.mqh — cut loss bar-close monitor + SL validation      |
//+------------------------------------------------------------------+
#ifndef ISCALP_RISK_MQH
#define ISCALP_RISK_MQH

#include "iScalp_Orders.mqh"

// Called on each new bar. Closes positions that breached cut loss on the closed bar.
void MonitorCutLoss(long magic, double buyCL, double sellCL)
{
   if(buyCL <= 0 && sellCL <= 0) return;

   double close1 = iClose(_Symbol, _Period, 1);
   if(close1 <= 0) return;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC)  != magic)  continue;

      ENUM_POSITION_TYPE pt = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(pt == POSITION_TYPE_BUY  && buyCL  > 0 && close1 <= buyCL)
         g_trade.PositionClose(ticket);
      else if(pt == POSITION_TYPE_SELL && sellCL > 0 && close1 >= sellCL)
         g_trade.PositionClose(ticket);
   }
}

// Returns "" if valid, otherwise a warning string
string ValidateSLDistance(double entryPrice, double slPrice, ENUM_ORDER_TYPE orderType)
{
   int    stops = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double minDist = stops * point;

   double dist = (orderType == ORDER_TYPE_BUY_LIMIT)
                 ? entryPrice - slPrice
                 : slPrice   - entryPrice;

   if(dist < minDist)
      return "SL too tight (min " + IntegerToString(stops) + " pts)";
   return "";
}

#endif
