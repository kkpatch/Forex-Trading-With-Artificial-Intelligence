#include <Trade\Trade.mqh>

CTrade trade;   


input group           "Average Directional Movement Index" 
input int ADX_Period = 14;                //ADX: Period

input group           "Relative Strength Index" 
input int RSI_Period = 7;                 //RSI: Period

input group           "Moving Average"
input int MA_Period = 200;                //MA: Period
input int MA_Shift = 0;                   //MA: Shift
input ENUM_MA_METHOD MA_Method=MODE_SMA;  //MA: Method

input group           "StopLoss/TakeProfit"
double SL;
input int stoploss = 300;       //StopLoss: 
double TP;
input int takeprofit = 500;     //TakeProfit: 

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
   // Get current ask, bid
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);   
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   
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
   
   // RSI Setup
   double myRSIArray[];
   int myRSIDefinition = iRSI(_Symbol,_Period,RSI_Period,PRICE_CLOSE);
   ArraySetAsSeries(myRSIArray,true);
   CopyBuffer(myRSIDefinition,0,0,3,myRSIArray);

   // MA Setup 
   double myMovingAverageArray[];
   ArraySetAsSeries(myMovingAverageArray,true);
   int movingAverageDefination = iMA (_Symbol,_Period,MA_Period,MA_Shift,MA_Method,PRICE_CLOSE);
   CopyBuffer(movingAverageDefination,0,0,3,myMovingAverageArray); //copy from movingAverageDefination to myMovingAverageArray

   // Buy Condition  
   if(ADX_UpperBandArray[0] > ADX_LowerBandArray[0] && ADX_UpperBandArray[1] < ADX_LowerBandArray[1]){
      if(ADX_PriceArray[0] > 25 ){
         if(myRSIArray[0] > 50 ){
            if(myMovingAverageArray[0]<Ask){
               if(PositionsTotal()==0){
                  if(stoploss == 0) SL = stoploss;
                  if(stoploss != 0) SL = (Ask-stoploss*_Point);
                  if(takeprofit == 0) TP = stoploss;
                  if(takeprofit != 0) TP = (Ask+takeprofit*_Point);
                  
                  trade.Buy(0.1,NULL,Ask,SL,TP,NULL);
               }
            }  
         }  
      }    
   }
   // Sell Condition 
   else if(ADX_UpperBandArray[0] < ADX_LowerBandArray[0] && ADX_UpperBandArray[1] > ADX_LowerBandArray[1]){
      if(ADX_PriceArray[0] > 25 ){
         if(myRSIArray[0] < 50 ){
            if(myMovingAverageArray[0]>Bid){
               if(PositionsTotal()==0){
                  if(stoploss == 0) SL = stoploss;
                  if(stoploss != 0) SL = (Bid+stoploss*_Point);
                  if(takeprofit == 0) TP = stoploss;
                  if(takeprofit != 0) TP = (Bid-takeprofit*_Point);
                  
                  trade.Sell(0.1,NULL,Bid,SL,TP,NULL);
                     
               }
            }    
         }      
      }   
   }        
  }   
//+------------------------------------------------------------------+
