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
#resource 
//+------------------------------------------------------------------+
//| Includes                                                         |
//+------------------------------------------------------------------+

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Math/Stat/Math.mqh>
#include <Custom/chart_functions.mqh>
#include <Custom/ea_helper.mqh>

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
input string BuyComment = "Naive-RSI-EA: Buy";
input string SellComment = "Naive-RSI-EA: Sell";
input int Slippage = 100; // Slippage: Tolerated slippage in points.
input ENUM_APPLIED_PRICE price_type = PRICE_CLOSE;


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
int max_period = MathMax(MA_Period_1, MA_Period_2);

// indicator handles
int rsi_handle;


// buffers
double rsi_buffer_1[];
double rsi_buffer_2[];



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
   {

// init CTrade
    Trade = new CTrade;
    Trade.SetDeviationInPoints(Slippage);

// Get handle for RSI
    rsi_handle = iCustom(_Symbol, _Period, "heiken_ashi_rsi", RSI_Period, price_type);


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

    double avg_1 = 0, avg_2 = 0;
    avg_1 = MathMean(rsi_buffer_1);
    avg_2 = MathMean(rsi_buffer_2);

    bool buy_condition = rsi_buffer_1[0] > MathMax(avg_1, avg_2);
    bool sell_condition = rsi_buffer_1[0] < MathMin(avg_1, avg_2);

    bool exit_long  = rsi_buffer_1[0] < avg_1;
    bool exit_short = rsi_buffer_1[0] > avg_1;


    SetPositionStates();

    if((HaveLongPosition) && (exit_long))
       {
        Print("---------------------------------------------------EXIT LONG [ START ]----------------------------------------------------------");
        ClosePrevious();
        Print("---------------------------------------------------EXIT LONG [ DONE ]-----------------------------------------------------------");
       }


    if((HaveShortPosition) && (exit_short))
       {
        Print("---------------------------------------------------EXIT SHORT [ START ]----------------------------------------------------------");
        ClosePrevious();
        Print("---------------------------------------------------EXIT SHORT [ DONE ]-----------------------------------------------------------");
       }


    if(buy_condition)
       {
        if(!HaveLongPosition)
           {
            // logic for buying
            Print("---------------------------------------------------BUY [ START ]----------------------------------------------------------");
            fBuy();
            Print("---------------------------------------------------BUY [ DONE ]-----------------------------------------------------------");
            return;
           }
       }

    if(sell_condition)
       {
        if(!HaveShortPosition)
           {
            // logic for selling
            Print("---------------------------------------------------SELL [ START ]----------------------------------------------------------");
            fSell();
            Print("---------------------------------------------------SELL [ DONE ]-----------------------------------------------------------");
            return;
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
void fBuy()
   {

    ENUM_ORDER_TYPE type = ORDER_TYPE_BUY;
    string sym = _Symbol;
    int digits = _Digits;
    string comment = BuyComment;
    double point = _Point * 10;

    double Ask = get_ask(sym, digits);
    double Bid = get_bid(sym, digits);
    double SL = Bid - StopLoss * point ;
    double TP = Bid + TakeProfit * point ;
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
void fSell()
   {

    ENUM_ORDER_TYPE type = ORDER_TYPE_SELL;
    string sym = _Symbol;
    int digits = _Digits;
    string comment = SellComment;
    double point = _Point * 10;

    double Ask = get_ask(sym, digits);
    double Bid = get_bid(sym, digits);
    double SL = Ask + StopLoss * point ;
    double TP = Ask - TakeProfit * point ;
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