//+------------------------------------------------------------------+
//|                                                _isDivergence.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, GIA"
#property link      "http://www.saita.net"

int _isDivergence(int timeframe)
{
 int index;
 switch(timeframe)
 {
  case PERIOD_D1:
      index = 0;
      break;
  case PERIOD_H1:
      index = 1;
      break;
  case PERIOD_M5:
      index = 2;
      break;
  default:
      Alert("_isDivergence: Вы ошиблись с таймфреймом");
      return(false);
 }
 
 int qnt = aDivergence[index][0][0];
 int i;
 int ExtremumMACD = isMACDExtremum(timeframe, divergenceFastMACDPeriod, divergenceSlowMACDPeriod);
 
 /*
 // Номер бара с максимальной ценой на ВСЕМ отрезке
 int maxPriceBarNumber = iHighest(NULL, aTimeframe[index,0], MODE_HIGH, depthDiv, 0);
 // Номер бара с минимальной ценой на ВСЕМ отрезке 
 int minPriceBarNumber = iLowest(NULL, aTimeframe[index,0], MODE_LOW, depthDiv, 0);
 
 // Номер бара с максимальной ценой на ОСТАВШЕМСЯ отрезке
 maxPriceBarNumber 
         = iHighest(NULL, aTimeframe[index,0], MODE_HIGH, depthDiv - maxPriceBarNumber, maxPriceBarNumber + 1);
 // Номер бара с минимальной ценой на ОСТАВШЕМСЯ отрезке
 minPriceBarNumber
          = iLowest(NULL, aTimeframe[index,0], MODE_LOW, depthDiv - minPriceBarNumber, minPriceBarNumber + 1);
 */

 // Номер бара с максимальной ценой на 15-100 барах
 int maxPriceBarNumber 
         = iHighest(NULL, timeframe, MODE_HIGH, depthDiv - 8, 9);
 // Номер бара с минимальной ценой на 15-100 последних барах
 int minPriceBarNumber
          = iLowest(NULL, timeframe, MODE_LOW, depthDiv - 8, 9);

 double maxPrice = 
      iHigh(NULL, timeframe, maxPriceBarNumber); // считаем максимальную цену на 15-100 последних барах
 double minPrice = 
      iLow(NULL, timeframe, minPriceBarNumber); // считаем минимальную цену на 15-100 последних барах

 if (maxPriceForDiv[index][0] > maxPrice) // на последних 15-ти барах цена выше максимума на 15-100
 {
  //Alert("на последних 15-ти барах цена выше максимума на 15-100, номер бара ", maxPriceForDiv[index][1]);
  if (ExtremumMACD > 0) // Дождались очередного максимума MACD
  {
   //Alert("Дождались очередного максимума MACD ", aDivergence[index][1][3]);
   if (maxMACD[index][0] > aDivergence[index][1][1]) // Последний максимум MACD меньше(ближе к нулю) глобального максимума
   {
    i = 2;
    while (aDivergence[index][i][3] < maxMACD[index][1]) // Идем по всем экстремумам, сравниваем номера баров с номером глобального максимума
    {
     if (aDivergence[index][i][4] < 0) // Есть отрицательный MACD между положительными
     {
      /*
      Alert (" Расхождение вверху: отрицательный экстремум  ", aDivergence[index][i][1]
      , " номер бара " , aDivergence[index][i][3],  " время "
      , TimeDay(iTime(NULL, timeframe, aDivergence[index][i][3])),":"
      , TimeHour(iTime(NULL, timeframe, aDivergence[index][i][3])),":"
      , TimeMinute(iTime(NULL, timeframe, aDivergence[index][i][3])));
      
      Alert(" время глобального максимума MACD " , maxMACD[index][0], " "
      , TimeDay(iTime(NULL, timeframe, maxMACD[index][1])),":"
      , TimeHour(iTime(NULL, timeframe, maxMACD[index][1])),":"
      , TimeMinute(iTime(NULL, timeframe, maxMACD[index][1])));
      
      Alert(" глобальный(предыдущий) максимум цены " , maxPrice, " "
      , " Номер бара с максимальной ценой на ОСТАВШЕМСЯ отрезке ", maxPriceBarNumber);
      
      Alert(" последний экстремум MACD ", aDivergence[index][1][1]
      , " номер бара " , aDivergence[index][1][3],  " время "
      , TimeDay(iTime(NULL, timeframe, aDivergence[index][1][3])),":"
      , TimeHour(iTime(NULL, timeframe, aDivergence[index][1][3])),":"
      , TimeMinute(iTime(NULL, timeframe, aDivergence[index][1][3])));
      
      Alert(" последний максимум цены " , maxPriceForDiv[index][0], " ");
      */
      openPlace = "расхождение на " + timeframe + "-минутном ТФ на MACD вниз ";
      barsCountToBreak[index][0] = 0;
      //Alert("trendDirection[",index,"][0]",trendDirection[index][0]);
      return(-1); // Расхождение вверху, ждем падение, расхождение вниз (медвежье)
     } 
     i++;
    } // close while
   } // 
   //waitForMACDMaximum[index] = false;
  } // close Дождались очередного максимума MACD
 }
 
 if (minPriceForDiv[index][0] < minPrice) // на последних 10-ти барах цена ниже минимума на 10-100
 {
  if (ExtremumMACD < 0) // Дождались очередного минимума MACD
  {
   if (minMACD[index][0] < aDivergence[index][1][1]) // Последний минимум MACD больше(ближе к нулю) глобального минимума
   {
    i = 2;
    while (aDivergence[index][i][3] < minMACD[index][1])// Идем по всем экстремумам, сравниваем номера баров с номером глобального минимума
    {
     if (aDivergence[index][i][4] > 0) // Есть положительный MACD между отрицательными
     {
      /*
      Alert (" Расхождение внизу: положительный экстремум,  ", aDivergence[index][i][1]
      , " номер бара " , aDivergence[index][i][3], " время "
      , TimeDay(iTime(NULL, timeframe, aDivergence[index][i][3])),":"
      , TimeHour(iTime(NULL, timeframe, aDivergence[index][i][3])),":"
      , TimeMinute(iTime(NULL, timeframe, aDivergence[index][i][3])));
      
      Alert ( " время глобального минимума ", minMACD[index][0], " "
      , TimeDay(iTime(NULL, timeframe, minMACD[index][1])),":"
      , TimeHour(iTime(NULL, timeframe, minMACD[index][1])),":"
      , TimeMinute(iTime(NULL, timeframe, minMACD[index][1])));
      
      Alert(" глобальный(предыдущий) минимум цены " , minPrice, " "
      , " Номер бара с минимальной ценой на ОСТАВШЕМСЯ отрезке ", minPriceBarNumber);
      
      Alert ( " последний экстремум MACD ", aDivergence[index][1][1]
      , " номер бара ", aDivergence[index][1][3],  " время "
      , TimeDay(iTime(NULL, timeframe, aDivergence[index][1][3])),":"
      , TimeHour(iTime(NULL, timeframe, aDivergence[index][1][3])),":"
      , TimeMinute(iTime(NULL, timeframe, aDivergence[index][1][3])));
      
      Alert(" последний минимум цены " , minPriceForDiv[index][0], " ");
      */
      openPlace = "расхождение на " + timeframe + "-минутном ТФ на MACD вверх ";
      barsCountToBreak[index][0] = 0;
      return(1); // Расхождение внизу, ждем рост, расхождение вверх (бычье)
     } 
     i++;
    } // close while 
   } 
   //waitForMACDMinimum[index] = false;
  } // close Дождались очередного минимума MACD
 }
 
 return(0);
}