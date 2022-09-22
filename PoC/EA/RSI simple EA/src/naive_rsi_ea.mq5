//+------------------------------------------------------------------+
//|                                                       RSI_EA.mq5 |
//|                                                        69Billion |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "69Billion"
#property link      "https://www.mql5.com"
#property version   "1.00"

#property description "EA Based on RSI Indicator"
#property description "Sell if: rsi_9 < min(MA_9, MA_18)"
#property description "Buy  if: rsi_9 > max(MA_9, MA_18)"
#property description "Exit Short if: rsi_9 >= MA_9"
#property description "Exit Long  if: rsi_9 <= MA_9"

//+------------------------------------------------------------------+
//| Includes                                                         |
//+------------------------------------------------------------------+

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Math/Stat/Math.mqh>

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+

input group "Money management"
input double Lot = 0.1;
//input int StopLoss=30;
//input int TakeProfit=100;


input group "Period"
input int RSI_Period = 9;


input group "Miscellaneous"
input int EA_Magic = 12345;
input string OrderComment= "69Billion-RSI-EA";
input int Slippage = 100; // Slippage: Tolerated slippage in points.


//+------------------------------------------------------------------+
//| Global Vars                                                      |
//+------------------------------------------------------------------+


CTrade *Trade;
CPositionInfo PositionInfo;
ulong LastBars = 0;
bool HaveLongPosition;
bool HaveShortPosition;
double StopLoss;
int file_handle;

// indicator handles
int rsi_handle;


// buffers
double rsi_buffer_9[];
double rsi_buffer_18[];

//+------------------------------------------------------------------+
//| Helper functions                                                 |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GetPositionStates()
  {

// Is there a position on this currency pair?
   PrintFormat("PositionInfoSelect: ", PositionInfo.Select(Symbol()));
   if(PositionInfo.Select(Symbol()))
     {

      Print("Got Position info");
      if(PositionInfo.PositionType() == POSITION_TYPE_BUY)
        {
         Print("Buy Position");
         HaveLongPosition = true;
         HaveShortPosition = false;
        }
      else
         if(PositionInfo.PositionType() == POSITION_TYPE_SELL)
           {
            Print("Sell Position");
            HaveLongPosition = false;
            HaveShortPosition = true;
           }
     }
   else
     {
      Print("Default Position");
      HaveLongPosition = false;
      HaveShortPosition = false;
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ClosePrevious()
  {
   for(int i = 0; i < 10; i++)
     {
      Trade.PositionClose(Symbol(), Slippage);
      if((Trade.ResultRetcode() != 10008) && (Trade.ResultRetcode() != 10009) && (Trade.ResultRetcode() != 10010))
         Print("Position Close Return Code: ", Trade.ResultRetcodeDescription());
      else
         return;
     }
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void fBuy()
  {
   double Ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   Trade.PositionOpen(Symbol(), ORDER_TYPE_BUY, Lot, Ask, 0, 0, OrderComment);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void fSell()
  {
   double Bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   Trade.PositionOpen(Symbol(), ORDER_TYPE_SELL, Lot, Bid, 0, 0, OrderComment);
  }



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

// init CTrade
   Trade = new CTrade;
   Trade.SetDeviationInPoints(Slippage);

// Get handle for RSI
   rsi_handle = iRSI(Symbol(), Period(), RSI_Period, PRICE_CLOSE);

   if(rsi_handle == INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iRSI indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }

   return(INIT_SUCCEEDED);
  }



//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   delete Trade;
  }



//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if((!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) || (!TerminalInfoInteger(TERMINAL_CONNECTED)) || (SymbolInfoInteger(Symbol(), SYMBOL_TRADE_MODE) != SYMBOL_TRADE_MODE_FULL))
      return;

   int bars = Bars(Symbol(), _Period);


   if(bars < 18)
     {
      Alert("We have less than 18 bars, EA will now exit!!");
      return;
     }

// Trade only if new bar has arrived.
   if(LastBars != bars)
      LastBars = bars;
   else
      return;


   if(CopyBuffer(rsi_handle, 0, 0, 18, rsi_buffer_18) != 18 || CopyBuffer(rsi_handle, 0, 0, 9, rsi_buffer_9) != 9)
     {
      Alert("Error copying RSI indicator buffer");
      return;
     }

   double avg_9=0, avg_18=0;
   avg_9 = MathMean(rsi_buffer_9);
   avg_18 = MathMean(rsi_buffer_18);

   bool buy_condition = rsi_buffer_9[0] > MathMax(avg_9, avg_18);
   bool sell_condition = rsi_buffer_9[0] < MathMin(avg_9, avg_18);

   bool exit_long  = rsi_buffer_9[0] <= avg_9;
   bool exit_short = rsi_buffer_9[0] >= avg_9;


   GetPositionStates();

   if((HaveLongPosition) && (exit_long))
     {
      ClosePrevious();
      GetPositionStates();
      return;
     }


   if((HaveShortPosition) && (exit_short))
     {
      ClosePrevious();
      GetPositionStates();
      return;
     }


   if(buy_condition)
     {
      if(!HaveLongPosition)
        {
         // logic for buying
         fBuy();
         GetPositionStates();

         return;
        }
     }

   if(sell_condition)
     {
      if(!HaveShortPosition)
        {
         // logic for selling
         fSell();
         GetPositionStates();
         return;
        }
     }

  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
