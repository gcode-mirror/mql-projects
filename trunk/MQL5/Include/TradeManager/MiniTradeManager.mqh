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


// создает ордер и возвращает его тикет в случае успеха
ulong OrderCreate (string symbol, ENUM_ORDER_TYPE type,
                                 double lot, double stopLoss,double takeProfit,
                                 double price,int deviation=3, string comment="ok")
 {
  ulong ticket = 0;
  MqlTradeRequest mtr;
  MqlTradeResult  mt_res;
  mtr.action          = TypeOfOrder(type);
  mtr.symbol          = symbol;
  mtr.volume          = lot;
  mtr.type_filling    = ORDER_FILLING_FOK;
  mtr.sl              = stopLoss;
  mtr.tp              = takeProfit;
  mtr.deviation       = deviation;
  mtr.comment         = comment; 
  mtr.type            = type;
  
    
   if (BuyOrSell (type) )  // если BUY                 
    {
     if ( type == ORDER_TYPE_BUY || type == ORDER_TYPE_SELL) 
      mtr.price   = SymbolInfoDouble(symbol,SYMBOL_ASK);   
     else
      mtr.price   = price;
    }
   else                    // если SELL
    {
     if ( type == ORDER_TYPE_BUY || type == ORDER_TYPE_SELL)
      mtr.price   = SymbolInfoDouble(symbol,SYMBOL_BID);
     else
      mtr.price   = price;
    }      
  if ( OrderSend(mtr,mt_res) ) // если был успешно отправлен ордер
   {
    ticket = mt_res.order;     // сохраняем ордер
   }   
  return (ticket);
 }

 
// модифицирует ордер по тикету 
bool OrderModify(MqlTradeRequest &mtr)
 {
  MqlTradeResult tmp_res;
  // если был успешно выбран тикет
  if (OrderSelect(mtr.order)) 
   {
    return (OrderSend(mtr,tmp_res));
   }
   return (false);
 }

/*

// удаляет все лимитные ордера 
void delete_all_limit_orders()
{
  uint i, lv_total;
  ulong lv_ticket;
  bool lv_is_here;
  
  lv_is_here = true;
  while (lv_is_here)
  {
    lv_is_here = false;
    lv_total = OrdersTotal();
    for (i = 0; i < lv_total; i++ )
      if ((lv_ticket = OrderGetTicket(i)) > 0)
        if (((OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_LIMIT) || (OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_LIMIT)) && (OrderGetInteger(ORDER_MAGIC) == gv_magic))
        {
          lv_is_here = true;
          delete_limit_order(lv_ticket);
          break;
        }
  }
} 

// удаление отложенника по текету
bool delete_limit_order(ulong p_ticket)
{
  int lv_return;
  MqlTradeRequest ls_trade;
  MqlTradeResult ls_result;
  string lv_error_list, lv_retcode;
  
  ZeroMemory(ls_trade);
  ZeroMemory(ls_result);
  
  ls_trade.action = TRADE_ACTION_REMOVE;
  ls_trade.order = p_ticket;
  lv_error_list = "";
  
  while (!IsStopped())
  {
    lv_return = 2;
    OrderSend(ls_trade, ls_result);
    switch (ls_result.retcode)
    {
      case TRADE_RETCODE_DONE: lv_return = 1; if (gv_logging) Print("order ", ls_result.order, " successfully deleted"); break;
      case TRADE_RETCODE_REQUOTE: lv_return = 2; Sleep(1000); break;
      case TRADE_RETCODE_INVALID_PRICE: lv_return = 2; break;
      case TRADE_RETCODE_INVALID_STOPS: lv_return = 2; Sleep(1000); break;
      case TRADE_RETCODE_PRICE_CHANGED: lv_return = 2; break;
      case TRADE_RETCODE_FROZEN: lv_return = 2; Sleep(1000); break;
      default: lv_return = 2; break;
    }  
    
    lv_retcode = "<";
    StringAdd(lv_retcode, IntegerToString(ls_result.retcode));
    StringAdd(lv_retcode, ">");
    if (lv_return == 1) break;
    if ((lv_return == 2)&&(StringFind(lv_error_list, lv_retcode, 0) == -1))
    {
      StringAdd(lv_error_list, lv_retcode);
      if (gv_logging) Print("error of order ", p_ticket, " delete: ", ls_result.retcode, "; GetLastError() = ", GetLastError(), "; Bid = ", ls_result.bid, "; Ask = ", ls_result.ask, "; Price = ", ls_result.price);
    }
  }
  
  if (lv_return == 1) return (true); else return (false); 
}

*/
 
// открывает позицию
ulong PositionOpen( string symbol,
                ENUM_POSITION_TYPE type,double lot,
                double stopLoss,double takeProfit,int deviation=3,string comment="" )
 {
   MqlTradeRequest mtr;
   MqlTradeResult  mt_res;
   ulong ticket;
   mtr.symbol          = symbol;
   mtr.volume          = lot;
   mtr.type_filling    = ORDER_FILLING_FOK;
   mtr.sl              = stopLoss;
   mtr.tp              = takeProfit;
   mtr.deviation       = deviation;
   mtr.comment         = comment;
       
   if (type == POSITION_TYPE_BUY)  // если BUY                 
    {
     mtr.price   = SymbolInfoDouble(symbol,SYMBOL_ASK);   
     mtr.type    = ORDER_TYPE_BUY;
     mtr.action  = TypeOfOrder(ORDER_TYPE_BUY);     
    }
   else                            // если SELL
    {
     mtr.price   = SymbolInfoDouble(symbol,SYMBOL_BID);
     mtr.type    = ORDER_TYPE_SELL;
     mtr.action  = TypeOfOrder(ORDER_TYPE_SELL);
    }     
   // если позиция уже существует по данному символу
   if ( PositionSelect (symbol) )
    {
     // если знак позиции такой же, как у уже открытой
     if (ENUM_POSITION_TYPE(PositionGetInteger(POSITION_TYPE)) != type)
      return (0); // то вернем нулевой тикет и ничего не делаем
     
    }    
   if ( OrderSend(mtr,mt_res) ) // если был успешно отправлен ордер
    {
     ticket = mt_res.order;     // сохраняем ордер
    }  
   return ( ticket );
 }

// закрывает позицию
  
bool PositionClose (string symbol)
 {
  ulong ticket;
  MqlTradeRequest pos_req;
  MqlTradeResult  pos_res;
  if ( PositionSelect(symbol) )
   {
     if ( ENUM_POSITION_TYPE( PositionGetInteger(POSITION_TYPE) ) == POSITION_TYPE_BUY)
      {
       if (PositionOpen(symbol,POSITION_TYPE_SELL,PositionGetDouble(POSITION_VOLUME),
                       PositionGetDouble(POSITION_SL),PositionGetDouble(POSITION_TP) ) )
          return (true);             
      }  
     else if ( ENUM_POSITION_TYPE( PositionGetInteger(POSITION_TYPE) ) == POSITION_TYPE_SELL)
      {
        if ( PositionOpen(symbol,POSITION_TYPE_BUY,PositionGetDouble(POSITION_VOLUME),
                       PositionGetDouble(POSITION_SL),PositionGetDouble(POSITION_TP) ) )
          return (true);             
      }  
   }
  return (false);  // не удалось закрыть позицию
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