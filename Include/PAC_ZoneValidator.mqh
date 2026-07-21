//+------------------------------------------------------------------+
//| PAC_ZoneValidator.mqh — Bounce counting, consumed%, invalidation |
//+------------------------------------------------------------------+
#ifndef PAC_ZONEVALIDATOR_MQH
#define PAC_ZONEVALIDATOR_MQH

#include "PAC_ControlZone.mqh"

enum EAState
{
   STATE_SCAN = 0,
   STATE_WAIT_BOUNCE,
   STATE_TRADE_ACTIVE,
   STATE_INVALIDATED
};

// Zone consumed percentage
//   RBR BUY:  consumed = (Ceiling - CurrentPrice) / (Ceiling - Floor) * 100
//   DBD SELL: consumed = (CurrentPrice - Floor) / (Ceiling - Floor) * 100
double PAC_ConsumedPercent(const ControlZone &z)
{
   double range = z.ceiling - z.floor;
   if(range <= 0) return 0;
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(z.type == ZONE_RBR)
      return (z.ceiling - bid) / range * 100.0;
   else
      return (bid - z.floor) / range * 100.0;
}

// Check if entry is allowed given bounce count and zone state
bool PAC_EntryAllowed(int bounceCount, int minBounces, int maxBounces,
                      bool aggressiveMode, double consumeThreshold,
                      const ControlZone &z)
{
   if(bounceCount < minBounces) return false;
   if(bounceCount <= maxBounces) return true;

   // bounceCount > maxBounces
   if(!aggressiveMode) return false;
   double consumed = PAC_ConsumedPercent(z);
   return (consumed < consumeThreshold);
}

// Called each new bar to track zone visits.
// Returns: 1 = bounce counted, -1 = breakout (zone invalid), 0 = no change.
// Caller must track g_inZone across calls.
int PAC_CheckBounce(ENUM_TIMEFRAMES tf, const ControlZone &z, bool &inZone)
{
   double close1 = iClose(_Symbol, tf, 1);
   bool   inside = (close1 >= z.floor && close1 <= z.ceiling);

   if(!inZone && inside)
   {
      inZone = true;
      return 0;
   }

   if(inZone && !inside)
   {
      inZone = false;
      bool exitedAbove = (close1 > z.ceiling);
      bool exitedBelow = (close1 < z.floor);

      if(z.type == ZONE_RBR)
      {
         if(exitedAbove) return 1;   // bounce: price re-tested base and left upward
         if(exitedBelow) return -1;  // breakout: zone broken to the downside
      }
      else // ZONE_DBD
      {
         if(exitedBelow) return 1;   // bounce
         if(exitedAbove) return -1;  // breakout
      }
   }
   return 0;
}

// Check zone invalidation rules 2–4 (rule 1 = cut loss, handled separately)
bool PAC_IsZoneInvalidated(int bounceCount, int maxBounces,
                           bool aggressiveMode, double consumeThreshold,
                           const ControlZone &z)
{
   // Rule 2: bounce count exceeded + aggressive off
   if(bounceCount > maxBounces && !aggressiveMode) return true;

   // Rule 3: consumed >= threshold AND bounces >= 3
   if(bounceCount >= 3 && PAC_ConsumedPercent(z) >= consumeThreshold) return true;

   // Rule 4 (opposing pattern inside zone) is evaluated by the caller
   // after calling PAC_DetectZone on the zone corridor

   return false;
}

#endif
