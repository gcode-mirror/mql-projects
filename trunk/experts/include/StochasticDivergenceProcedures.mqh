//+------------------------------------------------------------------+
//|                               StochasticDivergenceProcedures.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+


extern int depthSto = 10;
double aStochastic[3][10][5]; // [][0] - резерв
                           // [][1] - знач-е Stochastic
                           // [][2] - знач-е цены в экстремуме Stochastic
                           // [][3] - номер бара
                           // [][4] - знак +/-                           

// --- Проверяем не появились ли новые экстремумы --- 
int isStochasticExtremum(int timeframe, int startIndex = 0)
{
  double Sto1 = iStochastic(NULL,timeframe, 5, 3, 3 ,MODE_SMA,0,MODE_MAIN, startIndex + 1);
  double Sto2 = iStochastic(NULL,timeframe, 5, 3, 3 ,MODE_SMA,0,MODE_MAIN, startIndex + 2);
  double Sto3 = iStochastic(NULL,timeframe, 5, 3, 3 ,MODE_SMA,0,MODE_MAIN, startIndex + 3);

  if (Sto1 < Sto2 && Sto3 < Sto2) // Нашли еще один максимум
  {
   return(1);
  }

  if (Sto1 > Sto2 && Sto3 > Sto2) // Нашли еще один минимум
  {
   return(-1);     
  }
  return(0);
}
//------------------------------------------------



// --- Заполняем массив экстремумов стохастика ---
void InitStoDivergenceArray(int timeframe)
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
      Alert("InitStoDivergenceArray: Вы ошиблись с таймфреймом");
      return(false);
 }
 // Обнуляем нужный слой массива расхождений
 double tmpArray[10][4];
 ArrayInitialize(tmpArray, 0);
 
 for (int m = 0; m < 10; m++)
    for (int n = 0; n < 4; n++)
       aStochastic[index][m][n] = tmpArray[m][n];
 
 // Заполняем нужный слой новыми значениями
 int cnt = 0; // Счетчик экстремумов
 for (int bar_num = 0; bar_num < depthSto; bar_num++) // проходим по барам 
 {
  int stochasticExtremum = isStochasticExtremum(timeframe, bar_num);
  
  if (stochasticExtremum > 0) // Если есть максимум на Stochastic
  { 
   cnt++;
   
   aStochastic[index][cnt][1] = iStochastic(NULL, timeframe, 5, 3, 3, MODE_SMA, 0, MODE_MAIN, bar_num+2); // Значение локального максимума Stochastic
   //aStochastic[index][cnt][2] = iHigh(NULL, timeframe, iHighest(NULL, timeframe, MODE_HIGH, 3, bar_num+2)); // максимум цены в локальном максимуме //iHighest(NULL, PERIOD_M15, MODE_HIGH, depthPrice, 0)]; 
   aStochastic[index][cnt][3] = bar_num+2; // номер бара с максимумом
   aStochastic[index][cnt][4] = 1; // это локальный максимум  
  }
   
  if (stochasticExtremum < 0) // Если есть минимум на Stochastic
  {
   cnt++;
   aStochastic[index][cnt][1] = iStochastic(NULL, timeframe, 5, 3, 3, MODE_SMA, 0, MODE_MAIN, bar_num+2); // Значение локального минимума Stochastic
   //aStochastic[index][cnt][2] = iLow(NULL, timeframe, iLowest(NULL, timeframe, MODE_LOW, 3, bar_num+2)); // минимум цены в локальном максимуме //iHighest(NULL, PERIOD_M15, MODE_HIGH, depthPrice, 0)]; 
   aStochastic[index][cnt][3] = bar_num+2; // номер бара с минимумом
   aStochastic[index][cnt][4] = -1; // это локальный минимум  
  }
 }
 aStochastic[index][0][0] = cnt; // Общее количество экстремумов
}
// -----------------------------------------------


//  --- Проверяем не появилось ли расхождение ----                           
int isStoDivergence(int timeframe)
{
 int i;
 int stochasticExtremum = isStochasticExtremum(timeframe);
 
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
      Alert("isStoDivergence: Вы ошиблись с таймфреймом");
      return(false);
 }
 
 double curMaxPrice = 
      iHigh(NULL, timeframe, iHighest(NULL, timeframe, MODE_HIGH, 3, 0)); // считаем максимальную цену на 0-2 последних барах
 double curMinPrice = 
      iLow(NULL, timeframe, iLowest(NULL, timeframe, MODE_LOW, 3, 0)); // считаем минимальную цену на 0-2 последних барах
      
 double maxPrice = 
      iHigh(NULL, timeframe, iHighest(NULL, timeframe, MODE_HIGH, depthSto - 4, 3)); // считаем максимальную цену на 2-10 последних барах
 double minPrice = 
      iLow(NULL, timeframe, iLowest(NULL, timeframe, MODE_LOW, depthSto - 4, 3)); // считаем минимальную цену на 2-10 последних барах

 if (curMaxPrice > maxPrice) // цена текущего стохастика больше, чем в истории
 {
  if (stochasticExtremum > 0 && aStochastic[index][1][1] < 80) // Дождались очередного максимума Sto меньше 80
  {
   for (i = 2; i <= 10; i++)
   { 
    if (aStochastic[index][i][4] > 0 && aStochastic[index][i][1] > 80) // максимум, больше 80
    {
     openPlace = 
       TimeDay(iTime(NULL, timeframe, aStochastic[index][1][3])) + ":"
     + TimeHour(iTime(NULL, timeframe, aStochastic[index][1][3])) + ":"
     + TimeMinute(iTime(NULL, timeframe, aStochastic[index][1][3]));
     barsCountToBreak[index][1] = 0;
     return(-1); // Расхождение вверху, ждем падение, расхождение вниз (медвежье)
    } 
   } // 
  } // close Дождались очередного максимума Sto
 } // close цена текущего стохастика больше, чем в истории
 
 //Alert("цена текущего стохастика =", curMinPrice, " минимальная цена на 2-10 последних барах=",minPrice);
 if(curMinPrice < minPrice) // цена текущего стохастика меньше чем в истории
 {
  //Alert("цена текущего стохастика меньше чем в истории");
  if (stochasticExtremum < 0 && aStochastic[index][1][1] > 20) // Дождались очередного минимума стохастика больше 20
  {
   //Alert("");
   for (i = 2; i <= 10; i++)
   {
    if (aStochastic[index][i][4] < 0 && aStochastic[index][i][1] < 20) // минимум, меньше 20
    { 
     openPlace = 
       TimeDay(iTime(NULL, timeframe, aStochastic[index][1][3])) + ":"
     + TimeHour(iTime(NULL, timeframe, aStochastic[index][1][3])) + ":"
     + TimeMinute(iTime(NULL, timeframe, aStochastic[index][1][3]));
     barsCountToBreak[index][1] = 0;
     return(1); // Расхождение вверху, ждем падение, расхождение вверх (бычье)
    } 
   } // 
  } // close Дождались очередного минимума MACD
 }// close цена текущего стохастика меньше чем в истории 
 
 return(0);
}                           