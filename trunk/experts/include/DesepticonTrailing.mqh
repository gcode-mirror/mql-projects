//+------------------------------------------------------------------+
//|                                           DesepticonTrailing.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, GIA"
#property link      "http://www.saita.net"

void DesepticonTrailing() 
{
  total = OrdersTotal();
  int currentMagic;
  int timeframe;
  
  for (int i=0; i<total; i++) {
    if (!(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))) continue;
    if (OrderSymbol() != Symbol()) continue;
    
    currentMagic = OrderMagicNumber();
    switch (currentMagic){
      case (1127):
         //MinProfit = MinProfit_5M; 
         //TrailingStop_min = TrailingStop_5M_min;
         //TrailingStop_max = TrailingStop_5M_max; 
         //TrailingStep = TrailingStep_5M;
         timeframe = PERIOD_M5;
         break;
      case (1182):
         //MinProfit = MinProfit_1H; 
         //TrailingStop_min = TrailingStop_1H_min;
         //TrailingStop_max = TrailingStop_1H_max; 
         //TrailingStep = TrailingStep_1H;
         timeframe = PERIOD_H1;      
         break;
      case (2562):
         //MinProfit = MinProfit_1D; 
         //TrailingStop_min = TrailingStop_1D_min;
         //TrailingStop_max = TrailingStop_1D_max; 
         //TrailingStep = TrailingStep_1D;
         timeframe = PERIOD_D1;      
         break;
      default:
         return;
    }

    if (OrderType() == OP_BUY) {
      if (Bid-OrderOpenPrice() > MinProfit*Point) {
        TrailingStop = Ask - iLow(NULL, timeframe, iLowest(NULL, timeframe, MODE_LOW, 3, 0)) + 30*Point; //(мин_цена - тек.покупка + 30п.)
        if (TrailingStop < TrailingStop_min*Point) { TrailingStop = TrailingStop_min*Point; }
        if (TrailingStop > TrailingStop_max*Point) { TrailingStop = TrailingStop_max*Point; }
        
        if (OrderStopLoss() < Bid-(TrailingStop+TrailingStep*Point-1*Point)) {
          //Alert (TrailingStop," трейл");
          OrderModify(OrderTicket(), OrderOpenPrice(), Bid-TrailingStop, OrderTakeProfit(), 0, Blue);
        }
      }
    }

    if (OrderType() == OP_SELL) {
      if (OrderOpenPrice()-Ask > MinProfit*Point) {
        TrailingStop = iHigh(NULL, timeframe, iHighest(NULL, timeframe, MODE_HIGH, 3, 0)) - Bid + 30*Point; //(макс_цена - тек.продажа + 30п.)
        if (TrailingStop < TrailingStop_min*Point) { TrailingStop = TrailingStop_min*Point; }
        if (TrailingStop > TrailingStop_max*Point) { TrailingStop = TrailingStop_max*Point; }
        
        if (OrderStopLoss() > Ask+(TrailingStop+TrailingStep*Point-1*Point) || OrderStopLoss() == 0) {
          //Alert (TrailingStop," трейл");
          OrderModify(OrderTicket(), OrderOpenPrice(), Ask+TrailingStop, OrderTakeProfit(), 0, Blue);
        }
      }
    }
  }
}