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
 
// входные параметры
input double lot      = 0.20;                      // размер лота
input double lotStep  = 0.20;                      // размер шага увеличения лота
input int    lotCount = 4;                         // количество доливок
input int    spread   = 30;                        // максимально допустимый размер спреда в пунктах на открытие и доливку позиции

// хэндлы индикатора SmydMACD
int handleSmydMACD_M5;                             // хэндл индикатора расхождений MACD на минутке
int handleSmydMACD_M15;                            // хэндл индикатора расхождений MACD на 15 минутах
int handleSmydMACD_H1;                             // хэндл индикатора расхождений MACD на часовике

// необходимые буферы
MqlRates lastBarD1[];                              // буфер цен на дневнике
// буферы для хранения расхождений на MACD
double divMACD_M5[];                               // на пятиминутке
double divMACD_M15[];                              // на 15-минутке
double divMACD_H1[];                               // на часовике
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
double           curPriceAsk       = 0;            // для хранения текущей цены Ask
double           curPriceBid       = 0;            // для хранения текущей цены Bid 
double           prevPriceAsk      = 0;            // для хранения предыдущей цены Ask
double           prevPriceBid      = 0;            // для хранения предыдущей цены Bid
double           lotReal;                          // действительный лот
ENUM_TENDENTION  lastTendention;                   // переменная для хранения последней тенденции
                           
int OnInit()
  {
   // пытаемся инициализировать хэндлы расхождений MACD 
   handleSmydMACD_M5  = iCustom(_Symbol,PERIOD_M5,"smydMACD","");  
   handleSmydMACD_M15 = iCustom(_Symbol,PERIOD_M15,"smydMACD","");    
   handleSmydMACD_H1  = iCustom(_Symbol,PERIOD_H1,"smydMACD","");   
   if (handleSmydMACD_M5  == INVALID_HANDLE || handleSmydMACD_M15 == INVALID_HANDLE || handleSmydMACD_H1 == INVALID_HANDLE)
    {
     Print("Ошибка при инициализации эксперта SimpleTrend. Не удалось создать хэндл индикатора SmydMACD ");
     return (INIT_FAILED);
    }              
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
 Comment("Индекс трейла = ",indexForTrail);
 prevPriceAsk = curPriceAsk;                             // сохраним предыдущую цену Ask
 prevPriceBid = curPriceBid;                             // сохраним предыдущую цену Bid
 curPriceBid  = SymbolInfoDouble(_Symbol, SYMBOL_BID);   // получаем текущую цену Bid    
 curPriceAsk  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);   // получаем текущую цену Ask
 if (blowInfo[0].Upload(EXTR_BOTH,TimeCurrent(),1000) &&
     blowInfo[1].Upload(EXTR_BOTH,TimeCurrent(),1000) &&
     blowInfo[2].Upload(EXTR_BOTH,TimeCurrent(),1000) &&
     blowInfo[3].Upload(EXTR_BOTH,TimeCurrent(),1000)
    )
 {   
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
   // если текущая цена пробила один из экстемумов на одном из таймфреймов
   if ( IsExtremumBeaten(1,BUY) || IsExtremumBeaten(2,BUY) || IsExtremumBeaten(3,BUY) )
   { 
    // если текущее расхождение MACD НЕ противоречит текущему движению
    if (IsMACDCompatible(BUY))
    {                       
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
      // разрешаем возможность доливаться
      changeLotValid = true; 
      // выставляем флаг открытия позиции BUY
      openedPosition = BUY;                 
      // выставляем лот по умолчанию
      lotReal = lot;
      // вычисляем стоп лосс
      stopLoss = GetStopLoss();             
      // открываем позицию на BUY
      ctm.OpenUniquePosition(_Symbol, _Period, OP_BUY, lotReal, stopLoss, 0,TRAILING_TYPE_EXTREMUMS);
     }
    } 
   }
  }
  // если общая тенденция - вниз
  if (lastTendention == TENDENTION_DOWN && GetTendention (lastBarD1[1].open,curPriceAsk) == TENDENTION_DOWN)
  {                     
   // если текущая цена пробила один из экстемумов на одном из таймфреймов
   if ( IsExtremumBeaten(1,SELL) || IsExtremumBeaten(2,SELL) || IsExtremumBeaten(3,SELL) )
   {                
    // если текущее расхождение MACD НЕ противоречит текущему движению
    if (IsMACDCompatible(SELL))
    {
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
      // разрешаем возможность доливаться
      changeLotValid = true; 
      // выставляем флаг открытия позиции SELL
      openedPosition = SELL;                 
      // выставляем лот по умолчанию
      lotReal = lot;    
      // вычисляем стоп лосс
      stopLoss = GetStopLoss();    
      // открываем позицию на SELL
      ctm.OpenUniquePosition(_Symbol, _Period, OP_SELL, lotReal, stopLoss, 0,TRAILING_TYPE_EXTREMUMS);
     }
    } 
   }      
  }
 }  // END OF UPLOAD EXTREMUMS
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
  // если пробили экстремум на более старшем таймфрейме
  if (IsExtremumBeaten ( indexForTrail+1, openedPosition) )
  {
   indexForTrail ++;  // то переходим на более старший таймфрейм
   changeLotValid = false; // запрещаем доливаться
  }
  else if (countAdd == 4)  // если было сделано 4 доливки
       {
        indexForTrail ++;  // то переходим на более старший таймфрейм 
        changeLotValid = false; // запрещаем доливаться
        countAdd = 5;
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
     Comment("Пробит экстремум = ",cont);
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
 Alert("А стопа нет");
 return (0.0);
}
  