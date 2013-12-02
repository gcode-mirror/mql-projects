//+------------------------------------------------------------------+
//|                                                AddOnFuctions.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+

//+----------------------------------------------------------------------------+
//|  Версия   : 11.02.2013                                                     |
//|  Описание : Возвращает значение в зависимости от того, какой дабл больше   |
//+----------------------------------------------------------------------------+
//|  Параметры:                                                                |
//|    arg1 - аргумент 1                                                       |
//|    arg2 - аргумент 2                                                       |
//+----------------------------------------------------------------------------+ 
int GreatDouble(double arg1, double arg2)
{
 if(NormalizeDouble(arg1 - arg2, 8) > 0) return(1);
 else if (NormalizeDouble(arg1 - arg2, 8) < 0) return(-1);
      else return(0); 
}

//+----------------------------------------------------------------------------+
//|  Версия   : 11.02.2013                                                     |
//|  Описание : Возвращает значение в зависимости от того, какой дабл больше   |
//+----------------------------------------------------------------------------+
//|  Параметры:                                                                |
//|    arg1 - аргумент 1                                                       |
//|    arg2 - аргумент 2                                                       |
//+----------------------------------------------------------------------------+ 
int LessDouble(double arg1, double arg2)
{
 if(NormalizeDouble(arg2 - arg1, 8) > 0) return(1);
 else if (NormalizeDouble(arg2 - arg1, 8) < 0) return(-1);
      else return(0); 
}
//+----------------------------------------------------------------------------+
//|  Версия   : 20.11.2012                                                     |
//|  Описание : возвращает знак значения аргумента                             |
//+----------------------------------------------------------------------------+
//|  Параметры:                                                                |
//|    v - аргумент                                                            |
//+----------------------------------------------------------------------------+
int sign( double v )
{
    if( v < 0 ) return( -1 );
    return( 1 );
}

//+----------------------------------------------------------------------------+
//|  Версия   : 20.11.2012                                                     |
//|  Описание : эквивалент оператора языка С "condition ? ifTrue : ifFalse"    |
//+----------------------------------------------------------------------------+
//|  Параметры:                                                                |
//|    condition - проверяемое условие                                         |
//|    ifTrue - значение возвращаемое при выполнении условия                   |
//|    ifFalse - значение возвращаемое при НЕ выполнении условия               |
//+----------------------------------------------------------------------------+ 
double iif( bool condition, double ifTrue, double ifFalse )
{
    if( condition ) return( ifTrue );
    
    return( ifFalse );
}

//+----------------------------------------------------------------------------+
//|  Версия   : 20.11.2012                                                     |
//|  Описание : эквивалент оператора языка С "condition ? ifTrue : ifFalse"    |
//+----------------------------------------------------------------------------+
//|  Параметры:                                                                |
//|    condition - проверяемое условие                                         |
//|    ifTrue - значение возвращаемое при выполнении условия                   |
//|    ifFalse - значение возвращаемое при НЕ выполнении условия               |
//+----------------------------------------------------------------------------+ 
string iifStr( bool condition, string ifTrue, string ifFalse )
{
    if( condition ) return( ifTrue );
    
    return( ifFalse );
}

//+----------------------------------------------------------------------------+
//|  Версия   : 20.11.2012                                                     |
//|  Описание : Возвращает направление ордера                                  |
//+----------------------------------------------------------------------------+
//+----------------------------------------------------------------------------+ 
int orderDirection()
{
    return( 1 - 2 * ( OrderType() % 2 ) );
}

//+----------------------------------------------------------------------------+
//|  Версия   : 20.11.2012                                                     |
//|  Описание : Вывод сообщения в журнал в случае нарушения логики             |
//+----------------------------------------------------------------------------+
//|  Параметры:                                                                |
//|    functionName - имя функции с нарушением логики                          |
//|    assertion - логическое условие                                          |
//|    description - текст сообщения                                           |
//+----------------------------------------------------------------------------+
void assert(string functionName, bool assertion, string description = "")
{
 if(!assertion) 
  Print("ASSERT: in " + functionName + "() - " + description);
}

//+----------------------------------------------------------------------------+
//+----------------------------------------------------------------------------+
//|  Версия   : 01.09.2005                                                     |
//|  Описание : Вывод сообщения в коммент и в журнал                           |
//+----------------------------------------------------------------------------+
//|  Параметры:                                                                |
//|    m - текст сообщения                                                     |
//+----------------------------------------------------------------------------+
void Message(string m)
{
 Comment(m);
 if (StringLen(m)>0) Print(m);
} 

//+----------------------------------------------------------------------------+
//+----------------------------------------------------------------------------+
//|  Версия   : 01.09.2005                                                     |
//|  Описание : Возвращает наименование таймфрейма                             |
//+----------------------------------------------------------------------------+
//|  Параметры:                                                                |
//|    TimeFrame - таймфрейм (количество секунд)      (0 - текущий ТФ)         |
//+----------------------------------------------------------------------------+
string GetNameTF(int TimeFrame=0)
{
 if (TimeFrame==0) TimeFrame=Period();
 switch (TimeFrame)
 {
  case PERIOD_M1:  return("M1");
  case PERIOD_M5:  return("M5");
  case PERIOD_M15: return("M15");
  case PERIOD_M30: return("M30");
  case PERIOD_H1:  return("H1");
  case PERIOD_H4:  return("H4");
  case PERIOD_D1:  return("Daily");
  case PERIOD_W1:  return("Weekly");
  case PERIOD_MN1: return("Monthly");
  default:         return("UnknownPeriod");
 }
}

//+----------------------------------------------------------------------------+
//+----------------------------------------------------------------------------+
//|  Версия   : 01.09.2005                                                     |
//|  Описание : Возвращает наименование торговой операции                      |
//+----------------------------------------------------------------------------+
//|  Параметры:                                                                |
//|    op - идентификатор торговой операции                                    |
//+----------------------------------------------------------------------------+
string GetNameOP(int op)
{
 switch (op)
 {
  case OP_BUY      : return("Buy");
  case OP_SELL     : return("Sell");
  case OP_BUYLIMIT : return("Buy Limit");
  case OP_SELLLIMIT: return("Sell Limit");
  case OP_BUYSTOP  : return("Buy Stop");
  case OP_SELLSTOP : return("Sell Stop");
  default          : return("Unknown Operation");
 }
}

//+----------------------------------------------------------------------------+
//|  Автор    : Ким Игорь В. aka KimIV,  http://www.kimiv.ru                   |
//+----------------------------------------------------------------------------+
//|  Версия   : 12.03.2008                                                     |
//|  Описание : Возвращает флаг существования ордеров.                         |
//+----------------------------------------------------------------------------+
//|  Параметры:                                                                |
//|    sy - наименование инструмента   (""   - любой символ,                   |
//|                                     NULL - текущий символ)                 |
//|    op - операция                   (-1   - любой ордер)                    |
//|    mn - MagicNumber                (-1   - любой магик)                    |
//|    ot - время открытия             ( 0   - любое время установки)          |
//+----------------------------------------------------------------------------+
bool ExistOrders(string sy="", int op=-1, int mn=-1, datetime ot=0) {
  int i, total=OrdersTotal(), ty;

  if (sy=="0") sy=Symbol();
  for (i=0; i<total; i++) {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      ty=OrderType();
      if (ty>1 && ty<6) {
        if ((OrderSymbol()==sy || sy=="") && (op<0 || ty==op)) {
          if (mn<0 || OrderMagicNumber()==mn) {
            if (ot<=OrderOpenTime()) return(True);
          }
        }
      }
    }
  }
  return(False);
}

//+----------------------------------------------------------------------------+
//|  Автор    : Ким Игорь В. aka KimIV,  http://www.kimiv.ru                   |
//+----------------------------------------------------------------------------+
//|  Версия   : 06.03.2008                                                     |
//|  Описание : Возвращает флаг существования позиций                          |
//+----------------------------------------------------------------------------+
//|  Параметры:                                                                |
//|    sy - наименование инструмента   (""   - любой символ,                   |
//|                                     NULL - текущий символ)                 |
//|    op - операция                   (-1   - любая позиция)                  |
//|    mn - MagicNumber                (-1   - любой магик)                    |
//|    ot - время открытия             ( 0   - любое время открытия)           |
//+----------------------------------------------------------------------------+
bool ExistPositions(string sy="", int op=-1, int mn=-1, datetime ot=0) {
  int i, total=OrdersTotal();

  if (sy=="0") sy=Symbol();
  for (i=0; i<total; i++) {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      if (OrderSymbol()==sy || sy=="") {
        if (OrderType()==OP_BUY || OrderType()==OP_SELL) {
          if (op<0 || OrderType()==op) {
            if (mn<0 || OrderMagicNumber()==mn) {
              if (ot<=OrderOpenTime()) return(True);
            }
          }
        }
      }
    }
  }
  return(False);
}

//+----------------------------------------------------------------------------+
//|  Версия   :                                                      |
//|  Описание : Открывает позицию и возвращает её тикет.                       |
//+----------------------------------------------------------------------------+
//|  Параметры:                                                                |
//|    symb - наименование инструмента   (NULL или "" - текущий символ)        |
//|    operation - операция                                                    |
//|    Lots - лот                                                              |
//|    sl - уровень стоп                                                       |
//|    tp - уровень тейк                                                       |
//|    mn - MagicNumber                                                        |
//+----------------------------------------------------------------------------+
int OpenPosition(string symb, int operation, int stopLoss = 0, int takeProfit = 0, string openPlace = "", int mn=0, string lsComm="")
 {
  Alert("Открываем позицию");
  color op_color;
  datetime currentTime, expirationTime;
  double price, pAsk, pBid, vol, addPrice;
  int dg, err, it, ticket=0;
  double sl, tp;
  
  lots = GetLots();
   
  if (symb=="" || symb=="0") symb=Symbol();
  if (lsComm=="" || lsComm=="0") lsComm=WindowExpertName()+" "+GetNameTF(Period()) + " " + openPlace;
  dg=MarketInfo(symb, MODE_DIGITS);
  vol=MathPow(10.0,dg);
  addPrice=0.0003*vol;

  switch (operation)
  {
   case OP_BUY:
   {
    sl = iif (stopLoss > 0, Bid-stopLoss*Point, 0);
    tp = iif (takeProfit > 0, Ask+takeProfit*Point, 0);
    op_color = clOpenBuy;
    break;
   }
  
   case OP_SELL:
   {
    sl = iif (stopLoss > 0, Ask+stopLoss*Point, 0);
    tp = iif (takeProfit > 0, Bid-takeProfit*Point, 0);
    op_color = clOpenSell;
    break;
   }
  } // close switch
  
  for (it=1; it<=NumberOfTry; it++)
  {
   if (!IsTesting() && (!IsExpertEnabled() || IsStopped()))
   {
     Alert("OpenPosition(): Остановка работы функции");
     break;
   }
   while (!IsTradeAllowed()) Sleep(5000);
   RefreshRates();
   pAsk=MarketInfo(symb, MODE_ASK);
   pBid=MarketInfo(symb, MODE_BID);
   switch (operation)
   {
    case OP_BUY: {price = pAsk; break;}
    case OP_SELL: {price = pBid; break;}
   }
   price=NormalizeDouble(price, dg);
   currentTime=TimeCurrent();
   Alert("stopLoss=", sl, " takeProfit =",tp);
   ticket=OrderSend(symb, operation, lots, price, Slippage, 0, 0, lsComm, mn, 0, op_color);
   if (ticket > 0)
   {
    if (UseSound) PlaySound("expert.wav");
    if(tp != 0 || sl != 0)
     if(OrderSelect(ticket, SELECT_BY_TICKET))
      ModifyOrder(-1, sl, tp);
    break;
   }
   else
   {
    err=GetLastError();
    if (pAsk==0 && pBid==0) Message("Проверьте в Обзоре рынка наличие символа "+symb);
    // Вывод сообщения об ошибке
    Print("Error(",err,") opening position: ",ErrorDescription(err),", try ",it);
    Print("Ask=",pAsk," Bid=",pBid," symb=",symb," Lots=",lots," operation=",GetNameOP(operation),
          " price=",price," sl=",sl," tp=",tp," mn=",mn);
    // Блокировка работы советника
    if (err==2 || err==64 || err==65 || err==133) {
      gbDisabled=True; break;
    }
    // Длительная пауза
    if (err==4 || err==131 || err==132) {
      Sleep(1000*300); break;
    }
    if (err==128 || err==142 || err==143) {
      Sleep(1000*66.666);
      if (ExistPositions(symb, operation, mn, currentTime)) {
        if (UseSound) PlaySound("expert.wav"); break;
      }
    }
    if (err==140 || err==148 || err==4110 || err==4111) break;
    if (err==141) Sleep(1000*100);
    if (err==145) Sleep(1000*17);
    if (err==146) while (IsTradeContextBusy()) Sleep(1000*11);
    if (err!=135) Sleep(1000*7.7);
   }
  } // close for
  return(ticket);
}

//+----------------------------------------------------------------------------+
//|  Автор    : Ким Игорь В. aka KimIV,  http://www.kimiv.ru                   |
//+----------------------------------------------------------------------------+
//|  Версия   : 28.11.2006                                                     |
//|  Описание : Модификация одного предварительно выбранного ордера.           |
//+----------------------------------------------------------------------------+
//|  Параметры:                                                                |
//|    pp - цена установки ордера                                              |
//|    sl - ценовой уровень стопа                                              |
//|    tp - ценовой уровень тейка                                              |
//|    cl - цвет значка модификации                                            |
//+----------------------------------------------------------------------------+
void ModifyOrder(double pp=-1, double sl=0, double tp=0, color cl=CLR_NONE) {
  bool   fm;
  double op, pa, pb, os, ot;
  int    dg=MarketInfo(OrderSymbol(), MODE_DIGITS), er, it;
 
  if (pp<=0) pp=OrderOpenPrice();
  if (sl<=0 ) sl=OrderStopLoss();
  if (tp<=0 ) tp=OrderTakeProfit();
  
  pp=NormalizeDouble(pp, dg);
  sl=NormalizeDouble(sl, dg);
  tp=NormalizeDouble(tp, dg);
  op=NormalizeDouble(OrderOpenPrice() , dg);
  os=NormalizeDouble(OrderStopLoss()  , dg);
  ot=NormalizeDouble(OrderTakeProfit(), dg);
 
  if (pp!=op || sl!=os || tp!=ot) {
    for (it=1; it<=NumberOfTry; it++) {
      if (!IsTesting() && (!IsExpertEnabled() || IsStopped())) break;
      while (!IsTradeAllowed()) Sleep(5000);
      RefreshRates();
      fm=OrderModify(OrderTicket(), pp, sl, tp, 0, cl);
      if (fm) {
        if (UseSound) PlaySound(NameFileSound); break;
      } else {
        er=GetLastError();
        pa=MarketInfo(OrderSymbol(), MODE_ASK);
        pb=MarketInfo(OrderSymbol(), MODE_BID);
        Print("Error(",er,") modifying order: ",ErrorDescription(er),", try ",it);
        Print("Ask=",pa,"  Bid=",pb,"  sy=",OrderSymbol(),
              "  op="+GetNameOP(OrderType()),"  pp=",pp,"  sl=",sl,"  tp=",tp);
        Sleep(1000*10);
      }
    }
  }
}

//+----------------------------------------------------------------------------+
//|  Автор    : GIA                                                            |
//+----------------------------------------------------------------------------+
//|  Версия   : 10.01.2013                                                     |
//|  Описание : Удаение одной предварительно выбранной позиции.                |
//+----------------------------------------------------------------------------+
//|  Параметры:                                                                |
//|    pp - цена установки ордера                                              |
//+----------------------------------------------------------------------------+
void ClosePosBySelect(double pp=-1, string comment = "")
 {
  bool   fc;
  color  clClose;
  double pa, pb;
  int    err, it;

  if (OrderType()==OP_BUY || OrderType()==OP_SELL)
  {
   for (it=1; it<=NumberOfTry; it++)
   {
    if (!IsTesting() && (!IsExpertEnabled() || IsStopped())) break;
    while (!IsTradeAllowed()) Sleep(5000);
    
    RefreshRates();
    
    if (pp < 0)
    {
     if (OrderType()==OP_BUY)
     {
      pp=MarketInfo(OrderSymbol(), MODE_BID);
      clClose=Violet;
     }
     else
     {
      pp=MarketInfo(OrderSymbol(), MODE_ASK);
      clClose=Violet;
     }
    } 
    fc=OrderClose(OrderTicket(), OrderLots(), pp, Slippage, clClose);
    
    if (fc)
    {
     if (UseSound) PlaySound(NameFileSound);
     if (comment !="") Alert(comment);
     break;
    }
    else
    {
     err=GetLastError();
     if (err==146) while (IsTradeContextBusy()) Sleep(1000*11);
     Print("Error(",err,") Close ",GetNameOP(OrderType())," ", ErrorDescription(err),", try ",it);
     Print(OrderTicket(),"  Ask=",Ask,"  Bid=",Bid,"  pp=",pp);
     Print("sy=",OrderSymbol(),"  ll=",OrderLots(),"  sl=",OrderStopLoss(), "  tp=",OrderTakeProfit(),"  mn=",OrderMagicNumber());
     Sleep(1000*5);
    }
   }
  }
  else
  {
   Print("Некорректная торговая операция. Close ",GetNameOP(OrderType()));
  }
 }

//+----------------------------------------------------------------------------+
//+----------------------------------------------------------------------------+
//| Версия   :                                                      |
//| Описание : Удаление ордеров. Версия функции для тестов на истории.         |
//+----------------------------------------------------------------------------+
//| Параметры:                                                                 |
//| symb - наименование инструмента   (NULL - текущий символ)                    |
//| operation - операция                   ( -1  - любой ордер)                       |
//| magic - MagicNumber                ( -1  - любой магик)                       |
//+----------------------------------------------------------------------------+
void DeleteOrders(string symb="", int operation=-1, int magic=-1) 
{
 int i;
 total=OrdersTotal();
 int orderType;

 if (symb=="" || symb=="0") symb=Symbol();
 for (i = 0; i < total; i++)
 {
  if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
  {
   orderType=OrderType();
   if (orderType==OP_BUYLIMIT || orderType==OP_BUYSTOP || orderType==OP_SELLLIMIT || orderType==OP_SELLSTOP)
   {
    if (OrderSymbol()==symb && (operation<0 || orderType==operation))
    {
     if (magic<0 || OrderMagicNumber()==magic) 
     {
      OrderDelete(OrderTicket(), clDelete);
     }
    }
   }
  }
 }
}

