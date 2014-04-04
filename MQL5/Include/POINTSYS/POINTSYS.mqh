//+------------------------------------------------------------------+
//|                                                   DISEPTICON.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

// подключение библиотек

#include <TradeManager/TradeManager.mqh>             // торговая библиотека
#include <ColoredTrend/ColoredTrendUtilities.mqh>    // для констант PriceBased indicator   
#include <Lib CisNewBar.mqh>                         // для проверки формирования нового бара
#include "STRUCTS.mqh"                               // библиотека структур данных для получения сигналов

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
   int _priceDifference;           // Price Difference
   CisNewBar *_eldNewBar;          // переменная для определения нового бара на eldTF  
   
  public:
  // методы получения торговых сигналов на основе бальной системы
  bool  UpLoad();                  // метод загрузки (обновления) буферов в класс
  ENUM_MOVE_TYPE GetMovingType();  // для получения типа движения 
  // конструкторы и дестрикторы класса Дисептикона
  POINTSYS (DEAL_PARAMS &deal_params,BASE_PARAMS &base_params,EMA_PARAMS &ema_params,MACD_PARAMS &macd_params,STOC_PARAMS &stoc_params,PBI_PARAMS &pbi_params);      // конструктор класса
 ~POINTSYS ();      // деструктор класса 
 };
 
 // кодирование методов класса больной системы
 
 bool POINTSYS::UpLoad(void)   // метод загрузки (обновления) буферов в класс
  {
    int copiedPBI=-1;
    int copiedSTOCEld=-1;
    int copiedEMAfastJr=-1;
    int copiedEMAslowJr=-1;
    int copiedEMA3Eld=-1; 
    int attempts;
    if (_eldNewBar.isNewBar() > 0)      //на каждом новом баре старшего TF
      {
        for (attempts = 0; attempts < 25 && (   copiedPBI     < 0
                                             || copiedSTOCEld   < 0
                                             || copiedEMAfastJr < 0
                                             || copiedEMAslowJr < 0
                                             || copiedEMA3Eld   < 0 ); attempts++) //Копируем данные индикаторов
           {
            copiedPBI       =     CopyBuffer( _handlePBI,       4, 1, 1, _bufferPBI);
            copiedSTOCEld   =     CopyBuffer( _handleSTOCEld,   0, 1, 2, _bufferSTOCEld);
            copiedEMAfastJr =     CopyBuffer( _handleEMAfastJr, 0, 1, 2, _bufferEMAfastJr);
            copiedEMAslowJr =     CopyBuffer( _handleEMAslowJr, 0, 1, 2, _bufferEMAslowJr);
            copiedEMA3Eld   =     CopyBuffer( _handleEMA3Eld,   0, 0, 1, _bufferEMA3Eld);
           }  
        if (attempts < 25)
         return true;
        
      }
   return false;
  }
  
 // для получения типа движения
 
 ENUM_MOVE_TYPE POINTSYS::GetMovingType(void)
  {

   if (_bufferPBI[0] == 1)
    return MOVE_TYPE_TREND_UP;            // Тренд вверх - синий
   if (_bufferPBI[0] == 1)
    return MOVE_TYPE_TREND_UP_FORBIDEN;   // Тренд вверх, запрещенный верхним ТФ - фиолетовый
   if (_bufferPBI[0] == 1)
    return MOVE_TYPE_TREND_DOWN;          // Тренд вниз - красный
   if (_bufferPBI[0] == 1) 
    return MOVE_TYPE_TREND_DOWN_FORBIDEN; // Тренд вниз, запрещенный верхним ТФ - коричневый
   if (_bufferPBI[0] == 1)  
    return MOVE_TYPE_CORRECTION_UP;       // Коррекция вверх, корректируется тренд вниз - розовый
   if (_bufferPBI[0] == 1)  
    return MOVE_TYPE_CORRECTION_DOWN;     // Коррекция вниз, корректируется тренд вверх - голубой
   if (_bufferPBI[0] == 1)  
    return MOVE_TYPE_FLAT;                // Флэт - желтый
    
   return MOVE_TYPE_UNKNOWN;              // неизвестное движение
  }
 
 // кодирование конструктора и деструктора
 
 // конструктор класса Дисептикона
 POINTSYS::POINTSYS(DEAL_PARAMS &deal_params,BASE_PARAMS &base_params,EMA_PARAMS &ema_params,MACD_PARAMS &macd_params,STOC_PARAMS &stoc_params,PBI_PARAMS &pbi_params)
  {
   //---------инициализируем параметры, буферы, индикаторы и прочее
   
   ////// сохраняем внешние параметры
   _deal_params = deal_params;
   _base_params = base_params;
   _ema_params  = ema_params;
   _macd_params = macd_params;
   _stoc_params = stoc_params;
   _pbi_params  = pbi_params;
   
   Alert("проверяем top_level = ",_stoc_params.top_level);
   
   ////// инициализаруем индикаторы
   _handlePBI       = iCustom(_Symbol, _base_params.eldTF, "PriceBasedIndicator", _pbi_params.historyDepth, _pbi_params.bars);
   _handleSTOCEld   = iStochastic(NULL, _base_params.eldTF, _stoc_params.kPeriod, _stoc_params.dPeriod, _stoc_params.slow, MODE_SMA, STO_CLOSECLOSE);
   _handleEMAfastJr = iMA(Symbol(),  _base_params.jrTF, _ema_params.periodEMAfastJr, 0, MODE_EMA, PRICE_CLOSE);
   _handleEMAslowJr = iMA(Symbol(),  _base_params.jrTF, _ema_params.periodEMAslowJr, 0, MODE_EMA, PRICE_CLOSE);
   _handleEMA3Eld   = iMA(Symbol(), _base_params.eldTF,               3, 0, MODE_EMA, PRICE_CLOSE);

 if (_handlePBI == INVALID_HANDLE || _handleEMAfastJr == INVALID_HANDLE || _handleEMAslowJr == INVALID_HANDLE)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s INVALID_HANDLE (handleTrend). Error(%d) = %s" 
                                        , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
  //return(INIT_FAILED);
 }   
 
if ( _deal_params.useLimitOrders)                           // выбор типа сделок Order / Limit / Stop
 {
  _opBuy  = OP_BUYLIMIT;
  _opSell = OP_SELLLIMIT;
  _priceDifference =  _deal_params.limitPriceDifference;
 }
 else if (_deal_params.useStopOrders)
      {
       _opBuy  = OP_BUYSTOP;
       _opSell = OP_SELLSTOP;
       _priceDifference = _deal_params.stopPriceDifference;
      }
      else
      {
       _opBuy = OP_BUY;
       _opSell = OP_SELL;
       _priceDifference = 0;
      } 
  // выделяем память под объект класса определения формирования нового бара
  _eldNewBar = new CisNewBar(_base_params.eldTF);
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
   IndicatorRelease(_handlePBI);
   IndicatorRelease(_handleEMA3Eld);
   IndicatorRelease(_handleEMAfastJr);
   IndicatorRelease(_handleEMAslowJr);
   IndicatorRelease(_handleSTOCEld);
   // освобождаем память под буферы
   ArrayFree(_bufferPBI);
   ArrayFree(_bufferEMA3Eld);
   ArrayFree(_bufferEMAfastJr);
   ArrayFree(_bufferEMAslowJr);
   // пишем в лог об деинициализации
   log_file.Write(LOG_DEBUG, StringFormat("%s Деиниализация.", MakeFunctionPrefix(__FUNCTION__)));    
  }