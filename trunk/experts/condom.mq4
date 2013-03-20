//+------------------------------------------------------------------+
//|                                                       condom.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, GIA"
#property link      "http://www.saita.net"


#include <BasicVariables.mqh>

//------- Внешние параметры советника -----------------------------------------+
extern string Expert_Self_Parameters = "Expert_Self_Parameters";
extern int historyDepth = 6;
extern bool tradeOnTrend = true;
extern int fastMACDPeriod = 12;
extern int slowMACDPeriod = 26;
extern double levelMACD = 0.007;

//------- Глобальные переменные советника -------------------------------------+

bool waitForSell = false;
bool waitForBuy = false;
//------- Подключение внешних модулей -----------------------------------------+
#include <stdlib.mqh>
#include <stderror.mqh>
#include <WinUser32.mqh>
//--------------------------------------------------------------- 3 --
#include <AddOnFuctions.mqh> 
#include <GetLastOrderHist.mqh>
#include <GetLots.mqh>     // На какое количество лотов открываемся
#include <isNewBar.mqh>
#include <DesepticonOpening.mqh>
#include <DesepticonTrailing.mqh>

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
 {
  _symbol=Symbol();
  timeframe = PERIOD_H1; 
  return(0);
 }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
 {
  Alert("сработала функция deinit");
  return(0);
 }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
   if( isNewBar(timeframe) ) // на каждом новом баре 
   {
    double globalMax = iHigh(_symbol, timeframe, iHighest(_symbol, timeframe, MODE_HIGH, historyDepth, 2));
    double globalMin = iLow(_symbol, timeframe, iLowest(_symbol, timeframe, MODE_LOW, historyDepth, 2));
        
    if(GreatDouble(globalMin, iClose(_symbol, timeframe, 1)) > 0)
    {
     waitForSell = false;
     waitForBuy = true;
     //Alert("WTB");
    }
    
    if(GreatDouble(iClose(_symbol, timeframe, 1), globalMax) > 0)
    {
     waitForBuy = false;
     waitForSell = true;
     //Alert("WTS");
    }
   }
   
   if (tradeOnTrend) // смотрим на тренд
   {
    double currentMACD = iMACD(_symbol, timeframe, fastMACDPeriod, slowMACDPeriod, 9, PRICE_CLOSE, MODE_MAIN, 0);
    if (GreatDouble(currentMACD, levelMACD) > 0 || GreatDouble(-levelMACD, currentMACD) > 0) // не торгуем на тренде
    {
     if (useTrailing) DesepticonTrailing(_symbol, timeframe);
     return;
    }
   }
   
   if (waitForBuy)
   { 
    if (Ask > iClose(_symbol, timeframe, 1) && Ask > iClose(_symbol, timeframe, 2))
    {
     if (DesepticonOpening(1, timeframe) > 0)
     {
      Alert("открыли сделку, сбросили счетчики");
      waitForBuy = false;
      waitForSell = false;
     }
    } 
   }
   if (waitForSell)
   { 
    if (Bid < iClose(_symbol, timeframe, 1) && Bid < iClose(_symbol, timeframe, 2))
    {
     if (DesepticonOpening(-1, timeframe) > 0)
     {
      Alert("открыли сделку, сбросили счетчики");
      waitForBuy = false;
      waitForSell = false;
     }
    }
   }
   
//----
   if (useTrailing) DesepticonTrailing(_symbol, timeframe);
   return(0);
  }
//+------------------------------------------------------------------+

