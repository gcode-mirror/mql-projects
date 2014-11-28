//+------------------------------------------------------------------+
//|                                                  AddonPoints.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs 
//подключение необходимых библиотек
#include <ColoredTrend\ColoredTrendUtilities.mqh>
#include <CompareDoubles.mqh>
#include <ChartObjects/ChartObjectsLines.mqh>     
//+------------------------------------------------------------------+
//| Скрипт, показывающий дополнительые точки                         |
//+------------------------------------------------------------------+
// входные параметры скрипта
input int pbiDepth = 1000;     // глубина, на которую загружается 
// глобальные переменные скрипта
int handlePBI; // хэндл PBI
double bufferPBI[];  // буфер PBI
double high[]; // буфер высоких цен
double low[]; // буфер низких цен
double buffer[]; // буфер дополнительных точек 
datetime time[]; // буфер времени
int copiedPBI;
int copiedHigh;
int copiedLow;
int copiedTime;
CChartObjectVLine  vertLine;                       // объект класса вертикальной линии
void OnStart()
  { 
   // выставляем последовательность элементов в массивах, как в таймсерии
   ArraySetAsSeries(bufferPBI,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(buffer,true);
   ArraySetAsSeries(time,true);
   // обнуляем буфер дополнительных точек
   ArrayResize(buffer,pbiDepth);
   ArrayInitialize(buffer,0);
   // создаем хэндл PBI
   handlePBI = iCustom(_Symbol,_Period,"PriceBasedIndicator",pbiDepth);
   if (handlePBI == INVALID_HANDLE)
    {
     Alert("Ошибка скрипта AddingPoint.mq5: не удалось создать хэндл PriceBasedIndicator");
     return;
    }
   // пытаемся загрузить буфер PriceBasedIndicator
   for (int attempts=0;attempts<25;attempts++)
    {
     copiedHigh = CopyHigh(_Symbol,_Period,TimeCurrent(),pbiDepth,high);
     copiedLow  = CopyLow(_Symbol,_Period,TimeCurrent(),pbiDepth,low);
     copiedPBI  = CopyBuffer(handlePBI,4,TimeCurrent(),pbiDepth,bufferPBI);
     copiedTime = CopyTime(_Symbol,_Period,TimeCurrent(),pbiDepth,time);
    }
   if (copiedHigh < pbiDepth || copiedLow < pbiDepth || copiedPBI < pbiDepth || copiedTime < pbiDepth)
    {
     Alert("Ошибка скрипта AddingPoint.mq5: не удалось прогрузить буферы");
     return;
    }
   // запускаем первое вычисление точек
   FirstCalculate();
  }
 // функция первого расчета дополнительных точек
 void FirstCalculate ()
  {
   double min,max;
   int    indMin=-1,indMax=-1;
   int    prevMove=-1; // последнее движение
   // проходим с конца истории и вычисляем дополнительные точки
   for (int ind=pbiDepth-1;ind>=0;ind--)
    {
     // если поулчили коррекцию вверх
     if ( bufferPBI[ind] == MOVE_TYPE_CORRECTION_UP )
      {
       if ( indMax == -1 )
        {
         indMax = ind;
         max = high[ind];
        }
       else 
        {
         if ( GreatDoubles(high[ind],max) )
           {
            indMax = ind;
            max = high[ind];
           }
        }
      }
     // иначе если поулчили коррекцию вниз
     else if ( bufferPBI[ind] == MOVE_TYPE_CORRECTION_DOWN )
      {
       if ( indMin == -1 )
        {
         indMin = ind;
         min = low[ind];   
        }
       else 
        {
         if ( LessDoubles(low[ind],min) )
           {
            indMin = ind;
            min = low[ind];     
           }
        }
      }
     // любое другое движение, отличное от коррекции
     else
      {
     //  curMove = int(bufferPBI[ind]);   // сохраняем текущее движение
       // если текущее движение - тренд вверх, предыдущее - коррекция вниз и до него - тренд вверх, то сохраняем точку 
       if ( (bufferPBI[ind] == MOVE_TYPE_TREND_UP  ||  bufferPBI[ind] == MOVE_TYPE_TREND_UP_FORBIDEN ) &&
            (prevMove == MOVE_TYPE_TREND_UP || prevMove == MOVE_TYPE_TREND_UP_FORBIDEN) &&
            indMin != -1
          )
           {
            // то сохраняем точку
            buffer[indMin] = min;
            vertLine.Color(clrRed);
            // создаем вертикальную линию, показывающий момент появления расхождения MACD
            vertLine.Create(0,"MIN_"+IntegerToString(ind),0,time[indMin]);
            vertLine.Color(clrRed);
           }
       // если текущее движение - тренд вниз, предыдущее - коррекция вверх и до него - тренд вниз, то сохраняем точку 
       if ( (bufferPBI[ind] == MOVE_TYPE_TREND_DOWN  || bufferPBI[ind] == MOVE_TYPE_TREND_DOWN_FORBIDEN ) &&
            (prevMove == MOVE_TYPE_TREND_DOWN || prevMove == MOVE_TYPE_TREND_DOWN_FORBIDEN) &&
            indMax != -1
          )
           {
            // то сохраняем точку
            buffer[indMax] = max;
            vertLine.Color(clrRed);
            // создаем вертикальную линию, показывающий момент появления расхождения MACD
            vertLine.Create(0,"MAX_"+IntegerToString(ind),0,time[indMax]);   
            vertLine.Color(clrRed);      
           }
       // сбрасываем индексы Min и max
       indMax = -1;    
       indMin = -1;    
       // сохраняем текущее движение, как предыдущее
       prevMove = int(bufferPBI[ind]);       
      }
           
    }
  }