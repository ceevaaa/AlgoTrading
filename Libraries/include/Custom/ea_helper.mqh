//+------------------------------------------------------------------+
//|                                                    ea_checks.mqh |
//|                                                        69Billion |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "69Billion"
#property link      "https://www.mql5.com"



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int get_stops_level(string sym)
   {
    int stops_level = (int)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL);
    return stops_level;
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double get_bid(string sym, int digits, bool normalize = true)
   {

    if(normalize)
        return NormalizeDouble(SymbolInfoDouble(sym, SYMBOL_BID), digits);
    else
        return SymbolInfoDouble(sym, SYMBOL_BID);
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double get_ask(string sym, int digits, bool normalize = true)
   {
    if(normalize)
        return NormalizeDouble(SymbolInfoDouble(sym, SYMBOL_ASK), digits);
    else
        return SymbolInfoDouble(sym, SYMBOL_ASK);
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double get_stop(string sym, double point)
   {
    int stops_level = get_stops_level(sym);
    return stops_level * point;
   }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool check_tp(double tp, ENUM_ORDER_TYPE type, string sym, double point, int digits)
   {
    bool tp_check = false;
    double ask = get_ask(sym, digits);
    double bid = get_bid(sym, digits);
    double stop = get_stop(sym, point);

    switch(type)
       {
        case ORDER_TYPE_BUY:
           {
            PrintFormat(">> BUY: TP: %.6f, BID: %.6f, STOP: %.6f", tp, bid, stop);
            tp_check = (tp - bid > stop);
            break;
           }

        case ORDER_TYPE_SELL:
           {
            PrintFormat(">> SELL: TP: %.6f, BID: %.6f, STOP: %.6f", tp, bid, stop);
            tp_check = (ask - tp > stop);
            break;
           }
       }

    if(tp_check)
       {
        PrintFormat(">> tp_check is true");
       }
    else
       {
        PrintFormat(">> tp_check is false");
       }
    return tp_check;
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool check_sl(double sl, ENUM_ORDER_TYPE type, string sym, double point, int digits)
   {
    bool sl_check = false;
    double ask = get_ask(sym, digits);
    double bid = get_bid(sym, digits);
    double stop = get_stop(sym, point);

    switch(type)
       {
        case ORDER_TYPE_BUY:
           {
            PrintFormat(">> BUY: SL: %.6f, BID: %.6f, STOP: %.6f", sl, bid, stop);
            sl_check = (bid - sl > stop);
            break;
           }

        case ORDER_TYPE_SELL:
           {
            PrintFormat(">> SELL: SL: %.6f, BID: %.6f, STOP: %.6f", sl, bid, stop);
            sl_check = (sl - ask > stop);
            break;
           }
       }

    if(sl_check)
       {
        PrintFormat(">> sl_check is true");
       }
    else
       {
        PrintFormat(">> sl_check is false");
       }
    return sl_check;
   }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool check_sl_tp(double sl, double tp, ENUM_ORDER_TYPE type, string sym, double point, int digits)
   {
    int stops_level = get_stops_level(sym);
    bool sl_check = false, tp_check = false;

    sl_check = check_sl(sl, type, sym, point, digits);
    tp_check = check_tp(tp, type, sym, point, digits);

    return (sl_check && tp_check);
   }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double get_allowed_sl(ENUM_ORDER_TYPE type, string sym, double point, int digits)
   {
    double stop = get_stop(sym, point);
    double bid = get_bid(sym, digits);
    double ask = get_ask(sym, digits);
    double allowed_sl = 0;

    switch(type)
       {
        case ORDER_TYPE_BUY:
           {
            allowed_sl = (bid - stop) - point;
            break;
           }
        case ORDER_TYPE_SELL:
           {
            allowed_sl = (ask + stop) + point;
            break;
           }
       }

    PrintFormat(">> allowed sl: %.5f", allowed_sl);
    return allowed_sl;
   }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double get_allowed_tp(ENUM_ORDER_TYPE type, string sym, double point, int digits)
   {
    double stop = get_stop(sym, point);
    double bid = get_bid(sym, digits);
    double ask = get_ask(sym, digits);
    double allowed_tp = 0;

    switch(type)
       {
        case ORDER_TYPE_BUY:
           {
            allowed_tp = (bid + stop) + point;
            break;
           }
        case ORDER_TYPE_SELL:
           {
            allowed_tp = (ask - stop) - point;
            break;
           }
       }

    PrintFormat(">> allowed tp: %.5f", allowed_tp);
    return allowed_tp;
   }



//+------------------------------------------------------------------+
