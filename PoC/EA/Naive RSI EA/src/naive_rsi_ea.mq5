//+------------------------------------------------------------------+
//|                                                       RSI_EA.mq5 |
//|                                                        69Billion |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "69Billion"
#property link      "https://www.mql5.com"
#property version   "1.00"

#property description "EA Based on RSI Indicator"
#property description "Sell if: rsi_1 < min(MA_1, MA_2)"
#property description "Buy  if: rsi_1 > max(MA_1, MA_2)"
#property description "Exit Short if: rsi_1 >= MA_1"
#property description "Exit Long  if: rsi_1 <= MA_1"

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
input int StopLoss = 40;
input int TakeProfit = 80;


input group "Period"
input int RSI_Period = 9;
input int MA_Period_1 = 9;
input int MA_Period_2 = 18;




input group "Miscellaneous"
input int CopyIndexStart = 0;
input int EA_Magic = 12345;
input string BuyComment= "Naive-RSI-EA: Buy";
input string SellComment= "Naive-RSI-EA: Sell";
input int Slippage = 100; // Slippage: Tolerated slippage in points.


//+------------------------------------------------------------------+
//| Global Vars                                                      |
//+------------------------------------------------------------------+


CTrade *Trade;
CPositionInfo PositionInfo;
ulong LastBars = 0;
bool HaveLongPosition = false;
bool HaveShortPosition = false;
int accuracy = 4;
int max_period = MathMax(MA_Period_1, MA_Period_2);

// indicator handles
int rsi_handle;


// buffers
double rsi_buffer_1[];
double rsi_buffer_2[];

//+------------------------------------------------------------------+
//| Helper functions                                                 |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
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
        {
         return;
        }

     }
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void fBuy()
  {
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   double SL = Ask - StopLoss * _Point ;
   double TP = Ask + TakeProfit * _Point ;
   PrintFormat("---- STOP LOSS : ", DoubleToString(SL), " --- TAKE PROFIT : ", DoubleToString(TP) , " ----" );
   Trade.PositionOpen(Symbol(), ORDER_TYPE_BUY, Lot, Ask, SL, TP, BuyComment);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void fSell()
  {
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   double SL = Bid - StopLoss * _Point ;
   double TP = Bid + TakeProfit * _Point ;
   PrintFormat("---- STOP LOSS : ", DoubleToString(SL), " --- TAKE PROFIT : ", DoubleToString(TP) , " ----" );
   Trade.PositionOpen(Symbol(), ORDER_TYPE_SELL, Lot, Bid, SL, TP, SellComment);
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


   if(bars < max_period)
     {
      Alert("We have less than required bars, EA will now exit!!");
      return;
     }

// Trade only if new bar has arrived.
   if(LastBars != bars)
      LastBars = bars;
   else
      return;


   if(CopyBuffer(rsi_handle, 0, CopyIndexStart, MA_Period_1, rsi_buffer_1) != MA_Period_1 || CopyBuffer(rsi_handle, 0, CopyIndexStart, MA_Period_2, rsi_buffer_2) != MA_Period_2)
     {
      Alert("Error copying RSI indicator buffer");
      return;
     }

   ArraySetAsSeries(rsi_buffer_1, true);
   ArraySetAsSeries(rsi_buffer_2, true);

   double avg_1=0, avg_2=0;
   avg_1 = MathMean(rsi_buffer_1);
   avg_2 = MathMean(rsi_buffer_2);

   bool buy_condition = rsi_buffer_1[0] > MathMax(avg_1, avg_2);
   bool sell_condition = rsi_buffer_1[0] < MathMin(avg_1, avg_2);

   bool exit_long  = rsi_buffer_1[0] < avg_1;
   bool exit_short = rsi_buffer_1[0] > avg_1;


   GetPositionStates();

   if((HaveLongPosition) && (exit_long))
     {
      Print("HaveLong:try, exit_long");
      ClosePrevious();
      Print("HaveLong:done, exit_long");
     }


   if((HaveShortPosition) && (exit_short))
     {
      Print("HaveShort:try, exit_short");
      ClosePrevious();
      Print("HaveShort:done, exit_short");
     }


   if(buy_condition)
     {
      if(!HaveLongPosition)
        {
         // logic for buying
         Print("Buy:try, !HaveLong");
         fBuy();
         Print("Buy:done, !HaveLong");
         return;
        }
     }

   if(sell_condition)
     {
      if(!HaveShortPosition)
        {
         // logic for selling
         Print("Sell:try, !HaveShort");
         fSell();
         Print("Sell:done, !HaveShort");
         return;
        }
     }

  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
