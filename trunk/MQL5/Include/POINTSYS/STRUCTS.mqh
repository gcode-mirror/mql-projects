//+------------------------------------------------------------------+
//|                                                      STRUCTS.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| библиотека структур данных дл€ получени€ сигналов                |
//+------------------------------------------------------------------+

// структура EMA

struct EMA_PARAMS
 {
 
 };
 
// структура MACD

struct MACD_PARAMS
 {
  int    fast_EMA_period;            // быстрый период EMA дл€ MACD
  int    slow_EMA_period;            // медленный период EMA дл€ MACD
  int    signal_period;              // период сигнальной линии дл€ MACD 
 };

// структура параметров —тохастика

struct STOC_PARAMS
 {
  int    kPeriod;                    //  -период стохастика
  int    dPeriod;                    // D-период стохастика
  int    slow;                       // —глаживание стохастика. ¬озможные значени€ от 1 до 3.
  int    top_level;                  // Top-level стохастка
  int    bottom_level;               // Bottom-level стохастика
  int    DEPTH;                      // глубина поиска расхождени€
  int    ALLOW_DEPTH_FOR_PRICE_EXTR; // допустима€ глубина дл€ экстремума цены
 };
 
// структура параметров PriceBasedIndicator
struct PBI_PARAMS
 {
  int    historyDepth;               // глубина истории дл€ расчета
  int    bars;                       // сколько свечей показывать
 };
// структура сделок
struct DEAL_PARAMS
 {
  double orderVolume;                // ќбъЄм сделки
  int    slOrder;                    // Stop Loss
  int    tpOrder;                    // Take Profit
  int    trStop;                     // Trailing Stop
  int    trStep;                     // Trailing Step
  int    minProfit;                  // Minimal Profit 
  bool   useLimitOrders;             // »спользовать Limit ордера
  int    limitPriceDifference;       // –азнциа дл€ Limit ордеров
  bool   useStopOrders;              // »спользовать Stop ордера
  int    stopPriceDifference;        // –азнциа дл€ Stop ордеров 
 };
 
// структура базовых настроек
struct BASE_PARAMS
 {
  ENUM_TIMEFRAMES eldTF;             //
  ENUM_TIMEFRAMES jrTF;              //
  bool   useJrEMAExit;               // будем ли выходить по ≈ћј
  int    posLifeTime;                // врем€ ожидани€ сделки в барах
  int    deltaPriceToEMA;            // допустима€ разница между ценой и EMA дл€ пересечени€
  int    deltaEMAtoEMA;              // необходима€ разница дл€ разворота EMA
  int    waitAfterDiv;               // ожидание сделки после расхождени€ (в барах)
 };