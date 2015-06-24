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
   CisNewBar *_curNewBar;          // переменная для определения нового бара на текущем ТФ  
   // методы вычисления сигналов
   int StochasticAndEma();         // Сигнал разворота ЕМА в зоне перекупленности/перепроданности
   int CompareEMAWithPriceEld_AND_CrossEMAJr(); // 
   int CorrSignals();
   ENUM_MOVE_TYPE lastTrend;                  // Направление последнего тренда
  public:

  // методы получения торговых сигналов на основе балльной системы
   int  GetFlatSignals  ();        // получение торгового сигнала на Флэте
   int  GetTrendSignals ();        // получение торгового сигнала на тренде
   int  GetCorrSignals  ();        // получение торгового сигнала на коррекции  
  // системные методы
   bool  isUpLoaded();              // метод загрузки (обновления) буферов в класс. Возвращает true, если всё успешно
   int GetMovingType() {return((int)_bufferPBI[0]);};  // для получения типа движения 
  // конструкторы и дестрикторы класса Дисептикона
   CPointSys (sBaseParams &base_params,sEmaParams &ema_params,sMacdParams &macd_params,sStocParams &stoc_params,sPbiParams &pbi_params);      // конструктор класса
   ~CPointSys ();      // деструктор класса 
 };

//--------------------------------------
// конструктор балльной системы
//--------------------------------------
CPointSys::CPointSys(sBaseParams &base_params,sEmaParams &ema_params,sMacdParams &macd_params,sStocParams &stoc_params,sPbiParams &pbi_params)
{
 Print("Конструтор PointSystem");
 //---------инициализируем параметры, буферы, индикаторы и прочее
 _symbol = Symbol();
 lastTrend = 0;     // последнего тренда пока еще не было
 ////// сохраняем внешние параметры
 _base_params = base_params;
 _ema_params  = ema_params;
 _macd_params = macd_params;
 _stoc_params = stoc_params;
 _pbi_params  = pbi_params;
               
 // выделяем память под объект класса определения формирования нового бара
 _eldNewBar = new CisNewBar(_base_params.eldTF);
 _curNewBar = new CisNewBar(_base_params.curTF);
  // порядок элементов в массивах, как в таймсерии
 ArraySetAsSeries( _bufferPBI, true);
 ArraySetAsSeries( _bufferPBIforTrendDirection, true);
 ArraySetAsSeries( _bufferEMAfastJr, true);
 ArraySetAsSeries( _bufferEMAslowJr, true);
 ArraySetAsSeries( _bufferSTOCEld, true);
 ArraySetAsSeries( _bufferHighEld,   true);
 ArraySetAsSeries( _bufferLowEld,    true);
  // изменяем размер буферов
 //int bars = Bars(Symbol(), Period());
 ArrayResize( _bufferPBI, 1);
 ArrayResize( _bufferPBIforTrendDirection, _pbi_params.historyDepth);
 ArrayResize( _bufferEMAfastJr, 2);
 ArrayResize( _bufferEMAslowJr, 2);
 ArrayResize( _bufferSTOCEld, 1);
 
 //int tmp_handle = iCustom(Symbol(), Period(), "PriceBasedIndicator", 1000, 1, 1.5);
}

//---------------------------------------------  
// деструктор балльной системы
//---------------------------------------------
 CPointSys::~CPointSys(void)
  {
   delete _eldNewBar;
   // освобождаем память под буферы
   ArrayFree(_bufferPBI);
   ArrayFree( _bufferPBIforTrendDirection);   
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
  static int dm = 0, ds = 0;
  int points = 0; 
  SymbolInfoTick(_symbol, _tick); 

  if (isUpLoaded ())     // если данные индикатора успешно прогрузились
  {
   if (_curNewBar.isNewBar())
   {
    dm = divergenceMACD(_macd_params.handleMACD, Symbol(), Period());
    ds = divergenceSTOC(_stoc_params.handleStochastic, Symbol(), Period(), _stoc_params.top_level, _stoc_params.bottom_level);
   }
   points += dm;
   points += ds;
   //points += lastTrend;
   if (MathAbs(points) >= 1)
   {
    Print("Points=",points);  
    dm = 0;
    ds = 0;
   }
  }
  return (points); 
 }

//---------------------------------------------------
// Вычисляем сигнал на тренде
//--------------------------------------------------- 
int  CPointSys::GetTrendSignals(void)
{
 int points = 0;
 SymbolInfoTick(Symbol(), _tick);
 
 if ( isUpLoaded () )   // пытаемся прогрузить индикаторы
 {
   points+= CompareEMAWithPriceEld_AND_CrossEMAJr();  // прибавляем сигнал 
 }
 return (points); // возвращаем количество баллов
} 

//---------------------------------------------------
// Вычисляем сигнал на коррекции
//---------------------------------------------------  
int CPointSys::GetCorrSignals(void)
{
 int points = 0;
 SymbolInfoTick(Symbol(), _tick);
 if ( isUpLoaded () ) // если удалось прогрузить индикаторы
 {
   points+= CorrSignals();  // прибавляем сигнал
 }
 return (points); // возвращаем количество баллов
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
 int copiedEMAfast =-1;
 int copiedEMAfastJr=-1;
 int copiedEMAslowJr=-1;
 int copiedHigh=-1;
 int copiedLow=-1;
 int attempts;
 
 if (lastTrend == 0)
 {
  for(attempts = 0; attempts < 25; attempts++)
  {
   Sleep(100);
   copiedPBI = CopyBuffer(_pbi_params.handlePBI, 4, 0, _pbi_params.historyDepth, _bufferPBIforTrendDirection);
  }
  if (copiedPBI < 0)
  {
   PrintFormat("%s Не удалось скопировать буфер _bufferPBIforTrendDirection", MakeFunctionPrefix(__FUNCTION__));
   return(false);
  }
  
  for (int i = 0; i < _pbi_params.historyDepth; i++)
  {
   if (_bufferPBIforTrendDirection[i] == 1 ||   // если последний тренд ВВЕРХ
       _bufferPBIforTrendDirection[i] == 2 )
   {
    lastTrend = 1;
    break;
   }
   if (_bufferPBIforTrendDirection[i] == 3 ||   // если последний тренд ВНИЗ
       _bufferPBIforTrendDirection[i] == 4 ) 
   {
    lastTrend = -1;
    break;
   }
  }
 }
 
 for(attempts = 0; attempts < 25; attempts++)
 {
  Sleep(100);
  copiedPBI = CopyBuffer(_pbi_params.handlePBI, 4, 0, 1, _bufferPBI);
 }
 if (copiedPBI < 0)
 {
  PrintFormat("%s Не удалось скопировать буфер PBI", MakeFunctionPrefix(__FUNCTION__));
  return(false);
 }
 
 if (_bufferPBI[0] == 1 ||   // если последний тренд ВВЕРХ
     _bufferPBI[0] == 2 )
   {
     lastTrend = 1;
   }
 if (_bufferPBI[0] == 3 ||   // если последний тренд ВНИЗ
     _bufferPBI[0] == 4 ) 
    {
     lastTrend = -1;
    }
 
 if (_eldNewBar.isNewBar() > 0)      //на каждом новом баре старшего TF
 {
  for (attempts = 0; attempts < 25 && (copiedSTOCEld   < 0
                                       || copiedEMAfastJr < 0
                                       || copiedEMAslowJr < 0); attempts++) 
  {
   //Копируем данные индикаторов
   copiedSTOCEld   = CopyBuffer( _stoc_params.handleStochastic,   0, 1, 2, _bufferSTOCEld);
   copiedEMA3Eld   = CopyBuffer( _ema_params.handleEMA3,   0, 0, 1, _bufferEMA3Eld);
   copiedEMAfast   = CopyBuffer( _ema_params.handleEMAfast,0, 1, 2, _bufferEMAfastEld);
   copiedEMAfastJr = CopyBuffer( _ema_params.handleEMAfastJr, 0, 1, 2, _bufferEMAfastJr);
   copiedEMAslowJr = CopyBuffer( _ema_params.handleEMAslowJr, 0, 1, 2, _bufferEMAslowJr);
   copiedHigh      = CopyHigh  ( Symbol(),  _base_params.eldTF,  1, 2, _bufferHighEld);
   copiedLow       = CopyLow   ( Symbol(),  _base_params.eldTF,  1, 2, _bufferLowEld); 
  }  
  if (copiedSTOCEld    != 2 ||
      copiedEMA3Eld    != 1 ||
      copiedEMAfast    != 2 || 
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
    return(1);  // типо сигнал на покупку
   }
  }
 }
 return(0);   // нет сигнала
}

//------------------------------------------
// Сигнал для тренда
//------------------------------------------
int CPointSys::CompareEMAWithPriceEld_AND_CrossEMAJr(void)
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
     return (1);  // типо сигнал на покупку
    }
   }
  }
 } //end TREND_UP
 else if (_bufferPBI[0] == 3)               //Если направление тренда TREND_DOWN  
 {
  if(GreatOrEqualDoubles(_tick.ask, _bufferEMA3Eld[0] - _base_params.deltaPriceToEMA*_Point))
  {

   if (GreatDoubles(_bufferHighEld[0], _bufferEMAfastEld[0] - _base_params.deltaPriceToEMA*_Point) || 
       GreatDoubles(_bufferHighEld[1], _bufferEMAfastEld[1] - _base_params.deltaPriceToEMA*_Point))
   {
    if (GreatDoubles(_bufferEMAfastJr[1], _bufferEMAslowJr[1]) && LessDoubles(_bufferEMAfastJr[0], _bufferEMAslowJr[0]))
    {
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
    return(1);  
 
  return (0); // нет сигнала
 }
