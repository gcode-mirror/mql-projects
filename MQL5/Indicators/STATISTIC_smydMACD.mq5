//+------------------------------------------------------------------+
//|                                                     smydMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window   // будем задействовать побочное окно индикатора

#include <StringUtilities.mqh> 

//+------------------------------------------------------------------+
//| Индикатор, показывающий расхождения MACD                         |
//| 1) рисует MACD                                                   |
//| 2) рисует линиями расхождения на MACD и на графике цены          |
//| 3) рисует стрелочками момент возникновения сигнала               |
//| 4) собирает статистику расхождений                               |
//+------------------------------------------------------------------+

// подключаем библиотеки 
#include <Lib CisNewBar.mqh>                       // для проверки формирования нового бара
#include <Divergence/divergenceMACD.mqh>           // подключаем библиотеку для поиска расхождений MACD
#include <ChartObjects/ChartObjectsLines.mqh>      // для рисования линий расхождения
#include <CompareDoubles.mqh>                      // для проверки соотношения  цен

// входные пользовательские параметры индикатора
sinput string             macd_params        = "";           // ПАРАМЕТРЫ ИНДИКАТОРА MACD
input  int                fast_ema_period    = 12;           // период быстрой средней MACD
input  int                slow_ema_period    = 26;           // период медленной средней MACD
input  ENUM_APPLIED_PRICE priceType          = PRICE_CLOSE;  // тип цен, по которым вычисляется MACD

sinput string             stat_params        = "";           // ПАРАМЕТРЫ ВЫЧИСЛЕНИЯ СТАТИСТИКИ
input  int                actualBars         = 10;           // количество баров для подсчета актуальности
input  string             fileName           = "MACD_STAT_"; // имя файла статистики
input  datetime           start_time         = 0;            // дата, с которой начать проводить статистику
input  datetime           finish_time        = 0;            // дата, по которую проводить статистику
input  double             ZoneLossBuy        = 0;            // уровень убытка актуальных расхождений по BUY
input  double             ZoneProfitBuy      = 0;            // уровень прибыли актуальных расхождений по BUY
input  double             ZoneLossSell       = 0;            // уровень убытка актуальных расхождений по SELL 
input  double             ZoneProfitSell     = 0;            // уровень прибыли актуальных расхождений по SELL


// параметры индикаторных буферов 
#property indicator_buffers 2                      // задействовано 2 индикаторных буфера
#property indicator_plots   1                      // 1 буфер отображаются на графиках

// параметры буферов

// параметры 1-го буфера (MACD)
#property indicator_type1 DRAW_HISTOGRAM           // гистограммы
#property indicator_color1  clrWhite               // цвет гистограммы
#property indicator_width1  1                      // толщина гистограммы
#property indicator_label1  "MACD"                 // наименование буфера


// глобальные переменные индикатора
int                handleMACD;                     // хэндл MACD
int                lastBarIndex;                   // индекс последнего бара 
int                retCode;                        // для записи результата вычисления  расхождения  
long               countDiv;                       // счетчик тренд линий (для рисования линий расхождений) 

PointDivMACD       divergencePoints;               // точки расхождения MACD на ценовом графике и на графике MACD
CChartObjectTrend  trendLine;                      // объект класса трендовой линии (для отображения расхождений)
CChartObjectVLine  vertLine;                       // объект класса вертикальной линии
CisNewBar          isNewBar;                       // для проверки формирования нового бара

// буферы индикатора 
double bufferMACD[];                               // буфер уровней MACD
double bufferDiv[];                                // буфер моментов расхождения

// хэндл файла статистики
int    fileHandle;

// переменные для хранения результатов статистики

double averActualProfitDivBuy      = 0;    // средняя потенциальная прибыль от актуального расхождения на покупку
double averActualLossDivBuy        = 0;    // средний потенциальный убыток при актуальном расхождении на покупку
double averActualProfitDivSell     = 0;    // средняя потенциальная прибыль от актуального расхождения на продажу
double averActualLossDivSell       = 0;    // средний потенциальный убыток при актуальном расхождении на продажу    

double averNotActualProfitDivBuy   = 0;    // средняя потенциальная прибыль от НЕ актуального расхождения на покупку
double averNotActualLossDivBuy     = 0;    // средний потенциальный убыток при НЕ актуальном расхождении на покупку
double averNotActualProfitDivSell  = 0;    // средняя потенциальная прибыль от НЕ актуального расхождения на продажу
double averNotActualLossDivSell    = 0;    // средний потенциальный убыток при НЕ актуальном расхождении на продажу                     

// счетчики расхождений
int    countActualDivBuy           = 0;    // количество актуальных расхождений на покупку
int    countDivBuy                 = 0;    // общее количество расхождений на покупку     
int    countActualDivSell          = 0;    // колчиство актуальных расхождений на продажу
int    countDivSell                = 0;    // общее количество расхождений на продажу     

int    countDivZoneLossBuy         = 0;    // количество расхождений с убытком ниже уровня по BUY
int    countDivZoneProfitBuy       = 0;    // количество расхождений с прибылью выше уровня по BUY

int    countDivZoneLossSell        = 0;    // количество расхожденй с убытком ниже уровня по SELL
int    countDivZoneProfitSell      = 0;    // количество расхождений с прибылью выше уровня по SELL
                                                  

// дополнительные функции работы индикатора
void DrawIndicator(datetime vertLineTime); // отображает линии индикатора. В функцию передается время вертикальной линии
   
// инициализация индикатора
int OnInit()
  {
   // создаем файл статистики на запись
   fileHandle = FileOpen(fileName+_Symbol+"_"+PeriodToString(_Period)+".txt",FILE_WRITE|FILE_COMMON|FILE_ANSI|FILE_TXT, "");
   if (fileHandle == INVALID_HANDLE) //не удалось открыть файл
    {
     Print("Ошибка индикатора ShowMeYourDivMACD. Не удалось создать файл статистики");
     return (INIT_FAILED);
    }  
   ArraySetAsSeries(bufferDiv,true);
   // загружаем хэндл индикатора MACD
   handleMACD = iMACD(_Symbol, _Period, fast_ema_period,slow_ema_period,9,PRICE_CLOSE);
   if ( handleMACD == INVALID_HANDLE)  // если не удалось загрузить хэндл MACD
    {
     return(INIT_FAILED);  // то инициализация завершилась не успенно
    }  
   // удаляем все графические объекты (линии расхождений, а также линии появления сигналов расхождений)  
   ObjectsDeleteAll(0,0,OBJ_TREND); // все трендовые линии с ценового графика 
   ObjectsDeleteAll(0,1,OBJ_TREND); // все трендовые линии с побочного графика
   ObjectsDeleteAll(0,0,OBJ_VLINE); // все вертикальные линии, обозначающие момент возникновения расхождения
   // связываем индикаторы с буферами 
   SetIndexBuffer(0,bufferMACD,INDICATOR_DATA);         // буфер MACD
   SetIndexBuffer(1,bufferDiv ,INDICATOR_CALCULATIONS); // буфер расхождений (моментов возникновения сигналов)
   // инициализация глобальных  переменных
   countDiv = 0;                                        // выставляем начальное количество расхождений
   return(INIT_SUCCEEDED); // успешное завершение инициализации индикатора
  }

// деинициализация индикатора
void OnDeinit(const int reason)
 {
   // удаляем все графические объекты (линии расхождений, а также линии появления сигналов расхождений)  
   ObjectsDeleteAll(0,0,OBJ_TREND); // все трендовые линии с ценового графика 
   ObjectsDeleteAll(0,1,OBJ_TREND); // все трендовые линии с побочного графика
   ObjectsDeleteAll(0,0,OBJ_VLINE); // все вертикальные линии, обозначающие момент возникновения расхождения
   // очищаем индикаторные буферы
   ArrayFree(bufferMACD);
   ArrayFree(bufferDiv);
   // освобождаем хэндл MACD
   IndicatorRelease(handleMACD);
   // закрываем файл статистики 
   if (fileHandle != INVALID_HANDLE)
   FileClose(fileHandle);
 }

// базовая функция расчета индикатора
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
// локальные переменные
 double maxPrice;          // локальный максимум цен
 double minPrice;          // локальный минимум цен
   
 if (prev_calculated == 0) // если на пред. вызове было обработано 0 баров, значит этот вызов первый
 {
 // загрузим буфер MACD
  if (CopyBuffer(handleMACD,0,0,rates_total,bufferMACD) < 0  )
  {
  // если не удалось загрузить буфера MACD
   Print("Ошибка индикатора ShowMeYourDivMACD. Не удалось загрузить буфер MACD");
   return (0); 
  }                
  // положим индексацию нужных массивов как в таймсерии
  if (!ArraySetAsSeries (time,true) || 
      !ArraySetAsSeries (open,true) || 
      !ArraySetAsSeries (high,true) ||
      !ArraySetAsSeries (low,true)  || 
      !ArraySetAsSeries (close,true) )
  {
  // если не удалось установаить индексацию как в таймсерии для всех массивов цен и времени
   Print("Ошибка индикатора ShowMeYourDivMACD. Не удалось установить индексацию массивов как в таймсерии");
   return (0);
  }
  // проходим по всем барам истории и ищем расхождения MACD
  for (lastBarIndex = rates_total-DEPTH_MACD-1; lastBarIndex > 0; lastBarIndex--)
  {
  // обнуляем буфер сигналов расхождений MACD
   bufferDiv[lastBarIndex] = 0;
   retCode = divergenceMACD(handleMACD, _Symbol, _Period, divergencePoints, lastBarIndex);  // получаем сигнал на расхождение
  // если не удалось загрузить буферы MACD
   if (retCode == -2)
   {
    Print("Ошибка индикатора ShowMeYourDivMACD. Не удалось загрузить буферы MACD");
    return (0);
   }
   if (retCode)
   {                                          
    DrawIndicator(time[lastBarIndex]);    // отображаем графические элементы индикатора     
    bufferDiv[lastBarIndex] = retCode;    // сохраняем в буфер значение    
           
   // вычисляем статистические данные по данному расхождению
    if (time[lastBarIndex] >= start_time  && time[lastBarIndex] <= finish_time)   // если текущее время попадает в зону вычисления статистики
    {
    // вычисляем максимум на глубину вычисления актуальности
     maxPrice =  high[ArrayMaximum(high,lastBarIndex-actualBars,actualBars)];  // находим максимум по high
     minPrice =  low[ArrayMinimum(low,lastBarIndex -actualBars,actualBars)];   // находим минимум по low

    // вычисляем актуальность расхождений
     if (retCode == 1)      // если расхождение на SELL
     { 
      countDivSell ++;    // увеличиваем количество расхождений на SELL
               
      maxPrice = maxPrice - close[lastBarIndex];   // вычисляем, насколько цена ушла вверх от цены закрытия
      minPrice = close[lastBarIndex] - minPrice;   // вычисляем, насколько цена ушла вниз от цены закрытия
      
                
      if (maxPrice < 0)
       maxPrice = 0;
      if (minPrice < 0)
       minPrice = 0;
                
      if (minPrice > maxPrice)  // данное расхождение является актуальным
      {
       countActualDivSell ++;   // увеличиваем количество актуальных расхождений на SELL
                   
       averActualProfitDivSell = averActualProfitDivSell + minPrice; // увеличиваем сумму для средней прибыли
       averActualLossDivSell   = averActualLossDivSell   + maxPrice; // увеличиваем сумму для среднего убытка
       
       if (minPrice > ZoneProfitSell)
         {
           countDivZoneProfitSell++;  
         }
       if (maxPrice < ZoneLossSell)
         {
           countDivZoneLossSell++;  
         }         
                            
      }
      else
      {
       averNotActualProfitDivSell = averNotActualProfitDivSell + minPrice; // увеличиваем сумму для средней прибыли
       averNotActualLossDivSell   = averNotActualLossDivSell   + maxPrice; // увеличиваем сумму для среднего убытка
                           
      }
     }
     if (retCode == -1)     // если расхождение на BUY
     {              
      countDivBuy ++;     // увеличиваем количество расхождений на BUY
                
      maxPrice = maxPrice - close[lastBarIndex];   // вычисляем, насколько цена ушла вверх от цены закрытия
      minPrice = close[lastBarIndex] - minPrice;   // вычисляем, насколько цена ушла вниз от цены закрытия  
                
      if (maxPrice < 0)
       maxPrice = 0;
      if (minPrice < 0)
       minPrice = 0;     
                
      if (maxPrice > minPrice)  // данное расхождение является аткуальным
      {
       countActualDivBuy ++;    // увеличиваем количество актуальных расхождений на BUY
                   
       averActualProfitDivBuy = averActualProfitDivBuy + maxPrice;  // увеличиваем сумму для средней прибыли
       averActualLossDivBuy   = averActualLossDivBuy   + minPrice;  // увеличиваем сумму для среднего убытка
       
       if (maxPrice > ZoneProfitBuy)
         {
           countDivZoneProfitBuy++;  
         }
       if (minPrice < ZoneLossBuy)
         {
           countDivZoneLossBuy++;  
         }         
 
      }
      else
      {
       averNotActualProfitDivBuy = averNotActualProfitDivBuy + maxPrice;  // увеличиваем сумму для средней прибыли
       averNotActualLossDivBuy   = averNotActualLossDivBuy   + minPrice;  // увеличиваем сумму для среднего убытка                 
  
      }
     }
    } // end проверки на дату 
   }
  }
          
  // запись в файл общей статистики
  if (countActualDivSell > 0)
  {
   averActualLossDivSell   = averActualLossDivSell   / countActualDivSell;
   averActualProfitDivSell = averActualProfitDivSell / countActualDivSell; 
  }
  if (countActualDivBuy > 0)
  {
   averActualLossDivBuy    = averActualLossDivBuy    / countActualDivBuy;
   averActualProfitDivBuy  = averActualProfitDivBuy  / countActualDivBuy;
  }
  if (countActualDivSell != countDivSell)
  {
   averNotActualLossDivSell   = averNotActualLossDivSell   / (countDivSell-countActualDivSell);
   averNotActualProfitDivSell = averNotActualProfitDivSell / (countDivSell-countActualDivSell); 
  }
  if (countActualDivBuy != countDivBuy)
  {
   averNotActualLossDivBuy    = averNotActualLossDivBuy    / (countDivBuy-countActualDivBuy);
   averNotActualProfitDivBuy  = averNotActualProfitDivBuy  / (countDivBuy-countActualDivBuy);
  }        
      
     
    FileWriteString(fileHandle,"\n\n Количество расхождений SELL: "+IntegerToString(countDivSell));
    FileWriteString(fileHandle,"\n Из них актуальных: "+IntegerToString(countActualDivSell));
    FileWriteString(fileHandle,"\n Из них НЕ актуальных: "+IntegerToString(countDivSell - countActualDivSell));          
          
    FileWriteString(fileHandle,"\n Средняя прибыль актуальных: "+DoubleToString(averActualProfitDivSell,5));
    FileWriteString(fileHandle,"\n Средний потенциальный убыток актуальных: "+DoubleToString(averActualLossDivSell,5));  
          
    FileWriteString(fileHandle,"\n Средняя прибыль НЕ актуальных: "+DoubleToString(averNotActualProfitDivSell,5));
    FileWriteString(fileHandle,"\n Средний потенциальный убыток НЕ актуальных: "+DoubleToString(averNotActualLossDivSell,5));                
          
    FileWriteString(fileHandle,"\n\n Количество расхождений BUY: "+IntegerToString(countDivBuy));
    FileWriteString(fileHandle,"\n Из них актуальных: "+IntegerToString(countActualDivBuy));
    FileWriteString(fileHandle,"\n Из них НЕ актуальных: "+IntegerToString(countDivBuy - countActualDivBuy));          
           
    FileWriteString(fileHandle,"\n Средняя прибыль актуальных: "+DoubleToString(averActualProfitDivBuy,5));
    FileWriteString(fileHandle,"\n Средний потенциальный убыток актуальных: "+DoubleToString(averActualLossDivBuy,5));  
          
    FileWriteString(fileHandle,"\n Средняя прибыль НЕ актуальных: "+DoubleToString(averNotActualProfitDivBuy,5));
    FileWriteString(fileHandle,"\n Средний потенциальный убыток НЕ актуальных: "+DoubleToString(averNotActualLossDivBuy,5));
    
    FileWriteString(fileHandle,"\n\n Количество актуальных расхождений на SELL с прибылью выше уровня: "+IntegerToString(countDivZoneProfitSell));        
    FileWriteString(fileHandle,"\n Количество актуальных расхождений на SELL с убытком ниже уровня: "+IntegerToString(countDivZoneLossSell));  
   
    FileWriteString(fileHandle,"\n Количество актуальных расхождений на BUY с прибылью выше уровня: "+IntegerToString(countDivZoneProfitBuy));        
    FileWriteString(fileHandle,"\n Количество актуальных расхождений на BUY с убытком ниже уровня: "+IntegerToString(countDivZoneLossBuy));        
   
  
  // закрываем файл статистики
  FileClose(fileHandle);                       
  fileHandle = INVALID_HANDLE;                     
 }
 else    // если это не первый вызов индикатора 
 {
  // если сформировался новый бар
  if (isNewBar.isNewBar() > 0 )
  {
  // положим индексацию нужных массивов как в таймсерии
   if (!ArraySetAsSeries (time,true) || 
       !ArraySetAsSeries (open,true) || 
       !ArraySetAsSeries (high,true) ||
       !ArraySetAsSeries (low,true)  || 
       !ArraySetAsSeries (close,true) )
   {
   // если не удалось установаить индексацию как в таймсерии для всех массивов цен и времени
    Print("Ошибка индикатора ShowMeYourDivMACD. Не удалось установить индексацию массивов как в таймсерии");
    return (rates_total);
   }
   // обнуляем буфер сигнала расхождений
   bufferDiv[0] = 0;
   if (CopyBuffer(handleMACD,0,0,rates_total,bufferMACD) < 0  )
   {
   // если не удалось загрузить буфера MACD
    Print("Ошибка индикатора ShowMeYourDivMACD. Не удалось загрузить буферы MACD");
    return (rates_total);
   }   
   retCode = divergenceMACD (handleMACD,_Symbol,_Period,divergencePoints,0);  // получаем сигнал на расхождение
   // если не удалось загрузить буферы MACD
   if (retCode == -2)
   {
    Print("Ошибка индикатора ShowMeYourDivMACD. Не удалось загрузить буферы MACD");
    return (0);
   }
   if (retCode)
   {                                        
    DrawIndicator (time[0]);       // отображаем графические элементы индикатора    
    bufferDiv[0] = retCode;        // сохраняем текущий сигнал
   }        
  }
 }
 return(rates_total);
}
 
//---------------------------------------------------------  
// функция отображения графических элементов индикатора
//----------------------------------------------------------
void DrawIndicator (datetime vertLineTime)
 {
   trendLine.Color(clrYellow);
   // создаем линию схождения\расхождения                    
   trendLine.Create(0,"MacdPriceLine_"+IntegerToString(countDiv),0,divergencePoints.timeExtrPrice1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2);           
   trendLine.Color(clrYellow);         
   // создаем линию схождения\расхождения на MACD
   trendLine.Create(0,"MACDLine_"+IntegerToString(countDiv),1,divergencePoints.timeExtrMACD1,divergencePoints.valueExtrMACD1,divergencePoints.timeExtrMACD2,divergencePoints.valueExtrMACD2);            
   vertLine.Color(clrRed);
   // создаем вертикальную линию, показывающий момент появления расхождения MACD
   vertLine.Create(0,"MACDVERT_"+IntegerToString(countDiv),0,vertLineTime);
   countDiv++; // увеличиваем количество отображаемых схождений
 }