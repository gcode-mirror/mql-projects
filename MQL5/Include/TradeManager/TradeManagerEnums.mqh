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
enum ENUM_TM_ORDER_TYPE
  {
   OP_BUY,           //Покупка 
   OP_SELL,          //Продажа 
   OP_BUYLIMIT,      //Отложенный ордер BUY LIMIT 
   OP_SELLLIMIT,     //Отложенный ордер SELL LIMIT 
   OP_BUYSTOP,       //Отложенный ордер BUY STOP 
   OP_SELLSTOP      //Отложенный ордер SELL STOP 
  };

//+------------------------------------------------------------------+ 
// Функция плучения названия операции по ее номеру
//+------------------------------------------------------------------+
string GetNameOP(ENUM_TM_ORDER_TYPE op)
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
/// Tracks status of virtual orders.
//+------------------------------------------------------------------+
enum ENUM_POSITION_STATUS
  {
   POSITION_STATUS_OPEN,
   POSITION_STATUS_PENDING,
   POSITION_STATUS_CLOSED,
   POSITION_STATUS_DELETED,
   POSITION_STATUS_NOT_INITIALISED
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
      case POSITION_STATUS_CLOSED: return("closed");
      case POSITION_STATUS_DELETED: return("deleted");
      case POSITION_STATUS_NOT_INITIALISED: return("not initialised");
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
/// Converts Virtual Order string name to enum
/// \param [in]   strVirtualOrderType
/// \return ENUM_VIRTUAL_ORDER_TYPE      
//+------------------------------------------------------------------+
ENUM_POSITION_TYPE StringToPositionType(string posType)
  {
   if(posType == "virtual buy") return(POSITION_TYPE_BUY);
   if(posType == "virtual sell") return(POSITION_TYPE_SELL);
   return("Error: unknown position type " + posType);
  }

//+------------------------------------------------------------------+
/// Status of 
//+------------------------------------------------------------------+
enum ENUM_STOPLEVEL_STATUS
  {
   STOPLEVEL_STATUS_NOT_DEFINED,
   STOPLEVEL_STATUS_PLACED,
   STOPLEVEL_STATUS_NOT_PLACED,
   STOPLEVEL_STATUS_DELETED,
   STOPLEVEL_STATUS_NOT_DELETED
  };