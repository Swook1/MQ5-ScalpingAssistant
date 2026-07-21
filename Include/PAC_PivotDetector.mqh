//+------------------------------------------------------------------+
//| PAC_PivotDetector.mqh — Pivot candle detection logic             |
//+------------------------------------------------------------------+
#ifndef PAC_PIVOTDETECTOR_MQH
#define PAC_PIVOTDETECTOR_MQH

#define PAC_LOOKAHEAD 10

struct PivotInfo
{
   int    bar;        // MT5 bar index of the confirmed pivot (1+ = completed)
   bool   isBullish;  // true = lower wick dominant (bullish pivot)
   double high;
   double low;
   bool   confirmed;
};

// Full range / body ratio per spec pseudocode:
//   tailRatio = (High - Low) / Max(Body, 1 pip)
double PAC_TailRatio(int bar, ENUM_TIMEFRAMES tf, bool &isBullish)
{
   double o    = iOpen(_Symbol, tf, bar);
   double c    = iClose(_Symbol, tf, bar);
   double h    = iHigh(_Symbol, tf, bar);
   double l    = iLow(_Symbol, tf, bar);
   double body = MathAbs(c - o);
   double pip  = SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10.0;
   if(body < pip) body = pip;

   double upperWick = h - MathMax(o, c);
   double lowerWick = MathMin(o, c) - l;
   isBullish = (lowerWick >= upperWick);
   return (h - l) / body;
}

// Pivot must be the local extreme over ±lookback bars
bool PAC_IsLocalExtreme(int bar, ENUM_TIMEFRAMES tf, bool isBullish, int lookback)
{
   double val     = isBullish ? iLow(_Symbol, tf, bar) : iHigh(_Symbol, tf, bar);
   int    total   = iBars(_Symbol, tf);

   for(int d = 1; d <= lookback; d++)
   {
      // Newer side (lower index)
      int ni = bar - d;
      if(ni >= 1)
      {
         double v = isBullish ? iLow(_Symbol, tf, ni) : iHigh(_Symbol, tf, ni);
         if(isBullish && v < val) return false;
         if(!isBullish && v > val) return false;
      }
      // Older side (higher index)
      int oi = bar + d;
      if(oi < total)
      {
         double v = isBullish ? iLow(_Symbol, tf, oi) : iHigh(_Symbol, tf, oi);
         if(isBullish && v < val) return false;
         if(!isBullish && v > val) return false;
      }
   }
   return true;
}

// Count net-directional follow-through candles in bars [pivotBar-1 .. pivotBar-LOOKAHEAD]
// (more recent bars = lower MT5 index)
// Requires at least 3 matching-direction candles within the look-ahead window
bool PAC_HasFollowThrough(int pivotBar, bool isBullish, ENUM_TIMEFRAMES tf)
{
   int count = 0;
   for(int j = 1; j <= PAC_LOOKAHEAD && count < 3; j++)
   {
      int idx = pivotBar - j;
      if(idx < 1) break;
      bool bull = (iClose(_Symbol, tf, idx) > iOpen(_Symbol, tf, idx));
      if(isBullish == bull) count++;
   }
   return (count >= 3);
}

// Scan bars [1..scanBars] for the most recent confirmed pivot.
// Returns true and fills piv if found.
bool PAC_FindPivot(ENUM_TIMEFRAMES tf, int scanBars, double tailThreshold, PivotInfo &piv)
{
   int maxBar = MathMin(scanBars, iBars(_Symbol, tf) - PAC_LOOKAHEAD - 2);
   for(int i = 1; i <= maxBar; i++)
   {
      bool   bullish;
      double ratio = PAC_TailRatio(i, tf, bullish);
      if(ratio < tailThreshold)           continue;
      if(!PAC_IsLocalExtreme(i, tf, bullish, 5)) continue;
      if(!PAC_HasFollowThrough(i, bullish, tf))  continue;

      piv.bar       = i;
      piv.isBullish = bullish;
      piv.high      = iHigh(_Symbol, tf, i);
      piv.low       = iLow(_Symbol, tf, i);
      piv.confirmed = true;
      return true;
   }
   return false;
}

#endif
