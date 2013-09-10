//+------------------------------------------------------------------+
//|                                         CHistoryTradeManager.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#include <CLog.mqh>

#define INITIAL_BALANCE 10000

enum ENUM_HTM_POSITION_TYPE
{
 EMPTY,
 BUY,
 SELL
};

struct virtual_position
{
 ENUM_HTM_POSITION_TYPE type;// направление виртуальной позиции (0-нет открытой позиции,+1 покупка,-1 продажа)
 //double   volume;            // объем позиции в лотах
 //double   profit;            // текущая прибыль открытой виртуальной позиции в пунктах
 //datetime time_open;         // дата и время открытия виртуальной позиции
 //datetime time_close;        // дата и время закрытия виртуальной позиции
 double   price;             // цена виртуальной позиции
};

class CHistoryTradeManager
{
 private:
 bool _is_position;              //флаг наличия открытой позиции
 virtual_position _position;     //виртуальная позиция
 
 double _balance;                //баланс счета
 MqlRates _rates[];              //массив котировок
 
 double _profit;                 //переменная для сбора статистических данных : профит на текущий момент
 int _count_order;               //переменная для сбора статистических данных : счетчик сделок
 
 public:
 CHistoryTradeManager(string symbol, ENUM_TIMEFRAMES tf, int depth);
~CHistoryTradeManager(); 
 void   UpdateInfo();
 void   OpenPosition(ENUM_HTM_POSITION_TYPE type, int index); 
 bool   ClosePosition(int index);
 int    GetCountOrder() { return(_count_order); }
 double GetProfit()     { return(_profit); }
 double GetBalance()    { return(_balance); }
};

CHistoryTradeManager::CHistoryTradeManager(string symbol, ENUM_TIMEFRAMES tf, int depth):
                      _balance (INITIAL_BALANCE),
                      _profit (0),
                      _count_order (0)
{
 ArrayResize(_rates, depth);
 ArraySetAsSeries(_rates, true);
 int copiedRates = -1;
 for(int attempts = 0; attempts < 25 && copiedRates < 0; attempts++)
 {
  copiedRates = CopyRates(symbol, tf, 0, depth, _rates);
 }
 if(copiedRates != depth)
 {
  Alert("Не удалось скопировать массив котировок.");
  return;
 }
 log_file.Write (LOG_DEBUG, StringFormat("%s Инициализация", __FUNCTION__));
}

CHistoryTradeManager::~CHistoryTradeManager(void)
{
 ArrayFree(_rates);
 log_file.Write (LOG_DEBUG, StringFormat("%s Деинициализация", __FUNCTION__));
}

void CHistoryTradeManager::UpdateInfo()
{
 //?
}

void CHistoryTradeManager::OpenPosition(ENUM_HTM_POSITION_TYPE type, int index)
{
 if(_is_position) 
 {// если есть открытая позиция противоположная открываемой - закрываем
  switch(type)
  {
   case BUY:
    if(_position.type == SELL)
    {
     ClosePosition (index);
    }
    break;
   case SELL:
    if(_position.type == BUY)
    {
     ClosePosition (index);
    }
    break;
  }
 }
 //открытие самой позиции
 _is_position = true;
 _position.type  = type;
 _position.price = _rates[index].close;
 _balance -= _position.price;
 _count_order++;
 log_file.Write (LOG_DEBUG, StringFormat("%s Открыли позицию типа %s. Текущий баланс %f", __FUNCTION__, EnumToString((ENUM_HTM_POSITION_TYPE)type), _balance));
}

bool CHistoryTradeManager::ClosePosition(int index)
{
 if (_is_position)
 {
  _is_position = false;
  _balance += _rates[index].close;
  _profit = _balance - INITIAL_BALANCE;
  log_file.Write (LOG_DEBUG, StringFormat("%s Закрыди позицию типа %s. Текущий баланс %f. Текущий профит %f.", 
                                          __FUNCTION__, EnumToString((ENUM_HTM_POSITION_TYPE)_position.type), _balance, _profit));
  _position.type = EMPTY;
  _position.price = 0;
  return true;
 }
 return false;
}