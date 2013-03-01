//+------------------------------------------------------------------+
//|                                          VirtualOrderManager.mqh |
//|                                     Copyright Paul Hampton-Smith |
//|                            http://paulsfxrandomwalk.blogspot.com |
//+------------------------------------------------------------------+
#property copyright "Paul Hampton-Smith"
#property link      "http://paulsfxrandomwalk.blogspot.com"

#include "Log.mqh"
#include "VirtualOrderManagerConfig.mqh"
#include "VirtualOrderManagerEnums.mqh"
#include "StringUtilities.mqh"
#include "VirtualOrderArray.mqh"
#include "VirtualOrder.mqh"
#include "SimpleChartObject.mqh"
#include "GlobalVirtualStopList.mqh"
#include "VOM_manual.mqh"
#include <CompareDoubles.mqh>
//+------------------------------------------------------------------+
/// The main object encapsulating the Virtual Order processes.
//+------------------------------------------------------------------+
class CVirtualOrderManager
  {
private:
   CVirtualOrder    *m_SelectedOrder; ///< Selected with OrderSelect()
   long              m_lMagicNumber; ///< Magic number of the EA using this VOM
   int               m_nLastBars; ///< value of Bars at last tick, used by OnTick()
   bool              m_bNewBar; ///< set to true by OnTick() for first tick of new bar, accessed by NewBar()
   datetime          m_dtTime0; ///< Open time of current incomplete bar
   CGlobalVirtualStopList m_GlobalVirtualStopList;
   int _minProfit;
   int _trailingStop;
   int _trailingStep;

public:
   CVirtualOrderArray m_OpenOrders; ///< Array of open virtual orders for this VOM instance, also persisted as a file
   CVirtualOrderArray m_OrderHistory; ///< Array of closed virtual orders, also persisted as a file

                                      /// Destructor freeing all resources.
                    ~CVirtualOrderManager();

   /// Send out notification of an order event
   void BroadcastVirtualTradeEvent();
   /// Simple market buy order.
   long Buy(string strSymbol,double dblLots,const int nStoploss,const int nTakeprofit,string strComment="");
   /// Simple market buy order with timestop.
   long Buy(string strSymbol,double dblLots,const int nStoploss,const int nTakeprofit,const int nTimeStopBars,string strComment="");
   /// Close all orders for symbol and type
   bool CloseAllOrders(string strSymbol,ENUM_VIRTUAL_ORDER_TYPE Type);
   /// Called from EA OnInit().
   void Initialise(long lMagicNumber=-1, int minProfit = 0, int tStop = 0, int tStep = 0);
   /// Has there been an order closed in this bar?
   bool LastOrderCloseInBar(string strSymbol="");
   /// Magic number for the EA using this VOM
   long MagicNumber(){return(m_lMagicNumber);}
   /// Creates a unique magic number from the EA symbol and name.
   long MakeMagic(string strSymbol="");
   /// True for first tick of new bar.
   //bool NewBar(){return(m_bNewBar);}
   /// Called from EA OnTick().
   void OnTick();
   /// returns open lots * 1000
   int OpenLots(string strSymbol="");
   /// Count of open orders
   int OpenOrders(string strSymbol=""){if(strSymbol=="")strSymbol=_Symbol;return(m_OpenOrders.OrderCount(strSymbol,MagicNumber()));}
   /// Orders opened since beginning of bar.
   int OpenedOrdersInSameBar(string strSymbol="");
   /// Close a virtual order.
   bool OrderClose(long ticket,int slippage,color Color=CLR_NONE);
   /// Not implemented in this version
   bool OrderCloseBy(long ticket,int opposite,color Color=CLR_NONE) {LogFile.Log(LOG_PRINT,__FUNCTION__,"Not implemented"); return(false);}
   /// Close price for virtual order. Use OrderSelect() first
   double OrderClosePrice() {if(ValidSelectedOrder()) return(m_SelectedOrder.ClosePrice()); else return(0.0);}
   /// Close time for virtual order. Use OrderSelect() first
   datetime OrderCloseTime() {if(ValidSelectedOrder()) return(m_SelectedOrder.CloseTime()); else return((datetime)0);}
   /// Comment for virtual order. Use OrderSelect() first
   string OrderComment() {if(ValidSelectedOrder()) return(m_SelectedOrder.Comment()); else return("");}
   double OrderCommission() {if(ValidSelectedOrder()) return(m_SelectedOrder.Commission()); else return(0.0);}
   /// Delete a pending virtual order.
   bool OrderDelete(long ticket);
   /// Expiration time of virtual order. Use OrderSelect() first
   datetime OrderExpiration() {if(ValidSelectedOrder()) return(m_SelectedOrder.Expiration()); else return((datetime)0);}
   /// Size of selected virtual order. Use OrderSelect() first
   double OrderLots() {if(ValidSelectedOrder()) return(m_SelectedOrder.Lots()); else return(0.0);}
   /// Magic number of selected virtual order. Use OrderSelect() first
   long OrderMagicNumber() {if(ValidSelectedOrder()) return(m_SelectedOrder.MagicNumber()); else return(0);}
   /// Modify a virtual order.
   bool OrderModify(long ticket,double price,int nStopLoss,int nTakeProfit,datetime expiration,color arrow_color=CLR_NONE);
   bool OrderModify(long ticket,double price,double stoploss,double takeprofit,datetime expiration,color arrow_color=CLR_NONE);
   /// Open price for selected virtual order. Use OrderSelect() first
   double OrderOpenPrice() {if(ValidSelectedOrder()) return(m_SelectedOrder.OpenPrice()); else return(0.0);}
   /// Open time for selected virtual order. Use OrderSelect() first
   datetime OrderOpenTime() {if(ValidSelectedOrder()) return(m_SelectedOrder.OpenTime()); else return((datetime)0);}
   /// Profit for selected virtual order. Use OrderSelect() first
   double OrderProfit() {if(ValidSelectedOrder()) return(m_SelectedOrder.Profit()); else return(0.0);}
   /// Select an open virtual order.
   bool OrderSelect(long index,ENUM_VIRTUAL_SELECT_TYPE type,ENUM_VIRTUAL_SELECT_MODE pool=MODE_TRADES);
   /// Send a virtual order.
   long OrderSend(string symbol,ENUM_VIRTUAL_ORDER_TYPE cmd,double volume,double price,int slippage,double stoploss,double takeprofit,int timestop,string comment="",datetime expiration=0,color arrow_color=CLR_NONE);
   /// Send a virtual order.
   long OrderSend(string symbol,ENUM_VIRTUAL_ORDER_TYPE cmd,double volume,double price,int slippage,double stoploss,double takeprofit,string comment="",datetime expiration=0,color arrow_color=CLR_NONE);
   /// Number of closed virtual orders in history.
   int OrdersHistoryTotal() {return(m_OrderHistory.Total());}
   /// Stoploss for selected virtual order. Use OrderSelect() first
   double OrderStopLoss() {if(ValidSelectedOrder()) return(m_SelectedOrder.StopLoss()); else return(0.0);}
   /// Symbol for selected virtual order. Use OrderSelect() first
   string OrderSymbol() {if(ValidSelectedOrder()) return(m_SelectedOrder.Symbol()); else return("");}
   /// Take profit for selected virtual order. Use OrderSelect() first
   double OrderTakeProfit() {if(ValidSelectedOrder()) return(m_SelectedOrder.TakeProfit()); else return(0.0);}
   /// Number of open virtual orders.
   int OrdersTotal() {return(m_OpenOrders.Total());}
   /// Ticket for selected virtual order. Use OrderSelect() first
   long OrderTicket() {return(m_SelectedOrder.Ticket());}
   /// Type of selected virtual order. Use OrderSelect() first
   int OrderType() {return(m_SelectedOrder.OrderType());}
   /// Sends Buy or Sell orders to adjust real server position size.
   bool PositionChangeSizeAtServer(string strSymbol,double dblLots,ENUM_ORDER_TYPE OrderType,double dblStopLoss);
   /// Modifies real server StopLoss.
   bool PositionSetTightestStopAtServer(string strSymbol);
   /// Simple market sell order.
   long Sell(string strSymbol,double dblLots,const int nStoploss,const int nTakeprofit,string strComment="");
   /// Simple market sell order with timestop.
   long Sell(string strSymbol,double dblLots,const int nStoploss,const int nTakeprofit,const int nTimeStopBars,string strComment="");
   /// Trailing current orders
   void DoTrailing(string symb);
   /// Open time of current incomplete bar
   datetime Time0(){return(m_dtTime0);}
   string OneLineStatus();
   /// Checks that the selected order pointer is valid
   bool ValidSelectedOrder()
     {
      if(CheckPointer(m_SelectedOrder)==POINTER_INVALID)
        {
         LogFile.Log(LOG_PRINT,__FUNCTION__,"Error: m_SelectedOrder pointer is not valid");
         return(false);
        }
      else
        {
         return(true);
        }
     }
  };

// Global declaration
CVirtualOrderManager VOM;
//+------------------------------------------------------------------+
/// Destructor freeing all resources.
//+------------------------------------------------------------------+
CVirtualOrderManager::~CVirtualOrderManager()
  {
   if(CheckPointer(m_SelectedOrder)!=POINTER_INVALID) delete(m_SelectedOrder);
  }
//+------------------------------------------------------------------+
/// Notifies all other open charts of a virtual trade event.
//+------------------------------------------------------------------+
void CVirtualOrderManager::BroadcastVirtualTradeEvent()
  {
   long lChartID=ChartFirst();
   while(lChartID>=0)
     {
      if(lChartID!=ChartID())
        {
         LogFile.Log(LOG_DEBUG,__FUNCTION__);
         EventChartCustom(lChartID,Config.CustomVirtualOrderEvent,0,0.0,"");
        }
      lChartID=ChartNext(lChartID);
     }
  }
//+------------------------------------------------------------------+
/// Simple market buy order.
/// \param strSymbol		Order symbol
/// \param nStopLoss		stoploss pips away from open price
/// \param nTakeProfit	takeprofit pips away from open price
/// \param strComment	Order comment
/// \return 				Order ticket, or -1 if not successful
//+------------------------------------------------------------------+
long CVirtualOrderManager::Buy(string strSymbol,double dblLots,const int nStoploss,const int nTakeprofit,string strComment/*=""*/)
  {
   if(strComment=="") strComment=MQL5InfoString(MQL5_PROGRAM_NAME);
   LogFile.Log(LOG_DEBUG,__FUNCTION__,StringFormat("(%s,%0.2f,%d,%d,%s)",strSymbol,dblLots,nStoploss,nTakeprofit,strComment));
   double sl,tp;
   double dblPrice=SymbolInfoDouble(strSymbol,SYMBOL_ASK);
   double dblPoint=SymbolInfoDouble(strSymbol,SYMBOL_POINT);
   sl =nStoploss==0 ? 0.0 : dblPrice-nStoploss*dblPoint;
   tp =nTakeprofit==0 ? 0.0 : dblPrice+nTakeprofit*dblPoint;
   return(VOM.OrderSend(strSymbol,VIRTUAL_ORDER_TYPE_BUY,dblLots,dblPrice,Config.Deviation,sl,tp,strComment,0));
  }
//+------------------------------------------------------------------+
/// Simple market buy order.
/// \param strSymbol		Order symbol
/// \param nStopLoss		stoploss pips away from open price
/// \param nTakeProfit	takeprofit pips away from open price
/// \param nTimeStopBars timestop 
/// \param strComment	Order comment
/// \return 				Order ticket, or -1 if not successful
//+------------------------------------------------------------------+
long CVirtualOrderManager::Buy(string strSymbol,double dblLots,const int nStoploss,const int nTakeprofit,const int nTimeStopBars,string strComment/*=""*/)
  {
   if(strComment=="") strComment=MQL5InfoString(MQL5_PROGRAM_NAME);
   LogFile.Log(LOG_DEBUG,__FUNCTION__,StringFormat("(%s,%0.2f,%d,%d,%s)",strSymbol,dblLots,nStoploss,nTakeprofit,strComment));
   double sl,tp;
   double dblPrice=SymbolInfoDouble(strSymbol,SYMBOL_ASK);
   double dblPoint=SymbolInfoDouble(strSymbol,SYMBOL_POINT);
   sl =nStoploss==0 ? 0.0 : dblPrice-nStoploss*dblPoint;
   tp =nTakeprofit==0 ? 0.0 : dblPrice+nTakeprofit*dblPoint;
   return(VOM.OrderSend(strSymbol,VIRTUAL_ORDER_TYPE_BUY,dblLots,dblPrice,Config.Deviation,sl,tp,nTimeStopBars,strComment,0));
  }
//+------------------------------------------------------------------+
/// Close all orders for symbol and type
/// \param [in] strSymbol
/// \param [in] Type			Order type
/// \return						True if successful, false otherwise
//+------------------------------------------------------------------+
bool CVirtualOrderManager::CloseAllOrders(string strSymbol,ENUM_VIRTUAL_ORDER_TYPE Type)
  {
   LogFile.Log(LOG_DEBUG,__FUNCTION__,_Symbol,",",VirtualOrderTypeToStr(Type));
   for(int i=m_OpenOrders.Total()-1;i>=0;i--)
     {
      CVirtualOrder *vo=m_OpenOrders.VirtualOrder(i);
      if(vo.MagicNumber()==MagicNumber())
         if(vo.OrderType()==Type)
            if(vo.Symbol()==strSymbol)
               if(!OrderClose(vo.Ticket(),Config.Deviation))
                 {
                  return(false);
                 }
     }
   return(true);
  }
//+------------------------------------------------------------------+
/// Called from EA OnInit().
/// Allocates resources and establishes status \n
/// Include the following in each EA that uses VirtualOrderManager
/// \code
/// // EA code
/// void OnInit()
///  {
///   VOM.Initialise();
///   //
///   // continue with other init handling in this EA
///   // ....
/// \endcode
//+------------------------------------------------------------------+
void CVirtualOrderManager::Initialise(long lMagicNumber/*=-1*/, int minProfit = 0, int tStop = 0, int tStep = 0)
  {
// restore previous state
   m_OpenOrders.PersistFilename(StringFormat("%s%s_%s_%s_OpenOrders.csv",Config.FileBase,_Symbol,PeriodToString(_Period),MQL5InfoString(MQL5_PROGRAM_NAME)));
   m_OpenOrders.ReadFromFile();
   m_OpenOrders.Clear(MagicNumber());
   m_OpenOrders.WriteToFile();

   m_OrderHistory.PersistFilename(StringFormat("%s%s_%s_%s_OrderHistory.csv",Config.FileBase,_Symbol,PeriodToString(_Period),MQL5InfoString(MQL5_PROGRAM_NAME)));
   m_OrderHistory.Clear();
   m_OrderHistory.ReadFromFile();

   m_nLastBars=Bars(_Symbol,Period());
   //m_bNewBar=false;
   if(lMagicNumber==-1)
      MakeMagic();
   else
      m_lMagicNumber=lMagicNumber;
   LogFile.Log(LOG_PRINT,__FUNCTION__," - System ID or Magic Number is ",(string)m_lMagicNumber);

   datetime Arr[];
   if(CopyTime(_Symbol,_Period,0,1,Arr)!=1)
     {
      m_dtTime0=0;
      LogFile.Log(LOG_MAJOR,__FUNCTION__," error - unable to obtain bar time");
     }
   else
     {
      m_dtTime0=Arr[0];
     }
   _minProfit = minProfit;
   _trailingStop = tStop;
   _trailingStep = tStep;
  }
//+------------------------------------------------------------------+
/// Has there been an order closed in this bar?
//+------------------------------------------------------------------+
bool CVirtualOrderManager::LastOrderCloseInBar(string strSymbol/*=""*/)
  {
   if(strSymbol=="") strSymbol=_Symbol;
// Only look though most recent 100 trades for last order closed by this system
   int nMaxLookback=(int)MathMax(0,OrdersHistoryTotal()-100);

   for(int nPosition=OrdersHistoryTotal()-1;nPosition>=nMaxLookback;nPosition--)
     {
      CVirtualOrder *vo=m_OrderHistory.VirtualOrder(nPosition);
      if(vo.MagicNumber()==MagicNumber())
         if(vo.Symbol()==strSymbol)
           {
            return(vo.CloseTime()>=Time0());
           }
     }
   return(false);
  }
//+------------------------------------------------------------------+
/// Creates a unique magic number from the EA symbol, chart period and name.
/// Uses a character to number hash approach, thanks to 
/// - http://forum.mql4.com/25432/page4
/// - http://www.cse.yorku.ca/~oz/hash.html
//+------------------------------------------------------------------+
long CVirtualOrderManager::MakeMagic(string strSymbol/*=""*/)
  {
   if(strSymbol=="") strSymbol=_Symbol;
   string s=strSymbol+PeriodToString(Period())+MQL5InfoString(MQL5_PROGRAM_NAME);
   ulong ulHash=5381;
   for(int i=StringLen(s)-1;i>=0;i--)
     {
      ulHash=((ulHash<<5)+ulHash)+StringGetCharacter(s,i);
     }
// need to convert back to long and ensure positive because MT5 functions in general do not support ulong
   m_lMagicNumber=(long)ulHash;
   if(m_lMagicNumber<0) m_lMagicNumber=-m_lMagicNumber;
   return(m_lMagicNumber);
  }
//+------------------------------------------------------------------+
/// Called from EA OnTick().
/// Actions virtual stoplosses, takeprofits \n
/// Include the following in each EA that uses VirtualOrderManager
/// \code
/// // EA code
/// void OnTick()
///  {
///   // action virtual stoplosses, takeprofits
///   VOM.OnTick();
///   //
///   // continue with other tick event handling in this EA
///   // ....
/// \endcode
//+------------------------------------------------------------------+
void CVirtualOrderManager::OnTick()
  {
   uint uDaysSince1970=(uint)TimeLocal()/(3600*24);
   static uint uLastDaysSince1970=0;
   if(uLastDaysSince1970<uDaysSince1970)
     {
      LogFile.Log(LOG_PRINT,__FUNCTION__," - startup tick or first local time tick of new day");
      uLastDaysSince1970=uDaysSince1970;
     }

// Set m_bNewBar to true for one tick at the beginning of each bar
   int nBars=Bars(_Symbol,PERIOD_CURRENT);
   if(m_nLastBars!=nBars)
     {
      m_nLastBars=nBars;
      m_bNewBar=true;
      datetime Arr[1];
      if(CopyTime(_Symbol,_Period,0,1,Arr)!=1)
        {
         m_dtTime0=0;
         LogFile.Log(LOG_MAJOR,__FUNCTION__," error - unable to obtain bar time");
        }
      else
        {
         m_dtTime0=Arr[0];
        }
     }
   else
     {
      m_bNewBar=false;
     }

   if(m_OpenOrders.OpenLots(Symbol())!=0 && OpenLots(Symbol())==0)
     {
      // assume that a server side stoploss event has occurred
      // and close all virtual open orders without sending anything to the server
      LogFile.Log(LOG_PRINT,__FUNCTION__,StringFormat(" - warning: virtual open lots = %0.2f ; server open lots = 0. Assume a server stoploss event has occurred; closing all virtual orders",m_OpenOrders.OpenLots(Symbol())/1000.0));
      for(int i=m_OpenOrders.Total()-1;i>=0;i--)
        {
         CVirtualOrder* vo=m_OpenOrders.VirtualOrder(i);
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
   for(int i=m_OpenOrders.Total()-1;i>=0;i--)
     {
      CVirtualOrder *vo=m_OpenOrders.VirtualOrder(i);
      LogFile.Log(LOG_DEBUG,__FUNCTION__," looking at order ",(string)vo.Ticket()," with magic ",(string)vo.MagicNumber()," for ",vo.Symbol());
      if(vo.MagicNumber()==MagicNumber())
         if(vo.Symbol()==_Symbol)
           {
            switch(vo.CheckStopsAndLimits())
              {
               case VIRTUAL_ORDER_EVENT_NONE:
                  break;

               case VIRTUAL_ORDER_EVENT_BUY_TRIGGER:
                  if(PositionChangeSizeAtServer(vo.Symbol(),vo.Lots(),ORDER_TYPE_BUY,vo.StopLoss()))
                    {
                     vo.PendingOrderTrigger();
                     m_OpenOrders.WriteToFile();
                     BroadcastVirtualTradeEvent();
                     PositionSetTightestStopAtServer(_Symbol);
                    }
                  break;

               case VIRTUAL_ORDER_EVENT_SELL_TRIGGER:
                  if(PositionChangeSizeAtServer(vo.Symbol(),vo.Lots(),ORDER_TYPE_SELL,vo.StopLoss()))
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
                  OrderClose(vo.Ticket(),Config.Deviation);
                  break;

               default:
                  LogFile.Log(LOG_PRINT,__FUNCTION__," error: invalid Virtual Order Event");
              } // switch vo.CheckStopsAndLimits()
           } // if
     } // i
  }
//+------------------------------------------------------------------+
/// Orders opened since beginning of bar.
//+------------------------------------------------------------------+
int CVirtualOrderManager::OpenedOrdersInSameBar(string strSymbol/*=""*/)
  {
   if(strSymbol=="") strSymbol=_Symbol;
   int nOpenOrders=0;

   for(int nPosition=OrdersTotal()-1;nPosition>=0;nPosition--)
     {
      CVirtualOrder *vo=m_OpenOrders.VirtualOrder(nPosition);
      if(vo.MagicNumber()==MagicNumber())
         if(vo.Symbol()==strSymbol)
           {
            if(vo.OpenTime()>=Time0()) nOpenOrders++;
           }
     }
   return(nOpenOrders);
  }
//+------------------------------------------------------------------+
/// Close a virtual order.
/// \param [in] ticket			Open virtual order ticket
/// \param [in] slippage		also known as deviation.  Typical value is 50
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool CVirtualOrderManager::OrderClose(long ticket,int slippage,color Color=CLR_NONE)
  {
   LogFile.Log(LOG_DEBUG,__FUNCTION__,"(",(string)ticket,",",(string)slippage,")");
   int nVoIndex=m_OpenOrders.TicketToIndex(ticket);
   if(nVoIndex==-1)
     {
      LogFile.Log(LOG_DEBUG,__FUNCTION__," warning: invalid ticket - no action");
      return(false);
     }
   CVirtualOrder *vo=m_OpenOrders.VirtualOrder(nVoIndex);
   m_GlobalVirtualStopList.Delete(vo.Ticket());

   bool bSuccess=false;
   switch(vo.OrderType())
     {
      case VIRTUAL_ORDER_TYPE_BUY:
         bSuccess=PositionChangeSizeAtServer(vo.Symbol(),vo.Lots(),ORDER_TYPE_SELL,0);
         break;
      case VIRTUAL_ORDER_TYPE_SELL:
         bSuccess=PositionChangeSizeAtServer(vo.Symbol(),vo.Lots(),ORDER_TYPE_BUY,0);
         break;
      default:
         LogFile.Log(LOG_PRINT,__FUNCTION__," error: invalid ordertype");
     }

   if(bSuccess)
     {
      // proceed with virtual closure and transfer details from open to closed list
      vo.Close();
      // Detach removes element from array but doesn't delete object
      m_OpenOrders.Detach(nVoIndex);
      m_OrderHistory.Add(vo);
      PositionSetTightestStopAtServer(vo.Symbol());
      m_OpenOrders.WriteToFile();
      m_OrderHistory.WriteToFile();
      BroadcastVirtualTradeEvent();
      return(true);
     }
   else
     {
      // reverse deletion of stoploss
      m_GlobalVirtualStopList.Add(vo.Ticket(),vo.Symbol(),vo.OrderType(),vo.StopLoss());
      return(false);
     }
  }
//+------------------------------------------------------------------+
/// Delete a pending virtual order.
//+------------------------------------------------------------------+
bool CVirtualOrderManager::OrderDelete(long ticket)
  {
   LogFile.Log(LOG_DEBUG,__FUNCTION__,"(",(string)ticket,")");
   int nVoIndex=m_OpenOrders.TicketToIndex(ticket);

   if(nVoIndex==-1)
     {
      LogFile.Log(LOG_DEBUG,__FUNCTION__," warning: invalid ticket - no action");
      return(false);
     }

   CVirtualOrder *vo=m_OpenOrders.VirtualOrder(nVoIndex);
   if(vo.OrderType()==VIRTUAL_ORDER_TYPE_BUY || vo.OrderType()==VIRTUAL_ORDER_TYPE_SELL || vo.Status()==VIRTUAL_ORDER_STATUS_OPEN)
     {
      LogFile.Log(LOG_PRINT,__FUNCTION__," error: cannot delete an open order");
      return(false);
     }

// proceed with virtual deletion and transfer details from open to closed list
   vo.Delete();
// Detach removes element from array but doesn't delete object
   m_OpenOrders.Detach(nVoIndex);
   m_OpenOrders.WriteToFile();
   BroadcastVirtualTradeEvent();

   m_OrderHistory.Add(vo);
   m_OrderHistory.WriteToFile();
   return(true);
  }
//+------------------------------------------------------------------+
/// Modify a virtual order.
/// <b> Only market orders in this version. </b>
/// \param [in] ticket			Open virtual order ticket
/// \param [in] price			Open price
/// \param [in] nStopLoss		Integer stop loss distance from open price, or zero for none
/// \param [in] nTakeProfit	Integer take profit distance from open price, or zero for none
/// \param [in] expiration 	Default=0 (1/1/1970)
/// \param [in] arrow_color 	Default=CLR_NONE.  This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool CVirtualOrderManager::OrderModify(long ticket,double price,int nStopLoss,int nTakeProfit,datetime expiration,color arrow_color=CLR_NONE)
  {
   LogFile.Log(LOG_DEBUG,__FUNCTION__,StringFormat("(%d,%0.5f,%d,%d,%s,%s)",ticket,price,nStopLoss,nTakeProfit,TimeToString(expiration)));

   int nIndex=m_OpenOrders.TicketToIndex(ticket);
   if(nIndex<0) return(false);

   CVirtualOrder *vo=m_OpenOrders.VirtualOrder(nIndex);
   double stoploss=0.0;
   double takeprofit=0.0;
   double dblPoint=SymbolInfoDouble(vo.Symbol(),SYMBOL_POINT);

   if(price==0.0) price=vo.OpenPrice();

   switch(vo.OrderType())
     {
      case VIRTUAL_ORDER_TYPE_BUYSTOP:
      case VIRTUAL_ORDER_TYPE_BUYLIMIT:
      case VIRTUAL_ORDER_TYPE_BUY:
         stoploss=nStopLoss==0 ? 0.0 : price-nStopLoss*dblPoint;
         takeprofit=nTakeProfit==0 ? 0.0 : price+nTakeProfit*dblPoint;
         break;

      case VIRTUAL_ORDER_TYPE_SELLSTOP:
      case VIRTUAL_ORDER_TYPE_SELLLIMIT:
      case VIRTUAL_ORDER_TYPE_SELL:
         stoploss=nStopLoss==0 ? 0.0 : price+nStopLoss*dblPoint;
         takeprofit=nTakeProfit==0 ? 0.0 : price-nTakeProfit*dblPoint;
         break;

      default:
         LogFile.Log(LOG_PRINT,__FUNCTION__," error: invalid order type");
     }

   return(OrderModify(ticket,price,stoploss,takeprofit,expiration,arrow_color));
  }
//+------------------------------------------------------------------+
/// Modify a virtual order.
/// <b> Only market orders in this version. </b>
/// \param [in] ticket			Open virtual order ticket
/// \param [in] price			Open price
/// \param [in] stoploss		Stop loss value, or zero for none
/// \param [in] takeprofit		Take profit value, or zero for none
/// \param [in] expiration 	Default=0 (1/1/1970)
/// \param [in] arrow_color 	Default=CLR_NONE.  This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool CVirtualOrderManager::OrderModify(long ticket,double price,double stoploss,double takeprofit,datetime expiration,color arrow_color=CLR_NONE)
  {

   LogFile.Log(LOG_DEBUG,__FUNCTION__,StringFormat("(%d,%0.5f,%0.5f,%0.5f,%s,%s)",ticket,price,stoploss,takeprofit,TimeToString(expiration)));
   CVirtualOrder *vo=m_OpenOrders.AtTicket(ticket);
   if(vo==NULL)
     {
      LogFile.Log(LOG_PRINT,__FUNCTION__," error: virtual order ticket ",(string)ticket," not found");
      return(false);
     }

   bool bSuccess=vo.Modify(price,stoploss,takeprofit,expiration);

   if(bSuccess)
     {
      if(vo.Status()==VIRTUAL_ORDER_STATUS_OPEN)
        {
         if(!PositionSetTightestStopAtServer(vo.Symbol()))
           {
            LogFile.Log(LOG_PRINT,__FUNCTION__," error: failed to modify stoploss at server");
            return(false);
           }
        }
      m_OpenOrders.WriteToFile();
      BroadcastVirtualTradeEvent();
      LogFile.Log(LOG_DEBUG,__FUNCTION__," success");
      return(true);
     }
   else
     {
      LogFile.Log(LOG_DEBUG,__FUNCTION__," failure");
      return(false);
     }
  }
//+------------------------------------------------------------------+
/// Select an open virtual order.
/// \param [in] i			Either index or ticket
/// \param [in] type		Either SELECT_BY_POS or SELECT_BY_TICKET		
/// \param [in] pool		Either MODE_TRADES (default) or MODE_HISTORY
/// \return					True if successful, false otherwise
//+------------------------------------------------------------------+
bool CVirtualOrderManager::OrderSelect(long i,ENUM_VIRTUAL_SELECT_TYPE type,ENUM_VIRTUAL_SELECT_MODE pool=MODE_TRADES)
  {
   switch(type)
     {
      case SELECT_BY_POS:
         switch(pool)
           {
            case MODE_TRADES: m_SelectedOrder = m_OpenOrders.VirtualOrder((int)i); return(true);
            case MODE_HISTORY: m_SelectedOrder = m_OrderHistory.VirtualOrder((int)i); return(true);
            default:
               LogFile.Log(LOG_PRINT,__FUNCTION__," error: Unknown pool id ",(string)pool);
               return(false);
           }
         break;
      case SELECT_BY_TICKET:
         switch(pool)
           {
            case MODE_TRADES: m_SelectedOrder = m_OpenOrders.AtTicket(i); return(true);
            case MODE_HISTORY: m_SelectedOrder = m_OrderHistory.AtTicket(i); return(true);
            default:
               LogFile.Log(LOG_PRINT,__FUNCTION__," error: Unknown pool id ",(string)pool);
               return(false);
           }
         break;
      default:
         LogFile.Log(LOG_PRINT,__FUNCTION__," error: Unknown type ",(string)type);
         return(false);
     }
  }
//+------------------------------------------------------------------+
/// Send a virtual order.
/// \param [in] symbol			Order symbol.  Both 6 chars (eg EURUSD) and full name (eg EURUSDm) are valid
/// \param [in] cmd				VIRTUAL_ORDER_TYPE_BUY or VIRTUAL_ORDER_TYPE_SELL 
/// \param [in] volume			Order lots
/// \param [in] price			Open price
/// \param [in] slippage		also known as deviation.  Typical value is 50
/// \param [in] stoploss		Stop loss value, or zero for none
/// \param [in] takeprofit		Take profit value, or zero for none
/// \param [in] comment			String comment, typically Expert Advisor name
/// \param [in] expiration 	Default=0 (1/1/1970)
/// \param [in] arrow_color 	Default=CLR_NONE.  This parameter is provided for MT4 compatibility and is not used.
/// \return							Order ticket if successful, -1 if not
//+------------------------------------------------------------------+
long CVirtualOrderManager::OrderSend(string symbol,ENUM_VIRTUAL_ORDER_TYPE cmd,double volume,double price,int slippage,double stoploss,double takeprofit,string comment="",datetime expiration=0,color arrow_color=CLR_NONE)
  {
   LogFile.Log(LOG_DEBUG,__FUNCTION__,StringFormat("(%s,%s,%0.2f,%0.5f,%d,%0.5f,%0.5f,%s,%s)",symbol,VirtualOrderTypeToStr(cmd),volume,price,slippage,stoploss,takeprofit,comment,TimeToString(expiration)));

   bool bSuccess=false;
   switch(cmd)
     {
      case VIRTUAL_ORDER_TYPE_BUY:
         bSuccess=PositionChangeSizeAtServer(symbol,volume,ORDER_TYPE_BUY,stoploss); break;
      case VIRTUAL_ORDER_TYPE_SELL:
         bSuccess=PositionChangeSizeAtServer(symbol,volume,ORDER_TYPE_SELL,stoploss); break;

      case VIRTUAL_ORDER_TYPE_BUYSTOP:
      case VIRTUAL_ORDER_TYPE_BUYLIMIT:
      case VIRTUAL_ORDER_TYPE_SELLSTOP:
      case VIRTUAL_ORDER_TYPE_SELLLIMIT:
         // no action at server
         bSuccess=true;
         break;

      default:
         LogFile.Log(LOG_PRINT,__FUNCTION__," error: Invalid ENUM_VIRTUAL_ORDER_TYPE");
         return(-1);
     }

   if(bSuccess)
     {
      CVirtualOrder *vo=new CVirtualOrder;
      vo.Send(symbol,cmd,volume,price,stoploss,takeprofit,comment,MagicNumber(),expiration);
      m_OpenOrders.Add(vo);
      m_OpenOrders.WriteToFile();
      BroadcastVirtualTradeEvent();

      LogFile.Log(LOG_DEBUG,__FUNCTION__,"(",vo.Trace(),") returning ",(string)vo.Ticket());
      PositionSetTightestStopAtServer(symbol);
      return(vo.Ticket());
     }
   else
     {
      LogFile.Log(LOG_PRINT,__FUNCTION__," error: failed to adjust position at server, returning -1");
      return(-1);
     }
  }
//+------------------------------------------------------------------+
/// Send a virtual order.
/// \param [in] symbol			Order symbol.  Both 6 chars (eg EURUSD) and full name (eg EURUSDm) are valid
/// \param [in] cmd				VIRTUAL_ORDER_TYPE_BUY or VIRTUAL_ORDER_TYPE_SELL 
/// \param [in] volume			Order lots
/// \param [in] price			Open price
/// \param [in] slippage		also known as deviation.  Typical value is 50
/// \param [in] stoploss		Stop loss value, or zero for none
/// \param [in] takeprofit		Take profit value, or zero for none
/// \param [in] timestop		timestop bars
/// \param [in] comment			String comment, typically Expert Advisor name
/// \param [in] expiration 	Default=0 (1/1/1970)
/// \param [in] arrow_color 	Default=CLR_NONE.  This parameter is provided for MT4 compatibility and is not used.
/// \return							Order ticket if successful, -1 if not
//+------------------------------------------------------------------+
long CVirtualOrderManager::OrderSend(string symbol,ENUM_VIRTUAL_ORDER_TYPE cmd,double volume,double price,int slippage,double stoploss,double takeprofit,int timestop,string comment="",datetime expiration=0,color arrow_color=CLR_NONE)
  {
   LogFile.Log(LOG_DEBUG,__FUNCTION__,StringFormat("(%s,%s,%0.2f,%0.5f,%d,%0.5f,%0.5f,%s,%s)",symbol,VirtualOrderTypeToStr(cmd),volume,price,slippage,stoploss,takeprofit,comment,TimeToString(expiration)));

   bool bSuccess=false;
   switch(cmd)
     {
      case VIRTUAL_ORDER_TYPE_BUY:
         bSuccess=PositionChangeSizeAtServer(symbol,volume,ORDER_TYPE_BUY,stoploss); break;
      case VIRTUAL_ORDER_TYPE_SELL:
         bSuccess=PositionChangeSizeAtServer(symbol,volume,ORDER_TYPE_SELL,stoploss); break;

      case VIRTUAL_ORDER_TYPE_BUYSTOP:
      case VIRTUAL_ORDER_TYPE_BUYLIMIT:
      case VIRTUAL_ORDER_TYPE_SELLSTOP:
      case VIRTUAL_ORDER_TYPE_SELLLIMIT:
         // no action at server
         bSuccess=true;
         break;

      default:
         LogFile.Log(LOG_PRINT,__FUNCTION__," error: Invalid ENUM_VIRTUAL_ORDER_TYPE");
         return(-1);
     }

   if(bSuccess)
     {
      CVirtualOrder *vo=new CVirtualOrder;
      vo.Send(symbol,cmd,volume,price,stoploss,takeprofit,comment,MagicNumber(),expiration);
      vo.TimeStopBars(timestop);
      m_OpenOrders.Add(vo);
      m_OpenOrders.WriteToFile();
      BroadcastVirtualTradeEvent();

      LogFile.Log(LOG_DEBUG,__FUNCTION__,"(",vo.Trace(),") returning ",(string)vo.Ticket());
      PositionSetTightestStopAtServer(symbol);
      return(vo.Ticket());
     }
   else
     {
      LogFile.Log(LOG_PRINT,__FUNCTION__," error: failed to adjust position at server, returning -1");
      return(-1);
     }
  }
//+------------------------------------------------------------------+
/// Returns positive lots if position is long and negative lots if short.
/// \param [in]   strSymbol   Symbol
/// \return       +/-Lots * 1000
//+------------------------------------------------------------------+
int CVirtualOrderManager::OpenLots(string strSymbol/*=""*/)
  {
   if(strSymbol=="") strSymbol=_Symbol;
   int nLots=0;
// because there is only ever one position per symbol, don't need to run through all open positions
   if(PositionSelect(strSymbol))
     {
      switch(PositionGetInteger(POSITION_TYPE))
        {
         case POSITION_TYPE_BUY:
            nLots=(int)MathRound(PositionGetDouble(POSITION_VOLUME)*1000);
            break;

         case POSITION_TYPE_SELL:
            nLots=-(int)MathRound(PositionGetDouble(POSITION_VOLUME)*1000);
            break;

         default:
            LogFile.Log(LOG_PRINT,__FUNCTION__," problem with POSITION_TYPE");
        }
     }
   LogFile.Log(LOG_VERBOSE,__FUNCTION__,"(",strSymbol,") returning ",(string)nLots);
   return(nLots);
  }
//+------------------------------------------------------------------+
/// Sends Buy or Sell orders to adjust real server position size.
/// Server StopLoss is set to the tightest StopLoss of all open virtual positions plus ServerStopLossMargin in CConfig
/// \param [in]   strSymbol   Symbol
/// \param [in]   dblLots     Size of order
/// \param [in]	OrderType	Buy or Sell
/// \param [in]	dblStopLoss
/// \return       True if successful, false otherwise 
//+------------------------------------------------------------------+
bool CVirtualOrderManager::PositionChangeSizeAtServer(string strSymbol,double dblLots,ENUM_ORDER_TYPE OrderType,double dblStopLoss)
  {
   long n=SymbolInfoInteger(strSymbol,SYMBOL_DIGITS);

   LogFile.Log(LOG_PRINT,__FUNCTION__,StringFormat("(%s,%0.2f,%s,%0."+(string)n+"f)",strSymbol,dblLots,OrderTypeToString(OrderType),dblStopLoss));

   double dblTightestLongStop=0.0;
   double dblTightestShortStop=0.0;
   m_GlobalVirtualStopList.TightestStops(strSymbol,dblTightestShortStop,dblTightestLongStop);

   MqlTick CurrentTick;
   SymbolInfoTick(strSymbol,CurrentTick);
   long lDigits=SymbolInfoInteger(strSymbol,SYMBOL_DIGITS);
   double dblPoint=SymbolInfoDouble(strSymbol,SYMBOL_POINT);

   MqlTradeRequest MtRequest; ZeroMemory(MtRequest);
   int nCurrentLots=OpenLots(strSymbol);
   int nTargetLots=0;
   switch(OrderType)
     {
      case ORDER_TYPE_BUY:
         nTargetLots=nCurrentLots+(int)MathRound(dblLots*1000);
         MtRequest.price=CurrentTick.ask;
         dblTightestLongStop=MathMax(dblTightestLongStop,dblStopLoss);
         MtRequest.sl=dblTightestLongStop==0.0 ? 0.0 : NormalizeDouble(dblTightestLongStop-Config.ServerStopLossMargin*dblPoint,(int)lDigits);
         break;

      case ORDER_TYPE_SELL:
         nTargetLots=nCurrentLots-(int)MathRound(dblLots*1000);
         MtRequest.price=CurrentTick.bid;
         if(dblStopLoss!=0.0) dblTightestShortStop=MathMin(dblTightestShortStop,dblStopLoss);
         if(dblTightestShortStop==DBL_MAX || dblTightestShortStop==0)
            MtRequest.sl=0.0;
         else
            MtRequest.sl=NormalizeDouble(dblTightestShortStop+Config.ServerStopLossMargin*dblPoint,(int)lDigits);
         break;

      default:
         LogFile.Log(LOG_PRINT,__FUNCTION__," error: Invalid ordertype");
         return(false);
     }

   MtRequest.tp=0.0;
   MtRequest.action= TRADE_ACTION_DEAL;
   MtRequest.magic = MagicNumber();
   MtRequest.symbol = strSymbol;
   MtRequest.volume = NormalizeDouble(dblLots,2);
   MtRequest.deviation=10;
   MtRequest.type=OrderType;
   MtRequest.type_filling=ORDER_FILLING_FOK;

   LogFile.Log(LOG_DEBUG,__FUNCTION__,StringFormat(" attempting %s for %s at %0.5G with stoploss %0.5G, volume %0.2f, magic %d",OrderTypeToString(OrderType),strSymbol,MtRequest.price,MtRequest.sl,MtRequest.volume, MtRequest.magic));
   MqlTradeCheckResult MtCheckResult;
   ::ResetLastError();
   if(OrderCheck(MtRequest,MtCheckResult))
     {
      MqlTradeResult MtResult;
      OrderSend(MtRequest,MtResult);
      LogFile.Log(LOG_DEBUG,__FUNCTION__," result of OrderSend TRADE_ACTION_DEAL to server: ",ReturnCodeDescription(MtResult.retcode));
      return(true);
     }
   else
     {
      LogFile.Log(LOG_PRINT,__FUNCTION__," error: Problem with OrderSend TRADE_ACTION_DEAL, return code ",ReturnCodeDescription(MtCheckResult.retcode),". OrderCheck() returned ",ErrorDescription(::GetLastError()));
      return(false);
     }
  }
//+------------------------------------------------------------------+
/// Modifies real server StopLoss.
/// Note that Virtual Order Manager doesn't run a takeprofit at the server, and pending orders are not sent to the server at all. \n
/// Server StopLoss is set to the tightest StopLoss of all open virtual positions plus ServerStopLossMargin in CConfig
/// \param [in]   nTicket		Ticket number of position to be modified
/// \return       True if successful, false otherwise 
//+------------------------------------------------------------------+
bool CVirtualOrderManager::PositionSetTightestStopAtServer(string strSymbol)
  {
   long lDigits=SymbolInfoInteger(strSymbol,SYMBOL_DIGITS);
   LogFile.Log(LOG_DEBUG,__FUNCTION__,StringFormat("(%d,%0."+(string)lDigits+"f)",strSymbol));

   int nPositionSize=OpenLots(strSymbol);

   if(nPositionSize==0)
     {
      LogFile.Log(LOG_PRINT,__FUNCTION__," - no open position; no action");
      return(true);
     }

   double dblTightestLongStop=0.0;
   double dblTightestShortStop=0.0;
   m_GlobalVirtualStopList.TightestStops(strSymbol,dblTightestShortStop,dblTightestLongStop);

   MqlTick CurrentTick;
   SymbolInfoTick(strSymbol,CurrentTick);
   double dblPoint=SymbolInfoDouble(strSymbol,SYMBOL_POINT);
   PositionSelect(strSymbol);
   double dblPositionStopLoss=PositionGetDouble(POSITION_SL);

   MqlTradeRequest MtRequest; ZeroMemory(MtRequest);

   if(nPositionSize>0)
     {
      // need long stoploss at server
      MtRequest.sl=dblTightestLongStop==0.0 ? 0.0 : NormalizeDouble(dblTightestLongStop-Config.ServerStopLossMargin*dblPoint,(int)lDigits);

     }
   else if(nPositionSize<0)
     {
      // need short stoploss at server
      if(dblTightestShortStop==DBL_MAX || dblTightestShortStop==0)
         MtRequest.sl=0.0;
      else
         MtRequest.sl=NormalizeDouble(dblTightestShortStop+Config.ServerStopLossMargin*dblPoint,(int)lDigits);
     }

   if(MathRound((MtRequest.sl-dblPositionStopLoss)/dblPoint)==0)
     {
      LogFile.Log(LOG_DEBUG,__FUNCTION__," POSITION_SL is already correct - no action");
      return(true);
     }

   MtRequest.action=TRADE_ACTION_SLTP;
   MtRequest.tp=0.0;
   MtRequest.symbol=strSymbol;

   MqlTradeCheckResult MtCheckResult;
   ::ResetLastError();
   if(OrderCheck(MtRequest,MtCheckResult))
     {
      MqlTradeResult MtResult;
      OrderSend(MtRequest,MtResult);
      LogFile.Log(LOG_DEBUG,__FUNCTION__," result of OrderSend TRADE_ACTION_SLTP to server: ",ReturnCodeDescription(MtResult.retcode));
      return(true);
     }
   else
     {
      LogFile.Log(LOG_PRINT,__FUNCTION__," error: Problem with OrderSend TRADE_ACTION_SLTP, return code ",ReturnCodeDescription(MtCheckResult.retcode),". OrderCheck() returned ",ErrorDescription(::GetLastError()));
      return(false);
     }
  }
//+------------------------------------------------------------------+
/// Simple market sell order.
/// \param strSymbol		Order symbol
/// \param nStopLoss		stoploss pips away from open price
/// \param nTakeProfit	takeprofit pips away from open price
/// \param strComment	Order comment
/// \return 				Order ticket, or -1 if not successful
//+------------------------------------------------------------------+
long CVirtualOrderManager::Sell(string strSymbol,double dblLots,const int nStoploss,const int nTakeprofit,string strComment/*=""*/)
  {
   if(strComment=="") strComment=MQL5InfoString(MQL5_PROGRAM_NAME);
   LogFile.Log(LOG_DEBUG,__FUNCTION__,StringFormat("(%s,%0.2f,%d,%d,%s)",strSymbol,dblLots,nStoploss,nTakeprofit,strComment));
   double sl,tp;
   double dblPrice=SymbolInfoDouble(strSymbol,SYMBOL_BID);
   double dblPoint=SymbolInfoDouble(strSymbol,SYMBOL_POINT);
   sl =nStoploss==0 ? 0.0 : dblPrice+nStoploss*dblPoint;
   tp =nTakeprofit==0 ? 0.0 : dblPrice-nTakeprofit*dblPoint;
   return(VOM.OrderSend(strSymbol,VIRTUAL_ORDER_TYPE_SELL,dblLots,dblPrice,Config.Deviation,sl,tp,strComment,0));
  }
//+------------------------------------------------------------------+
/// Simple market sell order.
/// \param strSymbol		Order symbol
/// \param nStopLoss		stoploss pips away from open price
/// \param nTakeProfit	takeprofit pips away from open price
/// \param strComment	Order comment
/// \return 				Order ticket, or -1 if not successful
//+------------------------------------------------------------------+
long CVirtualOrderManager::Sell(string strSymbol,double dblLots,const int nStoploss,const int nTakeprofit,const int nTimeStopBars,string strComment/*=""*/)
  {
   if(strComment=="") strComment=MQL5InfoString(MQL5_PROGRAM_NAME);
   LogFile.Log(LOG_DEBUG,__FUNCTION__,StringFormat("(%s,%0.2f,%d,%d,%s)",strSymbol,dblLots,nStoploss,nTakeprofit,strComment));
   double sl,tp;
   double dblPrice=SymbolInfoDouble(strSymbol,SYMBOL_BID);
   double dblPoint=SymbolInfoDouble(strSymbol,SYMBOL_POINT);
   sl =nStoploss==0 ? 0.0 : dblPrice+nStoploss*dblPoint;
   tp =nTakeprofit==0 ? 0.0 : dblPrice-nTakeprofit*dblPoint;
   return(VOM.OrderSend(strSymbol,VIRTUAL_ORDER_TYPE_SELL,dblLots,dblPrice,Config.Deviation,sl,tp,nTimeStopBars,strComment,0));
  }
//+------------------------------------------------------------------+
/// Simple summary of order status
/// \return One line of text
//+------------------------------------------------------------------+
string CVirtualOrderManager::OneLineStatus()
  {
   int nLongOrderCount=m_OpenOrders.OrderCount(_Symbol,VIRTUAL_ORDER_TYPE_BUY,MagicNumber());
   int nShortOrderCount=m_OpenOrders.OrderCount(_Symbol,VIRTUAL_ORDER_TYPE_SELL,MagicNumber());
   return(StringFormat(" - long orders: %d; short orders %d; open lots %0.2f",nLongOrderCount,nShortOrderCount,OpenLots()/1000.0));
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
/// Trailing orders.
/// \param strSymbol		Order symbol
/// \param nStopLoss		stoploss pips away from open price
/// \param nTakeProfit	takeprofit pips away from open price
/// \param strComment	Order comment
/// \return 				Order ticket, or -1 if not successful
//+------------------------------------------------------------------+
void CVirtualOrderManager::DoTrailing(string symb) 
{
  LogFile.Log(LOG_DEBUG,__FUNCTION__,StringFormat("(%s)",symb));
  int total = this.OrdersTotal();
  double vol, addPrice;
  int dg;
  double bid, ask, point;
  double new_sl, new_tp;
  
  if (symb=="" || symb=="0") symb=Symbol();
  dg = SymbolInfoInteger(symb, SYMBOL_DIGITS);
  bid = SymbolInfoDouble(symb, SYMBOL_BID);
  ask = SymbolInfoDouble(symb, SYMBOL_ASK);
  point=SymbolInfoDouble(symb,SYMBOL_POINT);
  vol = MathPow(10.0,dg);
  addPrice = 0.0003*vol;
  
  for (int i = 0; i < total; i++)
  {
   if ((this.OrderSelect(i, SELECT_BY_POS, MODE_TRADES)))
   {
    double openPrice = this.OrderOpenPrice();
    double sl = this.OrderStopLoss();
    
    if (this.OrderType() == VIRTUAL_ORDER_TYPE_BUY)
    {
     if (LessDoubles(openPrice, bid - _minProfit*point))
     {
      if (LessDoubles(sl, bid - (_trailingStop + _trailingStep - 1)*point) || sl == 0)
      {
       new_sl = NormalizeDouble(bid - _trailingStop*point, dg);
       new_tp = this.OrderTakeProfit();
       this.OrderModify(OrderTicket(), openPrice, new_sl, new_tp, 0, CLR_NONE);
      }
     }
    }
    
    if (OrderType() == VIRTUAL_ORDER_TYPE_SELL)
    {
     if (GreatDoubles(openPrice - ask, _minProfit*point))
     {
      if (GreatDoubles(sl, ask + (_trailingStop + _trailingStep - 1)*point) || sl == 0) 
      {
       new_sl = NormalizeDouble(ask + _trailingStop*point, dg);
       new_tp = this.OrderTakeProfit();
       this.OrderModify(OrderTicket(), openPrice, new_sl, new_tp, 0, CLR_NONE);
      }
     }
    }
   } 
  }
}