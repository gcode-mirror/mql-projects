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

/// входные параметры
input string baseParam = "";                       // Базовые параметры
input double lot      = 1;                         // размер лота
input double lotStep  = 1;                         // размер шага увеличения лота
input int    lotCount = 3;                         // количество доливок
input int    spread   = 30;                        // максимально допустимый размер спреда в пунктах на открытие и доливку позиции
input string addParam = "";                        // Настройки
input bool   useMultiFill=true;                    // Использовать доливки при переходе на старш. период
input int    pbiDepth = 1000;                      // глубина вычисления индикатора PBI
input int    addToStopLoss = 50;                   // прибавка пунктов к начальному стоп лоссу
input  int    koLock         = 2;                  // коэффициент запрета на вход 

// структура уровней
struct bufferLevel
 {
  double price[];  // цена уровня
  double atr[];    // ширина уровня
 };

// хэндлы индикатора SmydMACD
int handleSmydMACD_M5;                             // хэндл индикатора расхождений MACD на минутке
int handleSmydMACD_M15;                            // хэндл индикатора расхождений MACD на 15 минутах
int handleSmydMACD_H1;                             // хэндл индикатора расхождений MACD на часовике
// хэндлы Price Based Indicator
int handlePBI_M1;                                  // хэндл PriceBasedIndicator M1
int handlePBI_M5;                                  // хэндл PriceBasedIndicator M5
int handlePBI_M15;                                 // хэндл PriceBasedIndicator M15
int handlePBI_H1;                                  // хэндл PriceBasedIndicator MH1
// хэндл NineTeenLines
int handle_19Lines;
// необходимые буферы
MqlRates lastBarD1[];                              // буфер цен на дневнике
// буферы для хранения расхождений на MACD
double divMACD_M5[];                               // на пятиминутке
double divMACD_M15[];                              // на 15-минутке
double divMACD_H1[];                               // на часовике
// буфер для хранения PriceBasedIndicator
double pbiBuf[];
// массив уровней
bufferLevel buffers[10];                                                 // буфер уровней
// буферы для проверки пробития экстремумов
Extr             lastExtrHigh[4];                  // буфер последних экстремумов по HIGH
Extr             lastExtrLow[4];                   // буфер последних экстремумов по LOW
Extr             currentExtrHigh[4];               // буфер текущих экстремумов по HIGH
Extr             currentExtrLow[4];                // буфер текущих экстремумов по LOW
bool             extrHighBeaten[4];                // буфер флагов пробития экстремумов HIGH
bool             extrLowBeaten[4];                 // буфер флагов пробития экстремумов LOW

// объекты классов
CTradeManager *ctm;                                // объект торговой библиотеки
CisNewBar     *isNewBar_D1;                        // новый бар на D1
CBlowInfoFromExtremums *blowInfo[4];               // массив объектов класса получения информации об экстремумах индикатора DrawExtremums 

// дополнительные системные переменные
bool             firstLaunch       = true;         // флаг первого запуска эксперта
bool             changeLotValid;                   // флаг возможности доливки на M1
int              openedPosition    = NO_POSITION;  // тип открытой позиции 
int              stopLoss;                         // стоп лосс
int              indexForTrail     = 0;            // индекс для трейлинга
int              countAdd          = 0;            // количество доливок

int              lastTrendM5       = 0;            // тип последнего тренда по PBI M5
int              lastTrendM15      = 0;            // тип последнего тренда по PBI M15
int              lastTrendH1       = 0;            // тип последнего тренда по PBI H1
int              tmpLastBar;

double           curPriceAsk       = 0;            // для хранения текущей цены Ask
double           curPriceBid       = 0;            // для хранения текущей цены Bid 
double           prevPriceAsk      = 0;            // для хранения предыдущей цены Ask
double           prevPriceBid      = 0;            // для хранения предыдущей цены Bid
double           lotReal;                          // действительный лот
double           lenClosestUp;                     // расстояние до ближайшего уровня сверху
double           lenClosestDown;                   // расстояние до ближайшего уровня снизу 
ENUM_TENDENTION  lastTendention;                   // переменная для хранения последней тенденции
// флаги пробития экстремумов для получения сигнала
bool             M5,M15,H1;
                           
SPositionInfo pos_info;
STrailing trailing;                           
                           
int OnInit()
  {
   // пытаемся инициализировать хэндлы расхождений MACD 
   handleSmydMACD_M5  = iCustom(_Symbol,PERIOD_M5,"smydMACD","");  
   handleSmydMACD_M15 = iCustom(_Symbol,PERIOD_M15,"smydMACD","");    
   handleSmydMACD_H1  = iCustom(_Symbol,PERIOD_H1,"smydMACD","");   

   //iCustom(_Symbol,_Period,"NineteenLines");  
          
   if (handleSmydMACD_M5  == INVALID_HANDLE || handleSmydMACD_M15 == INVALID_HANDLE || handleSmydMACD_H1 == INVALID_HANDLE)
    {
     Print("Ошибка при инициализации эксперта SimpleTrend. Не удалось создать хэндл индикатора SmydMACD ");
     return (INIT_FAILED);
    }
   // пытаемся инициализировать хэндл NineTeenLines      
   handle_19Lines = iCustom(_Symbol,_Period,"NineteenLines");     
   if (handle_19Lines == INVALID_HANDLE)
     {
      Print("Не удалось получить хэндл NineteenLines");
      return (INIT_FAILED);
     }     
   // пытаемся инициализировать хэндл PriceBasedIndicator
   handlePBI_M5  = iCustom(_Symbol,PERIOD_M5,"PriceBasedIndicator");
   handlePBI_M15 = iCustom(_Symbol,PERIOD_M15,"PriceBasedIndicator");    
   handlePBI_H1  = iCustom(_Symbol,PERIOD_H1,"PriceBasedIndicator");   
   if ( handlePBI_M5 == INVALID_HANDLE || 
       handlePBI_M15 == INVALID_HANDLE || handlePBI_H1 == INVALID_HANDLE)
    {
     Print("Ошибка при иниализации эксперта SimpleTrend. Не удалось создать хэндл индикатора PriceBasedIndicator");
     return (INIT_FAILED);
    } 
   // получаем последний тип тренда на 3-х таймфреймах
   lastTrendM5  = GetLastTrendDirection(handlePBI_M5,PERIOD_M5);
   lastTrendM15 = GetLastTrendDirection(handlePBI_M15,PERIOD_M15);
   lastTrendH1  = GetLastTrendDirection(handlePBI_H1,PERIOD_H1);            
   // создаем объект класса TradeManager
   ctm = new CTradeManager();                    
   // создаем объекты класса CisNewBar
   isNewBar_D1  = new CisNewBar(_Symbol,PERIOD_D1);
   // создаем объекты класса CBlowInfoFromExtremums
   blowInfo[0]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_M1,1000,30,30,217);  // M1 
   blowInfo[1]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_M5,1000,30,30,217);  // M5 
   blowInfo[2]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_M15,1000,30,30,217); // M15 
   blowInfo[3]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_H1,1000,30,30,217);  // H1          
   if (!blowInfo[0].IsInitFine() )
        return (INIT_FAILED);
   // пытаемся загрузить экстремумы
   if ( blowInfo[0].Upload(EXTR_BOTH,TimeCurrent(),1000) &&
        blowInfo[1].Upload(EXTR_BOTH,TimeCurrent(),1000) &&
        blowInfo[2].Upload(EXTR_BOTH,TimeCurrent(),1000) &&
        blowInfo[3].Upload(EXTR_BOTH,TimeCurrent(),1000)
    )
    {
     // получаем первые экстремумы
     for (int index = 0; index < 4; index++)
     {
      lastExtrHigh[index]   =  blowInfo[index].GetExtrByIndex(EXTR_HIGH,0);  // сохраним значение последнего экстремума HIGH
      lastExtrLow[index]    =  blowInfo[index].GetExtrByIndex(EXTR_LOW,0);   // сохраним значение последнего экстремума LOW
     }
    }
   else
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
   // освобождаем буферы
   ArrayFree(divMACD_M5);
   ArrayFree(divMACD_M15);
   ArrayFree(divMACD_H1);
   ArrayFree(lastBarD1);
   // удаляем все индикаторы
   IndicatorRelease(handleSmydMACD_M5);
   IndicatorRelease(handleSmydMACD_M15);   
   IndicatorRelease(handleSmydMACD_H1);
   IndicatorRelease(handlePBI_H1);
   IndicatorRelease(handlePBI_M15);
   IndicatorRelease(handlePBI_M5);
   IndicatorRelease(handle_19Lines);
   // удаляем объекты классов
   delete ctm;
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
 // если не удалось прогрузить буферы уровней
 if (!UploadBuffers())
  return;
 prevPriceAsk = curPriceAsk;                             // сохраним предыдущую цену Ask
 prevPriceBid = curPriceBid;                             // сохраним предыдущую цену Bid
 curPriceBid  = SymbolInfoDouble(_Symbol, SYMBOL_BID);   // получаем текущую цену Bid    
 curPriceAsk  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);   // получаем текущую цену Ask
 
 if (!blowInfo[0].Upload(EXTR_BOTH,TimeCurrent(),1000) ||
     !blowInfo[1].Upload(EXTR_BOTH,TimeCurrent(),1000) ||
     !blowInfo[2].Upload(EXTR_BOTH,TimeCurrent(),1000) ||
     !blowInfo[3].Upload(EXTR_BOTH,TimeCurrent(),1000)
    )
 {   
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
 
 // обновляем значения последних трендов
 tmpLastBar = GetLastMoveType(handlePBI_M5);
 if (tmpLastBar != 0)
  lastTrendM5 = tmpLastBar;
  
 tmpLastBar = GetLastMoveType(handlePBI_M15);
 if (tmpLastBar != 0)
  lastTrendM15 = tmpLastBar;
  
 tmpLastBar = GetLastMoveType(handlePBI_H1);
 if (tmpLastBar != 0)
  lastTrendH1 = tmpLastBar;    
  
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
  if (countAdd < 4 && changeLotValid)            // если было совершено меньше 4-х доливок и есть разрешение на доливку
  {
   if (ChangeLot())                           // если получили сигнал на доливание 
   {
    ctm.PositionChangeSize(_Symbol, lotStep);   // доливаемся 
   }       
  }        
 }
 
 // если общая тенденция  - вверх
 if (lastTendention == TENDENTION_UP && GetTendention (lastBarD1[1].open,curPriceBid) == TENDENTION_UP)
 {   
  // если текущая цена пробила один из экстемумов на одном из таймфреймов и текущее расхождение MACD НЕ противоречит текущему движению
  if (( (M5=IsExtremumBeaten(1,BUY)) || (M15=IsExtremumBeaten(2,BUY)) || (H1=IsExtremumBeaten(3,BUY)) ) /*&& IsMACDCompatible(BUY) */)
  { 
   // получаем расстояния до ближайших уровней снизу и сверху
   lenClosestUp   = GetClosestLevel(BUY);
   lenClosestDown = GetClosestLevel(SELL);  
   // если ближайший уровень сверху отсутствует, или дальше билжайшего уровня снизу
   if (lenClosestUp == 0 || 
       GreatDoubles(lenClosestUp, lenClosestDown*koLock) )
    {   
     // если пробит верхний экстремум на H1, но последний тренд на H1 в противоположную сторону      
     if (H1 && lastTrendH1==-1 )
      {
       Comment("Пробит H1");    
       return;
      }
     // если пробит верхний экстремум на M15, но последний тренд на M15 в противоположную сторону      
     if (M15 && lastTrendM15==-1 )
      {
       Comment("Пробит M15");    
       return;
      }
     // если пробит верхний экстремум на M5, но последний тренд на M5 в противоположную сторону      
     if (M5 && lastTrendM5==-1 )
      {
       Comment("Пробит M5");     
       return;
      }
       
    // если спред не превышает заданное число пунктов
    if (LessDoubles(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD), spread))
     {
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
     // открываем позицию на BUY
     pos_info.type = OP_BUY;
     pos_info.sl = stopLoss;
     ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing);
   } // конец от проверки на уровни
   
   }
  }
 }
 
 // если общая тенденция - вниз
 if (lastTendention == TENDENTION_DOWN && GetTendention (lastBarD1[1].open,curPriceAsk) == TENDENTION_DOWN)
 {                     
  // если текущая цена пробила один из экстемумов на одном из таймфреймов и текущее расхождение MACD НЕ противоречит текущему движению
  if (( (M5=IsExtremumBeaten(1,SELL))  || (M15=IsExtremumBeaten(2,SELL)) || (H1=IsExtremumBeaten(3,SELL)) ) /*&& IsMACDCompatible(SELL)*/)
  {    
   // получаем расстояния до ближайших уровней снизу и сверху
   lenClosestUp   = GetClosestLevel(BUY);
   lenClosestDown = GetClosestLevel(SELL);
   // если ближайший уровень снизу отсутствует, или дальше ближайшего уровня сверху
    if (lenClosestDown == 0 ||
        GreatDoubles(lenClosestDown, lenClosestUp*koLock) )
       {      
        // если пробит нижний экстремум на H1, но последний тренд на H1 в противоположную сторону      
        if (H1 && lastTrendH1==1 )
         {
          Comment("Пробит H1");
          return;
         }
        // если пробит нижний экстремум на M15, но последний тренд на M15 в противоположную сторону      
        if (M15 && lastTrendM15==1 )
         {
          Comment("Пробит M15");    
          return;
         }
        // если пробит нижний экстремум на M5, но последний тренд на M5 в противоположную сторону      
        if (M5 && lastTrendM5==1 )
         {
          Comment("Пробит M5");    
          return;
         }              
        // если спред не превышает заданное число пунктов
        if (LessDoubles(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD), spread))
         {             
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
        // открываем позицию на SELL
        pos_info.type = OP_SELL;
        pos_info.sl = stopLoss;
        ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing);
     }// конец проверки на уровни
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
  
bool IsMACDCompatible(int direction)        // проверяет, не противоречит ли расхождение MACD текущей тенденции
{
 int copiedMACD_M5  = CopyBuffer(handleSmydMACD_M5,1,0,1,divMACD_M5);
 int copiedMACD_M15 = CopyBuffer(handleSmydMACD_M15,1,0,1,divMACD_M15);
 int copiedMACD_H1  = CopyBuffer(handleSmydMACD_H1,1,0,1,divMACD_H1);   
 if (copiedMACD_M5  < 1 || copiedMACD_M15 < 1 || copiedMACD_H1  < 1)
 {
  Print("Ошибка эксперта SimpleTrend. Не удалось получить данные о расхождениях");
  return (false);
 }        
 // dir = 1 или -1, div = -1 или 1; Если расхождение против направления, то рез-т будет 0 = false, в противном случае true
 return ((divMACD_M5[0]+direction) && (divMACD_M15[0]+direction) && (divMACD_H1[0]+direction));
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
 if (indexForTrail < 3)  // переходим на старший таймфрейм в случае, если сейчас не H1
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
    return ( (slValue/_Point)+addToStopLoss );
   else
    return ( ((stopLevel+0.0001)/_Point)+addToStopLoss );
  case SELL:
   slValue = blowInfo[0].GetExtrByIndex(EXTR_HIGH,0).price - curPriceAsk;
   if ( GreatDoubles(slValue,stopLevel) )
    return ( (slValue/_Point)+addToStopLoss );     
   else
    return ( ((stopLevel+0.0001)/_Point)+addToStopLoss );     
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
  
  for (index=1;index<nBars;index++)
   {
    copiedPBI = CopyBuffer(handle,4,index,1,pbiBuf);
    if (copiedPBI < 1)
     return(0);
    signTrend = int(pbiBuf[0]);
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
  
  string GetLT(int type)
   {
    if (type == 1)
     return "тренд вверх";
    if (type == -1)
     return "тренд вниз";
    return "нет тренда";
   }
   
bool UploadBuffers ()   // получает последние значения уровней
 {
  int copiedPrice;
  int copiedATR;
  int indexPer;
  int indexBuff;
  int indexLines = 0;
  for (indexPer=0;indexPer<5;indexPer++)
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
      for (index=0;index<10;index++)
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
      for (index=0;index<10;index++)
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
     