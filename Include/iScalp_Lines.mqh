//+------------------------------------------------------------------+
//| iScalp_Lines.mqh — chart horizontal line draw/update/drag        |
//+------------------------------------------------------------------+
#ifndef ISCALP_LINES_MQH
#define ISCALP_LINES_MQH

#define LS_BUY_FLOOR    "BUY_FLOOR"
#define LS_BUY_ENTRY    "BUY_ENTRY"
#define LS_BUY_CUTLOSS  "BUY_CUTLOSS"
#define LS_BUY_SL       "BUY_SL"
#define LS_BUY_TP       "BUY_TP"
#define LS_SELL_CEIL    "SELL_CEIL"
#define LS_SELL_ENTRY   "SELL_ENTRY"
#define LS_SELL_CUTLOSS "SELL_CUTLOSS"
#define LS_SELL_SL      "SELL_SL"
#define LS_SELL_TP      "SELL_TP"

#define LINE_WIDTH 3

string LN(long magic, string suffix)
{
   return "iScalp_" + IntegerToString(magic) + "_" + suffix;
}

void LineSet(long magic, string suffix, double price,
             color clr, ENUM_LINE_STYLE style, bool selectable,
             string tooltip)
{
   string name = LN(magic, suffix);
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
   ObjectSetDouble(0, name,  OBJPROP_PRICE,      price);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE,      style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,      LINE_WIDTH);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, selectable ? 1 : 0);
   ObjectSetInteger(0, name, OBJPROP_SELECTED,   0);
   ObjectSetInteger(0, name, OBJPROP_BACK,       1);
   ObjectSetString(0,  name, OBJPROP_TOOLTIP,    tooltip);
}

void LineLabelSet(long magic, string suffix, double price,
                  color clr, string labelTxt)
{
   string name = LN(magic, suffix + "_LBL");
   int    digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   string txt = labelTxt + " " + DoubleToString(price, digits);
   datetime t = iTime(_Symbol, _Period, 0);
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_TEXT, 0, t, price);
   ObjectSetInteger(0, name, OBJPROP_TIME,       0, (long)t);
   ObjectSetDouble(0,  name, OBJPROP_PRICE,      0, price);
   ObjectSetString(0,  name, OBJPROP_TEXT,       txt);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,   9);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR,     ANCHOR_LEFT_LOWER);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, 0);
   ObjectSetInteger(0, name, OBJPROP_BACK,       0);
}

void LineLabelDel(long magic, const string suffix)
{
   string name = LN(magic, suffix + "_LBL");
   if(ObjectFind(0, name) >= 0)
      ObjectDelete(0, name);
}

void LineDel(long magic, string suffix)
{
   string name = LN(magic, suffix);
   if(ObjectFind(0, name) >= 0)
      ObjectDelete(0, name);
   LineLabelDel(magic, suffix);
}

double LineGet(long magic, string suffix)
{
   string name = LN(magic, suffix);
   if(ObjectFind(0, name) < 0) return 0.0;
   return ObjectGetDouble(0, name, OBJPROP_PRICE, 0);
}

bool LineExists(long magic, string suffix)
{
   return ObjectFind(0, LN(magic, suffix)) >= 0;
}

void LinesDeleteAll(long magic)
{
   string suf[] = {
      LS_BUY_FLOOR, LS_BUY_ENTRY, LS_BUY_CUTLOSS, LS_BUY_SL, LS_BUY_TP,
      LS_SELL_CEIL, LS_SELL_ENTRY, LS_SELL_CUTLOSS, LS_SELL_SL, LS_SELL_TP
   };
   for(int i = 0; i < ArraySize(suf); i++)
      LineDel(magic, suf[i]);
}

// Refresh label time anchors so labels stay at current bar (call from OnTimer)
void LinesRefreshLabels(long magic,
                        double buyFloor, double buyEntry, double buyCL, double buySL, double buyTP,
                        double sellCeil, double sellEntry, double sellCL, double sellSL, double sellTP)
{
   if(buyFloor  > 0) LineLabelSet(magic, LS_BUY_FLOOR,    buyFloor,  clrLimeGreen, "Floor");
   if(buyEntry  > 0) LineLabelSet(magic, LS_BUY_ENTRY,    buyEntry,  clrLimeGreen, "Entry");
   if(buyCL     > 0) LineLabelSet(magic, LS_BUY_CUTLOSS,  buyCL,     clrRed,       "CL");
   if(buySL     > 0) LineLabelSet(magic, LS_BUY_SL,       buySL,     clrRed,       "SL");
   if(buyTP     > 0) LineLabelSet(magic, LS_BUY_TP,       buyTP,     clrLimeGreen, "TP");
   if(sellCeil  > 0) LineLabelSet(magic, LS_SELL_CEIL,    sellCeil,  clrRed,       "Ceiling");
   if(sellEntry > 0) LineLabelSet(magic, LS_SELL_ENTRY,   sellEntry, clrRed,       "Entry");
   if(sellCL    > 0) LineLabelSet(magic, LS_SELL_CUTLOSS, sellCL,    clrRed,       "CL");
   if(sellSL    > 0) LineLabelSet(magic, LS_SELL_SL,      sellSL,    clrRed,       "SL");
   if(sellTP    > 0) LineLabelSet(magic, LS_SELL_TP,      sellTP,    clrLimeGreen, "TP");
}

void LinesUpdateBuy(long magic, double floor_, double entry, double cutloss, double sl, double tp)
{
   if(floor_  > 0) LineSet(magic, LS_BUY_FLOOR,   floor_,  clrLimeGreen, STYLE_SOLID, true,  "BUY Floor (drag to move)");
   if(entry   > 0) LineSet(magic, LS_BUY_ENTRY,   entry,   clrLimeGreen, STYLE_SOLID, true,  "BUY Entry (drag to move)");
   if(cutloss > 0) LineSet(magic, LS_BUY_CUTLOSS, cutloss, clrRed,       STYLE_DASH,  false, "BUY Cut Loss (auto)");
   if(sl      > 0) LineSet(magic, LS_BUY_SL,      sl,      clrRed,       STYLE_SOLID, false, "BUY Stop Loss (auto)");
   if(tp      > 0) LineSet(magic, LS_BUY_TP,      tp,      clrLimeGreen, STYLE_DASH,  false, "BUY TP (auto)");
   ChartRedraw(0);
}

void LinesUpdateSell(long magic, double ceil_, double entry, double cutloss, double sl, double tp)
{
   if(ceil_   > 0) LineSet(magic, LS_SELL_CEIL,    ceil_,   clrRed,       STYLE_SOLID, true,  "SELL Ceiling (drag to move)");
   if(entry   > 0) LineSet(magic, LS_SELL_ENTRY,   entry,   clrRed,       STYLE_SOLID, true,  "SELL Entry (drag to move)");
   if(cutloss > 0) LineSet(magic, LS_SELL_CUTLOSS, cutloss, clrRed,       STYLE_DASH,  false, "SELL Cut Loss (auto)");
   if(sl      > 0) LineSet(magic, LS_SELL_SL,      sl,      clrRed,       STYLE_SOLID, false, "SELL Stop Loss (auto)");
   if(tp      > 0) LineSet(magic, LS_SELL_TP,      tp,      clrLimeGreen, STYLE_DASH,  false, "SELL TP (auto)");
   ChartRedraw(0);
}

#endif
