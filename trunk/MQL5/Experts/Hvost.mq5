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
#include <SystemLib/IndicatorManager.mqh>   // библиотека по работе с индикаторами
#include <CLog.mqh>                         // для лога

#include <ChartObjects/ChartObjectsLines.mqh>      // для рисования линий расхождения

// входные параметры робота
input int    depth        = 20;     // глубина      
input double lot          = 1.0;    // лот 

// переменные
double max_price;            // максимальная цена канала
double min_price;            // минимальная цена канала
double h;                    // ширина канала
double price_bid;            // текущая цена bid
double price_ask;            // текущая цена ask
double prev_price_bid=0;     // предыдущая цена bid
double prev_price_ask=0;     // предыдущая цена ask
double average_price;        // значение средней цены на момент получения сигнала о скачке (присваивание переменных wait_for_sell или wait_for_buy)
bool wait_for_sell=false;    // флаг ожидания условия открытия на SELL
bool wait_for_buy=false;     // флаг ожидания условия открытия на BUY
bool is_flat_now;            // флаг, показывающий, флэт ли сейчас на графике или нет 
int opened_position = 0;     // флаг открытой позиции (0 - нет позиции, 1 - buy, (-1) - sell)
ENUM_TIMEFRAMES periodEld;   // период старшего таймфрейма
// переменные для хранения времени движения цены
datetime signal_time;        // время получения сигнала пробития ценой уровня на расстояние H
datetime open_pos_time;      // время открытия позиции
// массивы цен последних 4-х экстремумов для определения бокового движения
double extrHigh[2];          // массив экстремумов High (0 младше 1)
double extrLow[2];           // массив экстремумов Low (0 младше 1)     
// хэндлы индикаторов
int handleDE;                // хэндл DrawExtremums 
// объекты классов
CTradeManager *ctm;          // объект торгового класса
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
   // привязка индикатора DrawExtremums 
   handleDE = DoesIndicatorExist(_Symbol,_Period,"DrawExtremums");
   if (handleDE == INVALID_HANDLE)
    {
     handleDE = iCustom(_Symbol,_Period,"DrawExtremums");
     if (handleDE == INVALID_HANDLE)
      {
       Print("Не удалось создать хэндл индикатора ");
       return (INIT_FAILED);
      }
     SetIndicatorByHandle(_Symbol,_Period,handleDE);
    }
   // при первом запуске эксперта определяем движение
   if (UploadLastExtremums ())
    {
     is_flat_now = IsFlatNow(); 
     // если вычисленное движение является флэтом
     if (is_flat_now)
      {
       CountMaxMinChannel (); // то вычисляем  максимум, минимум и ширину канала движения
       // вычисление средней цены для дальнейшего вычисления тейк профита 
       average_price = (max_price + min_price)/2;            
      }
    }
   // сохраняем период страшего таймфрейма 
   periodEld = GetTopTimeframe(_Period);   // заменить на функцию, которая определяет старший ТФ по отношению к текущему
   // заполняем поля позиции
   pos_info.volume = lot;
   pos_info.expiration = 0;
   // заполняем 
   trailing.trailingType = TRAILING_TYPE_NONE;
      
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   Print("Код ошибки = ",reason);
   // удаляем объекты
   delete ctm;
  }

void OnTick()
  { 
   ctm.OnTick();
   // сохраняем предыдущие значения цен
   prev_price_ask = price_ask;
   prev_price_bid = price_bid;
   // получаем текущее значение цен 
   price_bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   price_ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   
   // если нет открытых позиций то сбрасываем тип позиции на нуль
   if (ctm.GetPositionCount() == 0)
    {
     opened_position = 0;   
    }
   
   // если текущее движение - flat
   if (is_flat_now)
      {        
       // если цена bid отошла вверх и расстояние от нее до уровня как минимум 2 раза больше, чем ширина канала
       if ( GreatDoubles(price_bid-max_price,h)  && LessOrEqualDoubles(prev_price_bid-max_price,h) && !wait_for_sell && opened_position!=-1 )
        {               
         // то переходим в режим отскока для открытия на SELL
         wait_for_sell = true;   
         wait_for_buy = false;
         // сохраняем время получения сигнала пробития уровня движения цены
         signal_time = TimeCurrent(); 
         Print("Цена отошла вверх от уровня high[0]=",DoubleToString(extrHigh[0],5)," high[1]=",DoubleToString(extrHigh[1],5)," low[0]=",DoubleToString(extrLow[0],5)," low[1]=",DoubleToString(extrLow[1],5)," bid=",DoubleToString(price_bid)," prev_bid=",DoubleToString(prev_price_bid,5)," h=",DoubleToString(h,5) );
        }
       // если цена ask отошла вниз и расстояние от нее до уровня как минимум 2 раза больше, чем ширина канала
       if ( GreatDoubles(min_price-price_ask,h) && LessOrEqualDoubles(min_price-prev_price_ask,h) && !wait_for_buy && opened_position!=1 )
        {
         // то переходим в режим отскока для открытия на BUY
         wait_for_buy = true; 
         wait_for_sell = false;    
         // сохраняем время получения сигнала пробития уровня движения цены
         signal_time = TimeCurrent();   
         Print("Цена отошла вниз от уровня high[0]=",DoubleToString(extrHigh[0],5)," high[1]=",DoubleToString(extrHigh[1],5)," low[0]=",DoubleToString(extrLow[0],5)," low[1]=",DoubleToString(extrLow[1],5)," ask=",DoubleToString(price_ask)," prev_ask=",DoubleToString(prev_price_ask,5)," h=",DoubleToString(h,5) );                            
        }
      }

     // если перешли в режим ожидания отбития для открытия позиции на SELL
     if (wait_for_sell)
      {           
       // если удалось пробить последние два бара и от текущей цены на старшем ТФ нет тел свечей 
       if (IsBeatenBars(-1))
        {
         // если на старшем ТФ слева нет тел баров
         if (TestEldPeriod(-1))
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
           // сохраняем время открытия позиции
           open_pos_time = TimeCurrent();  
             
           // выводим всю информацию        
           Print("SELL ",
                 " время = ",TimeToString(TimeCurrent())
                );          
          }
        }
      } 
     // если перешли в режим ожидания отбития для открытия позиции на BUY
     if (wait_for_buy)
      {
       // если удалось пробить последние два бара и от текущей цены на старшем ТФ нет тел свечей
       if (IsBeatenBars(1))
        {
         // если удалось пробить последние два бара и от текущей цены на старших ТФ нет тел свечей
         if (TestEldPeriod(1))
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
           // сохраняем время открытия позиции
           open_pos_time = TimeCurrent();   
           
           // выводим всю информацию
           Print("BUY ",
                 " время = ",TimeToString(TimeCurrent())
                );    
          }
        }
      }
   // если позиция уже открыта, то обрабатываем условия закрытия позиции  
   if (opened_position)
    {    
     // если мы получили первое условие закрытия позиции (закрытие по экстремуму)
     if (IsBeatenExtremum(opened_position))
      {
       ctm.ClosePosition(0);
       Print("Закрыли позицию по экстремуму. Время = ",TimeToString(TimeCurrent()) );  
      }
       
     // если мы получили второе условие закрытия позиции (закрытие по заверешнению периода удержания октрытой позиции)
     if ( (TimeCurrent() - open_pos_time) > 1.5*(open_pos_time - signal_time) )
      {
       ctm.ClosePosition(0);
       Print("Закрыли позицию по времени Время = ",TimeToString(TimeCurrent())," Время сигнала = ",TimeToString(signal_time)," Время позиции = ",TimeToString(open_pos_time));
      } 
    
    }  
  }

// функция вычисляет параметры канала последнего движения цены
void CountMaxMinChannel ()
 {
  max_price = extrHigh[ArrayMaximum(extrHigh)];
  min_price = extrLow[ArrayMinimum(extrLow)];
  h = max_price - min_price;
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
    return ( int ( MathAbs(price_ask - max_price)/_Point ) );
  //  return ( int ( MathAbs(price_ask - average_price)/_Point ) );    
   }
  if (type == -1)
   {
    return ( int ( MathAbs(price_bid - min_price)/_Point ) );
  //  return ( int ( MathAbs(price_bid - average_price)/_Point ) );       
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
    if (LessDoubles(price_ask,price_low[1]) && LessDoubles(price_ask,price_low[0]) && LessDoubles(price_low[1],price_low[0]) &&
        GreatDoubles(price_high[1],price_high[0]) && GreatDoubles(price_high[1],price_high[2]) )
     {
      return (true);
     } 
   }
  if (type == -1)
   {
    // условие закрытие позиции SELL 
    if (GreatDoubles(price_bid,price_high[1]) && GreatDoubles(price_bid,price_high[0]) && GreatDoubles(price_high[1],price_high[0]) &&
        LessDoubles(price_low[1],price_low[0]) && LessDoubles(price_low[1],price_low[2]) )
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
  double extrHighTemp[];
  double extrLowTemp[];
  for (ind=0;ind<bars;)
   {
    if (CopyBuffer(handleDE,0,ind,1,extrHighTemp) < 1 || CopyBuffer(handleDE,1,ind,1,extrLowTemp) < 1)
     {
      Sleep(100);
      continue;
     }
    // если был найден high экстремум
    if (extrHighTemp[0] != 0.0)
     {
      extrHigh[extrCountHigh] = extrHighTemp[0];
      extrCountHigh++;
     }
    // если был найден low экстремум
    if (extrLowTemp[0] != 0.0)
     {
      extrLow[extrCountLow] = extrLowTemp[0];
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
   {
    return (false);
   }
  // если направленное движение вниз
  if ( LessDoubles (extrHigh[0],extrHigh[1]) && LessDoubles(extrLow[0],extrLow[1]) )
   {
    return (false);   
   }
  return (true);
 }

// функция смотрит на старший ТФ и проверяет
bool TestEldPeriod (int type)
 {
  MqlRates eldPriceBuf[];  
  int copied_rates;
  for (int attempts=0;attempts<25;attempts++)
   {
    copied_rates = CopyRates(_Symbol,periodEld,1,depth,eldPriceBuf);
    Sleep(100);
   }
  if (copied_rates < depth)
   {
    Print("Не удалось прогрузить все котировки");
    return (false);
   }
  // проходим по скопированным барам и проверяем, чтобы не попадались тела баров
  for (int ind=0;ind<depth;ind++)
   {
    // если нужно открываться на Buy, но на пути попалось тело бара
    if (type == 1  &&  ( GreatDoubles(price_ask,eldPriceBuf[ind].open) || GreatDoubles(price_ask,eldPriceBuf[ind].close) ) )
      return (false);
    // если нужно открываться на Sell, но на пути попалось тело бара
    if (type == -1 &&  ( LessDoubles(price_bid,eldPriceBuf[ind].open)  || LessDoubles(price_bid,eldPriceBuf[ind].close) ) )
      return (false);      
   }
  return (true);
 } 
 
// функция обработки внешних событий
void OnChartEvent(const int id,         // идентификатор события  
                  const long& lparam,   // параметр события типа long
                  const double& dparam, // параметр события типа double
                  const string& sparam  // параметр события типа string 
                 )
  {  
   if (sparam == "экстремум")
    {
     if (lparam == 1)
      {
       extrHigh[1] = extrHigh[0];
       extrHigh[0] = dparam;
       wait_for_buy = false;     
      }
     if (lparam == -1)
      {
       extrLow[1] = extrLow[0];
       extrLow[0] = dparam;
       wait_for_sell = false;       
      }
     
     if (wait_for_buy == false && wait_for_sell == false)
      {
       is_flat_now = IsFlatNow();
       if (is_flat_now)
        {       
         CountMaxMinChannel();  
         // вычисление средней цены для дальнейшего вычисления тейк профита 
         average_price = (max_price + min_price)/2; 
        } 
      }     
    }  
  }