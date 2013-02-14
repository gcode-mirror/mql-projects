//+------------------------------------------------------------------+
//|                                                CTradeManager.mqh |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <CompareDoubles.mqh>

//--- Объявление констант
#define OP_BUY 0           //Покупка 
#define OP_SELL 1          //Продажа 
#define OP_BUYLIMIT 2      //Отложенный ордер BUY LIMIT 
#define OP_SELLLIMIT 3     //Отложенный ордер SELL LIMIT 
#define OP_BUYSTOP 4       //Отложенный ордер BUY STOP 
#define OP_SELLSTOP 5      //Отложенный ордер SELL STOP 

//+------------------------------------------------------------------+
//| Класс обеспечивает вспомогательные торговые вычисления           |
//+------------------------------------------------------------------+
class CTradeManager
  {
protected:
  CPositionInfo PosInfo;
  CSymbolInfo SymbInfo;
  MqlTradeRequest request;      // указатель на структуру запроса по OrderSend
  MqlTradeResult trade_result;  // указатель на структуру ответа по OrderSend
  string _symbol;              // символ
  ulong _magic;
  int _digits;                 // количество знаков после запятой у цены
  double _point;               // значение пункта
  int _stopLevel;
  int _freezeLevel;
  double _bid;
  double _ask;
  int _spread; 
  int _SL, _TP;
  int _minProfit, _trailingStop, _trailingStep;
  int _numberOfTry; 
  bool _useSound;
  string _nameFileSound;   // Наименование звукового файла
  
public:
  void CTradeManager(string symbol, ulong magic, int SL, int TP, int minProfit, int trailingStop, int trailingStep)
             : _symbol(symbol), _magic(magic), _point(SymbolInfoDouble(_symbol, SYMBOL_POINT))
             , _SL(SL), _TP(TP), _minProfit(minProfit), _trailingStop(trailingStop), _trailingStep(trailingStep)
             , _numberOfTry(5), _useSound(true), _nameFileSound("expert.wav"){};
  double pricetype(int type);     // вычисляет уровень открытия в зависимости от типа 
  double SLtype(int type);        // вычисляет уровень стоп-лосса в зависимости от типа
  double TPtype(int type);        // вычисляет уровень тейк-профита в зависимости от типа
               // возвращает спред текущего инструмента
  
  bool UpdateSymbolInfo();
  void SendOrder(ENUM_ORDER_TYPE type,double volume);
  void DoTrailing();
  void ModifyPosition(ENUM_TRADE_REQUEST_ACTIONS trade_action);
  string GetNameOP(int op);
  };

//+------------------------------------------------------------------+
//|Получение актуальной информации по торговому инструменту          |
//+------------------------------------------------------------------+

bool CTradeManager::UpdateSymbolInfo()
  {
   SymbInfo.Name(_symbol);
   if(SymbInfo.Select() && SymbInfo.RefreshRates())
     {
      _symbol = SymbInfo.Name();
      _digits = SymbInfo.Digits();
      _point = SymbInfo.Point();
      _stopLevel = SymbInfo.StopsLevel();
      _freezeLevel = SymbInfo.FreezeLevel();
      _bid = SymbInfo.Bid();
      _ask = SymbInfo.Ask();
      _spread = SymbInfo.Spread();
      return(true);
     }
   return(false);
  }  
//+------------------------------------------------------------------+
//| Вычисляет уровень открытия в зависимости от типа                 |
//+------------------------------------------------------------------+
double CTradeManager::pricetype(int type)
  {
   UpdateSymbolInfo();
   if(type == 0)return(_ask);
   if(type == 1)return(_bid);
   return(-1);
  }
//+------------------------------------------------------------------+
//| Вычисляет уровень стоплосса в зависимости от типа                |
//+------------------------------------------------------------------+
double CTradeManager::SLtype(int type)
  {
   if(UpdateSymbolInfo())
     {
      if(type==0)return(_bid-_SL*_point);
      if(type==1)return(_ask+_SL*_point);
     }
   return(0);
  }
//+------------------------------------------------------------------+
//| Вычисляет уровень тейкпрофита в зависимости от типа              |
//+------------------------------------------------------------------+
double CTradeManager::TPtype(int type)
  {
   if(UpdateSymbolInfo())
     {
      if(type==0)return(_ask+_TP*_point);
      if(type==1)return(_bid-_TP*_point);
     }
   return(0);
  }
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTradeManager::SendOrder(ENUM_ORDER_TYPE type,double volume)
  {
   request.action = TRADE_ACTION_DEAL;      // Тип выполняемого действия
   request.magic = _magic;                  // Штамп эксперта (идентификатор magic number)
   request.symbol = _symbol;                // Имя торгового инструмента
   request.volume = volume;                 // Запрашиваемый объем сделки в лотах
   request.price = pricetype((int)type);   // Цена       
   request.sl = SLtype((int)type);      // Уровень Stop Loss ордера
   request.tp = TPtype((int)type);      // Уровень Take Profit ордера         
   request.deviation = _spread;                 // Максимально приемлемое отклонение от запрашиваемой цены
   request.type = type;                               // Тип ордера
   request.type_filling = ORDER_FILLING_FOK;
   
   ModifyPosition(request.action);
   
  }
//+------------------------------------------------------------------+ 
// Функция вычисления параметров трейлинга
//+------------------------------------------------------------------+
void CTradeManager::DoTrailing()
 {
  //--- выделение позиции, если ее удалось выделить, значит позиция существует
  if(PositionSelect(_symbol))
  {
   if(UpdateSymbolInfo())
   {
    double positionOpenPrice = PosInfo.PriceOpen();
    double positionSL = PosInfo.StopLoss();
    if (PosInfo.PositionType() == POSITION_TYPE_BUY)
    {
     if (LessDoubles(positionOpenPrice, _bid - _minProfit*_point))
     {
      if (LessDoubles(positionSL, _bid - (_trailingStop+_trailingStep-1)*_point) || positionSL == 0)
      {
       request.sl = NormalizeDouble(_bid - _trailingStop*_point, _digits);
       request.tp = PosInfo.TakeProfit();

       this.ModifyPosition(TRADE_ACTION_SLTP);
      }
     }
    }
    
    if (PosInfo.PositionType() == POSITION_TYPE_SELL)
    {
     if (GreatDoubles(positionOpenPrice - _ask, _minProfit*_point))
     {
      if (GreatDoubles(positionSL, _ask+(_trailingStop+_trailingStep-1)*_point) || positionSL == 0) 
      {
       request.sl = NormalizeDouble(_ask + _trailingStop*_point, _digits);
       request.tp = PosInfo.TakeProfit();

       this.ModifyPosition(TRADE_ACTION_SLTP);
      }
     }
    }
   }
  } 
 }; 

//+------------------------------------------------------------------+ 
// Функция модификации позиции
//+------------------------------------------------------------------+
void CTradeManager::ModifyPosition(ENUM_TRADE_REQUEST_ACTIONS trade_action)
{
//--- сбросим код последней ошибки в ноль
 ResetLastError();
 request.action = trade_action;
 bool success = false;
 int er;
  
 for (int it = 1; it <= _numberOfTry; it++) 
 {
  if (!MQL5InfoInteger(MQL5_TESTING) && (!AccountInfoInteger(ACCOUNT_TRADE_EXPERT) || IsStopped())) break;
  while (!MQL5InfoInteger(MQL5_TRADE_ALLOWED)) Sleep(5000);

//--- отправим запрос
  success = OrderSend(request,trade_result);
  if (success)
  {
   if (_useSound) PlaySound(_nameFileSound); break;
  }
  else
  {
  //--- если результат неудачный - попробуем узнать в чем дело
   er=GetLastError();
   //Print("Error(",trade_result.retcode,") modifying order: ",ErrorDescription(er),", try ",it);
   Print("Ask=",trade_result.ask,"  Bid=",trade_result.bid,"  sy=",_symbol,
             "  op="+GetNameOP(request.type),"  pp=",request.price,"  sl=",request.sl,"  tp=",request.tp);
             
   Print("TradeLog: Trade request failed. Error = ",GetLastError(),", try ",it);
   switch(trade_result.retcode)
   {
    //--- реквота
    case 10004:
    {
     Print("TRADE_RETCODE_REQUOTE");
     Print("request.price = ",request.price,"   trade_result.ask = ", trade_result.ask," trade_result.bid = ",trade_result.bid);
     break;
    }
    //--- ордер не принят сервером
    case 10006:
    {
     Print("TRADE_RETCODE_REJECT");
     Print("request.price = ",request.price,"   trade_result.ask = ", trade_result.ask," trade_result.bid = ",trade_result.bid);
     break;
    }
    //--- неправильная цена
    case 10015:
    {
     Print("TRADE_RETCODE_INVALID_PRICE");
     Print("request.price = ",request.price,"   trade_result.ask = ", trade_result.ask," trade_result.bid = ",trade_result.bid);
     break;
    }
    //--- неправильный SL и/или TP
    case 10016:
    {
     Print("TRADE_RETCODE_INVALID_STOPS");
     Print("request.sl = ",request.sl," request.tp = ",request.tp);
     Print("trade_result.ask = ",trade_result.ask," trade_result.bid = ",trade_result.bid);
     break;
    }
    //--- некорректный объем
    case 10014:
    {
     Print("TRADE_RETCODE_INVALID_VOLUME");
     Print("request.volume = ",request.volume,"   trade_result.volume = ", trade_result.volume);
     break;
    }
    //--- не хватает денег на торговую операцию  
    case 10019:
    {
     Print("TRADE_RETCODE_NO_MONEY");
     Print("request.volume = ",request.volume,"   trade_result.volume = ", trade_result.volume,"   trade_result.comment = ",trade_result.comment);
     break;
    }
    //--- какая-то другая причина, сообщим код ответа сервера   
    default:
    {
     Print("Other answer = ",trade_result.retcode);
    }
   }          
  Sleep(1000*10);
  }
 }
};

string CTradeManager::GetNameOP(int op)
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