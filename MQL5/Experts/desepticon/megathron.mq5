//+------------------------------------------------------------------+
//|                                                    megathron.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

//подключение необходимых библиотек

#include <ColoredTrend/ColoredTrendUtilities.mqh> 
#include <CTrendChannel.mqh> // трендовый контейнер
#include <Rabbit/RabbitsBrain.mqh>
#include <Chicken/ChickensBrain.mqh>                 // объект по вычислению сигналов для торговли

//константы
#define KO 3            //коэффициент для условия открытия позиции, во сколько как минимум вычисленный тейк профит должен превышать вычисленный стоп лосс
#define SPREAD 30       // размер спреда 

// ---------переменные робота------------------
CContainerBuffers *conbuf; // буфер контейнеров на различных Тф, заполняемый на OnTick()
                           // highPrice[], lowPrice[], closePrice[] и т.д; 
CRabbitsBrain *rabbit;
CChickensBrain *chicken;

CTradeManager *ctm;        // торговый класс 
     
datetime history_start;    // время для получения торговой истории                           

ENUM_TM_POSITION_TYPE opBuy, opSell;
ENUM_TIMEFRAMES TFs[6] = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_H1, PERIOD_H4, PERIOD_D1};
//---------параметры позиции и трейлинга------------
SPositionInfo pos_info;
STrailing     trailing;

// направление открытия позиции
long magic[6] = {1111, 1112, 1113, 1114, 1115, 1116};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
 ctm = new CTradeManager();
 history_start = TimeCurrent(); // запомним время запуска эксперта для получения торговой истории

 //---------- Конец обработки NineTeenLines----------------
 conbuf = new CContainerBuffers(TFs);
 
 rabbit = new CRabbitsBrain(_Symbol, conbuf); // поместим все созданное в класс - сигнал Кролика
 chicken = new CChickensBrain(_Symbol,_Period, conbuf);

 pos_info.volume = 1;
 trailing.trailingType = TRAILING_TYPE_NONE;
 trailing.trailingStop = 0;
 trailing.trailingStep = 0;
 trailing.handleForTrailing = 0;

 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   
  }
//+------------------------------------------------------------------+
