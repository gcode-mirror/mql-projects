//+------------------------------------------------------------------+
//|                                            TrailingPositions.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, GIA"
#property link      "http://www.saita.net"

void TrailingPositions() 
{
  //int cnt = OrdersTotal();

  for (int i=0; i<total; i++) {
    if (!(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))) continue;
    if (OrderSymbol() != Symbol()) continue;        

    if (OrderType() == OP_BUY) {
      if (Bid-OrderOpenPrice() > MinProfit*Point) {
        if (OrderStopLoss() < Bid-(TrailingStop+TrailingStep-1)*Point) {
          OrderModify(OrderTicket(), OrderOpenPrice(), Bid-TrailingStop*Point, OrderTakeProfit(), 0, Blue);
        }
      }
    }

    if (OrderType() == OP_SELL) {
      if (OrderOpenPrice()-Ask > MinProfit*Point) {
        if (OrderStopLoss() > Ask+(TrailingStop+TrailingStep-1)*Point || OrderStopLoss() == 0) {
          OrderModify(OrderTicket(), OrderOpenPrice(), Ask+TrailingStop*Point, OrderTakeProfit(), 0, Blue);
        }
      }
    }
  }
  
}