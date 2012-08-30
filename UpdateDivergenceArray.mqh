//+------------------------------------------------------------------+
//|                                        UpdateDivergenceArray.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, GIA"
#property link      "http://www.saita.net"

void UpdateDivergenceArray(int timeframe)
{
 int index;
 int fastPeriod = divergenceFastMACDPeriod;
 int slowPeriod = divergenceSlowMACDPeriod;
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
      Alert("UpdateDivergenceArray: Вы ошиблись с таймфреймом");
      return(false);
 }
 
 int qnt = aDivergence[index][0][0];
 int i; int j;
  
 for (i = 1; i <= qnt; i++) // по всем экстремумам
 {
  aDivergence[index][i][3]++; // сдвиг номеров баров всех экстремумов
 }
 
// --- Выкидываем старые экстремумы ---
 if (aDivergence[index][qnt][3] > depthDiv) // Если дальний экстремум ушел за границу истории, удаляем его
 {
  for (i = 0; i < 5; i++)
   {
    aDivergence[index][qnt][i] = 0;
   }
  qnt--; // количество экстремумов уменьшилось
  aDivergence[index][0][0] = qnt; // записали новое количество
 }  
  
 //Alert ("Ищем экстремум MACD");
 int ExtremumMACD = isMACDExtremum(timeframe, fastPeriod, slowPeriod); //Проверим нет ли экстремума на MACD
 
 if (ExtremumMACD > 0) // Если есть максимум на MACD
 {
  for (i = qnt; i > 0; i--)
  {
   for (j = 0; j < 5; j++)
   {
    aDivergence[index][i+1][j] = aDivergence[index][i][j];
   }
  }
  aDivergence[index][1][1] = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, 2); // Значение локального максимума MACD
  //aDivergence[1][2] = iHigh(NULL, Jr_Timeframe, 2); // максимум цены в локальном максимуме //iHighest(NULL, PERIOD_M15, MODE_HIGH, depthPrice, 0)]; 
  aDivergence[index][1][3] = 2; // номер бара с максимумом
  aDivergence[index][1][4] = 1; // это локальный максимум
  qnt++; // увеличили количество экстремумов
  aDivergence[index][0][0] = qnt; // записали новое количество
 }
 
 if (ExtremumMACD < 0)  // Если есть минимум на MACD
 {
  for (i = qnt; i > 0; i--)
  {
   for (j = 0; j < 5; j++)
   {
    aDivergence[index][i+1][j] = aDivergence[index][i][j];
   }
  }
  aDivergence[index][1][1] = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, 2); // Значение локального минимума MACD
  //aDivergence[1][2] = iLow(NULL, Jr_Timeframe, 2); // минимум цены в локальном максимуме //iHighest(NULL, PERIOD_M15, MODE_HIGH, depthPrice, 0)]; 
  aDivergence[index][1][3] = 2; // номер бара с минимумом
  aDivergence[index][1][4] = -1; // это локальный минимум
  qnt++; // увеличили количество экстремумов
  aDivergence[index][0][0] = qnt; // записали новое количество 
 }
 
 return;
}