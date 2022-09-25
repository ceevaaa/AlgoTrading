//+---------------------------------------------------------------------+
//|                                               heiken_ashi_close.mq5 |
//|                                                           69Billion |
//|ref: https://www.mql5.com/en/code/viewcode/33/129914/heiken_ashi.mq5 |
//+---------------------------------------------------------------------+
// indicator properties
#property copyright "69Billion"
#property description "Heiken Ashi Close"


//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   1
#property indicator_type1   DRAW_LINE
#property indicator_color1  Black
#property indicator_label1  "Heiken Ashi Close"


//--- indicator buffers
double ExtOBuffer[];
double ExtHBuffer[];
double ExtLBuffer[];
double ExtCBuffer[];


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
   {

//--- indicator buffers mapping
    SetIndexBuffer(0, ExtCBuffer, INDICATOR_DATA); // set close buffer to zero index
    SetIndexBuffer(1, ExtOBuffer, INDICATOR_CALCULATIONS);
    SetIndexBuffer(2, ExtHBuffer, INDICATOR_CALCULATIONS);
    SetIndexBuffer(3, ExtLBuffer, INDICATOR_CALCULATIONS);
//---
    IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
//--- sets first bar from what index will be drawn
    IndicatorSetString(INDICATOR_SHORTNAME, "Heiken Ashi [ PRICE_CLOSE ]");
//--- sets drawing line empty value
    PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   }


//+------------------------------------------------------------------+
//| Heiken Ashi                                                      |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
   {
    int start;
//--- preliminary calculations
    if(prev_calculated == 0)
       {
        ExtLBuffer[0] = low[0];
        ExtHBuffer[0] = high[0];
        ExtOBuffer[0] = open[0];
        ExtCBuffer[0] = close[0];
        start = 1;
       }
    else
        start = prev_calculated - 1;

//--- the main loop of calculations
    for(int i = start; i < rates_total && !IsStopped(); i++)
       {
        double ha_open = (ExtOBuffer[i - 1] + ExtCBuffer[i - 1]) / 2;
        double ha_close = (open[i] + high[i] + low[i] + close[i]) / 4;
        double ha_high = MathMax(high[i], MathMax(ha_open, ha_close));
        double ha_low  = MathMin(low[i], MathMin(ha_open, ha_close));

        ExtLBuffer[i] = ha_low;
        ExtHBuffer[i] = ha_high;
        ExtOBuffer[i] = ha_open;
        ExtCBuffer[i] = ha_close;
       }
//---
    return(rates_total);
   }
//+------------------------------------------------------------------+
