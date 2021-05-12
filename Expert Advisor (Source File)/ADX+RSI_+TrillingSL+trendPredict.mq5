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

double openPrice;
double checkPoint;
string CurrentType = "";

string MLResult[51][2] = {{"2020.10.21","UpTrend"},{"2020.10.22","UpTrend"},{"2020.10.23","DownTrend"},{"2020.10.26","UpTrend"},{"2020.10.27","DownTrend"},{"2020.10.28","DownTrend"},{"2020.10.29","DownTrend"},{"2020.10.30","DownTrend"},{"2020.11.02","DownTrend"},{"2020.11.03","DownTrend"},{"2020.11.04","UpTrend"},{"2020.11.05","UpTrend"},{"2020.11.06","UpTrend"},{"2020.11.09","UpTrend"},{"2020.11.10","DownTrend"},{"2020.11.11","DownTrend"},{"2020.11.12","DownTrend"},{"2020.11.13","UpTrend"},{"2020.11.16","UpTrend"},{"2020.11.17","UpTrend"},{"2020.11.18","UpTrend"},{"2020.11.19","DownTrend"},{"2020.11.20","UpTrend"},{"2020.11.23","DownTrend"},{"2020.11.24","DownTrend"},{"2020.11.25","UpTrend"},{"2020.11.26","UpTrend"},{"2020.11.27","UpTrend"},{"2020.11.30","UpTrend"},{"2020.12.01","DownTrend"},{"2020.12.02","UpTrend"},{"2020.12.03","UpTrend"},{"2020.12.04","UpTrend"},{"2020.12.07","DownTrend"},{"2020.12.08","DownTrend"},{"2020.12.09","DownTrend"},{"2020.12.10","DownTrend"},{"2020.12.11","UpTrend"},{"2020.12.14","UpTrend"},{"2020.12.15","UpTrend"},{"2020.12.16","UpTrend"},{"2020.12.17","UpTrend"},{"2020.12.18","UpTrend"},{"2020.12.21","UpTrend"},{"2020.12.22","DownTrend"},{"2020.12.23","DownTrend"},{"2020.12.24","DownTrend"},{"2020.12.28","UpTrend"},{"2020.12.29","UpTrend"},{"2020.12.30","UpTrend"},{"2020.12.31","UpTrend"}};
string trend = "";
string tmpdate = "";

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
   
   string date = TimeToString(TimeGMT(),TIME_DATE);
   if(tmpdate != date){
      for(int i = 0;i<51;i++){
         if(date == MLResult[i][0]){
            if(MLResult[i][1] == "UpTrend"){
               trend="UpTrend";
            }
               
            if(MLResult[i][1] == "DownTrend"){
               trend="DownTrend";
            }
            Comment(trend);  
         }       
      }
   }
   
   // Get current ask, bid
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);   
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   
   // Get current OHLC
   MqlRates PriceInfo[]; 
   ArraySetAsSeries(PriceInfo,true);
   int Data = CopyRates(_Symbol,_Period,0,3,PriceInfo);
   
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
   if(trend == "UpTrend")  
   if(ADX_UpperBandArray[0] > ADX_LowerBandArray[0] && ADX_UpperBandArray[1] < ADX_LowerBandArray[1]){
      if(ADX_PriceArray[0] > 25 ){
         if(myRSIArray[0] > 50 ){
            if(myMovingAverageArray[0]<Ask){
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
   }
   // Sell Condition
   if(trend == "DownTrend")  
   if(ADX_UpperBandArray[0] < ADX_LowerBandArray[0] && ADX_UpperBandArray[1] > ADX_LowerBandArray[1]){
      if(ADX_PriceArray[0] > 25 ){
         if(myRSIArray[0] < 50 ){
            if(myMovingAverageArray[0]>Bid){
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