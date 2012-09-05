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
#include <AddOnFuctions.mqh> 
#include <InitDivergenceArray.mqh>
#include <InitExtremums.mqh>
#include <CheckBeforeStart.mqh>       // Проверка входных параметров
#include <DesepticonTrendCriteria.mqh>
//#include <direction_MACD.mqh>
#include <DesepticonBreakthrough2.mqh>
#include <searchForTits.mqh>
//#include <DesepticonDivergence.mqh>
#include <GetLastOrderHist.mqh>
#include <GetLots.mqh>     // На какое количество лотов открываемся
#include <isNewBar.mqh>
#include <UpdateDivergenceArray.mqh>
#include <isMACDExtremum.mqh>
#include <_isDivergence.mqh>
#include <DesepticonOpening.mqh>
#include <DesepticonTrailing.mqh>

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
  
  ArrayInitialize(aCorrection, 0);

  for (frameIndex = startTF; frameIndex <= finishTF; frameIndex++)
  {
   // инициализируем расхождение MACD
   InitDivergenceArray(aTimeframe[frameIndex, 0]);
   //Alert("проинитили массив расхождения MACD");
   InitTrendDirection(aTimeframe[frameIndex, 0], aTimeframe[frameIndex,4]);
   //Alert("проинитили направление тренда");
   InitExtremums(frameIndex);
   //Alert("проинитили экстремумы MACD");
  }
  
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
     Jr_Timeframe = aTimeframe[frameIndex, 9];
     Elder_Timeframe = aTimeframe[frameIndex, 0];
     
     TakeProfit = aTimeframe[frameIndex, 1];
     StopLoss_min = aTimeframe[frameIndex, 2];
     StopLoss_max = aTimeframe[frameIndex, 3]; 
     Jr_MACD_channel = aTimeframe[frameIndex + 1, 4];
     Elder_MACD_channel = aTimeframe[frameIndex, 4];
     
     MinProfit = aTimeframe[frameIndex, 5]; 
     TrailingStop_min = aTimeframe[frameIndex, 6];
     TrailingStop_max = aTimeframe[frameIndex, 7]; 
     TrailingStep = aTimeframe[frameIndex, 8];
     
     if (!CheckBeforeStart())  return (0); // проверяем входные параметры
     
     total=OrdersTotal();


     if( isNewBar(Elder_Timeframe) ) // на каждом новом баре старшего ТФ вычисляем тренд и коррекцию на старшем
     {
      trendDirection[frameIndex][0] = TwoTitsTrendCriteria(Elder_Timeframe, Elder_MACD_channel, eld_EMA1, eld_EMA2, eldFastMACDPeriod, eldSlowMACDPeriod);
      if (trendDirection[frameIndex][0] > 0) // Есть тренд вверх на старшем таймфрейме
      {
       trendDirection[frameIndex][1] = 1;
      }
      if (trendDirection[frameIndex][0] < 0) // Есть тренд вниз
      {
       trendDirection[frameIndex][1] = -1;
      }
      
  //--------------------------
  // проверяемм что все еще хотим открываться
  //--------------------------     
      if (wantToOpen[frameIndex][0] != 0) // если хотели открываться по расхождению MACD
      {
       barsCountToBreak[frameIndex][0]++;
       if (barsCountToBreak[frameIndex][0] > breakForMACD)
       { 
        barsCountToBreak[frameIndex][0] = 0; // дальше 4х баров забываем, что хотели открываться
        wantToOpen[frameIndex][0] = 0;
       }
      }
  //--------------------------
  // проверяем, что все еще хотим открываться
  //--------------------------     
      
  //--------------------------
  // вычисляем расхождение MACD
  //--------------------------     
      
      UpdateDivergenceArray(Elder_Timeframe); // Обновляем массив экстремумов MACD
      InitExtremums(frameIndex); // обновляем максимумы цены и MACD
      if (wantToOpen[frameIndex][0] == 0) // если еще не хотим открываться
      {   
       wantToOpen[frameIndex][0] = _isDivergence(Elder_Timeframe);  // проверяем на расхождение на этом баре       
      } 
  //--------------------------
  // вычисляем расхождение MACD
  //-------------------------- 
     
     } // close isNewBar(Elder_Timeframe)

     //-------------------------------------------------------------------------------------------
     // Флэт
     //-------------------------------------------------------------------------------------------      
     if (trendDirection[frameIndex][0] == 0)    // определяем флэт, потом ищем критерии входа по MACD, открываемся.
     {
      
      if (Ask > iMA(NULL, Elder_Timeframe, 3, 0, 1, PRICE_HIGH, 0) + hairLength*Point)
      {
       trendDirection[frameIndex][0] = 1;
       trendDirection[frameIndex][1] = 1;
       return(0);
      }
      if (Bid < iMA(NULL, Elder_Timeframe, 3, 0, 1, PRICE_LOW, 0) - hairLength*Point)
      {
       trendDirection[frameIndex][0] = -1;
       trendDirection[frameIndex][1] = -1;
       return(0);
      }

	//--------------------------
	// Расхождение 
	//--------------------------
	   if (wantToOpen[frameIndex][0] > 0) // нашли расхождение вверх (ждем рост), ждем пробой максимума, будем покупать
      {
       if (Bid < iMA(NULL, Elder_Timeframe, 3, 0, 1, 0, 0) + deltaPriceToEMA*Point)
       {
        openPlace = "старший ТФ флэт, " + openPlace;
	     if (DesepticonBreakthrough2(1, Jr_Timeframe) != 0) // при определенной экстремальной цене, ищем пробой, открываемся
	     {
	      // вставить обработчик ошибки открытия сделки 
	     }
	    }
      } // close нашли расхождение вверх
    
      if (wantToOpen[frameIndex][0] < 0) // нашли расхождение вниз (ждем падение), ждем пробой минимума, будем продавать
      {
       if (Ask > iMA(NULL, Elder_Timeframe, 3, 0, 1, 0, 0) - deltaPriceToEMA*Point)
       {
        openPlace = "старший ТФ флэт, " + openPlace;
	     if (DesepticonBreakthrough2(-1, Jr_Timeframe) <= 0) // при определенной экстремальной цене, ищем пробой, открываемся
	     {
	      // вставить обработчик ошибки открытия сделки 
	     }
	    }
      } // close нашли расхождение вниз
	//--------------------------
	// Расхождение 
	//--------------------------
   
     } // close Флэт	
    } // close цикл
//----
	if (UseTrailing) DesepticonTrailing(); 
	return(0);
} // close start
//+------------------------------------------------------------------+