//+------------------------------------------------------------------+
//|                                             MiniTradeManager.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| библиотека торговых функций mini Trade Manager                   |
//+------------------------------------------------------------------+

// системные переменные торговой библиотеки

MqlTradeRequest    mtm_req;        // структура открытия ордера
MqlTradeResult     mtm_res;        // для хранения результатов

bool OrderOpen (string symbol,
                ENUM_ORDER_TYPE type,double lot,
                double stopLoss,double takeProfit,int deviation=3
                ) 
                   // функция открытия позиции
 {  
   mtm_req.action       = TypeOfOrder(type);                   // тип ордера (немедленный или отложенник)
   mtm_req.symbol       = symbol;                              // символ
   mtm_req.volume       = lot;                                 // лот
   mtm_req.type         = type;                                // тип ордера
   mtm_req.type_filling = ORDER_FILLING_FOK;                   // тип заполнения
   mtm_req.sl=stopLoss;                                        // стоп лосс
   mtm_req.tp=takeProfit;                                      // тейк профит
   mtm_req.deviation=deviation;                                // отклонение
   mtm_req.comment="Everything is okay";                       // комментарий
   if (BuyOrSell (type) )  // если BUY                 
    {
     mtm_req.price   = SymbolInfoDouble(symbol,SYMBOL_ASK);   
    }
   else                    // если SELL
    {
     mtm_req.price   = SymbolInfoDouble(symbol,SYMBOL_BID);
    }
   // отправляем ордер на заявку 
   if(OrderSend(mtm_req,mtm_res))
     {
      Print("Sent...");
     }
   Print("ticket =",mtm_res.order,"   retcode =",mtm_res.retcode);
   if(mtm_res.order != 0)
     {
      datetime tm=TimeCurrent();
      HistorySelect(0,tm);
      string comment;
      bool result=HistoryOrderGetString(mtm_res.order,ORDER_COMMENT,comment);
      if(result)
        {
         Print("ticket:",mtm_res.order,"    Comment:",comment);
        }
      else
        {
         Print("failed");  
         return (false);   // ордер не исполнен
        }
     }
   return (true);   // ордер успешно отправлен на заявку
 }
 
bool PositionOpen(string symbol,
                ENUM_POINTER_TYPE type,double lot,
                double stopLoss,double takeProfit,int deviation=3)  // функиция открывает позицию
 {
  return ( OrderOpen(
 }
 
bool PositionClose() // функция закрытия позиции
 {
  return (false);
 }
 
bool BuyOrSell (ENUM_ORDER_TYPE type) // возвращает true - если buy, и false, если sell
 {
  switch (type)
   {
    case ORDER_TYPE_BUY:
    case ORDER_TYPE_BUY_LIMIT:
    case ORDER_TYPE_BUY_STOP:
    case ORDER_TYPE_BUY_STOP_LIMIT:
     return (true);
   }
  return (false);
 }
 
ENUM_TRADE_REQUEST_ACTIONS TypeOfOrder (ENUM_ORDER_TYPE type) // возвращает тип ордера
 {
  switch (type)
   {
    case ORDER_TYPE_BUY:
    case ORDER_TYPE_SELL:
     return (TRADE_ACTION_DEAL);  // немедленное исполнение
   }
  return (TRADE_ACTION_PENDING);  // отложенник
 }