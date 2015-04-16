//+------------------------------------------------------------------+
//|                                               CChickensBrain.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              ht_tp://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "ht_tp://www.mql5.com"
#property version   "1.00"

#include <ColoredTrend/ColoredTrendUtilities.mqh>
#include <Lib CisNewBarDD.mqh>
#include <TradeManager\TradeManager.mqh>   //Ради одной структуры, стоит ли?

#define DEPTH 20
#define ALLOW_INTERVAL 16
// константы сигналов
#define BUY   1    
#define SELL -1 
#define NO_POSITION 0
#define NO_ENTER 2
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CChickensBrain
{
 private:
  string _symbol;
  ENUM_TIMEFRAMES _period;
  int _handle_pbi; 
  int _tmpLastBar;
  int _lastTrend;            // тип последнего тренда по PBI 
  double buffer_pbi[];
  double buffer_high[];
  double buffer_low[];
  double highPrice[], lowPrice[], closePrice[];
 
  bool recountInterval;
  CisNewBar *isNewBar;
  // поля, доступ к которым реализован через функции Get...()
  int _index_max;
  int _index_min;
  int _diff_high; 
  int _diff_low; 
  int _tp;
  int _sl_min;
  double _highBorder; 
  double _lowBorder;
  double _stoplevel;
  double _priceDifference;
  
 public:
  
                     CChickensBrain(string symbol, ENUM_TIMEFRAMES period);
                    ~CChickensBrain();
                   int GetSignal();  //pos_info._tp = 0?
                   int GetLastMoveType (int handle);
                   int GetIndexMax()      { return _index_max;}
                   int GetIndexMin()      { return _index_min;}
                   int GetDiffHigh()      { return _diff_high;}
                   int GetDiffLow()       { return _diff_low;}
                   int GetTP()            { return _tp;}
                   int GetSLmin()         { return _sl_min;}
                   double GetHighBorder() { return _highBorder;}
                   double GetLowBorder()  { return _lowBorder;}
                   double GetPriceDifference(){ return _priceDifference;}
                   
                   
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CChickensBrain::CChickensBrain(string symbol, ENUM_TIMEFRAMES period)
{
 _symbol = symbol;
 _period = period;
 _handle_pbi = iCustom(_Symbol, _Period, "PriceBasedIndicator");
 if (_handle_pbi == INVALID_HANDLE)
 {
  Print("Не удалось создать хэндл индикатора PriceBasedIndicator");
 }
 _index_max = -1;
 _index_min = -1;
 isNewBar = new CisNewBar(_symbol, _period);
 _lastTrend = 0; 
 recountInterval = false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CChickensBrain::~CChickensBrain()
{
}
//+------------------------------------------------------------------+
int CChickensBrain::GetSignal()
{
 double _stoplevel;
 static int _index_max = -1;
 static int _index_min = -1;
 if(isNewBar.isNewBar() || recountInterval)
 {
  ArraySetAsSeries(buffer_high, false);
  ArraySetAsSeries(buffer_low, false);
  if(CopyClose(_Symbol, _period, 1, 1, closePrice)     < 1 ||      // цена закрытия последнего сформированного бара
     CopyHigh(_Symbol, _period, 1, DEPTH, buffer_high) < DEPTH ||  // буфер максимальных цен всех сформированных баров на заданую глубину
     CopyLow(_Symbol, _period, 1, DEPTH, buffer_low)   < DEPTH ||  // буфер минимальных цен всех сформированных баров на заданую глубину
     CopyBuffer(_handle_pbi, 4, 0, 1, buffer_pbi)       < 1)        // последнее полученное движение
  {
   _index_max = -1;
   _index_min = -1;  // если не получилось посчитать максимумы не будем открывать сделок
   recountInterval = true;
  }
  _index_max = ArrayMaximum(buffer_high, 0, DEPTH - 1);
  _index_min = ArrayMinimum(buffer_low, 0, DEPTH - 1);
  recountInterval = false;
  
  _tmpLastBar = GetLastMoveType(_handle_pbi);
  if (_tmpLastBar != 0)
  {
   _lastTrend = _tmpLastBar;
  }
  if (buffer_pbi[0] == MOVE_TYPE_FLAT && _index_max != -1 && _index_min != -1)
  {
   _highBorder = buffer_high[_index_max];
   _lowBorder = buffer_low[_index_min];
   _sl_min = MathMax((int)MathCeil((_highBorder - _lowBorder)*0.10/Point()), 50);
   _diff_high = (buffer_high[DEPTH - 1] - _highBorder)/Point();
   _diff_low = (_lowBorder - buffer_low[DEPTH - 1])/Point();
  
   if(_index_max < ALLOW_INTERVAL && GreatDoubles(closePrice[0], _highBorder) && _diff_high > _sl_min && _lastTrend == SELL)
   { 
    PrintFormat("Цена закрытия пробила цену максимум = %s, Время = %s, цена = %.05f, _sl_min = %d, _diff_high = %d",
          DoubleToString(_highBorder, 5),
          TimeToString(TimeCurrent()),
          closePrice[0],
          _sl_min, _diff_high);
    _priceDifference = (closePrice[0] - _highBorder)/Point();
    return SELL;
   }
    
   if(_index_min < ALLOW_INTERVAL && LessDoubles(closePrice[0], _lowBorder) && _diff_low > _sl_min && _lastTrend == BUY)
   {
    PrintFormat("Цена закрытия пробила цену минимум = %s, Время = %s, цена = %.05f, _sl_min = %d, _diff_low = %d",
          DoubleToString(_lowBorder, 5),
          TimeToString(TimeCurrent()),
          closePrice[0],
          _sl_min, _diff_low);
    _priceDifference = (_lowBorder - closePrice[0])/Point();
    return BUY;
   }
  } 
  else
   return NO_POSITION;
 } 
 return NO_ENTER;
}

int  CChickensBrain::GetLastMoveType (int handle) // получаем последнее значение PriceBasedIndicator
{
 int copiedPBI;
 int signTrend;
 copiedPBI = CopyBuffer(handle, 4, 1, 1, buffer_pbi);
 if (copiedPBI < 1)
  return (0);
 signTrend = int(buffer_pbi[0]);
  // если тренд вверх
 if (signTrend == 1 || signTrend == 2)
  return (1);
 // если тренд вниз
 if (signTrend == 3 || signTrend == 4)
  return (-1);
 return (0);
}
