//+------------------------------------------------------------------+
//|                                                        Brain.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#include <Constants.mqh>
#include <StringUtilities.mqh>               // строковое преобразование
#include <CLog.mqh>                          // для лога
#include <Object.mqh>
#include <ContainerBuffers.mqh>       // контейнер буферов цен на всех ТФ (No PBI) - для запуска в ТС
#include <CompareDoubles.mqh>               // сравнение вещественных чисел

class CBrain : public CObject
{
protected:
 //string          _symbol;
 //int             _magic;
 //int             _current_direction;
 
 
public:

virtual int  GetSignal()     { PrintFormat("%s попал на CBrain, а не должен был", MakeFunctionPrefix(__FUNCTION__));return 3;}
virtual int  GetMagic()      { PrintFormat("%s попал на CBrain, а не должен был", MakeFunctionPrefix(__FUNCTION__));return 3;}
virtual int  GetDirection()  { PrintFormat("%s попал на CBrain, а не должен был", MakeFunctionPrefix(__FUNCTION__));return 3;}
virtual void ResetDirection(){ PrintFormat("%s попал на CBrain, а не должен был", MakeFunctionPrefix(__FUNCTION__));return;}

virtual ENUM_TIMEFRAMES GetPeriod() { PrintFormat("%s попал на CBrain, а не должен был", MakeFunctionPrefix(__FUNCTION__));return 3;}

//---------------или посылать нулевые значения---------------
//virtual int GetSL();

//virtual ENUM_TIMEFRAMES GetPeriod() {return _period;}
                    
};
