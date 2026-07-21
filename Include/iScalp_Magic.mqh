//+------------------------------------------------------------------+
//| iScalp_Magic.mqh — magic number derivation (symbol+timeframe)    |
//+------------------------------------------------------------------+
#ifndef ISCALP_MAGIC_MQH
#define ISCALP_MAGIC_MQH

ushort CRC16Str(const string s)
{
   ushort crc = 0xFFFF;
   for(int i = 0, n = StringLen(s); i < n; i++)
   {
      crc ^= (ushort)StringGetCharacter(s, i) << 8;
      for(int b = 0; b < 8; b++)
         crc = ((crc & 0x8000) !=0) ? (ushort)((crc << 1) ^ 0x1021) : (ushort)(crc << 1);
   }
   return crc;
}

int PeriodCode(ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M1:  return 1;    case PERIOD_M2:  return 2;
      case PERIOD_M3:  return 3;    case PERIOD_M4:  return 4;
      case PERIOD_M5:  return 5;    case PERIOD_M6:  return 6;
      case PERIOD_M10: return 10;   case PERIOD_M12: return 12;
      case PERIOD_M15: return 15;   case PERIOD_M20: return 20;
      case PERIOD_M30: return 30;   case PERIOD_H1:  return 60;
      case PERIOD_H2:  return 120;  case PERIOD_H3:  return 180;
      case PERIOD_H4:  return 240;  case PERIOD_H6:  return 360;
      case PERIOD_H8:  return 480;  case PERIOD_H12: return 720;
      case PERIOD_D1:  return 1440; case PERIOD_W1:  return 10080;
      case PERIOD_MN1: return 43200;
      default:         return (int)tf;
   }
}

string TFStr(ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M1:  return "M1";   case PERIOD_M2:  return "M2";
      case PERIOD_M3:  return "M3";   case PERIOD_M4:  return "M4";
      case PERIOD_M5:  return "M5";   case PERIOD_M6:  return "M6";
      case PERIOD_M10: return "M10";  case PERIOD_M12: return "M12";
      case PERIOD_M15: return "M15";  case PERIOD_M20: return "M20";
      case PERIOD_M30: return "M30";  case PERIOD_H1:  return "H1";
      case PERIOD_H2:  return "H2";   case PERIOD_H3:  return "H3";
      case PERIOD_H4:  return "H4";   case PERIOD_H6:  return "H6";
      case PERIOD_H8:  return "H8";   case PERIOD_H12: return "H12";
      case PERIOD_D1:  return "D1";   case PERIOD_W1:  return "W1";
      case PERIOD_MN1: return "MN";
      default: return EnumToString(tf);
   }
}

// Magic is per-SYMBOL only — deliberately timeframe-independent so that
// switching TF keeps the same orders, panel state and chart lines.
long DeriveMagic()
{
   return 79000000L + (long)CRC16Str(_Symbol);
}

#endif
