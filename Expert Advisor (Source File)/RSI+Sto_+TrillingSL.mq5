//+------------------------------------------------------------------+
//|                                               RSI+Stochastic.mq5 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

CTrade trade;

input group           "Stochastic" 
input int Sto_KPeriod = 5;                         //Stochastic: %K Period
input int Sto_DPeriod = 3;                         //Stochastic: %D Period
input int Sto_Slowing = 3;                         //Stochastic: Slowing
input ENUM_MA_METHOD Sto_MA_Method=MODE_SMA;       //Stochastic: MA Method
input ENUM_STO_PRICE Sto_PriceField = STO_LOWHIGH; //Stochastic: Price Field

input group           "Relative Strength Index" 
input int RSI_Period = 14;                 //RSI: Period

input group           "Moving Average"
input int MA_Period = 200;                //MA: Period
input int MA_Shift = 0;                   //MA: Shift
input ENUM_MA_METHOD MA_Method=MODE_SMA;  //MA: Method

input group           "StopLoss/TakeProfit"
double SL;
double TP;
input int stoploss = 200;                 //StopLoss: 
input int takeprofit = 400;               //TakeProfit: 

double openPrice;
double checkPoint;
string CurrentType = "";

int OnInit()
  {
//---
   
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
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   
   MqlRates PriceInfo[]; 
   ArraySetAsSeries(PriceInfo,true);
   int Data = CopyRates(_Symbol,_Period,0,3,PriceInfo);
      
   double KArray[];
   double DArray[];   
   ArraySetAsSeries(KArray,true);
   ArraySetAsSeries(DArray,true);   
   int StochasticDefinition = iStochastic(_Symbol,_Period,Sto_KPeriod,Sto_DPeriod,Sto_Slowing,Sto_MA_Method,Sto_PriceField);   
   CopyBuffer(StochasticDefinition,0,0,3,KArray); //LightSeaGreen = Main
   CopyBuffer(StochasticDefinition,1,0,3,DArray); //Red = Signal     
   
   //--- RSI Setup
   double myRSIArray[];
   int myRSIDefinition = iRSI(_Symbol,_Period,RSI_Period,PRICE_CLOSE);
   ArraySetAsSeries(myRSIArray,true);
   CopyBuffer(myRSIDefinition,0,0,3,myRSIArray);
   //---
   
   double myMovingAverageArray[];
   int movingAverageDefination = iMA (_Symbol,_Period,MA_Period,MA_Shift,MA_Method,PRICE_CLOSE);
   CopyBuffer(movingAverageDefination,0,0,3,myMovingAverageArray);
   
   if(myMovingAverageArray[0]<Ask){
      if(myRSIArray[0]>50 && myRSIArray[1]<50){
         if(KArray[0]<30 || DArray[0]<30){
            if(PositionsTotal()==0){
               if(stoploss == 0) SL = stoploss;
               if(stoploss != 0) SL = (Ask-stoploss*_Point);
               if(takeprofit == 0) TP = stoploss;
               if(takeprofit != 0) TP = (Ask+takeprofit*_Point);
                     
               checkPoint = Ask + ((takeprofit*_Point)*0.6);
               CurrentType = "Buy";
               openPrice = Ask;
                     
               trade.Buy(0.1,NULL,Ask,SL,TP,NULL);
            }  
         }
      }
   }
   
   if(myMovingAverageArray[0]>Bid){
      if(myRSIArray[0]<50 && myRSIArray[1]>50){
         if(KArray[0]>70 || DArray[0]>70){
            if(PositionsTotal()==0){
               if(stoploss == 0) SL = stoploss;
               if(stoploss != 0) SL = (Bid+stoploss*_Point);
               if(takeprofit == 0) TP = stoploss;
               if(takeprofit != 0) TP = (Bid-takeprofit*_Point);

               checkPoint = Bid - ((takeprofit*_Point)*0.6); 
               CurrentType = "Sell";
               openPrice = Bid;

               trade.Sell(0.1,NULL,Bid,SL,TP,NULL);
            }                 
         }
      }
   }
   
   int CandleNumber = Bars(_Symbol,_Period);   
   if(CheckForNewCandle(CandleNumber) == "YES, A NEW CANDLE APPEARED!"){
      if(PositionsTotal() == 1 && CurrentType == "Buy"){
         if(PriceInfo[1].close >= checkPoint && PriceInfo[1].low>PriceInfo[2].low)
            CheckTrailingStop(openPrice,TP,PriceInfo[1].low);
      }
      if(PositionsTotal() == 1 && CurrentType == "Sell"){
         if(PriceInfo[1].close <= checkPoint && PriceInfo[1].high<PriceInfo[2].high)
            CheckTrailingStop(openPrice,TP,PriceInfo[1].high); 
      }  
   } 
  }
//+------------------------------------------------------------------+
string CheckForNewCandle(int CandleNumber)
   {
      static int LastCandleNumber;
      
      string IsNewCandle = "no new candle";
      
      if(CandleNumber>LastCandleNumber)
      {
         IsNewCandle = "YES, A NEW CANDLE APPEARED!";
         LastCandleNumber = CandleNumber;
      }
      
      return IsNewCandle;
   }
void CheckTrailingStop(double priceOpen,double TakeProfit,double chk)
   {
      for(int i = PositionsTotal()-1;i>=0;i--){         
         string symbol = PositionGetSymbol(i);         
         if(_Symbol == symbol){
            if(PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY)
            {
               ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
               double CurrentStopLoss = PositionGetDouble(POSITION_SL);               
               double PositionPriceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
               if(chk > CurrentStopLoss)
                  trade.PositionModify(PositionTicket,chk,TakeProfit);         
            }
            if(PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL)
            {
               ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
               double CurrentStopLoss = PositionGetDouble(POSITION_SL);               
               double PositionPriceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
               if(chk < CurrentStopLoss)
                  trade.PositionModify(PositionTicket,chk,TakeProfit);         
            }
         }            
      }
   }