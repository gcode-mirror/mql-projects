//+------------------------------------------------------------------+
//|                                              desepticon v004.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, GIA"
#property link      "http://www.saita.net"

#include <BasicVariables.mqh>
#include <DesepticonVariables.mqh>    // Описание переменных
//------- Внешние параметры советника -----------------------------------------+
extern string Expert_Self_Parameters = "Expert_Self_Parameters";
extern int hairLength = 250;

extern int divergenceFastMACDPeriod = 12;
extern int divergenceSlowMACDPeriod = 26;
extern double differencePrice = 10;
extern int depthDiv = 100;
//------- Глобальные переменные советника -------------------------------------+


//------- Подключение внешних модулей -----------------------------------------+
#include <stdlib.mqh>
#include <stderror.mqh>
#include <WinUser32.mqh>
//--------------------------------------------------------------- 3 --
#include <AddOnFuctions.mqh> 
#include <CheckBeforeStart.mqh>       // Проверка входных параметров
#include <DesepticonTrendCriteria.mqh>
//#include <direction_MACD.mqh>
//#include <DesepticonBreakthrough2.mqh>
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

  aTimeframe[1,0] = PERIOD_H1;
  aTimeframe[1,4] = MACD_channel;
  
  aTimeframe[2,0] = PERIOD_M5;
  aTimeframe[2,4] = MACD_channel;
  
  for (frameIndex = startTF; frameIndex <= finishTF; frameIndex++)
  {
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
int start()
{
 for (frameIndex = startTF; frameIndex < finishTF; frameIndex++)
 {
  jr_Timeframe = PERIOD_M5;
  elder_Timeframe = PERIOD_H1;
    
  jr_MACD_channel = aTimeframe[frameIndex + 1, 4];
  elder_MACD_channel = aTimeframe[frameIndex, 4];
  
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
       if (!isMinProfit && Bid-OrderOpenPrice() > minimumProfitLvl*Point) // достигли минимального уровня прибыли
       {
        isMinProfit = true;
        Alert("мин профит на промежутке. Прекращаем отсчет. isMinProfit = ",isMinProfit);
       }
       
       if (useLowTF_EMA_Exit)
       {
        if (Bid-OrderOpenPrice() > minProfit*Point) // получили минимальный профит
        {
         if (iMA(NULL, jr_Timeframe, jr_EMA2, 0, 1, 0, 0) 
                > iMA(NULL, jr_Timeframe, jr_EMA1, 0, 1, 0, 0) + deltaEMAtoEMA*Point) // разворот движения EMA  на младшем ТФ
         {
          ClosePosBySelect(Bid, "получена минимальная прибыль, разворот ЕМА на младщем ТФ, фиксируем прибыль"); // закрываем позицию BUY
          Alert("Закрыли ордер, обнуляем переменные. Bid-OrderOpenPrice()= ",Bid-OrderOpenPrice(), " minProfit ", minProfit*Point);
         }
        } // close получили минимальный профит 
       }
      } // Close открыта длинная позиция BUY
       
      if (OrderType()==OP_SELL) // Открыта короткая позиция SELL
      {
       if (!isMinProfit && OrderOpenPrice()-Ask > minimumProfitLvl*Point) // достигли минимального уровня прибыли
       {
        isMinProfit = true;
        Alert("Sell, мин профит на промежутке. Прекращаем отсчет. isMinProfit = ",isMinProfit);
       }
       
       if (useLowTF_EMA_Exit)
       {
        if (OrderOpenPrice()-Ask > minProfit*Point)
        {
         if (iMA(NULL, jr_Timeframe, jr_EMA2, 0, 1, 0, 0)
                < iMA(NULL, jr_Timeframe, jr_EMA1, 0, 1, 0, 0) - deltaEMAtoEMA*Point) // разворот движения EMA  на младшем ТФ
         {
          ClosePosBySelect(Ask, "получена минимальная прибыль, разворот ЕМА на младщем ТФ, фиксируем прибыль");// закрываем позицию SELL
          Alert("Закрыли ордер, обнуляем переменные. OrderOpenPrice()-Ask= ",OrderOpenPrice()-Ask, " minProfit ", minProfit*Point);
         }
        } // close получили минимальный профит
       }
      } // Close Открыта короткая позиция SELL
     } // close _MagicNumber от этого jr_Timeframe
    } // close OrderSelect 
   } // close for
  } // close total > 0

  if( isNewBar(elder_Timeframe) ) // на каждом новом баре старшего ТФ вычисляем тренд и коррекцию на старшем
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
   
   trendDirection[frameIndex][0] = TwoTitsTrendCriteria(elder_Timeframe, elder_MACD_channel, eld_EMA1, eld_EMA2, eldFastMACDPeriod, eldSlowMACDPeriod);
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
      
   UpdateDivergenceArray(elder_Timeframe); // Обновляем массив экстремумов MACD
   InitExtremums(frameIndex); // обновляем максимумы цены и MACD
   if (wantToOpen[frameIndex][0] == 0) // если еще не хотим открываться
   {   
    wantToOpen[frameIndex][0] = _isDivergence(elder_Timeframe);  // проверяем на расхождение на этом баре       
   } 
//--------------------------
// вычисляем расхождение MACD
//-------------------------- 

  } // close isNewBar(elder_Timeframe)

  //-------------------------------------------------------------------------------------------
  // Флэт
  //-------------------------------------------------------------------------------------------      
  if (trendDirection[frameIndex][0] == 0)    // определяем флэт, потом ищем критерии входа по MACD, открываемся.
  {
   if (Ask > iMA(NULL, elder_Timeframe, 3, 0, 1, PRICE_HIGH, 0) + hairLength*Point)
   {
    trendDirection[frameIndex][0] = 1;
    trendDirection[frameIndex][1] = 1;
    return(0);
   }
   if (Bid < iMA(NULL, elder_Timeframe, 3, 0, 1, PRICE_LOW, 0) - hairLength*Point)
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
    if (Bid < iMA(NULL, elder_Timeframe, 3, 0, 1, 0, 0) + deltaPriceToEMA*Point)
    {
     openPlace = "старший ТФ флэт, " + openPlace;
     ticket = DesepticonOpening(1, elder_Timeframe);
     if (ticket > 0)
     {
      Alert("открыли сделку, начали отсчет");
      for (frameIndex = startTF; frameIndex <= finishTF; frameIndex++)
      {
       wantToOpen[frameIndex][0] = 0;
       wantToOpen[frameIndex][1] = 0;
       barsCountToBreak[frameIndex][0] = 0;
       barsCountToBreak[frameIndex][1] = 0;
      }
	   isMinProfit = false; // сделка длится
	   barNumber = 0;
     }
    }
   } // close нашли расхождение вверх
    
   if (wantToOpen[frameIndex][0] < 0) // нашли расхождение вниз (ждем падение), ждем пробой минимума, будем продавать
   {
    if (Ask > iMA(NULL, elder_Timeframe, 3, 0, 1, 0, 0) - deltaPriceToEMA*Point)
    {
     openPlace = "старший ТФ флэт, " + openPlace;
     ticket = DesepticonOpening(-1, elder_Timeframe);
     if (ticket > 0)
     {
      Alert("открыли сделку, начали отсчет");
      for (frameIndex = startTF; frameIndex <= finishTF; frameIndex++)
      {
       wantToOpen[frameIndex][0] = 0;
       wantToOpen[frameIndex][1] = 0;
       barsCountToBreak[frameIndex][0] = 0;
       barsCountToBreak[frameIndex][1] = 0;
      }
	   isMinProfit = false; // сделка длится
	   barNumber = 0;
     }
    }
   } // close нашли расхождение вниз
//--------------------------
// Расхождение 
//--------------------------
   
  } // close Флэт	
 } // close цикл
//----
 if (useTrailing) DesepticonTrailing(NULL, jr_Timeframe); 
 return(0);
} // close start
//+------------------------------------------------------------------+