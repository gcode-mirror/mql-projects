//+------------------------------------------------------------------+
//|                                                   DISEPTICON.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

// подключение библиотек

#include <TradeManager/TradeManager.mqh>    // торговая библиотека
#include "STRUCTS.mqh"                      // библиотека структур данных для получения сигналов

// класс Дисептикона
class POINTSYS
 { 
  private:
   //---------- приватные методы класса Дисептикона
   
   // структуры параметров
   EMA_PARAMS  _ema_params;   // параметры EMA
   MACD_PARAMS _macd_params;  // параметры MACD
   STOC_PARAMS _stoc_params;  // параметры Стохастика
   PBI_PARAMS  _pbi_params;   // параметры PriceBasedIndicator
   DEAL_PARAMS _deal_params;  // параментры сделок
   BASE_PARAMS _base_params;  // базовые параметры
   
   // P.S. пока что взять хэндлы и буферы для DesepticonFlat
   
   // хэндлы индикаторов
   int    _handlePBI;              // хэндл PriceBased indicator
   int    _handleEMA3Eld;          // хэндл EMA 3 дневного TF
   int    _handleEMAfastJr;        // хэндл EMA fast старшего таймфрейма
   int    _handleEMAslowJr;        // хэндл EMA fast младшего таймфрейма
   int    _handleSTOCEld;          // хэндл Stochastic старшего таймфрейма

   // буферы индикаторов 
   double _bufferPBI[];            // буфер для PriceBased indicator  
   double _bufferEMA3Eld[];        // буфер для EMA 3 старшего таймфрейма
   double _bufferEMAfastJr[];      // буфер для EMA fast младшего таймфрейма
   double _bufferEMAslowJr[];      // буфер для EMA slow младшего таймфрейма
   double _bufferSTOCEld[];        // буфер для Stochastic старшего таймфрейма  
   
   // системные переменные
   ENUM_TM_POSITION_TYPE _opBuy,   // сигнал на покупку 
                         _opSell;  // сигнал на продажу
   
   
  public:
  // методы получения торговых сигналов на основе бальной системы
  
  // конструкторы и дестрикторы класса Дисептикона
  POINTSYS (); // конструктор класса
 ~POINTSYS (); // деструктор класса 
 };
 
 // кодирование конструктора и деструктора
 
 // конструктор класса Дисептикона
 POINTSYS::POINTSYS(void)
  {
   //---------инициализируем параметры, буферы, индикаторы и прочее
   
   ////// инициализаруем индикаторы
   _handlePBI       = iCustom(_Symbol, _base_params.eldTF, "PriceBasedIndicator", _pbi_params.historyDepth, _pbi_params.bars);
   _handleSTOCEld   = iStochastic(NULL, eldTF, kPeriod, dPeriod, slow, MODE_SMA, STO_CLOSECLOSE);
   _handleEMAfastJr = iMA(Symbol(),  jrTF, periodEMAfastJr, 0, MODE_EMA, PRICE_CLOSE);
   _handleEMAslowJr = iMA(Symbol(),  jrTF, periodEMAslowJr, 0, MODE_EMA, PRICE_CLOSE);
   _handleEMA3Eld   = iMA(Symbol(), eldTF,               3, 0, MODE_EMA, PRICE_CLOSE);

 if (handleTrend == INVALID_HANDLE || handleEMAfastJr == INVALID_HANDLE || handleEMAslowJr == INVALID_HANDLE)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s INVALID_HANDLE (handleTrend). Error(%d) = %s" 
                                        , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
  //return(INIT_FAILED);
 }   
 
  // порядок элементов в массивах, как в таймсерии
  ArraySetAsSeries( _bufferPBI, true);
  ArraySetAsSeries( _bufferEMA3Eld, true);
  ArraySetAsSeries( _bufferEMAfastJr, true);
  ArraySetAsSeries( _bufferEMAslowJr, true);
  ArraySetAsSeries( _bufferSTOCEld, true);
  // изменяем размер буферов
  ArrayResize( _bufferPBI, 1);
  ArrayResize( _bufferEMA3Eld, 1);
  ArrayResize( _bufferEMAfastJr, 2);
  ArrayResize( _bufferEMAslowJr, 2);
  ArrayResize( _bufferSTOCEld, 1);
   
  }
  
 // деструктор класса дисептикона
 
 POINTSYS::~POINTSYS(void)
  {
   // освобождаем индикаторы
   IndicatorRelease(_handleTrend);
   IndicatorRelease(_handleEMA3Eld);
   IndicatorRelease(_handleEMAfastJr);
   IndicatorRelease(_handleEMAslowJr);
   IndicatorRelease(_handleSTOCEld);
   // освобождаем память под буферы
   ArrayFree(_bufferTrend);
   ArrayFree(_bufferEMA3Eld);
   ArrayFree(_bufferEMAfastJr);
   ArrayFree(_bufferEMAslowJr);
   // пишем в лог об деинициализации
   log_file.Write(LOG_DEBUG, StringFormat("%s Деиниализация.", MakeFunctionPrefix(__FUNCTION__)));    
  }