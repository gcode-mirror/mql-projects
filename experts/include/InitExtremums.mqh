//+------------------------------------------------------------------+
//|                                                InitExtremums.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
void InitExtremums(int index)
{
 maxPriceForDiv[index][1] = iHighest(NULL, aTimeframe[index,0], MODE_HIGH, 9, 0); 
 minPriceForDiv[index][1] = iLowest(NULL, aTimeframe[index,0], MODE_LOW, 9, 0);
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


