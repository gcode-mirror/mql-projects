//+------------------------------------------------------------------+
//|                                            CriteriaOnFlatRSI.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
void CriteriaOnFlatRSI()
{
   bool MACD_down;
   bool MACD_up;
   int i;
   
   RSI = iRSI(NULL,Elder_Timeframe,periodRSI,PRICE_CLOSE,0);

   if  (-MACD_channel < MACD_1H && MACD_1H < MACD_channel)
   {
    // Слабый MACD
    if (RSI < 25) // RSI внизу, перепродажа - будем покупать
    {
     MACD_up = true;
     for (i = 0; i < depthMACD - 1; i++)
     {
      if (MACD_15M[i] < MACD_15M[i+1])
      {
       MACD_up = false;
      }
     }  
     if (MACD_up && MACD_15M[i-1] < 0) // MACD начал расти с отрицательной величины
     {
      minPrice = iLow(NULL, Jr_Timeframe, iLowest(NULL, Jr_Timeframe, MODE_LOW, depthPrice, 0));
      return;
     }     
    }
    
    if (RSI > 75) // RSI наверху, перепокупка - будем продавать
    {
     MACD_down = true; // проверим падает ли MACD
     for (i = 0; i < depthMACD - 1; i++)
     {
      if (MACD_15M[i] > MACD_15M[i+1])
      {
       MACD_down = false;  // Нет не падает
      }
     }
     if (MACD_down && MACD_15M[i-1] > 0) // MACD начал падать с положительной величины- ищем максимальную цену
     {
      maxPrice = iHigh(NULL, Jr_Timeframe, iHighest(NULL, Jr_Timeframe, MODE_HIGH, depthPrice, 0));
      return;
     }     
    }
   } // Close  Слабый MACD
   return;
}


