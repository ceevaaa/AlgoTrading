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
input int TrailingStop = 50;                       // Trailing Stop, points
input int Profit = 100;   
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
int OrderOpRetry = 5; // Number of position modification attempts.

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
    //configure_chart(CUSTOM_PROFILE_1, 0);
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
    TrailingStop();
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
   
//+--------------------------------------------------------------------------------------------------------------+
//|https://github.com/EarnForex/Trailing-Stop-on-Profit/blob/main/MQL5/Experts/Trailing%20Stop%20on%20Profit.mq5 |
//+--------------------------------------------------------------------------------------------------------------+
void ModifyPosition(ulong Ticket, double OpenPrice, double SLPrice, double TPPrice)
{
    for (int i = 1; i <= OrderOpRetry; i++) // Several attempts to modify the position.
    {
        bool result = Trade.PositionModify(Ticket, SLPrice, TPPrice);
        if (result)
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

//+--------------------------------------------------------------------------------------------------------------+
//|https://github.com/EarnForex/Trailing-Stop-on-Profit/blob/main/MQL5/Experts/Trailing%20Stop%20on%20Profit.mq5 |
//+--------------------------------------------------------------------------------------------------------------+
void TrailingStop()
{
    for (int j = 0; j < 1; ++j)
    {
        bool PositionSelected = false;
        for (int i = 0; i < 10; ++i)
        {
            if (PositionInfo.Select(Symbol()))
            {
               PositionSelected = true;
               break;
            }
        }
        
        if (PositionSelected == false) 
        {
            Print("WARN : in TrailingStop, counldn't select the position");
            return;
        }
        ulong ticket = PositionGetInteger(POSITION_TICKET);

        if (ticket <= 0)
        {
            int Error = GetLastError();
            string ErrorText = ErrorDescription(Error);
            Print("ERROR - Unable to select the position - ", Error);
            Print("ERROR - ", ErrorText);
            break;
        }

        // Trading disabled.
        if (SymbolInfoInteger(PositionGetString(POSITION_SYMBOL), SYMBOL_TRADE_MODE) == SYMBOL_TRADE_MODE_DISABLED) continue;
        
        // Filters.
        if (PositionGetString(POSITION_SYMBOL) != Symbol()) continue;
        //if ((UseMagic) && (PositionGetInteger(POSITION_MAGIC) != MagicNumber)) continue;
        //if ((UseComment) && (StringFind(PositionGetString(POSITION_COMMENT), CommentFilter) < 0)) continue;
        //if ((OnlyType != All) && (PositionGetInteger(POSITION_TYPE) != OnlyType)) continue;

        // Normalize trailing stop value to the point value.
        double TSTP = TrailingStop * _Point * 10;
        double P = Profit * _Point * 10;

        double Bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
        double Ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
        double OpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        double StopLoss_t = PositionGetDouble(POSITION_SL);
        double TakeProfit_t = PositionGetDouble(POSITION_TP);

        if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
        {
            if (NormalizeDouble(Bid - OpenPrice, _Digits) > NormalizeDouble(P, _Digits))
            {
                if ((TSTP != 0) && (StopLoss_t < NormalizeDouble(Bid - TSTP, _Digits)))
                {
                    ModifyPosition(ticket, OpenPrice, NormalizeDouble(Bid - TSTP, _Digits), TakeProfit_t);
                }
            }
        }
        else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
        {
            if ((TSTP != 0) && (NormalizeDouble(OpenPrice - Ask, _Digits) > TSTP))
            {
                if ((StopLoss_t > NormalizeDouble(Ask + TSTP, _Digits)) || (StopLoss == 0))
                {
                    ModifyPosition(ticket, OpenPrice, NormalizeDouble(Ask + TSTP, _Digits), TakeProfit_t);
                }
            }
        }
    }
}
//+------------------------------------------------------------------+