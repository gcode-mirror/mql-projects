//+------------------------------------------------------------------+
//|                                                 isDivergence.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, GIA"
#property link      "http://www.saita.net"

int isDivergence()
{
 int qnt = aDivergence[frameIndex][0][0];
 int i;
 int ExtremumMACD = isMACDExtremum(Jr_Timeframe, jrFastMACDPeriod, jrSlowMACDPeriod, 0);
 
 if (waitForMACDMaximum[frameIndex]) 
 {
  //Alert (" Ждем максимума MACD ");
  if (ExtremumMACD > 0) // Дождались очередного максимума MACD
  {
   //Alert (" Дождались очередного максимума MACD ", ExtremumMACD);
   if (maxMACD[frameIndex][0] > aDivergence[frameIndex][1][1]) // Значение последнего максимума MACD меньше глобального максимума
   {
    //for (i=2; i<aDivergence[0][0]; i++)
    i = 2;
    while (aDivergence[frameIndex][i][3] < maxMACD[frameIndex][1]) // Идем по всем экстремумам, сравниваем номера баров с номером глобального максимума
    {
     //Alert (" Ищем отрицательный экстремум ", aDivergence[frameIndex][i][3], " ", minMACD[frameIndex][1], " ");
     //Alert (" Ищем отрицательный экстремум ", aDivergence[i][3], " ", maxMACD[1]);
     if (aDivergence[frameIndex][i][4] < 0) // Есть отрицательный MACD между положительными
     {
      waitForMACDMaximum[frameIndex] = false;
      waitForMACDMinimum[frameIndex] = false;
      
      Alert (" Расхождение вверху: отрицательный экстремум  ", aDivergence[frameIndex][i][1]
      , " номер бара " , aDivergence[frameIndex][i][3],  " время "
      , TimeDay(iTime(NULL, Jr_Timeframe, aDivergence[frameIndex][i][3])),":"
      , TimeHour(iTime(NULL, Jr_Timeframe, aDivergence[frameIndex][i][3])),":"
      , TimeMinute(iTime(NULL, Jr_Timeframe, aDivergence[frameIndex][i][3])));
      
      Alert(" время глобального максимума MACD " , maxMACD[frameIndex][0], " "
      , TimeDay(iTime(NULL, Jr_Timeframe, maxMACD[frameIndex][1])),":"
      , TimeHour(iTime(NULL, Jr_Timeframe, maxMACD[frameIndex][1])),":"
      , TimeMinute(iTime(NULL, Jr_Timeframe, maxMACD[frameIndex][1])));
      
      Alert(" глобальный максимум цены " , aDivergence[frameIndex][i][2], " ");
      
      Alert(" последний экстремум MACD ", aDivergence[frameIndex][1][1]
      , " номер бара " , aDivergence[frameIndex][1][3],  " время "
      , TimeDay(iTime(NULL, Jr_Timeframe, aDivergence[frameIndex][1][3])),":"
      , TimeHour(iTime(NULL, Jr_Timeframe, aDivergence[frameIndex][1][3])),":"
      , TimeMinute(iTime(NULL, Jr_Timeframe, aDivergence[frameIndex][1][3])));
      
      Alert(" последний максимум цены " , aDivergence[frameIndex][1][2], " ");
      
      return(-1); // Расхождение вверху, ждем падение, расхождение вниз (медвежье)
     } 
     i++;
    } // close while
   } // 
   waitForMACDMaximum[frameIndex] = false;
  } // close Дождались очередного максимума MACD
 }
 
 if (waitForMACDMinimum[frameIndex])
 {
  //Alert (" Ждем минимума MACD ", ExtremumMACD);
  if (ExtremumMACD < 0) // Дождались очередного минимума MACD
  {
   //Alert (" Дождались очередного минимума MACD ");
   if (minMACD[frameIndex][0] < aDivergence[frameIndex][1][1]) // Значение последнего минимума MACD больше глобального минимума
   {
    // for (i=2; i<aDivergence[0][0]; i++)
    i = 2;
    while (aDivergence[frameIndex][i][3] < minMACD[frameIndex][1])// Идем по всем экстремумам, сравниваем номера баров с номером глобального минимума
    {
     //Alert (" Ищем положительный экстремум ", aDivergence[frameIndex][i][3], " ", minMACD[frameIndex][1], " ");
     //Alert (" Ищем положительный экстремум ", aDivergence[i][3], " ", maxMACD[1]);
     if (aDivergence[frameIndex][i][4] > 0) // Есть положительный MACD между отрицательными
     {
      waitForMACDMaximum[frameIndex] = false;
      waitForMACDMinimum[frameIndex] = false;
      
      Alert (" Расхождение внизу: положительный экстремум,  ", aDivergence[frameIndex][i][1]
      , " номер бара " , aDivergence[frameIndex][i][3], " время "
      , TimeDay(iTime(NULL, Jr_Timeframe, aDivergence[frameIndex][i][3])),":"
      , TimeHour(iTime(NULL, Jr_Timeframe, aDivergence[frameIndex][i][3])),":"
      , TimeMinute(iTime(NULL, Jr_Timeframe, aDivergence[frameIndex][i][3])));
      
      Alert ( " время глобального минимума ", minMACD[frameIndex][0], " "
      , TimeDay(iTime(NULL, Jr_Timeframe, minMACD[frameIndex][1])),":"
      , TimeHour(iTime(NULL, Jr_Timeframe, minMACD[frameIndex][1])),":"
      , TimeMinute(iTime(NULL, Jr_Timeframe, minMACD[frameIndex][1])));
      
      Alert(" глобальный минимум цены " , aDivergence[frameIndex][i][2], " ");
      
      Alert ( " последний экстремум  ", aDivergence[frameIndex][1][1], " номер бара "
      , aDivergence[frameIndex][1][3],  " время "
      , TimeDay(iTime(NULL, Jr_Timeframe, aDivergence[frameIndex][1][3])),":"
      , TimeHour(iTime(NULL, Jr_Timeframe, aDivergence[frameIndex][1][3])),":"
      , TimeMinute(iTime(NULL, Jr_Timeframe, aDivergence[frameIndex][1][3])));
      
      Alert(" последний минимум цены " , aDivergence[frameIndex][1][2], " ");
      return(1); // Расхождение внизу, ждем рост, расхождение вверх (бычье)
     } 
     i++;
    } // close while 
   } 
   waitForMACDMinimum[frameIndex] = false;
  } // close Дождались очередного минимума MACD
 }
 
 return(0);
}