//+------------------------------------------------------------------+
//|                                                  SimpleTrend.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Робот, торгующий на простом тренде                               |
//+------------------------------------------------------------------+
// подключение необходимых библиотек
#include <Lib CisNewBarDD.mqh>                     // для проверки формирования нового бара
#include <CompareDoubles.mqh>                      // для сравнения вещественных чисел
#include <TradeManager\TradeManager.mqh>           // торговая библиотека
#include <StringUtilities.mqh>

// константы сигналов
#define BUY   1    
#define SELL -1 
#define NO_POSITION 0

// перечисления и константы
enum ENUM_TENDENTION
{
 TENDENTION_NO = 0,     // нет тенденции
 TENDENTION_UP,         // тенденция вверх
 TENDENTION_DOWN        // тенденция вниз
};
// перечисления режимов PriceBasedIndicator
enum ENUM_PBI
{
 PBI_NO = 0,            // нет PBI
 PBI_SELECTED,          // PBI с выбранным таймфреймом
 PBI_FIXED              // PBI с фиксированными таймфреймами
};
/// входные параметры
input string baseParam = "";                       // БАЗОВЫЕ ПАРАМЕТРЫ
input double lot      = 1;                         // размер лота
input int    spread   = 30;                        // максимально допустимый размер спреда в пунктах на открытие и доливку позиции
input string lotAddParam="";                       // ПАРАМЕТРЫ ДОЛИВОК
input bool   useMultiFill=true;                    // использовать доливки при переходе на старш. период
input double lotStep  = 1;                         // размер шага увеличения лота
input int    lotCount = 3;                         // количество доливок
input string pbiParam = "";                        // Параметры PriceBasedIndicator
input ENUM_PBI  usePBI = PBI_NO;                   // тип  использования PBI
input ENUM_TIMEFRAMES pbiPeriod = PERIOD_H1;       // период PBI
input string lockParams="";                        // Параметры запретов на вход
input bool useLinesLock=false;                     // флаг включения запрета на вход по индикатора NineTeenLines
input int    koLock  = 2;                          // коэффициент запрета на вход
input bool   useExtr = true;                       // использовать пробития экстремумов
input bool   useClose = true;                      // использовать пробития close-в
input int indexStopLoss = 0;                       // индекс по которому выставляем стоп лосс
// структура уровней
struct bufferLevel
 {
  double price[];  // цена уровня
  double atr[];    // ширина уровня
 };
// необходимые буферы
MqlRates lastBarD1[];                              // буфер цен на дневнике
// хэндлы PriceBasedIndicator
int handlePBI_1;
int handlePBI_2;
int handlePBI_3;
// хэндл индикатора NineTeenLines
int handle_19Lines; 
// хэндлы индикатора DrawExtremums
int aHandleExtremums[4];
// буферы для проверки пробития экстремумов
int      countExtrHigh[4];                         // массив счетчиков экстремумов HIGH
int      countExtrLow[4];                          // массив счетчиков экстремумов LOW
int      countLastExtrHigh[4];                     // массив последних значений счетчиков экстремумов HIGH 
int      countLastExtrLow[4];                      // массив послених значений счетчиков экстремумов LOW
bool     beatenExtrHigh[4];                        // массив флагов пробития экстремумов HIGH
bool     beatenExtrLow[4];                         // массив флагов пробития экстремумов LOW
double   closes[];                                 // массив для хранения цен закрытия последних трех баров 
// объекты классов 
CTradeManager   *ctm;             // объект торговой библиотеки                                                     
CisNewBar       *isNewBar_D1;     // новый бар на D1
CArrayObj       containers;        // массив объектов класса получения информации об экстремумах индикатора DrawExtremums 
// дополнительные системные переменные
bool firstLaunch       = true;         // флаг первого запуска эксперта
bool beatM5;                           // флаг пробития на M5
bool beatM15;                          // флаг пробития на M15
bool beatH1;                           // флаг пробития на H1
bool beatCloseM5;                      // флаг пробития последних двух close M5
bool beatCloseM15;                     // флаг пробития последних двух close M15
bool beatCloseH1;                      // флаг пробития последних двух close H1
int  openedPosition    = NO_POSITION;  // тип открытой позиции 
int  stopLoss;                         // стоп лосс
int  indexForTrail     = 0;            // индекс для трейлинга
int  tmpLastBar;

double curPriceAsk       = 0;          // для хранения текущей цены Ask
double curPriceBid       = 0;          // для хранения текущей цены Bid 
double prevPriceAsk      = 0;          // для хранения предыдущей цены Ask
double prevPriceBid      = 0;          // для хранения предыдущей цены Bid
double lotReal;                        // действительный лот
double lastPriceAdding   = 0;          // последняя цена доливания      

int lastIndex;//Отладка

// переменные доливок
int  countAdd          = 0;            // количество доливок
bool changeLotValid    = false;        // флаг возможности доливки на M1
// переменные PriceBasedIndicator
int  lastTrendPBI_1    = 0;            // тип последнего тренда по PBI 
int  lastTrendPBI_2    = 0;            // тип последнего тренда по PBI
int  lastTrendPBI_3    = 0;            // тип последнего тренда по PBI
double pbiBuf[];                                   // буфер для хранения PriceBasedIndicator
ENUM_TENDENTION lastTendention, currentTendention; // переменные для хранения направления предыдущего и текущего баров
// переменные и буферы NineTeenLines
double signalBuffer[];                             // буфер для получения сигнала из индикатора smydMACD
bufferLevel buffers[8];                            // буфер уровней
double           lenClosestUp;                     // расстояние до ближайшего уровня сверху
double           lenClosestDown;                   // расстояние до ближайшего уровня снизу 
// структуры для работы с позициями            
SPositionInfo pos_info;                            // информация об открытии позиции 
STrailing trailing;                                // параметры трейлинга
// время последнего открытия позиции
datetime  timeOpenPos = 0;
// буфер для загрузки времени
datetime  timeBuf[]; 

int positstr = 0;
int OnInit()
 {     
  // если мы используем PriceBasedIndicator для вычисления последнего тренда на выбранном таймфрейме
  if (usePBI == PBI_SELECTED)
  {
  // пытаемся инициализировать хэндл PriceBasedIndicator
   handlePBI_1 = iCustom(_Symbol, pbiPeriod, "PriceBasedIndicator");   
   if ( handlePBI_1 == INVALID_HANDLE )
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s, Ошибка при иниализации эксперта SimpleTrend. Не удалось создать хэндл индикатора PriceBasedIndicator", MakeFunctionPrefix(__FUNCTION__)));
    return (INIT_FAILED);
   } 
   // получаем последний тип тренда на 3-х таймфреймах
   lastTrendPBI_1 = GetLastTrendDirection(handlePBI_1, pbiPeriod);
   lastTrendPBI_2 = lastTrendPBI_1;
   lastTrendPBI_3 = lastTrendPBI_1;           
  }           
  // если используеются фиксированные таймфреймы
  else if (usePBI == PBI_FIXED) 
  {
   // пытаемся инициализировать хэндл PriceBasedIndicator
   handlePBI_1  = iCustom(_Symbol,PERIOD_M5,"PriceBasedIndicator");   
   handlePBI_2  = iCustom(_Symbol,PERIOD_M15,"PriceBasedIndicator");  
   handlePBI_3  = iCustom(_Symbol,PERIOD_H1,"PriceBasedIndicator");            
   if ( handlePBI_1 == INVALID_HANDLE || handlePBI_2 == INVALID_HANDLE || handlePBI_3 == INVALID_HANDLE)
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s, Ошибка при иниализации эксперта SimpleTrend. Не удалось создать хэндл индикатора PriceBasedIndicator", MakeFunctionPrefix(__FUNCTION__)));
    return (INIT_FAILED);
   } 
   // получаем последний тип тренда на 3-х таймфреймах
   lastTrendPBI_1 = GetLastTrendDirection(handlePBI_1,PERIOD_M5);
   lastTrendPBI_2 = GetLastTrendDirection(handlePBI_2,PERIOD_M15);
   lastTrendPBI_3 = GetLastTrendDirection(handlePBI_3,PERIOD_H1); 
  } 
  // если использовать запреты на вход по NineTeenLines
  if (useLinesLock)
  {
   handle_19Lines = iCustom(_Symbol,_Period,"NineteenLines");     
   if (handle_19Lines == INVALID_HANDLE)
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s, Ошибка при инициализации эксперта SimpleTrend. Не удалось получить хэндл NineteenLines", MakeFunctionPrefix(__FUNCTION__)));
    return (INIT_FAILED);
   }    
  }  
  // инициализация массивов
  ArrayInitialize(countExtrHigh,0);
  ArrayInitialize(countExtrLow,0);
  ArrayInitialize(countLastExtrHigh,0);
  ArrayInitialize(countLastExtrLow,0);
  ArrayInitialize(beatenExtrHigh,false);
  ArrayInitialize(beatenExtrLow,false);      
  // создаем объект класса TradeManager
  ctm  = new CTradeManager();  
  // создаем объекты класса CisNewBar
  isNewBar_D1  = new CisNewBar(_Symbol,PERIOD_D1);
  
  aHandleExtremums[0] = iCustom(_Symbol, PERIOD_M1, "DrawExtremums");
  aHandleExtremums[1] = iCustom(_Symbol, PERIOD_M5, "DrawExtremums");
  aHandleExtremums[2] = iCustom(_Symbol, PERIOD_M15,"DrawExtremums");
  aHandleExtremums[3] = iCustom(_Symbol, PERIOD_H1, "DrawExtremums");
  containers.Add(new CExtrContainer(aHandleExtremums[0], _Symbol, PERIOD_M1));
  containers.Add(new CExtrContainer(aHandleExtremums[1], _Symbol, PERIOD_M5));
  containers.Add(new CExtrContainer(aHandleExtremums[2], _Symbol, PERIOD_M15));
  containers.Add(new CExtrContainer(aHandleExtremums[3], _Symbol, PERIOD_H1));
  
  // создаем объекты класса CBlowInfoFromExtremums
  for (int i = 0; i < 4; ++i)
  {
   if(aHandleExtremums[i] == INVALID_HANDLE)
    PrintFormat(__FUNCTION__ + " Не удалось скопировать хэндл для %i элемента",i);
   //CExtrContainer *cE = new CExtrContainer(aHandleExtremums[i]);
   //aBlowInfo.Add(cE);   // M1 
  }
  
  curPriceAsk = SymbolInfoDouble(_Symbol,SYMBOL_ASK);  
  curPriceBid = SymbolInfoDouble(_Symbol,SYMBOL_BID);    
  lotReal = lot;
   
  pos_info.tp = 0;
  pos_info.volume = lotReal;
  pos_info.expiration = 0;
  pos_info.priceDifference = 0;
  trailing.trailingType = TRAILING_TYPE_EXTREMUMS;
  trailing.minProfit    = 0;
  trailing.trailingStop = 0;
  trailing.trailingStep = 0;
  trailing.handleForTrailing = 0;
  trailing.extrContainer = containers.At(indexForTrail);
  lastIndex = indexForTrail;  //Отладка
  return(INIT_SUCCEEDED);
 }
 
void OnDeinit(const int reason)
{
 ArrayFree(lastBarD1);
 ArrayFree(pbiBuf);
 ArrayFree(timeBuf);
 ArrayFree(closes);
 // удаляем объекты классов
 delete ctm;
 delete isNewBar_D1;
 
 for (int i = containers.Total() - 1; i >= 0; i--)
 {
  delete containers.At(i);
  delete containers.At(i);
 }
 // освобождаем хэндлы индикаторов 
 if (usePBI == PBI_SELECTED) IndicatorRelease(handlePBI_1);  
 if (usePBI == PBI_FIXED)
 {
  IndicatorRelease(handlePBI_1);  
  IndicatorRelease(handlePBI_1);  
  IndicatorRelease(handlePBI_1);  
 }
 if (useLinesLock) IndicatorRelease(handle_19Lines);   
 for (int i = 0; i < 4; ++i)
 {
  IndicatorRelease(aHandleExtremums[i]);  
 }
}

int lastDeal = 0;


void OnTick()
{   
 int copied = 0;        // Количество скопированных данных из буфера
 int attempts = 0;      // Количество попыток копирования данных из буфера

 if(lastIndex!=indexForTrail) //Отладка
 {
  Print("Был изменен хэндл для трэйлинга, сейчас = ", indexForTrail);
  lastIndex = indexForTrail; 
 }
 ctm.OnTick(); 
 ctm.DoTrailing(aHandleExtremums[indexForTrail]); 

 prevPriceAsk = curPriceAsk;                             // сохраним предыдущую цену Ask
 prevPriceBid = curPriceBid;                             // сохраним предыдущую цену Bid
 curPriceBid  = SymbolInfoDouble(_Symbol, SYMBOL_BID);   // получаем текущую цену Bid    
 curPriceAsk  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);   // получаем текущую цену Ask
 
 /*for (int i = containers.Total() - 1; i >= 0; i--)
 {
  CExtrContainer *cE = containers.At(i);
  if (!cE.Upload(EXTR_BOTH,TimeCurrent(),1000))
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось прогрузить буфер индикатора DrawExtremums i=%d ", MakeFunctionPrefix(__FUNCTION__), i));           
   return;
  }
 }*/
 
 // если мы используем запрет на вход по NineTeenLines
 if (useLinesLock)
 {
  // если не удалось прогрузить буферы NineTeenLines
  if (!Upload19LinesBuffers()) 
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s, Не удалось прогрузить буферы NineTeenLines", MakeFunctionPrefix(__FUNCTION__)));
   return;
  }
 } 

 // получаем новые значения счетчиков экстремумов
 for (int ind = 0; ind < 4; ind++)
 {
  CExtrContainer *cEHigh = containers.At(ind);
  CExtrContainer *cELow  = containers.At(ind);
  
  countExtrHigh[ind] = cEHigh.GetCountByType(EXTR_HIGH);   // получаем текущее значение счетчика экстремумов HIGH
  countExtrLow[ind]  = cELow.GetCountByType(EXTR_LOW);     // получаем текущее значение счетчика экстремумов LOW
  // если счетчик экстремумов High обновился 
  if (countExtrHigh[ind] != countLastExtrHigh[ind])
  {
   // обновляем значение счетчика
   countLastExtrHigh[ind] = countExtrHigh[ind];
   // выставляем флаг пробития экстремума в false
   beatenExtrHigh[ind] = false; 
  } 
  // если счетчик экстремумов Low обновился
  if (countExtrLow[ind] != countLastExtrLow[ind])
  {
   // обновляем значение счетчика
   countLastExtrLow[ind] = countExtrLow[ind];
   // выставляем флаг пробития экстремума в false
   beatenExtrLow[ind] = false; 
  }   
 }

 // если используется PriceBasedIndicator с выбранным таймфреймом
 if (usePBI == PBI_SELECTED)
 {
  // обновляем значение последнего тренда
  tmpLastBar = GetLastMoveType(handlePBI_1);
  if (tmpLastBar != 0)
  {
   lastTrendPBI_1 = tmpLastBar;
   lastTrendPBI_2 = tmpLastBar;
   lastTrendPBI_3 = tmpLastBar;
  }   
 }
 // если используется PriceBasedIndicator с фиксированными таймфреймами
 else if (usePBI == PBI_FIXED)
 {
  // обновляем значение последнего тренда
  tmpLastBar = GetLastMoveType(handlePBI_1);
  if (tmpLastBar != 0)
  {
   lastTrendPBI_1 = tmpLastBar;
  }   
  // обновляем значение последнего тренда
  tmpLastBar = GetLastMoveType(handlePBI_2);
  if (tmpLastBar != 0)
  {
   lastTrendPBI_2 = tmpLastBar;
  }   
  // обновляем значение последнего тренда
  tmpLastBar = GetLastMoveType(handlePBI_3);
  if (tmpLastBar != 0)
  {
   lastTrendPBI_3 = tmpLastBar;
  }           
 } 

   
 // если это первый запуск эксперта или сформировался новый бар 
 if (firstLaunch || isNewBar_D1.isNewBar() > 0)
 {
  firstLaunch = false;
  while (copied < 2 && attempts < 5 && !IsStopped())
  {
   copied = CopyRates(_Symbol, PERIOD_D1, 0, 2, lastBarD1);
   attempts++;
   Sleep(111);
  }
  
  if (copied == 2 )     
  {
   lastTendention = GetTendention(lastBarD1[0].open, lastBarD1[0].close);        // получаем предыдущую тенденцию 
   copied = 0;
   attempts = 0;
  }
  else
  {
   firstLaunch = true;
   return;
  }
 }

 // если нет открытых позиций
 if (ctm.GetPositionCount() == 0)
  openedPosition = NO_POSITION;
 else    // иначе меняем индекс трейлинга и доливаемся, если это возможно
 {
  ChangeTrailIndex();                            // то меняем индекс трейлинга
  if (countAdd < lotCount && changeLotValid)     // если было совершено меньше lotCount доливок и есть разрешение на доливку
  {   
   if (ChangeLot())                              // если получили сигнал на доливание 
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s, Доливаемся. Количество доливок = %d", MakeFunctionPrefix(__FUNCTION__), countAdd));
    ctm.PositionChangeSize(_Symbol, lotStep);    // доливаемся 
   }       
  }        
 } 

 currentTendention = GetTendention(lastBarD1[1].open, curPriceBid);
 // если общая тенденция  - вверх
 if (lastTendention == TENDENTION_UP && currentTendention == TENDENTION_UP)
 {   
  // если текущая цена пробила один из экстемумов на одном из таймфреймов
  if ( ( (beatM5       =  IsExtremumBeaten(1,BUY) ) && (lastTrendPBI_1==BUY||usePBI==PBI_NO)  && useExtr)    || 
       ( (beatM15      =  IsExtremumBeaten(2,BUY) ) && (lastTrendPBI_2==BUY||usePBI==PBI_NO)  && useExtr)    || 
       ( (beatH1       =  IsExtremumBeaten(3,BUY) ) && (lastTrendPBI_3==BUY||usePBI==PBI_NO)  && useExtr)    ||
       ( (beatCloseM5  =  IsLastClosesBeaten(PERIOD_M5,BUY))      && (lastTrendPBI_1==BUY)    && useClose)   ||
       ( (beatCloseM15 =  IsLastClosesBeaten(PERIOD_M15,BUY))     && (lastTrendPBI_2==BUY)    && useClose)   ||
       ( (beatCloseH1  =  IsLastClosesBeaten(PERIOD_H1,BUY))      && (lastTrendPBI_3==BUY)    && useClose)         
     ) 
  {      
   //log_file.Write(LOG_DEBUG, StringFormat("%s, Получили сигнал на BUY, время = %s", MakeFunctionPrefix(__FUNCTION__), TimeToString(TimeCurrent())));
   // если используются запреты по NineTeenLines
   if (useLinesLock)
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s, Используем запрет по 19 линиям", MakeFunctionPrefix(__FUNCTION__)));
    // получаем расстояния до ближайших уровней снизу и сверху
    lenClosestUp   = GetClosestLevel(BUY);
    lenClosestDown = GetClosestLevel(SELL);
    // если получили сигнал на запрет на вход
    if (lenClosestUp != 0 && 
        LessOrEqualDoubles(lenClosestUp, lenClosestDown*koLock) )
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s, Получили сигнал запрета на вход на BUY", MakeFunctionPrefix(__FUNCTION__)));
     return;
    }   
   }   
   // если позиция не была уже открыта на BUY   
   if (openedPosition != BUY)
   {
    // обнуляем счетчик трейлинга
    indexForTrail = indexStopLoss;
    // обнуляем счетчик доливок, если 
    countAdd = 0;                                         
   }   
   if (useMultiFill || openedPosition!=BUY)
   {
    // разрешаем возможность доливаться
    changeLotValid = true;
   }     
   // выставляем флаг открытия позиции BUY
   openedPosition = BUY;                 
   // выставляем лот по умолчанию
   lotReal = lot;
   // вычисляем стоп лосс
   stopLoss = GetStopLoss();        
   // заполняем параметры открытия позиции
   pos_info.type = OP_BUY;
   pos_info.sl = stopLoss;    
   pos_info.volume = lotReal; 
   // открываем позицию на BUY
   trailing.extrContainer = containers.At(indexForTrail);
   if (ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing, spread))
   {
    timeOpenPos = TimeCurrent();       // сохраняем время открытия позиции
    lastPriceAdding = curPriceBid;     // сохраняем цену открытия позиции
    lastDeal = BUY;                    // сохраняем тип позиции
   } 
  }
 }
 // если общая тенденция - вниз
 if (lastTendention == TENDENTION_DOWN && currentTendention == TENDENTION_DOWN)
 {                     
  // если текущая цена пробила один из экстемумов на одном из таймфреймов 
  if (( (beatM5  = IsExtremumBeaten(1,SELL) ) && (lastTrendPBI_1==SELL||usePBI==PBI_NO) && useExtr)   || 
      ( (beatM15 = IsExtremumBeaten(2,SELL) ) && (lastTrendPBI_2==SELL||usePBI==PBI_NO) && useExtr)   || 
      ( (beatH1  = IsExtremumBeaten(3,SELL) ) && (lastTrendPBI_3==SELL||usePBI==PBI_NO) && useExtr)   || 
      ( (beatCloseM5  = IsLastClosesBeaten(PERIOD_M5,SELL))   && (lastTrendPBI_1==SELL) && useClose)  ||
      ( (beatCloseM15 = IsLastClosesBeaten(PERIOD_M15,SELL))  && (lastTrendPBI_2==SELL) && useClose)  ||
      ( (beatCloseH1  = IsLastClosesBeaten(PERIOD_H1,SELL))   && (lastTrendPBI_3==SELL) && useClose)       
     )  
  {    
   log_file.Write(LOG_CRITICAL, StringFormat("%s, Получили сигнал на Sell, время = %s", MakeFunctionPrefix(__FUNCTION__), TimeToString(TimeCurrent())));
   // если используются зарпеты по NineTeenLines
   if (useLinesLock)
   { 
    log_file.Write(LOG_DEBUG, StringFormat("%s, Используем запрет по 19 линиям", MakeFunctionPrefix(__FUNCTION__)));
    // получаем расстояния до ближайших уровней снизу и сверху
    lenClosestUp   = GetClosestLevel(BUY);
    lenClosestDown = GetClosestLevel(SELL);    
    // если получили сигнал запрета на вход
    if (lenClosestDown != 0 &&
        LessOrEqualDoubles(lenClosestDown, lenClosestUp*koLock) )
    {        
     log_file.Write(LOG_DEBUG, StringFormat("%s, Получили сигнал запрета на вход на SELL", MakeFunctionPrefix(__FUNCTION__)));
     return;
    }
   }                
   // если позиция не была уже открыта на SELL
   if (openedPosition != SELL)
   {
    // обнуляем счетчик трейлинга
    indexForTrail = indexStopLoss; 
    // обнуляем счетчик доливок, если 
    countAdd = 0;        
   }
   if (useMultiFill || openedPosition!=SELL)
   {
    // разрешаем возможность доливаться
    changeLotValid = true;
   }          
   // выставляем флаг открытия позиции SELL
   openedPosition = SELL;                 
   // выставляем лот по умолчанию
   lotReal = lot;    
   // вычисляем стоп лосс
   stopLoss = GetStopLoss();   
   // заполняем параметры открытия позиции
   pos_info.type = OP_SELL;
   pos_info.sl = stopLoss;   
   pos_info.volume = lotReal;
   trailing.extrContainer = containers.At(indexForTrail);  
   // открываем позицию на SELL 
   if (ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing, spread))
   {
    timeOpenPos = TimeCurrent();   // сохраняем время открытия позиции
    lastPriceAdding = curPriceAsk; // сохраняем цену позиции
    lastDeal = SELL;               // сохраняем тип позиции
   }
  } 
 }
}
  
// кодирование функций
ENUM_TENDENTION GetTendention (double priceOpen,double priceAfter)            // возвращает тенденцию по двум ценам
{
 if (GreatDoubles (priceAfter, priceOpen))
  return (TENDENTION_UP);
 if (LessDoubles  (priceAfter, priceOpen))
  return (TENDENTION_DOWN); 
 return (TENDENTION_NO); 
}

bool IsExtremumBeaten (int index,int direction)   // проверяет пробитие ценой экстремума
{
 CExtrContainer *cE = containers.At(index);
 
 switch (direction)
 {
  case SELL:
   if (LessDoubles(curPriceAsk,cE.GetLastFormedExtr(EXTR_LOW).price)&& GreatOrEqualDoubles(prevPriceAsk,cE.GetLastFormedExtr(EXTR_LOW).price) && !beatenExtrLow[index])
   {
    beatenExtrLow[index] = true; 
    return (true);    
   }     
  break;
  case BUY:
   if (GreatDoubles(curPriceBid,cE.GetLastFormedExtr(EXTR_HIGH).price) && LessOrEqualDoubles(prevPriceBid,cE.GetLastFormedExtr(EXTR_HIGH).price) && !beatenExtrHigh[index])
   {
    beatenExtrHigh[index] = true;
    return (true);
   }     
  break;
 }
 return (false);
}
 
void ChangeTrailIndex()   // функция меняет индекс таймфрейма для трейлинга
{
 // трейлим стоп лосс
 while (indexForTrail < 3 && IsExtremumBeaten(indexForTrail+1, openedPosition))  // переходим на старший таймфрейм в случае, если сейчас не H1
 {
  indexForTrail++;        // то переходим на более старший таймфрейм
  changeLotValid = false; // выставляем флаг возможности доливок в false
 }
 //trailing.extrContainer = new CExtrContainer (aHandleExtremums[indexForTrail], _Symbol, _Period);
}
 
int GetStopLoss()         // вычисляет стоп лосс
{
 int slValue;             // значение стоп лосса
 int stopLevel;           // стоп левел
 stopLevel = SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);  // получаем стоп левел
 CExtrContainer *cE = containers.At(indexStopLoss);
 switch (openedPosition)
 {
  case BUY:
   slValue = (curPriceBid - cE.GetLastFormedExtr(EXTR_LOW).price)/_Point; 
   if ( slValue > stopLevel )
   {
    return (slValue);
   }
   else
   {
    return (stopLevel + 1);
   }
  case SELL:
   slValue = (cE.GetLastFormedExtr(EXTR_HIGH).price - curPriceAsk)/_Point;
   if (slValue > stopLevel)
   {   
    return (slValue);     
   }
   else
   {
    return (stopLevel + 1);     
   }
 }
 return (0);
}

bool ChangeLot()    // функция изменяет размер лота, если это возможно (доливка)
{
 CExtrContainer *cE = containers.At(indexStopLoss);
 double pricePos = ctm.GetPositionPrice(_Symbol);
 double posAverPrice;  // средняя цена позиции 
 // в зависимости от типа открытой позиции
 switch (openedPosition)
 {
  case BUY:  // если позиция открыта на BUY
   if (cE.GetPrevExtrType() == EXTR_LOW)  // если последний экстремум LOW
   { 
    // получаем новую среднюю цену позиции
    posAverPrice = (lotReal*pricePos + lotStep*SymbolInfoDouble(_Symbol,SYMBOL_ASK) ) / (lotReal+lotStep);   
    if (IsExtremumBeaten(indexStopLoss,BUY) && 
        GreatDoubles(ctm.GetPositionStopLoss(_Symbol), posAverPrice) &&
        GreatDoubles(curPriceBid,lastPriceAdding)
       ) // если пробит экстремум и стоп лосс в безубытке
    {
     countAdd++; // увеличиваем счетчик доливок
     lastPriceAdding = curPriceBid; // сохраняем последнюю цену, по которой открывались \ доливались
     return (true);
    }
   } 
  break;
  case SELL: // если позиция открыта на SELL
   if (cE.GetPrevExtrType() == EXTR_HIGH) // если последний экстремум HIGH
   {   
    // получаем новую среднюю цену позиции
    posAverPrice = (lotReal*pricePos + lotStep*SymbolInfoDouble(_Symbol,SYMBOL_BID)) / (lotReal+lotStep);      
    if (IsExtremumBeaten(indexStopLoss,SELL) &&
        LessDoubles(ctm.GetPositionStopLoss(_Symbol), posAverPrice)  &&
        LessDoubles(curPriceAsk,lastPriceAdding)  
       ) // если пробит экстремум и стоп лосс в безубытке
    {
     countAdd++; // увеличиваем счетчик доливок
     lastPriceAdding = curPriceAsk; // сохраняем последнюю цену, по которой открывались \ доливались
     return (true);
    }   
   }
  break;
 }
 return(false);
}

int GetLastTrendDirection (int handle,ENUM_TIMEFRAMES period)   // возвращает true, если тендекция не противоречит последнему тренду на текущем таймфрейме
{
 int copiedPBI=-1;     // количество скопированных данных PriceBasedIndicator
 int signTrend=-1;     // переменная для хранения знака последнего тренда
 int index=1;          // индекс бара
 int nBars;            // количество баров
 
 ArraySetAsSeries(pbiBuf,true);
 
 nBars = Bars(_Symbol,period);
 
 for (int attempts = 0; attempts < 5; attempts++)
 {
  copiedPBI = CopyBuffer(handle, 4, 1, nBars - 1, pbiBuf);
  Sleep(100);
 }
 if (copiedPBI < (nBars-1))
 {
 // Comment("Не удалось скопировать все бары");
  return (0);
 }
 
 for (index = 0; index < nBars - 1; index++)
 {
  signTrend = int(pbiBuf[index]);
  // если найден последний тренд вверх
  if (signTrend == 1 || signTrend == 2)
   return (1);
  // если найден последний тренд вниз
  if (signTrend == 3 || signTrend == 4)
   return (-1);
 }
 return (0);
}
 
int  GetLastMoveType (int handle) // получаем последнее значение PriceBasedIndicator
{
 int copiedPBI;
 int signTrend;
 copiedPBI = CopyBuffer(handle,4,1,1,pbiBuf);
 if (copiedPBI < 1)
  return (0);
 signTrend = int(pbiBuf[0]);
 // если тренд вверх
 if (signTrend == 1 || signTrend == 2)
  return (1);
 // если тренд вниз
 if (signTrend == 3 || signTrend == 4)
  return (-1);
 return (0);
}
  
bool Upload19LinesBuffers ()   // получает последние значения уровней
{
 int copiedPrice;
 int copiedATR;
 int indexPer;
 int indexBuff;
 int indexLines = 0;
 for (indexPer=1;indexPer<5;indexPer++)
 {
  for (indexBuff=0;indexBuff<2;indexBuff++)
  {
   copiedPrice = CopyBuffer(handle_19Lines, indexPer * 8 + indexBuff * 2 + 4,  0, 1, buffers[indexLines].price);
   copiedATR   = CopyBuffer(handle_19Lines, indexPer * 8 + indexBuff * 2 + 5,  0, 1, buffers[indexLines].atr);
   if (copiedPrice < 1 || copiedATR < 1)
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s, Не удалось прогрузить буферы индикатора NineTeenLines", MakeFunctionPrefix(__FUNCTION__)));
    return (false);
   }
   indexLines++;
  }
 }
 return(true);     
}

// возвращает ближайший уровень к текущей цене
double GetClosestLevel (int direction) 
{
 double cuPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);
 double len = 0;  //расстояние до цены от уровня
 double tmpLen; 
 int    index;
 int    savedInd;
 switch (direction)
 {
  case BUY:  // ближний сверху
   for (index=0;index<8;index++)
   {         
    // если уровень выше
    if ( GreatDoubles((buffers[index].price[0]-buffers[index].atr[0]),cuPrice)  )
    {
     tmpLen = buffers[index].price[0] - buffers[index].atr[0] - cuPrice;
     if (tmpLen < len || len == 0)
     {
      savedInd = index;
      len = tmpLen;
     }  
    }           
   }
   break;
  case SELL: // ближний снизу
   for (index=0;index<8;index++)
   {
    // если уровень ниже
    if ( LessDoubles((buffers[index].price[0]+buffers[index].atr[0]),cuPrice)  )
    {
     tmpLen = cuPrice - buffers[index].price[0] - buffers[index].atr[0] ;
     if (tmpLen < len || len == 0)
     {
      savedInd = index;
      len = tmpLen;
     }
    }
   }     
   break;
 }
 return (len);
}    

// функция проверяет пробития цен close последних двух баров
bool IsLastClosesBeaten (ENUM_TIMEFRAMES period,int direction)
{
 // пытаемся скопировать время открытия последнего бара
 if ( CopyTime(_Symbol,period,1,1,timeBuf) < 1 )
 {
  Print("Не удалось скопировать время открытия последнего бара");
  return false;
 }
 // если время открытия последней позиции меньше времени открытия последнего бара
 if (timeOpenPos < timeBuf[0])
 {
  // пытаемся скопировать цены закрытия последних 3-х баров
  if (CopyClose(_Symbol, period, 1, 3, closes) < 3)
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s, Не удалось скопировать цены close 3-х последних сформированных баров", MakeFunctionPrefix(__FUNCTION__)));
   return false;
  }
  switch (direction)
  {
   case BUY:
   // если цена close на последнем баре пробила цены close на двух предыдущих 
    if (GreatDoubles(closes[2], closes[1]) && GreatDoubles(closes[2], closes[0]) && LessDoubles(closes[1], closes[0]))
    {
     return true;
    }
   case SELL:
   // если цена close на последнем баре пробила цены close на двух предыдущих
    if (LessDoubles(closes[2], closes[1]) && LessDoubles(closes[2], closes[0]) && GreatDoubles(closes[1], closes[0]))
    {  
     return true;
    }
  }
 }
 return false;
}  

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
 string strPeriod;
 //container.UploadOnEvent(sparam,dparam,lparam); 
 positstr = StringFind(sparam, "_", 12); positstr++;
 strPeriod = StringSubstr(sparam, positstr, 4);
 CExtrContainer *cextr;
 Comment(sparam);
 if(strPeriod == PeriodToString(PERIOD_M1))
 {
  cextr = containers.At(0);
  cextr.UploadOnEvent(sparam, dparam, lparam);
 }
 if(strPeriod == PeriodToString(PERIOD_M10))
 {
  cextr = containers.At(1);
  cextr.UploadOnEvent(sparam, dparam, lparam);
 }
 if(strPeriod == PeriodToString(PERIOD_M15))
 {
  cextr = containers.At(2);
  cextr.UploadOnEvent(sparam, dparam, lparam);
 }
 if(strPeriod == PeriodToString(PERIOD_H1))
 {
  cextr = containers.At(3);
  cextr.UploadOnEvent(sparam, dparam, lparam);
 }
 
  //trailing.extrContainer.UploadOnEvent(sparam, dparam, lparam);
 
 //Print(" По событию теперь элементов в контейнере = ", trailing.extrContainer.GetCountByType(EXTR_BOTH));
}

