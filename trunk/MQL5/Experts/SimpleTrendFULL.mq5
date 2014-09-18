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
#include <BlowInfoFromExtremums.mqh>               // класс по работе с экстремумами индикатора DrawExtremums

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
input string baseParam = "";                       // Базовые параметры
input double lot      = 1;                         // размер лота
input double lotStep  = 1;                         // размер шага увеличения лота
input int    lotCount = 3;                         // количество доливок
input int    spread   = 30;                        // максимально допустимый размер спреда в пунктах на открытие и доливку позиции
input string addParam = "";                        // Настройки
input bool   useMultiFill=true;                    // использовать доливки при переходе на старш. период
input string pbiParam = "";                        // Параметры PriceBasedIndicator
input ENUM_PBI  usePBI=PBI_NO;                     // тип  использования PBI
input ENUM_TIMEFRAMES pbiPeriod = PERIOD_H1;       // период PBI
input string lockParams="";                        // Параметры запретов на вход
input bool useLinesLock=false;                     // флаг включения запрета на вход по индикатора NineTeenLines
input  int    koLock  = 2;                         // коэффициент запрета на вход
input  bool   useMACDLock=false;                   // флаг включения запрета на вход по расхождению на MACD
input  int    lenToMACD = 5;                       // расстояние до поиска сигнала на MACD

// структура уровней
struct bufferLevel
 {
  double price[];  // цена уровня
  double atr[];    // ширина уровня
 };
// хэндлы PriceBasedIndicator
int handlePBI_1;
int handlePBI_2;
int handlePBI_3;
// хэндл индикатора NineTeenLines
int handle_19Lines;                                // хэндл 19 Lines
// хэндлы индикатора smydMACD
int handleMACDM5;                                  // хэндл smydMACD M5
int handleMACDM15;                                 // хэндл smydMACD M15
int handleMACDH1;                                  // хэндл smydMACD H1 
// необходимые буферы
MqlRates lastBarD1[];                              // буфер цен на дневнике
// буфер для хранения PriceBasedIndicator
double pbiBuf[];
// буферы для проверки пробития экстремумов
Extr             lastExtrHigh[4];                  // буфер последних экстремумов по HIGH
Extr             lastExtrLow[4];                   // буфер последних экстремумов по LOW
Extr             currentExtrHigh[4];               // буфер текущих экстремумов по HIGH
Extr             currentExtrLow[4];                // буфер текущих экстремумов по LOW
bool             extrHighBeaten[4];                // буфер флагов пробития экстремумов HIGH
bool             extrLowBeaten[4];                 // буфер флагов пробития экстремумов LOW

// объекты классов
CTradeManager *ctm;                                // объект торговой библиотеки
//CTradeManager *ctm2;                              
CisNewBar     *isNewBar_D1;                        // новый бар на D1
CBlowInfoFromExtremums *blowInfo[4];               // массив объектов класса получения информации об экстремумах индикатора DrawExtremums 
// буферы 
double signalBuffer[];                             // буфер для получения сигнала из индикатора smydMACD
bufferLevel buffers[8];                            // буфер уровней
// дополнительные системные переменные
bool             firstLaunch       = true;         // флаг первого запуска эксперта
bool             changeLotValid;                   // флаг возможности доливки на M1
bool             beatM5;                           // флаг пробития на M5
bool             beatM15;                          // флаг пробития на M15
bool             beatH1;                           // флаг пробития на H1
int              openedPosition    = NO_POSITION;  // тип открытой позиции 
int              stopLoss;                         // стоп лосс
int              indexForTrail     = 0;            // индекс для трейлинга
int              countAdd          = 0;            // количество доливок

int              lastTrendPBI_1    = 0;            // тип последнего тренда по PBI 
int              lastTrendPBI_2    = 0;            // тип последнего тренда по PBI
int              lastTrendPBI_3    = 0;            // тип последнего тренда по PBI
  
int              tmpLastBar;

double           curPriceAsk       = 0;            // для хранения текущей цены Ask
double           curPriceBid       = 0;            // для хранения текущей цены Bid 
double           prevPriceAsk      = 0;            // для хранения предыдущей цены Ask
double           prevPriceBid      = 0;            // для хранения предыдущей цены Bid
double           lotReal;                          // действительный лот
double           lenClosestUp;                     // расстояние до ближайшего уровня сверху
double           lenClosestDown;                   // расстояние до ближайшего уровня снизу 
ENUM_TENDENTION  lastTendention;                   // переменная для хранения последней тенденции

// структуры для работы с позициями            
SPositionInfo pos_info;                            // информация об открытии позиции 
STrailing trailing;                                // параметры трейлинга
                           
int OnInit()
  {     
   // если мы используем PriceBasedIndicator для вычисления последнего тренда на выбраенном таймфрейме
   if (usePBI == PBI_SELECTED)
    {
     // пытаемся инициализировать хэндл PriceBasedIndicator
     handlePBI_1  = iCustom(_Symbol,pbiPeriod,"PriceBasedIndicator");   
     if ( handlePBI_1 == INVALID_HANDLE )
      {
       Print("Ошибка при иниализации эксперта SimpleTrend. Не удалось создать хэндл индикатора PriceBasedIndicator");
       return (INIT_FAILED);
      } 
     // получаем последний тип тренда на 3-х таймфреймах
     lastTrendPBI_1  = GetLastTrendDirection(handlePBI_1,pbiPeriod);
     lastTrendPBI_2  = lastTrendPBI_1;
     lastTrendPBI_3  = lastTrendPBI_1;           
    }           
  // исли используеются фиксированных таймфреймы
  else if (usePBI == PBI_FIXED) 
   {
     // пытаемся инициализировать хэндл PriceBasedIndicator
     handlePBI_1  = iCustom(_Symbol,PERIOD_M5,"PriceBasedIndicator");   
     handlePBI_2  = iCustom(_Symbol,PERIOD_M15,"PriceBasedIndicator");  
     handlePBI_3  = iCustom(_Symbol,PERIOD_H1,"PriceBasedIndicator");            
     if ( handlePBI_1 == INVALID_HANDLE || handlePBI_2 == INVALID_HANDLE || handlePBI_3 == INVALID_HANDLE)
      {
       Print("Ошибка при иниализации эксперта SimpleTrend. Не удалось создать хэндл индикатора PriceBasedIndicator");
       return (INIT_FAILED);
      } 
     // получаем последний тип тренда на 3-х таймфреймах
     lastTrendPBI_1  = GetLastTrendDirection(handlePBI_1,PERIOD_M5);
     lastTrendPBI_2  = GetLastTrendDirection(handlePBI_2,PERIOD_M15);
     lastTrendPBI_3  = GetLastTrendDirection(handlePBI_3,PERIOD_H1); 
   }
  // если использовать запреты на вход по NineTeenLines
  if (useLinesLock)
   {
    handle_19Lines = iCustom(_Symbol,_Period,"NineteenLines");     
    if (handle_19Lines == INVALID_HANDLE)
     {
      Print("Ошибка при инициализации эксперта SimpleTrend. Не удалось получить хэндл NineteenLines");
      return (INIT_FAILED);
     }    
   }
  // если использовать запрет на вход на MACD
  if (useMACDLock)
   {
   // создаем хэндл индикатора ShowMeYourDivMACD
   handleMACDM5  = iCustom (_Symbol,PERIOD_M5,"smydMACD");
   handleMACDM15 = iCustom (_Symbol,PERIOD_M15,"smydMACD");
   handleMACDH1  = iCustom (_Symbol,PERIOD_H1,"smydMACD");   
   if ( handleMACDM5 == INVALID_HANDLE || handleMACDM15 == INVALID_HANDLE || handleMACDH1 == INVALID_HANDLE )
    {
     Print("Ошибка при инициализации эксперта SimpleTrend. Не удалось создать хэндл ShowMeYourDivMACD");
     return (INIT_FAILED);
    }
   } 
   // создаем объект класса TradeManager
   ctm = new CTradeManager();  
   // создаем объекты класса CisNewBar
   isNewBar_D1  = new CisNewBar(_Symbol,PERIOD_D1);
   // создаем объекты класса CBlowInfoFromExtremums
   blowInfo[0]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_M1,100,30,30,217);  // M1 
   blowInfo[1]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_M5,100,30,30,217);  // M5 
   blowInfo[2]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_M15,100,30,30,217); // M15 
   blowInfo[3]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_H1,100,30,30,217);  // H1          
   if (!blowInfo[0].IsInitFine() )
        return (INIT_FAILED);
   curPriceAsk = SymbolInfoDouble(_Symbol,SYMBOL_ASK);  
   curPriceBid = SymbolInfoDouble(_Symbol,SYMBOL_BID);  
   ArrayInitialize(extrHighBeaten,false);
   ArrayInitialize(extrLowBeaten,false);   
   lotReal = lot;
   
   pos_info.tp = 0;
   pos_info.volume = lotReal;
   pos_info.expiration = 0;
   pos_info.priceDifference = 0;
 
   trailing.trailingType = TRAILING_TYPE_EXTREMUMS;
   trailing.minProfit    = 0;
   trailing.trailingStop = 0;
   trailing.trailingStep = 0;
   trailing.handlePBI    = 0;  
   
   return(INIT_SUCCEEDED);
  }
void OnDeinit(const int reason)
  {
   ArrayFree(lastBarD1);
   ArrayFree(pbiBuf);
   // удаляем объекты классов
   delete ctm;
   // освобождаем хэндлы индикаторов
   IndicatorRelease(handleMACDM5);
   IndicatorRelease(handleMACDM15);
   IndicatorRelease(handleMACDH1);
   IndicatorRelease(handle_19Lines);
   delete isNewBar_D1;
   delete blowInfo[0];
   delete blowInfo[1];
   delete blowInfo[2];
   delete blowInfo[3];  
  }

void OnTick()
{     
 ctm.OnTick(); 
 ctm.UpdateData();
 ctm.DoTrailing(blowInfo[indexForTrail]); 

 
 prevPriceAsk = curPriceAsk;                             // сохраним предыдущую цену Ask
 prevPriceBid = curPriceBid;                             // сохраним предыдущую цену Bid
 curPriceBid  = SymbolInfoDouble(_Symbol, SYMBOL_BID);   // получаем текущую цену Bid    
 curPriceAsk  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);   // получаем текущую цену Ask
 
 if (!blowInfo[0].Upload(EXTR_BOTH,TimeCurrent(),100) ||
     !blowInfo[1].Upload(EXTR_BOTH,TimeCurrent(),100) ||
     !blowInfo[2].Upload(EXTR_BOTH,TimeCurrent(),100) ||
     !blowInfo[3].Upload(EXTR_BOTH,TimeCurrent(),100)
    )
 {   
  return;
 }
 /*
Comment("Последний экстремум тип = ",blowInfo[1].ShowExtrType(blowInfo[1].GetLastExtrType()) ,
        "\n последний экстремум = ",DoubleToString( blowInfo[1].GetExtrByIndex(EXTR_HIGH,0).price )
  );
 */
 // если мы используем запрет на вход по NineTeenLines
 if (useLinesLock)
 {
  // если не удалось прогрузить буферы NineTeenLines
  if ( !Upload19LinesBuffers () ) 
   return;
 }
 
 // получаем новые значения экстремумов
 for (int index = 0; index < 4; index++)
 {
  currentExtrHigh[index]  = blowInfo[index].GetExtrByIndex(EXTR_HIGH,0);
  currentExtrLow[index]   = blowInfo[index].GetExtrByIndex(EXTR_LOW,0);    
  if (currentExtrHigh[index].time != lastExtrHigh[index].time && currentExtrHigh[index].price)          // если пришел новый HIGH экстремум
  {
   lastExtrHigh[index] = currentExtrHigh[index];   // то сохраняем текущий экстремум в качестве последнего
   extrHighBeaten[index] = false;                  // и выставляем флаг пробития  в false     
  }
  if (currentExtrLow[index].time != lastExtrLow[index].time && currentExtrLow[index].price)            // если пришел новый LOW экстремум
  {
   lastExtrLow[index] = currentExtrLow[index];     // то сохраняем текущий экстремум в качестве последнего
   extrLowBeaten[index] = false;                   // и выставляем флаг пробития в false
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
  if ( CopyRates(_Symbol,PERIOD_D1,0,2,lastBarD1) == 2 )     
  {
   lastTendention = GetTendention(lastBarD1[0].open,lastBarD1[0].close);        // получаем предыдущую тенденцию 
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

    ctm.PositionChangeSize(_Symbol, lotStep);    // доливаемся 
   }       
  }        
 }
 
 // если общая тенденция  - вверх
 if (lastTendention == TENDENTION_UP && GetTendention (lastBarD1[1].open,curPriceBid) == TENDENTION_UP)
 {   
  // если текущая цена пробила один из экстемумов на одном из таймфреймов и текущее расхождение MACD НЕ противоречит текущему движению
  if (  ((beatM5=IsExtremumBeaten(1,BUY)) && (lastTrendPBI_1==BUY||usePBI==PBI_NO)) || 
        ((beatM15=IsExtremumBeaten(2,BUY))&& (lastTrendPBI_2==BUY||usePBI==PBI_NO)) || 
        ((beatH1=IsExtremumBeaten(3,BUY)) && (lastTrendPBI_3==BUY||usePBI==PBI_NO))  )
  {        
   // если спред не превышает заданное число пунктов
   if (LessDoubles(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD), spread))
   {
    // если используются запреты по smydMACD
    if (useMACDLock)
     {
      // если пробили M5 и сигнал MACD на M5 противоположный, то зарпещаем открываться
      if (beatM5&&GetMACDSignal(handleMACDM5)==SELL)
       return;
      // если пробили M15 и сигнал MACD на M15 противоположный, то запрещаем открываться
      if (beatM15&&GetMACDSignal(handleMACDM15)==SELL)
       return;
      // если пробили H1 и сигнал MACD на H1 противоположный, то запрещаем открываться
      if (beatH1&&GetMACDSignal(handleMACDH1)==SELL)
       return;
     }
    // если используются запреты по NineTeenLines
    if (useLinesLock)
     {
      // получаем расстояния до ближайших уровней снизу и сверху
      lenClosestUp   = GetClosestLevel(BUY);
      lenClosestDown = GetClosestLevel(SELL);
      // если получили сигнал на запрет на вход
      if (lenClosestUp != 0 && 
        LessOrEqualDoubles(lenClosestUp, lenClosestDown*koLock) )
         {
          return;
         }   
     }
    // если позиция не была уже открыта на BUY   
    if (openedPosition != BUY)
    {
     // обнуляем счетчик трейлинга
     indexForTrail = 0; 
     // обнуляем счетчик доливок, если 
     countAdd = 0;                                   
    }
    if (useMultiFill || openedPosition!=BUY)
    // разрешаем возможность доливаться
    changeLotValid = true; 
    // выставляем флаг открытия позиции BUY
    openedPosition = BUY;                 
    // выставляем лот по умолчанию
    lotReal = lot;
    // вычисляем стоп лосс
    stopLoss = GetStopLoss();        
    // заполняем параметры открытия позиции
    pos_info.type = OP_BUY;
    pos_info.sl = stopLoss;    
    // открываем позицию на BUY
    ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing,100);

   }
  }
 }
 
 // если общая тенденция - вниз
 if (lastTendention == TENDENTION_DOWN && GetTendention (lastBarD1[1].open,curPriceAsk) == TENDENTION_DOWN)
 {                     
  // если текущая цена пробила один из экстемумов на одном из таймфреймов и текущее расхождение MACD НЕ противоречит текущему движению
  if ( ((beatM5=IsExtremumBeaten(1,SELL)) && (lastTrendPBI_1==SELL||usePBI==PBI_NO)) || 
       ((beatM15=IsExtremumBeaten(2,SELL))&& (lastTrendPBI_2==SELL||usePBI==PBI_NO)) || 
       ((beatH1=IsExtremumBeaten(3,SELL)) && (lastTrendPBI_3==SELL||usePBI==PBI_NO)))  
  {                
   // если спред не превышает заданное число пунктов
   if (LessDoubles(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD), spread))
   {    
    // если используются запреты по smydMACD
    if (useMACDLock)
     {
      // если пробили M5 и сигнал MACD на M5 противоположный, то зарпещаем открываться
      if (beatM5 && GetMACDSignal(handleMACDM5)==BUY)
       return;
      // если пробили M15 и сигнал MACD на M15 противоположный, то запрещаем открываться
      if (beatM15 && GetMACDSignal(handleMACDM15)==BUY)
       return;
      // если пробили H1 и сигнал MACD на H1 противоположный, то запрещаем открываться
      if (beatH1 && GetMACDSignal(handleMACDH1)==BUY)
       return;
     }   
    // если используются зарпеты по NineTeenLines
    if (useLinesLock)
     { 
     // получаем расстояния до ближайших уровней снизу и сверху
     lenClosestUp   = GetClosestLevel(BUY);
     lenClosestDown = GetClosestLevel(SELL);    
     // если получили сигнал запрета на вход
     if (lenClosestDown != 0 &&
         LessOrEqualDoubles(lenClosestDown, lenClosestUp*koLock) )
         {            
          return;
         }
     }
    // если позиция не была уже открыта на SELL
    if (openedPosition != SELL)
    {
     // обнуляем счетчик трейлинга
     indexForTrail = 0; 
     // обнуляем счетчик доливок
     countAdd = 0;  
    }
   }
   if (useMultiFill || openedPosition!=SELL)
   // разрешаем возможность доливаться
   changeLotValid = true; 
   // выставляем флаг открытия позиции SELL
   openedPosition = SELL;                 
   // выставляем лот по умолчанию
   lotReal = lot;    
   // вычисляем стоп лосс
   stopLoss = GetStopLoss();   
   // заполняем параметры открытия позиции
   pos_info.type = OP_SELL;
   pos_info.sl = stopLoss;    
   // открываем позицию на SELL 
  // ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing,100);
  }
 } 
}
  
// кодирование функций
ENUM_TENDENTION GetTendention (double priceOpen,double priceAfter)            // возвращает тенденцию по двум ценам
{
 if ( GreatDoubles (priceAfter,priceOpen) )
  return (TENDENTION_UP);
 if ( LessDoubles  (priceAfter,priceOpen) )
  return (TENDENTION_DOWN); 
 return (TENDENTION_NO); 
}

bool IsExtremumBeaten (int index,int direction)   // проверяет пробитие ценой экстремума
{
 switch (direction)
 {
  case SELL:
   if (LessDoubles(curPriceAsk,lastExtrLow[index].price)&& GreatDoubles(prevPriceAsk,lastExtrLow[index].price) && !extrLowBeaten[index])
   {      
    extrLowBeaten[index] = true;
    return (true);    
   }     
  break;
  case BUY:
   if (GreatDoubles(curPriceBid,lastExtrHigh[index].price) && LessDoubles(prevPriceBid,lastExtrHigh[index].price) && !extrHighBeaten[index])
   {
    extrHighBeaten[index] = true;
    return (true);
   }     
  break;
 }
 return (false);
}
 
void  ChangeTrailIndex()   // функция меняет индекс таймфрейма для трейлинга
{
  // трейлим стоп лосс
  if (indexForTrail < (lotCount-1))  // переходим на старший таймфрейм в случае, если сейчас не H1
  {
   // если пробили экстремум на более старшем таймфрейме
   if (IsExtremumBeaten ( indexForTrail+1, openedPosition) )
   {
    indexForTrail ++;  // то переходим на более старший таймфрейм
    changeLotValid = false; // запрещаем доливаться
   }
   else if (countAdd == lotCount)  // если было сделано 4 доливки
        {
         indexForTrail ++;  // то переходим на более старший таймфрейм 
         changeLotValid = false; // запрещаем доливаться
         countAdd = lotCount+1;
        }
  }
}
   
bool ChangeLot()    // функция изменяет размер лота, если это возможно (доливка)
{
 int cont = 0;
 double pricePos = ctm.GetPositionPrice(_Symbol);

// в зависимости от типа открытой позиции
 switch (openedPosition)
 {
  case BUY:  // если позиция открыта на BUY
   if ( blowInfo[0].GetLastExtrType() == EXTR_LOW )  // если последний экстремум LOW
   {
    if (IsExtremumBeaten(0,BUY) && 
        GreatDoubles(ctm.GetPositionStopLoss(_Symbol),pricePos)
       ) // если пробит экстремум и стоп лосс в безубытке
    {
     countAdd++; // увеличиваем счетчик доливок
     return (true);
    }
   } 
  break;
  case SELL: // если позиция открыта на SELL
   if ( blowInfo[0].GetLastExtrType() == EXTR_HIGH ) // если последний экстремум HIGH
   {
    if (IsExtremumBeaten(0,SELL) &&
        LessDoubles(ctm.GetPositionStopLoss(_Symbol),pricePos)
       ) // если пробит экстремум и стоп лосс в безубытке
    {
     cont++;
     countAdd++; // увеличиваем счетчик доливок
     return (true);
    }   
   }
  break;
 }
 return(false);
}
 
int GetStopLoss()     // вычисляет стоп лосс
{
 double slValue;          // значение стоп лосса
 double stopLevel;        // стоп левел
 stopLevel = SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point;  // получаем стоп левел
 switch (openedPosition)
 {
  case BUY:
   slValue = curPriceBid - blowInfo[0].GetExtrByIndex(EXTR_LOW,0).price; 
   if ( GreatDoubles(slValue,stopLevel) )
    return ( slValue/_Point );
   else
    return ( (stopLevel+0.0001)/_Point );
  case SELL:
   slValue = blowInfo[0].GetExtrByIndex(EXTR_HIGH,0).price - curPriceAsk;
   if ( GreatDoubles(slValue,stopLevel) )
    return ( slValue/_Point );     
   else
    return ( (stopLevel+0.0001)/_Point );     
 }
 return (0.0);
}
  
 int GetLastTrendDirection (int handle,ENUM_TIMEFRAMES period)   // возвращает true, если тендекция не противоречит последнему тренду на текущем таймфрейме
 {
  int copiedPBI=-1;     // количество скопированных данных PriceBasedIndicator
  int signTrend=-1;     // переменная для хранения знака последнего тренда
  int index=1;          // индекс бара
  int nBars;            // количество баров
  
  ArraySetAsSeries(pbiBuf,true);
  
  nBars = Bars(_Symbol,period);
  
  for (int attempts=0;attempts<25;attempts++)
   {
     copiedPBI = CopyBuffer(handle,4,1,nBars-1,pbiBuf);
     //Sleep(100);
   }
  if (copiedPBI < (nBars-1))
   {
   // Comment("Не удалось скопировать все бары");
    return (0);
   }
  for (index=0;index<nBars-1;index++)
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
       copiedPrice = CopyBuffer(handle_19Lines,indexPer*8+indexBuff*2+4,  0,1,  buffers[indexLines].price);
       copiedATR   = CopyBuffer(handle_19Lines,indexPer*8+indexBuff*2+5,  0,1,buffers[indexLines].atr);
       if (copiedPrice < 1 || copiedATR < 1)
        {
         Print("Не удалось прогрузить буферы индикатора NineTeenLines");
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
  
  // фунция возвращает сигнал на MACD
  int  GetMACDSignal (int handleMACD)
   {
    double bufMACD[];
    int copiedMACD;
    for (int attempts = 0; attempts < 5; attempts ++)
     {
       copiedMACD = CopyBuffer(handleMACD,1,1,lenToMACD,bufMACD);
     }
    if (copiedMACD < lenToMACD)
     {
      Print("Ошибка! Не удалось прогрузить буфер smydMACD");
      return (0);
     }
    // проходим по массиву сигналов MACD и ищем последнее расхождение
    for (int ind=lenToMACD-1;ind>=0;ind--)
     {
      if (int(bufMACD[ind])!=0)
       {
        //Comment("сигнал = ",int(bufMACD[ind])," индекс = ",ind );     
        return ( int(bufMACD[ind]) );
       }
     }
     //Comment("Нет сигнала");
    return (0);
   }
   
   