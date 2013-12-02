//+------------------------------------------------------------------+
//|                                                searchForTits.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, GIA"
#property link      "http://www.saita.net"

bool searchForTits(int timeframe, double MACD_channel, bool bothTits)
{
 int i = 0;
 int ext = 0;
 int fastPeriod;
 int slowPeriod;
 bool isMax = false;
 bool isMin = false;
 
 if (timeframe == jr_Timeframe)
 { 
  fastPeriod = jrFastMACDPeriod;
  slowPeriod = jrSlowMACDPeriod;
 } 
 else if ( timeframe == elder_Timeframe )
      {
       fastPeriod = eldFastMACDPeriod;
       slowPeriod = eldSlowMACDPeriod;
      }
      else
      {
       Alert ("jr_Timeframe ", jr_Timeframe, " elder_Timeframe ",elder_Timeframe, " timeframe ", timeframe);
       Alert ("searchForTits: Вы ошиблись с таймфреймом");
       return (0);
      }
 
 //Alert ("fastPeriod ", fastPeriod, " slowPeriod ",slowPeriod, " timeframe ", timeframe);
 for (i = 0; MathAbs(iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, i)) < MACD_channel; i++)
 {
  ext = isMACDExtremum(timeframe, fastPeriod, slowPeriod, i);
  if (ext != 0)
  {
   if (ext < 0)
   {
    //Alert (" Найден минимум ", i, " баров назад" );
    isMin = true;
   } 
   if (ext > 0)
   {
    //Alert (" Найден максимум ", i, " баров назад" );
    isMax = true;
   } 
   if (isMin && isMax)
   {
    break;
   }
  }
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

