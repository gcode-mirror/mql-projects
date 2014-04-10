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
#include <ColoredTrend/ColoredTrendUtilities.mqh>
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
   int _handleEMA3Eld;             // хэндл для EMA 3 старшего таймфрейма
   int _handleEMAfastEld;          // хэндл EMA fast старшего таймфрейма   
   int _handleEMAfastJr;   // хэндл EMA fast старшего таймфрейма
   int _handleEMAslowJr;   // хэндл EMA fast младшего таймфрейма
   int _handleSTOCEld;     // хэндл Stochastic старшего таймфрейма
   int _handleMACD;        // хэндл MACD
   // буферы индикаторов 
   double _bufferPBI[];            // буфер для PriceBased indicator  
   double _bufferPBIforTrendDirection[];
   double _bufferEMA3Eld[];        // буфер для EMA 3 старшего таймфрейма
   double _bufferEMAfastEld[];     // буфер для EMA fast старшего таймфрейма    
   double _bufferEMAfastJr[];      // буфер для EMA fast младшего таймфрейма
   double _bufferEMAslowJr[];      // буфер для EMA slow младшего таймфрейма
   double _bufferSTOCEld[];        // буфер для Stochastic старшего таймфрейма  
   // буферы цен
   double _bufferHighEld[];        // буфер для цены high на старшем таймфрейме
   double _bufferLowEld[];         // буфер для цены low на старшем таймфрейме   
   
   CisNewBar *_eldNewBar;          // переменная для определения нового бара на eldTF  
   
   // методы вычисления сигналов
   int StochasticAndEma();         // Сигнал разворота ЕМА в зоне перекупленности/перепроданности
   
   int lastTrend;                  // Направление последнего тренда
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
   
 ////// инициализаруем индикаторы
 //---------инициализируем параметры, буферы, индикаторы и прочее
   
 ////// сохраняем внешние параметры   ////// инициализаруем индикаторы
 _handlePBI       = iCustom(Symbol(), Period(), "PriceBasedIndicator", 1000);
 _handleMACD      = iMACD(Symbol(), Period(), _macd_params.fast_EMA_period,  _macd_params.slow_EMA_period, _macd_params.signal_period, _macd_params.applied_price);
 _handleSTOCEld   = iStochastic(NULL, _base_params.eldTF, _stoc_params.kPeriod, _stoc_params.dPeriod, _stoc_params.slow, MODE_SMA, STO_CLOSECLOSE);
 _handleEMA3Eld    = iMA(Symbol(),  _base_params.eldTF, 3,                            0, MODE_EMA, PRICE_CLOSE);
 _handleEMAfastEld = iMA(Symbol(),  _base_params.eldTF, _ema_params.periodEMAfastEld, 0, MODE_EMA, PRICE_CLOSE); 
 _handleEMAfastJr = iMA(Symbol(),  _base_params.jrTF, _ema_params.periodEMAfastJr, 0, MODE_EMA, PRICE_CLOSE);
 _handleEMAslowJr = iMA(Symbol(),  _base_params.jrTF, _ema_params.periodEMAslowJr, 0, MODE_EMA, PRICE_CLOSE);

 if (_handlePBI == INVALID_HANDLE || 
     _handleEMA3Eld    == INVALID_HANDLE ||
     _handleEMAfastEld == INVALID_HANDLE ||
     _handleEMAfastJr == INVALID_HANDLE || 
     _handleEMAslowJr == INVALID_HANDLE || 
     _handleMACD == INVALID_HANDLE || 
     _handleSTOCEld    == INVALID_HANDLE   )
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s INVALID_HANDLE (handleTrend). Error(%d) = %s" 
                                        , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
 }   
            
 // выделяем память под объект класса определения формирования нового бара
 _eldNewBar = new CisNewBar(_base_params.eldTF);
  // порядок элементов в массивах, как в таймсерии
 ArraySetAsSeries( _bufferPBI, true);
 ArraySetAsSeries( _bufferPBIforTrendDirection, true);
 ArraySetAsSeries( _bufferEMAfastJr, true);
 ArraySetAsSeries( _bufferEMAslowJr, true);
 ArraySetAsSeries( _bufferSTOCEld, true);
 ArraySetAsSeries( _bufferHighEld,   true);
 ArraySetAsSeries( _bufferLowEld,    true);
  // изменяем размер буферов
 int bars = Bars(Symbol(), Period());
 ArrayResize( _bufferPBI, 1);
 ArrayResize( _bufferPBIforTrendDirection, bars);
 ArrayResize( _bufferEMAfastJr, 2);
 ArrayResize( _bufferEMAslowJr, 2);
 ArrayResize( _bufferSTOCEld, 1);
 
 int copiedPBI = 0;
 for (int attempts = 0; attempts < 25 && copiedPBI <= 0; attempts++)
 {
  Sleep(100);
  copiedPBI = CopyBuffer(_handlePBI, 4, 0, bars, _bufferPBIforTrendDirection);
 }
 
 lastTrend = MOVE_TYPE_UNKNOWN;
 for(int i = 0; i < bars; i++)
 {
  if (_bufferPBIforTrendDirection[i] == MOVE_TYPE_TREND_UP ||
      _bufferPBIforTrendDirection[i] == MOVE_TYPE_TREND_DOWN ||
      _bufferPBIforTrendDirection[i] == MOVE_TYPE_TREND_UP_FORBIDEN ||
      _bufferPBIforTrendDirection[i] == MOVE_TYPE_TREND_DOWN_FORBIDEN)
  {
   lastTrend = _bufferPBIforTrendDirection[i];
   break;
  }
 }
}

//---------------------------------------------  
// деструктор балльной системы
//---------------------------------------------
 CPointSys::~CPointSys(void)
  {
   delete _eldNewBar;
   // освобождаем индикаторы
   IndicatorRelease(_handlePBI);
   IndicatorRelease(_handleEMAfastEld);
   IndicatorRelease(_handleEMAfastJr);
   IndicatorRelease(_handleEMAslowJr);
   IndicatorRelease(_handleSTOCEld);
   IndicatorRelease(_handleMACD);
   // освобождаем память под буферы
   ArrayFree(_bufferPBI);
   ArrayFree(_bufferEMA3Eld);
   ArrayFree(_bufferEMAfastEld);
   ArrayFree(_bufferEMAfastJr);
   ArrayFree(_bufferEMAslowJr);
   ArrayFree(_bufferHighEld);
   ArrayFree(_bufferLowEld);
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
   points += (lastTrend == MOVE_TYPE_TREND_UP || lastTrend == MOVE_TYPE_TREND_UP_FORBIDEN) ? 1 : -1;  
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
   return ( TrendSignals() );  // вернем сигнал на тренде
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
 // переменные для хранения количества скопированных баров в буферы
 int copiedPBI=-1;
 int copiedSTOCEld=-1;
 int copiedEMA3Eld=-1;
 int copiedEMAfastEld=-1;
 int copiedEMAfastJr=-1;
 int copiedEMAslowJr=-1;
 int copiedHigh=-1;
 int copiedLow=-1;
 int attempts;

 for (attempts = 0; attempts < 25 && copiedPBI < 0; attempts++)
 {
  copiedPBI = CopyBuffer(_handlePBI, 4, 0, 1, _bufferPBI);
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
   copiedEMA3Eld    = CopyBuffer( _handleEMA3Eld,   0, 0, 1, _bufferEMA3Eld);
   copiedEMAfastEld = CopyBuffer( _handleEMAfastEld,0, 1, 2, _bufferEMAfastEld);
   copiedEMAfastJr = CopyBuffer( _handleEMAfastJr, 0, 1, 2, _bufferEMAfastJr);
   copiedEMAslowJr = CopyBuffer( _handleEMAslowJr, 0, 1, 2, _bufferEMAslowJr);
   copiedHigh       = CopyHigh  ( Symbol(),  _base_params.eldTF,  1, 2, _bufferHighEld);
   copiedLow        = CopyLow   ( Symbol(),  _base_params.eldTF,  1, 2, _bufferLowEld); 
  }  
  if (copiedSTOCEld    != 2 ||
      copiedEMA3Eld    != 1 ||
      copiedEMAfastEld != 2 || 
      copiedEMAfastJr  != 2 ||  
      copiedEMAslowJr  != 2 ||
      copiedHigh       != 2 ||
      copiedLow        != 2 )   
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
 return(0);   // нет сигнала
}

//------------------------------------------
// Сигнал расхождение MACD
//------------------------------------------

//------------------------------------------
// Сигнал расхождение на Стохастике
//------------------------------------------

//------------------------------------------
// Сигнал для тренда
//------------------------------------------

 

 int CPointSys::TrendSignals(void)
  {
   if (_bufferPBI[0] == 1)                   //Если направление тренда TREND_UP  
 {
  if (GreatOrEqualDoubles(_bufferEMA3Eld[0] + _base_params.deltaPriceToEMA*_Point, _tick.bid))
  {
  
   if (GreatDoubles(_bufferEMAfastEld[0] + _base_params.deltaPriceToEMA*_Point, _bufferLowEld[0]) || 
       GreatDoubles(_bufferEMAfastEld[1] + _base_params.deltaPriceToEMA*_Point, _bufferLowEld[1]))
   {

    if (GreatDoubles(_bufferEMAslowJr[1], _bufferEMAfastJr[1]) && LessDoubles(_bufferEMAslowJr[0], _bufferEMAfastJr[0]))
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s Открыта позиция BUY.", MakeFunctionPrefix(__FUNCTION__)));
     return (1);  // типо сигнал на покупку
    }
   }
  }
 } //end TREND_UP
 else if (_bufferPBI[0] == 3)               //Если направление тренда TREND_DOWN  
 {
  if (GreatOrEqualDoubles(_tick.ask, _bufferEMA3Eld[0] - _base_params.deltaPriceToEMA*_Point))
  {

   if (GreatDoubles(_bufferHighEld[0], _bufferEMAfastEld[0] - _base_params.deltaPriceToEMA*_Point) || 
       GreatDoubles(_bufferHighEld[1], _bufferEMAfastEld[1] - _base_params.deltaPriceToEMA*_Point))
   {
    if (GreatDoubles(_bufferEMAfastJr[1], _bufferEMAslowJr[1]) && LessDoubles(_bufferEMAfastJr[0], _bufferEMAslowJr[0]))
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s Открыта позиция SELL.", MakeFunctionPrefix(__FUNCTION__)));
     return (-1);  // типо сигнал на продажу
    }
   }
  }
 } //end TREND_DOWN
   return (0); // нет сигнала
  }
  
//------------------------------------------
// Сигнал для коррекции                
//------------------------------------------

int CPointSys::CorrSignals(void)
 {
 if(GreatDoubles(_bufferEMAslowJr[1], _bufferEMAfastJr[1]) && GreatDoubles (_bufferEMAfastJr[0], _bufferEMAslowJr[0]) 
    && _bufferSTOCEld[0] < _stoc_params.bottom_level) //стохастик внизу; пересечение младших EMA снизу вверх
    return(100);     
  return (0); // нет сигнала
 }