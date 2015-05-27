//+------------------------------------------------------------------+
//|                                             RabbitWithBrains.mq5 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

//подключение необходимых библиотек

#include <SystemLib/IndicatorManager.mqh> // библиотека по работе с индикаторами
#include <ColoredTrend/ColoredTrendUtilities.mqh> 
#include <CTrendChannel.mqh> // трендовый контейнер
#include <Rabbit/Timeframe.mqh>
#include <Rabbit/RabbitsBrain.mqh>

//константы
#define KO 3            //коэффициент для условия открытия позиции, во сколько как минимум вычисленный тейк профит должен превышать вычисленный стоп лосс
#define SPREAD 30       // размер спреда 

//---------------------Добавить---------------------------------+
// ENUM для сигнала
// входные параметры для процента supremacyPercent
// нужно ли в конбуф запихнуть данные индикатора АТР, а цену открытия?
//--------------------------------------------------------------+

//-------вводимые пользователем параметры ВСЕ перенесены в константы, если правильно надо УДАЛИТЬ-------------
input double percent = 0.1;   // процент
input double M1_Ratio  = 5;   //процент, насколько бар M1 больше среднего значения
input double M5_Ratio  = 3;   //процент, насколько бар M1 больше среднего значения
input double M15_Ratio  = 1;  //процент, насколько бар M1 больше среднего значения

// ---------переменные робота------------------
CTrendChannel *trend;      // буфер трендов
CTimeframe *ctf;           // данные по ТФ
CContainerBuffers *conbuf; // буфер контейнеров на различных Тф, заполняемый на OnTick()
                           // highPrice[], lowPrice[], closePrice[] и т.д; 
CArrayObj *dataTFs;        // массив ТФ, для торговли на нескольких ТФ одновременно
CArrayObj *trends;         // массив буферов трендов (для каждого ТФ свой буфер)
CRabbitsBrain *rabbit;
CTimeframe *posOpenedTF;  // период на котором была открыта позиция
CTradeManager ctm;         // торговый класс 
     
datetime history_start;    // время для получения торговой истории                           
ENUM_TIMEFRAMES TFs[3] = {PERIOD_M1, PERIOD_M5, PERIOD_M15};// ------------------исправь объявление рэбита и все в него запихни, +структура
ENUM_TM_POSITION_TYPE opBuy, opSell;
int handle19Lines; 
int handleATR;
int handleDE;


//---------параметры позиции и трейлинга------------
SPositionInfo pos_info;
STrailing     trailing;
double volume = 1.0;   // объем  

// направление открытия позиции
int signalForTrade;
int SL, TP;
long magic;



int indexPosOpenedTF;         // удалить елсли закрытие позиции по условию любого тренда или на том же тчо и была открыта

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{

 history_start = TimeCurrent(); //запомним время запуска эксперта для получения торговой истории

 //---------- Конец обработки NineTeenLines----------------
 conbuf = new CContainerBuffers(TFs);
 opBuy  = OP_BUY;  // так было. Зачем?
 opSell = OP_SELL;
 
 rabbit = new CRabbitsBrain(_Symbol, conbuf, TFs); // поместим все созданное в класс - сигнал Кролика
 
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
 delete trend;
 delete conbuf;
 dataTFs.Clear();
 delete dataTFs;
 trends.Clear();
 delete trends;  
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
 rabbit.OpenedPosition(ctm.GetPositionCount());  // ToDo получить позиции для конкретного робота
 signalForTrade = rabbit.GetSignal();             
 if( (signalForTrade == BUY || signalForTrade == SELL ) ) //(signalForTrade != NO_POISITION)
 {
  pos_info.sl = rabbit.GetSL();                     // установить рассчитанный SL
  pos_info.tp = 10 * SL; 
  if(signalForTrade == BUY)
   pos_info.type = opBuy;
  else 
   pos_info.type = opSell;
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
