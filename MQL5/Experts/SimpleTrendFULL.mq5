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
input int    spread   = 30;                        // максимально допустимый размер спреда в пунктах на открытие и доливку позиции
// необходимые буферы
MqlRates lastBarD1[];                              // буфер цен на дневнике
// буфер для хранения PriceBasedIndicator
double pbiBuf[];
// буферы для проверки пробития экстремумов
int      countExtrHigh[4];                         // массив счетчиков экстремумов HIGH
int      countExtrLow[4];                          // массив счетчиков экстремумов LOW
int      countLastExtrHigh[4];                     // массив последних значений счетчиков экстремумов HIGH 
int      countLastExtrLow[4];                      // массив послених значений счетчиков экстремумов LOW
bool     beatenExtrHigh[4];                        // массив флагов пробития экстремумов HIGH
bool     beatenExtrLow[4];                         // массив флагов пробития экстремумов LOW
// объекты классов
CTradeManager *ctm;                                // объект торговой библиотеки                             
CisNewBar     *isNewBar_D1;                        // новый бар на D1
CBlowInfoFromExtremums *blowInfo[4];               // массив объектов класса получения информации об экстремумах индикатора DrawExtremums 
// дополнительные системные переменные
bool             firstLaunch       = true;         // флаг первого запуска эксперта
bool             changeLotValid;                   // флаг возможности доливки на M1
bool             beatM5;                           // флаг пробития на M5
bool             beatM15;                          // флаг пробития на M15
bool             beatH1;                           // флаг пробития на H1
int              openedPosition    = NO_POSITION;  // тип открытой позиции 
int              stopLoss;                         // стоп лосс
int              indexForTrail     = 0;            // индекс для трейлинга
 
int              tmpLastBar;

double           curPriceAsk       = 0;            // для хранения текущей цены Ask
double           curPriceBid       = 0;            // для хранения текущей цены Bid 
double           prevPriceAsk      = 0;            // для хранения предыдущей цены Ask
double           prevPriceBid      = 0;            // для хранения предыдущей цены Bid
double           lotReal;                          // действительный лот

ENUM_TENDENTION lastTendention, currentTendention; // переменные для хранения направления предыдущего и текущего баров

// структуры для работы с позициями            
SPositionInfo pos_info;                            // информация об открытии позиции 
STrailing trailing;                                // параметры трейлинга
                           
int OnInit()
 {     
  // инициализация массивов
  ArrayInitialize(countExtrHigh,0);
  ArrayInitialize(countExtrLow,0);
  ArrayInitialize(countLastExtrHigh,0);
  ArrayInitialize(countLastExtrLow,0);
  ArrayInitialize(beatenExtrHigh,false);
  ArrayInitialize(beatenExtrLow,false);      
  // создаем объект класса TradeManager
  ctm = new CTradeManager();  
  // создаем объекты класса CisNewBar
  isNewBar_D1  = new CisNewBar(_Symbol,PERIOD_D1);
  // создаем объекты класса CBlowInfoFromExtremums
  blowInfo[0]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_M1,100,30,30,217);  // M1 
  blowInfo[1]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_M5,100,30,30,217);  // M5 
  blowInfo[2]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_M15,100,30,30,217); // M15 
  blowInfo[3]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_H1,100,30,30,217);  // H1          
  if (!blowInfo[0].IsInitFine())
     return (INIT_FAILED);
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
  trailing.handlePBI    = 0;  
  
  return(INIT_SUCCEEDED);
 }
 
void OnDeinit(const int reason)
  {
   ArrayFree(lastBarD1);
   ArrayFree(pbiBuf);
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
 int copied = 0;        // Количество скопированных данных из буфера
 int attempts = 0;      // Количество попыток копирования данных из буфера

 ctm.OnTick(); 
 ctm.UpdateData();
 ctm.DoTrailing(blowInfo[indexForTrail]); 

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
 // получаем новые значения счетчиков экстремумов
 for (int ind=0;ind<4;ind++)
  {
   countExtrHigh[ind] = blowInfo[ind].GetExtrCountHigh();   // получаем текущее значение счетчика экстремумов HIGH
   countExtrLow[ind]  = blowInfo[ind].GetExtrCountLow();    // получаем текущее значение счетчика экстремумов LOW
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
 // если это первый запуск эксперта или сформировался новый бар 
 if (firstLaunch || isNewBar_D1.isNewBar() > 0)
 {
  firstLaunch = false;
  do
  {
   copied = CopyRates(_Symbol,PERIOD_D1,0,2,lastBarD1);
   attempts++;
   PrintFormat("attempts = %d, copied = %d", attempts, copied);
  }
  while (copied < 2 && attempts < 5 && !IsStopped());
  
  if (copied == 2 )     
  {
   lastTendention = GetTendention(lastBarD1[0].open, lastBarD1[0].close);        // получаем предыдущую тенденцию 
   copied = 0;
   attempts = 0;
 }
 }
 
 // если нет открытых позиций
 if (ctm.GetPositionCount() == 0)
  openedPosition = NO_POSITION;
 else    // иначе меняем индекс трейлинга и доливаемся, если это возможно
 {
  ChangeTrailIndex();                            // то меняем индекс трейлинга      
 }
 
 currentTendention = GetTendention(lastBarD1[1].open, curPriceBid);
// Comment(StringFormat("lastTendention = %s, currentTendention = %s", TendentionToString(lastTendention), TendentionToString(currentTendention)));
 // если общая тенденция  - вверх
 if (lastTendention == TENDENTION_UP && currentTendention == TENDENTION_UP)
 {   
  // если текущая цена пробила один из экстемумов на одном из таймфреймов и текущее расхождение MACD НЕ противоречит текущему движению
  if ( (beatM5  =  IsExtremumBeaten(1,BUY) )  || 
       (beatM15 =  IsExtremumBeaten(2,BUY) )  || 
       (beatH1  =  IsExtremumBeaten(3,BUY) )   )
   {      
    // если позиция не была уже открыта на BUY   
    if (openedPosition != BUY)
    {
     // обнуляем счетчик трейлинга
     indexForTrail = 0;                                  
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
    // открываем позицию на BUY
   ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing, spread);
   }
  }
 
 // если общая тенденция - вниз
 if (lastTendention == TENDENTION_DOWN && currentTendention == TENDENTION_DOWN)
 {                     
  // если текущая цена пробила один из экстемумов на одном из таймфреймов и текущее расхождение MACD НЕ противоречит текущему движению
  if ( (beatM5   =  IsExtremumBeaten(1,SELL))  || 
       (beatM15  =  IsExtremumBeaten(2,SELL))  || 
       (beatH1   =  IsExtremumBeaten(3,SELL)) )  
  {                
    // если позиция не была уже открыта на SELL
    if (openedPosition != SELL)
    {
     // обнуляем счетчик трейлинга
     indexForTrail = 0; 
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
   // открываем позицию на SELL 
   ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing, spread);
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
 switch (direction)
 {
  case SELL:
   if (LessDoubles(curPriceBid,blowInfo[index].GetExtrByIndex(EXTR_LOW,0).price)&& GreatDoubles(prevPriceBid,blowInfo[index].GetExtrByIndex(EXTR_LOW,0).price) && !beatenExtrLow[index])
   {
    beatenExtrLow[index] = true;
    return (true);    
   }     
  break;
  case BUY:
   if (GreatDoubles(curPriceBid,blowInfo[index].GetExtrByIndex(EXTR_HIGH,0).price) && LessDoubles(prevPriceBid,blowInfo[index].GetExtrByIndex(EXTR_HIGH,0).price) && !beatenExtrHigh[index])
   {
    beatenExtrHigh[index] = true;
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
   // если пробили экстремум на более старшем таймфрейме
   if (IsExtremumBeaten ( indexForTrail+1, openedPosition) )
   {
    indexForTrail ++;  // то переходим на более старший таймфрейм
   }
  }
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