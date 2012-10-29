//+------------------------------------------------------------------+
//|                                                _isDivergence.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, GIA"
#property link      "http://www.saita.net"

//------- Глобальные переменные модуля -------------------------------------+
int depthMACD = 9;
double minPriceForDiv[3][2]; //[тф][0] - значение, [тф][1] - номер бара
double maxPriceForDiv[3][2]; //[тф][0] - значение, [тф][1] - номер бара

//------- Инициализация массива экстремумов---------------------------------+
void InitExtremums(int index)
{
 maxPriceForDiv[index][1] = iHighest(NULL, aTimeframe[index,0], MODE_HIGH, depthMACD, 0); 
 minPriceForDiv[index][1] = iLowest(NULL, aTimeframe[index,0], MODE_LOW, depthMACD, 0);
 maxPriceForDiv[index][0] = iHigh(NULL, aTimeframe[index,0], maxPriceForDiv[index][1]); // считаем максимальную цену на последних 15 барах (должны на всем отрезке)
 minPriceForDiv[index][0] = iLow(NULL, aTimeframe[index,0], minPriceForDiv[index][1]); // считаем минимальную цену на последних 15 барах (должны на всем отрезке)
 
 int qnt = aDivergence[index][0][0];
 minMACD[index][0] = aDivergence[index][1][1]; minMACD[index][1] = aDivergence[index][1][3];
 maxMACD[index][0] = aDivergence[index][1][1]; maxMACD[index][1] = aDivergence[index][1][3];
 
 for (int i = 2; i < qnt; i++) // проходим по массиву MACD
 {
  if (minMACD[index][0] > aDivergence[index][i][1])
   {
    minMACD[index][0] = aDivergence[index][i][1];
    minMACD[index][1] = aDivergence[index][i][3];
   }
  if (maxMACD[index][0] < aDivergence[index][i][1])
   {
    maxMACD[index][0] = aDivergence[index][i][1];
    maxMACD[index][1] = aDivergence[index][i][3];
   }
 }
 return;
}


//----------Заполняем массив экстремумов MACD -----------------
void InitDivergenceArray(int timeframe)
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
      Alert("InitDivergenceArray: Вы ошиблись с таймфреймом");
      return(false);
 }  
 
   // Обнуляем нужный слой массива расхождений
   double tmpArray[60][5];
   ArrayInitialize(tmpArray, 0);
   
   for (int m = 0; m < 60; m++)
      for (int n = 0; n < 5; n++)
         aDivergence[index][m][n] = tmpArray[m][n];
   
   // Заполняем нужный слой новыми значениями
   int cnt = 0; // Счетчик экстремумов
   for (int bar_num = 0; bar_num < depthDiv; bar_num++) // проходим по барам 
   {
    int ExtremumMACD = isMACDExtremum(timeframe, fastPeriod, slowPeriod, bar_num);
    
    if (ExtremumMACD > 0) // Если есть максимум на MACD
    { 
     cnt++;
     aDivergence[index][cnt][1] = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, bar_num+2); //M2; // Значение локального максимума MACD
     //aDivergence[cnt][2] = iHigh(NULL, Jr_Timeframe, bar_num+2); // максимум цены в локальном максимуме //iHighest(NULL, PERIOD_M15, MODE_HIGH, depthPrice, 0)]; 
     aDivergence[index][cnt][3] = bar_num+2; // номер бара с максимумом
     aDivergence[index][cnt][4] = 1; // это локальный максимум  
    }
    
    if (ExtremumMACD < 0) 
    {
     cnt++;
     aDivergence[index][cnt][1] = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, bar_num+2);//M2; // Значение локального минимума MACD
     //aDivergence[cnt][2] = iLow(NULL, Jr_Timeframe, bar_num+2); // минимум цены в локальном максимуме //iHighest(NULL, PERIOD_M15, MODE_HIGH, depthPrice, 0)]; 
     aDivergence[index][cnt][3] = bar_num+2; // номер бара с минимумом
     aDivergence[index][cnt][4] = -1; // это локальный минимум  
    }
   }
   aDivergence[index][0][0] = cnt; // Общее количество экстремумов
}

//------ Вычисление расхождения -----------------------------------+
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
 
 // Номер бара с максимальной ценой на 15-100 барах
 int maxPriceBarNumber 
         = iHighest(NULL, timeframe, MODE_HIGH, depthDiv - depthMACD + 1, depthMACD);
 // Номер бара с минимальной ценой на 15-100 последних барах
 int minPriceBarNumber
          = iLowest(NULL, timeframe, MODE_LOW, depthDiv - depthMACD + 1, depthMACD);

 double maxPrice = 
      iHigh(NULL, timeframe, maxPriceBarNumber); // считаем максимальную цену на 15-100 последних барах
 double minPrice = 
      iLow(NULL, timeframe, minPriceBarNumber); // считаем минимальную цену на 15-100 последних барах

 if (maxPriceForDiv[index][0] > maxPrice + differencePrice) // на последних 15-ти барах цена выше максимума на 15-100
 {
  //Alert("на последних 15-ти барах цена выше максимума на 15-100, номер бара ", maxPriceForDiv[index][1]);
  if (ExtremumMACD > 0) // Дождались очередного максимума MACD
  {
   if (maxMACD[index][0] - differenceMACD > aDivergence[index][1][1]) // Последний максимум MACD меньше(ближе к нулю) глобального максимума
   {
    i = 2;
    while (aDivergence[index][i][3] < maxMACD[index][1]) // Идем по всем экстремумам, сравниваем номера баров с номером глобального максимума
    {
     if (aDivergence[index][i][4] < 0) // Есть отрицательный MACD между положительными
     {
      openPlace = "расхождение на " + timeframe + "-минутном ТФ на MACD вниз ";
      barsCountToBreak[index][0] = 0;
      //Alert("trendDirection[",index,"][0]",trendDirection[index][0]);
      return(-1); // Расхождение вверху, ждем падение, расхождение вниз (медвежье)
     } 
     i++;
    } // close while
   } // 
  } // close Дождались очередного максимума MACD
 }
 
 if (minPriceForDiv[index][0] < minPrice - differencePrice) // на последних 10-ти барах цена ниже минимума на 10-100
 {
  if (ExtremumMACD < 0) // Дождались очередного минимума MACD
  {
   if (minMACD[index][0] + differenceMACD < aDivergence[index][1][1]) // Последний минимум MACD больше(ближе к нулю) глобального минимума
   {
    i = 2;
    while (aDivergence[index][i][3] < minMACD[index][1])// Идем по всем экстремумам, сравниваем номера баров с номером глобального минимума
    {
     if (aDivergence[index][i][4] > 0) // Есть положительный MACD между отрицательными
     {
      openPlace = "расхождение на " + timeframe + "-минутном ТФ на MACD вверх ";
      barsCountToBreak[index][0] = 0;
      return(1); // Расхождение внизу, ждем рост, расхождение вверх (бычье)
     } 
     i++;
    } // close while 
   } 
  } // close Дождались очередного минимума MACD
 }
 
 return(0);
}