//+------------------------------------------------------------------+
//|                                                     Position.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#include "test_CTMTradeFunctions.mqh" //подключаем библиотеку для совершения торговых операций
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class test_CPosition : public CObject
  {
private:
   CSymbolInfo SymbInfo;
   test_CTMTradeFunctions *trade;
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
   
   bool pos_opened, sl_placed, tp_placed;
   bool pos_closed, sl_removed, tp_removed;
   
public:
  void test_CPosition(ulong magic, string symbol, ENUM_POSITION_TYPE type, double volume
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
 };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
test_CPosition::test_CPosition(ulong magic, string symbol, ENUM_POSITION_TYPE type, double volume
                    ,int sl = 0, int tp = 0, int minProfit = 0, int trailingStop = 0, int trailingStep = 0)
                    : _magic(magic), _symbol(symbol), _type(type), _lots(volume)
                    , _sl(sl), _tp(tp), _minProfit(minProfit), _trailingStop(trailingStop), _trailingStep(trailingStep)
  {
//--- initialize trade functions class
   trade = new test_CTMTradeFunctions();
  }
 
//+------------------------------------------------------------------+
//|Получение актуальной информации по торговому инструменту          |
//+------------------------------------------------------------------+
bool test_CPosition::UpdateSymbolInfo()
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
double test_CPosition::pricetype(int type)
{
 UpdateSymbolInfo();
 if(type == 0)return(SymbInfo.Ask());
 if(type == 1)return(SymbInfo.Bid());
 return(-1);
}
//+------------------------------------------------------------------+
//| Вычисляет уровень стоплосса в зависимости от типа                |
//+------------------------------------------------------------------+
double test_CPosition::SLtype(int type)
{
 UpdateSymbolInfo();
 if(type==0)return(SymbInfo.Bid()-_sl*SymbInfo.Point()); // Buy
 if(type==1)return(SymbInfo.Ask()+_sl*SymbInfo.Point()); // Sell
 return(0);
}
//+------------------------------------------------------------------+
//| Вычисляет уровень тейкпрофита в зависимости от типа              |
//+------------------------------------------------------------------+
double test_CPosition::TPtype(int type)
{
 UpdateSymbolInfo();
 if(type==0)return(SymbInfo.Ask()+_tp*SymbInfo.Point()); // Buy 
 if(type==1)return(SymbInfo.Bid()-_tp*SymbInfo.Point()); // Sell
 return(0);
}

ENUM_ORDER_TYPE test_CPosition::SLOrderType(int type)
{
 ENUM_ORDER_TYPE res;
 if(type==0) res = ORDER_TYPE_SELL_STOP; // Buy
 if(type==1) res = ORDER_TYPE_BUY_STOP; // Sell
 return(res);
}

ENUM_ORDER_TYPE test_CPosition::TPOrderType(int type)
{
 ENUM_ORDER_TYPE res;
 if(type==0) res = ORDER_TYPE_SELL_LIMIT; // Buy
 if(type==1) res = ORDER_TYPE_BUY_LIMIT; // Sell
 return(res);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool test_CPosition::OpenPosition()
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
 pos_opened = false;
 sl_placed = true;
 tp_placed = true;
 
 if (trade.PositionOpen(_symbol, _type, _lots, _posPrice))
 {
  _posTicket = trade.ResultDeal();
  pos_opened = true;
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
   PrintFormat("%s Выставлен тейкпрофит %d", MakeFunctionPrefix(__FUNCTION__), _tpTicket);
  }
  else
  {
   tp_placed = false;
   PrintFormat("%s Ошибка при установке тейкпрофита", MakeFunctionPrefix(__FUNCTION__));
  }
 }
 
 // Если задан стоплосс - устанавливаем
 if (_sl > 0)
 {
  _slPrice = SLtype((int)_type);
  order_type = SLOrderType((int)_type);
  if (trade.OrderOpen(_symbol, order_type, _lots, _slPrice)) //, sl + stopLevel, sl - stopLevel);
  {
   _slTicket = trade.ResultOrder();
   PrintFormat("%s Выставлен стоплосс %d", MakeFunctionPrefix(__FUNCTION__), _slTicket);     
  }
  else
  {
   sl_placed = false;
   PrintFormat("%s Ошибка при установке стоплосса", MakeFunctionPrefix(__FUNCTION__));
  }
 }
      
 if (pos_opened && sl_placed && tp_placed)
 {
  return(true);
 }
 return(false);
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool test_CPosition::ClosePosition()
{
 int i = 0;
 pos_closed = false;
 sl_removed = false;
 tp_removed = false;
 
 if (trade.PositionClose(_symbol, _type, _lots, 50))
 {
  pos_closed = true;
 }
 
 if (sl_placed)
 {
  if (trade.OrderDelete(_slTicket))
  {
   sl_removed = true;
   sl_placed = false;
  }
 }
 else
 {
  sl_removed = true;
  sl_placed = false;
 }
  
 if (tp_placed)
 {
  if (trade.OrderDelete(_tpTicket))
  {
   tp_removed = true;
   tp_placed = false;
  }
 }
 else
 {
  tp_removed = true;
  tp_placed = false;
 }
  
 return(pos_closed && sl_removed && tp_removed);
}

