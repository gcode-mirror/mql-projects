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
//| Класс работает на М1, М5, М15. Для добавления новых периодов необходимо внести изменения в код функциий:   |
//|                       //-GetBottom()                                                                       |
//+------------------------------------------------------------------------------------------------------------+
class CTimeFrame: public CObject
{
 private:
   string _symbol;
   ENUM_TIMEFRAMES _period;
   CisNewBar *_isNewBar;   //ContainerBuffer
   int   _handleATR;
   int   _handleDE;
   bool  _isTrendNow; //не факт что понадобится. Заменено на _trend.IsTrendNow();
   int   _signalTrade;
   double   _supremacyPercent;
 public: 
   //конструктор
   CTimeFrame(ENUM_TIMEFRAMES period, string symbol, 
                           int handleATR, int   handleDE);
   ~CTimeFrame();
   //функции для работы с классом CTimeFrame
   ENUM_TIMEFRAMES GetPeriod()   {return _period;}
   bool            IsThisNewBar(){return _isNewBar.isNewBar();}
   bool            IsThisTrendNow(){return _isTrendNow;}
   int             GetHandleATR(){return _handleATR;}
   int             GetHandleDE() {return _handleDE;}
   int             GetSignal()   {return _signalTrade;}
   double          GetRatio()    {return _supremacyPercent;}
   void            SetRatio(double prc){_supremacyPercent = prc;} 
   void            SetSignal(int signalTrade)     {_signalTrade = signalTrade;}
   void            SetTrendNow(bool isTrendNow) {_isTrendNow = isTrendNow;}
  // bool            isTrendNow()  {return _trend.IsTrendNow();}
};


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CTimeFrame::CTimeFrame(ENUM_TIMEFRAMES period, string symbol, 
                           int handleATR, int   handleDE)
{
 _symbol = symbol;
 _period = period;
 _isNewBar = new CisNewBar(symbol,period);
 _handleATR = handleATR;
 _handleDE = handleDE;
 //  что с ним? _isTrendNow = fal;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CTimeFrame::~CTimeFrame()
  {
  }
//+------------------------------------------------------------------+
