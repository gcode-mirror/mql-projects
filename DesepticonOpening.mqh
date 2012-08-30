//+------------------------------------------------------------------+
//|                                                      Opening.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
int DesepticonOpening(int operation, string openPlace, int timeframe)
{
  double price;
  double SL;
  double TP;
  color op_color;
  Lots = GetLots();
  
  if (operation == 0)
  {
   price = Ask;
   StopLoss = Ask - iLow(NULL, timeframe, iLowest(NULL, timeframe, MODE_LOW, 4, 0)) + 30*Point; //(мин_цена - тек.покупка + 30п.)
   if (StopLoss < StopLoss_min*Point) { StopLoss = StopLoss_min*Point; }
   if (StopLoss > StopLoss_max*Point) { StopLoss = StopLoss_max*Point; }
   SL = Bid-StopLoss;
   TP = Ask+TakeProfit*Point;
   op_color = Red;
  }
  
  if (operation == 1)
  {
   price = Bid;
   StopLoss = iHigh(NULL, timeframe, iHighest(NULL, timeframe, MODE_HIGH, 4, 0)) - Bid + 30*Point; //(макс_цена - тек.продажа + 30п.)
   if (StopLoss < StopLoss_min*Point) { StopLoss = StopLoss_min*Point; }
   if (StopLoss > StopLoss_max*Point) { StopLoss = StopLoss_max*Point; }
   SL = Ask+StopLoss;
   TP = Bid-TakeProfit*Point;
   op_color = Green;
  }
  
  Alert (openPlace, " открываемся на ", timeframe, "-минутном ТФ ",  " _MagicNumber ", _MagicNumber+timeframe);
  Alert("buyCondition=",buyCondition," sellCondition=",sellCondition
  //, " buy_condition = ", buy_condition, " sell_condition=",sell_condition
  );
  //Alert(" wantToOpen[0]=",wantToOpen[frameIndex][0], "  wantToOpen[1]=",wantToOpen[frameIndex][1]);
  //Alert(" wantToOpen[0]=",wantToOpen[frameIndex+1][0], "  wantToOpen[1]=",wantToOpen[frameIndex+1][1]);
  
  ticket = OrderSend( Symbol(), operation, Lots, price, 5, SL, TP, "MACD_test", _MagicNumber+timeframe, 0, op_color);
  if(ticket < 0 ) //если не смогли открыться
  {
   _GetLastError = GetLastError();
   Alert("?????? OrderSend ? ", _GetLastError);
   return (-1);
  } // close если не смогли открыться
  for (frameIndex = startTF; frameIndex <= finishTF; frameIndex++)
  {
   wantToOpen[frameIndex][0] = 0;
   wantToOpen[frameIndex][1] = 0;
   //Alert("обнулили wantToOpen. wantToOpen[0]=",wantToOpen[frameIndex][0], "  wantToOpen[1]=",wantToOpen[frameIndex][1]);
   barsCountToBreak[frameIndex][0] = 0;
   barsCountToBreak[frameIndex][1] = 0;
  }
  
  //openPlace = " "; 
  //Alert("обнулили openPlace. openPlace=",openPlace);

  //breakthrough[frameIndex] = 0;
  //ArrayInitialize(minMACD, 0);
  //ArrayInitialize(maxMACD, 0);
  //minPriceForFlat[frameIndex] = 0;
  //maxPriceForFlat[frameIndex] = 0;
  //minPriceForDiv[frameIndex] = 0;
  //maxPriceForDiv[frameIndex] = 0;
  
  return (1);
}