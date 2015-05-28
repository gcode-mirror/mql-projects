//+------------------------------------------------------------------+
//|                                                    TimeFrame.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <Lib CisNewBarDD.mqh>
//+------------------------------------------------------------------------------------------------------------+
//|                           Класс TimeFrame содержит информацию, которую можно отнести к конкретному ТФ      |
//| Класс реализует работу с хэндлами, уникальными для ТФ (ATR, DE и др.), хранит состояние переменной isNewBar|
//| Класс работает на М1, М5, М15.                                                                                |
//+------------------------------------------------------------------------------------------------------------+
class CTimeframeInfo: public CObject
{
 private:
   string _symbol;
   ENUM_TIMEFRAMES _period;
   CisNewBar *_isNewBar;   //ContainerBuffer
   int   _handleATR;
   bool  _isTrendNow; //не факт что понадобится. Заменено на _trend.IsTrendNow();
   double _supremacyPercent;
 public: 
   //конструктор
   CTimeframeInfo(ENUM_TIMEFRAMES period, string symbol, 
                           int handleATR);
   ~CTimeframeInfo();
   //функции для работы с классом CTimeframeInfo
   ENUM_TIMEFRAMES GetPeriod()   {return _period;}
   bool            IsThisNewBar(){return _isNewBar.isNewBar();}
   bool            IsThisTrendNow(){return _isTrendNow;}
   int             GetHandleATR(){return _handleATR;}
   double          GetRatio()    {return _supremacyPercent;}
   void            SetRatio(double prc){_supremacyPercent = prc;} 
   void            SetTrendNow(bool isTrendNow) {_isTrendNow = isTrendNow;}

};


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CTimeframeInfo::CTimeframeInfo(ENUM_TIMEFRAMES period, string symbol, 
                           int handleATR)
{
 _symbol = symbol;
 _period = period;
 _isNewBar = new CisNewBar(symbol,period);
 _handleATR = handleATR;
 //  что с ним? _isTrendNow = fal;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CTimeframeInfo::~CTimeframeInfo()
  {
  }
//+------------------------------------------------------------------+
