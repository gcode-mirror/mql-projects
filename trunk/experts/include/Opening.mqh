//+------------------------------------------------------------------+
//|                                                      Opening.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
int Opening(int operation)
{
  double price;
  double SL;
  double TP;
  color op_color;
  Lots = GetLots();
  
  if (operation == 0)
  {
   price = Ask;
   StopLoss = Ask - iLow(NULL, Jr_Timeframe, iLowest(NULL, Jr_Timeframe, MODE_LOW, 4, 0)) + 30*Point; //(мин_цена - тек.покупка + 30п.)
   if (StopLoss < StopLoss_min*Point) { StopLoss = StopLoss_min*Point; }
   if (StopLoss > StopLoss_max*Point) { StopLoss = StopLoss_max*Point; }
   SL = Bid-StopLoss;
   TP = Ask+TakeProfit*Point;
   op_color = Red;
  }
  
  if (operation == 1)
  {
   price = Bid;
   StopLoss = iHigh(NULL, Jr_Timeframe, iHighest(NULL, Jr_Timeframe, MODE_HIGH, 4, 0)) - Bid + 30*Point; //(макс_цена - тек.продажа + 30п.)
   if (StopLoss < StopLoss_min*Point) { StopLoss = StopLoss_min*Point; }
   if (StopLoss > StopLoss_max*Point) { StopLoss = StopLoss_max*Point; }
   SL = Ask+StopLoss;
   TP = Bid-TakeProfit*Point;
   op_color = Green;
  }
  
  //Alert ("TP", TP);
  ticket = OrderSend( Symbol(), operation, Lots, price, 5, SL, TP, "MACD_test", _MagicNumber, 0, op_color);
  if(ticket < 0 ) //если не смогли открыться
  {
   _GetLastError = GetLastError();
   Alert("?????? OrderSend ? ", _GetLastError);
   return (-1);
  } // close если не смогли открыться
  wantToOpen[frameIndex] = 0;
  return (1);
}