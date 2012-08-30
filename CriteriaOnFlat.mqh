//+------------------------------------------------------------------+
//|                                               CriteriaOnFlat.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
void CriteriaOnFlat()
{
   bool MACD_down;
   bool MACD_up;
   int i;
   
   Stochastic = iStochastic(NULL,Elder_Timeframe, Kperiod, Dperiod , slowing ,MODE_SMA,0,MODE_SIGNAL,0);
   MACD_1H = iMACD(NULL, Elder_Timeframe, eldFastEMAPeriod, eldSlowEMAPeriod, 9, PRICE_CLOSE, MODE_MAIN, 0);
   
   if  (-MACD_channel < MACD_1H && MACD_1H < MACD_channel)
   {  // Слабый MACD
    if (searchForTits())
    {
     if (Stochastic < 25) // Стохастик внизу, перепродажа - будем покупать
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
    
     if (Stochastic > 75) // Стохастик наверху, перепокупка - будем продавать
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
    } // Close  searchForTits
   } // close слабый MACD
   return;
}


