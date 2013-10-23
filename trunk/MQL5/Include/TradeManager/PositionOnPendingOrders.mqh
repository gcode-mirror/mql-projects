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
#include <StringUtilities.mqh>
#include <CompareDoubles.mqh>
#include <CLog.mqh>
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
   string _symbol;
   double _lots;
   ulong _slTicket;
   double _slPrice; // цена установки стопа
   double _tpPrice; // цена установки тейка
   
   datetime _posOpenTime;  //время открытия позиции
   datetime _posCloseTime; //время завершения позиции 
   
   double _posOpenPrice;
   double _posClosePrice;     //цена, по которой позиция закрылась
   double   _posProfit;      //прибыль с позиции
   
   int _sl, _tp;  // Стоп и Тейк в пунктах
   int _minProfit, _trailingStop, _trailingStep; // параметры трейла в пунктах
   ENUM_TM_POSITION_TYPE _type;
   datetime _expiration;
   int      _priceDifference;
   
   CEntryPriceLine   _entryPriceLine;
   CStopLossLine     _stopLossLine;
   CTakeProfitLine   _takeProfitLine;

   ENUM_POSITION_STATUS pos_status;
   ENUM_STOPLEVEL_STATUS sl_status;
   
   ENUM_ORDER_TYPE SLOrderType(int type);
   ENUM_ORDER_TYPE TPOrderType(int type);
   ENUM_ORDER_TYPE PositionOrderType(int type);
   
public:
   void CPosition()   // конструктор по умолчанию
   {
    trade = new CTMTradeFunctions();
    pos_status = POSITION_STATUS_NOT_INITIALISED;
    sl_status = STOPLEVEL_STATUS_NOT_DEFINED;
   };  
   
   void CPosition(CPosition *pos);
   
   void CPosition(ulong magic, string symbol, ENUM_TM_POSITION_TYPE type, double volume
                ,int sl = 0, int tp = 0, int minProfit = 0, int trailingStop = 0, int trailingStep = 0, int priceDifference = 0);
                
   datetime getOpenPosDT() { return (_posOpenTime); };     //получает дату открытия позиции
   datetime getClosePosDT() { return (_posCloseTime); };   //получает дату закрытия позиции             
   double   getPriceOpen() { return(_posOpenPrice); };           //получает цену открытия позиции
   double   getPriceClose() { return(_posClosePrice); };        //получает цену закрытия позиции
   double   getPosProfit() { return(_posProfit); };          //получает прибыль позиции             
   ulong    getMagic() {return (_magic);};
   void     setMagic(ulong magic) {_magic = magic;};
   ulong    getPositionTicket() {return(_posTicket);};
   string   getSymbol() {return (_symbol);};
   double   getVolume() {return (_lots);};
   void     setVolume(double lots) {_lots = lots;};
   int      getSL() {return(_sl);};
   int      getTP() {return(_tp);};
   ulong    getStopLossTicket() {return (_slTicket);};
   double   getPositionPrice() {return(_posOpenPrice);};
   double   getStopLossPrice() {return(_slPrice);};
   double   getTakeProfitPrice() {return(_tpPrice);};
   double   getMinProfit() {return(_minProfit);};
   bool     isMinProfit();
   double   getTrailingStop() {return(_trailingStop);};
   double   getTrailingStep() {return(_trailingStep);};
   double   getPriceDifference() {return(_priceDifference);};
   datetime getExpiration() {return (_expiration);};
   
   ENUM_TM_POSITION_TYPE getType() {return (_type);};
   void setType(ENUM_TM_POSITION_TYPE type) {_type = type;};
   
   ENUM_POSITION_STATUS getPositionStatus() {return (pos_status);};
   void setPositionStatus(ENUM_POSITION_STATUS status) {pos_status = status;};
   
   ENUM_STOPLEVEL_STATUS getStopLossStatus() {return (sl_status);};
   void setStopLossStatus(ENUM_STOPLEVEL_STATUS status) {sl_status = status;};

   bool UpdateSymbolInfo();        // Получение актуальной информации по торговому инструменту 
   double pricetype(ENUM_TM_POSITION_TYPE type);     // вычисляет уровень открытия в зависимости от типа 
   double SLtype(ENUM_TM_POSITION_TYPE type);        // вычисляет уровень стоп-лосса в зависимости от типа
   double TPtype(ENUM_TM_POSITION_TYPE type);        // вычисляет уровень тейк-профита в зависимости от типа

   ENUM_POSITION_STATUS OpenPosition();
   ENUM_STOPLEVEL_STATUS setStopLoss();
   ENUM_STOPLEVEL_STATUS setTakeProfit();
   bool ModifyPosition();
   bool CheckTakeProfit();
   ENUM_STOPLEVEL_STATUS RemoveStopLoss();
   ENUM_POSITION_STATUS RemovePendingPosition();
   bool ClosePosition();
   bool DoTrailing();
   bool ReadFromFile (int handle);
   void WriteToFile (int handle);
 };

//+------------------------------------------------------------------+
//| Copy Constructor                                                 |
//+------------------------------------------------------------------+
CPosition::CPosition(CPosition *pos)
{
 _magic = pos.getMagic();
 _posTicket = pos.getPositionTicket();
 _symbol = pos.getSymbol();
 _lots = pos.getVolume();
 _slTicket = pos.getStopLossTicket();
 _slPrice = pos.getStopLossPrice(); // цена установки стопа
 _tpPrice = pos.getTakeProfitPrice(); // цена установки тейка
   
 _posOpenTime = pos.getOpenPosDT();  //время открытия позиции
 _posCloseTime = pos.getClosePosDT(); //время завершения позиции 
   
 _posOpenPrice = pos.getPriceOpen();
 _posClosePrice = pos.getPriceClose();     //цена, по которой позиция закрылась
 _posProfit = pos.getPosProfit();      //прибыль с позиции
   
 _sl = pos.getSL();
 _tp = pos.getTP();  // Стоп и Тейк в пунктах
 _minProfit = pos.getMinProfit();
 _trailingStop = pos.getTrailingStop();
 _trailingStep = pos.getTrailingStep(); // параметры трейла в пунктах
 _type = pos.getType();
 _expiration = pos.getExpiration();
 _priceDifference = pos.getPriceDifference();

 pos_status = getPositionStatus();
 sl_status = getStopLossStatus();
  
}

//+------------------------------------------------------------------+
//| Constructor with parameters                                      |
//+------------------------------------------------------------------+
CPosition::CPosition(ulong magic, string symbol, ENUM_TM_POSITION_TYPE type, double volume
                    ,int sl = 0, int tp = 0, int minProfit = 0, int trailingStop = 0, int trailingStep = 0, int priceDifference = 0)
                    : _magic(magic), _symbol(symbol), _type(type), _lots(volume), _minProfit(minProfit), 
                      _trailingStop(trailingStop), _trailingStep(trailingStep), _priceDifference(priceDifference), _sl(0), _tp(0)
{
//--- initialize trade functions class
 UpdateSymbolInfo();
 if(sl > 0) _sl = (sl < SymbInfo.StopsLevel()) ? SymbInfo.StopsLevel() : sl;
 if(tp > 0) _tp = (tp < SymbInfo.StopsLevel()) ? SymbInfo.StopsLevel() : tp;
 _expiration = TimeCurrent()+2*PeriodSeconds(Period());
 trade = new CTMTradeFunctions();
 pos_status = POSITION_STATUS_NOT_INITIALISED;
 sl_status = STOPLEVEL_STATUS_NOT_DEFINED;
}

//+------------------------------------------------------------------+
//|Получение информации о достижении минимального профита            |
//+------------------------------------------------------------------+
bool CPosition::isMinProfit(void)
{
 UpdateSymbolInfo();
 if(pos_status == POSITION_STATUS_OPEN)
 {
  switch(_type)
  {
   case OP_BUY:
   case OP_BUYLIMIT:
   case OP_BUYSTOP:
    if (SymbInfo.Bid() - _minProfit*SymbInfo.Point() >= _posOpenPrice ) return true;
    break;
   case OP_SELL:
   case OP_SELLLIMIT:
   case OP_SELLSTOP:
    if (SymbInfo.Ask() + _minProfit*SymbInfo.Point() <= _posOpenPrice ) return true;
    break;
  }
 }
 return false;
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
double CPosition::pricetype(ENUM_TM_POSITION_TYPE type)
{
 UpdateSymbolInfo();
 double ask = SymbInfo.Ask();
 double bid = SymbInfo.Bid();
 double point = SymbInfo.Point();
 if(type == OP_BUY) return(ask);
 if(type == OP_SELL) return(bid);
 if(type == OP_BUYLIMIT  || type == OP_SELLSTOP) return(bid - _priceDifference*point);
 if(type == OP_SELLLIMIT || type == OP_BUYSTOP)  return(ask + _priceDifference*point);
 return(-1);
}
//+------------------------------------------------------------------+
//| Вычисляет уровень стоплосса в зависимости от типа                |
//+------------------------------------------------------------------+
double CPosition::SLtype(ENUM_TM_POSITION_TYPE type)
{
 UpdateSymbolInfo();
 if(type == 0 || type == 2 || type == 4) return(SymbInfo.Bid()-_sl*SymbInfo.Point()); // Buy
 if(type == 1 || type == 3 || type == 5) return(SymbInfo.Ask()+_sl*SymbInfo.Point()); // Sell
 return(0);
}
//+------------------------------------------------------------------+
//| Вычисляет уровень тейкпрофита в зависимости от типа              |
//+------------------------------------------------------------------+
double CPosition::TPtype(ENUM_TM_POSITION_TYPE type)
{
 UpdateSymbolInfo();
 if(type == 0 || type == 2 || type == 4) return(SymbInfo.Ask()+_tp*SymbInfo.Point()); // Buy 
 if(type == 1 || type == 3 || type == 5) return(SymbInfo.Bid()-_tp*SymbInfo.Point()); // Sell
 return(0);
}

ENUM_ORDER_TYPE CPosition::SLOrderType(int type)
{
 ENUM_ORDER_TYPE res;
 if(type == 0 || type == 2 || type == 4) res = ORDER_TYPE_SELL_STOP; // Buy
 if(type == 1 || type == 3 || type == 5) res = ORDER_TYPE_BUY_STOP; // Sell
 return(res);
}

ENUM_ORDER_TYPE CPosition::TPOrderType(int type)
{
 ENUM_ORDER_TYPE res;
 if(type == 0 || type == 2 || type == 4) res = ORDER_TYPE_SELL_LIMIT; // Buy
 if(type == 1 || type == 3 || type == 5) res = ORDER_TYPE_BUY_LIMIT; // Sell
 return(res);
}


//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
ENUM_POSITION_STATUS CPosition::OpenPosition()
{
 UpdateSymbolInfo();
 _posOpenPrice = pricetype(_type);
 _posOpenTime = TimeCurrent(); //сохраняем время открытия позиции    
 _posProfit = 0;
 
 switch(_type)
 {
  case OP_BUY:
   if(trade.PositionOpen(_symbol, POSITION_TYPE_BUY, _lots, _posOpenPrice))
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s Открыта позиция %d", MakeFunctionPrefix(__FUNCTION__), _posTicket));
    if (setStopLoss() != STOPLEVEL_STATUS_NOT_PLACED && setTakeProfit() != STOPLEVEL_STATUS_NOT_PLACED)
    {
     _posTicket = 0;
     pos_status = POSITION_STATUS_OPEN;
    }
    else
    {
     _posTicket = 0;
     pos_status = POSITION_STATUS_NOT_COMPLETE;
    }
   }
   break;
  case OP_SELL:
   if(trade.PositionOpen(_symbol, POSITION_TYPE_SELL, _lots, _posOpenPrice))
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s Открыта позиция %d", MakeFunctionPrefix(__FUNCTION__), _posTicket));
    if (setStopLoss() != STOPLEVEL_STATUS_NOT_PLACED && setTakeProfit() != STOPLEVEL_STATUS_NOT_PLACED)
    {
     _posTicket = 0;
     pos_status = POSITION_STATUS_OPEN;   
    }
    else
    {
     _posTicket = 0;
     pos_status = POSITION_STATUS_NOT_COMPLETE;
    }
   }
   break;
  case OP_BUYLIMIT:
   Alert("OP_BUYLIMIT");
   if (trade.OrderOpen(_symbol, ORDER_TYPE_BUY_LIMIT, _lots, _posOpenPrice, ORDER_TIME_SPECIFIED, _expiration))
   {
    _posTicket = trade.ResultOrder();
    pos_status = POSITION_STATUS_PENDING;             
    log_file.Write(LOG_DEBUG, StringFormat("%s Открыт ордер %d; время истечения %s", MakeFunctionPrefix(__FUNCTION__), _posTicket, TimeToString(_expiration)));
   }
   break;
  case OP_SELLLIMIT:
   Alert("OP_SELLLIMIT");  
   if (trade.OrderOpen(_symbol, ORDER_TYPE_SELL_LIMIT, _lots, _posOpenPrice, ORDER_TIME_SPECIFIED, _expiration))
   {
    _posTicket = trade.ResultOrder();
    pos_status = POSITION_STATUS_PENDING;
    log_file.Write(LOG_DEBUG, StringFormat("%s Открыт ордер %d; время истечения %s", MakeFunctionPrefix(__FUNCTION__), _posTicket, TimeToString(_expiration)));
   }
   break;
  case OP_BUYSTOP:
   Alert("OP_BUYSTOP");  
   if (trade.OrderOpen(_symbol, ORDER_TYPE_BUY_STOP, _lots, _posOpenPrice, ORDER_TIME_SPECIFIED, _expiration))
   {
    _posTicket = trade.ResultOrder();
    pos_status = POSITION_STATUS_PENDING;  
    log_file.Write(LOG_DEBUG, StringFormat("%s Открыт ордер %d; время истечения %s", MakeFunctionPrefix(__FUNCTION__), _posTicket, TimeToString(_expiration)));
   }
   break;
  case OP_SELLSTOP:
   Alert("OP_SELLSTOP");  
   if (trade.OrderOpen(_symbol, ORDER_TYPE_SELL_STOP, _lots, _posOpenPrice, ORDER_TIME_SPECIFIED, _expiration))
   {
    _posTicket = trade.ResultOrder();
    pos_status = POSITION_STATUS_PENDING;
    log_file.Write(LOG_DEBUG, StringFormat("%s Открыт ордер %d; время истечения %s", MakeFunctionPrefix(__FUNCTION__), _posTicket, TimeToString(_expiration)));
   }
   break;
  default:
   Print("Задан неверный тип позиции");
   break;
 }

 return(pos_status);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool CPosition::ModifyPosition()
{
 return(false);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
ENUM_STOPLEVEL_STATUS CPosition::setStopLoss()
{
 ENUM_ORDER_TYPE order_type;
 if (_sl > 0 && sl_status != STOPLEVEL_STATUS_PLACED)
 {
  _slPrice = SLtype(_type);
  order_type = SLOrderType((int)_type);
  if (trade.OrderOpen(_symbol, order_type, _lots, _slPrice)) //, sl + stopLevel, sl - stopLevel);
  {
   _slTicket = trade.ResultOrder();
   sl_status = STOPLEVEL_STATUS_PLACED;
   log_file.Write(LOG_DEBUG, StringFormat("%s Выставлен стоплосс %d c с ценой %0.6f", MakeFunctionPrefix(__FUNCTION__), _slTicket, _slPrice));     
  }
  else
  {
   sl_status = STOPLEVEL_STATUS_NOT_PLACED;
   log_file.Write(LOG_DEBUG, StringFormat("%s Ошибка при установке стоплосса", MakeFunctionPrefix(__FUNCTION__)));
  }
 }
 return(sl_status);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
ENUM_STOPLEVEL_STATUS CPosition::setTakeProfit()
{
 if (_tp > 0)
 {
  _tpPrice = TPtype(_type);
  log_file.Write(LOG_DEBUG, StringFormat("%s Выставлен виртуальный тейкпрофит с ценой %.05f", MakeFunctionPrefix(__FUNCTION__), _tpPrice));     
 }
 else
 {
  _tpPrice = 0;
 }
 return(STOPLEVEL_STATUS_PLACED);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool CPosition::CheckTakeProfit(void)
{
 if (_tpPrice > 0)
 {
  UpdateSymbolInfo();
  if (_type == OP_SELL && _tpPrice >= SymbInfo.Ask())
  {
   PrintFormat("Позиция Селл, пройден уровень тейкпрофит");
  }
  if (_type == OP_BUY  && _tpPrice <= SymbInfo.Bid())
  {
   PrintFormat("Позиция Бай, пройден уровень тейкпрофит");
  }
  return ((_type == OP_SELL && _tpPrice >= SymbInfo.Ask()) || 
          (_type == OP_BUY  && _tpPrice <= SymbInfo.Bid()) );
 }
 return (false);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
ENUM_STOPLEVEL_STATUS CPosition::RemoveStopLoss()
{
 ResetLastError();
 if (sl_status == STOPLEVEL_STATUS_NOT_PLACED)
 {
  sl_status = STOPLEVEL_STATUS_DELETED;
 }
 
 if (sl_status == STOPLEVEL_STATUS_PLACED || sl_status == STOPLEVEL_STATUS_NOT_DELETED) // Если ордер был установлен или его не удалось удалить в прошлом
 {
  if (OrderSelect(_slTicket))
  {
   if (trade.OrderDelete(_slTicket))
   {
    sl_status = STOPLEVEL_STATUS_DELETED;
    log_file.Write(LOG_DEBUG, StringFormat("%s Удален стоплосс %d", MakeFunctionPrefix(__FUNCTION__), _slTicket));
   }
   else
   {
    sl_status = STOPLEVEL_STATUS_NOT_DELETED;
      log_file.Write(LOG_DEBUG, StringFormat("%s Ошибка при удалении стоплосса.Error(%d) = %s.Result retcode %d = %s", MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError()), trade.ResultRetcode(), trade.ResultRetcodeDescription()));
   }
  }
  else
  {
   switch(_type)
   {
    case OP_BUY:
    case OP_BUYLIMIT:
    case OP_BUYSTOP:
     if (trade.PositionClose(_symbol, POSITION_TYPE_SELL, _lots)) // тип позиции бай, мы закрываем стоп ордер - селл
     {
      sl_status = STOPLEVEL_STATUS_DELETED;

      log_file.Write(LOG_DEBUG, StringFormat("%s Удален сработавший стоплосс %d", MakeFunctionPrefix(__FUNCTION__), _slTicket));
      break;
     }
     else
     {
      log_file.Write(LOG_DEBUG, StringFormat("%s Ошибка при удалении стоплосса.Error(%d) = %s.Result retcode %d = %s", MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError()), trade.ResultRetcode(), trade.ResultRetcodeDescription()));
     }
     
    case OP_SELL:
    case OP_SELLLIMIT:
    case OP_SELLSTOP:
     if (trade.PositionClose(_symbol, POSITION_TYPE_BUY, _lots)) // тип позиции селл, мы закрываем стоп ордер - бай
     {
      sl_status = STOPLEVEL_STATUS_DELETED;

      log_file.Write(LOG_DEBUG, StringFormat("%s Удален сработавший стоплосс %d", MakeFunctionPrefix(__FUNCTION__), _slTicket));
      break;
     }
     else
     {
      log_file.Write(LOG_DEBUG, StringFormat("%s Ошибка при удалении стоплосса.Error(%d) = %s.Result retcode %d = %s", MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError()), trade.ResultRetcode(), trade.ResultRetcodeDescription()));
     }
   }
  }
 }
 return (sl_status);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
ENUM_POSITION_STATUS CPosition::RemovePendingPosition()
{
 if (pos_status == POSITION_STATUS_PENDING || pos_status == POSITION_STATUS_NOT_DELETED)
 {
  if (trade.OrderDelete(_posTicket))
  {
   pos_status = POSITION_STATUS_DELETED;
  }
  else
  {
   pos_status = POSITION_STATUS_NOT_DELETED;
  }
 }
 return(pos_status);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool CPosition::ClosePosition()
{
 //Alert("ПОЗИЦИЯ ЗАКРЫТА");
 int i = 0;
 double tmp_profit;   //переменная для хранения профита позиции
 ResetLastError();
 if (pos_status == POSITION_STATUS_PENDING)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s RemovePendingPosition", MakeFunctionPrefix(__FUNCTION__)));
  pos_status = RemovePendingPosition();
 }
 
 if (pos_status == POSITION_STATUS_OPEN)
 {
  switch(_type)
  {
   case OP_BUY:
    if(trade.PositionClose(_symbol, POSITION_TYPE_BUY, _lots, config.Deviation))
    {     
     _posClosePrice = SymbolInfoDouble(_symbol, SYMBOL_BID);   //сохраняем цену закрытия позиции
     _posCloseTime = TimeCurrent();                      //сохраняем время закрытия позиции
     _posProfit = _posClosePrice - _posOpenPrice; 
     log_file.Write(LOG_DEBUG, StringFormat("%s Закрыта позиция %d", MakeFunctionPrefix(__FUNCTION__), _posTicket));
    }
    else
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s Ошибка при удалении позиции BUY.Error(%d) = %s.Result retcode %d = %s", MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError()), trade.ResultRetcode(), trade.ResultRetcodeDescription()));
    }
    break;
   case OP_SELL:
    if(trade.PositionClose(_symbol, POSITION_TYPE_SELL, _lots, config.Deviation))
    {
     _posClosePrice = SymbolInfoDouble(_symbol, SYMBOL_ASK);   //сохраняем цену закрытия позиции
     _posCloseTime = TimeCurrent();                      //сохраняем время закрытия позиции
     _posProfit = _posOpenPrice - _posClosePrice;
     log_file.Write(LOG_DEBUG, StringFormat("%s Закрыта позиция %d", MakeFunctionPrefix(__FUNCTION__), _posTicket));
    }
    else
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s Ошибка при удалении позиции SELL.Error(%d) = %s.Result retcode %d = %s", MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError()), trade.ResultRetcode(), trade.ResultRetcodeDescription()));    
    }
    break;
   default:
    break;
  }
  
  if (sl_status == STOPLEVEL_STATUS_PLACED)
  {
   sl_status = RemoveStopLoss();
  }
 }
  
 return(pos_status != POSITION_STATUS_NOT_DELETED
      && sl_status != STOPLEVEL_STATUS_NOT_DELETED);

}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool CPosition::DoTrailing(void)
{
 UpdateSymbolInfo();
 double ask = SymbInfo.Ask();
 double bid = SymbInfo.Bid();
 double point = SymbInfo.Point();
 int digits = SymbInfo.Digits();
 double newSL = 0;
 
 if (getType() == OP_BUY)
 {
  if (LessDoubles(_posOpenPrice, bid - _minProfit*point))
  {
   if (LessDoubles(_slPrice, bid - (_trailingStop+_trailingStep-1)*point) || _slPrice == 0)
   {
    newSL = NormalizeDouble(bid - _trailingStop*point, digits);
    if (trade.OrderModify(_slTicket, newSL, 0, 0, ORDER_TIME_GTC, 0))
    {
     _slPrice = newSL;
     return true;
    } 
   }
  }
 }
 
 if (getType() == OP_SELL)
 {
  if (GreatDoubles(_posOpenPrice - ask, _minProfit*point))
  {
   if (GreatDoubles(_slPrice, ask+(_trailingStop+_trailingStep-1)*point) || _slPrice == 0) 
   {
    newSL = NormalizeDouble(ask + _trailingStop*point, digits);
    if (trade.OrderModify(_slTicket, newSL, 0, 0, ORDER_TIME_GTC, 0))
    {
     _slPrice = newSL;
     return true;
    }
   }
  }
 }
 return false;
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
 if(handle != INVALID_HANDLE)
 {
  if(FileIsEnding(handle)) return false;
  _magic = StringToInteger(FileReadString(handle));                               //считываем мэджик
  if(FileIsEnding(handle)) return false;
  _symbol         = FileReadString(handle);                      //считываем символ
  if(FileIsEnding(handle)) return false;  
  _type           = StringToPositionType(FileReadString(handle));//считываем тип
  if(FileIsEnding(handle)) return false;  
  _lots           = FileReadNumber(handle);                      //считываем размер лота
  if(FileIsEnding(handle)) return false;  
  _posTicket      = StringToInteger(FileReadString(handle));                      //считываем тикет позиции
  if(FileIsEnding(handle)) return false;  
  _slTicket       = StringToInteger(FileReadString(handle));                      //считываем тикет стоп лосса
  if(FileIsEnding(handle)) return false;  
  _slPrice        = FileReadNumber(handle);                      //считываем цену стоп лосса
  if(FileIsEnding(handle)) return false;  
  _sl             = FileReadNumber(handle);                      //считываем стоп лосс
  if(FileIsEnding(handle)) return false;  
  _tpPrice        = FileReadNumber(handle);                      //считываем цену тейк профита
  if(FileIsEnding(handle)) return false;  
  _trailingStop   = FileReadNumber(handle);                      //Трейлинг стоп
  if(FileIsEnding(handle)) return false;  
  _trailingStep   = FileReadNumber(handle);                      //Трейлинг степ
  if(FileIsEnding(handle)) return false;  
  _posOpenPrice       = FileReadNumber(handle);                      //цена открытия позиции
  if(FileIsEnding(handle)) return false;  
  _posClosePrice     = FileReadNumber(handle);                 //цена закрытия позиции
  if(FileIsEnding(handle)) return false;  
  _posOpenTime  = FileReadDatetime(handle);                    //время открытия позиции
  if(FileIsEnding(handle)) return false;  
  _posCloseTime = FileReadDatetime(handle);                    //время закрытия позиции
  if(FileIsEnding(handle)) return false;  
  _posProfit      = FileReadNumber(handle);                      //профит позиции
  if(FileIsEnding(handle)) return false;  
     FileReadString(handle);                                     //пропуск пустого символа  
  //log_file.Write(LOG_DEBUG, StringFormat("%s Файл успешно прочитан", MakeFunctionPrefix(__FUNCTION__)));
  return true;
 }
 return false;
}

//+------------------------------------------------------------------+
/// Writes order as a line to an open file handle.
/// File should be FILE_CSV format
/// \param [in] handle	handle of the CSV file
/// \param [in] bHeader 
//+------------------------------------------------------------------+
void CPosition::WriteToFile(int handle)
{
 if(handle != INVALID_HANDLE)
 {
  FileWrite(handle,      
            _magic,           
            Symbol(),         
            GetNameOP(_type), 
            _lots,            
            _posTicket,       
            _slTicket,        
            _slPrice,         
            _sl,              
            _tpPrice,         
            _trailingStop,   
            _trailingStep,    
            _posOpenPrice,
            _posClosePrice,
            _posOpenTime,
            _posCloseTime,
            _posProfit
            );
 }
}