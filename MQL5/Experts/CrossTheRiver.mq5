//+------------------------------------------------------------------+
//|                                                CrossTheRiver.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Эксперт, работающий на пробитии уровня                           |
//+------------------------------------------------------------------+

// подключаем библиотеки
#include <TradeManager\TradeManager.mqh>
#include <CompareDoubles.mqh>

// константы и структуры 

// константы расположения цены относительно уровня
#define no_location     0
#define up_location     1
#define down_location   2
#define inside_location 3

// структура уровней
struct bufferLevel
 {
  double price[];
  double atr[];
 };

int     handle19Lines;   // хэндл индикатора 19Lines
int     indexBuffer;     // индекс буфера
int     stopLoss;        // стоп лосс
int     takeProfit;      // тейк профит   
double  buffer19Lines[]; // буфер 19Lines
double  curPrice;        // текущая цена

// буферы уровней 
bufferLevel buffers[20];
int         bufferState[20];        // буфер состояний текущей цены относительно буфера

// торговая библиотека
CTradeManager *ctm;

int OnInit()
  {
   handle19Lines = iCustom(_Symbol,_Period,"NineteenLines");
   if (handle19Lines == INVALID_HANDLE)
    {
     Print("Не удалось создать хэндл индикатора NineteenLines");
     return (INIT_FAILED);
    }
   ctm = new CTradeManager();
   ArrayFill(bufferState,0,20,0);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   ArrayFree(buffer19Lines);
   IndicatorRelease(handle19Lines);
   delete ctm;
  }

void OnTick()
  {
   ctm.OnTick();
   curPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);  // получаем текущую цену
   if (UploadBuffers())
    {
     ChangeLevelState ();    // меняем статусы цены относительно уровней
     if (indexBuffer != -1)  // если какой либо уровень был пробит
      {
        if ( bufferState[indexBuffer] == up_location)   // если в последний момент цена оказалась выше уровня, то цена пробила уровень снизу вверх
          {
            stopLoss   = int( (buffers[indexBuffer].price[0]-buffers[indexBuffer].atr[0]) / _Point );  // стоп лосс
            takeProfit = int( GetClosestLevel (1) );                                                   // тейк профит
            ctm.OpenUniquePosition(_Symbol,_Period,OP_BUY,1,stopLoss,takeProfit);
          }
        if ( bufferState[indexBuffer] == down_location) // если в последний момент цена оказалась ниже уровня, то цена пробила уровень сверху вниз
          {
            stopLoss   = int( (buffers[indexBuffer].price[0]+buffers[indexBuffer].atr[0]) / _Point );  // стоп лосс
            takeProfit = int( GetClosestLevel (-1) );                                                  // тейк профит
            ctm.OpenUniquePosition(_Symbol,_Period,OP_SELL,1,stopLoss,takeProfit);          
          }
          
      }
    }
  }
  
  
void  ChangeLevelState ()   // проходит по уровням и возвращает номер того уровня, который удалось пробить
 {
   indexBuffer = -1;   // возвращаемый индекс буфера
   for (int index=0;index<20;index++)
    {
     // цена выше уровня
     if (GreatDoubles(curPrice,buffers[index].price[0]+buffers[index].atr[0]) )
      {
        if (bufferState [index] == down_location)
          {
           indexBuffer = index;
           return;
          }
        bufferState [index] = up_location;
      }
     // цена выше уровня
     else if (LessDoubles(curPrice,buffers[index].price[0]-buffers[index].atr[0]) )
      {
        if (bufferState [index] == up_location)
          {
           indexBuffer = index;
           return;
          }
        bufferState [index] = down_location;
      }
          
    }
 }
  
bool UploadBuffers ()   // получает последние значения уровней
 {
  int copiedPrice;
  int copiedATR;
  for (int index=0;index<20;index++)
   {
    copiedPrice = CopyBuffer(handle19Lines,index*2,  0,1,  buffers[index].price);
    copiedATR   = CopyBuffer(handle19Lines,index*2+1,0,1,buffers[index].atr);
    if (copiedPrice < 1 || copiedATR < 1)
     {
      Print("Не удалось прогрузить буферы индикатора NineTeenLines");
      return (false);
     }
   }
  return(true);     
 }
  
  
// возвращает ближайший уровень к текущей цене
 double GetClosestLevel (int direction) 
  {
   double len = 0;  //расстояние до цены от уровня
   double tmpLen; 
   bool   foundLevel = false;  // флаг найденного первого уровня
   int    index;
   
   switch (direction)
    {
     case 1:  // ближний сверху
      for (index=0;index<20;index++)
       {
        // если уровень выше
        if ( GreatDoubles((buffers[index].price[0]-buffers[index].atr[0]),curPrice)  )
         {
          if (foundLevel)
           {
             tmpLen = buffers[index].price[0] - buffers[index].atr[0] - curPrice;
             if (tmpLen < len)
              len = tmpLen;  
           }
          else
           {
            len = buffers[index].price[0] - buffers[index].atr[0] - curPrice;
            foundLevel = true;
           }
         }
       }
     break;
     case -1: // ближний снизу
      for (index=0;index<20;index++)
       {
        // если уровень ниже
        if ( LessDoubles((buffers[index].price[0]+buffers[index].atr[0]),curPrice)  )
          {
          if (foundLevel)
           {
             tmpLen = curPrice - buffers[index].price[0] + buffers[index].atr[0] ;
             if (tmpLen < len)
              len = tmpLen;
           }
          else
           {
            len =  curPrice - buffers[index].price[0] + buffers[index].atr[0];
            foundLevel = true;
           }
         }

       }     
       
      break;
   }
   return (len);
  }