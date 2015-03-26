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
#include <Constants.mqh>                        // библиотека констант
#define ADD_TO_STOPPLOSS 50
// константы сигналов
#define BUY   1    
#define SELL -1
//+------------------------------------------------------------------+
//| Эксперт, основанный на расхождении MACD                          |
//+------------------------------------------------------------------+                                                                    
// входные параметры
sinput string base_param                           = "";                 // БАЗОВЫЕ ПАРАМЕТРЫ ЭКСПЕРТА
input  double lot                                  = 0.1;                // Лот                
input  int    spread                               = 300;                // Размер спреда 
input  int    koLock                               = 2;                  // коэффициент запрета на вход
sinput string trailingStr                          = "";                 // ПАРАМЕТРЫ трейлинга
input ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_PBI;               // тип трейлинга
input int     trStop                               = 100;                // Trailing Stop
input int     trStep                               = 100;                // Trailing Step
input int     minProfit                            = 250;                // минимальная прибыль
input string  lineParams                           = "";                 // ПАРАМЕТРЫ 19 ЛИНИЙ
input bool    use19Lines                           = true;               // использовать запрет на вход 19 линий
// структура уровней
struct bufferLevel
 {
  double price[];  // цена уровня
  double atr[];    // ширина уровня
 };
// объекты
CTradeManager    *ctm;                                                   // указатель на объект торговой библиотеки
static CisNewBar *isNewBar;                                              // для проверки формирования нового бара
SPositionInfo pos_info;
STrailing trailing;
// хэндлы индикаторов 
int handleSmydMACD;                                                      // хэндл индикатора ShowMeYourDivMACD
int handle_PBI;                                                          // хэндл PriceBasedIndicator
int handle_19Lines;                                                      // хэндл 19 Lines
// переменные эксперта
int    stopLoss;                                                         // переменная для хранения действительного стоп лосса
double currentPrice;                                                     // текущая цена
double lenClosestUp;                                                     // расстояние до ближайшего уровня сверху
double lenClosestDown;                                                   // расстояние до ближайшего уровня снизу    
// буферы 
double signalBuffer[];                                                   // буфер для получения сигнала из индикатора smydMACD
bufferLevel buffers[10];                                                 // буфер уровней

int OnInit()
{
 // выделяем память под объект тороговой библиотеки
 isNewBar = new CisNewBar(_Symbol, _Period);
 ctm = new CTradeManager(); 
 // если трейлинш по PBI
 if (trailingType == TRAILING_TYPE_PBI)
  {
 handle_PBI = iCustom(_Symbol, _Period, "PriceBasedIndicator", 1000, 1, 1.5);
 if(handle_PBI == INVALID_HANDLE)                                //проверяем наличие хендла индикатора
  {
   Print("Не удалось получить хендл Price Based Indicator");      //если хендл не получен, то выводим сообщение в лог об ошибке
   return(INIT_FAILED); 
  }
  }
  // если используется запрет на вход по 19 линиям
  if (use19Lines)
   {
    handle_19Lines = iCustom(_Symbol,_Period,"NineteenLines");       
  if (handle_19Lines == INVALID_HANDLE)
   {
    Print("Не удалось получить хэндл NineteenLines");
    return(INIT_FAILED);    
   }
  }    
 // создаем хэндл индикатора ShowMeYourDivMACD
 handleSmydMACD = iCustom (_Symbol,_Period,"smydMACD");   
 if ( handleSmydMACD == INVALID_HANDLE )
 {
  Print("Ошибка при инициализации эксперта ONODERA. Не удалось создать хэндл ShowMeYourDivMACD");
  return(INIT_FAILED);
 }
   pos_info.tp = 0;
   pos_info.volume = lot;
   pos_info.expiration = 0;
   pos_info.priceDifference = 0;
   trailing.trailingType = trailingType;
   trailing.minProfit    = minProfit;
   trailing.trailingStop = trStop;
   trailing.trailingStep = trStep;
   trailing.handleForTrailing    = handle_PBI;
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 // удаляем объект класса TradeManager
 delete isNewBar;
 delete ctm;
 // удаляем индикаторы
 IndicatorRelease(handleSmydMACD);
 if (use19Lines)
 IndicatorRelease(handle_19Lines);
 if (trailingType == TRAILING_TYPE_PBI)
 IndicatorRelease(handle_PBI);
}

void OnTick()
{
 ctm.OnTick();
 if (trailingType!=TRAILING_TYPE_NONE)
 ctm.DoTrailing();
 // если не удалось прогрузить буферы уровней
 if (use19Lines)
  {
 if (!UploadBuffers())
  return;
  }
   if (CopyBuffer(handleSmydMACD,1,0,1,signalBuffer) < 1)
    {
     PrintFormat("Не удалось прогрузить все буферы Error=%d",GetLastError());
     return;
    }   
   if ( signalBuffer[0] == BUY)  // получили расхождение на покупку
     { 
      currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      // если используется запрет на вход по 19 линиям
      if (use19Lines)
       {
        // получаем расстояния до ближайших уровней снизу и сверху
        lenClosestUp    = GetClosestLevel(BUY);
        lenClosestDown  = GetClosestLevel(SELL);
        // если ближайший уровень сверху отсутствует, или дальше билжайшего уровня снизу
        if (lenClosestUp != 0 && 
            LessOrEqualDoubles(lenClosestUp, lenClosestDown*koLock) )
             {
              return;
             }
       }
        // то открываем позицию на BUY
        stopLoss  =  CountStoploss(BUY);       
        pos_info.type = OP_BUY;
        pos_info.sl = stopLoss;
        ctm.OpenUniquePosition(_Symbol,_Period, pos_info, trailing,spread);                
       }
   if ( signalBuffer[0] == SELL) // получили расхождение на продажу
     {     
      currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);  
      // если используется запрет по 19 линиям
      if (use19Lines) 
       {
      // получаем расстояния до ближайших уровней снизу и сверху
      lenClosestUp   = GetClosestLevel(BUY);
      lenClosestDown = GetClosestLevel(SELL);      
      // если ближайший уровень снизу отсутствует, или дальше ближайшего уровня сверху
        if (lenClosestDown != 0 &&
            LessOrEqualDoubles(lenClosestDown, lenClosestUp*koLock) )
             {    
              return;
             }
     }
      // то открываем позицию на SELL
      stopLoss  =  CountStoploss(SELL);       
      pos_info.type = OP_SELL;
      pos_info.sl = stopLoss;
      ctm.OpenUniquePosition(_Symbol,_Period, pos_info, trailing,spread);          
   }  
}

int CountStoploss(int point)
{
 int stopLoss = 0;
 int direction;
 double priceAB;
 double bufferStopLoss[];
 ArraySetAsSeries(bufferStopLoss, true);
 ArrayResize(bufferStopLoss, 1000); 
 int extrBufferNumber;
 if (point > 0)
 {
  extrBufferNumber = 6;
  priceAB = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
  direction = 1;
 }
 else
 {
  extrBufferNumber = 5; // Если point > 0 возьмем буфер с минимумами, иначе с максимумами
  priceAB = SymbolInfoDouble(_Symbol, SYMBOL_BID);
  direction = -1;
 }
 int copiedPBI = -1;
 for(int attempts = 0; attempts < 25; attempts++)
 {
  Sleep(100);
  copiedPBI = CopyBuffer(handle_PBI, extrBufferNumber, 0,1000, bufferStopLoss);
 }
 if (copiedPBI < 1000)
 {
  PrintFormat("%s Не удалось скопировать буфер bufferStopLoss", MakeFunctionPrefix(__FUNCTION__));
  return(0);
 }
 for(int i = 0; i < 1000; i++)
 {
  if (bufferStopLoss[i] > 0)
  {
   if (LessDoubles(direction*bufferStopLoss[i], direction*priceAB))
   {
    stopLoss = (int)(MathAbs(bufferStopLoss[i] - priceAB)/Point()) + ADD_TO_STOPPLOSS;
    break;
   }
  }
 }
 if (stopLoss <= 0)  
 {
  PrintFormat("Не поставили стоп на экстремуме");
  stopLoss = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) + ADD_TO_STOPPLOSS;
 }
 return(stopLoss);
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