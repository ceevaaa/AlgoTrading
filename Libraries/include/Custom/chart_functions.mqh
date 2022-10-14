//+------------------------------------------------------------------+
//|                                                chart_configs.mqh |
//|                                                        69Billion |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "69Billion"
#property link      "https://www.mql5.com"


enum CUSTOM_CHART_PROFILE_TYPE
   {
    CUSTOM_PROFILE_1,
    CUSTOM_PROFILE_2,
    CUSTOM_PROFILE_3
   };


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void configure_chart(long chart_id, CUSTOM_CHART_PROFILE_TYPE chart_profile_type = CUSTOM_PROFILE_1)
   {
    switch(chart_profile_type)
       {
        case CUSTOM_PROFILE_1:
           {
            configure_chart_profile_1(chart_id);
            break;
           }
       }
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void configure_chart_profile_1(long chart_id)
   {
    ChartSetInteger(chart_id, CHART_COLOR_BACKGROUND, White);
    ChartSetInteger(chart_id, CHART_COLOR_FOREGROUND, Black);
    ChartSetInteger(chart_id, CHART_COLOR_GRID, 241236242);
    ChartSetInteger(chart_id, CHART_COLOR_CHART_UP, clrSpringGreen);
    ChartSetInteger(chart_id, CHART_COLOR_CHART_DOWN, clrTomato);
    ChartSetInteger(chart_id, CHART_COLOR_CANDLE_BULL, clrSpringGreen);
    ChartSetInteger(chart_id, CHART_COLOR_CANDLE_BEAR, clrTomato);
    ChartSetInteger(chart_id, CHART_COLOR_CHART_LINE, 86186132);
    ChartSetInteger(chart_id, CHART_COLOR_VOLUME, 38166154);
    ChartSetInteger(chart_id, CHART_COLOR_BID, 38166154);
    ChartSetInteger(chart_id, CHART_COLOR_ASK, 2398380);
    ChartSetInteger(chart_id, CHART_COLOR_LAST, 156186240);
    ChartSetInteger(chart_id, CHART_COLOR_STOP_LEVEL, 2398380);
    ChartRedraw(chart_id);
   }
//+------------------------------------------------------------------+
