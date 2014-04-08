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

sinput string time_string="";                                           // параметры таймфреймов
input ENUM_TIMEFRAMES eldTF = PERIOD_H1;
input ENUM_TIMEFRAMES jrTF = PERIOD_M5;                                

sinput string stoc_string="";                                           // параметры Stochastic 
input int    kPeriod = 5;                                               // К-период стохастика
input int    dPeriod = 3;                                               // D-период стохастика
input int    slow  = 3;                                                 // Сглаживание стохастика. Возможные значения от 1 до 3.
input int    top_level = 80;                                            // Top-level стохастка
input int    bottom_level = 20;                                         // Bottom-level стохастика
input int    allow_depth_for_price_extr = 25;                           // допустимая глубина для экстремума цены
input int    depth_stoc = 100;                                          // глубина поиска расхождения

sinput string macd_string="";                                           // параметры MACD
input int fast_EMA_period = 12;                                         // быстрый период EMA для MACD
input int slow_EMA_period = 26;                                         // медленный период EMA для MACD
input int signal_period = 9;                                            // период сигнальной линии для MACD
input int depth_macd = 100;                                             // глубина истории поиска расхождения

sinput string ema_string="";                                            // параметры для EMA
input int    periodEMAfastJr = 9;                                      // период быстрой   EMA
input int    periodEMAslowJr = 15;                                       // период медленной EMA

sinput string pbi_string ="";                                           // параметры PriceBased indicator
input int    historyDepth = 2000;                                       // глубина истории для расчета
input int    bars=30;                                                   // сколько свечей показывать

sinput string deal_string="";                                           // параметры сделок  
input double orderVolume = 0.1;                                         // Объём сделки
input int    slOrder = 100;                                             // Stop Loss
input int    tpOrder = 100;                                             // Take Profit
input int    trStop = 100;                                              // Trailing Stop
input int    trStep = 100;                                              // Trailing Step
input int    minProfit = 250;                                           // Minimal Profit 
input ENUM_USE_PENDING_ORDERS pending_orders_type = USE_LIMIT_ORDERS;   // Тип отложенного ордера                    
input int    priceDifference = 50;                                      // Price Difference

sinput string base_string ="";                                          // базовые параметры робота
input         ENUM_TRAILING_TYPE  trailingType = TRAILING_TYPE_USUAL;   // тип трейлинга
input bool    useJrEMAExit = false;                                     // будем ли выходить по ЕМА
input int     posLifeTime = 10;                                         // время ожидания сделки в барах
input int     deltaPriceToEMA = 7;                                      // допустимая разница между ценой и EMA для пересечения
input int     deltaEMAtoEMA = 5;                                        // необходимая разница для разворота EMA
input int     waitAfterDiv = 4;                                         // ожидание сделки после расхождения (в барах)

// объявление структур данных
sEmaParams    ema_params;          // параметры EMA
sMacdParams   macd_params;         // параметры MACD
sStocParams   stoc_params;         // параметры стохастика
sPbiParams    pbi_params;          // параметры PriceBased indicator
sDealParams   deal_params;          // параметры сделок
sBaseParams   base_params;          // базовые параметры


// глобальные объекты
CTradeManager  *ctm;                // указатель на объект класса TradeManager
CPointSys      *pointsys;           // указатель на объект класса бальной системы

// глобальные системные переменные
string symbol;                       // переменная для хранения символа
ENUM_TIMEFRAMES period;              // переменная для хранения таймфрейма
ENUM_TM_POSITION_TYPE deal_type;     // тип совершения сделки
ENUM_TM_POSITION_TYPE opBuy, opSell; // сигнал на покупку 

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
   macd_params.depth                      = depth_macd;
   ///////////////////////////////////////////////////////////////
   
   // заполняем параметры Стохастика
   stoc_params.allow_depth_for_price_extr = allow_depth_for_price_extr;
   stoc_params.depth                      = depth_stoc;
   stoc_params.bottom_level               = bottom_level;
   stoc_params.dPeriod                    = dPeriod;
   stoc_params.kPeriod                    = kPeriod;
   stoc_params.slow                       = slow;
   stoc_params.top_level                  = top_level;
   //////////////////////////////////////////////////////////////
   
   // заполняем параметры сделок
   deal_params.minProfit                  = minProfit;
   deal_params.orderVolume                = orderVolume;
   deal_params.slOrder                    = slOrder;
   deal_params.tpOrder                    = tpOrder;
   deal_params.trStep                     = trStep;
   deal_params.trStop                     = trStop;
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
   pointsys = new CPointSys(deal_params,base_params,ema_params,macd_params,stoc_params,pbi_params);      // выделяем память под объект класса бальной системы  
   
   // сохраняем символ и период
   
   symbol = _Symbol;
   period = _Period;
   
   switch (pending_orders_type)  //вычисление priceDifference
   {
    case USE_LIMIT_ORDERS: //useLimitsOrders = true;
     opBuy  = OP_BUYLIMIT;
     opSell = OP_SELLLIMIT;
    break;
    case USE_STOP_ORDERS:
     opBuy  = OP_BUYSTOP;
     opSell = OP_SELLSTOP;
    break;
    case USE_NO_ORDERS:
     opBuy  = OP_BUY;
     opSell = OP_SELL;      
    break;
   }     
   
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
void OnTick()
  {
   ctm.OnTick();  
   // пробуем обновить буферы
   deal_type = OP_UNKNOWN;   // сохраняем неизвестный сигнал  
      
     // проверяем текущее ценовое движение 
     switch (pointsys.GetMovingType())
       {
        case MOVE_TYPE_CORRECTION_UP:          // на коррекции
        case MOVE_TYPE_CORRECTION_DOWN:

        break;
        case MOVE_TYPE_FLAT:                   // на флэте
         switch (pointsys.GetFlatSignals())
          {
           case 1:  // сигнал на покупку
            deal_type = opBuy;     
           break;  
           case -1: // сигнал на продажу
            deal_type = opSell;            
           break;
          }          
        break;
        case MOVE_TYPE_TREND_DOWN:             // на тренде
        case MOVE_TYPE_TREND_DOWN_FORBIDEN:
        case MOVE_TYPE_TREND_UP:
        case MOVE_TYPE_TREND_UP_FORBIDEN:
        
        break;
       }
     if (deal_type != OP_UNKNOWN)
       ctm.OpenUniquePosition(symbol,period,deal_type, orderVolume, slOrder, tpOrder, trailingType, minProfit, trStop, trStep, priceDifference);        

  }