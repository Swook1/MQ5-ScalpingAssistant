//+------------------------------------------------------------------+
//| iScalp_Orders.mqh — layer order placement and management          |
//+------------------------------------------------------------------+
#ifndef ISCALP_ORDERS_MQH
#define ISCALP_ORDERS_MQH

#include <Trade/Trade.mqh>

CTrade g_trade;

double LotNorm(double lot)
{
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minL  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxL  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(step <= 0) step = 0.01;
   lot = MathRound(lot / step) * step;
   return MathMax(minL, MathMin(maxL, lot));
}

//--- true if a pending order of this type already sits at this price
bool PendingExistsAt(long magic, ENUM_ORDER_TYPE type, double price)
{
   double tol = SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 0.5;
   if(tol <= 0) tol = 0.5 * MathPow(10, -_Digits);

   for(int i = 0; i < OrdersTotal(); i++)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol)   continue;
      if(OrderGetInteger(ORDER_MAGIC) != magic)     continue;
      if((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE) != type) continue;
      if(MathAbs(OrderGetDouble(ORDER_PRICE_OPEN) - price) <= tol)
         return true;
   }
   return false;
}

//--- true if an open position already covers this layer.
//    Matches on comment first (survives slippage/gap fills), price as fallback.
bool PositionExistsAt(long magic, ENUM_POSITION_TYPE type, double price, string cmt)
{
   double tol = SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 0.5;
   if(tol <= 0) tol = 0.5 * MathPow(10, -_Digits);

   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != magic)   continue;
      if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) != type) continue;
      if(cmt != "" && PositionGetString(POSITION_COMMENT) == cmt) return true;
      if(MathAbs(PositionGetDouble(POSITION_PRICE_OPEN) - price) <= tol) return true;
   }
   return false;
}

bool PlaceBuyLayers(long magic, int layers, double lotBase,
                    const double &mults[], double floor_, double entry,
                    double sl, double tp)
{
   g_trade.SetExpertMagicNumber(magic);
   g_trade.SetDeviationInPoints(10);
   bool ok = true;

   if(layers == 1)
   {
      double lot   = LotNorm(lotBase * mults[0]);
      double price = NormalizeDouble(entry, _Digits);
      string cmt1  = "iScalp BUY L1";
      if(PendingExistsAt(magic, ORDER_TYPE_BUY_LIMIT, price) ||
         PositionExistsAt(magic, POSITION_TYPE_BUY, price, cmt1))
         return true;                   // already placed or filled — not an error
      return g_trade.BuyLimit(lot, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, cmt1);
   }

   double step = (entry - floor_) / (double)(layers - 1);
   for(int i = 0; i < layers; i++)
   {
      double price = NormalizeDouble(entry - i * step, _Digits);  // L0=entry, L(N-1)=floor
      string cmt   = "iScalp BUY L" + IntegerToString(i + 1);
      if(PendingExistsAt(magic, ORDER_TYPE_BUY_LIMIT, price) ||
         PositionExistsAt(magic, POSITION_TYPE_BUY, price, cmt))
         continue;                      // layer already pending or filled
      double lot   = LotNorm(lotBase * mults[i]);
      if(!g_trade.BuyLimit(lot, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, cmt))
         ok = false;
   }
   return ok;
}

bool PlaceSellLayers(long magic, int layers, double lotBase,
                     const double &mults[], double ceil_, double entry,
                     double sl, double tp)
{
   g_trade.SetExpertMagicNumber(magic);
   g_trade.SetDeviationInPoints(10);
   bool ok = true;

   if(layers == 1)
   {
      double lot   = LotNorm(lotBase * mults[0]);
      double price = NormalizeDouble(entry, _Digits);
      string cmt1  = "iScalp SELL L1";
      if(PendingExistsAt(magic, ORDER_TYPE_SELL_LIMIT, price) ||
         PositionExistsAt(magic, POSITION_TYPE_SELL, price, cmt1))
         return true;                   // already placed or filled — not an error
      return g_trade.SellLimit(lot, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, cmt1);
   }

   double step = (ceil_ - entry) / (double)(layers - 1);
   for(int i = 0; i < layers; i++)
   {
      double price = NormalizeDouble(entry + i * step, _Digits);  // L0=entry, L(N-1)=ceil
      string cmt   = "iScalp SELL L" + IntegerToString(i + 1);
      if(PendingExistsAt(magic, ORDER_TYPE_SELL_LIMIT, price) ||
         PositionExistsAt(magic, POSITION_TYPE_SELL, price, cmt))
         continue;                      // layer already pending or filled
      double lot   = LotNorm(lotBase * mults[i]);
      if(!g_trade.SellLimit(lot, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, cmt))
         ok = false;
   }
   return ok;
}

int CountPositions(long magic)
{
   int cnt = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 &&
         PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC)  == magic)
         cnt++;
   }
   return cnt;
}

int CountPendingBuy(long magic)
{
   int cnt = 0;
   for(int i = 0; i < OrdersTotal(); i++)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0 &&
         OrderGetString(ORDER_SYMBOL)  == _Symbol &&
         OrderGetInteger(ORDER_MAGIC)  == magic)
      {
         ENUM_ORDER_TYPE ot = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
         if(ot == ORDER_TYPE_BUY_LIMIT || ot == ORDER_TYPE_BUY_STOP)
            cnt++;
      }
   }
   return cnt;
}

int CountPendingSell(long magic)
{
   int cnt = 0;
   for(int i = 0; i < OrdersTotal(); i++)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0 &&
         OrderGetString(ORDER_SYMBOL)  == _Symbol &&
         OrderGetInteger(ORDER_MAGIC)  == magic)
      {
         ENUM_ORDER_TYPE ot = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
         if(ot == ORDER_TYPE_SELL_LIMIT || ot == ORDER_TYPE_SELL_STOP)
            cnt++;
      }
   }
   return cnt;
}

int CountPending(long magic)
{
   int cnt = 0;
   for(int i = 0; i < OrdersTotal(); i++)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0 &&
         OrderGetString(ORDER_SYMBOL) == _Symbol &&
         OrderGetInteger(ORDER_MAGIC) == magic)
         cnt++;
   }
   return cnt;
}

void CloseAllPositions(long magic)
{
   g_trade.SetExpertMagicNumber(magic);
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 &&
         PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC)  == magic)
         g_trade.PositionClose(ticket);
   }
}

void DeletePendingBuy(long magic)
{
   g_trade.SetExpertMagicNumber(magic);
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0 &&
         OrderGetString(ORDER_SYMBOL) == _Symbol &&
         OrderGetInteger(ORDER_MAGIC)  == magic)
      {
         ENUM_ORDER_TYPE ot = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
         if(ot == ORDER_TYPE_BUY_LIMIT || ot == ORDER_TYPE_BUY_STOP)
            g_trade.OrderDelete(ticket);
      }
   }
}

void DeletePendingSell(long magic)
{
   g_trade.SetExpertMagicNumber(magic);
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0 &&
         OrderGetString(ORDER_SYMBOL) == _Symbol &&
         OrderGetInteger(ORDER_MAGIC)  == magic)
      {
         ENUM_ORDER_TYPE ot = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
         if(ot == ORDER_TYPE_SELL_LIMIT || ot == ORDER_TYPE_SELL_STOP)
            g_trade.OrderDelete(ticket);
      }
   }
}

void DeleteAllPending(long magic)
{
   g_trade.SetExpertMagicNumber(magic);
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0 &&
         OrderGetString(ORDER_SYMBOL) == _Symbol &&
         OrderGetInteger(ORDER_MAGIC)  == magic)
         g_trade.OrderDelete(ticket);
   }
}

#endif
