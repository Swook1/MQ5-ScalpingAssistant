//+------------------------------------------------------------------+
//| iScalp_Panel.mqh — floating control panel (native chart objects)  |
//+------------------------------------------------------------------+
//
// Panel layout (all Y relative to panel top-left corner):
//
//  [0..23]   Title / drag handle
//  [24..91]  Div1: Layers | Lot/Layer | Total  (row1=26..46, row2=52..72)
//  [92..261] Div2: BUY col (x=4) | SELL col (x=220), each 216px wide
//              Header 97, Floor/Ceil 118, Entry 141, CL 165, SL 187, TP 209, Btn 230
//  [262..357] Div3: CLOSE ALL 264, DEL BUY/SELL 290, DEL ALL 318
//  [358..374] Warning label
//  Panel: 440 x 376
//
#ifndef ISCALP_PANEL_MQH
#define ISCALP_PANEL_MQH

#include "iScalp_Magic.mqh"
#include "iScalp_Lines.mqh"
#include "iScalp_Orders.mqh"
#include "iScalp_Risk.mqh"

// Panel pixel dimensions
#define PNL_W         440
#define PNL_H         400
#define PNL_TITLE_H   24

// Column X offsets (from panel origin)
#define COL_BUY_X     4
#define COL_SELL_X    220
#define COL_W         216
#define COL_LBL_OX    4    // label X offset within col
#define COL_VAL_OX    78   // value/edit X offset within col
#define COL_VAL_W     134  // value/edit width

// Column field Y offsets (from panel origin)
#define COL_HDR_Y     97
#define COL_FLOOR_Y   118   // edit Y
#define COL_ENTRY_Y   141
#define COL_CL_Y      165
#define COL_SL_Y      187
#define COL_TP_Y      209
#define COL_BTN_Y     230
#define COL_BTN_H     26
#define COL_BTN_W     208

// Div3 Y offsets
#define D3_CLOSE_Y    264
#define D3_DEL_ROW_Y  290
#define D3_DELALL_Y   318
#define D3_DELLINES_Y 346
#define D3_BTN_H      24
#define D3_FULL_W     432
#define D3_HALF_W     212
#define D3_SELL_X     224   // X of DEL SELL button

// Colors
#define CLR_BG        (color)0x2D2D2D
#define CLR_D1_BG     (color)0x242B34
#define CLR_BUY_BG    (color)0x1E641E
#define CLR_SELL_BG   (color)0x1E1E64
#define CLR_TITLE_BG  (color)0x121619
#define CLR_LBL       (color)0x9AA3AE
#define CLR_VAL       (color)0xEAEBEC
#define CLR_EDIT_BG   (color)0x191D22
#define CLR_EDIT_FG   (color)0xFFFFFF
#define CLR_BUY_FG    (color)0x2ECC71
#define CLR_SELL_FG   (color)0xE74C3C
#define CLR_BTN_BG    (color)0x2C3440
#define CLR_BTN_FG    (color)0xFFFFFF
#define CLR_WARN      (color)0xFF6B35
#define CLR_INACTIVE  (color)0x555555

struct PanelState
{
   // Div1
   int    layers;
   double lotPerLayer;
   string multStr;
   double mults[];
   bool   multValid;
   double totalLot;

   // BUY side
   double buyFloor;
   double buyEntry;
   double buyCutLoss;
   double buyStopLoss;
   double buyTP;
   bool   buyEntryManual;

   // SELL side
   double sellCeil;
   double sellEntry;
   double sellCutLoss;
   double sellStopLoss;
   double sellTP;
   bool   sellEntryManual;

   // Panel position
   int    panelX;
   int    panelY;

   // Panel scale & minimize
   double panelScale;     // 1.0, 1.5, 2.0, 2.5, 3.0
   bool   panelMinimized; // collapse to title bar only

   // Live counts
   int    cntPos;
   int    cntPendBuy;
   int    cntPendSell;
   int    cntPend;

   // Validation
   bool   zoneValid;
   string warnMsg;
};

// Panel object name helper
string PN(long m, const string s)
{
   return "iScalp_" + IntegerToString(m) + "_P_" + s;
}

string FmtPrice(double p)
{
   if(p <= 0.0) return "—";
   return DoubleToString(p, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
}

// Low-level object helpers
void _SetRect(const string n, int x, int y, int w, int h, color bg, color bdr, int zorder = 0)
{
   if(ObjectFind(0, n) < 0) ObjectCreate(0, n, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, n, OBJPROP_XSIZE,     w);
   ObjectSetInteger(0, n, OBJPROP_YSIZE,     h);
   ObjectSetInteger(0, n, OBJPROP_BGCOLOR,   bg);
   ObjectSetInteger(0, n, OBJPROP_COLOR,     bdr);
   ObjectSetInteger(0, n, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, 0);
   ObjectSetInteger(0, n, OBJPROP_HIDDEN,    1);
   ObjectSetInteger(0, n, OBJPROP_ZORDER,    zorder);
}

void _SetDragRect(const string n, int x, int y, int w, int h, color bg)
{
   if(ObjectFind(0, n) < 0) ObjectCreate(0, n, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_CORNER,     CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE,  x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE,  y);
   ObjectSetInteger(0, n, OBJPROP_XSIZE,      w);
   ObjectSetInteger(0, n, OBJPROP_YSIZE,      h);
   ObjectSetInteger(0, n, OBJPROP_BGCOLOR,    bg);
   ObjectSetInteger(0, n, OBJPROP_COLOR,      bg);
   ObjectSetInteger(0, n, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, 1);
   ObjectSetInteger(0, n, OBJPROP_SELECTED,   0);
   ObjectSetInteger(0, n, OBJPROP_HIDDEN,     1);
   ObjectSetInteger(0, n, OBJPROP_ZORDER,     1);
}

void _SetLbl(const string n, int x, int y, const string txt, color clr, int fsize = 8)
{
   if(ObjectFind(0, n) < 0) ObjectCreate(0, n, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
   ObjectSetString(0,  n, OBJPROP_TEXT,      txt);
   ObjectSetInteger(0, n, OBJPROP_COLOR,     clr);
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE,  fsize);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, 0);
   ObjectSetInteger(0, n, OBJPROP_HIDDEN,    1);
   ObjectSetInteger(0, n, OBJPROP_ZORDER,    10);
}

void _SetEdit(const string n, int x, int y, int w, int h,
              const string txt, color bg, color fg, bool rdonly = false, int fsize = 8, color bdr = clrNONE)
{
   if(ObjectFind(0, n) < 0) ObjectCreate(0, n, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, n, OBJPROP_XSIZE,     w);
   ObjectSetInteger(0, n, OBJPROP_YSIZE,     h);
   ObjectSetString(0,  n, OBJPROP_TEXT,      txt);
   ObjectSetInteger(0, n, OBJPROP_BGCOLOR,   bg);
   ObjectSetInteger(0, n, OBJPROP_COLOR,     bdr == clrNONE ? fg : bdr);
   ObjectSetInteger(0, n, OBJPROP_READONLY,  rdonly ? 1 : 0);
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE,  fsize);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, 0);
   ObjectSetInteger(0, n, OBJPROP_HIDDEN,    1);
   ObjectSetInteger(0, n, OBJPROP_ZORDER,    10);
}

void _SetBtn(const string n, int x, int y, int w, int h,
             const string txt, color bg, color fg, bool enabled = true, int fsize = 8)
{
   if(ObjectFind(0, n) < 0) ObjectCreate(0, n, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, n, OBJPROP_XSIZE,     w);
   ObjectSetInteger(0, n, OBJPROP_YSIZE,     h);
   ObjectSetString(0,  n, OBJPROP_TEXT,      txt);
   ObjectSetInteger(0, n, OBJPROP_BGCOLOR,   enabled ? bg : (color)CLR_INACTIVE);
   ObjectSetInteger(0, n, OBJPROP_COLOR,     enabled ? fg : (color)CLR_BTN_FG);
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE,  fsize);
   ObjectSetInteger(0, n, OBJPROP_STATE,     0);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, 0);
   ObjectSetInteger(0, n, OBJPROP_HIDDEN,    1);
   ObjectSetInteger(0, n, OBJPROP_ZORDER,    10);
}

int _SS(int v, double sc) { return (int)MathRound(v * sc); }

// Parse multiplier string "1.1.2.2" → mults[], validate count matches layers
bool ParseMults(PanelState &s)
{
   string parts[];
   ushort dot = StringGetCharacter(".", 0);
   int n = StringSplit(s.multStr, dot, parts);
   if(n != s.layers || n <= 0) { s.multValid = false; return false; }
   ArrayResize(s.mults, n);
   s.totalLot = 0;
   for(int i = 0; i < n; i++)
   {
      s.mults[i] = StringToDouble(parts[i]);
      if(s.mults[i] <= 0.0) { s.multValid = false; return false; }
      s.totalLot += s.lotPerLayer * s.mults[i];
   }
   s.multValid = true;
   return true;
}

double GetArea(const PanelState &s)
{
   if(s.buyFloor > 0 && s.sellCeil > 0 && s.sellCeil > s.buyFloor)
      return s.sellCeil - s.buyFloor;
   return 0.0;
}

void RecomputeBuy(PanelState &s, double clBuf, double slMult)
{
   double area = GetArea(s);
   if(s.buyFloor <= 0 || area <= 0) return;
   if(!s.buyEntryManual)
      s.buyEntry = s.buyFloor + 0.25 * area;
   s.buyCutLoss  = s.buyFloor - (clBuf / 100.0) * area;
   s.buyStopLoss = s.buyFloor - slMult * area;
   s.buyTP       = s.buyFloor + 0.5 * area;
   s.zoneValid   = (s.buyFloor < s.buyEntry && s.buyEntry < s.buyTP && s.buyTP < s.sellCeil);
}

void RecomputeSell(PanelState &s, double clBuf, double slMult)
{
   double area = GetArea(s);
   if(s.sellCeil <= 0 || area <= 0) return;
   if(!s.sellEntryManual)
      s.sellEntry = s.sellCeil - 0.25 * area;
   s.sellCutLoss  = s.sellCeil + (clBuf / 100.0) * area;
   s.sellStopLoss = s.sellCeil + slMult * area;
   s.sellTP       = s.buyFloor + 0.5 * area;
   s.zoneValid    = (s.buyFloor < s.buyEntry && s.buyEntry < s.sellTP && s.sellTP < s.sellCeil);
}

void RecomputeAll(PanelState &s, double clBuf, double slMult)
{
   s.zoneValid = false;
   double area = GetArea(s);
   if(area <= 0) { s.warnMsg = ""; return; }
   RecomputeBuy(s,  clBuf, slMult);
   RecomputeSell(s, clBuf, slMult);
   s.zoneValid = (s.buyFloor > 0 && s.sellCeil > 0 && s.sellCeil > s.buyFloor);
}

void RefreshCounts(long magic, PanelState &s)
{
   s.cntPos      = CountPositions(magic);
   s.cntPendBuy  = CountPendingBuy(magic);
   s.cntPendSell = CountPendingSell(magic);
   s.cntPend     = CountPending(magic);
}

// Build the default "1.1.1..." mult string for given layer count
string DefaultMultStr(int layers)
{
   string r = "";
   for(int i = 0; i < layers; i++)
      r += (i > 0 ? "." : "") + "1";
   return r;
}

void StateInit(PanelState &s, int defLayers, double defLot)
{
   s.layers       = defLayers;
   s.lotPerLayer  = defLot;
   s.multStr      = DefaultMultStr(defLayers);
   ParseMults(s);
   s.buyFloor     = 0; s.buyEntry   = 0; s.buyCutLoss = 0;
   s.buyStopLoss  = 0; s.buyTP      = 0; s.buyEntryManual  = false;
   s.sellCeil     = 0; s.sellEntry  = 0; s.sellCutLoss = 0;
   s.sellStopLoss = 0; s.sellTP     = 0; s.sellEntryManual = false;
   s.panelX       = 20; s.panelY    = 50;
   s.panelScale   = 1.0; s.panelMinimized = false;
   s.cntPos       = 0;  s.cntPendBuy = 0; s.cntPendSell = 0; s.cntPend = 0;
   s.zoneValid    = false; s.warnMsg = "";
}

// Save/load state via GlobalVariables (keyed by magic, survives TF switch)
void SaveState(long magic, const PanelState &s)
{
   string k = "iSc_" + IntegerToString(magic) + "_";
   GlobalVariableSet(k + "bFloor",  s.buyFloor);
   GlobalVariableSet(k + "bEntry",  s.buyEntry);
   GlobalVariableSet(k + "bEM",     s.buyEntryManual ? 1 : 0);
   GlobalVariableSet(k + "sCeil",   s.sellCeil);
   GlobalVariableSet(k + "sEntry",  s.sellEntry);
   GlobalVariableSet(k + "sEM",     s.sellEntryManual ? 1 : 0);
   GlobalVariableSet(k + "layers",  s.layers);
   GlobalVariableSet(k + "lot",     s.lotPerLayer);
   GlobalVariableSet(k + "panX",    s.panelX);
   GlobalVariableSet(k + "panY",    s.panelY);
   GlobalVariableSet(k + "panSc",   s.panelScale);
   GlobalVariableSet(k + "panMin",  s.panelMinimized ? 1 : 0);
   // Store each mult value separately (dot-separator conflicts with decimal point)
   int nm = ArraySize(s.mults);
   GlobalVariableSet(k + "mnl", nm);
   for(int i = 0; i < nm; i++)
      GlobalVariableSet(k + "m" + IntegerToString(i), s.mults[i]);
}

void LoadState(long magic, PanelState &s, int defLayers, double defLot, double clBuf, double slMult)
{
   string k = "iSc_" + IntegerToString(magic) + "_";
   StateInit(s, defLayers, defLot);

   if(!GlobalVariableCheck(k + "layers")) return;

   s.layers          = (int)GlobalVariableGet(k + "layers");
   s.lotPerLayer     = GlobalVariableGet(k + "lot");
   s.panelX          = (int)GlobalVariableGet(k + "panX");
   s.panelY          = (int)GlobalVariableGet(k + "panY");
   if(GlobalVariableCheck(k + "panSc"))
   {
      s.panelScale = GlobalVariableGet(k + "panSc");
      if(s.panelScale < 1.0 || s.panelScale > 3.0) s.panelScale = 1.0;
   }
   if(GlobalVariableCheck(k + "panMin"))
      s.panelMinimized = (GlobalVariableGet(k + "panMin") != 0);
   s.buyFloor        = GlobalVariableGet(k + "bFloor");
   s.buyEntry        = GlobalVariableGet(k + "bEntry");
   s.buyEntryManual  = (GlobalVariableGet(k + "bEM") != 0);
   s.sellCeil        = GlobalVariableGet(k + "sCeil");
   s.sellEntry       = GlobalVariableGet(k + "sEntry");
   s.sellEntryManual = (GlobalVariableGet(k + "sEM") != 0);

   // Restore mult values from per-element GlobalVariables, rebuild display string
   if(GlobalVariableCheck(k + "mnl"))
   {
      int mnl = (int)GlobalVariableGet(k + "mnl");
      if(mnl > 0 && mnl <= 50)
      {
         string ms = "";
         bool ok = true;
         for(int i = 0; i < mnl && ok; i++)
         {
            string gk = k + "m" + IntegerToString(i);
            if(!GlobalVariableCheck(gk)) { ok = false; break; }
            double mv = GlobalVariableGet(gk);
            string tok = (MathAbs(mv - MathRound(mv)) < 0.0001)
                         ? IntegerToString((int)MathRound(mv))
                         : DoubleToString(mv, 2);
            ms += (i > 0 ? "." : "") + tok;
         }
         if(ok && ms != "") s.multStr = ms;
      }
   }
   ParseMults(s);
   RecomputeAll(s, clBuf, slMult);
}

// Draw/update ALL panel objects at current state.panelX / state.panelY
void PanelDraw(long magic, const PanelState &s)
{
   int px = s.panelX, py = s.panelY;
   bool ok = s.zoneValid && s.multValid;
   double sc = s.panelScale; if(sc < 1.0) sc = 1.0; if(sc > 3.0) sc = 3.0;
   bool   mn = s.panelMinimized;

   int titleH = _SS(PNL_TITLE_H, sc);
   int fullW  = _SS(PNL_W, sc);
   int fullH  = mn ? titleH : _SS(PNL_H, sc);
   int fs     = (int)MathMax(8, MathRound(8 * sc));
   int fs9    = (int)MathMax(9, MathRound(9 * sc));

   // --- Background ---
   _SetRect(PN(magic,"BG"), px, py, fullW, fullH, CLR_BG, clrGray, 0);

   // --- Title / drag ---
   _SetDragRect(PN(magic,"DRAG"), px, py, fullW, titleH, CLR_TITLE_BG);

   // Title label FIRST so buttons render on top (higher object index = on top)
   string scTxt = (MathAbs(sc - MathRound(sc)) < 0.01)
                  ? IntegerToString((int)MathRound(sc)) + "x"
                  : DoubleToString(sc, 1) + "x";
   int tbtnW  = _SS(22, sc);
   int btnArea = tbtnW * 3 + _SS(2, sc) * 2 + _SS(8, sc); // 3 btns + gaps + right margin
   int titleW = fullW - _SS(8, sc) - btnArea - _SS(4, sc);
   // Readonly edit clips text within titleW so it cannot overflow into buttons
   _SetEdit(PN(magic,"TITLE"), px + _SS(8, sc), py + _SS(2, sc), titleW, titleH - _SS(4, sc),
            "Personal Scalping Tool — " + _Symbol + " | " + TFStr(_Period) + "  [" + scTxt + "]",
            CLR_TITLE_BG, (color)CLR_VAL, true, fs9);

   // Title-bar buttons (right-aligned, created AFTER title so they render on top)
   int tbtnH = titleH - _SS(4, sc);
   int tbtnY = py + _SS(2, sc);
   int rx    = px + fullW - _SS(4, sc) - tbtnW;
   _SetBtn(PN(magic,"BTN_MIN"), rx, tbtnY, tbtnW, tbtnH,
           mn ? "^" : "_", CLR_BTN_BG, (color)CLR_BTN_FG, true, fs);
   rx -= (tbtnW + _SS(2, sc));
   bool szpEn = (sc < 3.0 - 0.001);
   _SetBtn(PN(magic,"BTN_SZP"), rx, tbtnY, tbtnW, tbtnH,
           "+", CLR_BTN_BG, (color)CLR_BUY_FG, szpEn, fs);
   rx -= (tbtnW + _SS(2, sc));
   bool szmEn = (sc > 1.0 + 0.001);
   _SetBtn(PN(magic,"BTN_SZM"), rx, tbtnY, tbtnW, tbtnH,
           "-", CLR_BTN_BG, (color)CLR_SELL_FG, szmEn, fs);

   if(mn)
   {
      // Hide non-title objects when minimized — destroy them
      string skipPrefix = "iScalp_" + IntegerToString(magic) + "_P_";
      string keep[] = {"BG","DRAG","TITLE","BTN_MIN","BTN_SZP","BTN_SZM"};
      int total = ObjectsTotal(0);
      for(int i = total - 1; i >= 0; i--)
      {
         string nm = ObjectName(0, i);
         if(StringFind(nm, skipPrefix) != 0) continue;
         string suf = StringSubstr(nm, StringLen(skipPrefix));
         bool isKeep = false;
         for(int j = 0; j < ArraySize(keep); j++)
            if(suf == keep[j]) { isKeep = true; break; }
         if(!isKeep) ObjectDelete(0, nm);
      }
      ChartRedraw(0);
      return;
   }

   // --- Div1: Layer Config ---
   _SetRect(PN(magic,"D1BG"), px + _SS(4, sc), py + _SS(25, sc),
            fullW - _SS(8, sc), _SS(68, sc), CLR_D1_BG, CLR_D1_BG);

   // Row1: Layers | Lot/Layer | Total
   _SetLbl(PN(magic,"LBL_LYR"),  px + _SS(8, sc),   py + _SS(32, sc), "Layers:", CLR_LBL, fs);
   _SetEdit(PN(magic,"EDT_LYR"), px + _SS(62, sc),  py + _SS(29, sc), _SS(50, sc), _SS(20, sc),
            IntegerToString(s.layers), CLR_EDIT_BG, CLR_EDIT_FG, false, fs);
   _SetLbl(PN(magic,"LBL_LOT"),  px + _SS(120, sc), py + _SS(32, sc), "Lot/Layer:", CLR_LBL, fs);
   _SetEdit(PN(magic,"EDT_LOT"), px + _SS(192, sc), py + _SS(29, sc), _SS(68, sc), _SS(20, sc),
            DoubleToString(s.lotPerLayer, 2), CLR_EDIT_BG, CLR_EDIT_FG, false, fs);
   _SetLbl(PN(magic,"LBL_TOT"),  px + _SS(272, sc), py + _SS(32, sc), "Total:", CLR_LBL, fs);
   _SetLbl(PN(magic,"VAL_TOT"),  px + _SS(310, sc), py + _SS(32, sc),
            s.multValid ? DoubleToString(s.totalLot, 2) + " lot" : "INVALID",
            s.multValid ? (color)CLR_VAL : (color)CLR_WARN, fs);

   // Row2: Mult/Layer
   _SetLbl(PN(magic,"LBL_MLT"),  px + _SS(8, sc),  py + _SS(58, sc), "Mult/Layer:", CLR_LBL, fs);
   _SetEdit(PN(magic,"EDT_MLT"), px + _SS(84, sc), py + _SS(55, sc), _SS(348, sc), _SS(20, sc),
            s.multStr,
            s.multValid ? (color)CLR_EDIT_BG : (color)0x3A0000,
            CLR_EDIT_FG, false, fs);

   // --- Div2: BUY/SELL columns ---
   _SetRect(PN(magic,"D2_BUY"), px + _SS(COL_BUY_X, sc),  py + _SS(92, sc),
            _SS(COL_W, sc), _SS(168, sc), CLR_BUY_BG,  CLR_BUY_BG);
   _SetRect(PN(magic,"D2_SEL"), px + _SS(COL_SELL_X, sc), py + _SS(92, sc),
            _SS(COL_W, sc), _SS(168, sc), CLR_SELL_BG, CLR_SELL_BG);

   int bx = px + _SS(COL_BUY_X, sc),  sx = px + _SS(COL_SELL_X, sc);
   int evx = _SS(COL_VAL_OX, sc);

   // BUY column
   _SetLbl(PN(magic,"HDR_B"),   bx + _SS(4, sc),  py + _SS(COL_HDR_Y, sc),  "BUY LIMIT",         (color)CLR_BUY_FG,  fs9);
   _SetLbl(PN(magic,"LBL_BF"),  bx + _SS(4, sc),  py + _SS(COL_FLOOR_Y + 3, sc), "Floor:",       (color)CLR_LBL, fs);
   _SetEdit(PN(magic,"EDT_BF"), bx + evx, py + _SS(COL_FLOOR_Y, sc), _SS(COL_VAL_W, sc), _SS(20, sc),
            s.buyFloor > 0 ? FmtPrice(s.buyFloor) : "", CLR_EDIT_BG, (color)CLR_BUY_FG, false, fs);
   _SetLbl(PN(magic,"LBL_BE"),  bx + _SS(4, sc),  py + _SS(COL_ENTRY_Y + 3, sc), "Entry:",       (color)CLR_LBL, fs);
   _SetEdit(PN(magic,"EDT_BE"), bx + evx, py + _SS(COL_ENTRY_Y, sc), _SS(COL_VAL_W, sc), _SS(20, sc),
            s.buyEntry > 0 ? FmtPrice(s.buyEntry) : "", CLR_EDIT_BG, (color)CLR_BUY_FG, false, fs);
   _SetLbl(PN(magic,"LBL_BC"),  bx + _SS(4, sc),  py + _SS(COL_CL_Y, sc),   "Cut Loss:",         (color)CLR_LBL, fs);
   _SetLbl(PN(magic,"VAL_BC"),  bx + evx, py + _SS(COL_CL_Y, sc),  FmtPrice(s.buyCutLoss),       (color)CLR_WARN, fs);
   _SetLbl(PN(magic,"LBL_BS"),  bx + _SS(4, sc),  py + _SS(COL_SL_Y, sc),   "Stop Loss:",        (color)CLR_LBL, fs);
   _SetLbl(PN(magic,"VAL_BS"),  bx + evx, py + _SS(COL_SL_Y, sc),  FmtPrice(s.buyStopLoss),      (color)CLR_SELL_FG, fs);
   _SetLbl(PN(magic,"LBL_BT"),  bx + _SS(4, sc),  py + _SS(COL_TP_Y, sc),   "TP:",               (color)CLR_LBL, fs);
   _SetLbl(PN(magic,"VAL_BT"),  bx + evx, py + _SS(COL_TP_Y, sc),  FmtPrice(s.buyTP),            (color)CLR_BUY_FG, fs);
   _SetBtn(PN(magic,"BTN_BUY"), bx + _SS(4, sc),  py + _SS(COL_BTN_Y, sc), _SS(COL_BTN_W, sc), _SS(COL_BTN_H, sc),
           "BUY LIMIT", (color)0x1E6B1E, (color)CLR_BUY_FG, ok, fs);

   // SELL column
   _SetLbl(PN(magic,"HDR_S"),   sx + _SS(4, sc),  py + _SS(COL_HDR_Y, sc),  "SELL LIMIT",        (color)CLR_SELL_FG, fs9);
   _SetLbl(PN(magic,"LBL_SC"),  sx + _SS(4, sc),  py + _SS(COL_FLOOR_Y + 3, sc), "Ceiling:",     (color)CLR_LBL, fs);
   _SetEdit(PN(magic,"EDT_SC"), sx + evx, py + _SS(COL_FLOOR_Y, sc), _SS(COL_VAL_W, sc), _SS(20, sc),
            s.sellCeil > 0 ? FmtPrice(s.sellCeil) : "", CLR_EDIT_BG, (color)CLR_SELL_FG, false, fs);
   _SetLbl(PN(magic,"LBL_SE"),  sx + _SS(4, sc),  py + _SS(COL_ENTRY_Y + 3, sc), "Entry:",       (color)CLR_LBL, fs);
   _SetEdit(PN(magic,"EDT_SE"), sx + evx, py + _SS(COL_ENTRY_Y, sc), _SS(COL_VAL_W, sc), _SS(20, sc),
            s.sellEntry > 0 ? FmtPrice(s.sellEntry) : "", CLR_EDIT_BG, (color)CLR_SELL_FG, false, fs);
   _SetLbl(PN(magic,"LBL_SCC"), sx + _SS(4, sc),  py + _SS(COL_CL_Y, sc),   "Cut Loss:",         (color)CLR_LBL, fs);
   _SetLbl(PN(magic,"VAL_SCC"), sx + evx, py + _SS(COL_CL_Y, sc),  FmtPrice(s.sellCutLoss),      (color)CLR_WARN, fs);
   _SetLbl(PN(magic,"LBL_SSL"), sx + _SS(4, sc),  py + _SS(COL_SL_Y, sc),   "Stop Loss:",        (color)CLR_LBL, fs);
   _SetLbl(PN(magic,"VAL_SSL"), sx + evx, py + _SS(COL_SL_Y, sc),  FmtPrice(s.sellStopLoss),     (color)CLR_SELL_FG, fs);
   _SetLbl(PN(magic,"LBL_STP"), sx + _SS(4, sc),  py + _SS(COL_TP_Y, sc),   "TP:",               (color)CLR_LBL, fs);
   _SetLbl(PN(magic,"VAL_STP"), sx + evx, py + _SS(COL_TP_Y, sc),  FmtPrice(s.sellTP),           (color)CLR_BUY_FG, fs);
   _SetBtn(PN(magic,"BTN_SEL"), sx + _SS(4, sc),  py + _SS(COL_BTN_Y, sc), _SS(COL_BTN_W, sc), _SS(COL_BTN_H, sc),
           "SELL LIMIT", (color)0x1E1E6B, (color)CLR_SELL_FG, ok, fs);

   // --- Div3: Order Management ---
   _SetRect(PN(magic,"D3BG"), px + _SS(4, sc), py + _SS(258, sc),
            fullW - _SS(8, sc), _SS(132, sc), CLR_D1_BG, CLR_D1_BG);

   _SetBtn(PN(magic,"BTN_CP"), px + _SS(4, sc), py + _SS(D3_CLOSE_Y, sc), _SS(D3_FULL_W, sc), _SS(D3_BTN_H, sc),
           "CLOSE ALL POSITIONS (" + IntegerToString(s.cntPos) + ")",
           CLR_BTN_BG, (color)CLR_BTN_FG, true, fs);
   _SetBtn(PN(magic,"BTN_DB"), px + _SS(4, sc),       py + _SS(D3_DEL_ROW_Y, sc), _SS(D3_HALF_W, sc), _SS(D3_BTN_H, sc),
           "DELETE PO BUY (" + IntegerToString(s.cntPendBuy) + ")",
           CLR_BTN_BG, (color)CLR_BUY_FG, true, fs);
   _SetBtn(PN(magic,"BTN_DS"), px + _SS(D3_SELL_X, sc), py + _SS(D3_DEL_ROW_Y, sc), _SS(D3_HALF_W, sc), _SS(D3_BTN_H, sc),
           "DELETE PO SELL (" + IntegerToString(s.cntPendSell) + ")",
           CLR_BTN_BG, (color)CLR_SELL_FG, true, fs);
   _SetBtn(PN(magic,"BTN_DA"), px + _SS(4, sc), py + _SS(D3_DELALL_Y, sc), _SS(D3_FULL_W, sc), _SS(D3_BTN_H, sc),
           "DELETE ALL PENDING (" + IntegerToString(s.cntPend) + ")",
           CLR_BTN_BG, (color)CLR_BTN_FG, true, fs);
   bool dlEnabled = (s.cntPos == 0 && s.cntPend == 0);
   _SetBtn(PN(magic,"BTN_DL"), px + _SS(4, sc), py + _SS(D3_DELLINES_Y, sc), _SS(D3_FULL_W, sc), _SS(D3_BTN_H, sc),
           "DELETE ALL LINES",
           CLR_BTN_BG, (color)CLR_WARN, dlEnabled, fs);

   // --- Warning label (only draw when there is a message) ---
   if(s.warnMsg != "")
      _SetLbl(PN(magic,"WARN"), px + _SS(8, sc), py + _SS(374, sc),
              s.warnMsg, (color)CLR_WARN, fs);
   else
      ObjectDelete(0, PN(magic,"WARN"));
   // --- Watermark (inside D3BG: py+258+132=py+390) ---
   _SetLbl(PN(magic,"WMK"), px + _SS(8, sc), py + _SS(382, sc),
           "Made by RayyanGanteng", (color)0x3A4A5A, (int)MathMax(7, MathRound(7 * sc)));

   ChartRedraw(0);
}

// Remove all panel objects from chart
void PanelDestroy(long magic)
{
   string prefix = "iScalp_" + IntegerToString(magic) + "_P_";
   ObjectsDeleteAll(0, prefix);
}

// Read current text from an edit field
string PanelEditText(long magic, const string key)
{
   return ObjectGetString(0, PN(magic, key), OBJPROP_TEXT);
}

// Main event handler — call from OnChartEvent
// Returns true if the event was consumed by the panel
bool PanelHandleEvent(long magic, PanelState &state, double clBuf, double slMult,
                      const int id, const long lparam, const double dparam, const string sparam)
{
   // --- Panel drag via title rectangle ---
   if(id == CHARTEVENT_OBJECT_DRAG && sparam == PN(magic, "DRAG"))
   {
      state.panelX = (int)ObjectGetInteger(0, PN(magic,"DRAG"), OBJPROP_XDISTANCE);
      state.panelY = (int)ObjectGetInteger(0, PN(magic,"DRAG"), OBJPROP_YDISTANCE);
      PanelDraw(magic, state);
      SaveState(magic, state);
      return true;
   }

   // --- Chart line drag (floor / ceil / entry) ---
   if(id == CHARTEVENT_OBJECT_DRAG)
   {
      bool changed = false;
      if(sparam == LN(magic, LS_BUY_FLOOR))
      {
         state.buyFloor = LineGet(magic, LS_BUY_FLOOR);
         RecomputeAll(state, clBuf, slMult);
         changed = true;
      }
      else if(sparam == LN(magic, LS_BUY_ENTRY))
      {
         state.buyEntry = LineGet(magic, LS_BUY_ENTRY);
         state.buyEntryManual = true;
         RecomputeAll(state, clBuf, slMult);
         changed = true;
      }
      else if(sparam == LN(magic, LS_SELL_CEIL))
      {
         state.sellCeil = LineGet(magic, LS_SELL_CEIL);
         RecomputeAll(state, clBuf, slMult);
         changed = true;
      }
      else if(sparam == LN(magic, LS_SELL_ENTRY))
      {
         state.sellEntry = LineGet(magic, LS_SELL_ENTRY);
         state.sellEntryManual = true;
         RecomputeAll(state, clBuf, slMult);
         changed = true;
      }
      if(changed)
      {
         PanelDraw(magic, state);
         LinesUpdateBuy(magic,  state.buyFloor,  state.buyEntry,  state.buyCutLoss,  state.buyStopLoss,  state.buyTP);
         LinesUpdateSell(magic, state.sellCeil,  state.sellEntry, state.sellCutLoss, state.sellStopLoss, state.sellTP);
         SaveState(magic, state);
         return true;
      }
   }

   // --- Edit field changes ---
   if(id == CHARTEVENT_OBJECT_ENDEDIT)
   {
      bool changed = false;
      if(sparam == PN(magic,"EDT_LYR"))
      {
         int v = (int)StringToInteger(PanelEditText(magic,"EDT_LYR"));
         if(v >= 1 && v <= 50) { state.layers = v; ParseMults(state); }
         changed = true;
      }
      else if(sparam == PN(magic,"EDT_LOT"))
      {
         double v = StringToDouble(PanelEditText(magic,"EDT_LOT"));
         if(v > 0) { state.lotPerLayer = v; ParseMults(state); }
         changed = true;
      }
      else if(sparam == PN(magic,"EDT_MLT"))
      {
         state.multStr = PanelEditText(magic,"EDT_MLT");
         ParseMults(state);
         changed = true;
      }
      else if(sparam == PN(magic,"EDT_BF"))
      {
         double v = StringToDouble(PanelEditText(magic,"EDT_BF"));
         if(v > 0) state.buyFloor = v;
         RecomputeAll(state, clBuf, slMult);
         LinesUpdateBuy(magic,  state.buyFloor,  state.buyEntry,  state.buyCutLoss,  state.buyStopLoss,  state.buyTP);
         LinesUpdateSell(magic, state.sellCeil,  state.sellEntry, state.sellCutLoss, state.sellStopLoss, state.sellTP);
         changed = true;
      }
      else if(sparam == PN(magic,"EDT_BE"))
      {
         double v = StringToDouble(PanelEditText(magic,"EDT_BE"));
         if(v > 0) { state.buyEntry = v; state.buyEntryManual = true; }
         RecomputeAll(state, clBuf, slMult);
         LinesUpdateBuy(magic,  state.buyFloor,  state.buyEntry,  state.buyCutLoss,  state.buyStopLoss,  state.buyTP);
         LinesUpdateSell(magic, state.sellCeil,  state.sellEntry, state.sellCutLoss, state.sellStopLoss, state.sellTP);
         changed = true;
      }
      else if(sparam == PN(magic,"EDT_SC"))
      {
         double v = StringToDouble(PanelEditText(magic,"EDT_SC"));
         if(v > 0) state.sellCeil = v;
         RecomputeAll(state, clBuf, slMult);
         LinesUpdateBuy(magic,  state.buyFloor,  state.buyEntry,  state.buyCutLoss,  state.buyStopLoss,  state.buyTP);
         LinesUpdateSell(magic, state.sellCeil,  state.sellEntry, state.sellCutLoss, state.sellStopLoss, state.sellTP);
         changed = true;
      }
      else if(sparam == PN(magic,"EDT_SE"))
      {
         double v = StringToDouble(PanelEditText(magic,"EDT_SE"));
         if(v > 0) { state.sellEntry = v; state.sellEntryManual = true; }
         RecomputeAll(state, clBuf, slMult);
         LinesUpdateBuy(magic,  state.buyFloor,  state.buyEntry,  state.buyCutLoss,  state.buyStopLoss,  state.buyTP);
         LinesUpdateSell(magic, state.sellCeil,  state.sellEntry, state.sellCutLoss, state.sellStopLoss, state.sellTP);
         changed = true;
      }
      if(changed)
      {
         PanelDraw(magic, state);
         SaveState(magic, state);
         return true;
      }
   }

   // --- Button clicks ---
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      // Reset button state immediately so it doesn't stay "pressed"
      if(ObjectFind(0, sparam) >= 0)
         ObjectSetInteger(0, sparam, OBJPROP_STATE, 0);

      if(sparam == PN(magic,"BTN_MIN"))
      {
         state.panelMinimized = !state.panelMinimized;
         PanelDraw(magic, state);
         SaveState(magic, state);
         return true;
      }
      if(sparam == PN(magic,"BTN_SZP"))
      {
         double ns = state.panelScale + 0.5;
         if(ns > 3.0) ns = 3.0;
         state.panelScale = ns;
         PanelDestroy(magic);
         PanelDraw(magic, state);
         SaveState(magic, state);
         return true;
      }
      if(sparam == PN(magic,"BTN_SZM"))
      {
         double ns = state.panelScale - 0.5;
         if(ns < 1.0) ns = 1.0;
         state.panelScale = ns;
         PanelDestroy(magic);
         PanelDraw(magic, state);
         SaveState(magic, state);
         return true;
      }

      if(sparam == PN(magic,"BTN_BUY"))
      {
         if(!state.zoneValid || !state.multValid)
         { state.warnMsg = "Invalid zone or mult config"; PanelDraw(magic,state); return true; }
         string warn = ValidateSLDistance(state.buyEntry, state.buyStopLoss, ORDER_TYPE_BUY_LIMIT);
         if(warn != "") { state.warnMsg = warn; PanelDraw(magic,state); return true; }
         state.warnMsg = "";
         if(!PlaceBuyLayers(magic, state.layers, state.lotPerLayer, state.mults,
                            state.buyFloor, state.buyEntry, state.buyStopLoss, state.buyTP))
            state.warnMsg = "Some BUY orders failed — check Journal";
         RefreshCounts(magic, state);
         PanelDraw(magic, state);
         return true;
      }
      if(sparam == PN(magic,"BTN_SEL"))
      {
         if(!state.zoneValid || !state.multValid)
         { state.warnMsg = "Invalid zone or mult config"; PanelDraw(magic,state); return true; }
         string warn = ValidateSLDistance(state.sellEntry, state.sellStopLoss, ORDER_TYPE_SELL_LIMIT);
         if(warn != "") { state.warnMsg = warn; PanelDraw(magic,state); return true; }
         state.warnMsg = "";
         if(!PlaceSellLayers(magic, state.layers, state.lotPerLayer, state.mults,
                             state.sellCeil, state.sellEntry, state.sellStopLoss, state.sellTP))
            state.warnMsg = "Some SELL orders failed — check Journal";
         RefreshCounts(magic, state);
         PanelDraw(magic, state);
         return true;
      }
      if(sparam == PN(magic,"BTN_CP"))
      {
         CloseAllPositions(magic);
         RefreshCounts(magic, state);
         PanelDraw(magic, state);
         return true;
      }
      if(sparam == PN(magic,"BTN_DB"))
      {
         DeletePendingBuy(magic);
         RefreshCounts(magic, state);
         PanelDraw(magic, state);
         return true;
      }
      if(sparam == PN(magic,"BTN_DS"))
      {
         DeletePendingSell(magic);
         RefreshCounts(magic, state);
         PanelDraw(magic, state);
         return true;
      }
      if(sparam == PN(magic,"BTN_DA"))
      {
         DeleteAllPending(magic);
         RefreshCounts(magic, state);
         PanelDraw(magic, state);
         return true;
      }
      if(sparam == PN(magic,"BTN_DL"))
      {
         RefreshCounts(magic, state);
         if(state.cntPos != 0 || state.cntPend != 0)
         {
            state.warnMsg = "Cannot delete lines: positions or pending orders exist";
            PanelDraw(magic, state);
            return true;
         }
         LinesDeleteAll(magic);
         state.buyFloor = 0; state.buyEntry = 0; state.buyCutLoss = 0;
         state.buyStopLoss = 0; state.buyTP = 0; state.buyEntryManual = false;
         state.sellCeil = 0; state.sellEntry = 0; state.sellCutLoss = 0;
         state.sellStopLoss = 0; state.sellTP = 0; state.sellEntryManual = false;
         state.zoneValid = false;
         state.warnMsg = "";
         PanelDraw(magic, state);
         SaveState(magic, state);
         return true;
      }
   }

   return false;
}

#endif
