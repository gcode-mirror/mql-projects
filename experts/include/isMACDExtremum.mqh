//+------------------------------------------------------------------+
//|                                               isMACDExtremum.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, GIA"
#property link      "http://www.saita.net"


// --- Проверяем не появились ли новые экстремумы --- 
int isMACDExtremum(int timeframe, int fastPeriod, int slowPeriod, int startIndex = 0)
{
  //Alert ("Ищем экстремум MACD_2");
  //int qnt = aDivergence[frameIndex][0][0];
  //int i; int j;
  
  //double M0 = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, startIndex);
  double M1 = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, startIndex + 1);
  double M2 = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, startIndex + 2);
  double M3 = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, startIndex + 3);
  double M4 = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, startIndex + 4);

  //if (M0 < M2 && M1 < M2 && M2 > M3 && M2 > M4 && M2 > 0) // Нашли еще один максимум
  if (M1 < M2 && M2 > M3 && M2 > M4 && M2 > differenceMACD)
  {
   //Alert("Нашли новый максимум на MACD ");
   return(1);
  }

  //if (M0 > M2 && M1 > M2 && M2 < M3 && M2 < M4 && M2 < 0) // Нашли еще один минимум
  if (M1 > M2 && M2 < M3 && M2 < M4 && M2 < -differenceMACD) 
  {
   //Alert("Нашли новый минимум на MACD ");
   return(-1);     
  }
  return(0);
}

// --- Проверяем не появились ли новые ямы --- 
int isMACDPit(int timeframe, int fastPeriod, int slowPeriod, int startIndex = 0)
{
  //Alert ("Ищем экстремум MACD_2");
  //int qnt = aDivergence[frameIndex][0][0];
  //int i; int j;
  
  //double M0 = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, startIndex);
  double M1 = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, startIndex + 1);
  double M2 = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, startIndex + 2);
  double M3 = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, startIndex + 3);
  double M4 = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, startIndex + 4);

  if (M1 < M2 && M2 > M3 && M2 > M4)
  {
   return(1); // MACD росла, начала падать
  }

  if (M1 > M2 && M2 < M3 && M2 < M4) 
  {
   return(-1);     
  }
  return(0); // MACD падала, начала расти
}