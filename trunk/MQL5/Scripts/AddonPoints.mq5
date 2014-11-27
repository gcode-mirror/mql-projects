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

int fileHandle;                          // хэндл файла статистики

void OnStart()
  {
  
    // создаем хэндл файла тестирования статистики прохождения уровней
    fileHandle = FileOpen("MY_REVOLUTION.txt",FILE_WRITE|FILE_COMMON|FILE_ANSI|FILE_TXT, "");
    if (fileHandle == INVALID_HANDLE) //не удалось открыть файл
     {
      Print("Не удалось создать файл тестирования статистики прохождения уровней");
      return;
     }   
  
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
   handlePBI = iCustom(_Symbol,_Period,"PriceBasedIndicator");
   if (handlePBI == INVALID_HANDLE)
    {
     Alert("Ошибка скрипта AddingPoint.mq5: не удалось создать хэндл PriceBasedIndicator");
     FileClose(fileHandle);
     return;
    }
   // пытаемся загрузить буфер PriceBasedIndicator
   for (int attempts=0;attempts<25;attempts++)
    {
     copiedHigh = CopyHigh(_Symbol,_Period,0,pbiDepth,high);
     copiedLow  = CopyLow(_Symbol,_Period,0,pbiDepth,low);
     copiedPBI  = CopyBuffer(handlePBI,4,0,pbiDepth,bufferPBI);
     copiedTime = CopyTime(_Symbol,_Period,0,pbiDepth,time);
    }
   if (copiedHigh < pbiDepth || copiedLow < pbiDepth || copiedPBI < pbiDepth || copiedTime < pbiDepth)
    {
     Alert("Ошибка скрипта AddingPoint.mq5: не удалось прогрузить буферы");
     FileClose(fileHandle);
     return;
    }
   // запускаем первое вычисление точек
   FirstCalculate();
   
   FileClose(fileHandle);
  }
 // функция первого расчета дополнительных точек
 void FirstCalculate ()
  {
   double min,max;
   int    indMin=-1,indMax=-1;
   int    prevMove=-1,curMove=-1; // последнее и текущее движение
   // проходим с конца истории и вычисляем дополнительные точки
   for (int ind=pbiDepth-1;ind>=0;ind--)
    {
     
     FileWriteString(fileHandle,"\nтип движения = "+DoubleToString(bufferPBI[ind],0)+" время = "+TimeToString(time[ind])+" ind = "+ind+" pbiDepth = "+pbiDepth );    
     //Alert("движение = ",DoubleToString(bufferPBI[ind]) ," время = ",TimeToString(time[ind]) );
     // если поулчили коррекцию вверх
     if ( bufferPBI[ind] == MOVE_TYPE_CORRECTION_UP )
      {
       if ( indMax == -1 )
        {
         indMax = ind;
         max = high[ind];
    /*     Alert("Начало коррекции вверх. Время = ",TimeToString(time[ind]),
               " макс = ",DoubleToString(max)
              );   */
        }
       else 
        {
         if ( GreatDoubles(high[ind],max) )
           {
            indMax = ind;
            max = high[ind];
        /*      Alert("Коррекция вверх продолжается. Время = ",TimeToString(time[ind]),
               " макс = ",DoubleToString(max)
              );*/
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
      /*   Alert("Начало коррекции вниз. Время = ",TimeToString(time[ind]),
               " мин = ",DoubleToString(min)
              );    */     
        }
       else 
        {
         if ( LessDoubles(low[ind],min) )
           {
            indMin = ind;
            min = low[ind];
        /*      Alert("Коррекция вниз продолжается. Время = ",TimeToString(time[ind]),
               " мин = ",DoubleToString(min)
              );      */      
           }
        }
      }
     // любое другое движение, отличное от коррекции
     else
      {
       //Alert("Другое движение");
       curMove = int(bufferPBI[ind]);   // сохраняем текущее движение
     //  Alert("движение = ",curMove," время = ",TimeToString(time[ind]) );
       // если текущее движение - тренд вверх, предыдущее - коррекция вниз и до него - тренд вверх, то сохраняем точку 
       if ( (curMove == MOVE_TYPE_TREND_UP  || curMove == MOVE_TYPE_TREND_UP_FORBIDEN ) &&
            (prevMove == MOVE_TYPE_TREND_UP || prevMove == MOVE_TYPE_TREND_UP_FORBIDEN) &&
            indMin != -1
          )
           {
          //  Alert("Сохраняем точку min время = ",TimeToString(time[indMin]));
            // то сохраняем точку
            buffer[indMin] = min;
            vertLine.Color(clrRed);
            // создаем вертикальную линию, показывающий момент появления расхождения MACD
            vertLine.Create(0,"MIN_"+IntegerToString(indMin),0,time[indMin]);
           }
       // если текущее движение - тренд вниз, предыдущее - коррекция вверх и до него - тренд вниз, то сохраняем точку 
       if ( (curMove == MOVE_TYPE_TREND_DOWN  || curMove == MOVE_TYPE_TREND_DOWN_FORBIDEN ) &&
            (prevMove == MOVE_TYPE_TREND_DOWN || prevMove == MOVE_TYPE_TREND_DOWN_FORBIDEN) &&
            indMax != -1
          )
           {
          //  Alert("Сохраняем точку max время = ",TimeToString(time[indMax]));
            // то сохраняем точку
            buffer[indMax] = max;
            vertLine.Color(clrRed);
            // создаем вертикальную линию, показывающий момент появления расхождения MACD
            vertLine.Create(0,"MAX_"+IntegerToString(indMax),0,time[indMax]);            
           }
       // сбрасываем индексы Min и max
       indMax = -1;    
       indMin = -1;    
       // сохраняем текущее движение, как предыдущее
       prevMove = curMove;       
      }
      
    }
  }