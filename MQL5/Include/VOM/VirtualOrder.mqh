//+------------------------------------------------------------------+
//|                                                 VirtualOrder.mqh |
//|                                     Copyright Paul Hampton-Smith |
//|                            http://paulsfxrandomwalk.blogspot.com |
//+------------------------------------------------------------------+
#property copyright "Paul Hampton-Smith"
#property link      "http://paulsfxrandomwalk.blogspot.com"

#include "VirtualOrderManagerConfig.mqh"
#include "Log.mqh"
#include "GlobalVariable.mqh"
#include "VirtualOrderManagerEnums.mqh"
#include <Object.mqh>
#include "ChartObjectsTradeLines.mqh"
#include "GlobalVirtualStopList.mqh"
//+------------------------------------------------------------------+
/// Maintains information and status of a virtual order.
//+------------------------------------------------------------------+
class CVirtualOrder : public CObject
  {
private:
   string m_strSymbol;
   double m_dblOpenPrice;
   double m_dblStopLoss;
   double m_dblTakeProfit;
   int m_nTimeStopBars;
   double m_dblClosePrice;
   ENUM_VIRTUAL_ORDER_TYPE m_Type;
   double m_dblLots;
   string m_strComment;
   long m_lMagic;
   datetime m_dtExpiration;
   double m_dblCurrentPrice;
   datetime m_dtOpenTime;
   datetime m_dtCloseTime;
   double m_dblCommission;
   long m_lTicket;
   ENUM_VIRTUAL_ORDER_STATUS m_Status;
   CEntryPriceLine   m_EntryPriceLine;
   CStopLossLine     m_StopLossLine;
   CTakeProfitLine   m_TakeProfitLine;
   CGlobalVirtualStopList m_GlobalVirtualStopList;

public:
   /// Constructor initialising order.
                     CVirtualOrder();
   /// Decides if an action needs to be performed on order.
   ENUM_VIRTUAL_ORDER_EVENT CheckStopsAndLimits();
   /// Close an order.
   bool Close();
   void CloseBy(){Alert("Not implemented");}
   double ClosePrice(){return(m_dblClosePrice);}
   datetime CloseTime(){return(m_dtCloseTime);}
   void Copy(CVirtualOrder *vo);
   /// Current Price.
   double CurrentPrice();
   string Comment(){return(m_strComment);}
   double Commission(){return(m_dblCommission);}
   bool Delete();
   datetime Expiration() {return(m_dtExpiration);}
   /// Live Close Price.
   double LiveClosePrice();
   double Lots() {return(m_dblLots);}
   long MagicNumber() {return(m_lMagic);}
   /// Modify this order.
   bool Modify(double price,double stoploss,double takeprofit,datetime expiration);
   /// Increments Config.VirtualOrderTicketGlobalVariable.
   long NewTicket();
   double OpenPrice() {return(m_dblOpenPrice);}
   datetime OpenTime(){return(m_dtOpenTime);}
   ENUM_VIRTUAL_ORDER_TYPE OrderType(){return(m_Type);}
   /// Convert a pending order to market order
   bool PendingOrderTrigger();
   /// Order profit.
   double Profit();
   /// Reads order line from an open file handle.
   bool ReadFromFile(int handle,bool bCreateLineObjects);
   /// Performs simple integrity check on order details.
   bool SelfCheck();
   /// Send an order.
   void Send(string symbol,ENUM_VIRTUAL_ORDER_TYPE cmd,double volume,double price,double stoploss,double takeprofit,string comment="",long magic=0,datetime expiration=0);
   ENUM_VIRTUAL_ORDER_STATUS Status() {return(m_Status);}
   double StopLoss() {return(m_dblStopLoss);}
   double StopLoss(double dblStopLoss) {return(m_dblStopLoss=dblStopLoss);}
   /// Returns short summary line of order details.
   string SummaryString();
   string Symbol() {return(m_strSymbol);}
   string TableRow();
   double TakeProfit(){return(m_dblTakeProfit);}
   long Ticket() {return(m_lTicket);}
   int TimeStopBars() {return(m_nTimeStopBars);}
   int TimeStopBars(int nTimeStopBars) {return(m_nTimeStopBars=nTimeStopBars);}
   /// Returns string line of all order details.
   string            Trace();
   /// Writes order as a line to an open file handle.
   void              WriteToFile(int handle,bool bHeader=false);
  };
//+------------------------------------------------------------------+
/// Constructor initialising order.
//+------------------------------------------------------------------+
CVirtualOrder::CVirtualOrder()
  {
   m_strSymbol="";
   m_dblOpenPrice= 0.0;
   m_dblStopLoss = 0.0;
   m_dblTakeProfit= 0.0;
   m_nTimeStopBars=0;
   m_dblClosePrice= 0.0;
   m_Type=VIRTUAL_ORDER_TYPE_UNDEFINED;
   m_dblLots=0.0;
   m_strComment="";
   m_lMagic=0;
   m_dtExpiration=0;
   m_dblCurrentPrice=0.0;
   m_dtOpenTime=0;
   m_dtCloseTime=0;
   m_dblCommission=0.0;
   m_lTicket=0;
   m_Status=VIRTUAL_ORDER_STATUS_NOT_INITIALISED;
  }
//+------------------------------------------------------------------+
/// Decides if an action needs to be performed on order.
/// - If an order is open then has its stoploss or takeprofit been hit
/// - If an order is pending then has strike price been hit
///
/// \return	Action if any.
//+------------------------------------------------------------------+
ENUM_VIRTUAL_ORDER_EVENT CVirtualOrder::CheckStopsAndLimits()
  {
   MqlTick CurrentTick;
   SymbolInfoTick(Symbol(),CurrentTick);

   if(TimeStopBars()!=0)
      if((int)MathRound((TimeCurrent()-OpenTime())/PeriodSeconds())>=TimeStopBars())
        {
         LogFile.Log(LOG_PRINT,__FUNCTION__," order ",(string)Ticket()," timestop of ",(string)TimeStopBars()," bars has been hit");
         return(VIRTUAL_ORDER_EVENT_TIMESTOP);
        }
        
   switch(OrderType())
     {
      case VIRTUAL_ORDER_TYPE_BUY:
         if(TakeProfit()!=0 && CurrentTick.bid>=TakeProfit())
           {
            LogFile.Log(LOG_PRINT,__FUNCTION__," order ",(string)Ticket()," takeprofit has been hit");
            return(VIRTUAL_ORDER_EVENT_TAKEPROFIT);
           }
         if(CurrentTick.bid<=StopLoss())
           {
            LogFile.Log(LOG_PRINT,__FUNCTION__," order ",(string)Ticket()," stoploss has been hit");
            return(VIRTUAL_ORDER_EVENT_STOPLOSS);
           }
         break;

      case VIRTUAL_ORDER_TYPE_SELL:
         if(CurrentTick.ask<=TakeProfit())
           {
            LogFile.Log(LOG_PRINT,__FUNCTION__," order ",(string)Ticket()," takeprofit has been hit");
            return(VIRTUAL_ORDER_EVENT_TAKEPROFIT);
           }
         if(StopLoss()!=0 && CurrentTick.ask>=StopLoss())
           {
            LogFile.Log(LOG_PRINT,__FUNCTION__," order ",(string)Ticket()," stoploss has been hit");
            return(VIRTUAL_ORDER_EVENT_STOPLOSS);
           }
         break;

      case VIRTUAL_ORDER_TYPE_BUYSTOP:
         if(CurrentTick.ask>=OpenPrice() && !(TakeProfit()!=0 && CurrentTick.ask>TakeProfit()))
           {
            LogFile.Log(LOG_PRINT,__FUNCTION__," pending order ",(string)Ticket()," has been triggered to buy");
            return(VIRTUAL_ORDER_EVENT_BUY_TRIGGER);
           }
         break;

      case VIRTUAL_ORDER_TYPE_BUYLIMIT:
         if(CurrentTick.ask<=OpenPrice() && !(StopLoss()!=0 && CurrentTick.ask<StopLoss()))
           {
            LogFile.Log(LOG_PRINT,__FUNCTION__," pending order ",(string)Ticket()," has been triggered to buy");
            return(VIRTUAL_ORDER_EVENT_BUY_TRIGGER);
           }
         break;

      case VIRTUAL_ORDER_TYPE_SELLSTOP:
         if(CurrentTick.bid<=OpenPrice() && !(TakeProfit()!=0 && CurrentTick.bid<TakeProfit()))
           {
            LogFile.Log(LOG_PRINT,__FUNCTION__," pending order ",(string)Ticket()," has been triggered to sell");
            return(VIRTUAL_ORDER_EVENT_SELL_TRIGGER);
           }
         break;

      case VIRTUAL_ORDER_TYPE_SELLLIMIT:
         if(CurrentTick.bid>=OpenPrice() && !(StopLoss()!=0 && CurrentTick.bid>StopLoss()))
           {
            LogFile.Log(LOG_PRINT,__FUNCTION__," pending order ",(string)Ticket()," has been triggered to sell");
            return(VIRTUAL_ORDER_EVENT_SELL_TRIGGER);
           }

      default:
         LogFile.Log(LOG_PRINT,__FUNCTION__," error - unknown virtual order type");
     }
   return(VIRTUAL_ORDER_EVENT_NONE);
  }
//+------------------------------------------------------------------+
/// Close an order.
/// \return 				True if successful, false otherwise
//+------------------------------------------------------------------+
bool CVirtualOrder::Close()
  {
   if(Status()!=VIRTUAL_ORDER_STATUS_OPEN)
     {
      LogFile.Log(LOG_PRINT,__FUNCTION__," error: order is not open");
      return(false);
     }
   switch(OrderType())
     {
      case VIRTUAL_ORDER_TYPE_BUY: m_dblClosePrice=SymbolInfoDouble(Symbol(),SYMBOL_BID); break;
      case VIRTUAL_ORDER_TYPE_SELL: m_dblClosePrice=SymbolInfoDouble(Symbol(),SYMBOL_ASK); break;
      default:
         LogFile.Log(LOG_PRINT,__FUNCTION__," error: cannot close an order of type "+VirtualOrderTypeToStr(OrderType()));
         return(false);
     }
   m_Status=VIRTUAL_ORDER_STATUS_CLOSED;
   m_EntryPriceLine.Delete();
   m_StopLossLine.Delete();
   m_TakeProfitLine.Delete();
   m_dtCloseTime=TimeCurrent();
   LogFile.Log(LOG_PRINT,__FUNCTION__," returning true");
   return(true);
  }
//+------------------------------------------------------------------+
/// Copies all attributes of a virtual order, including chart lines if it is open.
//+------------------------------------------------------------------+
void CVirtualOrder::Copy(CVirtualOrder *vo)
  {
   m_strSymbol         =vo.m_strSymbol;
   m_dblOpenPrice      =vo.m_dblOpenPrice;
   m_dblStopLoss       =vo.m_dblStopLoss;
   m_dblTakeProfit     =vo.m_dblTakeProfit;
   m_nTimeStopBars     =vo.m_nTimeStopBars;
   m_dblClosePrice     =vo.m_dblClosePrice;
   m_Type              =vo.m_Type;
   m_dblLots           =vo.m_dblLots;
   m_strComment        =vo.m_strComment;
   m_lMagic            =vo.m_lMagic;
   m_dtExpiration      =vo.m_dtExpiration;
   m_dblCurrentPrice   =vo.m_dblCurrentPrice;
   m_dtOpenTime        =vo.m_dtOpenTime;
   m_dtCloseTime       =vo.m_dtCloseTime;
   m_dblCommission     =vo.m_dblCommission;
   m_lTicket           =vo.m_lTicket;
   m_Status            =vo.m_Status;
   if(m_Status==VIRTUAL_ORDER_STATUS_OPEN || m_Status==VIRTUAL_ORDER_STATUS_PENDING)
     {
      m_EntryPriceLine.Create(m_lTicket,m_dblOpenPrice,m_Type);
      m_StopLossLine.Create(m_lTicket,m_dblStopLoss);
      m_TakeProfitLine.Create(m_lTicket,m_dblTakeProfit);
     }
  }
//+------------------------------------------------------------------+
/// Current Price.
/// \Return Bid or Ask if the order is open, otherwise zero.                                                                  
//+------------------------------------------------------------------+
double CVirtualOrder::CurrentPrice()
  {
   if(Status()!=VIRTUAL_ORDER_STATUS_OPEN) return(0.0);

   MqlTick CurrentTick;
   SymbolInfoTick(Symbol(),CurrentTick);
   switch(OrderType())
     {
      case VIRTUAL_ORDER_TYPE_BUY: return CurrentTick.bid;
      case VIRTUAL_ORDER_TYPE_SELL: return CurrentTick.ask;
     }
   return(0.0);
  }
//+------------------------------------------------------------------+
/// Delete an order.
/// \return 				True if successful, false otherwise
//+------------------------------------------------------------------+
bool CVirtualOrder::Delete()
  {
   if(Status()!=VIRTUAL_ORDER_STATUS_PENDING)
     {
      LogFile.Log(LOG_PRINT,__FUNCTION__," error: order is not pending");
      return(false);
     }
   m_Status=VIRTUAL_ORDER_STATUS_DELETED;
   m_EntryPriceLine.Delete();
   m_StopLossLine.Delete();
   m_TakeProfitLine.Delete();
   m_dtCloseTime=TimeCurrent();
   LogFile.Log(LOG_PRINT,__FUNCTION__," returning true");
   return(true);
  }
//+------------------------------------------------------------------+
/// Live Close Price.
/// \Return Current price if order is open, and close price if order is closed.
//+------------------------------------------------------------------+
double CVirtualOrder::LiveClosePrice()
  {
   switch(Status())
     {
      case VIRTUAL_ORDER_STATUS_OPEN: return(CurrentPrice());
      case VIRTUAL_ORDER_STATUS_CLOSED: return(ClosePrice());
      default: return(0.0);
     }
  }
//+------------------------------------------------------------------+
/// Modify this order.
/// Similar in behaviour to MQL4 OrderModify()
/// \param [in] price			Open price, only used for pending orders
/// \param [in] stoploss
/// \param [in] takeprofit
/// \param [in] expiration
/// \return 						True if successful, false otherwise
//+------------------------------------------------------------------+
bool CVirtualOrder::Modify(double price,double stoploss,double takeprofit,datetime expiration)
  {
   if(OrderType()==VIRTUAL_ORDER_TYPE_UNDEFINED)
     {
      LogFile.Log(LOG_PRINT,__FUNCTION__," error: order type not defined");
      return(false);
     }

   switch(Status())
     {
      case VIRTUAL_ORDER_STATUS_PENDING:
         if(price!=0)
           {
            m_dblOpenPrice=price;
            m_EntryPriceLine.Price(0,price);
           }
         m_dtExpiration=expiration;

         // fall through to modifying sl & tp
      case VIRTUAL_ORDER_STATUS_OPEN:
         if(StopLoss()!=stoploss)
           {
            m_GlobalVirtualStopList.Modify(Ticket(),stoploss);
            StopLoss(stoploss);
            m_StopLossLine.Price(0,stoploss);
           }
         m_dblTakeProfit=takeprofit;
         m_TakeProfitLine.Price(0,takeprofit);
         break;

      default:
         LogFile.Log(LOG_PRINT,__FUNCTION__," error: cannot modify an order with status ",VirtualOrderStatusToStr(Status()));
         return(false);
     }

   LogFile.Log(LOG_PRINT,__FUNCTION__,StringFormat("(%0.3f,%0.3f,%0.3f,%s) returning true",price,stoploss,takeprofit,TimeToString(expiration)));
   return(true);
  }
//+------------------------------------------------------------------+
/// Increments Config.VirtualOrderTicketGlobalVariable.
/// \return    Unique long integer
//+------------------------------------------------------------------+
long CVirtualOrder::NewTicket()
  {
   CGlobalVariable g_lTicket;
   g_lTicket.Name(Config.VirtualOrderTicketGlobalVariable);
   m_lTicket=g_lTicket.Increment();
   LogFile.Log(LOG_DEBUG,__FUNCTION__," returning ",(string)Ticket());
   return(Ticket());
  }
//+------------------------------------------------------------------+
/// Convert a pending order to market order.
/// \return True if successful, false otherwise
//+------------------------------------------------------------------+
bool CVirtualOrder::PendingOrderTrigger()
  {
   MqlTick Tick;
   SymbolInfoTick(Symbol(),Tick);
   ENUM_VIRTUAL_ORDER_TYPE ot;
   switch(OrderType())
     {
      case VIRTUAL_ORDER_TYPE_BUYSTOP:
      case VIRTUAL_ORDER_TYPE_BUYLIMIT:
         ot=VIRTUAL_ORDER_TYPE_BUY;
         m_dblOpenPrice=Tick.ask;
         break;

      case VIRTUAL_ORDER_TYPE_SELLSTOP:
      case VIRTUAL_ORDER_TYPE_SELLLIMIT:
         ot=VIRTUAL_ORDER_TYPE_SELL;
         m_dblOpenPrice=Tick.bid;
         break;

      case VIRTUAL_ORDER_TYPE_BUY:
      case VIRTUAL_ORDER_TYPE_SELL:
         LogFile.Log(LOG_PRINT,__FUNCTION__," error: Order is already a market order");
         return(false);
      default:
         LogFile.Log(LOG_PRINT,__FUNCTION__," error: unknown order type");
         return(false);
     }
   m_Type=ot;
   m_Status=VIRTUAL_ORDER_STATUS_OPEN;
   m_dtOpenTime=TimeCurrent();
   m_EntryPriceLine.Price(0,OpenPrice());

   m_GlobalVirtualStopList.Add(Ticket(),Symbol(),OrderType(),StopLoss());
   LogFile.Log(LOG_PRINT,__FUNCTION__,StringFormat(" pending order %d has been triggered to %s",Ticket(),VirtualOrderTypeToStr(ot)));
   return(true);
  }
//+------------------------------------------------------------------+
/// Order profit.
/// Either dynamic in the case of an open order, or fixed to the closing price with a closed order
/// \return	Order profit
//+------------------------------------------------------------------+
double CVirtualOrder::Profit()
  {
   double dblPoint=SymbolInfoDouble(Symbol(),SYMBOL_POINT);
   if(dblPoint==0.0)
     {
      LogFile.Log(LOG_PRINT,__FUNCTION__," problem with obtaining SYMBOL_POINT for symbol """+Symbol()+"""");
      return(0.0);
     }
   double dblProfit=Lots()*(LiveClosePrice()-OpenPrice())/SymbolInfoDouble(Symbol(),SYMBOL_POINT);
   switch(OrderType())
     {
      case VIRTUAL_ORDER_TYPE_BUY: return(dblProfit);
      case VIRTUAL_ORDER_TYPE_SELL: return(-dblProfit);
      default: return(0.0);
     }
  }
//+------------------------------------------------------------------+
/// Reads order line from an open file handle.
/// File should be FILE_CSV format
/// \param [in] handle					Handle of the CSV file
/// \param [in] bCreateLineObjects  if true, creates open, sl & tp lines on chart 
/// \return 				True if successful, false otherwise
//+------------------------------------------------------------------+
bool CVirtualOrder::ReadFromFile(int handle,bool bCreateLineObjects)
  {
   if(handle<=0)
     {
      LogFile.Log(LOG_PRINT,__FUNCTION__," error: file handle is not valid, returning false");
      return(false);
     }
   m_Status=StringToVirtualOrderStatus(FileReadString(handle));
   if(FileIsEnding(handle)) return(false);
   m_strSymbol=FileReadString(handle);
   m_Type=StringToVirtualOrderType(FileReadString(handle));
   m_dblLots=FileReadNumber(handle);
   m_dblOpenPrice=FileReadNumber(handle);
   m_dtOpenTime=StringToTime(FileReadString(handle));
   m_dblStopLoss=FileReadNumber(handle);
   m_dblTakeProfit=FileReadNumber(handle);
   m_nTimeStopBars=(int)FileReadNumber(handle);
   m_strComment=FileReadString(handle);
   m_lMagic=StringToInteger(FileReadString(handle));
   m_dblClosePrice=FileReadNumber(handle);
   m_dtCloseTime=StringToTime(FileReadString(handle));
   m_dtExpiration=StringToTime(FileReadString(handle));
   m_lTicket=StringToInteger(FileReadString(handle));

   if(!SelfCheck())
     {
      LogFile.Log(LOG_PRINT,__FUNCTION__," error - virtual order read from file is not valid, returning false");
      return(false);
     }

   if(bCreateLineObjects)
     {
      switch(Status())
        {
         case VIRTUAL_ORDER_STATUS_OPEN:
            m_GlobalVirtualStopList.Add(Ticket(),Symbol(),OrderType(),StopLoss());
            // fall through
         case VIRTUAL_ORDER_STATUS_PENDING:
            m_EntryPriceLine.Create(Ticket(),OpenPrice(),OrderType());
            m_StopLossLine.Create(Ticket(),StopLoss());
            m_TakeProfitLine.Create(Ticket(),TakeProfit());
        }
     }
   return(true);
  }
//+------------------------------------------------------------------+
/// Performs simple integrity check on order details.
/// \return 				True if order is OK, false otherwise
//+------------------------------------------------------------------+
bool CVirtualOrder::SelfCheck()
  {
   if(Status()==VIRTUAL_ORDER_STATUS_NOT_INITIALISED)
     {
      LogFile.Log(LOG_PRINT,__FUNCTION__," error - virtual order is not initialised");
      return(false);
     }
   bool bValidSymbol=false;
   for(int i=0;i<SymbolsTotal(false);i++)
     {
      if(Symbol()==SymbolName(i,false))
        {
         bValidSymbol=true;
         break;
        }
     }
   if(!bValidSymbol)
     {
      LogFile.Log(LOG_PRINT,__FUNCTION__," error - could not find symbol "+Symbol());
      return(false);
     }
   if(OpenPrice()==0)
     {
      LogFile.Log(LOG_PRINT,__FUNCTION__," error - found open price = 0");
      return(false);
     }
   if(OpenTime()==0)
     {
      LogFile.Log(LOG_PRINT,__FUNCTION__," error - found open time 1.1.1970");
      return(false);
     }
   if(Lots()==0)
     {
      LogFile.Log(LOG_PRINT,__FUNCTION__," error - found Lots = 0");
      return(false);
     }
   if(Status()==VIRTUAL_ORDER_STATUS_CLOSED)
     {
      if(ClosePrice()==0)
        {
         LogFile.Log(LOG_PRINT,__FUNCTION__," error - found closed order with close price = 0");
         return(false);
        }
      if(CloseTime()==0)
        {
         LogFile.Log(LOG_PRINT,__FUNCTION__," error - found closed order with close time 1.1.1970");
         return(false);
        }
     }

   LogFile.Log(LOG_DEBUG,__FUNCTION__," returning true");
   return(true);
  }
//+------------------------------------------------------------------+
/// Send an order.
/// Similar in behaviour to MQL4 OrderSend()
/// \param [in] symbol
/// \param [in] cmd
/// \param [in] volume
/// \param [in] price
/// \param [in] slippage
/// \param [in] stoploss
/// \param [in] takeprofit
/// \param [in] comment
/// \param [in] magic
/// \param [in] expiration
//+------------------------------------------------------------------+
void CVirtualOrder::Send(string symbol,ENUM_VIRTUAL_ORDER_TYPE cmd,double volume,double price,double stoploss,double takeprofit,string comment="",long magic=0,datetime expiration=0)
  {
   m_strSymbol=symbol;
   m_Type=cmd;
   m_dblLots=volume;
   m_dblOpenPrice=price;
   m_dtOpenTime=TimeCurrent();
   m_dblStopLoss=stoploss;
   m_dblTakeProfit=takeprofit;
   m_strComment=comment;
   m_lMagic=magic;
   m_dtExpiration=expiration;
   NewTicket();
   if(cmd==VIRTUAL_ORDER_TYPE_BUY || cmd==VIRTUAL_ORDER_TYPE_SELL)
     {
      m_Status=VIRTUAL_ORDER_STATUS_OPEN;
      m_GlobalVirtualStopList.Add(Ticket(),Symbol(),OrderType(),StopLoss());
     }
   else
     {
      m_Status=VIRTUAL_ORDER_STATUS_PENDING;
     }
   m_EntryPriceLine.Create(Ticket(),price,cmd);
   m_StopLossLine.Create(Ticket(),stoploss);
   m_TakeProfitLine.Create(Ticket(),takeprofit);
   LogFile.Log(LOG_PRINT,__FUNCTION__,"(",Trace(),")");
  }
//+------------------------------------------------------------------+
/// Returns short summary line of order details.
//+------------------------------------------------------------------+
string CVirtualOrder::SummaryString()
  {
   string n=(string)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS);
   return(StringFormat("%u:  %s   %s   %5.2f  %0."+n+"f   %6.1f   %s",Ticket(),Symbol(),VirtualOrderTypeToStr(OrderType()),Lots(),OpenPrice(),Profit(),Comment()));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CVirtualOrder::TableRow()
  {
   string n=(string)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS);
   return(StringFormat("%7s %5u %16s %20s %0.2f %8."+n+"f %8."+n+"f %8."+n+"f %8."+n+"f %32s",Symbol(),Ticket(),TimeToString(OpenTime()),VirtualOrderTypeToStr(OrderType()),Lots(),OpenPrice(),StopLoss(),TakeProfit(),CurrentPrice(),Comment()));
  }
//+------------------------------------------------------------------+
/// Returns string line of all order details.
//+------------------------------------------------------------------+
string CVirtualOrder::Trace()
  {
   string n=(string)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS);
   return(StringFormat("%u,%s,%s,%0.2f,%0."+n+"f,%0."+n+"f,%0."+n+"f,%d,%s,%u,%s",Ticket(),Symbol(),VirtualOrderTypeToStr(OrderType()),Lots(),OpenPrice(),StopLoss(),TakeProfit(),TimeStopBars(),Comment(),MagicNumber(),TimeToString(Expiration())));
  }
//+------------------------------------------------------------------+
/// Writes order as a line to an open file handle.
/// File should be FILE_CSV format
/// \param [in] handle	handle of the CSV file
/// \param [in] bHeader 
//+------------------------------------------------------------------+
void CVirtualOrder::WriteToFile(int handle,bool bHeader/*=false*/)
  {
   if(bHeader)
      FileWrite(handle,
                "Status",
                "Symbol",
                "Type",
                "Lots",
                "OpenPrice",
                "OpenTime",
                "StopLoss",
                "TakeProfit",
                "TimeStopBars"
                "Comment",
                "MagicNumber",
                "ClosePrice",
                "CloseTime",
                "Expiration",
                "Ticket"
                );
   else
     {
      LogFile.Log(LOG_VERBOSE,__FUNCTION__," ",TableRow());
      FileWrite(handle,
                ::VirtualOrderStatusToStr(Status()),
                Symbol(),
                ::VirtualOrderTypeToStr(OrderType()),
                Lots(),
                OpenPrice(),
                TimeToString(OpenTime(),TIME_DATE|TIME_SECONDS),
                StopLoss(),
                TakeProfit(),
                TimeStopBars(),
                Comment(),
                MagicNumber(),
                ClosePrice(),
                TimeToString(CloseTime(),TIME_DATE|TIME_SECONDS),
                TimeToString(Expiration(),TIME_DATE|TIME_SECONDS),
                Ticket()
                );
     }
  }
//+------------------------------------------------------------------+
