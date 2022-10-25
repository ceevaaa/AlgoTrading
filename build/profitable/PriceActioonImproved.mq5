//+------------------------------------------------------------------+
//|                                                       RSI_EA.mq5 |
//|                                                        69Billion |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "69Billion"
#property link      "https://www.mql5.com"
#property version   "1.00"

#property description "EA Based on HeikenAshi-RSI Indicator"
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
#include <Custom/chart_functions.mqh>
#include <Custom/ea_helper.mqh>
#include <Custom/errordescription.mqh>
//#include <Custom/Basic/acc_info.mqh>
//#include <Custom/Basic/sym_info.mqh>



//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+

input group "Money management"
input double Lot = 0.1;
input int StopLoss = 40;
input int TakeProfit = 80;
input int TrailingStopLoss = 40;
input int TSMinPipDifference = 20;

input group "Period"
input int RSI_Period = 9;
input int MA_Period_1 = 9;
input int MA_Period_2 = 18;


input group "Miscellaneous"
input int CopyIndexStart = 0;
input int EA_Magic = 12345;
input string BuyComment = "Naive-RSI-EA: Buy";
input string SellComment = "Naive-RSI-EA: Sell";
input int Slippage = 100; // Slippage: Tolerated slippage in points.
input ENUM_APPLIED_PRICE price_type = PRICE_CLOSE;
input double risk_reward = 2;


//+------------------------------------------------------------------+
//| Global Vars                                                      |
//+------------------------------------------------------------------+


CTrade *Trade;
CPositionInfo PositionInfo;
ulong LastBars = 0;
bool HaveLongPosition = false;
bool HaveShortPosition = false;
int accuracy = 4;
int print_accuracy = 5;
int min_bars = 3;

bool resistanceRealExists = false;
bool supportRealExists = false;
bool resistanceFakeExists = false;
bool supportFakeExists = false;

double point_delta = 10 * _Point;


int OrderOpRetry = 5; // Number of position modification attempts.

enum barColor
  {
   WHITE,
   GREEN,
   RED
  };

enum lastBreak
  {
   NONE,
   RESISTANCE,
   SUPPORT
  };

struct zone
  {
   double            top;
   double            bottom;

                     zone(double top_t, double bottom_t) : top(top_t), bottom(bottom_t) {}
  };


barColor bar_color0 {WHITE};
barColor bar_color1 {WHITE};
lastBreak last_break {NONE};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
zone real_resistance(EMPTY_VALUE, EMPTY_VALUE);
zone fake_resistance(EMPTY_VALUE, EMPTY_VALUE);
zone real_support(EMPTY_VALUE, EMPTY_VALUE);
zone fake_support(EMPTY_VALUE, EMPTY_VALUE);


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

// init CTrade
   Trade = new CTrade;
   Trade.SetDeviationInPoints(Slippage);


   configure_chart(CUSTOM_PROFILE_1, 0);
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
//TrailingStop baad mein kar lenge


   int bars = Bars(Symbol(), _Period);


   if(bars < min_bars)
     {
      Print("We have less than required bars, EA will now exit!!");
      return;
     }

// Trade only if new bar has arrived.
   if(LastBars != bars)
      LastBars = bars;
   else
      return;

//  TrailingStop();

   SetPositionStates();

   MqlRates rates[];
   ArraySetAsSeries(rates,true);
   int copied=CopyRates(Symbol(),0,0,3,rates);
   if(copied <= 2)
     {
      Print("CopyRates failed");
      return;
     }
   bar_color1 = bar_color0;
   if(MathAbs(rates[1].open - rates[1].close) < DBL_EPSILON)
     {
      Print("open : ", rates[1].open, " close : ", rates[1].close);
      bar_color0 = WHITE;
     }
   else
      if(rates[1].open < rates[1].close)
        {
         Print("Green bar arrived");
         bar_color0 = GREEN;
        }
      else
        {
         Print("Red bar arrived");
         bar_color0 = RED;
        }

   if(bar_color0 == WHITE || bar_color1 == WHITE)
     {
      Print("something was white or same color bars");
      return;
     }

   //Red bar -- Green bar
   if(bar_color1 == RED && bar_color0 == GREEN)
     {

      if(MathAbs(rates[1].open - rates[2].close) < point_delta)
        {
         //we have a support
         //updating last support
         Print("Support found");

         //updating recent support
         supportFakeExists = true;
         fake_support.top = MathMin(rates[1].open, rates[2].close);
         fake_support.bottom = MathMin(rates[1].low, rates[2].low);

         if(real_support.top == EMPTY_VALUE || fake_support.top + point_delta < real_support.bottom)
           {

            //Fake support broke the real support
            Print("supportRealExists");
            supportRealExists = true;
            real_support = fake_support;
            real_resistance = fake_resistance;
           }
        }
      }

//Green bar -- Red Bar
   if(bar_color1 == GREEN && bar_color0 == RED)
     {
      if(MathAbs(rates[1].open - rates[2].close) < point_delta)
        {
         //updating last resistance
         Print("Resistance found");

         //updating recent fake_rasistance
         resistanceFakeExists = true;
         fake_resistance.bottom = MathMax(rates[2].close, rates[1].open);
         fake_resistance.top = MathMax(rates[1].high, rates[2].high);

         if(real_resistance.top == EMPTY_VALUE || fake_resistance.bottom > real_resistance.top + point_delta)
           {

            //Fake support broke the real support
            Print("resistanceRealExists");
            resistanceRealExists = true;
            real_support = fake_support;
            real_resistance = fake_resistance;
           }
        }
     }

   //Stage 2
   if(bar_color0 == RED)
     {
      if(supportRealExists && rates[1].close + point_delta < real_support.bottom)
        {

         //close long position; if any
         Print("Sell condition satisfied");
         if(HaveLongPosition)
           {
            Print("---------------------------------------------------EXIT LONG [ START ]----------------------------------------------------------");
            ClosePrevious();
            Print("---------------------------------------------------EXIT LONG [ DONE ]-----------------------------------------------------------");
           }
         Print("---------------------------------------------------BUY [ START ]----------------------------------------------------------");
         fSell(real_support.top + point_delta, rates[1].close - (real_support.top - rates[1].close) * risk_reward);
         Print("---------------------------------------------------BUY [ DONE ]-----------------------------------------------------------");

         //update the resistance
         if(resistanceFakeExists)
           {
            Print("resistanceRealExists");
           }
         resistanceRealExists = resistanceFakeExists;
         real_resistance = fake_resistance;
         
         //fake resistance will exists, above condition are not neeeded; therefore we have a real_resistance at this moment
         //we now make stop loss above the new real_resistance.
         //TrailingStop(real_resistance.top + 5 * point_delta);
         
        }
     }
   else
      if(bar_color0 == GREEN)
        {
         if(resistanceRealExists && rates[1].close > point_delta + real_resistance.top)
           {
            //close short position; if any
            Print("Buy condition satisfied");
            if(HaveShortPosition)
              {
               Print("---------------------------------------------------EXIT LONG [ START ]----------------------------------------------------------");
               ClosePrevious();
               Print("---------------------------------------------------EXIT LONG [ DONE ]-----------------------------------------------------------");
              }

            Print("---------------------------------------------------BUY [ START ]----------------------------------------------------------");
            fBuy(real_resistance.bottom - point_delta, rates[1].close + (rates[1].close - real_resistance.bottom) * risk_reward);
            Print("---------------------------------------------------BUY [ DONE ]-----------------------------------------------------------");

            //update the support
            if(supportFakeExists)
              {
               Print("supportRealExists");
              }
            real_support = fake_support;
            supportRealExists = supportFakeExists;
            
            //In this case there will surely be a fake support, conditions above are not required.
            //We should trail the stop loss below the last support
            //TrailingStop(real_support.bottom - 5 * point_delta); 
           }

        }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetPositionStates()
  {

// Is there a position on this currency pair?
   if(PositionInfo.Select(Symbol()))
     {

      if(PositionInfo.PositionType() == POSITION_TYPE_BUY)
        {

         HaveLongPosition = true;
         HaveShortPosition = false;
        }
      else
         if(PositionInfo.PositionType() == POSITION_TYPE_SELL)
           {
            HaveLongPosition = false;
            HaveShortPosition = true;
           }
     }
   else
     {
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
void fBuy(double SL, double TP)
  {

   ENUM_ORDER_TYPE type = ORDER_TYPE_BUY;
   string sym = _Symbol;
   int digits = _Digits;
   string comment = BuyComment;
   double point = _Point * 10;

   double Ask = get_ask(sym, digits);
   double Bid = get_bid(sym, digits);
   //double SL = Bid - StopLoss * point ;
   //double TP = Bid + TakeProfit * point ;
   bool sl_check = false, tp_check = false;


   PrintFormat(">> CALCULATED SL: %s, CALCULATED TP: %s", DoubleToString(SL, print_accuracy), DoubleToString(TP, print_accuracy));

   sl_check = check_sl(SL, type, sym, point, digits);
   tp_check = check_tp(TP, type, sym, point, digits);

   if(!sl_check)
     {
      SL = get_allowed_sl(type, sym, point, digits);
     }

   if(!tp_check)
     {
      TP = get_allowed_tp(type, sym, point, digits);
     }

   Print("---- BID : ", DoubleToString(Bid, print_accuracy), "---- ASK : ", DoubleToString(Ask, print_accuracy), "---- STOP LOSS : ", DoubleToString(SL, print_accuracy), " --- TAKE PROFIT : ", DoubleToString(TP, print_accuracy), " ----");

   Trade.PositionOpen(sym, type, Lot, Ask, SL, TP, comment);

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void fSell(double SL, double TP)
  {

   ENUM_ORDER_TYPE type = ORDER_TYPE_SELL;
   string sym = _Symbol;
   int digits = _Digits;
   string comment = SellComment;
   double point = _Point * 10;

   double Ask = get_ask(sym, digits);
   double Bid = get_bid(sym, digits);
   //double SL = Ask + StopLoss * point ;
   //double TP = Ask - TakeProfit * point ;
   bool sl_check = false, tp_check = false;


   PrintFormat(">> CALCULATED SL: %s, CALCULATED TP: %s", DoubleToString(SL, print_accuracy), DoubleToString(TP, print_accuracy));

   sl_check = check_sl(SL, type, sym, point, digits);
   tp_check = check_tp(TP, type, sym, point, digits);

   if(!sl_check)
     {
      SL = get_allowed_sl(type, sym, point, digits);
     }

   if(!tp_check)
     {
      TP = get_allowed_tp(type, sym, point, digits);
     }

   Print("---- BID : ", DoubleToString(Bid, print_accuracy), "---- ASK : ", DoubleToString(Ask, print_accuracy), "---- STOP LOSS : ", DoubleToString(SL, print_accuracy), " --- TAKE PROFIT : ", DoubleToString(TP, print_accuracy), " ----");

   Trade.PositionOpen(sym, type, Lot, Bid, SL, TP, comment);

  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ModifyPosition(ulong Ticket, double OpenPrice, double SLPrice, double TPPrice)
  {
   for(int i = 1; i <= OrderOpRetry; i++)  // Several attempts to modify the position.
     {
      bool result = Trade.PositionModify(Ticket, SLPrice, TPPrice);
      if(result)
        {
         Print("TRADE - UPDATE SUCCESS - Order ", Ticket, " new stop-loss ", SLPrice);
         //NotifyStopLossUpdate(Ticket, SLPrice);
         break;
        }
      else
        {
         int Error = GetLastError();
         string ErrorText = ErrorDescription(Error);
         Print("ERROR - UPDATE FAILED - error modifying order ", Ticket, " return error: ", Error, " Open=", OpenPrice,
               " Old SL=", PositionGetDouble(POSITION_SL),
               " New SL=", SLPrice, " Bid=", SymbolInfoDouble(Symbol(), SYMBOL_BID), " Ask=", SymbolInfoDouble(Symbol(), SYMBOL_ASK));
         Print("ERROR - ", ErrorText);
        }
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailingStop()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {

      ulong ticket = PositionGetTicket(i);

      if(ticket <= 0)
        {
         int Error = GetLastError();
         string ErrorText = ErrorDescription(Error);
         Print("ERROR - Unable to select the position - ", Error);
         Print("ERROR - ", ErrorText);
         break;
        }
      // there can be multiple symbols
      double bid = get_bid(_Symbol, _Digits, false);
      double ask = get_ask(_Symbol, _Digits, false);
      double position_open_price = PositionGetDouble(POSITION_PRICE_OPEN);
      double position_sl = PositionGetDouble(POSITION_SL);
      double position_tp = PositionGetDouble(POSITION_TP);
      double ts_threshold = NormalizeDouble(TSMinPipDifference * _Point * 10, _Digits);
      double ts_value = TrailingStopLoss * _Point * 10;
      ulong position_type = PositionGetInteger(POSITION_TYPE);


      if(position_type == POSITION_TYPE_BUY)
        {
         if(NormalizeDouble(bid - position_open_price, _Digits) > ts_threshold)
           {
            if((NormalizeDouble(position_sl, _Digits) < NormalizeDouble(bid - ts_value, _Digits)))
              {
               Print("---------------------------------------------------MOVE SL FOR BUY [ START ]----------------------------------------------------------");
               ModifyPosition(ticket, position_open_price, NormalizeDouble(bid - ts_value, _Digits), position_tp);
               Print("---------------------------------------------------MOVE SL FOR BUY [ DONE ]-----------------------------------------------------------");
              }
           }
        }


      else
         if(position_type == POSITION_TYPE_SELL)
           {
            if(NormalizeDouble(position_open_price - ask, _Digits) > ts_threshold)
              {
               if((NormalizeDouble(position_sl, _Digits) > NormalizeDouble(ask + ts_value, _Digits)))
                 {
                  Print("---------------------------------------------------MOVE SL FOR SELL [ START ]----------------------------------------------------------");
                  ModifyPosition(ticket, position_open_price, NormalizeDouble(ask + ts_value, _Digits), position_tp);
                  Print("---------------------------------------------------MOVE SL FOR SELL [ DONE ]-----------------------------------------------------------");
                 }
              }
           }

     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailingStop(double stopLoss)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {

      ulong ticket = PositionGetTicket(i);

      if(ticket <= 0)
        {
         int Error = GetLastError();
         string ErrorText = ErrorDescription(Error);
         Print("ERROR - Unable to select the position - ", Error);
         Print("ERROR - ", ErrorText);
         break;
        }
      double bid = get_bid(_Symbol, _Digits, false);
      double ask = get_ask(_Symbol, _Digits, false);
      double position_open_price = PositionGetDouble(POSITION_PRICE_OPEN);
      double position_sl = PositionGetDouble(POSITION_SL);
      double position_tp = PositionGetDouble(POSITION_TP);
      ulong position_type = PositionGetInteger(POSITION_TYPE);


      if(position_type == POSITION_TYPE_BUY)
        {
         double stop_loss = MathMax(NormalizeDouble(position_sl, _Digits),  NormalizeDouble(stopLoss, _Digits));
         double take_profit = MathMax(NormalizeDouble(position_tp, _Digits), NormalizeDouble((bid - real_support.bottom) * risk_reward + bid, _Digits));
         if(stop_loss != position_sl || take_profit != position_tp)
           {
            Print("---------------------------------------------------MOVE SL FOR BUY [ START ]----------------------------------------------------------");
            ModifyPosition(ticket, position_open_price, stop_loss, take_profit);
            Print("---------------------------------------------------MOVE SL FOR BUY [ DONE ]-----------------------------------------------------------");
           }
        }


      else
         if(position_type == POSITION_TYPE_SELL)
           {
            double stop_loss = MathMin(NormalizeDouble(position_sl, _Digits),  NormalizeDouble(stopLoss, _Digits));
            double take_profit = MathMin(NormalizeDouble(position_tp, _Digits), NormalizeDouble(ask - (real_resistance.top - ask) * risk_reward, _Digits));
            if(stop_loss != position_sl || take_profit != position_tp)
              {
               Print("---------------------------------------------------MOVE SL FOR BUY [ START ]----------------------------------------------------------");
               ModifyPosition(ticket, position_open_price, stop_loss, take_profit);
               Print("---------------------------------------------------MOVE SL FOR BUY [ DONE ]-----------------------------------------------------------");
              }
           }

     }
  }
//+------------------------------------------------------------------+
