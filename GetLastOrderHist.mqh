//+------------------------------------------------------------------+
//|                                             GetLastOrderHist.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, GIA"
#property link      "http://www.saita.net"

int GetLastOrderHist(int type = -1) 
{
  int ticket = -1;
  datetime dt = 0;
  int cnt = OrdersHistoryTotal();
    
  for (int i=0; i < cnt; i++) {
    if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;

    // Опционально
    // if (OrderSymbol() != Symbol()) continue;
    // Опционально
    // if (OrderMagicNumber() != Magic) continue;
    
    if (type != -1 && OrderType() != type) continue;
    
    if (OrderCloseTime() > dt) {
      dt = OrderCloseTime();
      ticket = OrderTicket();
    }
  }
  return (ticket);
}