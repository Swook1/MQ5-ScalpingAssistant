//+------------------------------------------------------------------+
//| PAC_ControlZone.mqh — RBR / DBD zone detection and storage       |
//+------------------------------------------------------------------+
#ifndef PAC_CONTROLZONE_MQH
#define PAC_CONTROLZONE_MQH

enum PAC_ZoneType { ZONE_NONE = 0, ZONE_RBR = 1, ZONE_DBD = 2 };

struct ControlZone
{
   PAC_ZoneType type;
   double       ceiling;
   double       floor;
   bool         active;
};

bool PAC_BarBullish(int bar, ENUM_TIMEFRAMES tf)
{
   return iClose(_Symbol, tf, bar) > iOpen(_Symbol, tf, bar);
}

double PAC_BarBody(int bar, ENUM_TIMEFRAMES tf)
{
   return MathAbs(iClose(_Symbol, tf, bar) - iOpen(_Symbol, tf, bar));
}

double PAC_AvgBody(int startBar, int count, ENUM_TIMEFRAMES tf)
{
   double sum = 0;
   int    total = iBars(_Symbol, tf);
   for(int i = startBar; i < startBar + count && i < total; i++)
      sum += PAC_BarBody(i, tf);
   return (count > 0) ? sum / count : 0;
}

// Scan bars [scanStart .. scanStart+scanLen] for a valid RBR or DBD base.
// MT5 bar indices: 0=newest, higher=older.
// scanStart=1 means start from the last completed bar.
bool PAC_DetectZone(ENUM_TIMEFRAMES tf, int scanStart, int scanLen,
                    double baseFraction, double baseRangePips,
                    ControlZone &zone)
{
   double pip        = SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10.0;
   double rangeLimit = baseRangePips * pip;
   int    totalBars  = iBars(_Symbol, tf);
   int    scanEnd    = MathMin(scanStart + scanLen, totalBars - 4);

   // Reference body: average over the full scan window
   double refBody = PAC_AvgBody(scanStart, MathMin(scanLen, 30), tf);
   if(refBody <= 0) return false;

   for(int i = scanStart; i <= scanEnd - 2; i++)
   {
      // Candidate base candle at bar i (small body)
      if(PAC_BarBody(i, tf) > refBody * baseFraction) continue;

      // Extend base toward older bars (higher indices)
      int    baseStart = i;   // newest base bar (lowest index)
      int    baseEnd   = i;   // oldest base bar (highest index so far)
      double baseHigh  = iHigh(_Symbol, tf, i);
      double baseLow   = iLow(_Symbol, tf, i);

      for(int k = i + 1; k <= scanEnd - 1; k++)
      {
         if(PAC_BarBody(k, tf) > refBody * baseFraction) break;
         double hi = iHigh(_Symbol, tf, k);
         double lo = iLow(_Symbol, tf, k);
         double nh = MathMax(baseHigh, hi);
         double nl = MathMin(baseLow,  lo);
         if(nh - nl > rangeLimit) break;
         baseHigh = nh;
         baseLow  = nl;
         baseEnd  = k;
      }

      // Require at least 2 base candles
      if(baseEnd - baseStart < 1) continue;

      // Require base range is within limit
      if(baseHigh - baseLow > rangeLimit) continue;

      // Following impulse: bar just newer than base (baseStart - 1)
      if(baseStart - 1 < 1) continue;
      double follBody = PAC_BarBody(baseStart - 1, tf);
      if(follBody < refBody * 0.5) continue;
      bool follBull = PAC_BarBullish(baseStart - 1, tf);

      // Preceding impulse: bar just older than base (baseEnd + 1)
      if(baseEnd + 1 >= totalBars) continue;
      double precBody = PAC_BarBody(baseEnd + 1, tf);
      if(precBody < refBody * 0.5) continue;
      bool precBull = PAC_BarBullish(baseEnd + 1, tf);

      // Same direction for both impulses = valid zone
      if(follBull != precBull) continue;

      zone.ceiling = baseHigh;
      zone.floor   = baseLow;
      zone.type    = precBull ? ZONE_RBR : ZONE_DBD;
      zone.active  = true;
      return true;
   }
   return false;
}

#endif
