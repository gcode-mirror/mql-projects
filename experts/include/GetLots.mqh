//+------------------------------------------------------------------+
//|                                                      GetLots.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, GIA"
#property link      "http://www.saita.net"

double GetLots() {
 
  //double one_lot_price = MarketInfo("EURUSD", MODE_MARGININIT); // стоимость 1 лота
  //double Money=lotmin*one_lot_price;              // соимость ордера
  double lot;
  
  //if(Money<=AccountFreeMargin())           // средств хватает
   lot = lotmin;                           // ..принимаем заданное 
   /*
  else  
   {
    Alert ("не хватает денег");
    lot = 0;
    return (lot);
   }
  
  lot = lotmin;
  */
  if (!uplot) return (lot); // включено ли изменение величины лота
  
  int ticket = GetLastOrderHist(); // номер последней сделки
  
  if (ticket == -1) return (lot); // не было сделок
  
  if (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_HISTORY)) return (lot); // не выбрался ордер с полученным номером
  if (OrderProfit()*lastprofit < 0) return (lot);  // lastprofit = -1, минимальный лот после удачной сделки (если lastprofit = 1, то скидывать будем после неудач) 
  
  if (OrderLots() == lotmin) {lot = NormalizeLots(lotmin * 2); return(lot);}
  if (OrderLots() == lotmin * 2) {lot = NormalizeLots(lotmin * 3); return(lot);}
  //if (OrderLots() == lotmin *3) {lot = lotmin * 4; return(lot);}
  //if (OrderLots() == lotmin *4) {lot = lotmin * 5; return(lot);}
  //if (OrderLots() == lotmin *5) {lot = lotmin * 6; return(lot);}
  //if (OrderLots() == lotmin *6) {lot = lotmin * 7; return(lot);}
  //if (OrderLots() == lotmin *7) {lot = lotmin * 8; return(lot);}
  //if (OrderLots() == lotmin *8) {lot = lotmin * 9; return(lot);}
  //if (OrderLots() == lotmin *9) {lot = lotmin * 10; return(lot);}
  if (OrderLots() == lotmin * 3) {lot = NormalizeLots(lotmin * 3); return(lot);}
  
  /*
  Money=lotmin*one_lot_price;
  if(Money>AccountFreeMargin())           // средств не хватает
   {
    Alert ("не хватает денег на ", lot/lotmin, " лотов");
    lot = lotmin;
    return (lot);
   }
   */
  return (lot);
}

//+------------------------------------------------------------------+
//| Нормализация лота                                                |
//+------------------------------------------------------------------+

double NormalizeLots(double lot)
{
   double lotstep = MarketInfo(Symbol(), MODE_LOTSTEP);
   double lots = NormalizeDouble(lot / lotstep, 0) * lotstep;   
   lots = MathMax(lots, MarketInfo(Symbol(), MODE_MINLOT));
   lots = MathMin(lots, MarketInfo(Symbol(), MODE_MAXLOT));   
   return (lots);
}