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

MqlTradeRequest    mtm_pos_req;              // структура открытия позиции
MqlTradeResult     mtm_pos_res;              // для хранения результатов открытия позиции
bool               openedPosition=false; // флаг открытой позиции

// возвращает структуру данных об ордерах
void  SetTradeRequest (MqlTradeRequest &mtr,string symbol, ENUM_ORDER_TYPE type,
                                 double lot, double stopLoss,double takeProfit,
                                 int deviation=3, string comment="ok"                               
                                 )
  {
    mtr.action          = TypeOfOrder(type);
    mtr.symbol          = symbol;
    mtr.volume          = lot;
    mtr.type_filling    = ORDER_FILLING_FOK;
    mtr.sl              = stopLoss;
    mtr.tp              = takeProfit;
    mtr.deviation       = deviation;
    mtr.comment         = comment; 
    
   if (BuyOrSell (type) )  // если BUY                 
    {
     mtr.price   = SymbolInfoDouble(symbol,SYMBOL_ASK);   
    }
   else                    // если SELL
    {
     mtr.price   = SymbolInfoDouble(symbol,SYMBOL_BID);
    }    
  }
  
// создает ордер и возвращает его тикет в случае успеха
ulong OrderCreate ( MqlTradeRequest &mtr,MqlTradeResult &mt_res)
 {
  ulong ticket = 0;
  if ( OrderSend(mtr,mt_res) ) // если был успешно отправлен ордер
   {
    ticket = mt_res.order;     // сохраняем ордер
   }
  return (ticket);
 }
// модифицирует ордер по тикету 
bool OrderModify( ulong ticket, MqlTradeRequest &mtr)
 {
  MqlTradeResult tmp_res;
  // если был успешно выбран тикет
  if (OrderSelect(ticket)) 
   {
    return (OrderSend(mtr,tmp_res));
   }
   return (false);
 }
 
// открывает позицию
ulong PositionOpen( string symbol,
                ENUM_POSITION_TYPE type,double lot,
                double stopLoss,double takeProfit,int deviation=3 )
 {
   ENUM_ORDER_TYPE ot;
   MqlTradeRequest pos_req;
   MqlTradeResult  pos_res;
   
   switch (type)
    {
     case POSITION_TYPE_BUY:
      ot = ORDER_TYPE_BUY;
     break;
     case POSITION_TYPE_SELL:
      ot = ORDER_TYPE_SELL;
     break;
    }
   // если позиция уже существует по данному символу
   if ( PositionSelect (symbol) )
    {
     // если знак позиции такой же, как у уже открытой
     if (ENUM_POSITION_TYPE(PositionGetInteger(POSITION_TYPE)) != type)
      return (0); // то вернем нулевой тикет и ничего не делаем
     
    }
   SetTradeRequest(pos_req,symbol,ot,lot,stopLoss,takeProfit,deviation);
   return (OrderCreate (pos_req,pos_res) );
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