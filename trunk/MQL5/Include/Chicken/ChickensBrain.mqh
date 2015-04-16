//+------------------------------------------------------------------+
//|                                               CChickensBrain.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <ColoredTrend/ColoredTrendUtilities.mqh>
#include <Lib CisNewBarDD.mqh>
#include <TradeManager\TradeManager.mqh>   //–ади одной структуры, стоит ли?

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
  CisNewBar *isNewBar;
  int  tmpLastBar;
  int  lastTrend;            // тип последнего тренда по PBI 
  double buffer_pbi[];
  double buffer_high[];
  double buffer_low[];
  double highPrice[], lowPrice[], closePrice[];
  bool _use_tp;
 public:
  int diff_high; 
  int diff_low; 
  int tp;
  double highBorder; 
  double lowBorder;
  double stoplevel;
  double priceDifference;
  int index_max;
  int index_min;
  bool recountInterval;
                     CChickensBrain(string symbol, ENUM_TIMEFRAMES period, int handle_pbi, bool use_tp);
                    ~CChickensBrain();
                   int GetSignal();  //pos_info.tp = 0?
                   int GetLastMoveType (int handle);
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CChickensBrain::CChickensBrain(string symbol, ENUM_TIMEFRAMES period, int handle_pbi, bool use_tp)
{
 _symbol = symbol;
 _period = period;
 _handle_pbi = handle_pbi;
 _use_tp = use_tp; 
 index_max = -1;
 index_min = -1;
 isNewBar = new CisNewBar(_symbol, _period);
 lastTrend = 0; 
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
 int sl_min;
 double stoplevel;
 static int index_max = -1;
 static int index_min = -1;
 if(isNewBar.isNewBar() || recountInterval)
 {
  ArraySetAsSeries(buffer_high, false);
  ArraySetAsSeries(buffer_low, false);
  if(CopyClose(_Symbol, _period, 1, 1, closePrice)     < 1 ||      // цена закрыти€ последнего сформированного бара
     CopyHigh(_Symbol, _period, 1, DEPTH, buffer_high) < DEPTH ||  // буфер максимальных цен всех сформированных баров на заданую глубину
     CopyLow(_Symbol, _period, 1, DEPTH, buffer_low)   < DEPTH ||  // буфер минимальных цен всех сформированных баров на заданую глубину
     CopyBuffer(_handle_pbi, 4, 0, 1, buffer_pbi)       < 1)        // последнее полученное движение
  {
   index_max = -1;
   index_min = -1;  // если не получилось посчитать максимумы не будем открывать сделок
   recountInterval = true;
  }
  index_max = ArrayMaximum(buffer_high, 0, DEPTH - 1);
  index_min = ArrayMinimum(buffer_low, 0, DEPTH - 1);
  recountInterval = false;
  
  tmpLastBar = GetLastMoveType(_handle_pbi);
  if (tmpLastBar != 0)
  {
   lastTrend = tmpLastBar;
  }
  
  if (buffer_pbi[0] == MOVE_TYPE_FLAT && index_max != -1 && index_min != -1)
  {
   highBorder = buffer_high[index_max];
   lowBorder = buffer_low[index_min];
   sl_min = MathMax((int)MathCeil((highBorder - lowBorder) * 0.10 / Point()), 50);
   tp = (_use_tp) ? (int)MathCeil((highBorder - lowBorder)*0.75/Point()) : 0;
   diff_high = (buffer_high[DEPTH - 1] - highBorder)/Point();
   diff_low = (lowBorder - buffer_low[DEPTH - 1])/Point();
   
   stoplevel = MathMax(sl_min, SymbolInfoInteger(_symbol, SYMBOL_TRADE_STOPS_LEVEL))*Point();
   if(index_max < ALLOW_INTERVAL && GreatDoubles(closePrice[0], highBorder) && diff_high > sl_min && lastTrend == SELL)
   { 
    PrintFormat("÷ена закрыти€ пробила цену максимум = %s, ¬рем€ = %s, цена = %.05f, sl_min = %d, diff_high = %d",
          DoubleToString(highBorder, 5),
          TimeToString(TimeCurrent()),
          closePrice[0],
          sl_min, diff_high);
    priceDifference = (closePrice[0] - highBorder)/Point();
    return SELL;
   }
    
   if(index_min < ALLOW_INTERVAL && LessDoubles(closePrice[0], lowBorder) && diff_low > sl_min && lastTrend == BUY)
   {
    PrintFormat("÷ена закрыти€ пробила цену минимум = %s, ¬рем€ = %s, цена = %.05f, sl_min = %d, diff_low = %d",
          DoubleToString(lowBorder, 5),
          TimeToString(TimeCurrent()),
          closePrice[0],
          sl_min, diff_low);
    priceDifference = (lowBorder - closePrice[0])/Point();
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
