//+------------------------------------------------------------------+
//|                                                   AverageATR.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window       // значит индикатор будем выводить в отдельном окне
#property indicator_buffers 2             // количество буферов всего     
#property indicator_plots   2             // из них, которые отображаются в окне
// свойства буферов
#property indicator_type1   DRAW_LINE     // в качестве индикатора использованы линии
#property indicator_color1  clrWhite      // цвет линий
#property indicator_style1  STYLE_SOLID   // стиль линий
#property indicator_width1  1             // толщина линий
#property indicator_label1  "Среднее ATR" // наименование буфера

#property indicator_type2   DRAW_LINE     // в качестве индикатора использованы линии
#property indicator_color2  clrLightCoral // цвет линий
#property indicator_style2  STYLE_SOLID   // стиль линий
#property indicator_width2  1             // толщина линий
#property indicator_label2  "ATR"         // наименование буфера


//+------------------------------------------------------------------+
//| Индикатор усредняющий ATR                                        |
//+------------------------------------------------------------------+

// входные параметры индикатора 
input int ma_period   = 100;                       // период усреднения 
input int aver_period = 100;                       // период усреднения значений ATR
input int n_bars      = 10000;                     // количество рассчитанных баров при первом запуске индикатора
 

// системные переменные индикатора 
int    startIndex;               // индекс с которого начать вычисление усреднения ATR
int    index;                    // индекс прохода по циклу          
double lastSummPrice;            // переменная хранения последней суммы цен
double lastSummATR;              // переменная хранения последней суммы значений ATR              
// индикаторные буферы
double averATRBuffer[];          // хранит значения усредненных значений ATR
double bufferATR[];              // хранит значение буфера ATR

int OnInit()
  {
      startIndex = ma_period-1+aver_period;
      // если стартовый индекс превысил допустимое количество баров
      if (startIndex >= n_bars)
       {
        Print("Ошибка инициализации индикатора AverageATR. Некорректно заданы периоды усреднения");
        return (INIT_FAILED);
       }      
    
   // задаем параметры индикаторных буферов
   SetIndexBuffer(0,averATRBuffer,INDICATOR_DATA);  
   SetIndexBuffer(1,bufferATR,INDICATOR_DATA);     
   return(INIT_SUCCEEDED);
  }
  
void OnDeinit (const int reason)
 {
  // очищаем буферы индикаторов
  ArrayFree(averATRBuffer);
  ArrayFree(bufferATR);
 }
 
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
    // если это первый запуск индикатора
    if (prev_calculated == 0)
     {
        
       // проходим по всем барам и вычисляем ATR
       lastSummPrice = 0;
       for (index=0;index<ma_period;index++)
       {
        lastSummPrice = lastSummPrice + high[ rates_total - n_bars - ma_period - aver_period + index ]-low[ rates_total - n_bars - ma_period - aver_period + index ];
        bufferATR[ rates_total - n_bars - ma_period - aver_period + index ] = 0;
        averATRBuffer[ rates_total - n_bars - ma_period - aver_period + index ] = 0;
       }
       bufferATR[rates_total - n_bars - aver_period] = lastSummPrice / ma_period;  // сохраняем первое среднее значение
       // проходим по буферу цен и вычисляем остальные усредненные значения
       for (index = rates_total - n_bars - aver_period + 1;index < rates_total; index++)
        {
         lastSummPrice = lastSummPrice + high[index] - low[index] - high[index-ma_period] + low[index-ma_period]; // вычисляем новую сумму
         bufferATR[index] = lastSummPrice / ma_period;     // сохраняем среднее значение
        }       
       
       // проходим по буферу ATR от startIndex до конца и вычисляем сумму 
       lastSummATR = 0;
       for (index=0;index<aver_period;index++)
       {
        lastSummATR = lastSummATR + bufferATR[rates_total - n_bars + index];
        //averATRBuffer[startIndex-index] = 0;
       }
       averATRBuffer[rates_total - n_bars] = lastSummATR / aver_period;  // сохраняем первое среднее значение
       // проходим по буферу ATR и вычисляем остальные усредненные значения
       for (index = rates_total - n_bars + 1;index < rates_total; index++)
        {
         lastSummATR = lastSummATR + bufferATR[index] - bufferATR[index-aver_period];  // вычисляем новую сумму
         averATRBuffer[index] = lastSummATR / aver_period;     // сохраняем среднее значение
        }   
        
        
        
     }
    // если не первый пересчет индикатора
    else 
     { 
      
      //  bufferATR [rates_total-1] = bufferATR[rates_total-2] - (high[rates_total-1- ma_period]-low[rates_total-1-ma_period])/ma_period + ( MathMax(high[rates_total-1],close[rates_total-1])-MathMin(low[rates_total-1],close[rates_total-1]) )/ma_period;      
      bufferATR [rates_total-1] = bufferATR[rates_total-2] - (high[rates_total-1- ma_period]-low[rates_total-1-ma_period])/ma_period + (high[rates_total-1]-low[rates_total-1] )/ma_period;       
        averATRBuffer[rates_total-1] = averATRBuffer[rates_total-2] - bufferATR[rates_total-1-aver_period]/aver_period + bufferATR[rates_total-1]/aver_period;
  //   Print("Данные индикатора = ",DoubleToString(bufferATR[rates_total-1])," , ",DoubleToString(averATRBuffer[rates_total-1]) );
    
     }
   return(rates_total);
  }