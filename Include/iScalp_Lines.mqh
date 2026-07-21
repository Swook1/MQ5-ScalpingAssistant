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

string LN(long magic, const string suffix)
{
   return "iScalp_" + IntegerToString(magic) + "_" + suffix;
}

void LineSet(long magic, const string suffix, double price,
             color clr, ENUM_LINE_STYLE style, bool selectable,
             const string label, const string tooltip)
{
   string name = LN(magic, suffix);
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
   ObjectSetDouble(0, name,  OBJPROP_PRICE,      price);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE,      style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,      2);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, selectable ? 1 : 0);
   ObjectSetInteger(0, name, OBJPROP_SELECTED,   0);
   ObjectSetInteger(0, name, OBJPROP_BACK,       1);
   ObjectSetString(0,  name, OBJPROP_TEXT,       label);
   ObjectSetString(0,  name, OBJPROP_TOOLTIP,    tooltip);
}

void LineDel(long magic, const string suffix)
{
   string name = LN(magic, suffix);
   if(ObjectFind(0, name) >= 0)
      ObjectDelete(0, name);
}

double LineGet(long magic, const string suffix)
{
   string name = LN(magic, suffix);
   if(ObjectFind(0, name) < 0) return 0.0;
   return ObjectGetDouble(0, name, OBJPROP_PRICE, 0);
}

bool LineExists(long magic, const string suffix)
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

void LinesUpdateBuy(long magic, double floor_, double entry, double cutloss, double sl, double tp)
{
   if(floor_   > 0) LineSet(magic, LS_BUY_FLOOR,   floor_,   clrLimeGreen, STYLE_SOLID, true,  "Floor",   "BUY Floor (drag to move)");
   if(entry    > 0) LineSet(magic, LS_BUY_ENTRY,   entry,    clrGreen,     STYLE_SOLID, true,  "Entry",   "BUY Entry (drag to move)");
   if(cutloss  > 0) LineSet(magic, LS_BUY_CUTLOSS, cutloss,  clrRed,       STYLE_DOT,   false, "CL",      "BUY Cut Loss (auto)");
   if(sl       > 0) LineSet(magic, LS_BUY_SL,      sl,       clrCrimson,   STYLE_SOLID, false, "SL",      "BUY Stop Loss (auto)");
   if(tp       > 0) LineSet(magic, LS_BUY_TP,      tp,       clrLimeGreen, STYLE_DASH,  false, "TP",      "BUY TP (auto)");
   ChartRedraw(0);
}

void LinesUpdateSell(long magic, double ceil_, double entry, double cutloss, double sl, double tp)
{
   if(ceil_    > 0) LineSet(magic, LS_SELL_CEIL,    ceil_,    clrTomato,    STYLE_SOLID, true,  "Ceiling", "SELL Ceiling (drag to move)");
   if(entry    > 0) LineSet(magic, LS_SELL_ENTRY,   entry,    clrRed,       STYLE_SOLID, true,  "Entry",   "SELL Entry (drag to move)");
   if(cutloss  > 0) LineSet(magic, LS_SELL_CUTLOSS, cutloss,  clrRed,       STYLE_DOT,   false, "CL",      "SELL Cut Loss (auto)");
   if(sl       > 0) LineSet(magic, LS_SELL_SL,      sl,       clrCrimson,   STYLE_SOLID, false, "SL",      "SELL Stop Loss (auto)");
   if(tp       > 0) LineSet(magic, LS_SELL_TP,      tp,       clrTomato,    STYLE_DASH,  false, "TP",      "SELL TP (auto)");
   ChartRedraw(0);
}

#endif
