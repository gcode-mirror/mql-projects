//+------------------------------------------------------------------+
//|                                                       CDinya.mq4 |
//|                                                              GIA |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "GIA"

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
 if(NormalizeDouble(arg1 - arg2, 5) > 0) return(1);
 else if (NormalizeDouble(arg1 - arg2, 5) < 0) return(-1);
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
 if(NormalizeDouble(arg2 - arg1, 5) > 0) return(1);
 else if (NormalizeDouble(arg2 - arg1, 5) < 0) return(-1);
      else return(0); 
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

int _deltaFast;     // дельта для расчета объема "дневной" торговли
int _deltaSlow;     // дельта для расчета объема "месячной" торговли
double _fastVol;   // объем для дневной торговли
double _slowVol;   // объем для месячной торговли
 
double _startDayPrice;   // цена начала торгов текущего дня
double _prevDayPrice;   // текущий уровень цены дня
double _prevMonthPrice; // текущий уровень цены месяца
 

//+------------------------------------------------------------------+
//| Инициализация параметров для торговли с первого дня              |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void InitDayTrade()
{
 if (timeToUpdateFastDelta()) // Если случился новый день
 {
  Print("Новый день ", TimeDay(m_last_day_number));
  if (direction * _startDayPrice > direction * Bid)
  {
   _deltaFast = 0;
   isDayInit = false;
   dayDeltaChanged = true;
  }
  else
  {
   _startDayPrice = Bid;
   _deltaFast = fastDelta;
   isDayInit = true;
   dayDeltaChanged = true;
  } 
  
  _prevDayPrice = Bid;
  _slowVol = NormalizeDouble(volume * factor * _deltaSlow, 2);
  _fastVol = NormalizeDouble(_slowVol * _deltaFast * factor * percentage * factor, 2);
  
  Print("Закрываем все позиции в начале дня");
  double volume = ClosePositionsWithCalcLots();
  if (volume > 0)
  {
   Print("Объем закрытых позиций = ", volume, "откроем позицию на этот объем");
   int operation = iif (volume > 0, 0, 1);
   OpenPosition(symbol, operation, volume, _magic);
  }
 }
}

//+------------------------------------------------------------------+
//| Инициализация параметров для торговли с первого месяца           |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void InitMonthTrade()
{
 if(isNewMonth())
 {
  Print(" Новый месяц ", TimeMonth(m_last_month_number));
  _deltaSlow = slowDelta;
  _startDayPrice = Bid;
  _prevMonthPrice = Bid;
  _slowVol = NormalizeDouble(volume * _deltaSlow * factor, 2);
  isMonthInit = true;
  monthDeltaChanged = true;
 }
}

//+------------------------------------------------------------------+
//| Пересчет значений дневной дельта                                 |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void RecountDayDelta()
{
 double currentPrice = Bid;
 if (direction*(_deltaFast - 50) < 50 && GreatDouble(currentPrice, _prevDayPrice + dayStep*Point) == 1) // _dir = 1 : delta < 100; _dir = -1 : delta > 0
 {
  //Print("currentPrice", currentPrice, "> _prevDayPrice - dayStep*Point=", _prevDayPrice + dayStep*Point);
  Print("Цена сделала шаг ВВЕРХ внутри дня, стараяДельтаДня=", _deltaFast, " новаяДельтаДня=", _deltaFast + fastDeltaStep);
  _prevDayPrice = currentPrice;
  _deltaFast = _deltaFast + direction*fastDeltaStep;
  dayDeltaChanged = true;
 }
 if ((direction*_deltaFast + 50) > (direction*50) && LessDouble(currentPrice, _prevDayPrice - dayStep*Point) == 1) // _dir = 1 : delta > 0; _dir = -1 : delta < 100
 {
  //Print("currentPrice", currentPrice, "< _prevDayPrice - dayStep*Point=", _prevDayPrice - dayStep*Point);
  Print("Цена сделала шаг ВНИЗ внутри дня, стараяДельтаДня=", _deltaFast, " новаяДельтаДня=", _deltaFast - fastDeltaStep);
  _prevDayPrice = currentPrice;
  _deltaFast = _deltaFast - direction*fastDeltaStep;
  dayDeltaChanged = true;
 }
}

//+------------------------------------------------------------------+
//| Пересчет значений месячной дельта                                |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void RecountMonthDelta()
{
 double currentPrice = Bid;
 if (direction*(_deltaSlow - 50) < 50 && GreatDouble(currentPrice, _prevMonthPrice + monthStep*Point) == 1)
 {
  _prevMonthPrice = currentPrice;
  Print("Цена сделала шаг ВВЕРХ внутри месяца");
  if (direction < 0 && _deltaSlow < slowDelta)
  {
   _deltaSlow = slowDelta;
  }
  else
  {
   _deltaSlow = _deltaSlow + direction*slowDeltaStep;
  }
  monthDeltaChanged = true;
 }
 if ((direction*_deltaSlow + 50) > (direction*50) && LessDouble(currentPrice, _prevMonthPrice - monthStep*Point) == 1)
 {
  _prevMonthPrice = currentPrice;
  Print("Цена сделала шаг ВНИЗ внутри месяца");
  if (direction > 0 && _deltaSlow > slowDelta)
  {
   _deltaSlow = slowDelta;
  }
  else
  {
   _deltaSlow = _deltaSlow - direction*slowDeltaStep;
  }
  monthDeltaChanged = true;
 }
}

//+------------------------------------------------------------------+
//| Пересчет объемов торга на основании новых дельта                 |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
double RecountVolume()
{
 _slowVol = NormalizeDouble(volume * factor * _deltaSlow, 2);
 _fastVol = NormalizeDouble(_slowVol * _deltaFast * factor * percentage * factor, 2);
 monthDeltaChanged = false;
 dayDeltaChanged = false;
 return (_slowVol - _fastVol); 
}

//+------------------------------------------------------------------+
//| Пересчет объемов торга на основании новых дельта                 |
//| INPUT:  double volume.                                           |
//| OUTPUT: result of correction - true or false                     |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CorrectOrder(double volume)
{
 if (volume == 0) return(false);
 
 int type, i, count = 0;
 double price;
 int total=OrdersTotal();
 
 if (volume > 0)                                     // Объем увеличился
 {
  if (useOrder == OP_BUY)
  {
   price = Ask;
   type = OP_BUY;
  }
  else
  {
   price = Bid;
   type = OP_SELL;
  }
 }
 else // Если объем меньше нуля
 {
  if (useOrder == OP_BUY)
  {
   price = Bid;
   type = OP_SELL;
  }
  else
  {
   price = Ask;
   type = OP_BUY;
  }
 }
 
 Print("Корректируем позицию на объем= ", volume);
 return(OpenPosition(NULL, type, MathAbs(volume), _magic));
 
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
//|  Версия   :                                                                |
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
int OpenPosition(string symb, int operation, double volume, int mn=0, int stopLoss = 0, int takeProfit = 0, string openPlace = "", string lsComm="")
 {
  Alert("Открываем позицию");
  color op_color;
  datetime currentTime, expirationTime;
  double price, pAsk, pBid, vol, addPrice;
  int dg, err, it, ticket=0;
  double sl, tp;
     
  if (symb=="" || symb=="0") symb=Symbol();
  if (lsComm=="" || lsComm=="0") lsComm=WindowExpertName()+" "+GetNameTF(Period()) + " " + openPlace;
  dg=MarketInfo(symb, MODE_DIGITS);
  vol=MathPow(10.0,dg);
  addPrice=0.0003*vol;

  switch (operation)
  {
   case OP_BUY:
   {
    op_color = Red;
    break;
   }
   case OP_SELL:
   {
    op_color = Green;
    break;
   }
  } // close switch
  
  for (it = 1; it <= 5; it++)
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
   ticket=OrderSend(symb, operation, volume, price, 3, 0, 0, lsComm, mn, 0, op_color);
   if (ticket > 0)
   {
    break;
   }
   else
   {
    err=GetLastError();
    if (pAsk==0 && pBid==0) Print("Проверьте в Обзоре рынка наличие символа "+symb);
    // Вывод сообщения об ошибке
    Print("Error(",err,") opening position: ",ErrorDescription(err),", try ",it);
    Print("Ask=",pAsk," Bid=",pBid," symb=",symb," Lots=",volume," operation=",GetNameOP(operation),
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
      if (ExistPositions(symb, operation, mn, currentTime))
      {
       break;
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
//|  Автор    : GIA                                                            |
//+----------------------------------------------------------------------------+
//|  Версия   : 04.12.2013                                                     |
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
   for (it = 1; it <= 5; it++)
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
    fc=OrderClose(OrderTicket(), OrderLots(), pp, 3, clClose);
    
    if (fc)
    {
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
 
 //+---------------------------------------------------------------------------+
//|  Автор    : GIA                                                            |
//+----------------------------------------------------------------------------+
//|  Версия   : 04.12.2013                                                     |
//|  Описание : Закрытие позиций по рыночной цене                              |
//+----------------------------------------------------------------------------+
//+----------------------------------------------------------------------------+
double ClosePositionsWithCalcLots()
{
 int total = OrdersTotal();
 double lotsTotal;
 for (int i = total - 1; i >= 0; i--)
 {
  if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) 
  {
   if (OrderMagicNumber() == _magic)  
   {
    if (OrderType() == OP_BUY) lotsTotal+=OrderLots();
    if (OrderType() == OP_SELL)lotsTotal-=OrderLots(); 
   }
   ClosePosBySelect();
  }
 }
 return (lotsTotal);
}


