//+------------------------------------------------------------------+
//|                                                      ONODERA.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

// подсключение библиотек
#include <Divergence\divergenceMACD.mqh>  // подключение расхождения 
#include <TradeManager\TradeManager.mqh>  // подключение торговой библиотеки
#include <Lib CisNewBar.mqh>              // для проверки формирования нового бара


//+------------------------------------------------------------------+
//| Эксперт, основанный на расхождении MACD                          |
//+------------------------------------------------------------------+

// входные параметры

sinput string base_param                           = "";            // БАЗОВЫЕ ПАРАМЕТРЫ ЭКСПЕРТА
input  int    StopLoss                             = 150;           // Стоп Лосс
input  int    TakeProfit                           = 150;           // Тейк Профит
input  double Lot                                  = 1;             // Лот
input  ENUM_USE_PENDING_ORDERS pending_orders_type = USE_NO_ORDERS; // Тип отложенного ордера                    
input  int    priceDifference                      = 50;            // Price Difference

sinput string macd_param                           = "";            // ПАРАМЕТРЫ MACD
input  int fast_EMA_period                         = 12;            // быстрый период EMA для MACD
input  int slow_EMA_period                         = 26;            // медленный период EMA для MACD
input  int signal_period                           = 9;             // период сигнальной линии для MACD
input  ENUM_APPLIED_PRICE applied_price            = PRICE_CLOSE;   // тип цены  


// объекты
CTradeManager * ctm;                                     // указатель на объект торговой библиотеки
static CisNewBar isNewBar(_Symbol, _Period);             // для проверки формирования нового бара

// хэндлы индикаторов 
int handleMACD;                                          // хэндл MACD
      
// переменные эксперта
int divSignal;                                           // сигнал на расхождение
double currentPrice;                                     // текущая цена
ENUM_TM_POSITION_TYPE opBuy,opSell;                      // типы ордеров 

int OnInit()
  {
   // выделяем память под объект тороговой библиотеки
   ctm = new CTradeManager(); 
   // создаем хэндл индикатора MACD
   handleMACD = iMACD(_Symbol,_Period,fast_EMA_period,slow_EMA_period,signal_period,applied_price);
   if ( handleMACD == INVALID_HANDLE )
     {
       Print("Ошибка при инициализации эксперта ONODERA. Не удалось создать хэндл MACD");
       return(INIT_FAILED);
     }
   // сохранение типов ордеров
   switch (pending_orders_type)  
     {
      case USE_LIMIT_ORDERS: 
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

void OnDeinit(const int reason)
  {
   // удаляем объект класса TradeManager
   delete ctm;
   // удаляем индикатор MACD
   IndicatorRelease(handleMACD);
  }

void OnTick()
  {
    
    // если сформирован новый бар
    if(isNewBar.isNewBar() > 0)
     {
       divSignal = divergenceMACD(handleMACD,_Symbol,_Period);   // получаем сигнал расхождения
        if (divSignal == 1)  // получили расхождение на покупку
         { 
            currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
            ctm.OpenUniquePosition(_Symbol,_Period,opBuy,Lot,StopLoss,TakeProfit,0,0,0,0,0,priceDifference);
         }
        if (divSignal == -1) // получили расхождение на продажу
         {
            currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);       
            ctm.OpenUniquePosition(_Symbol,_Period,opBuy,Lot,StopLoss,TakeProfit,0,0,0,0,0,priceDifference);                 
         }
        
     }     
  }