//+------------------------------------------------------------------+
//|                                                      CondomA.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Шаблон переходного периода категории А                           |
//+------------------------------------------------------------------+

// подключение необходимых библиотек
#include <TradeManager/TradeManager.mqh>    // торговая библиотека
#include <CompareDoubles.mqh>               // для сравнения действительных чисел
#include <DrawExtremums/CExtrContainer.mqh> // контейнер экстремумов
#include <SystemLib/IndicatorManager.mqh>   // библиотека по работе с индикаторами
#include <CLog.mqh>                         // для лога
// входные параметры робота
input int depth = 20;     
input double lot = 1.0;   // лот 
// переменные
double max_price;         // максимальная цена канала
double min_price;         // минимальная цена канала
double h;                 // ширина канала
double price_bid;         // цена bid
double price_ask;         // цена ask
bool wait_for_sell=false; // флаг ожидания условия открытия на SELL
bool wait_for_buy=false;  // флаг ожидания условия открытия на BUY
int mode=0;               // режим работы робота
// объекты классов
CTradeManager *ctm;     // объект торгового класса
// структуры позиции и трейлинга
SPositionInfo pos_info; // структура информации о позиции
STrailing     trailing; // структура информации о трейлинге

int OnInit()
  {
   // создаем объект торгового класса для открытия и закрытия позиций
   ctm = new CTradeManager();
   if (ctm == NULL)
    {
     Print("Не удалось создать объект класса CTradeManager");
     return (INIT_FAILED);
    }    
   // заполняем поля позиции
   pos_info.volume = lot;
   pos_info.expiration = 0;
   // заполняем 
   trailing.trailingType = TRAILING_TYPE_NONE;
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   // удаляем объекты
   delete ctm;
  }

void OnTick()
  {
   // получаем текущее значение цен 
   price_bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   price_ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   // если удалось вычислить максимум и минимум
   if (GetMaxMinChannel())
    {
     // если цена bid резко двинулась вверх и расстояние от нее до уровня как минимум 2 раза больше, чем ширина канала
     if ( GreatDoubles(price_bid-max_price,/*h*2*/ h) )
      {
       // то переходим в режим отскока для открытия на SELL
       wait_for_sell = true;   
       wait_for_buy = false;      
      }
     // если цена ask резко двинулась вниз и расстояние от нее до уровня как минимум 2 раза больше, чем ширина канала
     if ( GreatDoubles(min_price-price_ask,/*h*2*/h) )
      {
       // то переходим в режим отскока для открытия на BUY
       wait_for_buy = true; 
       wait_for_sell = false;            
      }        
    }         
   // если перешли в режим ожидания отбития для открытия позиции на SELL
   if (wait_for_sell)
    {
     // если удалось пробить последние два бара 
     if (IsBeatenBars(-1))
      {
       // вычисляем стоп лосс, тейк профит и открываем позицию на SELL
       pos_info.type = OP_SELL;
       pos_info.sl = CountStopLoss(-1);       
       pos_info.tp = CountTakeProfit(-1);
       pos_info.priceDifference = 0;     
       ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing); 
       wait_for_sell = false;     
       wait_for_buy = false;  
      }
    } 
   // если перешли в режим ожидания отбития для открытия позиции на BUY
   if (wait_for_buy)
    {
     // если удалось пробить последние два бара
     if (IsBeatenBars(1))
      {
       // вычисляем стоп лосс, тейк профит и открываем позицию на BUY
       pos_info.type = OP_BUY;
       pos_info.sl = CountStopLoss(1);       
       pos_info.tp = CountTakeProfit(1);
       pos_info.priceDifference = 0;       
       ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);    
       wait_for_buy = false;
       wait_for_sell = false;
      }
    }
  }
  
// кодирование дополнительных функций робота
bool GetMaxMinChannel ()
 {
  // на данном этапа вчисляет минимум и максимум просто на заданную глубину
  int copied_high;
  int copied_low;
  double price_high[];
  double price_low[];
  for(int i=0;i<5;i++)
   {
    copied_high = CopyHigh(_Symbol,_Period,1,depth,price_high);
    copied_low  = CopyLow(_Symbol,_Period,1,depth,price_low);
    Sleep(100);
   }
  if (copied_high < depth || copied_low < depth)
   {
    Print("Не удалось прогрузить буферы цен");
    return (false);
   }
  // иначе вычисляем максимум и минимум на заданных массивах
  max_price = price_high[ArrayMaximum(price_high)]; 
  min_price = price_low[ArrayMinimum(price_low)];
  h = max_price - min_price;
  // Comment("Максимальная цена = ",DoubleToString(max_price)," минимальная цена = ",DoubleToString(min_price) );
  return (true);
 }

// вычисляет стоп лосс
int CountStopLoss (int type)
 {
  int copied;
  double prices[];
  if (type == 1)
   {
    copied = CopyLow(_Symbol,_Period,1,2,prices);
    if (copied < 2)
     {
      Print("Не удалось скопировать цены");
      return (0);
     } 
    // ставим стоп лосс на уровне минимума
    return ( int( (price_bid-prices[ArrayMinimum(prices)])/_Point) + 30 );   
   }
  if (type == -1)
   {
    copied = CopyHigh(_Symbol,_Period,1,2,prices);
    if (copied < 2)
     {
      Print("Не удалось скопировать цены");
      return (0);
     } 
    // ставим стоп лосс на уровне максимума
    return ( int( (prices[ArrayMaximum(prices)] - price_ask)/_Point) + 30 );
   }
  return (0);
 }
  
// вычисляет тейк профит
int CountTakeProfit (int type)
 {
  if (type == 1)
   {
    return ( int ( MathAbs(price_ask - ( (max_price+min_price)/2))/_Point ) );
   }
  if (type == -1)
   {
    return ( int ( MathAbs(price_bid - ( (max_price+min_price)/2))/_Point ) );   
   }
  return (0);
 }
  
// функция подсчета пробития последних двух баров
bool IsBeatenBars (int type)
 {
  int copiedBars;
  double prices[];
  if (type == 1)  // если нужно проверить пробитие на BUY
   {
     copiedBars = CopyHigh(_Symbol,_Period,1,2,prices);
     if (copiedBars < 2)
      {
       Print("Не удалось скопировать цены");
       return (false);
      }
     if ( GreatDoubles(price_bid,prices[0]) && GreatDoubles(price_bid,prices[1]) )
      {
       return (true);  // говорим, что успешно пробили последние два максимума
      }     
   }
  if (type == -1)  // если нужно проверить пробитие на SELL
   {
     copiedBars = CopyLow(_Symbol,_Period,1,2,prices);
     if (copiedBars < 2)
      {
       Print("Не удалось скопировать цены");
       return (false);
      }
     if ( LessDoubles(price_ask,prices[0]) && LessDoubles(price_ask,prices[1]) )
      {
       return (true);  // говорим, что успешно пробили последние два максимума
      }
   }
   return (false);  // ничего не пробили
 }
 
// функция для закрытия позиции по экстремуму
bool IsBeatenExtremum (int type)
 {
  int copied_high;
  int copied_low;
  double price_high[];
  double price_low[];
  copied_high = CopyHigh(_Symbol,_Period,0,3,price_high);
  copied_low  = CopyLow(_Symbol,_Period,0,3,price_low);
  if (copied_high < 3 || copied_low < 3)
   {
    Print("Не удалось прогрузить буферы цен");
    return (false);
   }
  if (type == 1)
   {
    // условие закрытие позиции BUY
    if (LessDoubles(price_ask,price_low[1]) && GreatDoubles(price_high[1],price_high[0]) && GreatDoubles(price_high[1],price_high[2])
     {
      return (true);
     } 
   }
  if (type == -1)
   {
    // условие закрытие позиции SELL  (завтра переделать на противоположную)
    if (LessDoubles(price_ask,price_low[1]) && GreatDoubles(price_high[1],price_high[0]) && GreatDoubles(price_high[1],price_high[2])
     {
      return (true);
     }    
   }
  return (false);
 }