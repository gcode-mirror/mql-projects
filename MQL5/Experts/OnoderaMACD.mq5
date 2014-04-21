//+------------------------------------------------------------------+
//|                                                      ONODERA.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

// подсключение библиотек 
#include <TradeManager\TradeManager.mqh>        // подключение торговой библиотеки
#include <Lib CisNewBar.mqh>                    // для проверки формирования нового бара
#include <CompareDoubles.mqh>                   // для проверки соотношения  цен


//+------------------------------------------------------------------+
//| Эксперт, основанный на расхождении MACD                          |
//+------------------------------------------------------------------+

// входные параметры

sinput string base_param                           = "";            // БАЗОВЫЕ ПАРАМЕТРЫ ЭКСПЕРТА
input  int    StopLoss                             = 0;             // Стоп Лосс
input  int    TakeProfit                           = 0;             // Тейк Профит
input  double Lot                                  = 1;             // Лот
input  ENUM_USE_PENDING_ORDERS pending_orders_type = USE_NO_ORDERS; // Тип отложенного ордера                    
input  int    priceDifference                      = 50;            // Price Difference

sinput string macd_string                          = "";            // ПАРАМЕТРЫ MACD

// объекты
CTradeManager * ctm;                                                // указатель на объект торговой библиотеки
static CisNewBar isNewBar(_Symbol, _Period);                        // для проверки формирования нового бара

// хэндлы индикаторов 
int handleMACD;                                                     // хэндл MACD

// переменные эксперта
int divSignal;                                                      // сигнал на расхождение
double currentPrice;                                                // текущая цена
ENUM_TM_POSITION_TYPE opBuy,opSell;                                 // типы ордеров 

double tmpBuffer[];

int OnInit()
{
 // выделяем память под объект тороговой библиотеки
 ctm = new CTradeManager(); 
 // создаем хэндл индикатора MACD
 handleMACD = iCustom (_Symbol,_Period,"smydMACD");   
   
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
 // удаляем индикатор 
 IndicatorRelease(handleMACD);
}

void OnTick()
{
 int copiedMACD = -1;
 // если сформирован новый бар
 if (isNewBar.isNewBar() > 0)
  {
 
   //divSignal = divergenceSTOC(handleStochastic,_Symbol,_Period,top_level,bottom_level);  // получаем сигнал расхождения
   copiedMACD = CopyBuffer(handleMACD,1,0,1,tmpBuffer);
   if (copiedMACD < 1)
    {
     PrintFormat("Не удалось прогрузить все буферы Error=%d",GetLastError());
     return;
    }    
   if ( EqualDoubles(tmpBuffer[0],1.0))  // получили расхождение на покупку
     { 
      currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      ctm.OpenUniquePosition(_Symbol,_Period,opSell,Lot,StopLoss,TakeProfit,0,0,0,0,0,priceDifference);
     }
   if ( EqualDoubles(tmpBuffer[0],-1.0)) // получили расхождение на продажу
     {
      currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);       
      ctm.OpenUniquePosition(_Symbol,_Period,opBuy,Lot,StopLoss,TakeProfit,0,0,0,0,0,priceDifference);                 
     }
   }  
}