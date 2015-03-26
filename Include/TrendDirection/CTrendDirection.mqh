//+------------------------------------------------------------------+
//|                                              CTrendDirection.mqh |
//|                                       Copyright © 2012,   Ilya G |
//+------------------------------------------------------------------+
#property copyright "2012,   Ilya G"
#property link      "poch@ty.net"
#property version   "1.00"

#include <CompareDoubles.mqh>
#include <TitsOnMACD.mqh>
//+------------------------------------------------------------------+
//|  Класс определяющий текущее направление тренда по 2м EMA         |
//+------------------------------------------------------------------+  
class CTrendDirection
 {
public: 
  void CTrendDirection(string symbol
                      , ENUM_TIMEFRAMES timeframe
                      , double MACD_channel
                      , int fastMACDPeriod
                      , int slowMACDPeriod
                      , int fastEMA
                      , int slowEMA
                      , int deltaEMAtoEMA); // конструктор с параметрами
  int OneTitTrendCriteria(); 
  int TwoTitsTrendCriteria();
                          
  void SetCurrentTrendDirection(int curDir) {_trendDirection[0] = curDir;}                       
  void SetLastTrendDirection(int lastDir) {_trendDirection[1] = lastDir;}                   
  int GetCurrentTrendDirection() {return _trendDirection[0];}
  int GetLastTrendDirection() {return _trendDirection[1];}
  
protected:

private:
 string _symbol;
 ENUM_TIMEFRAMES _timeframe;
 double _MACD_channel;
 int _fastMACDPeriod, _slowMACDPeriod, _fastEMA, _slowEMA;
 int _deltaEMAtoEMA;
 int _trendDirection[2]; // направление тренда 0- нынешнее, 1- предыдущее
 int handleMACD, handleFastMA, handleSlowMA;
 
 bool InitTrendDirection();
 };

//-----------------------------------------------------
// Конструктор
//-----------------------------------------------------  
void CTrendDirection::CTrendDirection(string symbol
                                     , ENUM_TIMEFRAMES timeframe
                                     , double MACD_channel
                                     , int fastMACDPeriod
                                     , int slowMACDPeriod
                                     , int fastEMA
                                     , int slowEMA
                                     , int deltaEMAtoEMA)
 {
  handleMACD = iMACD(symbol, timeframe, fastMACDPeriod, slowMACDPeriod, 9, PRICE_CLOSE);
  handleFastMA = iMA(symbol, timeframe, fastEMA, 0, MODE_EMA, PRICE_CLOSE);
  handleSlowMA = iMA(symbol, timeframe, slowEMA, 0, MODE_EMA, PRICE_CLOSE);
  _MACD_channel = MACD_channel;
  _fastMACDPeriod = fastMACDPeriod;
  _slowMACDPeriod = slowMACDPeriod;
  _fastEMA = fastEMA;
  _slowEMA = slowEMA;
  _deltaEMAtoEMA = deltaEMAtoEMA;
 };  
//+------------------------------------------------------------------+ 

//-----------------------------------------------------
// Инициализация направления тренда
//-----------------------------------------------------
bool CTrendDirection::InitTrendDirection()
{
  int i = 0;
  int depth = 200;
  bool isTrendDefined = false;
  double MACD[], fastMA[], slowMA[];
  ArraySetAsSeries(MACD, true);
  ArraySetAsSeries(fastMA, true);
  ArraySetAsSeries(slowMA, true);
  CopyBuffer(handleMACD, 0, 0, depth, MACD);
  CopyBuffer(handleFastMA, 0, 0, depth, fastMA);
  CopyBuffer(handleSlowMA, 0, 0, depth, slowMA);
  
  while (!isTrendDefined && i < depth)
  {
   while((_MACD_channel > MACD[i]
         && MACD[i] > -_MACD_channel) && i < depth)
   {
    i++;
   }
   if (LessDoubles(fastMA[i],(slowMA[i] - _deltaEMAtoEMA*_Point)))
   {
    _trendDirection[1] = -1;
    isTrendDefined = true;
   }
   
   if (GreatDoubles(fastMA[i],(slowMA[i] + _deltaEMAtoEMA*_Point)))
   {
    _trendDirection[1] = 1;
    isTrendDefined = true;
   }
   i++;
  }
 
  if (i >= depth)
  {
   Alert("ВНИМАНИЕ!!! Задан слишком широкий коридор MACD, начальное направление тренда не определено! Возможна некорректная работа эксперта!");
  }
  return(isTrendDefined);
} 

//-----------------------------------------------------
// Критерий тренда при одном изгибе MACD
//-----------------------------------------------------
int CTrendDirection::OneTitTrendCriteria()
{
  double MACD[], fastMA[], slowMA[];
  ArraySetAsSeries(MACD, true);
  ArraySetAsSeries(fastMA, true);
  ArraySetAsSeries(slowMA, true);
  CopyBuffer(handleMACD, 0, 0, 1, MACD);
  CopyBuffer(handleFastMA, 0, 0, 1, fastMA);
  CopyBuffer(handleSlowMA, 0, 0, 1, slowMA);
  
  if (-_MACD_channel < MACD[0] && MACD[0] < _MACD_channel)
  {  // Слабый MACD
   if (searchForTits(_timeframe, _MACD_channel, false))
   {
    return (0);
   } // Close  searchForTits
    return (_trendDirection[1]);
  }
  
  if (LessDoubles(fastMA[0],(slowMA[0] - _deltaEMAtoEMA*_Point)))
  {
	return (-1);   
  }
    
  if (GreatDoubles(fastMA[0], (slowMA[0] + _deltaEMAtoEMA*_Point)))
  {
   return (1);
  }

  return (0); // Нет тренда
}

//-----------------------------------------------------
// Критерий тренда при двух изгибах MACD
//-----------------------------------------------------
int CTrendDirection::TwoTitsTrendCriteria()
{
  double MACD[], fastMA[], slowMA[];
  ArraySetAsSeries(MACD, true);
  ArraySetAsSeries(fastMA, true);
  ArraySetAsSeries(slowMA, true);
  CopyBuffer(handleMACD, 0, 0, 1, MACD);
  CopyBuffer(handleFastMA, 0, 0, 1, fastMA);
  CopyBuffer(handleSlowMA, 0, 0, 1, slowMA);
  
  if (-_MACD_channel <= MACD[0] && MACD[0] <= _MACD_channel)
  {  // Слабый MACD
   if (isMACDExtremum(handleMACD) != 0)
   {
    if (searchForTits(_timeframe, _MACD_channel, true))
    {
     return (0);
    } // Close  searchForTits
   }
   return (_trendDirection[0]);
  }
  
  if (LessDoubles(fastMA[0],(slowMA[0] - _deltaEMAtoEMA*_Point)))
  {
   // медленный ЕМА выше быстрого - тренд вниз
	return (-1);   
  }
  else if (GreatDoubles(fastMA[0], (slowMA[0] + _deltaEMAtoEMA*_Point)))
       {
       // медленный ЕМА ниже быстрого - тренд вверх
        return (1);
       }
       else
       {
        // MACD большой, но ЕМА близко, живем по последнему тренду
        return (_trendDirection[1]);
       }
  
  Alert("ВНИМАНИЕ !!! нет тренда!!!");
  return (0); // Нет тренда
}