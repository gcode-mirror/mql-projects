//+------------------------------------------------------------------+
//|                                                  CExtremumNew.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#include <Object.mqh>

enum STATE_OF_EXTR
{
 EXTR_FORMING = 0,
 EXTR_FORMED,
 EXTR_NO_TYPE        //не ясно нужно ли отсавлять
};

class CExtremum : public CObject
{
 private:

 public:
 int direction;                      // направление экстремума: 1 - max; -1 -min; 0 - null
 double price;                       // цена экстремума: для max - high; для min - low
 datetime time;                      // время бара на котором возникает экстремум
 STATE_OF_EXTR state;                // статус экстремума типа перечислений STATE_OF_EXTR (форимирующийся/сформированный)
                     CExtremum();
                     CExtremum(int direction, double price, datetime time = 0, STATE_OF_EXTR state = EXTR_NO_TYPE);
                    ~CExtremum();
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CExtremum::CExtremum()
{
}
CExtremum::CExtremum(int _direction, double _price, datetime _time = 0, STATE_OF_EXTR _state = EXTR_NO_TYPE)
{
 direction = _direction;
 price     = _price;
 time      = _time;
 state     = _state;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CExtremum::~CExtremum()
{
}
//+------------------------------------------------------------------+
