//+------------------------------------------------------------------+
//|                                                           Om.mq5 |
//|                                                        69Billion |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
input int      StopLoss=30;      // Stop Loss
input int      TakeProfit=100;   // Take Profit
input int      MA_Period=8;      // Moving Average Period
input int      EA_Magic=12345;   // EA Magic Number
//input double   Adx_Min=22.0;     // Minimum ADX Value
input double   Lot=0.1;          // Lots to Trade
input int      MA
//--- Other parameters
//int adxHandle; // handle for our ADX indicator
int rsiHandle;  // handle for our Moving Average indicator
//double plsDI[],minDI[],adxVal[]; // Dynamic arrays to hold the values of +DI, -DI and ADX values for each bars
double rsiVal[]; // Dynamic array to hold the values of Moving Average for each bars
double p_close; // Variable to store the close value of a bar
int STP, TKP;   // To be used for Stop Loss & Take Profit values

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Get the handle for RSI Handle
   rsiHandle=iMA(_Symbol,_Period,MA_Period,0,MODE_EMA,PRICE_CLOSE);
//--- What if handle returns Invalid Handle
   if(rsiHandle<0)
     {
      Alert("Error Creating Handles for indicators - error: ",GetLastError(),"!!");
     }

   STP = StopLoss;
   TKP = TakeProfit;
   if(_Digits==5 || _Digits==3)
     {
      STP = STP*10;
      TKP = TKP*10;
     }
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
// Do we have enough bars to work with
   if(Bars(_Symbol,_Period)<60) // if total bars is less than 60 bars
     {
      Alert("We have less than 60 bars, EA will now exit!!");
      return;
     }
// We will use the static Old_Time variable to serve the bar time.
// At each OnTick execution we will check the current bar time with the saved one.
// If the bar time isn't equal to the saved time, it indicates that we have a new tick.
   static datetime Old_Time;
   datetime New_Time[1];
   bool IsNewBar=false;

// copying the last bar time to the element New_Time[0]
   int copied=CopyTime(_Symbol,_Period,0,1,New_Time);
   if(copied>0) // ok, the data has been copied successfully
     {
      if(Old_Time!=New_Time[0]) // if old time isn't equal to new bar time
        {
         IsNewBar=true;   // if it isn't a first call, the new bar has appeared
         if(MQL5InfoInteger(MQL5_DEBUGGING))
            Print("We have new bar here ",New_Time[0]," old time was ",Old_Time);
         Old_Time=New_Time[0];            // saving bar time
        }
     }
   else
     {
      Alert("Error in copying historical times data, error =",GetLastError());
      ResetLastError();
      return;
     }

//--- EA should only check for new trade if we have a new bar
   if(IsNewBar==false)
     {
      return;
     }

//--- Do we have enough bars to work with
   int Mybars=Bars(_Symbol,_Period);
   if(Mybars<60) // if total bars is less than 60 bars
     {
      Alert("We have less than 60 bars, EA will now exit!!");
      return;
     }

//--- Define some MQL5 Structures we will use for our trade
   MqlTick latest_price;     // To be used for getting recent/latest price quotes
   MqlTradeRequest mrequest;  // To be used for sending our trade requests
   MqlTradeResult mresult;    // To be used to get our trade results
   MqlRates mrate[];         // To be used to store the prices, volumes and spread of each bar
   ZeroMemory(mrequest);     // Initialization of mrequest structure
   /*
     Let's make sure our arrays values for the Rates, ADX Values and MA values
     is store serially similar to the timeseries array
   */
// the rates arrays
   ArraySetAsSeries(mrate,true);
   ArraySetAsSeries(rsiVal,true);

   if(!SymbolInfoTick(_Symbol,latest_price))
     {
      Alert("Error getting the latest price quote - error:",GetLastError(),"!!");
      return ;
     }

   if(CopyRates(_Symbol,_Period,0,3,mrate)<0)
     {
      Alert("Error copying rates/history data - error:",GetLastError(),"!!");
      return;
     }

   if(CopyBuffer(rsiHandle,0,0,18,rsiVal)<0)
     {
      Alert("Error copying Moving Average indicator buffer - error:",GetLastError());
      return;
     }
//Calculating moving average for 9 and 18
   double sum_9 = 0, sum_18 = 0;
   for(int i = 0; i < 18; ++i)
     {
      sum_18 += rsiVal[i];
      if(i < 9)
        {
         sum_9 += rsiVal[i];
        }
     }
   double avg_9 = sum_9 / 9.0;
   double avg_18 = sum_18 / 18.0;

   bool Buy_opened=false;  // variable to hold the result of Buy opened position
   bool Sell_opened=false; // variable to hold the result of Sell opened position

   if(PositionSelect(_Symbol) ==true)   // we have an opened position
     {
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
        {
         Buy_opened = true;  //It is a Buy
         
        }
      else
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
           {
            Sell_opened = true; // It is a Sell
           }
     }
   bool buy_condition_1 = rsiVal[i] > MathMax(avg_18, avg_9);
   bool sell_condition_1 = rsiVal[i] < MathMin(avg_18, avg_9);

   if(buy_condition_1 && !Buy_opened)
     {
      if (Sell_opened) {
         //square the position
      }
      mrequest.action = TRADE_ACTION_DEAL;                                 // immediate order execution
      mrequest.price = NormalizeDouble(latest_price.bid,_Digits);          // latest Bid price
      mrequest.sl = NormalizeDouble(latest_price.bid + STP*_Point,_Digits); // Stop Loss
      mrequest.tp = NormalizeDouble(latest_price.bid - TKP*_Point,_Digits); // Take Profit
      mrequest.symbol = _Symbol;                                         // currency pair
      mrequest.volume = Lot;                                            // number of lots to trade
      mrequest.magic = EA_Magic;                                        // Order Magic Number
      mrequest.type= ORDER_TYPE_SELL;                                     // Sell Order
      mrequest.type_filling = ORDER_FILLING_FOK;                          // Order execution type
      mrequest.deviation=100;                                           // Deviation from current price
      //--- send order
      OrderSend(mrequest,mresult);
      if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
        {
         Alert("A Buy order has been successfully placed with Ticket#:",mresult.order,"!!");
        }
      else
        {
         Alert("The Buy order request could not be completed -error:",GetLastError());
         ResetLastError();
         return;
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
if(sell_condition_1)
  {
   mrequest.action = TRADE_ACTION_DEAL;                                 // immediate order execution
   mrequest.price = NormalizeDouble(latest_price.bid,_Digits);          // latest Bid price
   mrequest.sl = NormalizeDouble(latest_price.bid + STP*_Point,_Digits); // Stop Loss
   mrequest.tp = NormalizeDouble(latest_price.bid - TKP*_Point,_Digits); // Take Profit
   mrequest.symbol = _Symbol;                                         // currency pair
   mrequest.volume = Lot;                                            // number of lots to trade
   mrequest.magic = EA_Magic;                                        // Order Magic Number
   mrequest.type= ORDER_TYPE_SELL;                                     // Sell Order
   mrequest.type_filling = ORDER_FILLING_FOK;                          // Order execution type
   mrequest.deviation=100;                                           // Deviation from current price
//--- send order
   OrderSend(mrequest,mresult);
   if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
     {
      Alert("A Sell order has been successfully placed with Ticket#:",mresult.order,"!!");
     }
   else
     {
      Alert("The Sell order request could not be completed -error:",GetLastError());
      ResetLastError();
      return;
     }
  }
  }
//+------------------------------------------------------------------+

