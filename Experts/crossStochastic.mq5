//+------------------------------------------------------------------+
//|                                              crossStochastic.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

input ENUM_MA_METHOD Method = MODE_SMA; // Метод сглаживания

input double slOrder = 200; // Stop Limit
input double tpOrder = 200; // Take Profit
input double orderVolume = 0.1; // Объём сделки
input int kPeriod = 5; // К-период
input int dPeriod = 3; // D-период
input int slov  = 3; // Сглаживание графика. Возможные значения от 1 до 3.

int totalPositions; // общее количество позиций на терминале.
int positionType; // тип открытой позиции на символе.
int stoHandle; // указатель на индикатор.
double stoMain[]; // массив для основной линии.
double stoSignal[]; // массив для сигнальной линии.
double price; // цена открываемой позиции.
double point = Point();
ENUM_ORDER_TYPE orderType; // тип открываемой позиции.

int OnInit()
  {   
   if (Method < 0)
   {
    Print("Error: Не определён метод сглаживания!");
    return(-1);  
   }
   
   stoHandle = iStochastic(NULL, 0, kPeriod, dPeriod, slov, Method, STO_LOWHIGH); // Инициализация указателя.
   if (stoHandle < 0)
   {
    Print("Error: Хэндл (указатель) не инициализирован!", GetLastError());
    return(-1);
   }
   else Print("Инициализация хэндла (указателя) прошла успешно!");
   
   ArraySetAsSeries(stoMain, true); // переопределение направления массива.
   ArraySetAsSeries(stoSignal, true);
   
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   IndicatorRelease(stoHandle);
   Print("Хэндл (указатель) stoHandle очищен");
  }

void OnTick()
  {
   if (CopyBuffer(stoHandle, MAIN_LINE, 0, 50, stoMain) < 0) // заполнение и проверка массива основной линии.
   {
    Print("Ошибка заполнения массива stoMain");
    return;
   }
   if (CopyBuffer(stoHandle, SIGNAL_LINE, 0, 50, stoSignal) < 0) // заполнение и проверка массива сигнальной линии.
   {
    Print("Ошибка заполнения массива stoSignal");
    return;
   }
   
   totalPositions = PositionsTotal();
   positionType = -1;
   orderType = -1;
   
   for (int i = 0; i < totalPositions; i++)
   {
    if (PositionGetSymbol(i) == _Symbol)
    {
     positionType = (int)PositionGetInteger(POSITION_TYPE);
    }
   }
   
   if (((stoMain[2] > 80) && (stoMain[1] < 80)) || ((stoMain[2] >= stoSignal[2]) && (stoSignal[1] > stoMain[1]))) // условия для начала продажи (SELL).
   {
    orderType = ORDER_TYPE_SELL;
   }
   if (((stoMain[2] < 20) && (stoMain[1] > 20)) || ((stoSignal[2] >= stoMain[2]) && (stoMain[1] > stoSignal[1]))) // условия для начала покупки (BUY).
   {
    orderType = ORDER_TYPE_BUY;
   }
   
   if (orderType == ORDER_TYPE_SELL) // если по условию выпал ордер на начало продажи (SELL)
   {
    if (positionType < 0) // ... и если нет открытых позиций
    {
     openPosition(orderType); // ... то открываем одну позицию продажи (SELL)
    }
    if (positionType == POSITION_TYPE_BUY) // если же есть открытая позиция покупки (BUY)
    {
     openPosition(orderType); // ... то закрываем её (т.е. покупку (BUY))
     openPosition(orderType); // ... и открываем продажу (SELL)
    }
    if (positionType == POSITION_TYPE_SELL) // если позиция продажи (SELL) уже открыта
    {
     return; //то дублировать её не нужно
    }
   }
   
   if (orderType == ORDER_TYPE_BUY) // если по условию выпал ордер на начало покупки (BUY)
   {
    if (positionType < 0) // ... и если нет открытых позиций
    {
     openPosition(orderType); // ... то открываем одну позицию покупки (BUY)
    }
    if (positionType == POSITION_TYPE_SELL) // если же есть открытая позиция продажи (SELL)
    {
     openPosition(orderType); // ... то закрываем её (т.е. продажу (SELL))
     openPosition(orderType); // ... и открываем покупку (BUY)
    }
    if (positionType == POSITION_TYPE_BUY) // если позиция покупки (BUY) уже открыта
    {
     return; // то дублировать её не нужно
    }
   }
  }
  
void openPosition (ENUM_ORDER_TYPE ot)
  {
   double sl = slOrder;
   double tp = tpOrder;
   
   switch (ot)
   {
    case ORDER_TYPE_SELL:
    tp = -tp;
    price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    break;
    case ORDER_TYPE_BUY:
    sl = -sl;
    price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   }
   
   MqlTradeRequest request = {0};
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = orderVolume;
   request.price = price;
   
   if (slOrder == 0)
   {
    request.sl = 0;
   }
   else
   {
    request.sl = request.price + sl*point;
   }
   
   if (tpOrder == 0)
   {
    request.tp = 0;
   }
   else
   {
    request.tp = request.price + tp*point;
   }
   
   request.type = ot;
   request.type_filling = ORDER_FILLING_FOK;
   
   MqlTradeResult result = {0};
   
   if (OrderSend(request, result) == false)
   {
    switch (result.retcode)
    {
     case 10004:
     Print("Error: TRADE_RETCODE_REQUOTE (Реквота)");
     Print("request.price = ", request.price, " || result.ask = ", result.ask, " || result.bid = ", result.bid);
     break;
     case 10014:
     Print("Error: TRADE_RETCODE_INVALID_VOLUME (Неправильный объём в запросе)");
     Print("request.volume = ", request.volume, " || result.volume = ", result.volume);
     break;
     case 10015:
     Print("Error: TRADE_RETCODE_INVALID_PRICE (Неправильная цена в запросе)");
     Print("request.price = ", request.price, " || result.ask = ", result.ask, " || result.bid = ", result.bid);
     break;
     case 10016:
     Print("Error: TRADE_RETCODE_INVALID_STOPS (Неправильные стопы в запросе)");
     Print("request.sl = ", request.sl, " || request.tp = ", request.tp, " || result.ask = ", result.ask, " || result.bid = ", result.bid);
     break;
     case 10019:
     Print("Error: TRADE_RETCODE_NO_MONEY (Нет достаточных денежных средств для выполнения запроса)");
     Print("request.volume = ", request.volume, " || result.volume = ", result.volume, " || result.comment = ", result.comment);
     break;
    }
   }
  }