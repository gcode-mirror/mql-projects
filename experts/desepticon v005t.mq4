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
#include <AddOnFuctions.mqh> 
//#include <InitDivergenceArray.mqh>
//#include <InitExtremums.mqh>
#include <CheckBeforeStart.mqh>       // Проверка входных параметров
#include <DesepticonTrendCriteria.mqh>
#include <Correction.mqh>
//#include <direction_MACD.mqh>
#include <DesepticonBreakthrough2.mqh>
#include <searchForTits.mqh>
//#include <DesepticonDivergence.mqh>
#include <GetLastOrderHist.mqh>
#include <GetLots.mqh>     // На какое количество лотов открываемся
#include <isNewBar.mqh>
//#include <UpdateDivergenceArray.mqh>
#include <isMACDExtremum.mqh>
//#include <isDivergence.mqh>
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
   trendDirection[frameIndex][0] =  InitTrendDirection(aTimeframe[frameIndex, 0], aTimeframe[frameIndex,4]);
   //Alert("trendDirection[0]=",trendDirection[frameIndex][0], " frameIndex=",frameIndex);
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
     
     if (!CheckBeforeStart())   // проверяем входные параметры
     {
      PlaySound("alert2.wav");
      return (0); 
     }
     
     total=OrdersTotal();
     
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
       if (Bid-OrderOpenPrice() > MinProfit*Point) // получили минимальный профит
       {
        if (iMA(NULL, Jr_Timeframe, jr_EMA2, 0, 1, 0, 0) > iMA(NULL, Jr_Timeframe, jr_EMA1, 0, 1, 0, 0) + deltaEMAtoEMA*Point)
        {
         OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet); // закрываем позицию BUY
         Alert("Закрыли ордер, обнуляем переменные. Bid-OrderOpenPrice()= ",Bid-OrderOpenPrice(), " MinProfit ", MinProfit*Point);
        }
       } // close получили минимальный профит 
      } // Close открыта длинная позиция BUY
       
      if (OrderType()==OP_SELL) // Открыта короткая позиция SELL
      {
       if (OrderOpenPrice()-Ask > MinProfit*Point)
       {
        if (iMA(NULL, Jr_Timeframe, jr_EMA2, 0, 1, 0, 0) < iMA(NULL, Jr_Timeframe, jr_EMA1, 0, 1, 0, 0) - deltaEMAtoEMA*Point)
        {
         OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet); // закрываем позицию SELL
         Alert("Закрыли ордер, обнуляем переменные. OrderOpenPrice()-Ask= ",OrderOpenPrice()-Ask, " MinProfit ", MinProfit*Point);
        }
       } // close получили минимальный профит
      } // Close Открыта короткая позиция SELL
     } // close _MagicNumber от этого Jr_Timeframe
    } // close OrderSelect 
   } // close for
  } // close total > 0

     if( isNewBar(Elder_Timeframe) ) // на каждом новом баре старшего ТФ вычисляем тренд и коррекцию на старшем
     {
      trendDirection[frameIndex][0] = TwoTitsTrendCriteria(Elder_Timeframe, Elder_MACD_channel, eld_EMA1, eld_EMA2, eldFastMACDPeriod, eldSlowMACDPeriod);
      if (aCorrection[frameIndex][0] > 0) // коррекция вверх
      {
       if (trendDirection[frameIndex][0] > 0 || Bid < aCorrection[frameIndex][1]) // тренд вверх
       {
        ArrayInitialize(aCorrection, 0); // конец коррекции вверх
       }
      } // close коррекция вверх
      else if (aCorrection[frameIndex][0] < 0) // коррекция вниз
           {
            if (trendDirection[frameIndex][0] < 0 || Ask > aCorrection[frameIndex][1]) // тренд вниз
            {
             ArrayInitialize(aCorrection, 0); // конец коррекции вниз
            }
           } // close коррекция вниз
           else  // нет коррекции
           {
            Correction(); // проверим не началась ли коррекция
           }
      //Alert("aCorrection[0]=",aCorrection[frameIndex][0], "trendDirection[0]=",trendDirection[frameIndex][0]);      
     } // close isNewBar
     
  //--------------------------------------
  // временная заглушка для отказа от торговли при флэте на младшем ТФ
  //--------------------------------------
     if( isNewBar(Jr_Timeframe) ) // на каждом новом баре младшего ТФ вычисляем тренд на младшем
     {
      trendDirection[frameIndex + 1][0] = TwoTitsTrendCriteria(Jr_Timeframe, Jr_MACD_channel, jr_EMA1, jr_EMA2, jrFastMACDPeriod, jrSlowMACDPeriod);
      if (trendDirection[frameIndex + 1][0] > 0) // Есть тренд вверх на старшем таймфрейме
      { 
       trendDirection[frameIndex + 1][1] = 1;
      } 
      if (trendDirection[frameIndex + 1][0] < 0) // Есть тренд вверх на старшем таймфрейме
      {
       trendDirection[frameIndex + 1][1] = -1;
      }
     } // close  isNewBar(Jr_Timeframe)
     if (trendDirection[frameIndex + 1][0] == 0) // если на младшем флэт не торгуем
     {
      //Alert("флэт на младшем");
      continue; // торговать все равно не будем
     }
  //--------------------------------------
  // временная заглушка для отказа от торговли при флэте на младшем ТФ
  //--------------------------------------
           
     //-------------------------------------------------------------------------------------------
     // Большой тренд вверх
     //-------------------------------------------------------------------------------------------
     if (trendDirection[frameIndex][0] > 0) // Есть тренд вверх на старшем таймфрейме
     {
      trendDirection[frameIndex][1] = 1;
   
      if (aCorrection[frameIndex][0] >= 0) // нет коррекции вниз
      {
       if (Bid < iMA(NULL, PERIOD_D1, 3, 0, 1, 0, 0) + deltaPriceToEMA*Point) // на дневнике цена ниже или не сильно выше ЕМА3 
       {
        if (iLow(NULL, Elder_Timeframe, 1) < iMA(NULL, Elder_Timeframe, eld_EMA1, 0, 1, 0, 1) + deltaPriceToEMA*Point ||
            Bid < iMA(NULL, Elder_Timeframe, eld_EMA1, 0, 1, 0, 0) + deltaPriceToEMA*Point) // на последних 2-х барах есть цена ниже быстрого ЕМА       
        {
         if (iMA(NULL, Jr_Timeframe, jr_EMA1, 0, 1, 0, 1) > iMA(NULL, Jr_Timeframe, jr_EMA2, 0, 1, 0, 1) && 
             iMA(NULL, Jr_Timeframe, jr_EMA1, 0, 1, 0, 2) < iMA(NULL, Jr_Timeframe, jr_EMA2, 0, 1, 0, 2)) // пересечение ЕМА снизу вверх
         {
          openPlace = "старший тренд вверх, на младшем пересечение ЕМА снизу вверх ";
          if (DesepticonBreakthrough2(1, Jr_Timeframe) <= 0) // 
          {
	         // сделать проверку при неоткрытии
	       }
         } // close пересечение ЕМА снизу вверх
        } // close на последних 2-х барах есть цена ниже быстрого ЕМА 
       } // close на дневнике цена ниже или не сильно выше ЕМА3
      } // close нет коррекции вниз
     }

     //-------------------------------------------------------------------------------------------
     // Большой тренд вниз
     //-------------------------------------------------------------------------------------------     
     if (trendDirection[frameIndex][0] < 0) // Есть тренд вниз
     {
      trendDirection[frameIndex][1] = -1;

      if (aCorrection[frameIndex][0] <= 0) // нет коррекции вверх
      {
       if (Ask > iMA(NULL, PERIOD_D1, 3, 0, 1, 0, 0) - deltaPriceToEMA*Point) // на дневнике цена выше или не сильно ниже ЕМА3
       {
        if (iHigh(NULL, Elder_Timeframe, 1) > iMA(NULL, Elder_Timeframe, eld_EMA1, 0, 1, 0, 1) - deltaPriceToEMA*Point ||
            Ask > iMA(NULL, Elder_Timeframe, eld_EMA1, 0, 1, 0, 0) - deltaPriceToEMA*Point) // на последних 2-х барах есть цена выше быстрого ЕМА
        {
         if (iMA(NULL, Jr_Timeframe, jr_EMA1, 0, 1, 0, 1) < iMA(NULL, Jr_Timeframe, jr_EMA2, 0, 1, 0, 1) && 
             iMA(NULL, Jr_Timeframe, jr_EMA1, 0, 1, 0, 2) > iMA(NULL, Jr_Timeframe, jr_EMA2, 0, 1, 0, 2)) // пересечение ЕМА сверху вниз
         {
          openPlace = "старший тренд вниз, на младшем пересечение ЕМА сверху вниз Ask=" + Ask + "  EMA="+ (iMA(NULL, PERIOD_D1, 3, 0, 1, 0, 0) - deltaPriceToEMA*Point);
          if (DesepticonBreakthrough2(-1, Jr_Timeframe) <= 0) // 
          {
           // сделать проверку при неоткрытии 
          }
         } // close пересечение ЕМА сверху вниз
        } // close на последних 2-х барах есть цена выше быстрого ЕМА 
       } // close на дневнике цена выше или не сильно ниже ЕМА3
      } // close else коррекция вверх 
     }
    } // close цикл
//----
	if (UseTrailing) DesepticonTrailing(NULL, Jr_Timeframe); 
	return(0);
} // close start
//+------------------------------------------------------------------+