//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
//#property indicator_chart_window
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   3


//---- plot RSI-1
#property indicator_label1  "RSI-1"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDarkGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2


//---- plot RSI-2
#property indicator_label2  "RSI-2"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDarkBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2


//---- plot RSI-3
#property indicator_label3  "RSI-3"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrDarkRed
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2


//--- limits for displaying of values in the indicator window
#property indicator_maximum 100
#property indicator_minimum 0
//--- horizontal levels in the indicator window
#property indicator_level1  70.0
#property indicator_level2  30.0


//+------------------------------------------------------------------+
//| Enumeration of the methods of handle creation                    |
//+------------------------------------------------------------------+


enum Creation
  {
   Call_iRSI,              // use iRSI
   Call_IndicatorCreate    // use IndicatorCreate
  };


input Creation             type_1=Call_iRSI;               // type of the function
input Creation             type_2=Call_iRSI;               // type of the function
input Creation             type_3=Call_iRSI;               // type of the function


input int                  ma_period_1=21;                 // period of averaging
input int                  ma_period_2=16;                 // period of averaging
input int                  ma_period_3=9;                 // period of averaging

input ENUM_APPLIED_PRICE   applied_price=PRICE_CLOSE;    // type of price
input string               symbol=" ";                   // symbol
input ENUM_TIMEFRAMES      period=PERIOD_CURRENT;        // timeframe



//--- indicator buffers
double         iRSIBuffer_1[];
double         iRSIBuffer_2[];
double         iRSIBuffer_3[];


//--- variable for storing the handle of the iRSI indicator
int    handle_1;
int    handle_2;
int    handle_3;

//--- variable for storing
string name=symbol;

//--- name of the indicator on a chart
string short_name_1;
string short_name_2;
string short_name_3;


//--- we will keep the number of values in the Relative Strength Index indicator
int    bars_calculated_1=0;
int    bars_calculated_2=0;
int    bars_calculated_3=0;


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
///--- assignment of array to indicator buffer
   SetIndexBuffer(0,iRSIBuffer_1,INDICATOR_DATA);
   SetIndexBuffer(1,iRSIBuffer_2,INDICATOR_DATA);
   SetIndexBuffer(2,iRSIBuffer_3,INDICATOR_DATA);

//--- determine the symbol the indicator is drawn for
   name=symbol;
//--- delete spaces to the right and to the left
   StringTrimRight(name);
   StringTrimLeft(name);
//--- if it results in zero length of the 'name' string
   if(StringLen(name)==0)
     {
      //--- take the symbol of the chart the indicator is attached to
      name=_Symbol;
     }

//--- create handle for iRSI_1
   if(type_1==Call_iRSI)
     {
      handle_1=iRSI(name,period,ma_period_1,applied_price);
     }
   else
     {
      //--- fill the structure with parameters of the indicator
      MqlParam pars[2];
      //--- period of moving average
      pars[0].type=TYPE_INT;
      pars[0].integer_value=ma_period_1;
      //--- limit of the step value that can be used for calculations
      pars[1].type=TYPE_INT;
      pars[1].integer_value=applied_price;
      handle_1=IndicatorCreate(name,period,IND_RSI,2,pars);
     }

//--- create handle for iRSI_2
   if(type_2==Call_iRSI)
     {
      handle_2=iRSI(name,period,ma_period_2,applied_price);
     }
   else
     {
      //--- fill the structure with parameters of the indicator
      MqlParam pars[2];
      //--- period of moving average
      pars[0].type=TYPE_INT;
      pars[0].integer_value=ma_period_2;
      //--- limit of the step value that can be used for calculations
      pars[1].type=TYPE_INT;
      pars[1].integer_value=applied_price;
      handle_2=IndicatorCreate(name,period,IND_RSI,2,pars);
     }


//--- create handle for iRSI_3
   if(type_3==Call_iRSI)
     {
      handle_3=iRSI(name,period,ma_period_3,applied_price);
     }
   else
     {
      //--- fill the structure with parameters of the indicator
      MqlParam pars[2];
      //--- period of moving average
      pars[0].type=TYPE_INT;
      pars[0].integer_value=ma_period_3;
      //--- limit of the step value that can be used for calculations
      pars[1].type=TYPE_INT;
      pars[1].integer_value=applied_price;
      handle_3=IndicatorCreate(name,period,IND_RSI,2,pars);
     }

//--- if the handle is not created
   if(handle_1==INVALID_HANDLE || handle_2==INVALID_HANDLE || handle_3==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iRSI indicator for the symbol %s/%s, error code %d",
                  name,
                  EnumToString(period),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }

//--- show the symbol/timeframe the Relative Strength Index indicator is calculated for
   
   short_name_1=StringFormat("iRSI(%s/%s, %d, %d)",name,EnumToString(period),
                           ma_period_1,applied_price);
   IndicatorSetString(INDICATOR_SHORTNAME,short_name_1);
   short_name_2=StringFormat("iRSI(%s/%s, %d, %d)",name,EnumToString(period),
                           ma_period_2,applied_price);
   IndicatorSetString(INDICATOR_SHORTNAME,short_name_2);
   short_name_3=StringFormat("iRSI(%s/%s, %d, %d)",name,EnumToString(period),
                           ma_period_3,applied_price);
   IndicatorSetString(INDICATOR_SHORTNAME,short_name_3);
//--- normal initialization of the indicator
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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

//--- number of values copied from the iRSI indicator
   int values_to_copy_1;
   int values_to_copy_2;
   int values_to_copy_3;

//--- determine the number of values calculated in the indicator
   int calculated_1=BarsCalculated(handle_1);
   int calculated_2=BarsCalculated(handle_2);
   int calculated_3=BarsCalculated(handle_3);
   if(calculated_1<=0 || calculated_2<=0 || calculated_3<=0)
     {
      PrintFormat("BarsCalculated() returned %d,%d,%d, error code %d",
                  calculated_1,calculated_2,calculated_3,GetLastError());
      return(0);
     }


//--- if it is the first start of calculation of the indicator or if the number of values in the iRSI indicator changed
//---or if it is necessary to calculated the indicator for two or more bars (it means something has changed in the price history)
   if(prev_calculated==0 || calculated_1!=bars_calculated_1 || rates_total>prev_calculated+1)
     {
      //--- if the iRSIBuffer array is greater than the number of values in the iRSI indicator for symbol/period, then we don't copy everything
      //--- otherwise, we copy less than the size of indicator buffers
      if(calculated_1>rates_total)
         values_to_copy_1=rates_total;
      else
         values_to_copy_1=calculated_1;
     }
   else
     {
      //--- it means that it's not the first time of the indicator calculation, and since the last call of OnCalculate()
      //--- for calculation not more than one bar is added
      values_to_copy_1=(rates_total-prev_calculated)+1;
     }

   if(prev_calculated==0 || calculated_2!=bars_calculated_2 || rates_total>prev_calculated+1)
     {
      //--- if the iRSIBuffer array is greater than the number of values in the iRSI indicator for symbol/period, then we don't copy everything
      //--- otherwise, we copy less than the size of indicator buffers
      if(calculated_2>rates_total)
         values_to_copy_2=rates_total;
      else
         values_to_copy_2=calculated_2;
     }
   else
     {
      //--- it means that it's not the first time of the indicator calculation, and since the last call of OnCalculate()
      //--- for calculation not more than one bar is added
      values_to_copy_2=(rates_total-prev_calculated)+1;
     }


   if(prev_calculated==0 || calculated_3!=bars_calculated_3 || rates_total>prev_calculated+1)
     {
      //--- if the iRSIBuffer array is greater than the number of values in the iRSI indicator for symbol/period, then we don't copy everything
      //--- otherwise, we copy less than the size of indicator buffers
      if(calculated_3>rates_total)
         values_to_copy_3=rates_total;
      else
         values_to_copy_3=calculated_3;
     }
   else
     {
      //--- it means that it's not the first time of the indicator calculation, and since the last call of OnCalculate()
      //--- for calculation not more than one bar is added
      values_to_copy_3=(rates_total-prev_calculated)+1;
     }



//--- fill the array with values of the iRSI indicator
//--- if FillArrayFromBuffer returns false, it means the information is nor ready yet, quit operation
   if(!FillArrayFromBuffer(iRSIBuffer_1,handle_1,values_to_copy_1))
      return(0);
   if(!FillArrayFromBuffer(iRSIBuffer_2,handle_2,values_to_copy_2))
      return(0);
   if(!FillArrayFromBuffer(iRSIBuffer_3,handle_3,values_to_copy_3))
      return(0);


//--- form the message
   string comm_1=StringFormat("%s ==>  Updated value in the indicator %s: %d",
                              TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),
                              short_name_1,
                              values_to_copy_1);
   string comm_2=StringFormat("%s ==>  Updated value in the indicator %s: %d",
                              TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),
                              short_name_2,
                              values_to_copy_2);
   string comm_3=StringFormat("%s ==>  Updated value in the indicator %s: %d",
                              TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),
                              short_name_3,
                              values_to_copy_3);

//--- display the service message on the chart
   Comment(comm_1);
   Comment(comm_2);
   Comment(comm_3);


//--- memorize the number of values in the Relative Strength Index indicator
   bars_calculated_1=calculated_1;
   bars_calculated_2=calculated_2;
   bars_calculated_3=calculated_3;

//--- return the prev_calculated value for the next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//| Filling indicator buffers from the iRSI indicator                |
//+------------------------------------------------------------------+
bool FillArrayFromBuffer(double &rsi_buffer[],  // indicator buffer of Relative Strength Index values
                         int ind_handle,        // handle of the iRSI indicator
                         int amount             // number of copied values
                        )
  {
//--- reset error code
   ResetLastError();
//--- fill a part of the iRSIBuffer array with values from the indicator buffer that has 0 index
   if(CopyBuffer(ind_handle,0,0,amount,rsi_buffer)<0)
     {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the iRSI indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(false);
     }
//--- everything is fine
   return(true);
  }

//+------------------------------------------------------------------+
//| Indicator deinitialization function                              |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(handle_1!=INVALID_HANDLE)
      IndicatorRelease(handle_1);
   if(handle_2!=INVALID_HANDLE)
      IndicatorRelease(handle_2);
   if(handle_3!=INVALID_HANDLE)
      IndicatorRelease(handle_3);
//--- clear the chart after deleting the indicator
   Comment("");
  }
//+------------------------------------------------------------------+
