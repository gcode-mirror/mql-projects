//+------------------------------------------------------------------+
//|                                            DesepticonOpening.mq4 |
//|                                            Copyright © 2013, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
//|  Версия   : 25.02.2013                                           |
//|  Описание : посылает запрос на открытие ордера или позиции       |
//|             в заданном направлении                               |
//+------------------------------------------------------------------+
//|  Параметры:                                                      |
//|    iDirection - направление                                      |
//|    timeframe - таймфрейм                                         |
//+------------------------------------------------------------------+ 
#property copyright "GIA"
#property show_confirm
int DesepticonOpening(int iDirection, int timeframe)
{
 int i, ticket;
 int operation = -1;
 total=OrdersTotal();

 if (iDirection < 0) // Будем ПРОДАВАТЬ по Bid или открывать SELLLIMIT
 {
  if (useLimitOrders) operation = OP_SELLLIMIT;
  else if (useStopOrders) operation = OP_SELLSTOP;
       else operation = OP_SELL;

  if (ExistOrders("", -1, _MagicNumber) || ExistPositions("", -1, _MagicNumber)) // Если есть открытые ордера или позиции
  {
   for (i = total - 1; i >= 0; i--) // Закрываем все ордера или позиции на покупку
   {
    if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
    {
     if (OrderMagicNumber() == _MagicNumber)  
     {
      if (OrderType()==OP_BUY)   // Открыта длинная позиция BUY
      {
       ClosePosBySelect(Bid); // закрываем позицию BUY
       Alert("DesepticonOpening: Закрыли ордер BUY" );
      }
      if (OrderType()==OP_BUYLIMIT || OrderType()==OP_BUYSTOP)
      {
       OrderDelete(OrderTicket(), clDelete);
       Alert("DesepticonOpening: Закрыли ордер BUYLIMIT" );
      }
     }
    }
   }
  }
 } // close Будем ПРОДАВАТЬ
 
 if (iDirection > 0) // Будем ПОКУПАТЬ по Ask или открывать BUYLIMIT
 {
  if (useLimitOrders) operation = OP_BUYLIMIT;
  else if (useStopOrders) operation = OP_BUYSTOP;
  else operation = OP_BUY;

  if (ExistOrders("", -1, _MagicNumber) || ExistPositions("", -1, _MagicNumber)) // Если есть открытые ордера или позиции
  {
   for (i = total - 1; i >= 0; i--) // Закрываем все ордера или позиции на продажу
   {
    if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
    {
     if (OrderMagicNumber() == _MagicNumber)  
     {
      if (OrderType()==OP_SELL)   // Открыта короткая позиция SELL
      {
       ClosePosBySelect(Ask); // закрываем позицию SELL
       Alert("DesepticonOpening: Закрыли ордер SELL" );
      }
      if (OrderType()==OP_SELLLIMIT || OrderType()==OP_SELLSTOP)
      {
       OrderDelete(OrderTicket(), clDelete);
       Alert("DesepticonOpening: Закрыли ордер SELLLIMIT" );
      }
     }
    }
   }
  }
 } // close Будем ПОКУПАТЬ
 
 total=OrdersTotal();
 if (total <= 0)
 {
  if (useLimitOrders || useStopOrders)
  {
   ticket = SetOrder(NULL, operation, openPlace, 0, 0, _MagicNumber);
  } 
  else  ticket = OpenPosition(NULL, operation, stopLoss, takeProfit, openPlace, _MagicNumber);
  if (ticket > 0)
  {
  /*
   OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES); 
   ticket = OrderTicket();
   Alert("Выбрали ордер по тикету. ticket=",ticket," OrderExpiration = ", TimeToStr(OrderExpiration(), TIME_DATE),":",TimeToStr(OrderExpiration(), TIME_MINUTES));
  */ 
   return (ticket);
  }
   else return(-1); // ошибка открытия
 } 
}

//+----------------------------------------------------------------------------+
//+----------------------------------------------------------------------------+
//|  Версия   : 13.03.2008                                                     |
//|  Описание : Установка ордера.                                              |
//+----------------------------------------------------------------------------+
//|  Параметры:                                                                |
//|    symb - наименование инструмента   (NULL или "" - текущий символ)        |
//|    operation - операция                                                    |
//|    price - цена                                                            |
//|    sl - уровень стоп                                                       |
//|    tp - уровень тейк                                                       |
//|    mn - Magic Number                                                       |
//|    expirationTime - Срок истечения                                         |
//+----------------------------------------------------------------------------+
int SetOrder(string symb, int operation, string openPlace, double sl=0, double tp=0, int mn=0, int timeframe = 0)
{
 color    op_color;
 datetime currentTime, expirationTime;
 double   pAsk, pBid, addPrice, vol, price;
 int      err, it, ticket, stopLevel, dg;
 string   lsComm = WindowExpertName()+" "+GetNameTF(Period());
 
 if (symb=="" || symb=="0") symb = Symbol();
 stopLevel=MarketInfo(symb, MODE_STOPLEVEL);
 dg=MarketInfo(symb, MODE_DIGITS);
 vol=MathPow(10.0,dg);
 addPrice=0.0003*vol;
 lots = GetLots();
 
 expirationTime = TimeCurrent() + 2*timeframe*60;
 if (expirationTime > 0 && expirationTime < TimeCurrent()) expirationTime = 0;
 for (it = 1; it <= NumberOfTry; it++)
 {
  if (!IsTesting() && (!IsExpertEnabled() || IsStopped()))
  {
   Print("SetOrder(): Остановка работы функции");
   break;
  }
  while (!IsTradeAllowed()) Sleep(5000);
  RefreshRates();
  pAsk=MarketInfo(symb, MODE_ASK);
  pBid=MarketInfo(symb, MODE_BID);
  switch (operation)
  {
   case OP_BUYLIMIT:
    price = pBid - limitPriceDifference*Point;
    sl = price - stopLoss*Point;
    tp = (pAsk + limitPriceDifference*Point)+takeProfit*Point;
    op_color = clOpenBuy;
    break;
   case OP_SELLLIMIT:
    price = pAsk + limitPriceDifference*Point;
    sl = price + stopLoss*Point;
    tp = (pBid - limitPriceDifference*Point)-takeProfit*Point;
    op_color = clOpenSell;
    break;
   case OP_BUYSTOP:
    price = pAsk + stopPriceDifference*Point;
    sl = (pBid - stopPriceDifference*Point)-stopLoss*Point;
    tp = price + takeProfit*Point;
    op_color = clOpenBuy;
    break;
   case OP_SELLSTOP:
    price = pBid - stopPriceDifference*Point;
    sl = (pAsk + stopPriceDifference*Point)+stopLoss*Point;
    tp = price - takeProfit*Point;
    op_color = clOpenSell;
    break;
  }
  
  price=NormalizeDouble(price, dg);
  currentTime=TimeCurrent();
  ticket=OrderSend(symb, operation, lots, price, Slippage, sl, tp, lsComm, mn, expirationTime, op_color);
  if (ticket>0)
  {
   if (UseSound) PlaySound("expert.wav");
   break;
  }
  else
  {
   err=GetLastError();
   if (err==128 || err==142 || err==143)
   {
    Sleep(1000*66);
    if (ExistOrders(symb, operation, mn, currentTime))
    {
     if (UseSound) PlaySound(NameFileSound); break;
    }
    Print("Error(",err,") set order: ",ErrorDescription(err),", try ",it);
    continue;
   }
   RefreshRates();
   pAsk=MarketInfo(symb, MODE_ASK);
   pBid=MarketInfo(symb, MODE_BID);
   if (pAsk==0 && pBid==0) Message("SetOrder(): Проверьте в обзоре рынка наличие символа "+symb);
   Print("Error(",err,") set order: ",ErrorDescription(err),", try ",it);
   Print("Ask=",pAsk,"  Bid=",pBid, "  symb=",symb,"  lots=",lots,"  operation=",GetNameOP(operation),
         "  price=",price,"  sl=",sl,"  tp=",tp,"  mn=",mn);
   // Неправильные стопы
   if (err==130) {
     switch (operation) {
       case OP_BUYLIMIT:
         if (price > pAsk - stopLevel*Point) price = pAsk - stopLevel*Point;
         if (sl > price - (stopLevel+1)*Point) sl = price - (stopLevel+1)*Point;
         if (tp > 0 && tp < price+(stopLevel+1)*Point) tp = price + (stopLevel+1)*Point;
         break;
       case OP_BUYSTOP:
         if (price < pAsk + (stopLevel+1)*Point) price = pAsk + (stopLevel+1)*Point;
         if (sl > price - (stopLevel+1)*Point) sl = price - (stopLevel+1)*Point;
         if (tp > 0 && tp < price + (stopLevel+1)*Point) tp = price + (stopLevel+1)*Point;
         break;
       case OP_SELLLIMIT:
         if (price < pBid + stopLevel*Point) price = pBid + stopLevel*Point;
         if (sl > 0 && sl < price+(stopLevel+1)*Point) sl = price + (stopLevel+1)*Point;
         if (tp > price - (stopLevel+1)*Point) tp = price - (stopLevel+1)*Point;
         break;
       case OP_SELLSTOP:
         if (price > pBid-stopLevel*Point) price = pBid - stopLevel*Point;
         if (sl > 0 && sl < price + (stopLevel+1)*Point) sl = price + (stopLevel+1)*Point;
         if (tp > price - (stopLevel+1)*Point) tp = price - (stopLevel+1)*Point;
         break;
     }
     Print("SetOrder(): Скорректированы ценовые уровни");
   }
   // Блокировка работы советника
   if (err==2 || err==64 || err==65 || err==133) {
     gbDisabled=true; break;
   }
   // Длительная пауза
   if (err==4 || err==131 || err==132) {
     Sleep(1000*300); break;
   }
   // Слишком частые запросы (8) или слишком много запросов (141)
   if (err==8 || err==141) Sleep(1000*100);
   if (err==139 || err==140 || err==148) break;
   // Ожидание освобождения подсистемы торговли
   if (err==146) while (IsTradeContextBusy()) Sleep(1000*11);
   // Обнуление даты истечения
   if (err==147) {
     expirationTime = 0; continue;
   }
   if (err!=135 && err!=138) Sleep(1000*7.7);
  }
 }
 return(ticket);
}
//+----------------------------------------------------------------------------+