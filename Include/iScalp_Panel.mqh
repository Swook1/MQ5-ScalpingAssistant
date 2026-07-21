//+------------------------------------------------------------------+
//| iScalp_Panel.mqh — floating control panel (native chart objects)  |
//+------------------------------------------------------------------+
//
// Panel layout at 1x scale (all Y relative to panel top-left):
//
//  [0..23]   Title / drag handle + SIZE(1x/2x/3x) + MINIMIZE buttons
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

// Panel base pixel dimensions (1x scale)
#define PNL_W         440
#define PNL_H         376
#define PNL_TITLE_H   24

// Column X offsets (from panel origin, 1x)
#define COL_BUY_X     4
#define COL_SELL_X    220
#define COL_W         216
#define COL_LBL_OX    4
#define COL_VAL_OX    78
#define COL_VAL_W     134

// Column field Y offsets (from panel origin, 1x)
#define COL_HDR_Y     97
#define COL_FLOOR_Y   118
#define COL_ENTRY_Y   141
#define COL_CL_Y      165
#define COL_SL_Y      187
#define COL_TP_Y      209
#define COL_BTN_Y     230
#define COL_BTN_H     26
#define COL_BTN_W     208

// Div3 Y offsets (1x)
#define D3_CLOSE_Y    264
#define D3_DEL_ROW_Y  290
#define D3_DELALL_Y   318
#define D3_BTN_H      24
#define D3_FULL_W     432
#define D3_HALF_W     212
#define D3_SELL_X     224

// Colors
#define CLR_BG        (color)0x1C2127
#define CLR_D1_BG     (color)0x242B34
#define CLR_BUY_BG    (color)0x0B1A0B
#define CLR_SELL_BG   (color)0x1A0B0B
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

   // Panel position and display
   int    panelX;
   int    panelY;
   int    panelScale;      // 1, 2, or 3
   bool   panelMinimized;

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
   ObjectSetInteger(0, n, OBJPROP_CORNER,      CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE,   x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE,   y);
   ObjectSetInteger(0, n, OBJPROP_XSIZE,       w);
   ObjectSetInteger(0, n, OBJPROP_YSIZE,       h);
   ObjectSetInteger(0, n, OBJPROP_BGCOLOR,     bg);
   ObjectSetInteger(0, n, OBJPROP_COLOR,       bdr);
   ObjectSetInteger(0, n, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE,  0);
   ObjectSetInteger(0, n, OBJPROP_HIDDEN,      1);
   ObjectSetInteger(0, n, OBJPROP_ZORDER,      zorder);
}

void _SetDragRect(const string n, int x, int y, int w, int h, color bg)
{
   if(ObjectFind(0, n) < 0) ObjectCreate(0, n, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_CORNER,      CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE,   x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE,   y);
   ObjectSetInteger(0, n, OBJPROP_XSIZE,       w);
   ObjectSetInteger(0, n, OBJPROP_YSIZE,       h);
   ObjectSetInteger(0, n, OBJPROP_BGCOLOR,     bg);
   ObjectSetInteger(0, n, OBJPROP_COLOR,       bg);
   ObjectSetInteger(0, n, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE,  1);
   ObjectSetInteger(0, n, OBJPROP_SELECTED,    0);
   ObjectSetInteger(0, n, OBJPROP_HIDDEN,      1);
   ObjectSetInteger(0, n, OBJPROP_ZORDER,      1);
}

void _SetLbl(const string n, int x, int y, const string txt, color clr, int fsize = 8)
{
   if(ObjectFind(0, n) < 0) ObjectCreate(0, n, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_CORNER,     CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE,  x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE,  y);
   ObjectSetString(0,  n, OBJPROP_TEXT,       txt);
   ObjectSetInteger(0, n, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE,   fsize);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, 0);
   ObjectSetInteger(0, n, OBJPROP_HIDDEN,     1);
   ObjectSetInteger(0, n, OBJPROP_ZORDER,     10);
}

void _SetEdit(const string n, int x, int y, int w, int h,
              const string txt, color bg, color fg, bool rdonly = false, int fsize = 8)
{
   if(ObjectFind(0, n) < 0) ObjectCreate(0, n, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_CORNER,     CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE,  x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE,  y);
   ObjectSetInteger(0, n, OBJPROP_XSIZE,      w);
   ObjectSetInteger(0, n, OBJPROP_YSIZE,      h);
   ObjectSetString(0,  n, OBJPROP_TEXT,       txt);
   ObjectSetInteger(0, n, OBJPROP_BGCOLOR,    bg);
   ObjectSetInteger(0, n, OBJPROP_COLOR,      fg);
   ObjectSetInteger(0, n, OBJPROP_READONLY,   rdonly ? 1 : 0);
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE,   fsize);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, 0);
   ObjectSetInteger(0, n, OBJPROP_HIDDEN,     1);
   ObjectSetInteger(0, n, OBJPROP_ZORDER,     10);
}

void _SetBtn(const string n, int x, int y, int w, int h,
             const string txt, color bg, color fg, bool enabled = true, int fsize = 8)
{
   if(ObjectFind(0, n) < 0) ObjectCreate(0, n, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_CORNER,     CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE,  x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE,  y);
   ObjectSetInteger(0, n, OBJPROP_XSIZE,      w);
   ObjectSetInteger(0, n, OBJPROP_YSIZE,      h);
   ObjectSetString(0,  n, OBJPROP_TEXT,       txt);
   ObjectSetInteger(0, n, OBJPROP_BGCOLOR,    enabled ? bg : (color)CLR_INACTIVE);
   ObjectSetInteger(0, n, OBJPROP_COLOR,      enabled ? fg : (color)CLR_BTN_FG);
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE,   fsize);
   ObjectSetInteger(0, n, OBJPROP_STATE,      0);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, 0);
   ObjectSetInteger(0, n, OBJPROP_HIDDEN,     1);
   ObjectSetInteger(0, n, OBJPROP_ZORDER,     10);
}

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

string DefaultMultStr(int layers)
{
   string r = "";
   for(int i = 0; i < layers; i++)
      r += (i > 0 ? "." : "") + "1";
   return r;
}

void StateInit(PanelState &s, int defLayers, double defLot)
{
   s.layers          = defLayers;
   s.lotPerLayer     = defLot;
   s.multStr         = DefaultMultStr(defLayers);
   ParseMults(s);
   s.buyFloor        = 0; s.buyEntry    = 0; s.buyCutLoss  = 0;
   s.buyStopLoss     = 0; s.buyTP       = 0; s.buyEntryManual  = false;
   s.sellCeil        = 0; s.sellEntry   = 0; s.sellCutLoss = 0;
   s.sellStopLoss    = 0; s.sellTP      = 0; s.sellEntryManual = false;
   s.panelX          = 20; s.panelY     = 50;
   s.panelScale      = 1;
   s.panelMinimized  = false;
   s.cntPos          = 0;  s.cntPendBuy = 0; s.cntPendSell = 0; s.cntPend = 0;
   s.zoneValid       = false; s.warnMsg  = "";
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
   GlobalVariableSet(k + "scale",   s.panelScale);
   GlobalVariableSet(k + "mini",    s.panelMinimized ? 1 : 0);
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
   s.buyFloor        = GlobalVariableGet(k + "bFloor");
   s.buyEntry        = GlobalVariableGet(k + "bEntry");
   s.buyEntryManual  = (GlobalVariableGet(k + "bEM") != 0);
   s.sellCeil        = GlobalVariableGet(k + "sCeil");
   s.sellEntry       = GlobalVariableGet(k + "sEntry");
   s.sellEntryManual = (GlobalVariableGet(k + "sEM") != 0);

   if(GlobalVariableCheck(k + "scale"))
   {
      s.panelScale = (int)GlobalVariableGet(k + "scale");
      if(s.panelScale < 1 || s.panelScale > 3) s.panelScale = 1;
   }
   if(GlobalVariableCheck(k + "mini"))
      s.panelMinimized = (GlobalVariableGet(k + "mini") != 0);

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

// Draw/update ALL panel objects at current state.panelX / state.panelY.
// All pixel coords are multiplied by state.panelScale (1/2/3).
void PanelDraw(long magic, const PanelState &s)
{
   int px = s.panelX, py = s.panelY;
   int sc = s.panelScale;
   bool ok = s.zoneValid && s.multValid;

   // Scaled dimensions
   int pw  = PNL_W * sc;
   int th  = PNL_TITLE_H * sc;
   int ph  = s.panelMinimized ? th : PNL_H * sc;

   // Font sizes: 8/10/12 for sc 1/2/3
   int fs  = 6 + sc * 2;
   int fsh = fs + 1;

   // --- Background ---
   _SetRect(PN(magic,"BG"), px, py, pw, ph, CLR_BG, clrGray, 0);

   // --- Title / drag (covers left portion; buttons on right) ---
   _SetDragRect(PN(magic,"DRAG"), px, py, pw - 48*sc, th, CLR_TITLE_BG);
   _SetLbl(PN(magic,"TITLE"), px + 8, py + 6*sc,
           "iScalp — " + _Symbol + " | " + TFStr(_Period),
           (color)CLR_VAL, fsh);

   // SIZE button (cycles 1x→2x→3x→1x)
   _SetBtn(PN(magic,"BTN_SZ"),
           px + pw - 47*sc, py + 1, 23*sc, th - 2,
           IntegerToString(sc) + "x",
           CLR_BTN_BG, (color)CLR_BTN_FG, true, fs);

   // MINIMIZE / RESTORE button
   _SetBtn(PN(magic,"BTN_MIN"),
           px + pw - 22*sc, py + 1, 20*sc, th - 2,
           s.panelMinimized ? "+" : "-",
           CLR_BTN_BG, (color)CLR_BTN_FG, true, fs);

   // Stop here when minimized — non-title objects were destroyed when entering minimized
   if(s.panelMinimized)
   {
      ChartRedraw(0);
      return;
   }

   // --- Div1: Layer Config ---
   _SetRect(PN(magic,"D1BG"), px+4*sc, py+25*sc, (PNL_W-8)*sc, 68*sc, CLR_D1_BG, CLR_D1_BG);

   _SetLbl(PN(magic,"LBL_LYR"),  px+8*sc,   py+32*sc, "Layers:",    CLR_LBL, fs);
   _SetEdit(PN(magic,"EDT_LYR"), px+62*sc,  py+29*sc, 50*sc, 20*sc,
            IntegerToString(s.layers), CLR_EDIT_BG, CLR_EDIT_FG, false, fs);
   _SetLbl(PN(magic,"LBL_LOT"),  px+120*sc, py+32*sc, "Lot/Layer:", CLR_LBL, fs);
   _SetEdit(PN(magic,"EDT_LOT"), px+192*sc, py+29*sc, 68*sc, 20*sc,
            DoubleToString(s.lotPerLayer, 2), CLR_EDIT_BG, CLR_EDIT_FG, false, fs);
   _SetLbl(PN(magic,"LBL_TOT"),  px+272*sc, py+32*sc, "Total:",     CLR_LBL, fs);
   _SetLbl(PN(magic,"VAL_TOT"),  px+310*sc, py+32*sc,
           s.multValid ? DoubleToString(s.totalLot, 2) + " lot" : "INVALID",
           s.multValid ? (color)CLR_VAL : (color)CLR_WARN, fs);

   _SetLbl(PN(magic,"LBL_MLT"),  px+8*sc,  py+58*sc, "Mult/Layer:", CLR_LBL, fs);
   _SetEdit(PN(magic,"EDT_MLT"), px+84*sc, py+55*sc, 348*sc, 20*sc,
            s.multStr,
            s.multValid ? (color)CLR_EDIT_BG : (color)0x3A0000,
            CLR_EDIT_FG, false, fs);

   // --- Div2: BUY / SELL columns ---
   int bx  = px + COL_BUY_X  * sc;
   int sx2 = px + COL_SELL_X * sc;
   int evx = COL_VAL_OX * sc;

   _SetRect(PN(magic,"D2_BUY"), bx,  py+92*sc, COL_W*sc, 168*sc, CLR_BUY_BG,  CLR_BUY_BG);
   _SetRect(PN(magic,"D2_SEL"), sx2, py+92*sc, COL_W*sc, 168*sc, CLR_SELL_BG, CLR_SELL_BG);

   // BUY column
   _SetLbl(PN(magic,"HDR_B"),   bx+4*sc, py+COL_HDR_Y*sc,          "BUY LIMIT",            (color)CLR_BUY_FG,  fsh);
   _SetLbl(PN(magic,"LBL_BF"),  bx+4*sc, py+(COL_FLOOR_Y+3)*sc,    "Floor:",               (color)CLR_LBL,     fs);
   _SetEdit(PN(magic,"EDT_BF"), bx+evx,  py+COL_FLOOR_Y*sc,        COL_VAL_W*sc, 20*sc,
            s.buyFloor > 0 ? FmtPrice(s.buyFloor) : "", CLR_EDIT_BG, (color)CLR_BUY_FG, false, fs);
   _SetLbl(PN(magic,"LBL_BE"),  bx+4*sc, py+(COL_ENTRY_Y+3)*sc,    "Entry:",               (color)CLR_LBL,     fs);
   _SetEdit(PN(magic,"EDT_BE"), bx+evx,  py+COL_ENTRY_Y*sc,        COL_VAL_W*sc, 20*sc,
            s.buyEntry > 0 ? FmtPrice(s.buyEntry) : "", CLR_EDIT_BG, (color)CLR_BUY_FG, false, fs);
   _SetLbl(PN(magic,"LBL_BC"),  bx+4*sc, py+COL_CL_Y*sc,           "Cut Loss:",            (color)CLR_LBL,     fs);
   _SetLbl(PN(magic,"VAL_BC"),  bx+evx,  py+COL_CL_Y*sc,           FmtPrice(s.buyCutLoss),  (color)CLR_WARN,   fs);
   _SetLbl(PN(magic,"LBL_BS"),  bx+4*sc, py+COL_SL_Y*sc,           "Stop Loss:",           (color)CLR_LBL,     fs);
   _SetLbl(PN(magic,"VAL_BS"),  bx+evx,  py+COL_SL_Y*sc,           FmtPrice(s.buyStopLoss), (color)CLR_SELL_FG, fs);
   _SetLbl(PN(magic,"LBL_BT"),  bx+4*sc, py+COL_TP_Y*sc,           "TP:",                  (color)CLR_LBL,     fs);
   _SetLbl(PN(magic,"VAL_BT"),  bx+evx,  py+COL_TP_Y*sc,           FmtPrice(s.buyTP),       (color)CLR_BUY_FG,  fs);
   _SetBtn(PN(magic,"BTN_BUY"), bx+4*sc, py+COL_BTN_Y*sc,          COL_BTN_W*sc, COL_BTN_H*sc,
           "BUY LIMIT", (color)0x1A4A1A, (color)CLR_BUY_FG, ok, fs);

   // SELL column
   _SetLbl(PN(magic,"HDR_S"),   sx2+4*sc, py+COL_HDR_Y*sc,         "SELL LIMIT",            (color)CLR_SELL_FG, fsh);
   _SetLbl(PN(magic,"LBL_SC"),  sx2+4*sc, py+(COL_FLOOR_Y+3)*sc,   "Ceiling:",              (color)CLR_LBL,     fs);
   _SetEdit(PN(magic,"EDT_SC"), sx2+evx,  py+COL_FLOOR_Y*sc,       COL_VAL_W*sc, 20*sc,
            s.sellCeil > 0 ? FmtPrice(s.sellCeil) : "", CLR_EDIT_BG, (color)CLR_SELL_FG, false, fs);
   _SetLbl(PN(magic,"LBL_SE"),  sx2+4*sc, py+(COL_ENTRY_Y+3)*sc,   "Entry:",                (color)CLR_LBL,     fs);
   _SetEdit(PN(magic,"EDT_SE"), sx2+evx,  py+COL_ENTRY_Y*sc,       COL_VAL_W*sc, 20*sc,
            s.sellEntry > 0 ? FmtPrice(s.sellEntry) : "", CLR_EDIT_BG, (color)CLR_SELL_FG, false, fs);
   _SetLbl(PN(magic,"LBL_SCC"), sx2+4*sc, py+COL_CL_Y*sc,          "Cut Loss:",             (color)CLR_LBL,     fs);
   _SetLbl(PN(magic,"VAL_SCC"), sx2+evx,  py+COL_CL_Y*sc,          FmtPrice(s.sellCutLoss),  (color)CLR_WARN,   fs);
   _SetLbl(PN(magic,"LBL_SSL"), sx2+4*sc, py+COL_SL_Y*sc,          "Stop Loss:",            (color)CLR_LBL,     fs);
   _SetLbl(PN(magic,"VAL_SSL"), sx2+evx,  py+COL_SL_Y*sc,          FmtPrice(s.sellStopLoss), (color)CLR_BUY_FG,  fs);
   _SetLbl(PN(magic,"LBL_STP"), sx2+4*sc, py+COL_TP_Y*sc,          "TP:",                   (color)CLR_LBL,     fs);
   _SetLbl(PN(magic,"VAL_STP"), sx2+evx,  py+COL_TP_Y*sc,          FmtPrice(s.sellTP),       (color)CLR_SELL_FG, fs);
   _SetBtn(PN(magic,"BTN_SEL"), sx2+4*sc, py+COL_BTN_Y*sc,         COL_BTN_W*sc, COL_BTN_H*sc,
           "SELL LIMIT", (color)0x4A1A1A, (color)CLR_SELL_FG, ok, fs);

   // --- Div3: Order Management ---
   _SetRect(PN(magic,"D3BG"), px+4*sc, py+258*sc, (PNL_W-8)*sc, 108*sc, CLR_D1_BG, CLR_D1_BG);

   _SetBtn(PN(magic,"BTN_CP"), px+4*sc,         py+D3_CLOSE_Y*sc,   D3_FULL_W*sc, D3_BTN_H*sc,
           "CLOSE ALL POSITIONS (" + IntegerToString(s.cntPos) + ")",
           CLR_BTN_BG, (color)CLR_BTN_FG, true, fs);
   _SetBtn(PN(magic,"BTN_DB"), px+4*sc,         py+D3_DEL_ROW_Y*sc, D3_HALF_W*sc, D3_BTN_H*sc,
           "DELETE PO BUY (" + IntegerToString(s.cntPendBuy) + ")",
           CLR_BTN_BG, (color)CLR_BUY_FG, true, fs);
   _SetBtn(PN(magic,"BTN_DS"), px+D3_SELL_X*sc, py+D3_DEL_ROW_Y*sc, D3_HALF_W*sc, D3_BTN_H*sc,
           "DELETE PO SELL (" + IntegerToString(s.cntPendSell) + ")",
           CLR_BTN_BG, (color)CLR_SELL_FG, true, fs);
   _SetBtn(PN(magic,"BTN_DA"), px+4*sc,         py+D3_DELALL_Y*sc,  D3_FULL_W*sc, D3_BTN_H*sc,
           "DELETE ALL PENDING (" + IntegerToString(s.cntPend) + ")",
           CLR_BTN_BG, (color)CLR_BTN_FG, true, fs);

   // --- Warning label ---
   _SetLbl(PN(magic,"WARN"), px+8*sc, py+350*sc, s.warnMsg, (color)CLR_WARN, fs);

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
         LinesUpdateBuy(magic, state.buyFloor, state.buyEntry, state.buyCutLoss, state.buyStopLoss, state.buyTP);
         changed = true;
      }
      else if(sparam == PN(magic,"EDT_BE"))
      {
         double v = StringToDouble(PanelEditText(magic,"EDT_BE"));
         if(v > 0) { state.buyEntry = v; state.buyEntryManual = true; }
         RecomputeAll(state, clBuf, slMult);
         LinesUpdateBuy(magic, state.buyFloor, state.buyEntry, state.buyCutLoss, state.buyStopLoss, state.buyTP);
         changed = true;
      }
      else if(sparam == PN(magic,"EDT_SC"))
      {
         double v = StringToDouble(PanelEditText(magic,"EDT_SC"));
         if(v > 0) state.sellCeil = v;
         RecomputeAll(state, clBuf, slMult);
         LinesUpdateSell(magic, state.sellCeil, state.sellEntry, state.sellCutLoss, state.sellStopLoss, state.sellTP);
         changed = true;
      }
      else if(sparam == PN(magic,"EDT_SE"))
      {
         double v = StringToDouble(PanelEditText(magic,"EDT_SE"));
         if(v > 0) { state.sellEntry = v; state.sellEntryManual = true; }
         RecomputeAll(state, clBuf, slMult);
         LinesUpdateSell(magic, state.sellCeil, state.sellEntry, state.sellCutLoss, state.sellStopLoss, state.sellTP);
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
      if(ObjectFind(0, sparam) >= 0)
         ObjectSetInteger(0, sparam, OBJPROP_STATE, 0);

      if(sparam == PN(magic,"BTN_SZ"))
      {
         state.panelScale = (state.panelScale % 3) + 1;
         PanelDraw(magic, state);
         SaveState(magic, state);
         return true;
      }
      if(sparam == PN(magic,"BTN_MIN"))
      {
         if(!state.panelMinimized)
            PanelDestroy(magic);   // clear body objects before collapsing
         state.panelMinimized = !state.panelMinimized;
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
         LinesDeleteAll(magic);
         state.buyFloor       = 0; state.buyEntry    = 0; state.buyCutLoss  = 0;
         state.buyStopLoss    = 0; state.buyTP       = 0; state.buyEntryManual  = false;
         state.sellCeil       = 0; state.sellEntry   = 0; state.sellCutLoss = 0;
         state.sellStopLoss   = 0; state.sellTP      = 0; state.sellEntryManual = false;
         state.zoneValid      = false; state.warnMsg  = "";
         RefreshCounts(magic, state);
         PanelDraw(magic, state);
         SaveState(magic, state);
         return true;
      }
   }

   return false;
}

#endif
