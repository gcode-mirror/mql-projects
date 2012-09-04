//+------------------------------------------------------------------+
//|                                              desepticon v004.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, GIA"
#property link      "http://www.saita.net"

#include <stdlib.mqh>
#include <stderror.mqh>
#include <WinUser32.mqh>
//--------------------------------------------------------------- 3 --
#include <DesepticonVariables.mqh>    // Описание переменных 
#include <isNewBar.mqh>

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init(){
  Alert("Сработала ф-ия init() при запуске");
  
  aTimeframe[0,0] = PERIOD_H1; 
  aTimeframe[0,1] = TakeProfit_1H;
  aTimeframe[0,2] = StopLoss_1H_min;
  aTimeframe[0,3] = StopLoss_1H_max;
  aTimeframe[0,4] = MACD_channel_1H;
  aTimeframe[0,5] = MACD_channel_1D;
  aTimeframe[0,6] = MinProfit_1H;
  aTimeframe[0,7] = TrailingStop_1H_min;
  aTimeframe[0,8] = TrailingStop_1H_max;
  aTimeframe[0,9] = TrailingStep_1H;
  aTimeframe[0,10] = PERIOD_D1;
  
  aTimeframe[1,0] = PERIOD_M5;
  aTimeframe[1,1] = TakeProfit_5M;
  aTimeframe[1,2] = StopLoss_5M_min;
  aTimeframe[1,3] = StopLoss_5M_max;
  aTimeframe[1,4] = MACD_channel_5M;
  aTimeframe[1,5] = MACD_channel_1H;
  aTimeframe[1,6] = MinProfit_5M;
  aTimeframe[1,7] = TrailingStop_5M_min;
  aTimeframe[1,8] = TrailingStop_5M_max;
  aTimeframe[1,9] = TrailingStep_5M;
  aTimeframe[1,10] = PERIOD_H1;
 
  return(0);
 }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit(){
	Alert("сработала функция deinit");
	return(0);
}
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start(){
	for (frameIndex = startTF; frameIndex < finishTF; frameIndex++){
     //Alert ("Вход на новый ТФ");
     //Alert ("frameIndex", frameIndex);
     Jr_Timeframe = aTimeframe[frameIndex, 0];
     Elder_Timeframe = aTimeframe[frameIndex, 10];
  
  //--------------------------------------
  // временная заглушка для отказа от торговли при флэте на младшем ТФ
  //--------------------------------------
     if( isNewBar(Jr_Timeframe) ) // на каждом новом баре
     {
      Alert("новый бар на младшем");
     }
  //--------------------------------------
  // временная заглушка для отказа от торговли при флэте на младшем ТФ
  //--------------------------------------
  
     if( isNewBar(Elder_Timeframe) ) // на каждом новом баре
     {
      Alert("новый бар на старшем");
     } // close isNewBar
   }      
	return(0);
}
//+------------------------------------------------------------------+