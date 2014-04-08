//+------------------------------------------------------------------+
//|                                                   DISEPTICON.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

// подключение библиотек

#include <TradeManager/TradeManager.mqh>    // торговая библиотека
#include <ColoredTrend/ColoredTrendUtilities.mqh>
#include <Lib CisNewBar.mqh>                // для проверки формирования нового бара
#include "STRUCTS.mqh"                      // библиотека структур данных для получения сигналов



// класс балльной системы
class CPointSys
 { 
  private:
   //---------- приватные методы класса Дисептикона
   
   // структуры параметров
   sEmaParams  _ema_params;   // параметры EMA
   sMacdParams _macd_params;  // параметры MACD
   sStocParams _stoc_params;  // параметры Стохастика
   sPbiParams  _pbi_params;   // параметры PriceBasedIndicator
   sDealParams _deal_params;  // параментры сделок
   sBaseParams _base_params;  // базовые параметры
   
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
   

   CisNewBar *_eldNewBar;          // переменная для определения нового бара на eldTF  
   
   // баллы
   int    _divMACD;                // расхождение MACD
   int    _divStoc;                // расхождение стохастика
   
  public:

  // методы получения торговых сигналов на основе балльной системы
   int  GetFlatSignals  ();        // получение торгового сигнала на Флэте
   int  GetTrendSignals ();        // получение торгового сигнала на тренде
   int  GetCorrSignals  ();        // получение торгового сигнала на коррекции  
  // системные методы
  bool  isUpLoaded();              // метод загрузки (обновления) буферов в класс. Возвращает true, если всё успешно
  ENUM_MOVE_TYPE GetMovingType();  // для получения типа движения 
  // конструкторы и дестрикторы класса Дисептикона
  CPointSys (sDealParams &deal_params,sBaseParams &base_params,sEmaParams &ema_params,sMacdParams &macd_params,sStocParams &stoc_params,sPbiParams &pbi_params);      // конструктор класса
 ~CPointSys ();      // деструктор класса 
 };
 
 
 int  CPointSys::GetFlatSignals(void)
  {
  static int  wait = 0;
  int order_direction = 0;  

  MqlTick tick;   // параметры тика 
 
  if ( isUpLoaded () )     // если данные индикатора успешно прогрузились
   {
 
  if(_bufferSTOCEld[1] > _stoc_params.top_level && _bufferSTOCEld[0] < _stoc_params.top_level)
  {
   if(GreatDoubles(_bufferEMAfastJr[1], _bufferEMAslowJr[1]) && GreatDoubles(_bufferEMAslowJr[0], _bufferEMAfastJr[0]))
   {
    if(GreatDoubles(tick.ask, _bufferEMA3Eld[0] - _base_params.deltaPriceToEMA*_Point))
    {
     //продажа
     log_file.Write(LOG_DEBUG, StringFormat("%s Открыта позиция SELL.", MakeFunctionPrefix(__FUNCTION__)));     
     return (-1);  // типо сигнал на продажу
    }
   }
  }
  if(_bufferSTOCEld[1] < _stoc_params.bottom_level && _bufferSTOCEld[0] > _stoc_params.bottom_level)
  {
   if(GreatDoubles(_bufferEMAslowJr[1], _bufferEMAfastJr[1]) && GreatDoubles(_bufferEMAfastJr[0], _bufferEMAslowJr[0]))
   {
    if(LessDoubles(tick.bid, _bufferEMA3Eld[0] + _base_params.deltaPriceToEMA*_Point))
    {
     //покупка
     log_file.Write(LOG_DEBUG, StringFormat("%s Открыта позиция BUY.", MakeFunctionPrefix(__FUNCTION__)));     
     return (1);  // типо сигнал на покупку
    }
   }
  }
  
  // divengenceFlatMACD
  
  wait++; 
  if (order_direction != 0)   // если есть сигнал о направлении ордера 
  {
   if (wait > _base_params.waitAfterDiv)   // проверяем на допустимое время ожидания после расхождения
   {
    wait = 0;                 // если не дождались обнуляем счетчик ожидания и направления сделки
    order_direction = 0;
   }
  }  
    //order_direction = divergenceMACD(handleMACD, Symbol(), eldTF, 0, nullMACD);   
  if (order_direction == 1)
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Расхождение MACD 1", MakeFunctionPrefix(__FUNCTION__)));
   if(LessDoubles(tick.bid, _bufferEMA3Eld[0] + _base_params.deltaPriceToEMA*_Point))
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s Открыта позиция BUY.", MakeFunctionPrefix(__FUNCTION__)));
    wait = 0;
    return (1);  // типо сигнал на покупку

   }
  }
  if (order_direction == -1)
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Расхождение MACD -1", MakeFunctionPrefix(__FUNCTION__)));
   if(GreatDoubles(tick.ask, _bufferEMA3Eld[0] - _base_params.deltaPriceToEMA*_Point))
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s Открыта позиция SELL.", MakeFunctionPrefix(__FUNCTION__)));
    wait = 0;
    return (-1);  // типо сигнал на продажу
  
   }
  }  
  
  // divergence Flat Stochastic
  
  if (order_direction == 1)
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Расхождение MACD 1", MakeFunctionPrefix(__FUNCTION__)));
   if(LessDoubles(tick.bid, _bufferEMA3Eld[0] + _base_params.deltaPriceToEMA*_Point))
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s Открыта позиция BUY.", MakeFunctionPrefix(__FUNCTION__)));
    wait = 0;
    return (1);  // сигнал на покупку    
   }
  }
  if (order_direction == -1)
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Расхождение MACD -1", MakeFunctionPrefix(__FUNCTION__)));
   if(GreatDoubles(tick.ask, _bufferEMA3Eld[0] - _base_params.deltaPriceToEMA*_Point))
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s Открыта позиция SELL.", MakeFunctionPrefix(__FUNCTION__)));
    wait = 0;    
    return (-1);  // сигнал на продажу
   }
  }
  
  }
  
    return 0; // нет сигнала
  }
  
 int  CPointSys::GetTrendSignals(void)
  {
   MqlTick tick;   // параметры тика
   
   if ( isUpLoaded () )   // пытаемся прогрузить индикаторы
    {
     
   }
   return (0); // нет сигнала
  } 
 
 
 
 int CPointSys::GetCorrSignals(void)
  {
   MqlTick tick;   // параметры тика
   if ( isUpLoaded () ) // если удалось прогрузить индикаторы
    {
     
    }
   return (0); // нет сигнала
  }
 
 // кодирование методов класса больной системы
 
 bool CPointSys::isUpLoaded(void)   // метож загрузки (обновления) буферов в класс. Возвращает true в случае успеха
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
            copiedPBI     =       CopyBuffer( _handlePBI,       4, 1, 1, _bufferPBI);
            copiedSTOCEld   =     CopyBuffer( _handleSTOCEld,   0, 1, 2, _bufferSTOCEld);
            copiedEMAfastJr =     CopyBuffer( _handleEMAfastJr, 0, 1, 2, _bufferEMAfastJr);
            copiedEMAslowJr =     CopyBuffer( _handleEMAslowJr, 0, 1, 2, _bufferEMAslowJr);
            copiedEMA3Eld   =     CopyBuffer( _handleEMA3Eld,   0, 0, 1, _bufferEMA3Eld);
           }  
 if (    copiedPBI != 1 ||   copiedSTOCEld != 2 ||  copiedEMA3Eld != 1 ||
      copiedEMAfastJr != 2 || copiedEMAslowJr != 2 )   //Копируем данные индикаторов
  {
  // Comment("STOC = ",copiedSTOCEld," copiedEMA3Eld = ",copiedEMA3Eld,"copiedEMAfastJr=",copiedEMAfastJr,"copiedEMAslowJr=",copiedEMAslowJr,"copiedPBI=",copiedPBI);
   log_file.Write(LOG_DEBUG, StringFormat("%s Ошибка заполнения буфера.Error(%d) = %s" 
                                          , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
   return (false);
  }
 else
  {
  //Comment("Значение в раскраске = ",_bufferPBI[0]);
  return (true);
   }     
      }
   return (false);
  }
 
 
 ENUM_MOVE_TYPE CPointSys::GetMovingType(void)
  {
   if (_bufferPBI[0] == 1)
    return (MOVE_TYPE_TREND_UP);            // Тренд вверх - синий
   if (_bufferPBI[0] == 2)
    return (MOVE_TYPE_TREND_UP_FORBIDEN);   // Тренд вверх, запрещенный верхним ТФ - фиолетовый
   if (_bufferPBI[0] == 3)
    return (MOVE_TYPE_TREND_DOWN);          // Тренд вниз - красный
   if (_bufferPBI[0] == 4) 
    return (MOVE_TYPE_TREND_DOWN_FORBIDEN); // Тренд вниз, запрещенный верхним ТФ - коричневый
   if (_bufferPBI[0] == 5)  
    return (MOVE_TYPE_CORRECTION_UP);       // Коррекция вверх, корректируется тренд вниз - розовый
   if (_bufferPBI[0] == 6)  
    return (MOVE_TYPE_CORRECTION_DOWN);     // Коррекция вниз, корректируется тренд вверх - голубой
   if (_bufferPBI[0] == 7)  
    return (MOVE_TYPE_FLAT);                // Флэт - желтый
    
   return (MOVE_TYPE_UNKNOWN);              // неизвестное движение
  }
 
 // кодирование конструктора и деструктора
 
 // конструктор класса Дисептикона
 CPointSys::CPointSys(sDealParams &deal_params,sBaseParams &base_params,sEmaParams &ema_params,sMacdParams &macd_params,sStocParams &stoc_params,sPbiParams &pbi_params)
  {
   //---------инициализируем параметры, буферы, индикаторы и прочее
   
   ////// сохраняем внешние параметры
   _deal_params = deal_params;
   _base_params = base_params;
   _ema_params  = ema_params;
   _macd_params = macd_params;
   _stoc_params = stoc_params;
   _pbi_params  = pbi_params;
   
   // обнуляем баллы
   _divMACD     = 0;
   _divStoc     = 0;
   
   ////// инициализаруем индикаторы
   //---------инициализируем параметры, буферы, индикаторы и прочее
   
   ////// сохраняем внешние параметры   ////// инициализаруем индикаторы
   _handlePBI       = iCustom(_Symbol, /*_base_params.eldTF*/ _Period, "PriceBasedIndicator", /*_pbi_params.bars*/1000);
   _handleSTOCEld   = iStochastic(NULL, _base_params.eldTF, _stoc_params.kPeriod, _stoc_params.dPeriod, _stoc_params.slow, MODE_SMA, STO_CLOSECLOSE);
   _handleEMAfastJr = iMA(Symbol(),  _base_params.jrTF, _ema_params.periodEMAfastJr, 0, MODE_EMA, PRICE_CLOSE);
   _handleEMAslowJr = iMA(Symbol(),  _base_params.jrTF, _ema_params.periodEMAslowJr, 0, MODE_EMA, PRICE_CLOSE);
   _handleEMA3Eld   = iMA(Symbol(),  _base_params.eldTF,               3, 0, MODE_EMA, PRICE_CLOSE);

 if (_handlePBI == INVALID_HANDLE || _handleEMAfastJr == INVALID_HANDLE || _handleEMAslowJr == INVALID_HANDLE)
 {

  log_file.Write(LOG_DEBUG, StringFormat("%s INVALID_HANDLE (handleTrend). Error(%d) = %s" 
                                        , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
  //return(INIT_FAILED);
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
 
 CPointSys::~CPointSys(void)
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