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

extern int divergenceFastMACDPeriod = 12;
extern int divergenceSlowMACDPeriod = 26;
extern double differencePrice = 10;
extern int depthDiv = 100;
extern int Kperiod = 5;
extern int Dperiod = 3;
extern int slowing = 3;
extern int topStochastic = 80;
extern int bottomStochastic = 20;


//------- Глобальные переменные советника -------------------------------------+
double aCorrection[3][2]; // [][0] - наличие коррекции, [][1] - значение цены
double Stochastic;
//------- Подключение внешних модулей -----------------------------------------+
#include <stdlib.mqh>
#include <stderror.mqh>
#include <WinUser32.mqh>
//--------------------------------------------------------------- 3 --
#include <AddOnFuctions.mqh> 
#include <CheckBeforeStart.mqh>       // Проверка входных параметров
#include <DesepticonTrendCriteria.mqh>
#include <Correction.mqh>
#include <StochasticDivergenceProcedures.mqh>
//#include <DesepticonBreakthrough2.mqh>
#include <searchForTits.mqh>
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
  ArrayInitialize(aCorrection, 0);
  
  aTimeframe[1,0] = PERIOD_H1;
  aTimeframe[1,4] = MACD_channel;
  
  aTimeframe[2,0] = PERIOD_M5;
  //aTimeframe[2,4] = 0.0001;
  
  for (frameIndex = startTF; frameIndex <= finishTF; frameIndex++)
  {
   InitTrendDirection(aTimeframe[frameIndex, 0], aTimeframe[frameIndex,4]);
   //Alert("проинитили направление тренда");  
   InitDivergenceArray(aTimeframe[frameIndex, 0]);
   //Alert("проинитили массив расхождения MACD");
   InitExtremums(frameIndex);
   //Alert("проинитили экстремумы MACD");
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
  if (iMA(NULL, jr_Timeframe, jr_EMA1, 0, 1, 0, 1) > iMA(NULL, jr_Timeframe, jr_EMA2, 0, 1, 0, 1) && 
      iMA(NULL, jr_Timeframe, jr_EMA1, 0, 1, 0, 2) < iMA(NULL, jr_Timeframe, jr_EMA2, 0, 1, 0, 2)) // пересечение ЕМА снизу вверх
  {
	if (Bid < iMA(NULL, elder_Timeframe, 3, 0, 1, 0, 0) + deltaPriceToEMA*Point)
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
  if (iMA(NULL, jr_Timeframe, jr_EMA1, 0, 1, 0, 1) < iMA(NULL, jr_Timeframe, jr_EMA2, 0, 1, 0, 1) && 
      iMA(NULL, jr_Timeframe, jr_EMA1, 0, 1, 0, 2) > iMA(NULL, jr_Timeframe, jr_EMA2, 0, 1, 0, 2)) // пересечение ЕМА сверху вниз
  {
	if (Ask > iMA(NULL, elder_Timeframe, 3, 0, 1, 0, 0) - deltaPriceToEMA*Point)
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
 if (_isTradeAllow)
 {
  jr_Timeframe = PERIOD_M5;
  elder_Timeframe = PERIOD_H1;
    
  jr_MACD_channel = aTimeframe[frameIndex + 1, 4];
  elder_MACD_channel = aTimeframe[frameIndex, 4];
    
  if (!CheckBeforeStart())   // проверяем входные параметры
  {
   PlaySound("alert2.wav");
   _isTradeAllow = false;
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
          Alert("Закрыли ордер, обнуляем переменные. Bid-OrderOpenPrice()= ",Bid-OrderOpenPrice(), " MinProfit ", minProfit*Point);
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
          Alert("Закрыли ордер, обнуляем переменные. OrderOpenPrice()-Ask= ",OrderOpenPrice()-Ask, " MinProfit ", minProfit*Point);
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
         if (OrderType()==OP_SELL || OrderType()==OP_BUY) // Открыта короткая позиция SELL
         {
          ClosePosBySelect(-1, "сделка не ушла в прибыль слишком долгое время");// закрываем позицию
         }
        }
       }
      } 
     }
    }
   }
   
   trendDirection[frameIndex][0] = TwoTitsTrendCriteria(elder_Timeframe, elder_MACD_channel, eld_EMA1, eld_EMA2, eldFastMACDPeriod, eldSlowMACDPeriod);
   
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
   UpdateDivergenceArray(elder_Timeframe); // Обновляем массив экстремумов MACD
   InitExtremums(frameIndex); // обновляем максимумы цены и MACD
   if (wantToOpen[frameIndex][0] == 0) // если еще не хотим открываться
   {   
    wantToOpen[frameIndex][0] = _isDivergence(elder_Timeframe);  // проверяем на расхождение на этом баре       
   } 
 //--------------------------
 // вычисляем расхождение MACD на младшем
 //--------------------------     
   UpdateDivergenceArray(jr_Timeframe); // Обновляем массив экстремумов MACD
   InitExtremums(frameIndex + 1); // обновляем максимумы цены и MACD
   if (wantToOpen[frameIndex + 1][0] == 0) // если еще не хотим открываться
   {   
    wantToOpen[frameIndex + 1][0] = _isDivergence(jr_Timeframe);  // проверяем на расхождение на этом баре       
   } 
 //--------------------------
 // вычисляем расхождение Stochastic на старшем
 //--------------------------    
   InitStoDivergenceArray(elder_Timeframe); 
   if (wantToOpen[frameIndex][1] == 0) // если еще не хотим открываться
   {   
    wantToOpen[frameIndex][1] = isStoDivergence(elder_Timeframe);  // проверяем на расхождение на этом баре    
   }
 //--------------------------
 // вычисляем расхождение Stochastic на младшем
 //--------------------------    
   InitStoDivergenceArray(jr_Timeframe); 
   if (wantToOpen[frameIndex + 1][1] == 0) // если еще не хотим открываться
   {   
    wantToOpen[frameIndex + 1][1] = isStoDivergence(jr_Timeframe);  // проверяем на расхождение на этом баре    
   }
  } // close isNewBar
    
 //--------------------------------------
 // временная заглушка для отказа от торговли при флэте на младшем ТФ
 //--------------------------------------
  if( isNewBar(jr_Timeframe) ) // на каждом новом баре младшего ТФ вычисляем тренд на младшем
  {
   trendDirection[frameIndex + 1][0] = TwoTitsTrendCriteria(jr_Timeframe, jr_MACD_channel, jr_EMA1, jr_EMA2, jrFastMACDPeriod, jrSlowMACDPeriod);
   Alert("trendDirection=",trendDirection[frameIndex + 1][0]);
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
    Alert("Есть тренд вверх на младшем таймфрейме");
    trendDirection[frameIndex + 1][1] = 1;
   } 
   if (trendDirection[frameIndex + 1][0] < 0) // Есть тренд вниз на младшем таймфрейме
   {
    Alert("Есть тренд вниз на младшем таймфрейме");
    trendDirection[frameIndex + 1][1] = -1;
   }
  } // close  isNewBar(jr_Timeframe)
  if (trendDirection[frameIndex + 1][0] == 0) // если на младшем флэт не торгуем
  {
   //Alert("торговать все равно не будем");
   return(0); // торговать все равно не будем
  }
 //--------------------------------------
 // временная заглушка для отказа от торговли при флэте на младшем ТФ
 //--------------------------------------     
     
  Stochastic = iStochastic(NULL, elder_Timeframe, Kperiod, Dperiod , slowing ,MODE_SMA,0,MODE_MAIN,1);
  buyCondition = CheckBuyCondition();
  sellCondition = CheckSellCondition();
   
  //-------------------------------------------------------------------------------------------
  // Большой тренд вверх
  //-------------------------------------------------------------------------------------------
  if (trendDirection[frameIndex][0] > 0) // Есть тренд вверх на старшем таймфрейме
  {
   trendDirection[frameIndex][1] = 1;
   if (aCorrection[frameIndex][0] < 0) // коррекция вниз
   {
    if (buyCondition > sellCondition)
    {
     ticket = DesepticonOpening(1, elder_Timeframe);
     if (ticket > 0)
     {
      OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES); 
      ticket = OrderTicket();
      Alert("открыли сделку, обнуляем переменные, начали отсчет.");
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
     openPlace = "";
    }
    if (sellCondition > buyCondition)
    {
     ticket = DesepticonOpening(-1, elder_Timeframe);
     if (ticket > 0)
     {
      OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES); 
      ticket = OrderTicket();
      Alert("открыли сделку, обнуляем переменные, начали отсчет.");
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
     ticket = DesepticonOpening(1, elder_Timeframe);
     if (ticket > 0)
     {
      OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES); 
      ticket = OrderTicket();
      Alert("открыли сделку, начали отсчет. ticket=",ticket," OrderExpiration = ", TimeToStr(OrderExpiration(), TIME_DATE),":",TimeToStr(OrderExpiration(), TIME_MINUTES));
      isMinProfit = false; // сделка длится
      barNumber = 0;
     }
     openPlace = "";
    }
    if (sellCondition > buyCondition)
    {
     ticket = DesepticonOpening(-1, elder_Timeframe);
     if (ticket > 0)
     {
      OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES); 
      ticket = OrderTicket();
      Alert("открыли сделку, начали отсчет. ticket=",ticket," OrderExpiration = ", TimeToStr(OrderExpiration(), TIME_DATE),":",TimeToStr(OrderExpiration(), TIME_MINUTES));
      isMinProfit = false; // сделка длится
      barNumber = 0;
     }
     openPlace = "";
    }
   } // close коррекция вверх 
  }
//}
//----
  if (useTrailing) DesepticonTrailing(NULL, jr_Timeframe);
  return(0);
 } // close isTradeAllow
}
//+------------------------------------------------------------------+


