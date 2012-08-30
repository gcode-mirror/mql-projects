//+------------------------------------------------------------------+
//|                                              CriteriaOnTrend.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
int CriteriaOnTrend()
{
  Current_fastEMA = iMA(NULL, Elder_Timeframe, jr_EMA1, 0, 1, 0, 0);
  Current_slowEMA = iMA(NULL, Elder_Timeframe, jr_EMA2, 0, 1, 0, 0);
  CurrentMACD = iMACD(NULL, Elder_Timeframe, eldFastMACDPeriod, eldSlowMACDPeriod, 9, PRICE_CLOSE, MODE_MAIN, 0);
  
  bool MACD_down;
  bool MACD_up;
  int i;
  
  if  (-MACD_channel_1H < CurrentMACD && CurrentMACD < MACD_channel_1H)
   {
    return (0);
   }
  
  if (Current_fastEMA < (Current_slowEMA - deltaEMAtoEMA*Point))
      {
      //Alert("Open order ", "Тренд вниз ");  проверяем 15-минутку
       MACD_down = true; // проверим падает ли MACD
       for (i = 0; i < depthMACD - 1; i++)
       {
         if (MACD_15M[i] > MACD_15M[i+1]) {
         MACD_down = false;  // Нет не падает
         }
       }
       if (MACD_down && MACD_15M[i-1] > 0) // MACD начал падать с положительной величины- ищем максимальную цену
       {
        //Alert("Тренд вниз  Критерий MACD найден!! Считаем максимум  Current_EMA_13 ", Current_EMA_13, " Current_EMA_20 ", Current_EMA_20, " Prev_EMA_13 ", Prev_EMA_13);
        maxPrice = iHigh(NULL, Jr_Timeframe, iHighest(NULL, Jr_Timeframe, MODE_HIGH, depthPrice, 0)); // считаем максимальную цену на последних 5-и барах
        //Alert(" Текущий максимум ", maxPrice);
        //for (int imax = 0; imax < depthPrice; imax++) {Alert("максимум на ", imax, "-м баре ", High[imax], "  Time=", TimeHour(Time[imax]),":", TimeMinute(Time[imax]));}
        //Alert("Посчитали максимум ", maxPrice, " ", wantToOpen, " ", wantToClose);
       }
       return (-1);
      }
    
   if (Current_fastEMA > (Current_slowEMA + deltaEMAtoEMA*Point))
      {
       //Alert("Open order ", "Тренд вверх ", "MACD_1H ", MACD_1H, " MACD_channel ", MACD_channel);
       MACD_up = true;
       for (i = 0; i < depthMACD - 1; i++)
       {
         if (MACD_15M[i] < MACD_15M[i+1])
         {
         MACD_up = false;
         }
       }  
      if (MACD_up && MACD_15M[i-1] < 0) // MACD начал расти с отрицательной величины- ищем минимальную цену
       {
        //Alert(" Тренд вверх Критерий MACD найден!! Считаем минимум. Current_EMA_13 ", Current_EMA_13, " Current_EMA_20 ", Current_EMA_20, " Prev_EMA_13 ", Prev_EMA_13);
        minPrice = iLow(NULL, Jr_Timeframe, iLowest(NULL, Jr_Timeframe, MODE_LOW, depthPrice, 0)); // считаем минимальную цену на последних 5-и барах
        //Alert(" Текущий минимум ", minPrice);
        //for (int imin = 0; imin < depthPrice; imin++) { Alert("минимум на ", imin, "-м баре ", Low[imin], "  Time=", TimeHour(Time[imin]), ":", TimeMinute(Time[imin]));}
        //Alert("Посчитали минимум ", minPrice, " ", wantToOpen, " ", wantToClose);
       }
       return (1);
      }
      
   return (0);
}


