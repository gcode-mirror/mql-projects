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
#include <Correction.mqh>
#include <StochasticDivergenceProcedures.mqh>
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
   InitTrendDirection(aTimeframe[frameIndex, 0], aTimeframe[frameIndex,4]);
   //Alert("проинитили направление тренда");  
   InitDivergenceArray(aTimeframe[frameIndex, 0]);
   //Alert("проинитили массив расхождения MACD");
   InitExtremums(frameIndex);
   //Alert("проинитили экстремумы MACD");
   
   // инициализируем расхождение Stochastic
   InitStoDivergenceArray(aTimeframe[frameIndex, 0]);
   //Alert("проинитили расхождение Stochastic");
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
//| Check for buy conditions function                                |
//+------------------------------------------------------------------+
int CheckBuyCondition()
{
 if (wantToOpen[frameIndex][0] > 0) // нашли расхождение на старшем MACD вверх (ждем рост)
 { 
  openPlace = openPlace + " расхождение на старшем MACD вверх";
  return(100);
 }
 if (wantToOpen[frameIndex][1] > 0) // нашли расхождение на старшем стохастике вверх (ждем рост)
 {    
  openPlace = openPlace + " расхождение на старшем стохастике вверх";
  return(100);
 }
 if (wantToOpen[frameIndex + 1][0] > 0) // нашли расхождение на младшем MACD вверх (ждем рост)
 {    
  openPlace = openPlace + " расхождение на младшем MACD вверх";
  return(50);
 }
 if (wantToOpen[frameIndex + 1][1] > 0) // нашли расхождение на младшем стохастике вверх (ждем рост)
 {   
  openPlace = openPlace + " расхождение на младшем стохастике вверх"; 
  return(50);
 }
 
 if (Stochastic < bottomStochastic) // Стохастик внизу, перепродажа - будем покупать
 {  			   
  if (iMA(NULL, Jr_Timeframe, jr_EMA1, 0, 1, 0, 1) > iMA(NULL, Jr_Timeframe, jr_EMA2, 0, 1, 0, 1) && 
      iMA(NULL, Jr_Timeframe, jr_EMA1, 0, 1, 0, 2) < iMA(NULL, Jr_Timeframe, jr_EMA2, 0, 1, 0, 2)) // пересечение ЕМА снизу вверх
  {
	if (Bid < iMA(NULL, Elder_Timeframe, 3, 0, 1, 0, 0) + deltaPriceToEMA*Point)
	{
	 openPlace = " стохастик внизу, на младшем пересечение ЕМА снизу вверх ";
	 return(100);
	}
  }
 }
 return(0); 
}

//+------------------------------------------------------------------+
//| Check for sell conditions function                               |
//+------------------------------------------------------------------+
int CheckSellCondition()
{
 if (wantToOpen[frameIndex][0] < 0) // нашли расхождение на старшем MACD вниз (ждем падение)
 {    
  openPlace = openPlace + " расхождение на старшем MACD вниз";
  return(100);
 }
 if (wantToOpen[frameIndex][1] < 0) // нашли расхождение на старшем стохастике вниз (ждем падение)
 {  
  openPlace = openPlace + " расхождение на старшем стохастике вниз";
  return(100);
 }
 if (wantToOpen[frameIndex + 1][0] < 0) // нашли расхождение на младшем MACD вниз (ждем падение)
 { 
  openPlace = openPlace + " расхождение на младшем MACD вниз"; 
  return(50);
 }
 if (wantToOpen[frameIndex + 1][1] < 0) // нашли расхождение на младшем стохастике вниз (ждем падение)
 {   
  openPlace = openPlace + " расхождение на младшем стохастике вниз"; 
  return(50);
 }
 
 if (Stochastic > topStochastic) // Стохастик внизу, перепродажа - будем покупать
 {  			   
  if (iMA(NULL, Jr_Timeframe, jr_EMA1, 0, 1, 0, 1) < iMA(NULL, Jr_Timeframe, jr_EMA2, 0, 1, 0, 1) && 
      iMA(NULL, Jr_Timeframe, jr_EMA1, 0, 1, 0, 2) > iMA(NULL, Jr_Timeframe, jr_EMA2, 0, 1, 0, 2)) // пересечение ЕМА сверху вниз
  {
	if (Ask > iMA(NULL, Elder_Timeframe, 3, 0, 1, 0, 0) - deltaPriceToEMA*Point)
	{
	 openPlace = " стохастик вверху, на младшем пересечение ЕМА сверху вниз ";
	 return(100);
	}
  }
 }
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
  
     if( isNewBar(Elder_Timeframe) ) // на каждом новом баре старшего ТФ вычисляем тренд и коррекцию на старшем
     {
      //Alert("openPlace=",openPlace);
      //Alert(" wantToOpen[0]=",wantToOpen[frameIndex][0], "  wantToOpen[1]=",wantToOpen[frameIndex][1]);
      //Alert(" wantToOpen[0]=",wantToOpen[frameIndex+1][0], "  wantToOpen[1]=",wantToOpen[frameIndex+1][1]);
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
      
      if (wantToOpen[frameIndex][1] != 0) // если хотели открываться по расхождению Stochastic
      {
       barsCountToBreak[frameIndex][1]++;
       if (barsCountToBreak[frameIndex][1] > breakForStochastic)
       { 
        barsCountToBreak[frameIndex][1] = 0; // дальше 2х баров забываем, что хотели открываться
        wantToOpen[frameIndex][1] = 0;
       }
      }
      
  //--------------------------
  // вычисляем расхождение MACD на старшем
  //--------------------------     
      UpdateDivergenceArray(Elder_Timeframe); // Обновляем массив экстремумов MACD
      InitExtremums(frameIndex); // обновляем максимумы цены и MACD
      if (wantToOpen[frameIndex][0] == 0) // если еще не хотим открываться
      {   
       wantToOpen[frameIndex][0] = _isDivergence(Elder_Timeframe);  // проверяем на расхождение на этом баре       
      } 

  //--------------------------
  // вычисляем расхождение MACD на младшем
  //--------------------------     
      UpdateDivergenceArray(Jr_Timeframe); // Обновляем массив экстремумов MACD
      InitExtremums(frameIndex + 1); // обновляем максимумы цены и MACD
      if (wantToOpen[frameIndex + 1][0] == 0) // если еще не хотим открываться
      {   
       wantToOpen[frameIndex + 1][0] = _isDivergence(Jr_Timeframe);  // проверяем на расхождение на этом баре       
      } 

  //--------------------------
  // вычисляем расхождение Stochastic на старшем
  //--------------------------    
      InitStoDivergenceArray(Elder_Timeframe); 
      if (wantToOpen[frameIndex][1] == 0) // если еще не хотим открываться
      {   
       wantToOpen[frameIndex][1] = isStoDivergence(Elder_Timeframe);  // проверяем на расхождение на этом баре    
      }

  //--------------------------
  // вычисляем расхождение Stochastic на младшем
  //--------------------------    
      InitStoDivergenceArray(Jr_Timeframe); 
      if (wantToOpen[frameIndex + 1][1] == 0) // если еще не хотим открываться
      {   
       wantToOpen[frameIndex + 1][1] = isStoDivergence(Jr_Timeframe);  // проверяем на расхождение на этом баре    
      }
     } // close isNewBar
     
  //--------------------------------------
  // временная заглушка для отказа от торговли при флэте на младшем ТФ
  //--------------------------------------
     if( isNewBar(Jr_Timeframe) ) // на каждом новом баре младшего ТФ вычисляем тренд на младшем
     {
      trendDirection[frameIndex + 1][0] = TwoTitsTrendCriteria(Jr_Timeframe, Jr_MACD_channel, jr_EMA1, jr_EMA2, jrFastMACDPeriod, jrSlowMACDPeriod);
      
  //--------------------------
  // проверяемм что все еще хотим открываться
  //--------------------------     
      if (wantToOpen[frameIndex + 1][0] != 0) // если хотели открываться по расхождению MACD
      {
       barsCountToBreak[frameIndex + 1][0]++;
       if (barsCountToBreak[frameIndex + 1][0] > breakForMACD)
       { 
        barsCountToBreak[frameIndex + 1][0] = 0; // дальше 4х баров забываем, что хотели открываться
        wantToOpen[frameIndex + 1][0] = 0;
       }
      }
      
      if (wantToOpen[frameIndex + 1][1] != 0) // если хотели открываться по расхождению Stochastic
      {
       barsCountToBreak[frameIndex + 1][1]++;
       if (barsCountToBreak[frameIndex + 1][1] > breakForStochastic)
       { 
        barsCountToBreak[frameIndex + 1][1] = 0; // дальше 2х баров забываем, что хотели открываться
        wantToOpen[frameIndex + 1][1] = 0;
       }
      }
      
  //--------------------------
  // запоминаем текущий тренд
  //-------------------------- 
      if (trendDirection[frameIndex + 1][0] > 0) // Есть тренд вверх на младшем таймфрейме
      { 
       trendDirection[frameIndex + 1][1] = 1;
      } 
      if (trendDirection[frameIndex + 1][0] < 0) // Есть тренд вверх на младшем таймфрейме
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
     
     Stochastic = iStochastic(NULL, Elder_Timeframe, Kperiod, Dperiod , slowing ,MODE_SMA,0,MODE_MAIN,1);
     buyCondition = CheckBuyCondition();
     sellCondition = CheckSellCondition();
     
     //-------------------------------------------------------------------------------------------
     // Большой тренд вверх
     //-------------------------------------------------------------------------------------------
     if (trendDirection[frameIndex][0] > 0) // Есть тренд вверх на старшем таймфрейме
     {
      trendDirection[frameIndex][1] = 1;
      //Alert("старший тренд вверх");
      if (aCorrection[frameIndex][0] < 0) // коррекция вниз
      {
       if (buyCondition > sellCondition)
       {
        //Alert("buyCondition коррекция вниз");
        //openPlace = "коррекция на старшем против тренда вверх, " + openPlace;
        if (DesepticonBreakthrough2(1, Jr_Timeframe) <= 0)
	     {
	       // вставить обработчик ошибки открытия сделки 
	     }
	     openPlace = "";
       }
       if (sellCondition > buyCondition)
       {
        //Alert("sellCondition коррекция вниз");
        //openPlace = "коррекция на старшем против тренда вверх, " + openPlace;
        if (DesepticonBreakthrough2(-1, Jr_Timeframe) <= 0)
	     {
	       // вставить обработчик ошибки открытия сделки 
	     }
	     openPlace = "";
       }
      } // close коррекция вниз
     }

     //-------------------------------------------------------------------------------------------
     // Большой тренд вниз
     //-------------------------------------------------------------------------------------------     
     if (trendDirection[frameIndex][0] < 0) // Есть тренд вниз
     {
      trendDirection[frameIndex][1] = -1;

      if (aCorrection[frameIndex][0] > 0) // коррекция вверх
      {
       if (buyCondition > sellCondition)
       {
        //Alert("buyCondition коррекция вверх" );
        //openPlace = "коррекция на старшем против тренда вниз, " + openPlace;
        if (DesepticonBreakthrough2(1, Jr_Timeframe) <= 0)
	     {
	       // вставить обработчик ошибки открытия сделки 
	     }
	     openPlace = "";
       }
       if (sellCondition > buyCondition)
       {
        //Alert("sellCondition коррекция вверх");
        //openPlace = "коррекция на старшем против тренда вниз, " + openPlace;
        if (DesepticonBreakthrough2(-1, Jr_Timeframe) <= 0)
	     {
	       // вставить обработчик ошибки открытия сделки 
	     }
	     openPlace = "";
       }
      } // close коррекция вверх 
     }
    } // close цикл
//}
//----
	if (UseTrailing) DesepticonTrailing(NULL, Jr_Timeframe);
	return(0);
}
//+------------------------------------------------------------------+


