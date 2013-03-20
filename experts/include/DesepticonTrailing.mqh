//+------------------------------------------------------------------+
//|                                           DesepticonTrailing.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, GIA"
#property link      "http://www.saita.net"

void DesepticonTrailing(string symb, int timeframe) 
{
  total = OrdersTotal();
  double vol, addPrice;
  int dg;
  
  if (symb=="" || symb=="0") symb=Symbol();
  dg=MarketInfo(symb, MODE_DIGITS);
  vol=MathPow(10.0,dg);
  addPrice=0.0003*vol;
  
  for (int i=0; i<total; i++) {
    if (!(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))) continue;
    if (OrderSymbol() != Symbol()) continue;
    if (OrderMagicNumber() != _MagicNumber) continue;

    if (OrderType() == OP_BUY) {
      if (Bid-OrderOpenPrice() > minProfit*Point) {
      /*
        trailingStop = Ask - iLow(NULL, timeframe, iLowest(NULL, timeframe, MODE_LOW, 3, 0)) + addPrice*Point; //(мин_цена - тек.покупка + 30п.)
        if (trailingStop < trailingStop_min*Point) { trailingStop = trailingStop_min*Point; }
        if (trailingStop > trailingStop_max*Point) { trailingStop = trailingStop_max*Point; }
      */  
        if (OrderStopLoss() < Bid - (trailingStop+trailingStep-1)*Point || OrderStopLoss() == 0) {
          ModifyOrder(-1, Bid-trailingStop*Point, OrderTakeProfit());
        }
      }
    }

    if (OrderType() == OP_SELL) {
      if (OrderOpenPrice()-Ask > minProfit*Point) {
      /*
        trailingStop = iHigh(NULL, timeframe, iHighest(NULL, timeframe, MODE_HIGH, 3, 0)) - Bid + addPrice*Point; //(макс_цена - тек.продажа + 30п.)
        if (trailingStop < trailingStop_min*Point) { trailingStop = trailingStop_min*Point; }
        if (trailingStop > trailingStop_max*Point) { trailingStop = trailingStop_max*Point; }
      */  
        if (OrderStopLoss() > Ask + (trailingStop+trailingStep-1)*Point || OrderStopLoss() == 0) {
          ModifyOrder(-1, Ask+trailingStop*Point, OrderTakeProfit());
        }
      }
    }
  }
}