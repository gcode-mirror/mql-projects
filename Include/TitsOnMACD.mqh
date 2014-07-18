//+------------------------------------------------------------------+
//|                                                   TitsOnMACD.mqh |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| isMACDExtremum                                                   |
//+------------------------------------------------------------------+
// --- Проверяем не появились ли новые экстремумы --- 
int isMACDExtremum(int handleMACD, int startIndex = 0)
{
  double MACD[];
  ArraySetAsSeries(MACD, true);
  CopyBuffer(handleMACD, 0, startIndex, 5, MACD);

  //if (M0 < M2 && M1 < M2 && M2 > M3 && M2 > M4 && M2 > 0) // Нашли еще один максимум
  if (MACD[1] < MACD[2] && MACD[2] > MACD[3] && MACD[2] > MACD[4] && MACD[2] > 0)
  {
   //Alert("Нашли новый максимум на MACD ");
   return(1);
  }

  //if (M0 > M2 && M1 > M2 && M2 < M3 && M2 < M4 && M2 < 0) // Нашли еще один минимум
  if (MACD[1] > MACD[2] && MACD[2] < MACD[3] && MACD[2] < MACD[4] && MACD[2] < 0) 
  {
   //Alert("Нашли новый минимум на MACD ");
   return(-1);     
  }
  return(0);
}

//+------------------------------------------------------------------+
//| isMACDPit                                                        |
//+------------------------------------------------------------------+
// --- Проверяем не появились ли новые перегибы --- 
int isMACDPit(int handleMACD, int startIndex = 0)
{
  double MACD[];
  ArraySetAsSeries(MACD, true);
  CopyBuffer(handleMACD, 0, startIndex, 5, MACD);

  if (MACD[1] < MACD[2] && MACD[2] > MACD[3] && MACD[2] > MACD[4])
  {
   return(1); // MACD росла, начала падать
  }

  if (MACD[1] > MACD[2] && MACD[2] < MACD[3] && MACD[2] < MACD[4]) 
  {
   return(-1);     
  }
  return(0); // MACD падала, начала расти
}
//+------------------------------------------------------------------+
//| searchForTits                                                    |
//+------------------------------------------------------------------+
bool searchForTits(int handleMACD, double MACD_channel, bool bothTits)
{
 double MACD[];
 ArraySetAsSeries(MACD, true);
 CopyBuffer(handleMACD, 0, 0, 5, MACD);
 int i = 0;
 int depth = 200;
 bool isMax = false;
 bool isMin = false;
 
 while (-MACD_channel < MACD[i] && MACD[i] < MACD_channel && i < depth)
 {
  if (isMACDExtremum(handleMACD, i) < 0)
  {
   //Alert (" Найден минимум ", i, " баров назад" );
   isMax = true;
   break;
  } 
  i++;
 }
 
 i = 0;
 while(-MACD_channel < MACD[i] && MACD[i] < MACD_channel)
 {
  if (isMACDExtremum(handleMACD, i) > 0)
  {
   //Alert (" Найден максимум ", i, " баров назад" );
   isMin = true;
   break;
  } 
  i++;
 }
 
 if (bothTits) // если нужны обе титьки для флэта
 {
  return (isMin && isMax); // возвращаем тру только если обе титьки найдены
 }
 else 
 {
  return (isMin || isMax);
 }
}
