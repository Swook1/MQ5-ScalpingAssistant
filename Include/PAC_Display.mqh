//+------------------------------------------------------------------+
//| PAC_Display.mqh — Chart drawing: zones, layers, labels           |
//+------------------------------------------------------------------+
#ifndef PAC_DISPLAY_MQH
#define PAC_DISPLAY_MQH

#include "PAC_ControlZone.mqh"
#include "PAC_OrderManager.mqh"

#define PAC_PREFIX "PAC_"

string PAC_ObjName(long magic, const string suffix)
{
   return PAC_PREFIX + IntegerToString(magic) + "_" + suffix;
}

void PAC_ObjDel(long magic, const string suffix)
{
   string n = PAC_ObjName(magic, suffix);
   if(ObjectFind(0, n) >= 0) ObjectDelete(0, n);
}

void PAC_SetHLine(long magic, const string suffix, double price,
                  color clr, ENUM_LINE_STYLE style, int width, const string tip)
{
   string n = PAC_ObjName(magic, suffix);
   if(ObjectFind(0, n) < 0) ObjectCreate(0, n, OBJ_HLINE, 0, 0, price);
   ObjectSetDouble(0,  n, OBJPROP_PRICE,      price);
   ObjectSetInteger(0, n, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, n, OBJPROP_STYLE,      style);
   ObjectSetInteger(0, n, OBJPROP_WIDTH,      width);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, 0);
   ObjectSetInteger(0, n, OBJPROP_BACK,       1);
   ObjectSetString(0,  n, OBJPROP_TOOLTIP,    tip);
}

void PAC_SetRect(long magic, const string suffix,
                 datetime t1, double p1, datetime t2, double p2,
                 color clr)
{
   string n = PAC_ObjName(magic, suffix);
   if(ObjectFind(0, n) < 0) ObjectCreate(0, n, OBJ_RECTANGLE, 0, t1, p1, t2, p2);
   ObjectSetInteger(0, n, OBJPROP_TIME,   0, (long)t1);
   ObjectSetDouble(0,  n, OBJPROP_PRICE,  0, p1);
   ObjectSetInteger(0, n, OBJPROP_TIME,   1, (long)t2);
   ObjectSetDouble(0,  n, OBJPROP_PRICE,  1, p2);
   ObjectSetInteger(0, n, OBJPROP_COLOR,  clr);
   ObjectSetInteger(0, n, OBJPROP_STYLE,  STYLE_SOLID);
   ObjectSetInteger(0, n, OBJPROP_WIDTH,  1);
   ObjectSetInteger(0, n, OBJPROP_FILL,   1);
   ObjectSetInteger(0, n, OBJPROP_BACK,   1);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, 0);
}

void PAC_SetTextLabel(long magic, const string suffix,
                      datetime t, double price, const string txt,
                      color clr, int fontSize)
{
   string n = PAC_ObjName(magic, suffix);
   if(ObjectFind(0, n) < 0) ObjectCreate(0, n, OBJ_TEXT, 0, t, price);
   ObjectSetInteger(0, n, OBJPROP_TIME,      0, (long)t);
   ObjectSetDouble(0,  n, OBJPROP_PRICE,     0, price);
   ObjectSetString(0,  n, OBJPROP_TEXT,      txt);
   ObjectSetInteger(0, n, OBJPROP_COLOR,     clr);
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE,  fontSize);
   ObjectSetInteger(0, n, OBJPROP_ANCHOR,    ANCHOR_LEFT_LOWER);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, 0);
   ObjectSetInteger(0, n, OBJPROP_BACK,      0);
}

void PAC_SetDot(long magic, const string suffix,
                datetime t, double price, color clr)
{
   string n = PAC_ObjName(magic, suffix);
   if(ObjectFind(0, n) < 0) ObjectCreate(0, n, OBJ_ARROW, 0, t, price);
   ObjectSetInteger(0, n, OBJPROP_TIME,      0, (long)t);
   ObjectSetDouble(0,  n, OBJPROP_PRICE,     0, price);
   ObjectSetInteger(0, n, OBJPROP_ARROWCODE, 159);
   ObjectSetInteger(0, n, OBJPROP_COLOR,     clr);
   ObjectSetInteger(0, n, OBJPROP_WIDTH,     1);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, 0);
   ObjectSetInteger(0, n, OBJPROP_BACK,      0);
}

// Draw or refresh all zone visuals
void PAC_DrawZone(long magic, ENUM_TIMEFRAMES tf,
                  const ControlZone &z, int bounceCount, int layers)
{
   if(!z.active) return;

   int    digits  = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   color  zoneClr = (z.type == ZONE_RBR) ? (color)0x1A4A1A : (color)0x4A1A1A;
   color  ceilClr = (z.type == ZONE_RBR) ? clrLimeGreen : clrTomato;
   color  floorClr= ceilClr;

   datetime tNow  = iTime(_Symbol, tf, 0);
   datetime tOld  = iTime(_Symbol, tf, 50);

   // Zone rectangle (ceiling to floor, shaded)
   PAC_SetRect(magic, "ZONE_RECT", tOld, z.ceiling, tNow, z.floor, zoneClr);

   // Ceiling line
   PAC_SetHLine(magic, "CEIL_LINE", z.ceiling, ceilClr, STYLE_SOLID, 2, "PAC Ceiling");
   PAC_SetTextLabel(magic, "CEIL_LBL", tNow, z.ceiling,
                    "Ceiling " + DoubleToString(z.ceiling, digits), ceilClr, 9);

   // Floor line
   PAC_SetHLine(magic, "FLOOR_LINE", z.floor, floorClr, STYLE_SOLID, 2, "PAC Floor");
   PAC_SetTextLabel(magic, "FLOOR_LBL", tNow, z.floor,
                    "Floor " + DoubleToString(z.floor, digits), floorClr, 9);

   // TP line
   double tp = PAC_CalcTP(z);
   PAC_SetHLine(magic, "TP_LINE", tp, clrDeepSkyBlue, STYLE_DASH, 1, "PAC TP");
   PAC_SetTextLabel(magic, "TP_LBL", tNow, tp,
                    "TP " + DoubleToString(tp, digits), clrDeepSkyBlue, 9);

   // SL line
   double sl = PAC_CalcSL(z);
   PAC_SetHLine(magic, "SL_LINE", sl, clrOrangeRed, STYLE_DASH, 1, "PAC SL");
   PAC_SetTextLabel(magic, "SL_LBL", tNow, sl,
                    "SL " + DoubleToString(sl, digits), clrOrangeRed, 9);

   // Cut Loss line
   double cl = PAC_CalcCutLoss(z);
   PAC_SetHLine(magic, "CL_LINE", cl, clrDarkOrange, STYLE_DOT, 1, "PAC Cut Loss");
   PAC_SetTextLabel(magic, "CL_LBL", tNow, cl,
                    "CL " + DoubleToString(cl, digits), clrDarkOrange, 9);

   // Layer markers
   double step = (layers > 1) ? (z.ceiling - z.floor) / (double)(layers - 1) : 0;
   for(int i = 0; i < layers; i++)
   {
      double layerPrice = (z.type == ZONE_RBR)
                          ? z.floor   + step * i
                          : z.ceiling - step * i;
      string lsuf = "LAYER_" + IntegerToString(i);
      PAC_SetDot(magic, lsuf, tNow, layerPrice, ceilClr);
   }

   // Bounce count label
   string bounceStr = "Bounces: " + IntegerToString(bounceCount);
   double midPrice  = (z.ceiling + z.floor) * 0.5;
   PAC_SetTextLabel(magic, "BOUNCE_LBL", tNow, midPrice + (z.ceiling - z.floor) * 0.1,
                    bounceStr, clrWhite, 9);

   // Zone status label
   string status;
   if(bounceCount == 0)      status = "UNVALIDATED";
   else if(bounceCount <= 3) status = "VALID";
   else                      status = "AGGRESSIVE";
   PAC_SetTextLabel(magic, "STATUS_LBL", tNow, midPrice - (z.ceiling - z.floor) * 0.1,
                    status, clrYellow, 9);

   ChartRedraw(0);
}

// Remove all PAC chart objects for this magic
void PAC_ClearDisplay(long magic)
{
   string prefix = PAC_PREFIX + IntegerToString(magic) + "_";
   ObjectsDeleteAll(0, prefix);
   ChartRedraw(0);
}

// Refresh time-anchored labels so they stay at current bar position
void PAC_RefreshLabels(long magic, ENUM_TIMEFRAMES tf, const ControlZone &z,
                       int bounceCount, int layers)
{
   if(!z.active) return;
   PAC_DrawZone(magic, tf, z, bounceCount, layers);
}

#endif
