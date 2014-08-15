//+------------------------------------------------------------------+
//|                                            CTMTradeFunctions.mqh |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#include <StringUtilities.mqh>
#include <Trade\Trade.mqh>
//#include <Trade\SymbolInfo.mqh>
#include <CompareDoubles.mqh>
#include <CLog.mqh>

//+------------------------------------------------------------------+
//| Класс обеспечивает вспомогательные торговые вычисления           |
//+------------------------------------------------------------------+
class CTMTradeFunctions : public CTrade
{
 public:
  void CTMTradeFunctions(void){};
  void ~CTMTradeFunctions(void){};
   
  bool OrderOpen(const string symbol,const ENUM_ORDER_TYPE type, const double volume, const double price,
                 const ENUM_ORDER_TYPE_TIME type_time=ORDER_TIME_GTC,const datetime expiration=0,const string comment="");
  bool OrderDelete(const ulong ticket);
  bool StopOrderModify(const ulong ticket, const double sl = 0.0);
  bool PositionOpen(const string symbol,const ENUM_POSITION_TYPE type,const double volume,
                    const double price,const double sl = 0.0,const double tp = 0.0,const string comment = "");
  bool PositionClose(const string symbol, const ENUM_POSITION_TYPE type, const double volume, const ulong deviation=ULONG_MAX);
};

//+------------------------------------------------------------------+
//| Установка отложника                                              |
//+------------------------------------------------------------------+
bool CTMTradeFunctions::OrderOpen(const string symbol, const ENUM_ORDER_TYPE type, const double volume, const double price,
                                  const ENUM_ORDER_TYPE_TIME type_time=ORDER_TIME_GTC,const datetime expiration=0,const string comment="")
{
 double sl = 0.0, tp = 0.0;
 if(volume<=0.0)
 {
  m_result.retcode=TRADE_RETCODE_INVALID_VOLUME;
  return(false);
 }
 
 return (OrderOpen(symbol,type,volume,0.0,price,sl,tp,type_time,expiration,comment));
}
//+------------------------------------------------------------------+
//| Удаление отложника                                               |
//+------------------------------------------------------------------+
bool CTMTradeFunctions::OrderDelete(ulong ticket)
{
  int i = 0;
  int tryNumber = 5;
  bool res = false;
  uint result_code;
  
  ZeroMemory(m_request);
  ZeroMemory(m_result);
  
  m_request.action = TRADE_ACTION_REMOVE;
  m_request.order = ticket;
  //error_list = "";
  
  while (i <= tryNumber)
  {
   res = false;
   if(OrderCheck(m_request,m_check_result)==true)
   {
    ResetLastError();
    log_file.Write(LOG_DEBUG, StringFormat("%s Проверка пройдена, пытаемся удалить ордер %d, попытка №%d", MakeFunctionPrefix(__FUNCTION__), ticket, i+1));
    OrderSend(m_request,m_result);
    switch (m_result.retcode)
    {
     case TRADE_RETCODE_DONE:
      res = true;
      log_file.Write(LOG_DEBUG, StringFormat("%s Ордер %d успешно удален", MakeFunctionPrefix(__FUNCTION__), ticket));
      break;
     case TRADE_RETCODE_REQUOTE:
     case TRADE_RETCODE_INVALID_STOPS:
     case TRADE_RETCODE_FROZEN:
      Sleep(1000);
     case TRADE_RETCODE_PRICE_CHANGED:
     case TRADE_RETCODE_INVALID_PRICE:
     case TRADE_RETCODE_INVALID:
     default:
      res = false;
      log_file.Write(LOG_DEBUG, StringFormat("%s Ордер не удален. Ошибка: %s", MakeFunctionPrefix(__FUNCTION__), ReturnCodeDescription(m_result.retcode)));
      break;
    }
    result_code = m_result.retcode;
   }
   else
   {
    result_code = m_check_result.retcode;
   }
   
   if (res) break;
   else
   {
     log_file.Write(LOG_DEBUG, StringFormat("%s при удалении ордера %d,  возникла ошибка: %s (%d); GetLastError() = %s (%d); Bid = %.06f; Ask = %.06f; Price = %.06f", MakeFunctionPrefix(__FUNCTION__), ticket, ReturnCodeDescription(result_code), result_code, ErrorDescription(::GetLastError()), ::GetLastError(), m_result.bid, m_result.ask, m_result.price));
   }
   i++;
  }
  return(res);
}

bool CTMTradeFunctions::StopOrderModify(const ulong ticket, const double sl = 0.0)
{
 
 double currentPrice = 0;
 if (sl > 0)
 {
  if (OrderSelect(ticket))
  {
   string symbol = OrderGetString(ORDER_SYMBOL);
   ENUM_ORDER_TYPE type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
   switch(type)
   {
    case ORDER_TYPE_BUY_STOP:
     currentPrice = SymbolInfoDouble(symbol, SYMBOL_ASK);
     if (LessDoubles(sl, currentPrice))
     {
      PrintFormat("%s Ордер БайСтоп не может быть ниже текущей цены", MakeFunctionPrefix(__FUNCTION__));
      return(false);
     }
     if (LessDoubles((sl - currentPrice)/Point(), SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL)))
     {
      PrintFormat("%s Ордер БайСтоп слишком близко к текущей цене", MakeFunctionPrefix(__FUNCTION__));
      return(false);
     }
    break;
    case ORDER_TYPE_SELL_STOP:
     currentPrice = SymbolInfoDouble(symbol, SYMBOL_BID);
     if (GreatDoubles(sl, currentPrice))
     {
      PrintFormat("%s Ордер СеллСтоп не может быть выше текущей цены", MakeFunctionPrefix(__FUNCTION__));
      return(false);
     }
     if (LessDoubles((currentPrice - sl)/Point(), SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL)))
     {
      PrintFormat("%s Ордер СеллСтоп слишком близко к текущей цене ", MakeFunctionPrefix(__FUNCTION__));
      PrintFormat("%s %s(цена) - %s(стоп) = %s > %s(стоп-левел) ", MakeFunctionPrefix(__FUNCTION__),
                                                           DoubleToString(NormalizeDouble(currentPrice, Digits())),
                                                           DoubleToString(NormalizeDouble(sl, Digits())),
                                                           DoubleToString(NormalizeDouble(currentPrice - sl, Digits())),
                                                           DoubleToString(SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point )
                                                           );
      return(false);
     }
    break;
    default:
     PrintFormat("%s Неверный тип столлосса %s", MakeFunctionPrefix(__FUNCTION__), OrderTypeToString(type));
     return(false);
   }
  }
  else
  {
   PrintFormat("%s Невозможно выбрать ордер по тикету %d", MakeFunctionPrefix(__FUNCTION__), ticket);
   return(false);
  } 
  
  if(OrderModify(ticket, sl, 0, 0, ORDER_TIME_GTC, 0))
  {
   PrintFormat("%s Новый стоплосс = %.05f",MakeFunctionPrefix(__FUNCTION__), sl);
   return (true);
  }
  else
  {
   PrintFormat("%s Не удалось изменить стоплосс",MakeFunctionPrefix(__FUNCTION__));
       PrintFormat("ask %s bid %s стоп %s левел %s цена %s",DoubleToString( SymbolInfoDouble(OrderGetString(ORDER_SYMBOL),SYMBOL_ASK) ),
                                                           DoubleToString(SymbolInfoDouble(OrderGetString(ORDER_SYMBOL),SYMBOL_BID) ),
                                                           DoubleToString(sl),
                                                           DoubleToString(SymbolInfoInteger(OrderGetString(ORDER_SYMBOL),SYMBOL_TRADE_STOPS_LEVEL)*_Point ),
                                                           DoubleToString(currentPrice)
                                                           ); 
  }
 }
 return(false);
}
//+-------------------------------------------------------------------------+
//| Открытие CTM-позиции                                                    |
//+-------------------------------------------------------------------------+
bool CTMTradeFunctions::PositionOpen(const string symbol,const ENUM_POSITION_TYPE type,const double volume,
                                     const double price,const double sl = 0.0,const double tp = 0.0,const string comment = "")
{
 ENUM_ORDER_TYPE order_type;
 if(volume <= 0.0)
 {
  PrintFormat("%s Неправильный объем", MakeFunctionPrefix(__FUNCTION__));
  m_result.retcode=TRADE_RETCODE_INVALID_VOLUME;
  return(false);
 }
 switch(type)
 {
  case POSITION_TYPE_BUY:
   order_type = ORDER_TYPE_BUY;
   break;
  case POSITION_TYPE_SELL:
   order_type = ORDER_TYPE_SELL;

   break;
  default:
   log_file.Write(LOG_DEBUG, StringFormat("%s Неправильный тип позиции", MakeFunctionPrefix(__FUNCTION__)));
   return(false);
 }
 PrintFormat("%s, Ордер на открытие %s, %s, %.02f, %.05f, %.05f, %.05f, %d", MakeFunctionPrefix(__FUNCTION__), symbol, OrderTypeToString(order_type), volume, price, sl, tp,m_deviation);
 m_deviation = 0;
 
 //формируем комментарий
 MqlDateTime mdt;
 TimeToStruct(TimeCurrent(),mdt);
 string orderComment = StringFormat("%s_%d%02d%02d_log.txt",log_file.MakeLogFilenameBase(),mdt.year,mdt.mon,mdt.day);
 
 return(PositionOpen(symbol, order_type, volume, price, sl, tp, orderComment));
}                                     

//+-------------------------------------------------------------------------+
//| Удаление CTM-позиции (выставляем противоположный ордер равного объема)  |
//+-------------------------------------------------------------------------+
bool CTMTradeFunctions::PositionClose(const string symbol, const ENUM_POSITION_TYPE type, const double volume, const ulong deviation=ULONG_MAX)
{
 int tryNumber = 5;

 ZeroMemory(m_request);
 ZeroMemory(m_result);
 ZeroMemory(m_check_result);
 
 while (0 <= tryNumber)
 {
  if(type == POSITION_TYPE_BUY)
  {
   //--- prepare request for close BUY position
   m_request.type =ORDER_TYPE_SELL;
   m_request.price=SymbolInfoDouble(symbol,SYMBOL_BID);
  }
  else
  {
   //--- prepare request for close SELL position
   m_request.type =ORDER_TYPE_BUY;
   m_request.price=SymbolInfoDouble(symbol,SYMBOL_ASK);
  }

  //--- setting request
  m_request.action      =TRADE_ACTION_DEAL;
  m_request.symbol      =symbol;
  m_request.magic       =m_magic;
  m_request.deviation   =(deviation==ULONG_MAX) ? m_deviation : deviation;
  //--- check filling
  if(!FillingCheck(symbol))
   return(false);
  m_request.volume = volume;
  //--- order send
  if(OrderSend(m_request,m_result))
  {
   return(true);
  }
  else
  {
   --tryNumber;
  }
 }
 
 return(false);
}