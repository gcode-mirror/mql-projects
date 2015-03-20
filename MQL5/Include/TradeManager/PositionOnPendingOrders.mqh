//+------------------------------------------------------------------+
//|                                                     Position.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#include "ChartObjectsTradeLines.mqh"
#include "TradeManagerConfig.mqh"
#include "TradeManagerEnums.mqh"
#include "CTMTradeFunctions.mqh" //подключаем библиотеку для совершения торговых операций
#include <TrailingStop\TrailingStop.mqh>
#include <GlobalVariable.mqh>
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
   CTrailingStop *trailingStop;
   CConfig config;
   SPositionInfo _pos_info;
   STrailing _trailing;
   ulong _magic;
   string _symbol;
   ENUM_TIMEFRAMES _period;
   ulong _tmTicket;
   ulong _orderTicket;
   ulong _slTicket;
   ENUM_ORDER_TYPE _slType;
   double _slPrice, _tpPrice; // цена установки стопа и тейка
   
   datetime _posOpenTime;  //время открытия позиции
   datetime _posCloseTime; //время завершения позиции 
   
   double _posOpenPrice;
   double _posAveragePrice;
   double _posClosePrice;     //цена, по которой позиция закрылась
   double _posProfit;         //прибыль с позиции
   
   CEntryPriceLine   _entryPriceLine;
   CStopLossLine     _stopLossLine;
   CTakeProfitLine   _takeProfitLine;

   ENUM_POSITION_STATUS _pos_status;
   ENUM_STOPLEVEL_STATUS _sl_status;
   ENUM_ORDER_TYPE_TIME _type_time;
   
   ENUM_ORDER_TYPE SLOrderType(int type);
   ENUM_ORDER_TYPE TPOrderType(int type);
   ENUM_ORDER_TYPE OrderType(int type);
   ENUM_POSITION_TYPE PositionType(int type);
   
public:
   void CPosition()   // конструктор по умолчанию
   {
    //Print("Конструктор по умолчанию");
    trade = new CTMTradeFunctions();
    trailingStop = new CTrailingStop();
    _pos_status = POSITION_STATUS_NOT_INITIALISED;
    _sl_status = STOPLEVEL_STATUS_NOT_DEFINED;
   };  
   
   void CPosition(CPosition *pos); // Конструктор копирования 
   void CPosition(string symbol, ENUM_TIMEFRAMES period
                 , ENUM_TM_POSITION_TYPE type, double volume
                 , double profit, double priceOpen, double priceClose); // Конструктор для отыгрыша позиций
   void CPosition(ulong magic, string symbol, ENUM_TIMEFRAMES period, SPositionInfo& pi, STrailing& tr); // Конструктор с параметрами
   void ~CPosition() {delete trade; delete trailingStop;}
// GET   
   datetime getClosePosDT()      {return(_posCloseTime);};    //получает дату закрытия позиции
   datetime getExpiration()      {return(_pos_info.expiration_time);};      
   int      getHandlePBI()       {return(_trailing.handleForTrailing);}; 
   ulong    getMagic()           {return(_magic);};
   int      getMinProfit()       {return(_trailing.minProfit);};
   datetime getOpenPosDT()       {return(_posOpenTime);};     //получает дату открытия позиции
   ENUM_TM_POSITION_TYPE getOppositeType(ENUM_TM_POSITION_TYPE type);
   ulong    getOrderTicket()     {return(_orderTicket);};
   ENUM_TIMEFRAMES getPeriod()   {return(_period);};
   SPositionInfo getPositionInfo(){return(_pos_info);};
   double   getPositionPrice()   {return(_posAveragePrice);};
   int      getPositionPointsProfit();
   ENUM_POSITION_STATUS getPositionStatus() {return (_pos_status);};
   double   getPosProfit();                                    //получает прибыль позиции  
   int      getPriceDifference() {return(_pos_info.priceDifference);};
   double   getPriceOpen()       {return(_posOpenPrice);};     //получает цену открытия позиции
   double   getPriceClose()      {return(_posClosePrice);};    //получает цену закрытия позиции
   int      getSL()              {return(_pos_info.sl);};
   double   getStopLossPrice()   {return(_slPrice);};
   ENUM_ORDER_TYPE getStopLossType() {return(_slType);};
   ENUM_STOPLEVEL_STATUS getStopLossStatus() {return (_sl_status);};
   ulong    getStopLossTicket()  {return(_slTicket);};
   string   getSymbol()          {return(_symbol);};
   double   getTakeProfitPrice() {return(_tpPrice);};
   ulong    getTMTicket()        {return(_tmTicket);};
   int      getTP()              {return(_pos_info.tp);};
   STrailing getTrailing()       {return(_trailing);};
   int      getTrailingStop()    {return(_trailing.trailingStop);};
   int      getTrailingStep()    {return(_trailing.trailingStep);};
   ENUM_TRAILING_TYPE getTrailingType() {return(_trailing.trailingType);};
   ENUM_TM_POSITION_TYPE getType() {return(_pos_info.type);};
   double   getVolume()            {return(_pos_info.volume);};
   
// SET
   void setMagic(ulong magic) {_magic = magic;};
   void setPositionStatus(ENUM_POSITION_STATUS status) {_pos_status = status;};
   void setStopLossStatus(ENUM_STOPLEVEL_STATUS status) {_sl_status = status;};
   ENUM_STOPLEVEL_STATUS setStopLoss();
   ENUM_STOPLEVEL_STATUS setTakeProfit();
   void setTrailingHandle(int handle) {_trailing.handleForTrailing = handle;};    
   void setType(ENUM_TM_POSITION_TYPE type) {_pos_info.type = type;};
   void setVolume(double lots) {_pos_info.volume = lots;}; 
 
   bool     ChangeSize(double lot);
   ENUM_STOPLEVEL_STATUS ChangeStopLossVolume();   
   bool     CheckTakeProfit();
   bool     ClosePosition();
   void     DoTrailing();
   bool     isMinProfit();
   bool     ModifyPosition(double sl, double tp); //tp - не работате
   ulong    NewTicket();
   ENUM_POSITION_STATUS OpenPosition();
   double   OpenPriceByType(ENUM_TM_POSITION_TYPE type);     // вычисляет уровень открытия в зависимости от типа 
   double   PriceByType(ENUM_TM_POSITION_TYPE type);     // вычисляет уровень открытия в зависимости от типа 
   bool     ReadFromFile (int handle);
   ENUM_POSITION_STATUS  RemovePendingPosition();
   ENUM_STOPLEVEL_STATUS RemoveStopLoss();         
   double   SLPriceByType(ENUM_TM_POSITION_TYPE type);        // вычисляет уровень стоп-лосса в зависимости от типа
   double   StopLevelByType(ENUM_TM_POSITION_TYPE type);          // вычисляет уровень спреда в зависимости от типа
   double   TPPriceByType(ENUM_TM_POSITION_TYPE type);        // вычисляет уровень тейк-профита в зависимости от типа
   bool     UpdateSymbolInfo();        // Получение актуальной информации по торговому инструменту 
   void     WriteToFile (int handle);
   
 };

//+------------------------------------------------------------------+
//| Constructor for replay positions                                 |
//+------------------------------------------------------------------+
CPosition::CPosition(string symbol, ENUM_TIMEFRAMES period, ENUM_TM_POSITION_TYPE type, double volume, double profit, double priceOpen, double priceClose)
{
  //Print("Конструктор с параметрами для реплея");
 trade = new CTMTradeFunctions();
 trailingStop = new CTrailingStop();
 _period = period;
 _pos_info.type = type;
 _pos_info.volume = volume;
 _posProfit = profit;
 _posOpenPrice = priceOpen;
 _posClosePrice = priceClose;
 _pos_status = POSITION_STATUS_NOT_INITIALISED;
 _sl_status = STOPLEVEL_STATUS_NOT_DEFINED;
 _type_time = ORDER_TIME_GTC;
}
//+------------------------------------------------------------------+
//| Copy Constructor                                                 |
//+------------------------------------------------------------------+
CPosition::CPosition(CPosition *pos)
{
 //Print("Конструктор копирования");
 trade = new CTMTradeFunctions();
 trailingStop = new CTrailingStop();
 _pos_info = pos.getPositionInfo();
 _trailing = pos.getTrailing();
 
 _magic = pos.getMagic();
 _tmTicket = pos.getTMTicket();
 _orderTicket = pos.getOrderTicket();
 _symbol = pos.getSymbol();
 _period = pos.getPeriod();
 _slTicket = pos.getStopLossTicket();
 _slType = pos.getStopLossType();
 _slPrice = pos.getStopLossPrice();         // цена установки стопа
 _tpPrice = pos.getTakeProfitPrice();       // цена установки тейка
 if (_tpPrice > 0) _takeProfitLine.Create(0, _tpPrice);
   
 _posOpenTime = pos.getOpenPosDT();         //время открытия позиции
 _posCloseTime = pos.getClosePosDT();       //время завершения позиции 
   
 _posOpenPrice = pos.getPriceOpen();
 _posClosePrice = pos.getPriceClose();      //цена, по которой позиция закрылась
 _posProfit = pos.getPosProfit();           //прибыль с позиции

 _pos_status = getPositionStatus();
 _sl_status = getStopLossStatus();
 _type_time = pos._type_time;
}

//+------------------------------------------------------------------+
//| Constructor with parameters                                      |
//+------------------------------------------------------------------+
CPosition::CPosition(ulong magic, string symbol, ENUM_TIMEFRAMES period, SPositionInfo &pi, STrailing &tr): 
                     _magic(magic), 
                     _symbol(symbol), 
                     _period(period)
{
//--- initialize trade functions class
 //Print("Конструктор с параметрами");
 UpdateSymbolInfo();
 _pos_info = pi;
 _trailing = tr;
 if(_pos_info.sl > 0 && _pos_info.sl < SymbInfo.StopsLevel()) _pos_info.sl = SymbInfo.StopsLevel();
 if(_pos_info.tp > 0 && _pos_info.tp < SymbInfo.StopsLevel()) _pos_info.tp = SymbInfo.StopsLevel();
 if(_pos_info.priceDifference > 0 && _pos_info.priceDifference < SymbInfo.StopsLevel()) _pos_info.priceDifference = SymbInfo.StopsLevel();
 if (_trailing.trailingStop < SymbInfo.StopsLevel()) _trailing.trailingStop = SymbInfo.StopsLevel();
 if(_pos_info.expiration <= 0)
 {
//--- check order expiration
  int exp=(int)SymbolInfoInteger(symbol,SYMBOL_EXPIRATION_MODE);
  if((exp&SYMBOL_EXPIRATION_GTC)==SYMBOL_EXPIRATION_GTC)
  {
   _type_time = ORDER_TIME_GTC;
   _pos_info.expiration_time = 0;
  }
  else if((exp&SYMBOL_EXPIRATION_SPECIFIED)==SYMBOL_EXPIRATION_SPECIFIED)
       {
        _type_time = ORDER_TIME_SPECIFIED;
        _pos_info.expiration_time = TimeCurrent()+31536000;
       }
       else if ((exp&SYMBOL_EXPIRATION_SPECIFIED_DAY)==SYMBOL_EXPIRATION_SPECIFIED_DAY)
            {
             _type_time = ORDER_TIME_SPECIFIED_DAY;
             _pos_info.expiration_time = (datetime)SymbolInfoInteger(symbol, SYMBOL_EXPIRATION_TIME) - PeriodSeconds(PERIOD_M1);
            }
            else 
            {
             _type_time = ORDER_TIME_DAY;
             _pos_info.expiration_time = 0;
            }
 }
 else
 {
  _type_time = ORDER_TIME_SPECIFIED;
  _pos_info.expiration_time = TimeCurrent()+_pos_info.expiration*PeriodSeconds(_period);  //помимио прочего нужно поменять во всем коде ORDER_TIME_SPECIFIED на ORDER_TIME_GTC 
 }
 trade = new CTMTradeFunctions();
 trailingStop = new CTrailingStop();
 _pos_status = POSITION_STATUS_NOT_INITIALISED;
 _sl_status = STOPLEVEL_STATUS_NOT_DEFINED;
}

//+------------------------------------------------------------------+
//|  Профит позиции в пунктах                                        |
//+------------------------------------------------------------------+
int CPosition::getPositionPointsProfit()
{
 UpdateSymbolInfo();
 double ask = SymbInfo.Ask();
 double bid = SymbInfo.Bid();
 int result = 0;
 if (_pos_info.type == OP_BUY)
  result = (int)((bid - _posAveragePrice)/_Point);
 if (_pos_info.type == OP_SELL)
  result = (int)((_posAveragePrice - ask)/_Point);
 
 return(result);
}
//+------------------------------------------------------------------+
//| Обновляет и возвращает значиние профита
//+------------------------------------------------------------------+
double CPosition::getPosProfit()
{
 double ask = 0, bid = 0;
 if (_posClosePrice > 0)
 { 
  ask = _posClosePrice;
  bid = _posClosePrice;
 }
 else
 {
  UpdateSymbolInfo();
  ask = SymbInfo.Ask();
  bid = SymbInfo.Bid();
 }
 switch(_pos_info.type)
 {
  case OP_BUY:
   _posProfit = (ask - _posAveragePrice) * _pos_info.volume;
   break;
  case OP_SELL:
   _posProfit = (_posAveragePrice - bid) * _pos_info.volume;
   break;
  case OP_BUYLIMIT:
  case OP_BUYSTOP:
  case OP_SELLLIMIT:
  case OP_SELLSTOP:
   _posProfit = 0;
   break;
 }

 return(_posProfit);
}

//+------------------------------------------------------------------+
//| Устанавливает StopLoss
//+------------------------------------------------------------------+
ENUM_STOPLEVEL_STATUS CPosition::setStopLoss()
{
 log_file.Write(LOG_DEBUG, StringFormat("%s Выставляем стоп-лосс", MakeFunctionPrefix(__FUNCTION__)));
 MqlDateTime mdt;
 TimeToStruct(_posOpenTime, mdt);
 //формируем комментарий
 string slComment = StringFormat("%s_%s_STOP", StringSubstr(MQL5InfoString(MQL5_PROGRAM_NAME), 0, 27), log_file.PeriodString());

 if (_pos_info.sl > 0 && _sl_status != STOPLEVEL_STATUS_PLACED)
 {
  if (_slPrice <= 0) _slPrice = SLPriceByType(_pos_info.type);
  
  _slType = SLOrderType((int)_pos_info.type);
  
  if (trade.OrderOpen(_symbol, _slType, _pos_info.volume, _slPrice, 0, 0, slComment))
  {
   _slTicket = trade.ResultOrder();
   _sl_status = STOPLEVEL_STATUS_PLACED;
   if (OrderSelect(_slTicket)) log_file.Write(LOG_DEBUG, StringFormat("%s Выставлен стоплосс %d c ценой %0.6f", MakeFunctionPrefix(__FUNCTION__), _slTicket, _slPrice));     
  }
  else
  {
   MqlTradeResult tradeResult;
   trade.Result(tradeResult);
   _sl_status = STOPLEVEL_STATUS_NOT_PLACED;
   log_file.Write(LOG_DEBUG, StringFormat("%s Ошибка при установке стоплосса %d", MakeFunctionPrefix(__FUNCTION__), tradeResult.retcode));
  }
 }
 return(_sl_status);
}

//+------------------------------------------------------------------+
//| Устанавливает TakeProfit
//+------------------------------------------------------------------+
ENUM_STOPLEVEL_STATUS CPosition::setTakeProfit()
{
 if (_pos_info.tp > 0)
 {
  _tpPrice = TPPriceByType(_pos_info.type);
  _takeProfitLine.Create(0, _tpPrice);
  log_file.Write(LOG_DEBUG, StringFormat("%s Выставлен виртуальный тейкпрофит с ценой %.05f", MakeFunctionPrefix(__FUNCTION__), _tpPrice));     
 }
 else
 {
  _tpPrice = 0;
 }
 return(STOPLEVEL_STATUS_PLACED);
}

//+------------------------------------------------------------------+
// Add additional volume to position
//+------------------------------------------------------------------+
bool CPosition::ChangeSize(double additionalVolume)
{
 ENUM_TM_POSITION_TYPE type = this.getType();
 if (additionalVolume < 0) type = getOppositeType(type);
 double openPrice = OpenPriceByType(type);
 string orderComment = StringFormat("%s_%s", StringSubstr(MQL5InfoString(MQL5_PROGRAM_NAME), 0, 27), log_file.PeriodString());
  
 if (type == OP_BUY || type == OP_SELL)
 {
  _posAveragePrice = (_pos_info.volume*_posAveragePrice + additionalVolume*openPrice)/(_pos_info.volume + additionalVolume);
 
  if(trade.PositionOpen(_symbol, PositionType(type), MathAbs(additionalVolume), openPrice, 0, 0, orderComment))
  {
   _pos_info.volume += additionalVolume;
   //PrintFormat("%s новый объем = %.02f", MakeFunctionPrefix(__FUNCTION__), _lots);
   if (_pos_info.volume < 0)
   {
    _pos_info.type = (ENUM_TM_POSITION_TYPE)(_pos_info.type + MathPow(-1, _pos_info.type));
    _pos_info.volume = MathAbs(_pos_info.volume);
    //PrintFormat("%s Позиция была перевернута, новый тип = %s", MakeFunctionPrefix(__FUNCTION__), GetNameOP(this.getType()));
    log_file.Write(LOG_DEBUG, StringFormat("%s Позиция была перевернута, новый тип = %s", MakeFunctionPrefix(__FUNCTION__), GetNameOP(this.getType()) ));      
   }
   
   log_file.Write(LOG_DEBUG, StringFormat("%s Изменена позиция %d, текущий тип = %s", MakeFunctionPrefix(__FUNCTION__), _tmTicket, GetNameOP(this.getType()) ) );
   
   if (_sl_status == STOPLEVEL_STATUS_PLACED) // Если статус не STOPLEVEL_STATUS_PLACED, то в тот момент когда стоплосс появится он будет уже с нужным объемом(за это отвечает переменная _lots)
   {
    if (ChangeStopLossVolume() == STOPLEVEL_STATUS_PLACED)
    {
     _pos_status = POSITION_STATUS_OPEN;
     log_file.Write(LOG_DEBUG, StringFormat("%s Изменили позицию и стоплосс", MakeFunctionPrefix(__FUNCTION__)) );
     return(true);
    }
    else
    {
     _pos_status = POSITION_STATUS_NOT_CHANGED;
     log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось изменить стоплосс", MakeFunctionPrefix(__FUNCTION__) ));
     return (false);
    }
   }
  }
  else
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось изменить позицию", MakeFunctionPrefix(__FUNCTION__) ));
   return (false);
  }
 }
 else
 {
  if (trade.OrderDelete(_orderTicket))
  {
   if (trade.OrderOpen(_symbol, OrderType(getType()), additionalVolume, openPrice, _type_time, _pos_info.expiration_time)) // у отлоотложенного ордера отсутствует expiration time и он может быть только снят руками
   {
   // PrintFormat("%s Изменен ордер %d; время истечения %s", MakeFunctionPrefix(__FUNCTION__), _tmTicket, TimeToString(_expiration));
    log_file.Write(LOG_DEBUG, StringFormat("%s Изменен ордер %d; время истечения %s", MakeFunctionPrefix(__FUNCTION__), _tmTicket, TimeToString(_pos_info.expiration_time)));
   }
   else
   {
 //   PrintFormat("%s Не удалось установить новый ордер при изменении отложенной позиции", MakeFunctionPrefix(__FUNCTION__));
    log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось установить новый ордер при изменении отложенной позиции", MakeFunctionPrefix(__FUNCTION__)));
   }
  }
  else
  {
  // PrintFormat("%s Не удалось удалить ордер %d при изменении отложенной позиции", MakeFunctionPrefix(__FUNCTION__), _tmTicket);
   log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось удалить ордер %d при изменении отложенной позиции", MakeFunctionPrefix(__FUNCTION__), _tmTicket));
  }
  
 }
 return(true);
}

//+------------------------------------------------------------------+
//| Изменяет объем StopLoss
//+------------------------------------------------------------------+
ENUM_STOPLEVEL_STATUS CPosition::ChangeStopLossVolume()
{
 if (RemoveStopLoss() == STOPLEVEL_STATUS_DELETED)
 {
  setStopLoss();
 }
 return (_sl_status);
}

//+------------------------------------------------------------------+
//| Проверка на то что цена прошла уровень TakeProfit
//+------------------------------------------------------------------+
bool CPosition::CheckTakeProfit(void)
{
 if (_tpPrice > 0)
 {
  UpdateSymbolInfo();
  if (_pos_info.type == OP_SELL && _tpPrice >= SymbInfo.Ask())
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Позиция Селл, пройден уровень тейкпрофит ",MakeFunctionPrefix(__FUNCTION__))  );
  }
  if (_pos_info.type == OP_BUY  && _tpPrice <= SymbInfo.Bid())
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Позиция Бай, пройден уровень тейкпрофит ",MakeFunctionPrefix(__FUNCTION__)) );
  }
  return ((_pos_info.type == OP_SELL && _tpPrice >= SymbInfo.Ask()) || 
          (_pos_info.type == OP_BUY  && _tpPrice <= SymbInfo.Bid()) );
 }
 return (false);
}

//+------------------------------------------------------------------+
//| Закрытие позиции
//+------------------------------------------------------------------+
bool CPosition::ClosePosition()
{
 int i = 0;
 ResetLastError();
 if (_pos_status == POSITION_STATUS_PENDING)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s RemovePendingPosition", MakeFunctionPrefix(__FUNCTION__)));
  _pos_status = RemovePendingPosition();
 }
 
 if (_pos_status == POSITION_STATUS_OPEN || _pos_status == POSITION_STATUS_NOT_COMPLETE) // статус open от статуса not_complete отличается только присутствием стоплоса. 
 {                                                                                       // соответсвенно для закрытия позиции со статусом not_complete нам нужно просто не трогать стоплосс, так как его нет 
  switch(_pos_info.type)
  {
   case OP_BUY:
    if(trade.PositionClose(_symbol, POSITION_TYPE_BUY, _pos_info.volume, config.Deviation))
    {     
     _pos_status = POSITION_STATUS_CLOSED;
     log_file.Write(LOG_DEBUG, StringFormat("%s Закрыта позиция %d", MakeFunctionPrefix(__FUNCTION__), _tmTicket));
    }
    else
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s Ошибка при удалении позиции BUY.Error(%d) = %s.Result retcode %d = %s", MakeFunctionPrefix(__FUNCTION__), ::GetLastError(), ErrorDescription(::GetLastError()), trade.ResultRetcode(), trade.ResultRetcodeDescription()));
    }
    break;
   case OP_SELL:
    if(trade.PositionClose(_symbol, POSITION_TYPE_SELL, _pos_info.volume, config.Deviation))
    {
     _pos_status = POSITION_STATUS_CLOSED;
     log_file.Write(LOG_DEBUG, StringFormat("%s Закрыта позиция %d", MakeFunctionPrefix(__FUNCTION__), _tmTicket));
    }
    else
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s Ошибка при удалении позиции SELL.Error(%d) = %s.Result retcode %d = %s", MakeFunctionPrefix(__FUNCTION__), ::GetLastError(), ErrorDescription(::GetLastError()), trade.ResultRetcode(), trade.ResultRetcodeDescription()));    
    }
    break;
   default:
    break;
  }
  
  if (_sl_status == STOPLEVEL_STATUS_PLACED) // при статусе not_complete сюда не зайдем так как _sl_status = STOPLEVEL_STATUS_NOT_PLACED 
  {
   _sl_status = RemoveStopLoss();
  }
 }
 
 if (_pos_status == POSITION_STATUS_CLOSED)
 {
  _posClosePrice = PriceByType(_pos_info.type);   //сохраняем цену закрытия позиции
  _posCloseTime = TimeCurrent();         //сохраняем время закрытия позиции
  getPosProfit();                        //обновляет профит позиции
 }
 
 _takeProfitLine.Delete();
 return(_pos_status != POSITION_STATUS_NOT_DELETED
      && _sl_status != STOPLEVEL_STATUS_NOT_DELETED);
}

void CPosition::DoTrailing()
{
 double sl = 0;
 switch(_trailing.trailingType)
 {
  case TRAILING_TYPE_USUAL :
   sl =  trailingStop.UsualTrailing(_symbol, _pos_info.type, _posAveragePrice, _slPrice, _trailing.minProfit, _trailing.trailingStop, _trailing.trailingStep);  
   break;
  case TRAILING_TYPE_LOSSLESS :
   sl = trailingStop.LosslessTrailing(_symbol, _pos_info.type, _posAveragePrice, _slPrice, _trailing.minProfit, _trailing.trailingStop, _trailing.trailingStep);  
   break;
  case TRAILING_TYPE_PBI :
   sl = trailingStop.PBITrailing(_symbol, _pos_info.type, _posAveragePrice, _slPrice, _trailing.handleForTrailing, _trailing.minProfit);  
   break;
  case TRAILING_TYPE_EXTREMUMS :
   sl = trailingStop.ExtremumsTrailing(_symbol, _pos_info.type, _slPrice, _posAveragePrice, _trailing.handleForTrailing);
   break;
  case TRAILING_TYPE_ATR :
   sl = trailingStop.ATRTrailing(_symbol, _pos_info.type, _period, _trailing.handleForTrailing, _posAveragePrice, _slPrice, _trailing.minProfit);
   break;
  case TRAILING_TYPE_NONE :
  default:
   break;
 }
 if (sl > 0) ModifyPosition(sl, 0);
}


//+------------------------------------------------------------------+
//|Получение информации о достижении минимального профита            |
//+------------------------------------------------------------------+
bool CPosition::isMinProfit(void)
{
 UpdateSymbolInfo();
 double ask = SymbInfo.Ask();
 double bid = SymbInfo.Bid();
 double point = SymbInfo.Point();
 
 if (getType() == OP_BUY && LessDoubles(_posAveragePrice, bid - _trailing.minProfit*point))
  return true;
 if (getType() == OP_SELL && GreatDoubles(_posAveragePrice, ask + _trailing.minProfit*point))
  return true;
  
 return false;
}

//+------------------------------------------------------------------+
//| EMPTY
//+------------------------------------------------------------------+
bool CPosition::ModifyPosition(double sl, double tp)
{
 //PrintFormat("Изменяем стоп-лосс");
  //если позиция реальная, то меняем отложенный ордер sl
 if (_pos_info.type == OP_BUY || _pos_info.type == OP_SELL)
 {
  if (trade.StopOrderModify(_slTicket, sl))
  {
   _slPrice = sl;
   log_file.Write(LOG_DEBUG, StringFormat("%s Изменили СтопЛосс, новый стоплосс %.05f", MakeFunctionPrefix(__FUNCTION__), _slPrice) ) ;
   return (true);
  }
  else
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось изменить СтопЛосс",MakeFunctionPrefix(__FUNCTION__)) );
  }
 }
 //else
//если позиция задана отложенным ордером, то меняем просто цену
 if (_pos_info.type == OP_BUYSTOP  || _pos_info.type == OP_SELLSTOP || _pos_info.type == OP_BUYLIMIT || _pos_info.type == OP_SELLLIMIT) 
 {
  _slPrice = sl;
  log_file.Write(LOG_DEBUG, StringFormat("%s Изменили СтопЛосс, новый стоплосс %.05f", MakeFunctionPrefix(__FUNCTION__), _slPrice) );
  return (true);
 }
 return(false);
}

//+------------------------------------------------------------------+
/// Increments Config.VirtualOrderTicketGlobalVariable.
/// \return    Unique long integer
//+------------------------------------------------------------------+
ulong CPosition::NewTicket()
{
 CGlobalVariable g_lTicket;
 g_lTicket.Name(Config.VirtualOrderTicketGlobalVariable);
 _tmTicket=g_lTicket.Increment();
 return(_tmTicket);
}

//+------------------------------------------------------------------+
//| Открытие позиции
//+------------------------------------------------------------------+
ENUM_POSITION_STATUS CPosition::OpenPosition()
{
 UpdateSymbolInfo();
 _posOpenPrice = OpenPriceByType(_pos_info.type);
 log_file.Write(LOG_DEBUG, StringFormat("%s, type = %s, _posOpenPrice=%.05f, bid = %.05f, diff = %.05f", MakeFunctionPrefix(__FUNCTION__), GetNameOP(_pos_info.type), _posOpenPrice, SymbInfo.Bid(), _pos_info.priceDifference));
 _posAveragePrice = OpenPriceByType(_pos_info.type);
 _posOpenTime = TimeCurrent(); //сохраняем время открытия позиции    
 _posProfit = 0;
 
 ENUM_ORDER_TYPE oType = OrderType(_pos_info.type);
 
 //формируем комментарий
 MqlDateTime mdt;
 TimeToStruct(_posOpenTime, mdt);
 string orderComment = StringFormat("%s_%s", StringSubstr(MQL5InfoString(MQL5_PROGRAM_NAME), 0, 27), log_file.PeriodString());
 
 switch(_pos_info.type)
 {
  case OP_BUY:
   log_file.Write(LOG_DEBUG, StringFormat("%s, Открываем позицию Бай, объем = %.02f", MakeFunctionPrefix(__FUNCTION__), _pos_info.volume));
   if(trade.PositionOpen(_symbol, POSITION_TYPE_BUY, _pos_info.volume, _posOpenPrice, 0, 0, orderComment))
   {
    _orderTicket = 0;
    log_file.Write(LOG_DEBUG, StringFormat("%s Открыта позиция", MakeFunctionPrefix(__FUNCTION__)));
    if (setStopLoss() != STOPLEVEL_STATUS_NOT_PLACED && setTakeProfit() != STOPLEVEL_STATUS_NOT_PLACED)
    {
     _pos_status = POSITION_STATUS_OPEN;
    }
    else
    {
     _pos_status = POSITION_STATUS_NOT_COMPLETE;
    }
   }
   break;
  case OP_SELL:
   log_file.Write(LOG_DEBUG, StringFormat("%s, Открываем позицию Селл, объем = %.02f", MakeFunctionPrefix(__FUNCTION__), _pos_info.volume));
   if(trade.PositionOpen(_symbol, POSITION_TYPE_SELL, _pos_info.volume, _posOpenPrice, 0, 0, orderComment))
   {
    _orderTicket = 0;
    log_file.Write(LOG_DEBUG, StringFormat("%s Открыта позиция ", MakeFunctionPrefix(__FUNCTION__)));
    if (setStopLoss() != STOPLEVEL_STATUS_NOT_PLACED && setTakeProfit() != STOPLEVEL_STATUS_NOT_PLACED)
    {
     _pos_status = POSITION_STATUS_OPEN;   
    }
    else
    {
     _pos_status = POSITION_STATUS_NOT_COMPLETE;
    }
   }
   break;
  case OP_BUYLIMIT:
  case OP_SELLLIMIT:
  case OP_BUYSTOP:
  case OP_SELLSTOP:
   if (trade.OrderOpen(_symbol, oType, _pos_info.volume, _posOpenPrice, _type_time, _pos_info.expiration_time, orderComment))
   {
    _orderTicket = trade.ResultOrder();
    _pos_status = POSITION_STATUS_PENDING;
    if (_pos_info.sl > 0) _slPrice = SLPriceByType(_pos_info.type);
    log_file.Write(LOG_DEBUG, StringFormat("%s Открыт отложенный ордер #%d; тип истечения %s, время истечения %s", MakeFunctionPrefix(__FUNCTION__), _orderTicket,  EnumToString(_type_time), TimeToString(_pos_info.expiration_time)));
   }
   break;
  default:
   log_file.Write(LOG_DEBUG, StringFormat("%s Задан неверный тип позиции",MakeFunctionPrefix(__FUNCTION__)) );
   break;
 }

 NewTicket();
 return(_pos_status);
}

//+------------------------------------------------------------------+
//| Вычисляет уровень открытия в зависимости от типа                 |
//+------------------------------------------------------------------+
double CPosition::OpenPriceByType(ENUM_TM_POSITION_TYPE type)
{
 UpdateSymbolInfo();
 double ask = SymbInfo.Ask();
 double bid = SymbInfo.Bid();
 double point = SymbInfo.Point();
 if(type == OP_BUY) return(ask);
 if(type == OP_SELL) return(bid);
 if(type == OP_BUYLIMIT  || type == OP_SELLSTOP) return(bid - _pos_info.priceDifference*point);
 if(type == OP_SELLLIMIT || type == OP_BUYSTOP)  return(ask + _pos_info.priceDifference*point);
 return(-1);
}

//+------------------------------------------------------------------+
//| Вычисляет уровень открытия в зависимости от типа                 |
//+------------------------------------------------------------------+
double CPosition::PriceByType(ENUM_TM_POSITION_TYPE type)
{
 UpdateSymbolInfo();
 double ask = SymbInfo.Ask();
 double bid = SymbInfo.Bid();
 double point = SymbInfo.Point();
 if(type == OP_BUY || type == OP_SELLLIMIT || type == OP_BUYSTOP) return(ask);
 if(type == OP_SELL || type == OP_BUYLIMIT  || type == OP_SELLSTOP) return(bid);
 return(-1);
}

//+------------------------------------------------------------------+
/// Reads order line from an open file handle.
/// File should be FILE_CSV format
/// \param [in] handle					Handle of the CSV file
/// \param [in] bCreateLineObjects  if true, creates open, sl & tp lines on chart 
/// \return 				True if successful, false otherwise
//+------------------------------------------------------------------+
bool CPosition::ReadFromFile(int  handle)
{
 if(handle != INVALID_HANDLE)
 {
  if(FileIsEnding(handle)) return false;
  _magic           = StringToInteger(FileReadString(handle));                     //считываем мэджик
 // Alert("> MAGIC = ",FileReadString(handle));  
  if(FileIsEnding(handle)) return false; 
   _symbol         = FileReadString(handle);                                      //считываем символ
//  Alert("> SYMBOL = ",FileReadString(handle));   
  if(FileIsEnding(handle)) return false;  
  _pos_info.type   = StringToPositionType(FileReadString(handle));                //считываем тип
 // Alert("> TYPE = ",_type);    
  if(FileIsEnding(handle)) return false;   
  _pos_info.volume = StringToDouble(FileReadString(handle));                      //считываем размер лота
 // Alert("> LOT = ",_lots);
  if(FileIsEnding(handle)) return false;   
  _pos_status      = StringToPositionStatus(FileReadString(handle));              //считываем статус позиции
 // Alert("> POS STATUS = ",_pos_status);  
  if(FileIsEnding(handle)) return false;   
  _tmTicket        = StringToInteger(FileReadString(handle));                     //считываем тикет позиции
 // Alert("> LOT = ",_lots);  
  if(FileIsEnding(handle)) return false;   
  _orderTicket     = StringToInteger(FileReadString(handle));                     //считываем тикет позиции
 // Alert("> POS TICKET = ",_posTicket);
  if(FileIsEnding(handle)) return false;   
  _sl_status       = StringToStoplevelStatus(FileReadString(handle));             //считываем статус стоп левела 
  // Alert("> Stoplevel STATUS = ",_pos_status);  
  if(FileIsEnding(handle)) return false;   
  _slTicket        = StringToInteger(FileReadString(handle));                     //считываем тикет стоп лосса  
 // Alert("> STOP LOSS TICKET = ",_slTicket);  
  if(FileIsEnding(handle)) return false;    
  _slPrice         = StringToDouble(FileReadString(handle));                      //считываем цену стоп лосса
 // Alert("> STOP LOSS PRICE = ",_slPrice);
  if(FileIsEnding(handle)) return false;    
  _slType          = StringToOrderType(FileReadString(handle));                   //считываем тип стоп лосса
 // Alert("> STOP LOSS PRICE = ",_slPrice);    
  if(FileIsEnding(handle)) return false;    
  _pos_info.sl     = (int)StringToInteger(FileReadString(handle));                     //считываем стоп лосс
 // Alert("> STOP LOSS = ",_pos_info.sl); 
  if(FileIsEnding(handle)) return false;    
  _pos_info.tp     = (int)StringToInteger(FileReadString(handle));                     //считываем тейк профит
 // Alert("> TAKE PROFIT = ",_pos_info.tp);
  if(FileIsEnding(handle)) return false;  
  _tpPrice         = StringToDouble(FileReadString(handle));                      //считываем цену тейк профита
 // Alert("> TAKE PROFIT PRICE = ",_tpPrice);  
  if(FileIsEnding(handle)) return false;  
  _trailing.trailingType = StringToTrailingType(FileReadString(handle));          //считываем тип трейлинга
 // Alert("> Trailing type = ",_trailing.trailingType);
  if(FileIsEnding(handle)) return false;    
  _trailing.minProfit    = (int)StringToInteger(FileReadString(handle));               //Мин профит
 // Alert("> MIN PROFIT = ",_trailing.minProfit);  
  if(FileIsEnding(handle)) return false;    
  _trailing.trailingStop = (int)StringToInteger(FileReadString(handle));               //Трейлинг стоп
 // Alert("> TRAILING STOP = ",_trailing.trailingStop); 
  if(FileIsEnding(handle)) return false;    
  _trailing.trailingStep = (int)StringToInteger(FileReadString(handle));               //Трейлинг степ
 // Alert("> TRAILING STEP = ",_trailing.trailingStep); 
  if(FileIsEnding(handle)) return false;    
  _posOpenPrice    = StringToDouble(FileReadString(handle));                      //цена открытия позиции
 // Alert("> POS OPEN PRICE = ",_posOpenPrice); 
  if(FileIsEnding(handle)) return false;    
  _posClosePrice   = StringToDouble(FileReadString(handle));                      //цена закрытия позиции
 // Alert("> POS CLOSE PRICE = ",_posClosePrice); 
  if(FileIsEnding(handle)) return false;    
  _posOpenTime     = StringToTime(FileReadString(handle));                        //время открытия позиции
 // Alert("> POS OPEN TIME = ",_posOpenTime); 
  if(FileIsEnding(handle)) return false;    
  _posCloseTime    = StringToTime(FileReadString(handle));                        //время закрытия позиции
 // Alert("> POS CLOSE TIME = ",_posCloseTime); 
  if(FileIsEnding(handle)) return false;    
  _posAveragePrice = StringToDouble(FileReadString(handle));                      //средняя цена позиции
 // Alert("> POS AVERAGE PRICE = ",_posAveragePrice);
 if(FileIsEnding(handle)) return false;    
  _pos_info.priceDifference = (int)StringToInteger(FileReadString(handle));            //разница между позицией и отложенником
 // Alert("> POS PRICE DIFFERENCE = ",_pos_info.priceDifference); 
                                //пропуск пустого символа                                  
  return true;
 }
 return false;
}
 
//+------------------------------------------------------------------+
//| Удалить отложенный ордер
//+------------------------------------------------------------------+
ENUM_POSITION_STATUS CPosition::RemovePendingPosition()
{
 if (_pos_status == POSITION_STATUS_PENDING || _pos_status == POSITION_STATUS_NOT_DELETED)
 {
  if (trade.OrderDelete(_orderTicket))
  {
   _pos_status = POSITION_STATUS_DELETED;
   log_file.Write(LOG_DEBUG, StringFormat("%s Удалось удалить отложенный ордер по тикету %i",MakeFunctionPrefix(__FUNCTION__), _orderTicket   ) );   
  }
  else
  {
   _pos_status = POSITION_STATUS_NOT_DELETED;
   log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось удалить отложенный ордер по тикету %i",MakeFunctionPrefix(__FUNCTION__), _orderTicket   ) );      
  }
 }
 return(_pos_status);
}

//+------------------------------------------------------------------+
//| Удалить StopLoss
//+------------------------------------------------------------------+
ENUM_STOPLEVEL_STATUS CPosition::RemoveStopLoss()
{
 ResetLastError();
 if (_sl_status == STOPLEVEL_STATUS_NOT_PLACED)
 {
  _sl_status = STOPLEVEL_STATUS_DELETED;
 }
 
 if (_sl_status == STOPLEVEL_STATUS_PLACED || _sl_status == STOPLEVEL_STATUS_NOT_DELETED) // Если ордер был установлен или его не удалось удалить в прошлом
 {
  if (OrderSelect(_slTicket))
  {
   if (trade.OrderDelete(_slTicket))
   {
    _sl_status = STOPLEVEL_STATUS_DELETED;
    log_file.Write(LOG_DEBUG, StringFormat("%s Удален стоплосс %d", MakeFunctionPrefix(__FUNCTION__), _slTicket));
   }
   else
   {
    _sl_status = STOPLEVEL_STATUS_NOT_DELETED;
    log_file.Write(LOG_DEBUG, StringFormat("%s Ошибка при удалении стоплосса.Error(%d) = %s.Result retcode %d = %s", MakeFunctionPrefix(__FUNCTION__), ::GetLastError(), ErrorDescription(::GetLastError()), trade.ResultRetcode(), trade.ResultRetcodeDescription()));
   }
  }
  else
  {
   switch(_pos_info.type)
   {
    case OP_BUY:
    case OP_BUYLIMIT:
    case OP_BUYSTOP:
     if (trade.PositionClose(_symbol, POSITION_TYPE_SELL, _pos_info.volume)) // тип позиции бай, мы закрываем стоп ордер - селл
     {
      _sl_status = STOPLEVEL_STATUS_DELETED;

      log_file.Write(LOG_DEBUG, StringFormat("%s Удален сработавший стоплосс %d", MakeFunctionPrefix(__FUNCTION__), _slTicket));
      break;
     }
     else
     {
      log_file.Write(LOG_DEBUG, StringFormat("%s Ошибка при удалении стоплосса.Error(%d) = %s.Result retcode %d = %s", MakeFunctionPrefix(__FUNCTION__), ::GetLastError(), ErrorDescription(::GetLastError()), trade.ResultRetcode(), trade.ResultRetcodeDescription()));
     }
     
    case OP_SELL:
    case OP_SELLLIMIT:
    case OP_SELLSTOP:
     if (trade.PositionClose(_symbol, POSITION_TYPE_BUY, _pos_info.volume)) // тип позиции селл, мы закрываем стоп ордер - бай
     {
      _sl_status = STOPLEVEL_STATUS_DELETED;

      log_file.Write(LOG_DEBUG, StringFormat("%s Удален сработавший стоплосс %d", MakeFunctionPrefix(__FUNCTION__), _slTicket));
      break;
     }
     else
     {
      log_file.Write(LOG_DEBUG, StringFormat("%s Ошибка при удалении стоплосса.Error(%d) = %s.Result retcode %d = %s", MakeFunctionPrefix(__FUNCTION__), ::GetLastError(), ErrorDescription(::GetLastError()), trade.ResultRetcode(), trade.ResultRetcodeDescription()));
     }
   }
  }
 }
 return (_sl_status);
}

//+------------------------------------------------------------------+
//| Вычисляет уровень стоплосса в зависимости от типа                |
//+------------------------------------------------------------------+
double CPosition::SLPriceByType(ENUM_TM_POSITION_TYPE type)
{
 UpdateSymbolInfo();
 if(type == 0 || type == 2 || type == 4) return(SymbInfo.Bid()-_pos_info.sl*SymbInfo.Point()); // Buy
 if(type == 1 || type == 3 || type == 5) return(SymbInfo.Ask()+_pos_info.sl*SymbInfo.Point()); // Sell
 return(0);
}

//+------------------------------------------------------------------+
//| Вычисляет уровень открытия в зависимости от типа                 |
//+------------------------------------------------------------------+
double CPosition::StopLevelByType(ENUM_TM_POSITION_TYPE type)
{
 UpdateSymbolInfo();
 if(type == 0 || type == 2 || type == 4) return(SymbInfo.Bid()-SymbInfo.StopsLevel()*SymbInfo.Point()); // Buy
 if(type == 1 || type == 3 || type == 5) return(SymbInfo.Ask()+SymbInfo.StopsLevel()*SymbInfo.Point()); // Sell
 return(0);
}

//+------------------------------------------------------------------+
//| Вычисляет уровень тейкпрофита в зависимости от типа              |
//+------------------------------------------------------------------+
double CPosition::TPPriceByType(ENUM_TM_POSITION_TYPE type)
{
 UpdateSymbolInfo();
 if(type == 0 || type == 2 || type == 4) return(SymbInfo.Ask()+_pos_info.tp*SymbInfo.Point()); // Buy 
 if(type == 1 || type == 3 || type == 5) return(SymbInfo.Bid()-_pos_info.tp*SymbInfo.Point()); // Sell
 return(0);
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
            GetNameOP(_pos_info.type), 
            _pos_info.volume,            
            _tmTicket, 
            _orderTicket,
            PositionStatusToStr(_pos_status),      
            _slTicket,        
            _slPrice,
            EnumToString(_slType),
            StoplevelStatusToStr(_sl_status),         
            _pos_info.sl,
            _pos_info.tp,              
            _tpPrice,
            GetNameTrailing(_trailing.trailingType),
            _trailing.minProfit,         
            _trailing.trailingStop,   
            _trailing.trailingStep,    
            _posOpenPrice,
            _posClosePrice,
            _posOpenTime,
            _posCloseTime,
            _posAveragePrice,
            _pos_info.priceDifference
            );
           // Alert("POS AVER PRICE = ",_posAveragePrice);
 }
}  


//---------------PRIVATE-----------------------------

//+------------------------------------------------------------------+
//| Возвращает тип позиции, противоположный переданному
//+------------------------------------------------------------------+
ENUM_TM_POSITION_TYPE CPosition::getOppositeType(ENUM_TM_POSITION_TYPE type)
{
 ENUM_TM_POSITION_TYPE res;
 switch (type)
 {
  case OP_BUY:
   res = OP_SELL;
   break;
  case OP_SELL:
   res = OP_BUY;
   break;
  case OP_BUYLIMIT:
   res = OP_SELLLIMIT;
   break;
  case OP_SELLLIMIT:
   res = OP_BUYLIMIT;
   break;
  case OP_BUYSTOP:
   res = OP_SELLSTOP;
   break;
  case OP_SELLSTOP:
   res = OP_BUYSTOP;
   break;
  default:
   res = -1;
   break;
 }
 return(res);
}

//+------------------------------------------------------------------+
//| Возвращает тип ордера StopLoss
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE CPosition::SLOrderType(int type)
{
 ENUM_ORDER_TYPE res = -1;
 if(type == 0 || type == 2 || type == 4) res = ORDER_TYPE_SELL_STOP; // Buy
 if(type == 1 || type == 3 || type == 5) res = ORDER_TYPE_BUY_STOP;  // Sell
 return(res);
}

//+------------------------------------------------------------------+
//| Возвращает тип ордера TakeProfit
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE CPosition::TPOrderType(int type)
{
 ENUM_ORDER_TYPE res = -1;
 if(type == 0 || type == 2 || type == 4) res = ORDER_TYPE_SELL_LIMIT; // Buy
 if(type == 1 || type == 3 || type == 5) res = ORDER_TYPE_BUY_LIMIT;  // Sell
 return(res);
}

//+------------------------------------------------------------------+
//| Возвращает тип позиции
//+------------------------------------------------------------------+
ENUM_POSITION_TYPE CPosition::PositionType(int type)
{
 ENUM_POSITION_TYPE res = -1;
 if(type == 0) res = POSITION_TYPE_BUY;
 if(type == 1) res = POSITION_TYPE_SELL;
 return(res);
}

//+------------------------------------------------------------------+
//| Возвращает тип отложенного ордера
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE CPosition::OrderType(int type)
{
 ENUM_ORDER_TYPE res = -1;
 switch (type)
 {
  case OP_BUYLIMIT:
   res = ORDER_TYPE_BUY_LIMIT;
   break;
  case OP_SELLLIMIT:
   res = ORDER_TYPE_SELL_LIMIT;
   break;
  case OP_BUYSTOP:
   res = ORDER_TYPE_BUY_STOP;
   break;
  case OP_SELLSTOP:
   res = ORDER_TYPE_SELL_STOP;
   break;
 }
 return(res);
}











