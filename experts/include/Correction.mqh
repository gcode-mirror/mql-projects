//+------------------------------------------------------------------+
//|                                                   Correction.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
int Correction()
{
 int fastEMA = eld_EMA1;
 int slowEMA = eld_EMA2;
 int fastMACD = eldFastMACDPeriod;
 int slowMACD = eldSlowMACDPeriod;
 //double MACD_channel = Elder_MACD_channel;
 int index = frameIndex;
 
 /*
 if (timeframe == Jr_Timeframe)
 {
  fastEMA = jr_EMA1;
  slowEMA = jr_EMA2;
  fastMACD = jrFastEMAPeriod;
  slowMACD = jrSlowEMAPeriod;
  MACD_channel = Jr_MACD_channel;
  index = frameindex + 1;
 }
 else if (timeframe == Elder_Timeframe)
      {
       fastEMA = eld_EMA1;
       slowEMA = eld_EMA2;
       fastMACD = eldFastEMAPeriod;
       slowMACD = eldSlowEMAPeriod;
       MACD_channel = Elder_MACD_channel;
       index = frameindex;
      }
      else 
      {
       Alert ("Jr_Timeframe ", Jr_Timeframe, " Elder_Timeframe ", Elder_Timeframe, " timeframe ", timeframe);
       Alert ("Вы ошиблись с таймфреймом");
       return (false);
      }
*/
        
  if (trendDirection[index][0] > 0) // Тренд вверх на заданном таймфрейме
  {  
   if (iMA(NULL, Elder_Timeframe, 3, 0, 1, 0, 1) < iMA(NULL, Elder_Timeframe, 3, 0, 1, 0, 2)) // началась коррекция вниз
   {
    aCorrection[index][0] = -1;
    aCorrection[index][1] = iHigh(NULL, Elder_Timeframe, iHighest(NULL, Elder_Timeframe, MODE_HIGH, 5, 0));
   } // Close  началась коррекция вниз
  } // close Тренд вверх
   
  if (trendDirection[index][0] < 0) // Тренд вниз на заданном таймфрейме
  { 
   if (iMA(NULL, Elder_Timeframe, 3, 0, 1, 0, 1) > iMA(NULL, Elder_Timeframe, 3, 0, 1, 0, 2)) // началась коррекция вверх
   {
    aCorrection[index][0] = 1;
    aCorrection[index][1] = iLow(NULL, Elder_Timeframe, iLowest(NULL, Elder_Timeframe, MODE_HIGH, 5, 0));
   } // Close  началась коррекция вниз
  } // close Тренд вверх
  return (aCorrection[index][0]);
}


