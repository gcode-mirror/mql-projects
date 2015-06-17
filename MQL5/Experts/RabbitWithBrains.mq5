//+------------------------------------------------------------------+
//|                                             RabbitWithBrains.mq5 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

//подключение необходимых библиотек

#include <ColoredTrend/ColoredTrendUtilities.mqh> 
#include <CTrendChannel.mqh> // трендовый контейнер
#include <Rabbit/RabbitsBrain.mqh>

//константы
#define KO 3            //коэффициент дл€ услови€ открыти€ позиции, во сколько как минимум вычисленный тейк профит должен превышать вычисленный стоп лосс
#define SPREAD 30       // размер спреда 

// ---------переменные робота------------------
CContainerBuffers *conbuf; // буфер контейнеров на различных “ф, заполн€емый на OnTick()
                           // highPrice[], lowPrice[], closePrice[] и т.д; 
CRabbitsBrain *rabbit;
CTradeManager *ctm;        // торговый класс 
     
datetime history_start;    // врем€ дл€ получени€ торговой истории                           

ENUM_TIMEFRAMES TFs[3] = {PERIOD_M1, PERIOD_M5, PERIOD_M15};
//---------параметры позиции и трейлинга------------
SPositionInfo pos_info;
STrailing     trailing;

// направление открыти€ позиции
int signalForTrade;
long magic;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
 history_start = TimeCurrent(); // запомним врем€ запуска эксперта дл€ получени€ торговой истории

 //----------  онец обработки NineTeenLines----------------
 conbuf = new CContainerBuffers(TFs);
 
 rabbit = new CRabbitsBrain(_Symbol, conbuf); // поместим все созданное в класс - сигнал  ролика
 
 pos_info.volume = 1;
 trailing.trailingType = TRAILING_TYPE_NONE;
 trailing.trailingStop = 0;
 trailing.trailingStep = 0;
 trailing.handleForTrailing = 0;
 ctm = new CTradeManager();

 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 delete ctm;
 delete conbuf;  
 delete rabbit;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
 ctm.OnTick();  
 rabbit.UpdateBuffers();      // потиковое обновление данных буферов            
 pos_info.type = OP_UNKNOWN;  // сброс струтуры позиции
 signalForTrade = NO_SIGNAL;  // обнулим текущий сигнал
 rabbit.OpenedPosition(ctm.GetPositionCount());  // ToDo получить позиции дл€ конкретного робота
 signalForTrade = rabbit.GetSignal();             
 if((signalForTrade == BUY || signalForTrade == SELL )) 
 {
  pos_info.sl = rabbit.GetSL();                          // установить рассчитанный SL
  pos_info.tp = 10 * pos_info.sl; 
  if(signalForTrade == BUY)
   pos_info.type = OP_BUY;
  else 
   pos_info.type = OP_SELL;
  ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing, SPREAD);   // открыть позицию
 }    
}
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
{
 ctm.OnTrade();
 if(history_start != TimeCurrent())
 {
  history_start = TimeCurrent() + 1;
 }   
}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
 if(rabbit.UpdateOnEvent(lparam, dparam, sparam, ctm.GetPositionCount()))
  ctm.ClosePosition(0);
}
//+------------------------------------------------------------------+
