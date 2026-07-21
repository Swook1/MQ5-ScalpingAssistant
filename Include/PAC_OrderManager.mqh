//+------------------------------------------------------------------+
//| PAC_OrderManager.mqh — Limit order placement, TP/SL management   |
//+------------------------------------------------------------------+
#ifndef PAC_ORDERMANAGER_MQH
#define PAC_ORDERMANAGER_MQH

#include <Trade/Trade.mqh>
#include "PAC_ControlZone.mqh"

CTrade g_pacTrade;

double PAC_LotNorm(double lot)
{
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minL  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxL  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(step <= 0) step = 0.01;
   lot = MathRound(lot / step) * step;
   return MathMax(minL, MathMin(maxL, lot));
}

// TP / SL / CutLoss calculations per spec
// RBR BUY:
//   TP = Ceiling + ZoneHeight * 0.50
//   SL = Floor - (TP - Ceiling)          [1:1 from Ceiling to TP, mirrored below Floor]
// DBD SELL:
//   TP = Floor - ZoneHeight * 0.50
//   SL = Ceiling + (Floor - TP)          [1:1 from Floor to TP, mirrored above Ceiling]
double PAC_CalcTP(const ControlZone &z)
{
   double h = z.ceiling - z.floor;
   return (z.type == ZONE_RBR) ? z.ceiling + h * 0.50
                                : z.floor   - h * 0.50;
}

double PAC_CalcSL(const ControlZone &z)
{
   double h  = z.ceiling - z.floor;
   double tp = PAC_CalcTP(z);
   if(z.type == ZONE_RBR)
   {
      double tpDist = tp - z.ceiling;  // = h * 0.50
      return z.floor - tpDist;
   }
   else
   {
      double tpDist = z.floor - tp;    // = h * 0.50
      return z.ceiling + tpDist;
   }
}

// Cut loss levels per spec (zone-visit expiry trigger)
// RBR BUY:  CL = Ceiling + (Ceiling - Floor) * 0.20  — triggers if close > CL
// DBD SELL: CL = Floor   - (Ceiling - Floor) * 0.20  — triggers if close < CL
double PAC_CalcCutLoss(const ControlZone &z)
{
   double h = z.ceiling - z.floor;
   return (z.type == ZONE_RBR) ? z.ceiling + h * 0.20
                                : z.floor   - h * 0.20;
}

// Layer prices per spec:
// RBR BUY:  Layer 1 = Floor, Layer N = Ceiling (spread evenly upward)
// DBD SELL: Layer 1 = Ceiling, Layer N = Floor (spread evenly downward)
bool PAC_PlaceBuyLayers(long magic, int layers, double lot, int slippage,
                        const ControlZone &z)
{
   if(z.type != ZONE_RBR) return false;
   g_pacTrade.SetExpertMagicNumber(magic);
   g_pacTrade.SetDeviationInPoints(slippage);

   double tp    = PAC_CalcTP(z);
   double sl    = PAC_CalcSL(z);
   double lotN  = PAC_LotNorm(lot);
   double step  = (layers > 1) ? (z.ceiling - z.floor) / (double)(layers - 1) : 0;
   bool   ok    = true;

   for(int i = 0; i < layers; i++)
   {
      double price = z.floor + step * i;
      string cmt   = "PAC BUY L" + IntegerToString(i + 1);
      if(!g_pacTrade.BuyLimit(lotN, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, cmt))
         ok = false;
   }
   return ok;
}

bool PAC_PlaceSellLayers(long magic, int layers, double lot, int slippage,
                         const ControlZone &z)
{
   if(z.type != ZONE_DBD) return false;
   g_pacTrade.SetExpertMagicNumber(magic);
   g_pacTrade.SetDeviationInPoints(slippage);

   double tp   = PAC_CalcTP(z);
   double sl   = PAC_CalcSL(z);
   double lotN = PAC_LotNorm(lot);
   double step = (layers > 1) ? (z.ceiling - z.floor) / (double)(layers - 1) : 0;
   bool   ok   = true;

   for(int i = 0; i < layers; i++)
   {
      double price = z.ceiling - step * i;
      string cmt   = "PAC SELL L" + IntegerToString(i + 1);
      if(!g_pacTrade.SellLimit(lotN, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, cmt))
         ok = false;
   }
   return ok;
}

// Adjust TP on open positions if a new opposing zone forms between entry and TP.
// Moves TP to the near edge of the new pattern (near edge = side closest to our entries).
void PAC_AdjustTP(long magic, ENUM_TIMEFRAMES tf, const ControlZone &activeZone,
                  double baseFraction, double baseRangePips)
{
   ControlZone newZone;
   newZone.active = false;

   // Scan the corridor between the active zone and its TP for an opposing pattern
   if(!PAC_DetectZone(tf, 1, 30, baseFraction, baseRangePips, newZone)) return;
   if(!newZone.active) return;

   // For RBR BUY: look for a DBD zone between ceiling and TP
   // For DBD SELL: look for a RBR zone between floor and TP
   double tp = PAC_CalcTP(activeZone);
   bool   relevant = false;
   double newTP    = tp;

   if(activeZone.type == ZONE_RBR && newZone.type == ZONE_DBD)
   {
      // New DBD zone must be above ceiling and below original TP
      if(newZone.floor > activeZone.ceiling && newZone.floor < tp)
      {
         newTP = newZone.floor;  // near edge = floor of the new DBD zone
         relevant = true;
      }
   }
   else if(activeZone.type == ZONE_DBD && newZone.type == ZONE_RBR)
   {
      // New RBR zone must be below floor and above original TP
      if(newZone.ceiling < activeZone.floor && newZone.ceiling > tp)
      {
         newTP = newZone.ceiling;  // near edge = ceiling of the new RBR zone
         relevant = true;
      }
   }

   if(!relevant) return;

   // Update TP on all open positions with this magic
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if((long)PositionGetInteger(POSITION_MAGIC) != magic) continue;
      double sl = PositionGetDouble(POSITION_SL);
      g_pacTrade.PositionModify(ticket, sl, newTP);
   }
}

void PAC_CloseAllPositions(long magic)
{
   g_pacTrade.SetExpertMagicNumber(magic);
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if((long)PositionGetInteger(POSITION_MAGIC) != magic) continue;
      g_pacTrade.PositionClose(ticket);
   }
}

void PAC_DeleteAllPending(long magic)
{
   g_pacTrade.SetExpertMagicNumber(magic);
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket <= 0) continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
      if((long)OrderGetInteger(ORDER_MAGIC) != magic) continue;
      g_pacTrade.OrderDelete(ticket);
   }
}

int PAC_CountPositions(long magic)
{
   int cnt = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong t = PositionGetTicket(i);
      if(t > 0 &&
         PositionGetString(POSITION_SYMBOL) == _Symbol &&
         (long)PositionGetInteger(POSITION_MAGIC) == magic)
         cnt++;
   }
   return cnt;
}

int PAC_CountPending(long magic)
{
   int cnt = 0;
   for(int i = 0; i < OrdersTotal(); i++)
   {
      ulong t = OrderGetTicket(i);
      if(t > 0 &&
         OrderGetString(ORDER_SYMBOL) == _Symbol &&
         (long)OrderGetInteger(ORDER_MAGIC) == magic)
         cnt++;
   }
   return cnt;
}

#endif
