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
#include <ContainerBuffers.mqh>              // контейнер буферов цен на всех ТФ (No PBI) - для запуска в ТС
#include <CompareDoubles.mqh>                // сравнение вещественных чисел
#include <TradeManager/TradeManager.mqh>     // торговая библиотека
class CBrain : public CObject
{
protected:
 //string          _symbol;
 //int             _magic;
 //int             _current_direction;
 
 
public:

virtual ENUM_TM_POSITION_TYPE  GetSignal()     { PrintFormat("%s попал на CBrain, а не должен был", MakeFunctionPrefix(__FUNCTION__));return 2;}
virtual long  GetMagic()                       { PrintFormat("%s попал на CBrain, а не должен был", MakeFunctionPrefix(__FUNCTION__));return 2;}
virtual ENUM_SIGNAL_FOR_TRADE    GetDirection(){ PrintFormat("%s попал на CBrain, а не должен был", MakeFunctionPrefix(__FUNCTION__));return 2;}
virtual int  CountTakeProfit()        { PrintFormat("%s попал на CBrain, а не должен был", MakeFunctionPrefix(__FUNCTION__));return 0;}
virtual int  CountStopLoss()          { PrintFormat("%s попал на CBrain, а не должен был", MakeFunctionPrefix(__FUNCTION__));return 0;}
virtual int  GetPriceDifference()   { PrintFormat("%s попал на CBrain, а не должен был", MakeFunctionPrefix(__FUNCTION__));return 0;}
virtual int  GetExpiration()        { PrintFormat("%s попал на CBrain, а не должен был", MakeFunctionPrefix(__FUNCTION__));return 0;}
virtual ENUM_TIMEFRAMES GetPeriod() { PrintFormat("%s попал на CBrain, а не должен был", MakeFunctionPrefix(__FUNCTION__));return 2;}
virtual string GetName()            { PrintFormat("%s попал на CBrain, а не должен был", MakeFunctionPrefix(__FUNCTION__));return "Brain";}
//---------------или посылать нулевые значения---------------
//virtual int GetSL();

//virtual ENUM_TIMEFRAMES GetPeriod() {return _period;}
                    
};
