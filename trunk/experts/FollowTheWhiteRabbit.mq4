//+------------------------------------------------------------------+
//|                                         FollowTheWhiteRabbit.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, GIA"
#property link      "http://www.saita.net"

#include <BasicVariables.mqh>
//------- Внешние параметры советника -----------------------------------------+
extern string Expert_Self_Parameters = "Expert_Self_Parameters";
extern int historyDepth = 6;
extern double supremacyPercent = 0.6;

//------- Глобальные переменные советника -------------------------------------+

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
   double sum = 0;
   double avgBar = 0;
   double lastBar = 0;
   int i = 0;   // счетчик
   int positionType;
   
   if( isNewBar(timeframe) ) // на каждом новом баре 
   {
    for(i = historyDepth; i > 1; i--)
    {
     sum = sum + iHigh(_symbol, timeframe, i) - iLow(_symbol, timeframe, i);  
    }
    avgBar = sum / historyDepth;
    lastBar = iHigh(_symbol, timeframe, 1) - iLow(_symbol, timeframe, 1);
    
    if(GreatDouble(lastBar, avgBar*(1 + supremacyPercent)) > 0)
    {
     Print("last bar = ", NormalizeDouble(lastBar,8), " avg Bar = ", NormalizeDouble(avgBar,8)*(1 + supremacyPercent));

     if(GreatDouble(iOpen(_symbol, timeframe, 1), iClose(_symbol, timeframe, 1)) > 0)
     {
      if (DesepticonOpening(-1, timeframe) > 0)
	   {
       Alert("открыли сделку, начали отсчет");
   //    isMinProfit = false; // сделка длится
   //    barNumber = 0;
      }
     }
     
     if(GreatDouble(iClose(_symbol, timeframe, 1), iOpen(_symbol, timeframe, 1)) > 0)
     {
      if (DesepticonOpening(1, timeframe) > 0)
      {
       Alert("открыли сделку, начали отсчет");
   //    isMinProfit = false; // сделка длится
   //    barNumber = 0;
      }
     }
    }
   }
//----
   if (useTrailing) DesepticonTrailing(NULL, timeframe);
   return(0);
  }
//+------------------------------------------------------------------+