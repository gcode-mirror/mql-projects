//+------------------------------------------------------------------+
//|                                                     crossEMA.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

input double orderVolume = 0.1;
input double stopLoss = 200;
input double takeProfit = 200;
input ulong magic = 01;

double maFast[]; // массив для индикатора iMA (Moving Average)
double maAverage[];
double maLow[];
int maHandleFast; // указатель на индикатор iMA
int maHandleAverage;
int maHandleLow;
string symbol = Symbol();
double price;
double point = Point();
ENUM_ORDER_TYPE orderType;
int positionType;
double volume;
int total;

int OnInit()
  {
   ArraySetAsSeries(maFast, true); // разметка массива MA[] в обратном порядке
   ArraySetAsSeries(maAverage, true);
   ArraySetAsSeries(maLow, true); 
      
   maHandleFast = iMA(NULL, 0, 3, 0, MODE_EMA, PRICE_CLOSE); // инициализация указателя
   maHandleAverage = iMA(NULL, 0, 12, 0, MODE_EMA, PRICE_CLOSE);
   maHandleLow = iMA(NULL, 0, 26, 0, MODE_EMA, PRICE_CLOSE);
   
   if (maHandleAverage < 0 || maHandleFast < 0 || maHandleLow < 0)
   {
    Print("Объект iMA не создан: Ошибка исполнения = ", GetLastError());
    return(-1);
   }
   else Print("Указатели инициализированы.");
   Print("StopLoss = ", stopLoss, " || TakeProfit = ", takeProfit);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   IndicatorRelease(maHandleAverage);
   Print("maHandleAverage clear...");
   IndicatorRelease(maHandleFast);
   Print("maHandleFast clear...");
   IndicatorRelease(maHandleLow);
   Print("maHandleLow clear...");   
  }

void OnTick()
  {   
   if (CopyBuffer(maHandleFast, 0, 0, 200, maFast) < 1)
   {
    Print("Ошибка заполнения массива maFast из буфера");
    return;
   }
   if (CopyBuffer(maHandleAverage, 0, 0, 200, maAverage) < 1)
   {
    Print("Ошибка заполнения массива maAverage из буфера");
    return;
   }
   if (CopyBuffer(maHandleLow, 0, 0, 200, maLow) < 1)
   {
    Print("Ошибка заполнения массива maLow из буфера");
    return;
   }
   
   double symbAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double symbBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);   

   total = PositionsTotal();
   orderType = -1;
   positionType = -1;
   
   for (int i = 0; i < total; i++)
   {
    if (PositionGetSymbol(i) == _Symbol)
    {
     positionType = (int)PositionGetInteger(POSITION_TYPE);
    }    
   }
   
   if((maAverage[2] >= maLow[2]) && (maLow[1] > maAverage[1]) && (symbBid > maFast[1]))
   {
    price = symbBid;
    orderType = ORDER_TYPE_SELL; // будем открывать продажу
   }
   
   if ((maLow[2] >= maAverage[2]) && (maAverage[1] > maLow[1]) && (symbAsk < maFast[1]))
   {
    price = symbAsk;
    orderType = ORDER_TYPE_BUY; // будем открывать покупку
   }
   
   if (orderType == ORDER_TYPE_SELL) // если по условию нужно открыть SELL
   {
    if (positionType < 0) // а открытых позиций нет
    {
     openPosition(orderType, price); // то открвыается позиция SELL
    }
    if (positionType == POSITION_TYPE_BUY) // если открыта позиция BUY
    {
     openPosition(orderType, price); // то закрывается BUY
     openPosition(orderType, price); // и открывается SELL
    }
    if (positionType == POSITION_TYPE_SELL) // если же открыта позиция SELL
    {
     return; // то повторное открытие SELL не требуется     
    }
   }
   
   if (orderType == ORDER_TYPE_BUY) // если тип сделки определён как BUY
   {
    if (positionType < 0) // а открытых позиций нет
    {
     openPosition(orderType, price); // то открвыается позиция BUY
    }
    if (positionType == POSITION_TYPE_SELL) // если открыта позиция SELL
    {
     openPosition(orderType, price); // то закрывается SELL
     openPosition(orderType, price); // и открывается BUY
    }
    if (positionType == POSITION_TYPE_BUY) // если же открыта позиция BUY
    {
     return; // то повторное открытие BUY не требуется     
    }
   }

  }
   
  void openPosition (ENUM_ORDER_TYPE ot, double pricePosition)
  {
   double sl = stopLoss, tp = takeProfit;
   
   switch (ot)
   {
    case ORDER_TYPE_BUY:
    sl = -sl;
    break;
    case ORDER_TYPE_SELL:
    tp = -tp;
    break;   
   }
   
   MqlTradeRequest request;
   ZeroMemory(request);
   request.action = TRADE_ACTION_DEAL;
   request.magic = magic;
   request.symbol = _Symbol;
   request.volume = orderVolume;
   request.price = pricePosition;
   
   if (stopLoss == 0)
   {
    request.sl = 0;
   }
   else request.sl = request.price + sl*point;
   
   if (takeProfit == 0)
   {
    request.tp = 0;
   }
   else request.tp = request.price + tp*point;
   
   request.type = ot;
   request.type_filling = ORDER_FILLING_FOK;   
   MqlTradeResult result={0};
     
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