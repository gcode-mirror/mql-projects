//+------------------------------------------------------------------+
//|                                                      STRUCTS.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| библиотека структур данных для получения сигналов                |
//+------------------------------------------------------------------+

// перечисление типов сигналов

enum SIGNAL_TYPE
 {
  CROSS_EMA=0  // это для примера от балды пока что временно
 };
 
// структура хранения сигналов и количества баллов

struct POINT_STRUCT
 {
  SIGNAL_TYPE signal;  // тип сигнала
  int point_value;     // количество баллов
 };

// структура EMA

struct EMA_PARAMS
 {
  int    periodEMAfastJr;            // период быстрой EMA
  int    periodEMAslowJr;            // период медленной EMA
 };
 
// структура MACD

struct MACD_PARAMS
 {
  int    fast_EMA_period;            // быстрый период EMA для MACD
  int    slow_EMA_period;            // медленный период EMA для MACD
  int    signal_period;              // период сигнальной линии для MACD 
 };

// структура параметров Стохастика

struct STOC_PARAMS
 {
  int    kPeriod;                    // К-период стохастика
  int    dPeriod;                    // D-период стохастика
  int    slow;                       // Сглаживание стохастика. Возможные значения от 1 до 3.
  int    top_level;                  // Top-level стохастка
  int    bottom_level;               // Bottom-level стохастика
  int    DEPTH;                      // глубина поиска расхождения
  int    ALLOW_DEPTH_FOR_PRICE_EXTR; // допустимая глубина для экстремума цены
 };
 
// структура параметров PriceBasedIndicator
struct PBI_PARAMS
 {
  int    historyDepth;               // глубина истории для расчета
  int    bars;                       // сколько свечей показывать
 };
// структура сделок
struct DEAL_PARAMS
 {
  double orderVolume;                // Объём сделки
  int    slOrder;                    // Stop Loss
  int    tpOrder;                    // Take Profit
  int    trStop;                     // Trailing Stop
  int    trStep;                     // Trailing Step
  int    minProfit;                  // Minimal Profit 
  bool   useLimitOrders;             // Использовать Limit ордера
  int    limitPriceDifference;       // Разнциа для Limit ордеров
  bool   useStopOrders;              // Использовать Stop ордера
  int    stopPriceDifference;        // Разнциа для Stop ордеров 
 };
 
// структура базовых настроек
struct BASE_PARAMS
 {
  ENUM_TIMEFRAMES eldTF;             //
  ENUM_TIMEFRAMES jrTF;              //
  bool   useJrEMAExit;               // будем ли выходить по ЕМА
  int    posLifeTime;                // время ожидания сделки в барах
  int    deltaPriceToEMA;            // допустимая разница между ценой и EMA для пересечения
  int    deltaEMAtoEMA;              // необходимая разница для разворота EMA
  int    waitAfterDiv;               // ожидание сделки после расхождения (в барах)
 };