//+------------------------------------------------------------------+
//|                                  Virtual Order Manager Enums.mqh |
//|                                     Copyright Paul Hampton-Smith |
//|                            http://paulsfxrandomwalk.blogspot.com |
//+------------------------------------------------------------------+
#property copyright "Paul Hampton-Smith"
#property link      "http://paulsfxrandomwalk.blogspot.com"
//+------------------------------------------------------------------+
/// Similar enum to ENUM_ORDER_TYPE.
//+------------------------------------------------------------------+
enum ENUM_TM_POSITION_TYPE
  {
   OP_BUY,           //Покупка 
   OP_SELL,          //Продажа 
   OP_BUYLIMIT,      //Отложенный ордер BUY LIMIT 
   OP_SELLLIMIT,     //Отложенный ордер SELL LIMIT 
   OP_BUYSTOP,       //Отложенный ордер BUY STOP 
   OP_SELLSTOP,      //Отложенный ордер SELL STOP
   OP_UNKNOWN       //Для инициализации или ошибка
  };
  
//+------------------------------------------------------------------+
/// ENUM_ORDER_TYPE to ENUM_TM_POSITION_TYPE.
//+------------------------------------------------------------------+
ENUM_TM_POSITION_TYPE OrderTypeToTMPositionType(ENUM_ORDER_TYPE type)
{
 switch (type)
 {
  case ORDER_TYPE_BUY        : return(OP_BUY);
  case ORDER_TYPE_SELL       : return(OP_SELL);
  case ORDER_TYPE_BUY_LIMIT  : return(OP_BUYLIMIT);
  case ORDER_TYPE_SELL_LIMIT : return(OP_SELLLIMIT);
  case ORDER_TYPE_BUY_STOP   : return(OP_BUYSTOP);
  case ORDER_TYPE_SELL_STOP  : return(OP_SELLSTOP);
  default          : return(OP_UNKNOWN);
 }
}
//+------------------------------------------------------------------+ 
// Функция плучения названия операции по ее номеру
//+------------------------------------------------------------------+
string GetNameOP(ENUM_TM_POSITION_TYPE op)
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
};

//+------------------------------------------------------------------+
/// Converts Virtual Order string name to enum
/// \param [in]   strVirtualOrderType
/// \return ENUM_VIRTUAL_ORDER_TYPE      
//+------------------------------------------------------------------+
ENUM_TM_POSITION_TYPE StringToPositionType(string posType)
  {
   if(posType == "Buy") return(OP_BUY);
   if(posType == "Sell") return(OP_SELL);
   if(posType == "Buy Limit") return(OP_BUYLIMIT);
   if(posType == "Sell Limit") return(OP_SELLLIMIT);
   if(posType == "Buy Stop") return(OP_BUYSTOP);
   if(posType == "Sell Stop") return(OP_SELLSTOP);   
   return("Error: unknown position type " + posType);
  }

//+------------------------------------------------------------------+
/// Tracks status of virtual orders.
//+------------------------------------------------------------------+
enum ENUM_POSITION_STATUS
  {
   POSITION_STATUS_OPEN,
   POSITION_STATUS_PENDING,
   POSITION_STATUS_CLOSED,
   POSITION_STATUS_DELETED,
   POSITION_STATUS_NOT_DELETED,
   POSITION_STATUS_NOT_CHANGED,
   POSITION_STATUS_NOT_INITIALISED,
   POSITION_STATUS_NOT_COMPLETE,
   POSITION_STATUS_MUST_BE_REPLAYED, //позиция должна отыграться
   POSITION_STATUS_READY_TO_REPLAY,   //позиция готова к отыгрышу
   POSITION_STATUS_ON_REPLAY
  };
//+------------------------------------------------------------------+
/// Returns string description of ENUM_POSITION_STATUS.                                                                 
/// \param [in]   ENUM_POSITION_STATUS enumVirtualOrderStatus
/// \return       string description of enumVirtualOrderType
//+------------------------------------------------------------------+
string PositionStatusToStr(ENUM_POSITION_STATUS enumPositionStatus)
  {
   switch(enumPositionStatus)
     {
      case POSITION_STATUS_OPEN: return("open");
      case POSITION_STATUS_PENDING: return("pending");
      case POSITION_STATUS_CLOSED: return("closed");
      case POSITION_STATUS_DELETED: return("deleted");
      case POSITION_STATUS_NOT_DELETED: return("not deleted");
      case POSITION_STATUS_NOT_CHANGED: return("not changed");
      case POSITION_STATUS_NOT_INITIALISED: return("not initialised");
      case POSITION_STATUS_NOT_COMPLETE: return("not completed");
      case POSITION_STATUS_MUST_BE_REPLAYED: return("must be replayed");
      case POSITION_STATUS_READY_TO_REPLAY: return ("ready to replay");            
      default: return("Error: unknown virtual order status "+(string)enumPositionStatus);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_POSITION_STATUS StringToPositionStatus(string posStatus)
  {
   if(posStatus=="open") return(POSITION_STATUS_OPEN);
   if(posStatus=="closed") return(POSITION_STATUS_CLOSED);
   if(posStatus=="deleted") return(POSITION_STATUS_DELETED);
   return(POSITION_STATUS_NOT_INITIALISED);
  }
  
//+------------------------------------------------------------------+
/// Returns string description of ENUM_VIRTUAL_ORDER_TYPE.                                                                 
/// \param [in]      ENUM_VIRTUAL_ORDER_TYPE VirtualOrderType
/// \return string   description of VirtualOrderType
//+------------------------------------------------------------------+
string PositionTypeToStr(ENUM_POSITION_TYPE enumPositionType)
  {
   switch(enumPositionType)
     {
      case POSITION_TYPE_BUY: return("position buy");
      case POSITION_TYPE_SELL: return("position sell");
      default: return("Error: unknown position type "+(string)enumPositionType);
     }
  }

//+------------------------------------------------------------------+
/// Status of stoplevels
//+------------------------------------------------------------------+
enum ENUM_STOPLEVEL_STATUS
  {
   STOPLEVEL_STATUS_NOT_DEFINED,
   STOPLEVEL_STATUS_PLACED,
   STOPLEVEL_STATUS_NOT_PLACED,
   STOPLEVEL_STATUS_DELETED,
   STOPLEVEL_STATUS_NOT_DELETED
  };
  
enum ENUM_FILENAME
  {
   FILENAME_RESCUE,
   FILENAME_HISTORY
  };

//+------------------------------------------------------------------+
/// Used by CTradeManager::OrderSelect()
/// Similar to MT4
//+------------------------------------------------------------------+
enum ENUM_SELECT_MODE
  {
   MODE_TRADES, ///< Select from CVirtualOrdermanager::m_OpenOrders
   MODE_HISTORY ///< Select from CVirtualOrdermanager::m_OrderHistory
  };
  
//+------------------------------------------------------------------+
/// Position trailing types
//+------------------------------------------------------------------+
enum ENUM_TRAILING_TYPE
  {
   TRAILING_TYPE_NONE,
   TRAILING_TYPE_USUAL,
   TRAILING_TYPE_LOSSLESS,
   TRAILING_TYPE_PBI
  };
  
//+------------------------------------------------------------------+
/// Used by CTradeManager::OrderSelect()
/// Similar to MT4
//+------------------------------------------------------------------+
enum ENUM_SELECT_TYPE
  {
   SELECT_BY_POS,
   SELECT_BY_TICKET
  };
  
//+------------------------------------------------------------------+
/// Структура свойств позиций на отыгрыш
//+------------------------------------------------------------------+
class ReplayPos
{
 public:  
  string symbol;               //символ 
  double price_open;           //цена открытия
  double price_close;          //цена закрытия
  double profit;               //профит позиции
  ENUM_POSITION_STATUS status; //статус позиции
  ENUM_TM_POSITION_TYPE type;  //тип позиции
};

