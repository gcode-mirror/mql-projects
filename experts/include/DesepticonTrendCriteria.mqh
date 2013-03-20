//+------------------------------------------------------------------+
//|                                      DesepticonTrendCriteria.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
int InitTrendDirection(int timeframe, double MACD_channel)
{
 int i = 0;
 int depth = 200;
 int index;
 int fastEMA;
 int slowEMA;
 int fastPeriod;
 int slowPeriod;
 bool isTrendDefined = false;
  
 switch(timeframe)
 {
  case PERIOD_D1:
      Alert("PERIOD_D1");
      index = 0;
      fastEMA = eld_EMA1;
      slowEMA = eld_EMA2;
      fastPeriod = eldFastMACDPeriod;
      slowPeriod = eldSlowMACDPeriod;
      break;
  case PERIOD_H1:
      Alert("PERIOD_H1");
      index = 1;
      fastEMA = eld_EMA1;
      slowEMA = eld_EMA2;
      fastPeriod = eldFastMACDPeriod;
      slowPeriod = eldSlowMACDPeriod;
      break;
  case PERIOD_M5:
      Alert("PERIOD_M5");
      index = 2;
      fastEMA = jr_EMA1;
      slowEMA = jr_EMA2;
      fastPeriod = jrFastMACDPeriod;
      slowPeriod = jrSlowMACDPeriod;
      break;
  default:
      Alert("InitTrendDirection: Вы ошиблись с таймфреймом");
      break;
 }
 
 while (!isTrendDefined && i < depth)
 {
  while((MACD_channel > iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, i)
        && iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, i) > -MACD_channel) && i < depth)
  {
   i++;
  }
  Current_fastEMA = iMA(NULL, timeframe, fastEMA, 0, 1, 0, i);
  Current_slowEMA = iMA(NULL, timeframe, slowEMA, 0, 1, 0, i);
  if ((Current_fastEMA < (Current_slowEMA - deltaEMAtoEMA*Point)))
  {
   trendDirection[index][1] = -1;
   isTrendDefined = true;
   return(-1);   
  }
  if ((Current_fastEMA > (Current_slowEMA + deltaEMAtoEMA*Point)) )
  {
   trendDirection[index][1] = 1;
   isTrendDefined = true;
   return(1);
  }
  i++;
 }
 
 if (i >= depth)
 {
  Alert("ВНИМАНИЕ!!! Задан слишком широкий коридор MACD, начальное направление тренда не определено! Возможна некорректная работа эксперта!");
 }
 return(0);
}

//-----------------------------------------------------
//
//-----------------------------------------------------

int OneTitTrendCriteria(int timeframe, double MACD_channel, int period_EMA1, int period_EMA2, int fastEMAPeriod, int slowEMAPeriod)
{

  Current_fastEMA = iMA(NULL, timeframe, period_EMA1, 0, 1, 0, 1);
  Current_slowEMA = iMA(NULL, timeframe, period_EMA2, 0, 1, 0, 1);
  CurrentMACD = iMACD(NULL, timeframe, fastEMAPeriod, slowEMAPeriod, 9, PRICE_CLOSE, MODE_MAIN, 1);
  
  bool MACD_down;
  bool MACD_up;
  int i;
  
  if (-MACD_channel < CurrentMACD && CurrentMACD < MACD_channel)
  {  // Слабый MACD
   if (searchForTits(timeframe, MACD_channel, false))
   {
    return (0);
   } // Close  searchForTits
   if (timeframe == elder_Timeframe)
    return (trendDirection[frameIndex][1]);
   if (timeframe == jr_Timeframe)
    return (trendDirection[frameIndex + 1][1]); 
  }
  
  if ((Current_fastEMA < (Current_slowEMA - deltaEMAtoEMA*Point)))
  {
	return (-1);   
  }
    
  if ((Current_fastEMA > (Current_slowEMA + deltaEMAtoEMA*Point)) )
  {
   return (1);
  }

  return (0); // Нет тренда
}

//-----------------------------------------------------
//
//-----------------------------------------------------

int TwoTitsTrendCriteria(int timeframe, double MACD_channel, int period_EMA1, int period_EMA2, int fastEMAPeriod, int slowEMAPeriod)
{
   int index;
   
   if (timeframe == elder_Timeframe)
   {
    index = frameIndex;
   }
   else if (timeframe == jr_Timeframe)
        {
         index = frameIndex + 1; 
        }
        else
        {
         Alert("TwoTitsTrendCriteria: Вы ошиблись с таймфреймом");
        }

  Current_fastEMA = iMA(NULL, timeframe, period_EMA1, 0, 1, 0, 1);
  Current_slowEMA = iMA(NULL, timeframe, period_EMA2, 0, 1, 0, 1);
  CurrentMACD = iMACD(NULL, timeframe, fastEMAPeriod, slowEMAPeriod, 9, PRICE_CLOSE, MODE_MAIN, 1);
  
  bool MACD_down;
  bool MACD_up;
  int i;
  
  if (-MACD_channel <= CurrentMACD && CurrentMACD <= MACD_channel)
  {  // Слабый MACD
   if (isMACDExtremum(timeframe, fastEMAPeriod, slowEMAPeriod) != 0)
   {
    if (searchForTits(timeframe, MACD_channel, true))
    {
     Alert("начался флэт");
     return (0); // появились маленькие титьки на MACD в обе стороны - начался флэт
    } // Close  searchForTits
   }
   Alert("MACD слабый, но флэт еще не начался");
   return (trendDirection[index][0]);
  }
  
  if ((Current_fastEMA < (Current_slowEMA - deltaEMAtoEMA*Point)))
  {
   // медленный ЕМА выше быстрого - тренд вниз
	return (-1);   
  }
  else if ((Current_fastEMA > (Current_slowEMA + deltaEMAtoEMA*Point)) )
       {
       // медленный ЕМА ниже быстрого - тренд вверх
       return (1);
       }
       else
       {
        // MACD большой, но ЕМА близко, живем по последнему тренду
        return (trendDirection[index][1]);
       }
  
  Alert("ВНИМАНИЕ !!! нет тренда!!!");
  return (0); // Нет тренда
}