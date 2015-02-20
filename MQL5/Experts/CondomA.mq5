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
#include <Lib CisNewBar.mqh>                // для проверки формирования нового бара
#include <CompareDoubles.mqh>               // для сравнения действительных чисел
#include <CLog.mqh>                         // для лога
// входные параметры робота
input int depth = 20;     
input double lot = 1.0;      // лот 
// переменные
double max_price;            // максимальная цена канала
double min_price;            // минимальная цена канала
double h;                    // ширина канала
double price_bid;            // цена bid
double price_ask;            // цена ask
double average_price;        // значение средней цены на момент получения сигнала о скачке (присваивание переменных wait_for_sell или wait_for_buy)
bool wait_for_sell=false;    // флаг ожидания условия открытия на SELL
bool wait_for_buy=false;     // флаг ожидания условия открытия на BUY
int mode=0;                  // режим работы робота
int opened_position = 0;     // флаг открытой позиции (0 - нет позиции, 1 - buy, (-1) - sell)
int last_move_bars;          // количество баров последнего движения
int count_bars_to_close = 0; // количество баров от пробития до открытия позиции
// массивы цен последних 4-х экстремумов для определения бокового движения
double extrHigh[2];          // массив экстремумов High
double extrLow[2];           // массив экстремумов Low
// хэндлы
int handleDE;                // хэндл DrawExtremums
// объекты классов
CTradeManager *ctm;          // объект торгового класса
CisNewBar *isNewBar;         // появление нового бара

// структуры позиции и трейлинга
SPositionInfo pos_info;      // структура информации о позиции
STrailing     trailing;      // структура информации о трейлинге

int OnInit()
  {
   // создаем объект торгового класса для открытия и закрытия позиций
   ctm = new CTradeManager();
   if (ctm == NULL)
    {
     Print("Не удалось создать объект класса CTradeManager");
     return (INIT_FAILED);
    }    
   // создаем объект CIsNewBar
   isNewBar = new CisNewBar(_Symbol,_Period);
   if (isNewBar == NULL)
    {
     Print("Не удалось создать объект класса CisNewBar");
     return (INIT_FAILED);
    }
   // создаем хэндл индикатора DrawExtremums
   handleDE = iCustom(_Symbol,_Period,"DE");
   if (handleDE == INVALID_HANDLE)
    {
     // не удалось создать хэндл индикатора DrawExtremums
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
   delete isNewBar;
  }

void OnTick()
  {
   ctm.OnTick();
   // получаем текущее значение цен 
   price_bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   price_ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   // если пришел новый бар, то увеличиваем счетчик баров на единицу
   if (isNewBar.isNewBar() > 0)
    count_bars_to_close++;
    
   if (ctm.GetPositionCount() == 0)
    {
     opened_position = 0;   
    }
     // если удалось вычислить максимум и минимум
     if (GetMaxMinChannel())
      {
       // если цена bid резко двинулась вверх и расстояние от нее до уровня как минимум 2 раза больше, чем ширина канала
       if ( GreatDoubles(price_bid-max_price,/*h*2*/ h) )
        {
         // то переходим в режим отскока для открытия на SELL
         wait_for_sell = true;   
         wait_for_buy = false;
         // вычисление средней цены для дальнейшего вычисления тейк профита 
         average_price = (max_price + min_price)/2;
         // обнуляем счетчик баров для вычисления шаблона 
         count_bars_to_close = 0;
        }
       // если цена ask резко двинулась вниз и расстояние от нее до уровня как минимум 2 раза больше, чем ширина канала
       if ( GreatDoubles(min_price-price_ask,/*h*2*/h) )
        {
         // то переходим в режим отскока для открытия на BUY
         wait_for_buy = true; 
         wait_for_sell = false;   
         // вычисление средней цены для дальнейшего вычисления тейк профита 
         average_price = (max_price + min_price)/2;  
         // обнуляем счетчик баров для вычисления шаблона
         count_bars_to_close = 0;                
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
         opened_position = -1;
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
         opened_position = 1;
        }
      }  
    /*      
    // обработка закрытия позиций
    if (opened_position != 0)
     {     
      // если получили сигнал о том, что нужно закрывать позицию
      if (IsBeatenExtremum (opened_position))
       {
        ctm.ClosePosition(0);
       }
     }   
     */ 
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
  last_move_bars = depth;  // сохраняем длину последнего движения
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
    return ( int ( MathAbs(price_ask - ( (average_price)/2))/_Point ) );
   }
  if (type == -1)
   {
    return ( int ( MathAbs(price_bid - ( (average_price)/2))/_Point ) );   
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
    if (LessDoubles(price_ask,price_low[1]) && GreatDoubles(price_high[1],price_high[0]) && GreatDoubles(price_high[1],price_high[2]) )
     {
      return (true);
     } 
   }
  if (type == -1)
   {
    // условие закрытие позиции SELL  (завтра переделать на противоположную)
    if (GreatDoubles(price_bid,price_high[1]) && LessDoubles(price_low[1],price_low[0]) && GreatDoubles(price_low[1],price_low[2]) )
     {
      return (true);
     }    
   }
  return (false);
 } 
 
// функция загружает цены последних 4-х экстремумов
bool UploadLastExtremums ()
 {
  int ind;
  int bars = Bars(_Symbol,_Period);
  int extrCountHigh=0;
  int extrCountLow=0;
  double extrHigh[];
  double extrLow[];
  for (ind=0;ind<bars;)
   {
    if (CopyBuffer(handleDE,0,ind,1,extrHigh) < 1 || CopyBuffer(handleDE,1,ind,1,extrLow) < 1)
     continue;
    // если был найден high экстремум
    if (extrHigh[ind] != 0.0)
     {
      extrHigh[extrCountHigh] = extrHigh[ind];
      extrCountHigh++;
     }
    // если был найден low экстремум
    if (extrLow[ind] != 0.0)
     {
      extrLow[extrCountLow] = extrLow[ind];
      extrCountLow++;
     }     
    // если было найдено 4 последних экстремума
    if (extrCountHigh == 2 && extrCountLow == 2)
     return (true);
    ind++;
   }
  return (false);
 }
 
// функция проверяет по 4-м экстремумам, не является ли последнее движение флэтом
bool IsFlatNow ()
 {
  // если направленное движение вверх
  if ( GreatDoubles (extrHigh[0],extrHigh[1]) && GreatDoubles(extrLow[0],extrLow[1]) )
   return (false);
  // если направленное движение вниз
  if ( LessDoubles (extrHigh[0],extrHigh[1]) && LessDoubles(extrLow[0],extrLow[1]) )
   return (false);   
  return (true);
 }