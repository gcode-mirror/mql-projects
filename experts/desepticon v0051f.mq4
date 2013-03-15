//+------------------------------------------------------------------+
//|                                              desepticon v004.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, GIA"
#property link      "http://www.saita.net"

//------- Внешние параметры советника -----------------------------------------+
extern int hairLength = 250;

extern int Kperiod = 5;
extern int Dperiod = 3;
extern int slowing = 3;
extern int topStochastic = 80;
extern int bottomStochastic = 20;
//------- Глобальные переменные советника -------------------------------------+


//------- Подключение внешних модулей -----------------------------------------+
#include <stdlib.mqh>
#include <stderror.mqh>
#include <WinUser32.mqh>
//--------------------------------------------------------------- 3 --
#include <DesepticonVariables.mqh>    // Описание переменных 
#include <AddOnFuctions.mqh> 
#include <CheckBeforeStart.mqh>       // Проверка входных параметров
#include <DesepticonTrendCriteria.mqh>
#include <DesepticonBreakthrough2.mqh>
#include <searchForTits.mqh>
#include <GetLastOrderHist.mqh>
#include <GetLots.mqh>     // На какое количество лотов открываемся
#include <isNewBar.mqh>
#include <isMACDExtremum.mqh>
#include <DesepticonOpening.mqh>
#include <DesepticonTrailing.mqh>

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init(){
  Alert("Сработала ф-ия init() при запуске");

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
  
  for (frameIndex = startTF; frameIndex <= finishTF; frameIndex++)
  {
   InitTrendDirection(aTimeframe[frameIndex, 0], aTimeframe[frameIndex,4]);
   //Alert("проинитили направление тренда");
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
  for (frameIndex = startTF; frameIndex < finishTF; frameIndex++)
  {
   Jr_Timeframe = aTimeframe[frameIndex, 9];
   Elder_Timeframe = aTimeframe[frameIndex, 0];
   
   TakeProfit = aTimeframe[frameIndex, 1];
   StopLoss_min = aTimeframe[frameIndex, 2];
   StopLoss_max = aTimeframe[frameIndex, 3]; 
   Jr_MACD_channel = aTimeframe[frameIndex + 1, 4];
   Elder_MACD_channel = aTimeframe[frameIndex, 4];
   
   minProfit = aTimeframe[frameIndex, 5]; 
   trailingStop_min = aTimeframe[frameIndex, 6];
   trailingStop_max = aTimeframe[frameIndex, 7]; 
   trailingStep = aTimeframe[frameIndex, 8];
   
   if (!CheckBeforeStart())   // проверяем входные параметры
   {
    PlaySound("alert2.wav");
    return (0); 
   }
    
   if (total > 0)
   {
    for (int i=0; i<total; i++)
    {
     if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
     {
      if (OrderMagicNumber() == _MagicNumber)  
      {
       if (OrderType()==OP_BUY)   // Открыта длинная позиция BUY
       {
        if (!isMinProfit && Bid-OrderOpenPrice() > MinimumLvl*Point) // достигли минимального уровня прибыли
        {
         isMinProfit = true;
         Alert("мин профит на промежутке. Прекращаем отсчет. isMinProfit = ",isMinProfit);
        }

        if (isMinProfit && Bid < OrderOpenPrice())
        {
         Alert("Buy, мин профит был достигнут ранее, перешли 0 запускаем счетчик заново");
	      isMinProfit = false; // сделка длится
	      barNumber = 0;
        }
        
        if (useLowTF_EMA_Exit)
        {
         if (Bid-OrderOpenPrice() > minProfit*Point) // получили минимальный профит
         {
          if (iMA(NULL, Jr_Timeframe, jr_EMA2, 0, 1, 0, 0) 
                 > iMA(NULL, Jr_Timeframe, jr_EMA1, 0, 1, 0, 0) + deltaEMAtoEMA*Point) // разворот движения EMA  на младшем ТФ
          {
           ClosePosBySelect(Bid, "получена минимальная прибыль, разворот ЕМА на младщем ТФ, фиксируем прибыль"); // закрываем позицию BUY
           Alert("Закрыли ордер, обнуляем переменные. Bid-OrderOpenPrice()= ",Bid-OrderOpenPrice(), " minProfit ", minProfit*Point);
          }
         } // close получили минимальный профит 
        }
       } // Close открыта длинная позиция BUY
        
       if (OrderType()==OP_SELL) // Открыта короткая позиция SELL
       {
        if (!isMinProfit && OrderOpenPrice()-Ask > MinimumLvl*Point) // достигли минимального уровня прибыли
        {
         isMinProfit = true;
         Alert("Sell, мин профит на промежутке. Прекращаем отсчет. isMinProfit = ",isMinProfit);
        }

        if (isMinProfit && Ask > OrderOpenPrice())
        {
         Alert("мин профит был достигнут ранее, перешли 0 запускаем счетчик заново");
	      isMinProfit = false; // сделка длится
	      barNumber = 0;
        }
        
        if (useLowTF_EMA_Exit)
        {
         if (OrderOpenPrice()-Ask > minProfit*Point)
         {
          if (iMA(NULL, Jr_Timeframe, jr_EMA2, 0, 1, 0, 0)
                 < iMA(NULL, Jr_Timeframe, jr_EMA1, 0, 1, 0, 0) - deltaEMAtoEMA*Point) // разворот движения EMA  на младшем ТФ
          {
           ClosePosBySelect(Ask, "получена минимальная прибыль, разворот ЕМА на младщем ТФ, фиксируем прибыль");// закрываем позицию SELL
           Alert("Закрыли ордер, обнуляем переменные. OrderOpenPrice()-Ask= ",OrderOpenPrice()-Ask, " minProfit ", minProfit*Point);
          }
         } // close получили минимальный профит
        }
       } // Close Открыта короткая позиция SELL
      } // close _MagicNumber от этого Jr_Timeframe
     } // close OrderSelect 
    } // close for
   } // close total > 0

   if( isNewBar(Elder_Timeframe) ) // на каждом новом баре старшего ТФ вычисляем тренд и коррекцию на старшем
   {
    total=OrdersTotal();
    if (useTimeExit)
    {
     if (total > 0 && !isMinProfit)
     {
      barNumber++; // увеличиваем счетчик баров если есть открытые сделки недостигшие минпрофита
      Alert("мин профит еще не был достигнут, сделки есть, увеличивали счетчик barNumber=",barNumber);
      if (barNumber > waitForMove) // если слишком долго ждем движения в нашу сторону
      {
       for (i=0; i<total; i++) // идем по всем сделкам
       {
        if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if (OrderMagicNumber() == _MagicNumber) // выбираем нашу сделку
         {
          ClosePosBySelect(-1, "сделка не ушла в прибыль слишком долгое время");// закрываем позицию
         }
        }
       } 
      }
     }
    }
   
    trendDirection[frameIndex][0] = TwoTitsTrendCriteria(Elder_Timeframe, Elder_MACD_channel, eld_EMA1, eld_EMA2, eldFastMACDPeriod, eldSlowMACDPeriod);
    if (trendDirection[frameIndex][0] > 0) // Есть тренд вверх на старшем таймфрейме
    {
     trendDirection[frameIndex][1] = 1;
    }
    if (trendDirection[frameIndex][0] < 0) // Есть тренд вниз
    {
     trendDirection[frameIndex][1] = -1;
    }
   } // close isNewBar(Elder_Timeframe) 
   //-------------------------------------------------------------------------------------------
   // Флэт
   //------------------------------------------------------------------------------------------- 
   double stochastic0;
   double stochastic1;     
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
    
    stochastic0 = iStochastic(NULL, Elder_Timeframe, Kperiod, Dperiod , slowing ,MODE_SMA,0,MODE_MAIN,1);
    stochastic1 = iStochastic(NULL, Elder_Timeframe, Kperiod, Dperiod , slowing ,MODE_SMA,0,MODE_MAIN,2);
    if (stochastic0 < topStochastic && stochastic1 > topStochastic) // Стохастик наверху, перепокупка - будем продавать
    {
     if (iMA(NULL, Jr_Timeframe, jr_EMA1, 0, 1, 0, 1) < iMA(NULL, Jr_Timeframe, jr_EMA2, 0, 1, 0, 1) && 
         iMA(NULL, Jr_Timeframe, jr_EMA1, 0, 1, 0, 2) > iMA(NULL, Jr_Timeframe, jr_EMA2, 0, 1, 0, 2)) // пересечение ЕМА сверху вниз
     { 
     if (Ask > iMA(NULL, Elder_Timeframe, 3, 0, 1, 0, 0) - deltaPriceToEMA*Point)
     {  
      openPlace = "старший ТФ флэт, стохастик наверху, на младшем пересечение ЕМА сверху вниз ";
      ticket = DesepticonBreakthrough2(-1, Elder_Timeframe);
      if (ticket > 0)
      {
       Alert("открыли сделку, начали отсчет");
	    isMinProfit = false; // сделка длится
	    barNumber = 0;
      }
     }
    } // close пересечение ЕМА сверху вниз   
   }  // close Стохастик наверху       
	 
   if (stochastic0 > bottomStochastic && stochastic1 < bottomStochastic) // Стохастик внизу, перепродажа - будем покупать
   {  			   
    if (iMA(NULL, Jr_Timeframe, jr_EMA1, 0, 1, 0, 1) > iMA(NULL, Jr_Timeframe, jr_EMA2, 0, 1, 0, 1) && 
        iMA(NULL, Jr_Timeframe, jr_EMA1, 0, 1, 0, 2) < iMA(NULL, Jr_Timeframe, jr_EMA2, 0, 1, 0, 2)) // пересечение ЕМА снизу вверх
    {
     if (Bid < iMA(NULL, Elder_Timeframe, 3, 0, 1, 0, 0) + deltaPriceToEMA*Point)
     {   
      openPlace = "старший ТФ флэт, стохастик внизу, на младшем пересечение ЕМА снизу вверх ";
      ticket = DesepticonBreakthrough2(1, Elder_Timeframe);
      if (ticket > 0)
      {
       Alert("открыли сделку, начали отсчет");
	    isMinProfit = false; // сделка длится
	    barNumber = 0;
      }
     }
    } // close пересечение ЕМА снизу вверх
   } // close Стохастик внизу
  } // close Флэт	
 } // close цикл
//----
 if (useTrailing) DesepticonTrailing(NULL, Jr_Timeframe); 
 return(0);
} // close start
//+------------------------------------------------------------------+