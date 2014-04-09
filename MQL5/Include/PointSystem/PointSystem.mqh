//+------------------------------------------------------------------+
//|                                                   DISEPTICON.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

// подключение библиотек
#include <Divergence/divergenceMACD.mqh>
#include <Divergence/divergenceStochastic.mqh>
#include <Lib CisNewBar.mqh>                // для проверки формирования нового бара
#include <StringUtilities.mqh>
#include <CLog.mqh>
#include "PointSystemUtilities.mqh"                      // библиотека структур данных для получения сигналов

// класс балльной системы
class CPointSys
 { 
  private:
   //---------- приватные методы класса балльной системы
   
   // структуры параметров
   sEmaParams  _ema_params;   // параметры EMA
   sMacdParams _macd_params;  // параметры MACD
   sStocParams _stoc_params;  // параметры Стохастика
   sPbiParams  _pbi_params;   // параметры PriceBasedIndicator
   sDealParams _deal_params;  // параментры сделок
   sBaseParams _base_params;  // базовые параметры
   
   //---------- приватные переменные класса балльной системы
   MqlTick _tick;   // параметры тика 
   string _symbol; // рабочий инструмент
   
   // P.S. пока что взять хэндлы и буферы для DesepticonFlat
   
   // хэндлы индикаторов
   int _handlePBI;         // хэндл PriceBased indicator
   int _handleEMAfastJr;   // хэндл EMA fast старшего таймфрейма
   int _handleEMAslowJr;   // хэндл EMA fast младшего таймфрейма
   int _handleSTOCEld;     // хэндл Stochastic старшего таймфрейма
   int _handleMACD;        // хэндл MACD
   // буферы индикаторов 
   double _bufferPBI[];            // буфер для PriceBased indicator  
   double _bufferEMA3Eld[];        // буфер для EMA 3 старшего таймфрейма
   double _bufferEMAfastJr[];      // буфер для EMA fast младшего таймфрейма
   double _bufferEMAslowJr[];      // буфер для EMA slow младшего таймфрейма
   double _bufferSTOCEld[];        // буфер для Stochastic старшего таймфрейма  
   
   CisNewBar *_eldNewBar;          // переменная для определения нового бара на eldTF  
   
   // методы вычисления сигналов
   int StochasticAndEma();

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
   int GetMovingType() {return((int)_bufferPBI[0]);};  // для получения типа движения 
  // конструкторы и дестрикторы класса Дисептикона
   CPointSys (sDealParams &deal_params,sBaseParams &base_params,sEmaParams &ema_params,sMacdParams &macd_params,sStocParams &stoc_params,sPbiParams &pbi_params);      // конструктор класса
   ~CPointSys ();      // деструктор класса 
 };

//--------------------------------------
// конструктор балльной системы
//--------------------------------------
CPointSys::CPointSys(sDealParams &deal_params,sBaseParams &base_params,sEmaParams &ema_params,sMacdParams &macd_params,sStocParams &stoc_params,sPbiParams &pbi_params)
{
 //---------инициализируем параметры, буферы, индикаторы и прочее
 _symbol = Symbol();

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
 _handlePBI       = iCustom(Symbol(), Period(), "PriceBasedIndicator", 1000);
 _handleMACD      = iMACD(Symbol(), Period(), _macd_params.fast_EMA_period,  _macd_params.slow_EMA_period, _macd_params.signal_period, _macd_params.applied_price);
 _handleSTOCEld   = iStochastic(NULL, _base_params.eldTF, _stoc_params.kPeriod, _stoc_params.dPeriod, _stoc_params.slow, MODE_SMA, STO_CLOSECLOSE);
 _handleEMAfastJr = iMA(Symbol(),  _base_params.jrTF, _ema_params.periodEMAfastJr, 0, MODE_EMA, PRICE_CLOSE);
 _handleEMAslowJr = iMA(Symbol(),  _base_params.jrTF, _ema_params.periodEMAslowJr, 0, MODE_EMA, PRICE_CLOSE);

 if (_handlePBI == INVALID_HANDLE || 
     _handleEMAfastJr == INVALID_HANDLE || 
     _handleEMAslowJr == INVALID_HANDLE || 
     _handleMACD == INVALID_HANDLE || 
     _handleSTOCEld == INVALID_HANDLE)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s INVALID_HANDLE (handleTrend). Error(%d) = %s" 
                                        , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
 }   
            
 // выделяем память под объект класса определения формирования нового бара
 _eldNewBar = new CisNewBar(_base_params.eldTF);
  // порядок элементов в массивах, как в таймсерии
 ArraySetAsSeries( _bufferPBI, true);
 ArraySetAsSeries( _bufferEMAfastJr, true);
 ArraySetAsSeries( _bufferEMAslowJr, true);
 ArraySetAsSeries( _bufferSTOCEld, true);
  // изменяем размер буферов
 ArrayResize( _bufferPBI, 1);
 ArrayResize( _bufferEMAfastJr, 2);
 ArrayResize( _bufferEMAslowJr, 2);
 ArrayResize( _bufferSTOCEld, 1);
}

//---------------------------------------------  
// деструктор балльной системы
//---------------------------------------------
 CPointSys::~CPointSys(void)
  {
   delete _eldNewBar;
   // освобождаем индикаторы
   IndicatorRelease(_handlePBI);
   IndicatorRelease(_handleEMAfastJr);
   IndicatorRelease(_handleEMAslowJr);
   IndicatorRelease(_handleSTOCEld);
   IndicatorRelease(_handleMACD);
   // освобождаем память под буферы
   ArrayFree(_bufferPBI);
   ArrayFree(_bufferEMAfastJr);
   ArrayFree(_bufferEMAslowJr);
   // пишем в лог об деинициализации
   log_file.Write(LOG_DEBUG, StringFormat("%s Деиниализация.", MakeFunctionPrefix(__FUNCTION__)));    
  }
 
//---------------------------------------------------
// Вычисляем сигнал на флете
//--------------------------------------------------- 
int CPointSys::GetFlatSignals()
 {
  int points = 0; 
  SymbolInfoTick(_symbol, _tick); 

  if (isUpLoaded ())     // если данные индикатора успешно прогрузились
  {
   //StochasticAndEma();  // Этот сигнал не проверен и пока что не используется
      
   points += divergenceMACD(_handleMACD, Symbol(), Period());   
   points += divergenceSTOC(_handleSTOCEld, Symbol(), Period(),80,20);   
  }
  return (points); // нет сигнала
 }

//---------------------------------------------------
// Вычисляем сигнал на тренде
//--------------------------------------------------- 
int  CPointSys::GetTrendSignals(void)
{
 SymbolInfoTick(Symbol(), _tick);
 
 if ( isUpLoaded () )   // пытаемся прогрузить индикаторы
 {
    
 }
 return (0); // нет сигнала
} 

//---------------------------------------------------
// Вычисляем сигнал на коррекции
//---------------------------------------------------  
int CPointSys::GetCorrSignals(void)
{
 SymbolInfoTick(Symbol(), _tick);
 if ( isUpLoaded () ) // если удалось прогрузить индикаторы
 {
   
 }
 return (0); // нет сигнала
}

//-----------------------------------------------
// метод заполнения индикаторных буферов
//-----------------------------------------------
bool CPointSys::isUpLoaded(void)  
{
 int copiedPBI=-1;
 int copiedSTOCEld=-1;
 int copiedEMAfastJr=-1;
 int copiedEMAslowJr=-1;
 int attempts;

 for (attempts = 0; attempts < 25 && copiedPBI < 0; attempts++)
 {
  copiedPBI = CopyBuffer(_handlePBI, 4, 1, 1, _bufferPBI);
 }
 if (copiedPBI < 0) return(false);  // Не смогли загрузить буфер PBI
 
 if (_eldNewBar.isNewBar() > 0)      //на каждом новом баре старшего TF
 {
  for (attempts = 0; attempts < 25 && (copiedSTOCEld   < 0
                                       || copiedEMAfastJr < 0
                                       || copiedEMAslowJr < 0); attempts++) 
  {
   //Копируем данные индикаторов
   copiedSTOCEld   = CopyBuffer( _handleSTOCEld,   0, 1, 2, _bufferSTOCEld);
   copiedEMAfastJr = CopyBuffer( _handleEMAfastJr, 0, 1, 2, _bufferEMAfastJr);
   copiedEMAslowJr = CopyBuffer( _handleEMAslowJr, 0, 1, 2, _bufferEMAslowJr);
  }  
  if (copiedSTOCEld != 2 || copiedEMAfastJr != 2 || copiedEMAslowJr != 2 )   
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Ошибка заполнения буфера.Error(%d) = %s" 
                                          , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
   return (false);
  }
 }
 return (true); // Нигде не выбило, значит все загрузилось
}
 
//------------------------------------------
// Сигнал Стохастик и ЕМА
//------------------------------------------
int CPointSys::StochasticAndEma(void) 
{
 if(_bufferSTOCEld[1] > _stoc_params.top_level && _bufferSTOCEld[0] < _stoc_params.top_level)
 {
  if(GreatDoubles(_bufferEMAfastJr[1], _bufferEMAslowJr[1]) && GreatDoubles(_bufferEMAslowJr[0], _bufferEMAfastJr[0]))
  {
   if(GreatDoubles(_tick.ask, _bufferEMA3Eld[0] - _base_params.deltaPriceToEMA*_Point))
   {
     //продажа
    log_file.Write(LOG_DEBUG, StringFormat("%s Открыта позиция SELL.", MakeFunctionPrefix(__FUNCTION__)));     
    return(-1);  // типо сигнал на продажу
   }
  }
 }
 if(_bufferSTOCEld[1] < _stoc_params.bottom_level && _bufferSTOCEld[0] > _stoc_params.bottom_level)
 {
  if(GreatDoubles(_bufferEMAslowJr[1], _bufferEMAfastJr[1]) && GreatDoubles(_bufferEMAfastJr[0], _bufferEMAslowJr[0]))
  {
   if(LessDoubles(_tick.bid, _bufferEMA3Eld[0] + _base_params.deltaPriceToEMA*_Point))
   {
     //покупка
    log_file.Write(LOG_DEBUG, StringFormat("%s Открыта позиция BUY.", MakeFunctionPrefix(__FUNCTION__)));     
    return(1);  // типо сигнал на покупку
   }
  }
 }
 return(0);
}

//------------------------------------------
// Сигнал расхождение MACD
//------------------------------------------
