//+------------------------------------------------------------------+
//|                                                 TrailingStop.mqh |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <TradeManager\TradeManagerEnums.mqh>
#include <ColoredTrend\ColoredTrendUtilities.mqh>
#include <CompareDoubles.mqh>
#include <StringUtilities.mqh>

//+------------------------------------------------------------------+
//| Класс для управления стоп-лоссом                                 |
//+------------------------------------------------------------------+
class CTrailingStop
  {
private:
   CSymbolInfo SymbInfo;
   bool UpdateSymbolInfo(string symbol);
   
   double PBI_colors[], PBI_Extrems[];
   
public:
   CTrailingStop();
   ~CTrailingStop();
   
   double UsualTrailing(string symbol, ENUM_TM_POSITION_TYPE type, double openPrice, double sl
                       , int _minProfit, int _trailingStop, int _trailingStep);
                       
   double LosslessTrailing(string symbol, ENUM_TM_POSITION_TYPE type, double openPrice, double sl
                       , int _minProfit, int _trailingStop, int _trailingStep);
   double PBITrailing(string symbol, ENUM_TIMEFRAMES timeframe, ENUM_TM_POSITION_TYPE type, double sl, int handle_PBI);                    
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CTrailingStop::CTrailingStop()
  {
   ArraySetAsSeries(PBI_colors, true);
   ArraySetAsSeries(PBI_Extrems, true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CTrailingStop::~CTrailingStop()
  {
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
// Обычный трейлинг
//+------------------------------------------------------------------+
double CTrailingStop::UsualTrailing(string symbol, ENUM_TM_POSITION_TYPE type, double openPrice, double sl
                                   , int minProfit, int trailingStop, int trailingStep)
{
 double newSL = 0;
 if (minProfit > 0 && trailingStop > 0 && trailingStep > 0)
 {
  UpdateSymbolInfo(symbol);
  double ask = SymbInfo.Ask();
  double bid = SymbInfo.Bid();
  double point = SymbInfo.Point();
  int digits = SymbInfo.Digits();
 
  if (type == OP_BUY &&
      LessDoubles(openPrice, bid - minProfit*point) &&
      (LessDoubles(sl, bid - (trailingStop+trailingStep-1)*point) || sl == 0))
  {
   Print("UsualTrailing");
   newSL = NormalizeDouble(bid - trailingStop*point, digits);
  }
 
  if (type == OP_SELL &&
      GreatDoubles(openPrice, ask + minProfit*point) &&
      (GreatDoubles(sl, ask + (trailingStop+trailingStep-1)*point) || sl == 0))
  {
   Print("UsualTrailing");
   newSL = NormalizeDouble(ask + trailingStop*point, digits);
  }
 }
 return (newSL);
}

//+------------------------------------------------------------------+
// Трейлинг с выходом на безубыток
//+------------------------------------------------------------------+
double CTrailingStop::LosslessTrailing(string symbol, ENUM_TM_POSITION_TYPE type, double openPrice, double sl
                       , int minProfit, int trailingStop, int trailingStep)
{
 double newSL = 0;
 if (minProfit > 0 && trailingStop > 0 && trailingStep > 0)
 {
  UpdateSymbolInfo(symbol);
  double price;
  int direction;
  if (type == OP_BUY)
  {
   price = SymbInfo.Bid();
   direction = -1;
  }
  else if (type == OP_SELL)
       {
        price = SymbInfo.Ask();
        direction = 1; 
       }
       else return true;
  
  double point = SymbInfo.Point();
  int digits = SymbInfo.Digits();
 
  if (GreatDoubles(direction*openPrice, direction*price + minProfit*point)) // Если достигнут минпрофит 
  {
   newSL = openPrice*point;                                                  // переносим СЛ в безубыток 
  }
  if (GreatDoubles(direction*openPrice, direction*price + minProfit*point)
     && GreatDoubles(direction*sl, direction*price + (trailingStop+trailingStep-1)*point) || sl == 0)
  {
   newSL = NormalizeDouble(price + direction*trailingStop*point, digits);
  }
 }
 return (newSL);
}

//+------------------------------------------------------------------+
// Трейлинг по индикатору PBI
//+------------------------------------------------------------------+
double CTrailingStop::PBITrailing(string symbol, ENUM_TIMEFRAMES timeframe, ENUM_TM_POSITION_TYPE type, double sl, int handle_PBI)
{
 int errcolors = CopyBuffer(handle_PBI, 4, 0, 100, PBI_colors);
 int errextrems, direction;
 if (type == OP_SELL)
 {
  //Print("PBI_Trailing, позиция СЕЛЛ, тип движения ", PBI_colors[0]);
  errextrems = CopyBuffer(handle_PBI, 5, 0, 100, PBI_Extrems); // Копируем максимумы
  direction = 1;
 }
 if (type == OP_BUY)
 {
  //Print("PBI_Trailing, позиция БАЙ, тип движения ", PBI_colors[0]);
  errextrems = CopyBuffer(handle_PBI, 6, 0, 1000, PBI_Extrems); // Копируем минимумы
  direction = -1;
 }
 if(errcolors < 0 || errextrems < 0)
 {
  Alert("Не удалось скопировать данные из индикаторного буфера"); 
  return(0.0); 
 }

 double newExtr = 0;
 if (PBI_colors[0] == 1 || PBI_colors[0] == 2 || PBI_colors[0] == 3 || PBI_colors[0] == 4)
 {
  //Print("Текущее движение ", MoveTypeToString((ENUM_MOVE_TYPE)PBI_colors[0]));
  for (int index = 0; index < 1000; index++)
  { 
   if (PBI_Extrems[index] > 0)
   {
    if (PBI_colors[index] == 5 || PBI_colors[index] == 6 || PBI_colors[index] == 7)
    {
     newExtr = PBI_Extrems[index];
     //Print("последний экстремум ", newExtr);
     break;
    } 
   }
  }
 }
 
 if (newExtr > 0 && GreatDoubles(direction * sl, direction * newExtr, 5))
 {
  PrintFormat("%s oldSL = %.05f, newSL = %.05f", MakeFunctionPrefix(__FUNCTION__), sl, newExtr);
  return (newExtr);
 }
 return(0.0);
};
//+------------------------------------------------------------------+
//|Получение актуальной информации по торговому инструменту          |
//+------------------------------------------------------------------+
bool CTrailingStop::UpdateSymbolInfo(string symbol)
{
 SymbInfo.Name(symbol);
 if(SymbInfo.Select() && SymbInfo.RefreshRates())
 {
  return(true);
 }
 return(false);
}