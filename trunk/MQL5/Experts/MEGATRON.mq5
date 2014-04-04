//+------------------------------------------------------------------+
//|                                                     MEGATRON.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Эксперт МЕГАТРОН - объединенный дисептикон                       |
//+------------------------------------------------------------------+

//-------- подключение библиотек

#include <Lib CisNewBar.mqh>                // для проверки формирования нового бара
#include <TradeManager/TradeManager.mqh>    // торговая библиотека
#include <POINTSYS/POINTSYS.mqh>            // класс бальной системы

//-------- входные параметры

// параметры таймфреймов
input ENUM_TIMEFRAMES eldTF = PERIOD_H1;
input ENUM_TIMEFRAMES jrTF = PERIOD_M5;                                

//параметры Stochastic 
input int    kPeriod = 5;                                              // К-период стохастика
input int    dPeriod = 3;                                              // D-период стохастика
input int    slow  = 3;                                                // Сглаживание стохастика. Возможные значения от 1 до 3.
input int    top_level = 80;                                           // Top-level стохастка
input int    bottom_level = 20;                                        // Bottom-level стохастика
input int    DEPTH = 100;                                              // глубина поиска расхождения
input int    ALLOW_DEPTH_FOR_PRICE_EXTR = 25;                          // допустимая глубина для экстремума цены

//параметры MACD
input int fast_EMA_period = 12;                                        // быстрый период EMA для MACD
input int slow_EMA_period = 26;                                        // медленный период EMA для MACD
input int signal_period = 9;                                           // период сигнальной линии для MACD

//параметры для EMA
input int    periodEMAfastJr = 15;                                     // период быстрой   EMA
input int    periodEMAslowJr = 9;                                      // период медленной EMA

//параметры сделок  
input double orderVolume = 0.1;                                        // Объём сделки
input int    slOrder = 100;                                            // Stop Loss
input int    tpOrder = 100;                                            // Take Profit
input int    trStop = 100;                                             // Trailing Stop
input int    trStep = 100;                                             // Trailing Step
input int    minProfit = 250;                                          // Minimal Profit 
input bool   useLimitOrders = false;                                   // Использовать Limit ордера
input int    limitPriceDifference = 50;                                // Разнциа для Limit ордеров
input bool   useStopOrders = false;                                    // Использовать Stop ордера
input int    stopPriceDifference = 50;                                 // Разнциа для Stop ордеров

input        ENUM_TRAILING_TYPE  trailingType = TRAILING_TYPE_USUAL;   // тип трейлинга
input bool   useJrEMAExit = false;                                     // будем ли выходить по ЕМА
input int    posLifeTime = 10;                                         // время ожидания сделки в барах
input int    deltaPriceToEMA = 7;                                      // допустимая разница между ценой и EMA для пересечения
input int    deltaEMAtoEMA = 5;                                        // необходимая разница для разворота EMA
input int    waitAfterDiv = 4;                                         // ожидание сделки после расхождения (в барах)
//параметры PriceBased indicator
input int    historyDepth = 40;                                        // глубина истории для расчета
input int    bars=30;                                                  // сколько свечей показывать

// объявление структур данных

EMA_PARAMS    ema_params;     // параметры EMA
MACD_PARAMS   macd_params;    // параметры MACD
STOC_PARAMS   stoc_params;    // параметры стохастика
PBI_PARAMS    pbi_params;     // параметры PriceBased indicator
DEAL_PARAMS   deal_params;    // параметры сделок
BASE_PARAMS   base_params;    // базовые параметры


// глобальные объекты

CTradeManager *ctm;          // указатель на объект класса TradeManager
POINTSYS      *pointsys;     // указатель на объект класса бальной системы


//+------------------------------------------------------------------+
//| функция иницициализации                                          |
//+------------------------------------------------------------------+
int OnInit()
  {

   //------- заполняем структуры данных 
   
   // заполняем парметры EMA
   ema_params.periodEMAfastJr             = periodEMAfastJr;
   ema_params.periodEMAslowJr             = periodEMAslowJr;
   // заполняем параметры MACD
   macd_params.fast_EMA_period            = fast_EMA_period; 
   macd_params.signal_period              = signal_period;
   macd_params.slow_EMA_period            = slow_EMA_period;
   ///////////////////////////////////////////////////////////////
   
   // заполняем параметры Стохастика
   stoc_params.ALLOW_DEPTH_FOR_PRICE_EXTR = ALLOW_DEPTH_FOR_PRICE_EXTR;
   stoc_params.DEPTH                      = DEPTH;
   stoc_params.bottom_level               = bottom_level;
   stoc_params.dPeriod                    = dPeriod;
   stoc_params.kPeriod                    = kPeriod;
   stoc_params.slow                       = slow;
   stoc_params.top_level                  = top_level;
   //////////////////////////////////////////////////////////////
   
   // заполняем параметры PriceBased indicator
   pbi_params.bars                        = bars;
   pbi_params.historyDepth                = historyDepth;
   //////////////////////////////////////////////////////////////
   
   // заполняем параметры сделок
   deal_params.limitPriceDifference       = limitPriceDifference;
   deal_params.minProfit                  = minProfit;
   deal_params.orderVolume                = orderVolume;
   deal_params.slOrder                    = slOrder;
   deal_params.stopPriceDifference        = stopPriceDifference;
   deal_params.tpOrder                    = tpOrder;
   deal_params.trStep                     = trStep;
   deal_params.trStop                     = trStop;
   deal_params.useLimitOrders             = useLimitOrders;
   deal_params.useStopOrders              = useStopOrders;
   //////////////////////////////////////////////////////////////
   
   // заполняем базовые параметры
   base_params.deltaEMAtoEMA              = deltaEMAtoEMA;
   base_params.deltaPriceToEMA            = deltaPriceToEMA;
   base_params.eldTF                      = eldTF;
   base_params.jrTF                       = jrTF;
   base_params.posLifeTime                = posLifeTime;
   base_params.useJrEMAExit               = useJrEMAExit;
   base_params.waitAfterDiv               = waitAfterDiv;
   //------- выделяем память под динамические объекты
   ctm      = new CTradeManager(); // выделяем память под объект класса TradeManager
   pointsys = new POINTSYS(deal_params,base_params,ema_params,macd_params,stoc_params,pbi_params);      // выделяем память под объект класса бальной системы  
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| функция деиницициализации                                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // очищаем память, выделенную под динамические объекты
   delete ctm;      // удаляем объект класса торговой библиотеки
   delete pointsys; // удаляем объект класса Дисептикона
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
int count_bars = 0;

void OnTick()
  {
   // пробуем обновить буферы
   if ( pointsys.UpLoad() == true )
    {
      // проверяем текущее ценовое движение 
      switch ( pointsys.GetMovingType() )
       {
        case MOVE_TYPE_CORRECTION_UP:          // на коррекции
        case MOVE_TYPE_CORRECTION_DOWN:
        
        break;
        case MOVE_TYPE_FLAT:                   // на флэте
        
        break;
        case MOVE_TYPE_TREND_DOWN:            // на тренде
        case MOVE_TYPE_TREND_DOWN_FORBIDEN:
        case MOVE_TYPE_TREND_UP:
        case MOVE_TYPE_TREND_UP_FORBIDEN:
        
        break;
       }
    } 
  }