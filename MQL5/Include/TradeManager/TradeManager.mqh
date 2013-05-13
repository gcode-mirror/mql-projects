//+------------------------------------------------------------------+
//|                                                CTradeManager.mqh |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#include "TradeManagerEnums.mqh"
#include "Position.mqh"
#include "PositionArray.mqh"
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <CompareDoubles.mqh>

//+------------------------------------------------------------------+
//| Класс обеспечивает вспомогательные торговые вычисления           |
//+------------------------------------------------------------------+
class CTradeManager : public CTrade
{
protected:
  CPosition *position;
  //CPositionInfo PosInfo;
  ENUM_TIMEFRAMES _timeframe;
  ulong _magic;
  int _digits;                 // количество знаков после запятой у цены
  double _point;               // значение пункта
  int _stopLevel;
  int _freezeLevel;
  double _bid;
  double _ask;
  int _spread; 
  int _numberOfTry; 
  bool _useSound;
  string _nameFileSound;   // Наименование звукового файла
  
public:
  void CTradeManager(ulong magic, ENUM_TIMEFRAMES timeframe, int minProfit, int trailingStop, int trailingStep)
             : _magic(magic), _timeframe(timeframe)
             , _numberOfTry(5), _useSound(true), _nameFileSound("expert.wav"){};
             
               // возвращает спред текущего инструмента
  
  CPositionArray _openPositions; ///< Array of open virtual orders for this VOM instance, also persisted as a file
  CPositionArray _positionsHistory; ///< Array of closed virtual orders, also persisted as a file
  
  void OpenPosition(string symbol, ENUM_POSITION_TYPE type,double volume
                   ,int sl, int tp, int minProfit, int trailingStop, int trailingStep);
  void DoTrailing();
  void ModifyPosition(ENUM_TRADE_REQUEST_ACTIONS trade_action);
  string GetNameOP(int op);
  void OnTick();
  void OnTrade(datetime history_start);
  bool PositionClose(long ticket,int slippage,color Color=CLR_NONE); 
  bool CloseAllOrdersByTypeOnSymbol(string strSymbol="",int type = -1);
  bool CloseAllOrdersOnSymbol(string strSymbol);
  bool CloseAllOrdersByType(ENUM_ORDER_TYPE Type);
  bool CloseAllOrders();
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTradeManager::OpenPosition(string symbol, ENUM_POSITION_TYPE type, double volume
                                ,int sl, int tp, int minProfit, int trailingStop, int trailingStep)
{
 //Print("=> ",__FUNCTION__," at ",TimeToString(TimeCurrent(),TIME_SECONDS));
 int i = 0;
 int total = _openPositions.Total();
 switch(type)
 {
  case POSITION_TYPE_BUY:
   //Print("Открываем позицию БАЙ");
   if (total > 0)
   {
    //Print("Есть открытые позиции");
    for (i = total - 1; i >= 0; i--) // Закрываем все ордера или позиции на покупку
    {
     //PrintFormat("Выбрали %d-ю позицию", i);
     CPosition *pos = _openPositions.At(i);
     //PrintFormat("Выбрали %d-ю позицию символ=%s, магик=%d", i, pos.getSymbol(), pos.getMagic());
     if ((pos.getSymbol() == symbol) && (pos.getMagic() == _magic))
     {
      if (pos.getType() == POSITION_TYPE_SELL)
      {
       //Print("Закрываем позицию СЕЛЛ");
       pos.ClosePosition();
       _openPositions.Delete(i);
      }
     }
    }
   }
   break;
  case POSITION_TYPE_SELL:
   //Print("Открываем позицию СЕЛЛ");
   if (total > 0)
   {
    //Print("Есть открытые позиции");
    for (i = total - 1; i >= 0; i--) // Закрываем все ордера или позиции на продажу
    {
     //PrintFormat("Выбрали %d-ю позицию", i);
     CPosition *pos = _openPositions.At(i);
     if ((pos.getSymbol() == symbol) && (pos.getMagic() == _magic))
     {
      if (pos.getType() == POSITION_TYPE_BUY)
      {
       //Print("Закрываем позицию БАЙ");
       pos.ClosePosition();
       _openPositions.Delete(i);
      }
     }
    }
   }
   break;
  default:
   //LogFile.Log(LOG_PRINT,__FUNCTION__," error: Invalid ENUM_VIRTUAL_ORDER_TYPE");
   break;
 }
 
 total = _openPositions.Total();
 if (total <= 0)
 {
  //Print("=> ",__FUNCTION__," at ",TimeToString(TimeCurrent(),TIME_SECONDS));
  //Print("Открываем позицию");
  position = new CPosition(_magic, symbol, type, volume, sl, tp, minProfit, trailingStop, trailingStep);
  position.OpenPosition();
  /*
  PrintFormat(" тейкпрофит TakeProfitTicket=%d", position.getTakeProfitTicket());
  PrintFormat(" стоплосс StopLossTicket=%d", position.getStopLossTicket());
  PrintFormat(" позиция PositionTicket=%d", position.getPositionTicket());
  */
  _openPositions.Add(position);
 }
}
//+------------------------------------------------------------------+ 
// Функция вычисления параметров трейлинга
//+------------------------------------------------------------------+
void CTradeManager::DoTrailing()
{
 int total = _openPositions.Total();
 ulong ticket = 0, slTicket = 0;
 long type = -1;
 double newSL = 0;

//--- пройдем в цикле по всем ордерам
 for(uint i=0; i<total; i++)
 {
  CPosition *pos = _openPositions.At(i);
  pos.DoTrailing();
 } 
};
//+------------------------------------------------------------------+ 
// Функция модификации позиции
//+------------------------------------------------------------------+
void CTradeManager::ModifyPosition(ENUM_TRADE_REQUEST_ACTIONS trade_action)
{
};

//+------------------------------------------------------------------+
/// Called from EA OnTrade().
/// Actions virtual stoplosses, takeprofits \n
/// Include the following in each EA that uses TradeManager
//+------------------------------------------------------------------+
void CTradeManager::OnTrade(datetime history_start)
  {
//--- статические члены для хранения состояния торгового счета
   static int prev_volume = 0, prev_positions = 0, prev_orders = 0, prev_deals = 0, prev_history_orders = 0;
   int index;
//--- запросим торговую историю
   bool update=HistorySelect(history_start,TimeCurrent());
//   PrintFormat("HistorySelect(%s , %s) = %s",
//               TimeToString(history_start),TimeToString(TimeCurrent()),(string)update);
//--- заголовок по имени функции-обработчика торгового события 
//   Print("=> ",__FUNCTION__," at ",TimeToString(TimeCurrent(),TIME_SECONDS));
//--- выведем имя обработчика и количество ордеров на момент обработки
   double curr_volume = PositionGetDouble(POSITION_VOLUME);
   int curr_positions = PositionsTotal();
   int curr_orders = OrdersTotal();
   int curr_deals = HistoryOrdersTotal();
   int curr_history_orders = HistoryDealsTotal();/*
//--- выводим количество ордеров, позиций, сделок, а также изменение в скобках 
   PrintFormat("PositionsTotal() = %d (%+d)",
               curr_positions,(curr_positions-prev_positions));
   PrintFormat("OrdersTotal() = %d (%+d)",
               curr_orders,curr_orders-prev_orders);
   PrintFormat("HistoryOrdersTotal() = %d (%+d)",
               curr_deals,curr_deals-prev_deals);
   PrintFormat("HistoryDealsTotal() = %d (%+d)",
               curr_history_orders,curr_history_orders-prev_history_orders);
//--- вставка разрыва строк для удобного чтения Журнала
   Print("");*/
   if ((curr_positions-prev_positions) != 0 || (curr_volume - prev_volume) != 0) // если изменилось количество или объем позиций
   {
    for(int i = _openPositions.Total()-1; i>=0; i--) // по массиву НАШИХ позиций
    {
     position = _openPositions.At(i);
     if (!OrderSelect(position.getStopLossTicket()) || !OrderSelect(position.getTakeProfitTicket()))
     {
      if (!OrderSelect(position.getStopLossTicket()))
      {
       //PrintFormat(" Нету ордера-стоплосса, закрываем тейкпрофит TakeProfitTicket=%d",position.getTakeProfitTicket());
       OrderDelete(position.getTakeProfitTicket());
       index = _openPositions.TicketToIndex(position.getPositionTicket());
       _openPositions.Delete(index);
       break;
      }
      if (!OrderSelect(position.getTakeProfitTicket()))
      {
       //PrintFormat("Нету ордера-тейкпрофита, закрываем стоплосс");
       OrderDelete(position.getStopLossTicket());
       index = _openPositions.TicketToIndex(position.getPositionTicket());
       _openPositions.Delete(index);
       break;
      }
     }
    }
   }
//--- запомним состояние счета
   prev_volume = curr_volume;
   prev_positions = curr_positions;
   prev_orders = curr_orders;
   prev_deals = curr_deals;
   prev_history_orders = curr_history_orders;
  }

//+------------------------------------------------------------------+
/// Called from EA OnTick().
/// Actions virtual stoplosses, takeprofits \n
/// Include the following in each EA that uses TradeManager
/// \code
/// // EA code
/// void OnTick()
///  {
///   // action virtual stoplosses, takeprofits
///   tm.OnTick();
///   //
///   // continue with other tick event handling in this EA
///   // ....
/// \endcode
//+------------------------------------------------------------------+
void CTradeManager::OnTick()
{
 /*
 if(m_OpenOrders.OpenLots(Symbol())!=0 && OpenLots(Symbol())==0)
 {
  // assume that a server side stoploss event has occurred
  // and close all virtual open orders without sending anything to the server
  //LogFile.Log(LOG_PRINT,__FUNCTION__,StringFormat(" - warning: virtual open lots = %0.2f ; server open lots = 0. Assume a server stoploss event has occurred; closing all virtual orders",m_OpenOrders.OpenLots(Symbol())/1000.0));
  for(int i=m_OpenOrders.Total()-1; i>=0; i--)
  {
   CVirtualOrder *vo=m_OpenOrders.VirtualOrder(i);
   if(vo.OrderType()==VIRTUAL_ORDER_TYPE_BUY || vo.OrderType()==VIRTUAL_ORDER_TYPE_SELL)
   {
    vo.Close();
    m_GlobalVirtualStopList.Delete(vo.Ticket());
    m_OpenOrders.Detach(i);
    m_OrderHistory.Add(vo);
   }
  }
  m_OpenOrders.WriteToFile();
  m_OrderHistory.WriteToFile();
  BroadcastVirtualTradeEvent();
 }

// check for sl,tp,or pending order trigger
 for(int i=m_OpenOrders.Total()-1; i>=0; i--)
 {
  CVirtualOrder *vo=m_OpenOrders.VirtualOrder(i);
  LogFile.Log(LOG_DEBUG,__FUNCTION__," looking at order ",(string)vo.Ticket()," with magic ",(string)vo.MagicNumber()," for ",vo.Symbol());
  if(vo.MagicNumber()==MagicNumber())
  {
   if(vo.Symbol()==_Symbol)
   {
    switch(vo.CheckStopsAndLimits())
    {
     case VIRTUAL_ORDER_EVENT_NONE:
      break;
     case VIRTUAL_ORDER_EVENT_BUY_TRIGGER:
      if(PositionChangeSizeAtServer(vo.Symbol(),vo.Lots(), ORDER_TYPE_BUY, vo.StopLoss()))
      {
       vo.PendingOrderTrigger();
       m_OpenOrders.WriteToFile();
       BroadcastVirtualTradeEvent();
       PositionSetTightestStopAtServer(_Symbol);
      }
      break;
     case VIRTUAL_ORDER_EVENT_SELL_TRIGGER:
      if(PositionChangeSizeAtServer(vo.Symbol(),vo.Lots(), ORDER_TYPE_SELL, vo.StopLoss()))
      {
       vo.PendingOrderTrigger();
       m_OpenOrders.WriteToFile();
       BroadcastVirtualTradeEvent();
       PositionSetTightestStopAtServer(_Symbol);
      }
      break;
     case VIRTUAL_ORDER_EVENT_STOPLOSS:
     case VIRTUAL_ORDER_EVENT_TAKEPROFIT:
     case VIRTUAL_ORDER_EVENT_TIMESTOP:
      OrderClose(vo.Ticket(), config.Deviation);
      break;
     default:
      LogFile.Log(LOG_PRINT,__FUNCTION__," error: invalid Virtual Order Event");
    } // switch vo.CheckStopsAndLimits()
   } // if
  } // i
 }*/
}  
//+------------------------------------------------------------------+
/// Close a virtual order.
/// \param [in] ticket			Open virtual order ticket
/// \param [in] slippage		also known as deviation.  Typical value is 50
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool CTradeManager::PositionClose(long ticket,int slippage,color Color=CLR_NONE)
{
 return(false);
}
  
//+------------------------------------------------------------------+
/// Close all orders for symbol and type
/// \param [in] strSymbol
/// \param [in] Type			Order type
/// \return						True if successful, false otherwise
//+------------------------------------------------------------------+
bool CTradeManager::CloseAllOrdersByTypeOnSymbol(string strSymbol="",int type = -1)
{
 //LogFile.Log(LOG_DEBUG,__FUNCTION__,_Symbol,",",VirtualOrderTypeToStr(Type));
 ulong ticket = 0;
 int ot;
 for(int i = OrdersTotal()-1; i>=0 ;i--)
 {
  if((ticket = OrderGetTicket(i)) > 0)
  {
   if (OrderSelect(ticket))
   {
    if (OrderGetInteger(ORDER_MAGIC) == _magic)
    {
     ot = OrderGetInteger(ORDER_TYPE);
     if (ot>1 && ot<6)
     {
      if((type < 0 || ot == type) && (strSymbol=="" || position.getSymbol() == strSymbol))
      {
       if(!OrderDelete(ticket))
       {
        return(false); 
       }
      }
     }
    }
   }
  }
 }   
 return(true);
}
