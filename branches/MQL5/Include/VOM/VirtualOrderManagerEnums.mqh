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
enum ENUM_VIRTUAL_ORDER_TYPE
  {
   VIRTUAL_ORDER_TYPE_BUY,
   VIRTUAL_ORDER_TYPE_BUYSTOP,
   VIRTUAL_ORDER_TYPE_BUYLIMIT,
   VIRTUAL_ORDER_TYPE_SELL,
   VIRTUAL_ORDER_TYPE_SELLSTOP,
   VIRTUAL_ORDER_TYPE_SELLLIMIT,
   VIRTUAL_ORDER_TYPE_UNDEFINED
  };
//+------------------------------------------------------------------+
/// Returns string description of ENUM_VIRTUAL_ORDER_TYPE.                                                                 
/// \param [in]      ENUM_VIRTUAL_ORDER_TYPE VirtualOrderType
/// \return string   description of VirtualOrderType
//+------------------------------------------------------------------+
string VirtualOrderTypeToStr(ENUM_VIRTUAL_ORDER_TYPE enumVirtualOrderType)
  {
   switch(enumVirtualOrderType)
     {
      case VIRTUAL_ORDER_TYPE_BUY: return("virtual buy");
      case VIRTUAL_ORDER_TYPE_BUYSTOP: return("virtual buy stop");
      case VIRTUAL_ORDER_TYPE_BUYLIMIT: return("virtual buy limit");
      case VIRTUAL_ORDER_TYPE_SELL: return("virtual sell");
      case VIRTUAL_ORDER_TYPE_SELLSTOP: return("virtual sell stop");
      case VIRTUAL_ORDER_TYPE_SELLLIMIT: return("virtual sell limit");
      case VIRTUAL_ORDER_TYPE_UNDEFINED: return("virtual undefined");
      default: return("Error: unknown virtual order type "+(string)enumVirtualOrderType);
     }
  }
//+------------------------------------------------------------------+
/// Result of comparing market price to stops and pending orders.
/// Output from CVirtualOrder::CheckStopsAndLimits()
//+------------------------------------------------------------------+
enum ENUM_VIRTUAL_ORDER_EVENT
  {
   VIRTUAL_ORDER_EVENT_BUY_TRIGGER, ///< Result of a BUYSTOP or BUYLIMIT triggering
   VIRTUAL_ORDER_EVENT_SELL_TRIGGER, ///< Result of a SELLSTOP or SELLLIMIT triggering
   VIRTUAL_ORDER_EVENT_STOPLOSS, ///< Result of a stoploss being hit
   VIRTUAL_ORDER_EVENT_TAKEPROFIT, ///< Result of a takeprofit being hit
   VIRTUAL_ORDER_EVENT_TIMESTOP, ///< Result of a timestop being hit
   VIRTUAL_ORDER_EVENT_NONE 
  };
//+------------------------------------------------------------------+
/// Returns string description of ENUM_VIRTUAL_ORDER_EVENT.                                                                 
/// \param [in]      VirtualOrderEvent
/// \return string   description of VirtualOrderEvent
//+------------------------------------------------------------------+
string VirtualOrderEventToStr(ENUM_VIRTUAL_ORDER_EVENT enumVirtualOrderEvent)
  {
   switch(enumVirtualOrderEvent)
     {
      case VIRTUAL_ORDER_EVENT_BUY_TRIGGER: return("buy trigger");
      case VIRTUAL_ORDER_EVENT_SELL_TRIGGER: return("sell trigger");
      case VIRTUAL_ORDER_EVENT_STOPLOSS: return("stoploss hit");
      case VIRTUAL_ORDER_EVENT_TAKEPROFIT: return("takeprofit hit");
      case VIRTUAL_ORDER_EVENT_TIMESTOP: return("timestop hit");
      case VIRTUAL_ORDER_EVENT_NONE: return("no action");
      default: return("Error: unknown virtual event "+(string)enumVirtualOrderEvent);
     }
  }
//+------------------------------------------------------------------+
/// Converts Virtual Order string name to enum
/// \param [in]   strVirtualOrderType
/// \return ENUM_VIRTUAL_ORDER_TYPE      
//+------------------------------------------------------------------+
ENUM_VIRTUAL_ORDER_TYPE StringToVirtualOrderType(string strVirtualOrderType)
  {
   if(strVirtualOrderType=="virtual buy") return(VIRTUAL_ORDER_TYPE_BUY);
   if(strVirtualOrderType=="virtual buy stop") return(VIRTUAL_ORDER_TYPE_BUYSTOP);
   if(strVirtualOrderType=="virtual buy limit") return(VIRTUAL_ORDER_TYPE_BUYLIMIT);
   if(strVirtualOrderType=="virtual sell") return(VIRTUAL_ORDER_TYPE_SELL);
   if(strVirtualOrderType=="virtual sell stop") return(VIRTUAL_ORDER_TYPE_SELLSTOP);
   if(strVirtualOrderType=="virtual sell limit") return(VIRTUAL_ORDER_TYPE_SELLLIMIT);
   return(VIRTUAL_ORDER_TYPE_UNDEFINED);
  }
//+------------------------------------------------------------------+
/// Tracks status of virtual orders.
//+------------------------------------------------------------------+
enum ENUM_VIRTUAL_ORDER_STATUS
  {
   VIRTUAL_ORDER_STATUS_OPEN,
   VIRTUAL_ORDER_STATUS_PENDING,
   VIRTUAL_ORDER_STATUS_CLOSED,
   VIRTUAL_ORDER_STATUS_DELETED,
   VIRTUAL_ORDER_STATUS_NOT_INITIALISED
  };
//+------------------------------------------------------------------+
/// Returns string description of ENUM_VIRTUAL_ORDER_STATUS.                                                                 
/// \param [in]   ENUM_VIRTUAL_ORDER_STATUS enumVirtualOrderStatus
/// \return       string description of enumVirtualOrderType
//+------------------------------------------------------------------+
string VirtualOrderStatusToStr(ENUM_VIRTUAL_ORDER_STATUS enumVirtualOrderStatus)
  {
   switch(enumVirtualOrderStatus)
     {
      case VIRTUAL_ORDER_STATUS_OPEN: return("open");
      case VIRTUAL_ORDER_STATUS_PENDING: return("pending");
      case VIRTUAL_ORDER_STATUS_CLOSED: return("closed");
      case VIRTUAL_ORDER_STATUS_DELETED: return("deleted");
      case VIRTUAL_ORDER_STATUS_NOT_INITIALISED: return("not initialised");
      default: return("Error: unknown virtual order status "+(string)enumVirtualOrderStatus);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_VIRTUAL_ORDER_STATUS StringToVirtualOrderStatus(string strVirtualOrderStatus)
  {
   if(strVirtualOrderStatus=="open") return(VIRTUAL_ORDER_STATUS_OPEN);
   if(strVirtualOrderStatus=="pending") return(VIRTUAL_ORDER_STATUS_PENDING);
   if(strVirtualOrderStatus=="closed") return(VIRTUAL_ORDER_STATUS_CLOSED);
   if(strVirtualOrderStatus=="deleted") return(VIRTUAL_ORDER_STATUS_DELETED);
   return(VIRTUAL_ORDER_STATUS_NOT_INITIALISED);
  }
//+------------------------------------------------------------------+
/// Used by CVirtualOrdermanager::OrderSelect()
/// Similar to MT4
//+------------------------------------------------------------------+
enum ENUM_VIRTUAL_SELECT_MODE
  {
   MODE_TRADES, ///< Select from CVirtualOrdermanager::m_OpenOrders
   MODE_HISTORY ///< Select from CVirtualOrdermanager::m_OrderHistory
  };
//+------------------------------------------------------------------+
/// Returns string description of ENUM_VIRTUAL_SELECT_MODE.                                                                 
/// \param [in]   ENUM_VIRTUAL_SELECT_MODE enumVirtualOrderSelect
/// \return       string description of enumVirtualOrderSelect
//+------------------------------------------------------------------+
string VirtualOrderSelectModeToStr(ENUM_VIRTUAL_SELECT_MODE enumVirtualOrderSelect)
  {
   switch(enumVirtualOrderSelect)
     {
      case MODE_TRADES: return("MODE_TRADES");
      case MODE_HISTORY: return("MODE_HISTORY");
      default: return("Error: unknown virtual order select "+(string)enumVirtualOrderSelect);
     }
  }
//+------------------------------------------------------------------+
/// Used by CVirtualOrdermanager::OrderSelect()
/// Similar to MT4
//+------------------------------------------------------------------+
enum ENUM_VIRTUAL_SELECT_TYPE
  {
   SELECT_BY_POS,
   SELECT_BY_TICKET
  };
//+------------------------------------------------------------------+
/// Returns string description of ENUM_VIRTUAL_SELECT_MODE.                                                                 
/// \param [in]   ENUM_VIRTUAL_SELECT_MODE enumVirtualOrderSelect
/// \return       string description of enumVirtualOrderSelect
//+------------------------------------------------------------------+
string VirtualOrderSelectTypeToStr(ENUM_VIRTUAL_SELECT_TYPE enumVirtualOrderSelectType)
  {
   switch(enumVirtualOrderSelectType)
     {
      case SELECT_BY_POS: return("SELECT_BY_POS");
      case SELECT_BY_TICKET: return("SELECT_BY_TICKET");
      default: return("Error: unknown virtual order select type "+(string)enumVirtualOrderSelectType);
     }
  }
//+------------------------------------------------------------------+
