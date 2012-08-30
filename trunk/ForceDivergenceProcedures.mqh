//+------------------------------------------------------------------+
//|                                    ForceDivergenceProcedures.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+


extern int depthSto = 30;
double aForce[3][10][5]; // [][0] - резерв
                           // [][1] - знач-е MACD
                           // [][2] - знач-е цены в экстремуме MACD
                           // [][3] - номер бара
                           // [][4] - знак +/-                           

// --- ѕровер€ем не по€вились ли новые экстремумы --- 
int isForceExtremum(int timeframe, int startIndex = 0)
{
  double force1 = iForce(NULL,Jr_Timeframe, 2 ,MODE_SMA,PRICE_CLOSE, startIndex + 1);
  double force2 = iForce(NULL,Jr_Timeframe, 2 ,MODE_SMA,PRICE_CLOSE, startIndex + 2);
  double force3 = iForce(NULL,Jr_Timeframe, 2 ,MODE_SMA,PRICE_CLOSE, startIndex + 3);

  if (force1 < force2 && force3 < force2) // Ќашли еще один максимум
  {
   return(1);
  }

  if (force1 > force2 && force3 > force2) // Ќашли еще один минимум
  {
   return(-1);     
  }
  return(0);
}
//------------------------------------------------



// --- «аполн€ем массив экстремумов стохастика ---
void InitForceDivergenceArray(int timeframe)
{  
   // ќбнул€ем нужный слой массива расхождений
   double tmpArray[10][4];
   ArrayInitialize(tmpArray, 0);
   
   for (int m = 0; m < 10; m++)
      for (int n = 0; n < 4; n++)
         aForce[frameIndex][m][n] = tmpArray[m][n];
   
   // «аполн€ем нужный слой новыми значени€ми
   int cnt = 0; // —четчик экстремумов
   for (int bar_num = 0; bar_num < depthSto; bar_num++) // проходим по барам 
   {
    int forceExtremum = isForceExtremum(timeframe, bar_num);
    
    if (forceExtremum > 0) // ≈сли есть максимум на Force
    { 
     cnt++;
     
     aForce[frameIndex][cnt][1] = iForce(NULL, timeframe, 2, MODE_SMA, PRICE_CLOSE, bar_num+2); // «начение локального максимума MACD
     aForce[frameIndex][cnt][2] = iHigh(NULL, Jr_Timeframe, iHighest(NULL, Jr_Timeframe, MODE_HIGH, 3, bar_num+1)); // максимум цены в локальном максимуме //iHighest(NULL, PERIOD_M15, MODE_HIGH, depthPrice, 0)]; 
     aForce[frameIndex][cnt][3] = bar_num+2; // номер бара с максимумом
     aForce[frameIndex][cnt][4] = 1; // это локальный максимум  
    }
    
    if (forceExtremum < 0) // ≈сли есть минимум на Force
    {
     cnt++;
     aForce[frameIndex][cnt][1] = iForce(NULL, timeframe, 2, MODE_SMA, PRICE_CLOSE, bar_num+2); // «начение локального минимума MACD
     aForce[frameIndex][cnt][2] = iLow(NULL, Jr_Timeframe, iLowest(NULL, Jr_Timeframe, MODE_LOW, 3, bar_num+1)); // минимум цены в локальном максимуме //iHighest(NULL, PERIOD_M15, MODE_HIGH, depthPrice, 0)]; 
     aForce[frameIndex][cnt][3] = bar_num+2; // номер бара с минимумом
     aForce[frameIndex][cnt][4] = -1; // это локальный минимум  
    }
   }
   aForce[frameIndex][0][0] = cnt; // ќбщее количество экстремумов
}

// -----------------------------------------------


//  --- ѕровер€ем не по€вилось ли расхождение ----                           
int isForceDivergence()
{
 int i;
 int forceExtremum = isForceExtremum(Jr_Timeframe);
 
 double maxPrice = 
      iHigh(NULL, Jr_Timeframe, iHighest(NULL, Jr_Timeframe, MODE_HIGH, 3, 0)); // считаем максимальную цену на 3 последних барах
 double minPrice = 
      iLow(NULL, Jr_Timeframe, iLowest(NULL, Jr_Timeframe, MODE_LOW, 3, 0)); // считаем минимальную цену на 3 последних барах

  if (forceExtremum > 0 && aForce[frameIndex][1][1] > 0.15) // ƒождались очередного максимума Force
  {
   for (i = 2; i <= 10; i++)
   { 
    if (aForce[frameIndex][i][4] > 0 && aForce[frameIndex][i][1] > 0.2 // максимум больше 80
        && aForce[frameIndex][1][1] < aForce[frameIndex][i][1])        // текущий стохастик меньше чем в истории
     if (aForce[frameIndex][1][2] > aForce[frameIndex][i][2])       // цена текущего стохастика больше чем в истории
     {
      if (iHigh(NULL, Jr_Timeframe, iHighest(NULL, Jr_Timeframe, MODE_HIGH, aForce[frameIndex][i][3] - aForce[frameIndex][1][3] - 1, aForce[frameIndex][1][3] + 1)) < aForce[frameIndex][1][2])
      {
       return(-1); // –асхождение вверху, ждем падение, расхождение вниз (медвежье)
      }
      else
      {
       return(0);
      }
     }
     else
     {
      return(0);
     } 
   } // 
  } // close ƒождались очередного максимума Force
 
  if (forceExtremum < 0 && aForce[frameIndex][1][1] < -0.15) // ƒождались очередного минимума Force
  {
   for (i = 2; i <= 10; i++)
   {
    if (aForce[frameIndex][i][4] < 0 && aForce[frameIndex][i][1] < -0.2 // минимум меньше 20
        && aForce[frameIndex][1][1] > aForce[frameIndex][i][1])        // текущий стохастик больше чем в истории
     if (aForce[frameIndex][1][2] < aForce[frameIndex][i][2])       // цена текущего стохастика меньше чем в истории
     {
      if (iLow(NULL, Jr_Timeframe, iLowest(NULL, Jr_Timeframe, MODE_LOW, aForce[frameIndex][i][3] - aForce[frameIndex][1][3] - 1, aForce[frameIndex][1][3] + 1)) > aForce[frameIndex][1][2])
      {
       return(1); // –асхождение вверху, ждем падение, расхождение вниз (медвежье)
      }
      else
      {
       return(0);
      }
     }
     else 
     {
      return(0);
     }
   } // 
  } // close ƒождались очередного минимума Force
 
 return(0);
}                           