//+------------------------------------------------------------------+
//|                                                 ParabolicSAR.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

CTrade trade; 

input group           "Average Directional Movement Index" 
input int ADX_Period = 14;                //ADX: Period

input group           "Parabolic SAR" 
input double PSar_Step = 0.03;            //PSar: Step
input double PSar_Maximum = 0.2;          //PSar: Maximum

input group           "Moving Average"
input int MA_Period = 200;                //MA: Period
input int MA_Shift = 0;                   //MA: Shift
input ENUM_MA_METHOD MA_Method=MODE_SMA;  //MA: Method

input group           "Other"
double SL;
double TP;
input int stoploss = 200;                 //StopLoss: 
input int takeprofit = 400;               //TakeProfit:
input double lotSize = 0.1;              //LotSize: 

int OnInit()
  {
//---
   ResetLastError();
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---  
   // Get current ask, bid
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   
   // Get current OHLC
   MqlRates PriceInfo[]; 
   ArraySetAsSeries(PriceInfo,true);
   int Data = CopyRates(_Symbol,_Period,0,3,PriceInfo);
   
   // PSar Setup   
   double mySARArray[];
   int SARDefinition = iSAR(_Symbol,_Period,PSar_Step, PSar_Maximum);
   ArraySetAsSeries(mySARArray,true);
   CopyBuffer(SARDefinition,0,0,3,mySARArray);
   
   // ADX Setup 
   double ADX_PriceArray[];
   double ADX_UpperBandArray[];
   double ADX_LowerBandArray[];
   int ADXDefinition = iADX(_Symbol,_Period,ADX_Period);
   ArraySetAsSeries(ADX_PriceArray,true);
   ArraySetAsSeries(ADX_UpperBandArray,true);
   ArraySetAsSeries(ADX_LowerBandArray,true);  
   CopyBuffer(ADXDefinition,0,0,3,ADX_PriceArray);
   CopyBuffer(ADXDefinition,1,0,3,ADX_UpperBandArray);
   CopyBuffer(ADXDefinition,2,0,3,ADX_LowerBandArray);
   
   // MA Setup 
   double myMovingAverageArray[];
   int movingAverageDefination = iMA (_Symbol,_Period,MA_Period,MA_Shift,MA_Method,PRICE_CLOSE);
   ArraySetAsSeries(myMovingAverageArray,true);
   CopyBuffer(movingAverageDefination,0,0,3,myMovingAverageArray);
   
   // Buy Condition
   if(ADX_UpperBandArray[0] > ADX_LowerBandArray[0] && ADX_UpperBandArray[1] < ADX_LowerBandArray[1]){
      if(ADX_PriceArray[0] > 25){
         if(mySARArray[0] < PriceInfo[0].low){
            if(myMovingAverageArray[0] < Ask){
               if(PositionsTotal()<1){
                  if(stoploss == 0) SL = stoploss;
                  if(stoploss != 0) SL = (Ask-stoploss*_Point);
                  if(takeprofit == 0) TP = stoploss;
                  if(takeprofit != 0) TP = (Ask+takeprofit*_Point);
                     
                  trade.Buy(lotSize,NULL,Ask,SL,TP,NULL);
                     
               }
            }
         }
      }
   }
   // Sell Condition      
   else if(ADX_UpperBandArray[0] < ADX_LowerBandArray[0] && ADX_UpperBandArray[1] > ADX_LowerBandArray[1]){
      if(ADX_PriceArray[0] > 25){
         if(mySARArray[0] > PriceInfo[0].high){
            if(myMovingAverageArray[0] > Bid){
               if(PositionsTotal()<1){                  
                  if(stoploss == 0) SL = stoploss;
                  if(stoploss != 0) SL = (Bid+stoploss*_Point);
                  if(takeprofit == 0) TP = stoploss;
                  if(takeprofit != 0) TP = (Bid-takeprofit*_Point);
                      
                  trade.Sell(lotSize,NULL,Bid,SL,TP,NULL);
                     
               }
            }
         }
      }
   }          
  }
//+------------------------------------------------------------------+
