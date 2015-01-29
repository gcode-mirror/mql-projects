//+------------------------------------------------------------------+
//|                                                    SExtremum.mqh |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| основная структура для хранения экстремумов                      |
//+------------------------------------------------------------------+

struct SExtremum
{
 int direction;                      // направление экстремума: 1 - max; -1 -min; 0 - null
 double price;                       // цена экстремума: для max - high; для min - low
 datetime time;                      // время бара на котором возникает экстремум
}; 