//+------------------------------------------------------------------+
//|                                                     Position.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#include "ChartObjectsTradeLines.mqh"
#include "TradeManagerConfig.mqh"
#include "CTMTradeFunctions.mqh" //подключаем библиотеку для совершения торговых операций
#include "StringUtilities.mqh"
#include <CompareDoubles.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CPosition : public CObject
  {
private:
   CSymbolInfo SymbInfo;
   CTMTradeFunctions *trade;
   CConfig config;
   ulong _magic;
   ulong _posTicket;
   double _posPrice;
   string _symbol;
   double _lots;
   ulong _slTicket;
   double _slPrice;
   ulong _tpTicket;
   double _tpPrice;
   int _sl, _tp;
   int _minProfit, _trailingStop, _trailingStep;
   ENUM_POSITION_TYPE _type;
   ENUM_POSITION_STATUS _status;
   
   CEntryPriceLine   _entryPriceLine;
   CStopLossLine     _stopLossLine;
   CTakeProfitLine   _takeProfitLine;

   ENUM_STOPLEVEL_STATUS sl_status, tp_status;
   ENUM_POSITION_STATUS pos_status;
   
public:
  void CPosition(ulong magic, string symbol, ENUM_POSITION_TYPE type, double volume
                ,int sl = 0, int tp = 0, int minProfit = 0, int trailingStop = 0, int trailingStep = 0);
   ulong getMagic() {return (_magic);};
   void setMagic(ulong magic) {_magic = magic;};
   ulong getPositionTicket() {return(_posTicket);};
   void setPositionTicket(ulong ticket) {_posTicket = ticket;};
   double getPositionPrice() {return(_posPrice);};
   string getSymbol() {return (_symbol);};
   void setSymbol(string symbol) {_symbol = symbol;};
   double getVolume() {return (_lots);};
   void setVolume(double lots) {_lots = lots;};
   ulong getStopLossTicket() {return (_slTicket);};
   void setStopLossTicket(ulong ticket) {_slTicket = ticket;};
   double getStopLossPrice() {return(_slPrice);};
   ulong getTakeProfitTicket() {return (_tpTicket);};
   void setTakeProfitTicket(ulong ticket) {_tpTicket = ticket;};
   double getTakeProfitPrice() {return(_tpPrice);};
   double getMinProfit() {return(_minProfit);};
   double getTrailingStop() {return(_trailingStop);};
   double getTrailingStep() {return(_trailingStep);};
   ENUM_POSITION_TYPE getType() {return (_type);};
   void setType(ENUM_POSITION_TYPE type) {_type = type;};
   
   bool UpdateSymbolInfo();        // Получение актуальной информации по торговому инструменту 
   double pricetype(int type);     // вычисляет уровень открытия в зависимости от типа 
   double SLtype(int type);        // вычисляет уровень стоп-лосса в зависимости от типа
   double TPtype(int type);        // вычисляет уровень тейк-профита в зависимости от типа
   ENUM_ORDER_TYPE SLOrderType(int type);
   ENUM_ORDER_TYPE TPOrderType(int type);
   bool OpenPosition();
   bool ClosePosition();
   void DoTrailing();
   bool ReadFromFile (int handle);
   void WriteToFile (int handle,bool bHeader/*=false*/);
 };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPosition::CPosition(ulong magic, string symbol, ENUM_POSITION_TYPE type, double volume
                    ,int sl = 0, int tp = 0, int minProfit = 0, int trailingStop = 0, int trailingStep = 0)
                    : _magic(magic), _symbol(symbol), _type(type), _lots(volume)
                    , _sl(sl), _tp(tp), _minProfit(minProfit), _trailingStop(trailingStop), _trailingStep(trailingStep)
  {
//--- initialize trade functions class
   trade = new CTMTradeFunctions();
   pos_status = POSITION_STATUS_NOT_INITIALISED;
   sl_status = STOPLEVEL_STATUS_NOT_DEFINED;
   tp_status = STOPLEVEL_STATUS_NOT_DEFINED;
  }
 
//+------------------------------------------------------------------+
//|Получение актуальной информации по торговому инструменту          |
//+------------------------------------------------------------------+
bool CPosition::UpdateSymbolInfo()
  {
   SymbInfo.Name(_symbol);
   if(SymbInfo.Select() && SymbInfo.RefreshRates())
   {
    return(true);
   }
   return(false);
  }  
 
//+------------------------------------------------------------------+
//| Вычисляет уровень открытия в зависимости от типа                 |
//+------------------------------------------------------------------+
double CPosition::pricetype(int type)
{
 UpdateSymbolInfo();
 if(type == 0)return(SymbInfo.Ask());
 if(type == 1)return(SymbInfo.Bid());
 return(-1);
}
//+------------------------------------------------------------------+
//| Вычисляет уровень стоплосса в зависимости от типа                |
//+------------------------------------------------------------------+
double CPosition::SLtype(int type)
{
 UpdateSymbolInfo();
 if(type==0)return(SymbInfo.Bid()-_sl*SymbInfo.Point()); // Buy
 if(type==1)return(SymbInfo.Ask()+_sl*SymbInfo.Point()); // Sell
 return(0);
}
//+------------------------------------------------------------------+
//| Вычисляет уровень тейкпрофита в зависимости от типа              |
//+------------------------------------------------------------------+
double CPosition::TPtype(int type)
{
 UpdateSymbolInfo();
 if(type==0)return(SymbInfo.Ask()+_tp*SymbInfo.Point()); // Buy 
 if(type==1)return(SymbInfo.Bid()-_tp*SymbInfo.Point()); // Sell
 return(0);
}

ENUM_ORDER_TYPE CPosition::SLOrderType(int type)
{
 ENUM_ORDER_TYPE res;
 if(type==0) res = ORDER_TYPE_SELL_STOP; // Buy
 if(type==1) res = ORDER_TYPE_BUY_STOP; // Sell
 return(res);
}

ENUM_ORDER_TYPE CPosition::TPOrderType(int type)
{
 ENUM_ORDER_TYPE res;
 if(type==0) res = ORDER_TYPE_SELL_LIMIT; // Buy
 if(type==1) res = ORDER_TYPE_BUY_LIMIT; // Sell
 return(res);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool CPosition::OpenPosition()
{
 if (_type != POSITION_TYPE_BUY && _type != POSITION_TYPE_SELL)
 {
  Print(" Неправильный тип позиции");
  return(false);
 }
 UpdateSymbolInfo();
 ENUM_ORDER_TYPE order_type;
 double stopLevel = _Point*SymbolInfoInteger(Symbol(),SYMBOL_TRADE_STOPS_LEVEL);
 double ask = SymbInfo.Ask();
 double bid = SymbInfo.Bid();
 _posPrice = pricetype((int)_type);
 
 if (trade.PositionOpen(_symbol, _type, _lots, _posPrice))
 {
  _posTicket = trade.ResultDeal();
  pos_status = POSITION_STATUS_OPEN;
  PrintFormat("%s Открыта позиция %d", MakeFunctionPrefix(__FUNCTION__), _posTicket);
 }
 
 // Если задан тейкпрофит - устанавливаем
 if (_tp > 0)
 {
  _tpPrice = TPtype((int)_type);
  order_type = TPOrderType((int)_type);
  if (trade.OrderOpen(_symbol, order_type, _lots, _tpPrice))  //, tp + stopLevel, tp - stopLevel);
  {
   _tpTicket = trade.ResultOrder();
   tp_status = STOPLEVEL_STATUS_PLACED;
   PrintFormat("%s Выставлен тейкпрофит %d", MakeFunctionPrefix(__FUNCTION__), _tpTicket);
  }
  else
  {
   tp_status = STOPLEVEL_STATUS_NOT_PLACED;
   PrintFormat("%s Ошибка при установке тейкпрофита", MakeFunctionPrefix(__FUNCTION__));
  }
 }
 /*
 else
 {
  tp_status = STOPLEVEL_STATUS_NOT_DEFINED;
  PrintFormat("Тейкпрофит не задан", MakeFunctionPrefix(__FUNCTION__));
 }
 */
 // Если задан стоплосс - устанавливаем
 if (_sl > 0)
 {
  _slPrice = SLtype((int)_type);
  order_type = SLOrderType((int)_type);
  if (trade.OrderOpen(_symbol, order_type, _lots, _slPrice)) //, sl + stopLevel, sl - stopLevel);
  {
   _slTicket = trade.ResultOrder();
   sl_status = STOPLEVEL_STATUS_PLACED;
   PrintFormat("%s Выставлен стоплосс %d", MakeFunctionPrefix(__FUNCTION__), _slTicket);     
  }
  else
  {
   sl_status = STOPLEVEL_STATUS_NOT_PLACED;
   PrintFormat("%s Ошибка при установке стоплосса", MakeFunctionPrefix(__FUNCTION__));
  }
 }
      
 if (pos_status != POSITION_STATUS_NOT_INITIALISED && sl_status != STOPLEVEL_STATUS_NOT_PLACED && tp_status != STOPLEVEL_STATUS_NOT_PLACED)
 {
  return(true);
 }
 return(false);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool CPosition::ClosePosition()
{
 int i = 0;
 
 if (trade.PositionClose(_symbol, _type, _lots, config.Deviation))
 {
  pos_status = POSITION_STATUS_DELETED;
 }
 
 if (sl_status == STOPLEVEL_STATUS_PLACED)
 {
  if (trade.OrderDelete(_slTicket))
  {
   sl_status = STOPLEVEL_STATUS_DELETED;
  }
  else
  {
   sl_status = STOPLEVEL_STATUS_NOT_DELETED;
  }
 }
  
 if (tp_status == STOPLEVEL_STATUS_PLACED)
 {
  if (trade.OrderDelete(_tpTicket))
  {
   tp_status = STOPLEVEL_STATUS_DELETED;
  }
  else
  {
   tp_status = STOPLEVEL_STATUS_NOT_DELETED;
  }
 }
  
 return(pos_status == POSITION_STATUS_DELETED && sl_status == STOPLEVEL_STATUS_DELETED && tp_status == STOPLEVEL_STATUS_DELETED);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void CPosition::DoTrailing(void)
{
 UpdateSymbolInfo();
 double ask = SymbInfo.Ask();
 double bid = SymbInfo.Bid();
 double point = SymbInfo.Point();
 int digits = SymbInfo.Digits();
 double newSL = 0;
 
 if (getType() == POSITION_TYPE_BUY)
 {
  if (LessDoubles(_posPrice, bid - _minProfit*point))
  {
   if (LessDoubles(_slPrice, bid - (_trailingStop+_trailingStep-1)*point) || _slPrice == 0)
   {
    newSL = NormalizeDouble(bid - _trailingStop*point, digits);
    if (trade.OrderModify(_slTicket, newSL, 0, 0, ORDER_TIME_GTC, 0))
    {
     _slPrice = newSL;
    } 
   }
  }
 }
 
 if (getType() == POSITION_TYPE_SELL)
 {
  if (GreatDoubles(_posPrice - ask, _minProfit*point))
  {
   if (GreatDoubles(_slPrice, ask+(_trailingStop+_trailingStep-1)*point) || _slPrice == 0) 
   {
    newSL = NormalizeDouble(ask + _trailingStop*point, digits);
    if (trade.OrderModify(_slTicket, newSL, 0, 0, ORDER_TIME_GTC, 0))
    {
     _slPrice = newSL;
    }
   }
  }
 }
}

//+------------------------------------------------------------------+
/// Reads order line from an open file handle.
/// File should be FILE_CSV format
/// \param [in] handle					Handle of the CSV file
/// \param [in] bCreateLineObjects  if true, creates open, sl & tp lines on chart 
/// \return 				True if successful, false otherwise
//+------------------------------------------------------------------+
bool CPosition::ReadFromFile(int handle)
{
 if(handle<=0)
 {
  //LogFile.Log(LOG_PRINT,__FUNCTION__," error: file handle is not valid, returning false");
  return(false);
 }
 _status=StringToPositionStatus(FileReadString(handle));
 if(FileIsEnding(handle)) return(false);
 _symbol=FileReadString(handle);
 _type=StringToPositionType(FileReadString(handle));
 _lots=FileReadNumber(handle);
 /*
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
 */
 _posTicket=StringToInteger(FileReadString(handle));
/*
 if(!SelfCheck())
 {
  LogFile.Log(LOG_PRINT,__FUNCTION__," error - virtual order read from file is not valid, returning false");
  return(false);
 }
*/
 return(true);
}

//+------------------------------------------------------------------+
/// Writes order as a line to an open file handle.
/// File should be FILE_CSV format
/// \param [in] handle	handle of the CSV file
/// \param [in] bHeader 
//+------------------------------------------------------------------+
void CPosition::WriteToFile(int handle,bool bHeader/*=false*/)
  {/*
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
      //LogFile.Log(LOG_VERBOSE,__FUNCTION__," ",TableRow());
      FileWrite(handle,
                ::PositionStatusToStr(Status()),
                Symbol(),
                ::PositionTypeToStr(OrderType()),
                _lots(),
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
     }*/
  }