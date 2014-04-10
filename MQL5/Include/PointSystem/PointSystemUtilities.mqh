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

struct sPoint
 {
  SIGNAL_TYPE signal;  // тип сигнала
  int point_value;     // количество баллов
 };

// структура EMA

struct sEmaParams
 {
  int    periodEMAfastEld;           // период быстрой EMA на страршем таймфрейме
  int    periodEMAfastJr;            // период быстрой EMA на младшем таймфрейме
  int    periodEMAslowJr;            // период медленной EMA на младшем таймфрейме
 };
 
// структура MACD

struct sMacdParams
 {
  int fast_EMA_period;            // быстрый период EMA для MACD
  int slow_EMA_period;            // медленный период EMA для MACD
  int signal_period;              // период сигнальной линии для MACD 
  int applied_price;                      // глубина поиска расхождения    
 };

// структура параметров Стохастика

struct sStocParams
 {
  int kPeriod;                    // К-период стохастика
  int dPeriod;                    // D-период стохастика
  int slow;                       // Сглаживание стохастика. Возможные значения от 1 до 3.
  int top_level;                  // Top-level стохастка
  int bottom_level;               // Bottom-level стохастика
  int allow_depth_for_price_extr; // допустимая грубина для экстремума цены
  int depth;                      // глубина поиска расхождения    
 };
 
// структура параметров PriceBasedIndicator
struct sPbiParams
 {
  int historyDepth;                            // глубина истории для расчета
  int bars;                                    // сколько свечей показывать
 };
// структура сделок
struct sDealParams
 {
  double orderVolume;                          // Объём сделки
  int slOrder;                                 // Stop Loss
  int tpOrder;                                 // Take Profit
  int trStop;                                  // Trailing Stop
  int trStep;                                  // Trailing Step
  int minProfit;                               // Minimal Profit 
 };
 
// структура базовых настроек
struct sBaseParams
 {
  ENUM_TIMEFRAMES eldTF;             //
  ENUM_TIMEFRAMES jrTF;              //
  bool useJrEMAExit;               // будем ли выходить по ЕМА
  int posLifeTime;                // время ожидания сделки в барах
  int deltaPriceToEMA;            // допустимая разница между ценой и EMA для пересечения
  int deltaEMAtoEMA;              // необходимая разница для разворота EMA
  int waitAfterDiv;               // ожидание сделки после расхождения (в барах)
 };