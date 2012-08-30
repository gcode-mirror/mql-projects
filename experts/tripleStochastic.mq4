//+------------------------------------------------------------------+
//|                                              desepticon v005.mq4 |
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
#include <CheckBeforeStart.mqh>       // Проверка входных параметров
//#include <DesepticonBreakthrough2.mqh>
#include <GetLastOrderHist.mqh>
#include <GetLots.mqh>     // На какое количество лотов открываемся
#include <isNewBar.mqh>
#include <Opening.mqh>
#include <DesepticonTrailing.mqh>

double Stochastic_1H_1 = 0;
double Stochastic_1H_2 = 0;
double Stochastic_M30_1 = 0;
double Stochastic_M30_2 = 0;
double Stochastic_M5 = 0;
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init(){
  Alert("Сработала ф-ия init() при запуске");
  
  aTimeframe[0,0] = PERIOD_D1; 
  aTimeframe[0,1] = TakeProfit_1D;
  aTimeframe[0,2] = StopLoss_1D_min;
  aTimeframe[0,3] = StopLoss_1D_max;
  aTimeframe[0,4] = MACD_channel_1D;
  aTimeframe[0,5] = MinProfit_1D;
  aTimeframe[0,6] = TrailingStop_1D_min;
  aTimeframe[0,7] = TrailingStop_1D_max;
  aTimeframe[0,8] = TrailingStep_1D;
  aTimeframe[0,9] = PERIOD_H1;
  
  aTimeframe[1,0] = PERIOD_H1;
  aTimeframe[1,1] = TakeProfit_1H;
  aTimeframe[1,2] = StopLoss_1H_min;
  aTimeframe[1,3] = StopLoss_1H_max;
  aTimeframe[1,4] = MACD_channel_1H;
  aTimeframe[1,5] = MinProfit_1H;
  aTimeframe[1,6] = TrailingStop_1H_min;
  aTimeframe[1,7] = TrailingStop_1H_max;
  aTimeframe[1,8] = TrailingStep_1H;
  aTimeframe[1,9] = PERIOD_M5;
  
  aTimeframe[2,0] = PERIOD_M5;
  aTimeframe[2,1] = TakeProfit_5M;
  aTimeframe[2,2] = StopLoss_5M_min;
  aTimeframe[2,3] = StopLoss_5M_max;
  aTimeframe[2,4] = MACD_channel_5M;
  aTimeframe[2,5] = MinProfit_5M;
  aTimeframe[2,6] = TrailingStop_5M_min;
  aTimeframe[2,7] = TrailingStop_5M_max;
  aTimeframe[2,8] = TrailingStep_5M;
  aTimeframe[2,9] = PERIOD_M5;
  
  Stochastic_1H_1 = iStochastic(NULL, PERIOD_H1, Kperiod, Dperiod , slowing ,MODE_SMA,0,MODE_MAIN,1);
  Stochastic_1H_2 = iStochastic(NULL, PERIOD_H1, Kperiod, Dperiod , slowing ,MODE_SMA,0,MODE_MAIN,2);
  
  Stochastic_M30_1 = iStochastic(NULL, PERIOD_M30, Kperiod, Dperiod , slowing ,MODE_SMA,0,MODE_MAIN,1);
  Stochastic_M30_2 = iStochastic(NULL, PERIOD_M30, Kperiod, Dperiod , slowing ,MODE_SMA,0,MODE_MAIN,2);
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
//| Check for buy conditions function                                |
//+------------------------------------------------------------------+
int CheckBuyCondition()
{
 if (Stochastic_1H_1 > Stochastic_1H_2 && Stochastic_M30_1 > Stochastic_M30_2 && Stochastic_M5 < bottomStochastic)
 {
  return(100); 
 }
 return(0); 
}

//+------------------------------------------------------------------+
//| Check for sell conditions function                               |
//+------------------------------------------------------------------+
int CheckSellCondition()
{
 if (Stochastic_1H_1 < Stochastic_1H_2 && Stochastic_M30_1 < Stochastic_M30_2 && Stochastic_M5 > topStochastic)
 {
  return(100);
 }
 return(0);
}
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
{
 Jr_Timeframe = PERIOD_M5;
 //Elder_Timeframe = aTimeframe[frameIndex, 0];
     
 TakeProfit = aTimeframe[2, 1];
 StopLoss_min = aTimeframe[2, 2];
 StopLoss_max = aTimeframe[2, 3]; 
 //Jr_MACD_channel = aTimeframe[frameIndex + 1, 4];
 //Elder_MACD_channel = aTimeframe[frameIndex, 4];
     
 MinProfit = aTimeframe[2, 5]; 
 TrailingStop_min = aTimeframe[2, 6];
 TrailingStop_max = aTimeframe[2, 7]; 
 TrailingStep = aTimeframe[2, 8];
 
 if (!CheckBeforeStart())  return (0); // проверяем входные параметры
 
 if( isNewBar(PERIOD_H1) ) // на каждом новом баре старшего ТФ вычисляем тренд и коррекцию на старшем
 {
   Stochastic_1H_2 = Stochastic_1H_1;
   Stochastic_1H_1 = iStochastic(NULL, PERIOD_H1, Kperiod, Dperiod , slowing ,MODE_SMA,0,MODE_MAIN,1);
 }
 
 if( isNewBar(PERIOD_M30) ) // на каждом новом баре старшего ТФ вычисляем тренд и коррекцию на старшем
 {
  Stochastic_M30_2 = Stochastic_M30_1;
  Stochastic_M30_1 = iStochastic(NULL, PERIOD_M30, Kperiod, Dperiod , slowing ,MODE_SMA,0,MODE_MAIN,1);
 }

 if( isNewBar(PERIOD_M5) ) // на каждом новом баре старшего ТФ вычисляем тренд и коррекцию на старшем
 { 
  Stochastic_M5 = iStochastic(NULL, PERIOD_M5, Kperiod, Dperiod , slowing ,MODE_SMA,0,MODE_MAIN,1);
  buyCondition = CheckBuyCondition();
  sellCondition = CheckSellCondition(); 
 }
 
 if (buyCondition > sellCondition)
 {
  Opening(OP_BUY);
  buyCondition = 0;
  sellCondition = 0; 
 }
 if (sellCondition > buyCondition)
 {
  Opening(OP_SELL);
  buyCondition = 0;
  sellCondition = 0; 
 }

//----
	if (UseTrailing) DesepticonTrailing(); 
	return(0);
} // close start
//+------------------------------------------------------------------+