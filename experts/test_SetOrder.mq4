//+----------------------------------------------------------------------------+
//|                                                         test_SetOrder.mq4  |
//|                                                                            |
//|                                                    Ким Игорь В. aka KimIV  |
//|                                                       http://www.kimiv.ru  |
//|                                                                            |
//|  13.03.2008  Скрипт для тестирования функции SetOrder().                   |
//+----------------------------------------------------------------------------+
#property copyright "Ким Игорь В. aka KimIV"
#property link  "http://www.kimiv.ru"
#property show_confirm

//------- Глобальные переменные -----------------------------------------------+
bool   gbDisabled    = False;          // Флаг блокировки советника
color  clOpenBuy     = LightBlue;      // Цвет значка открытия покупки
color  clOpenSell    = LightCoral;     // Цвет значка открытия продажи
int    Slippage      = 3;              // Проскальзывание цены
int    NumberOfTry   = 5;              // Количество торговых попыток
bool   UseSound      = True;           // Использовать звуковой сигнал
string NameFileSound = "expert.wav";   // Наименование звукового файла

//------- Подключение внешних модулей -----------------------------------------+
#include <stdlib.mqh>                  // Стандартная библиотека


void start() {
//1. Установка ордера BuyLimit лотом 0.1 на 5 пунктов ниже текущей цены
//  SetOrder(NULL, OP_BUYLIMIT, 0.1, Ask-5*Point);

//2. Установка ордера BuyStop лотом 0.3 на 6 пунктов выше текущей цены со стопом 9 пунктов
//  SetOrder(NULL, OP_BUYSTOP, 0.3, Ask+6*Point, Ask+(6-9)*Point);

//3. Установка ордера SellLimit лотом 0.5 на 8 пунктов выше текущей цены со стопом 9 пунктов и тейком 7 пунктов
  SetOrder(NULL, OP_SELLLIMIT, 0.5, Bid+8*Point, Bid+(8+9)*Point, Bid-(8-7)*Point);
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
  int i, k=OrdersTotal(), ty;

  if (sy=="0") sy=Symbol();
  for (i=0; i<k; i++) {
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
//|  Версия   : 01.09.2005                                                     |
//|  Описание : Возвращает наименование торговой операции                      |
//+----------------------------------------------------------------------------+
//|  Параметры:                                                                |
//|    op - идентификатор торговой операции                                    |
//+----------------------------------------------------------------------------+
string GetNameOP(int op) {
  switch (op) {
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
//|  Версия   : 01.09.2005                                                     |
//|  Описание : Возвращает наименование таймфрейма                             |
//+----------------------------------------------------------------------------+
//|  Параметры:                                                                |
//|    TimeFrame - таймфрейм (количество секунд)      (0 - текущий ТФ)         |
//+----------------------------------------------------------------------------+
string GetNameTF(int TimeFrame=0) {
  if (TimeFrame==0) TimeFrame=Period();
  switch (TimeFrame) {
    case PERIOD_M1:  return("M1");
    case PERIOD_M5:  return("M5");
    case PERIOD_M15: return("M15");
    case PERIOD_M30: return("M30");
    case PERIOD_H1:  return("H1");
    case PERIOD_H4:  return("H4");
    case PERIOD_D1:  return("Daily");
    case PERIOD_W1:  return("Weekly");
    case PERIOD_MN1: return("Monthly");
    default:		     return("UnknownPeriod");
  }
}

//+----------------------------------------------------------------------------+
//|  Автор    : Ким Игорь В. aka KimIV,  http://www.kimiv.ru                   |
//+----------------------------------------------------------------------------+
//|  Версия   : 01.09.2005                                                     |
//|  Описание : Вывод сообщения в коммент и в журнал                           |
//+----------------------------------------------------------------------------+
//|  Параметры:                                                                |
//|    m - текст сообщения                                                     |
//+----------------------------------------------------------------------------+
void Message(string m) {
  Comment(m);
  if (StringLen(m)>0) Print(m);
}

//+----------------------------------------------------------------------------+
//|  Автор    : Ким Игорь В. aka KimIV,  http://www.kimiv.ru                   |
//+----------------------------------------------------------------------------+
//|  Версия   : 13.03.2008                                                     |
//|  Описание : Установка ордера.                                              |
//+----------------------------------------------------------------------------+
//|  Параметры:                                                                |
//|    sy - наименование инструмента   (NULL или "" - текущий символ)          |
//|    op - операция                                                           |
//|    ll - лот                                                                |
//|    pp - цена                                                               |
//|    sl - уровень стоп                                                       |
//|    tp - уровень тейк                                                       |
//|    mn - Magic Number                                                       |
//|    ex - Срок истечения                                                     |
//+----------------------------------------------------------------------------+
void SetOrder(string sy, int op, double ll, double pp,
              double sl=0, double tp=0, int mn=0, datetime ex=0) {
  color    clOpen;
  datetime ot;
  double   pa, pb, mp;
  int      err, it, ticket, msl;
  string   lsComm=WindowExpertName()+" "+GetNameTF(Period());

  if (sy=="" || sy=="0") sy=Symbol();
  msl=MarketInfo(sy, MODE_STOPLEVEL);
  if (op==OP_BUYLIMIT || op==OP_BUYSTOP) clOpen=clOpenBuy; else clOpen=clOpenSell;
  if (ex>0 && ex<TimeCurrent()) ex=0;
  for (it=1; it<=NumberOfTry; it++) {
    if (!IsTesting() && (!IsExpertEnabled() || IsStopped())) {
      Print("SetOrder(): Остановка работы функции");
      break;
    }
    while (!IsTradeAllowed()) Sleep(5000);
    RefreshRates();
    ot=TimeCurrent();
    ticket=OrderSend(sy, op, ll, pp, Slippage, sl, tp, lsComm, mn, ex, clOpen);
    if (ticket>0) {
      if (UseSound) PlaySound(NameFileSound); break;
    } else {
      err=GetLastError();
      if (err==128 || err==142 || err==143) {
        Sleep(1000*66);
        if (ExistOrders(sy, op, mn, ot)) {
          if (UseSound) PlaySound(NameFileSound); break;
        }
        Print("Error(",err,") set order: ",ErrorDescription(err),", try ",it);
        continue;
      }
      mp=MarketInfo(sy, MODE_POINT);
      pa=MarketInfo(sy, MODE_ASK);
      pb=MarketInfo(sy, MODE_BID);
      if (pa==0 && pb==0) Message("SetOrder(): Проверьте в обзоре рынка наличие символа "+sy);
      Print("Error(",err,") set order: ",ErrorDescription(err),", try ",it);
      Print("Ask=",pa,"  Bid=",pb,"  sy=",sy,"  ll=",ll,"  op=",GetNameOP(op),
            "  pp=",pp,"  sl=",sl,"  tp=",tp,"  mn=",mn);
      // Неправильные стопы
      if (err==130) {
        switch (op) {
          case OP_BUYLIMIT:
            if (pp>pa-msl*mp) pp=pa-msl*mp;
            if (sl>pp-(msl+1)*mp) sl=pp-(msl+1)*mp;
            if (tp>0 && tp<pp+(msl+1)*mp) tp=pp+(msl+1)*mp;
            break;
          case OP_BUYSTOP:
            if (pp<pa+(msl+1)*mp) pp=pa+(msl+1)*mp;
            if (sl>pp-(msl+1)*mp) sl=pp-(msl+1)*mp;
            if (tp>0 && tp<pp+(msl+1)*mp) tp=pp+(msl+1)*mp;
            break;
          case OP_SELLLIMIT:
            if (pp<pb+msl*mp) pp=pb+msl*mp;
            if (sl>0 && sl<pp+(msl+1)*mp) sl=pp+(msl+1)*mp;
            if (tp>pp-(msl+1)*mp) tp=pp-(msl+1)*mp;
            break;
          case OP_SELLSTOP:
            if (pp>pb-msl*mp) pp=pb-msl*mp;
            if (sl>0 && sl<pp+(msl+1)*mp) sl=pp+(msl+1)*mp;
            if (tp>pp-(msl+1)*mp) tp=pp-(msl+1)*mp;
            break;
        }
        Print("SetOrder(): Скорректированы ценовые уровни");
      }
      // Блокировка работы советника
      if (err==2 || err==64 || err==65 || err==133) {
        gbDisabled=True; break;
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
        ex=0; continue;
      }
      if (err!=135 && err!=138) Sleep(1000*7.7);
    }
  }
}
//+----------------------------------------------------------------------------+

