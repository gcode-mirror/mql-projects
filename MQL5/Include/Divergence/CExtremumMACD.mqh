//+------------------------------------------------------------------+
//|                                                CExtremumMACD.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <Object.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CExtremumMACD : public CObject
{
private:
 datetime _time;                      // НУЖНО ЛИ? время бара на котором возникает экстремум

public:
 CExtremumMACD(){};
 ~CExtremumMACD(){};
 CExtremumMACD(int direction, int index, double value);
                     
 int direction;                      // направление экстремума: 1 - max; -1 -min; 0 - null
 double value;                       // значение экстремума: для max - high; для min - low
 int index;                          // Индекс экстремума относительно заданного диапазона
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CExtremumMACD::CExtremumMACD(int direction, int index, double value): direction(direction), index(index), value(value)
  {
  }
