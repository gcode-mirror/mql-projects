//+------------------------------------------------------------------+
//|                                              divergence v001.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, GIA"
#property link      "http://www.saita.net"

#include <stdlib.mqh>
#include <stderror.mqh>
#include <WinUser32.mqh>
//--------------------------------------------------------------- 3 --
//#include <Variables.mqh>   // Описание переменных 
#include <DesepticonVariables.mqh>
#include <InitDivergenceArray.mqh>
#include <InitExtremums.mqh>
#include <CheckBeforeStart.mqh>       // Проверка входных параметров
#include <GetLastOrderHist.mqh>
#include <GetLots.mqh> // На какое количество лотов открываемся
#include <isNewBar.mqh>
#include <UpdateDivergenceArray.mqh>
#include <isMACDExtremum.mqh>
#include <_isDivergence.mqh>
#include <Opening.mqh>
#include <TrailingPositions.mqh>

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init() 
 { 
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
  
  frameIndex = startTF;
  
  Jr_Timeframe = aTimeframe[frameIndex, 0];
     
  TakeProfit = aTimeframe[frameIndex, 1];
  StopLoss_min = aTimeframe[frameIndex, 2];
  StopLoss_max = aTimeframe[frameIndex, 3];
  
  minPriceForDiv[frameIndex][0] = 0;
  maxPriceForDiv[frameIndex][0] = 0;
  ArrayInitialize(wantToOpen, 0);
  waitForMACDMaximum[frameIndex] = false;
  waitForMACDMinimum[frameIndex] = false;
  InitDivergenceArray(Jr_Timeframe);
  InitExtremums(frameIndex);
  
  //Alert (aDivergence[0][0]);
  int index;
  
  for (int i = 1; i <= aDivergence[0][0][0]; i++){
   index = aDivergence[0][i][3];
   Alert ("Значание MACD ", aDivergence[0][i][1],
          " Знач цены ", aDivergence[0][i][2],
          " номер бара ", aDivergence[0][i][3],
          " вверх/вниз ", aDivergence[0][i][4],
          " время бара ",
                TimeDay(iTime(NULL, aTimeframe[startTF,0], index)),":",
                TimeHour(iTime(NULL, aTimeframe[startTF,0], index)),":",
                TimeMinute(iTime(NULL, aTimeframe[startTF,0], index))
          );
  }
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
void start()
  {
   if (!CheckBeforeStart()) // проверяем входные параметры
    { return (0); }
   
   if( isNewBar(Jr_Timeframe) ) // на каждом новом баре
   { 
    UpdateDivergenceArray(Jr_Timeframe); // Обновляем массив экстремумов MACD
    InitExtremums(frameIndex); // обновляем максимумы цены и MACD
    
    if (wantToOpen[frameIndex][0] != 0){ // если хотели открываться
      barsCountToBreak[frameIndex][0]++;
      if (barsCountToBreak[frameIndex][0] > 6){ 
        barsCountToBreak[frameIndex][0] = 0; // дальше 6-ти баров забываем, что хотели открываться
        wantToOpen[frameIndex][0] = 0;
      }
    }
        
    if (wantToOpen[frameIndex][0] == 0) // если еще не хотим открываться   
      wantToOpen[frameIndex][0] = _isDivergence(Jr_Timeframe);  // проверяем на расхождение на этом баре  
   } // close на каждом новом баре
   
   total=OrdersTotal();
   if (total < 1)
   { // Нету открытых ордеров -> ищем возможность открытия

    if (wantToOpen[frameIndex][0] > 0) // нашли расхождение вверх (ждем рост), ждем пробой максимума, будем покупать
    {
     if (Ask > iHigh(NULL, Jr_Timeframe, 1) && Ask > iHigh(NULL, Jr_Timeframe, 2))  // Если пробит максимум
     {
      Opening(OP_BUY);
     } // close Если пробит максимум
    } // close нашли расхождение вверх
    
    if (wantToOpen[frameIndex][0] < 0) // нашли расхождение вниз (ждем падение), ждем пробой минимума, будем продавать
    {
     if (Bid < iLow(NULL, Jr_Timeframe, 1) && Bid < iLow(NULL, Jr_Timeframe, 2)) // Если пробит минимум
     {
      Opening(OP_SELL);
     } // close Если пробит минимум
    } // close нашли расхождение вниз
   } // close  Нету открытых ордеров
    
   if (UseTrailing) TrailingPositions();
  } // end