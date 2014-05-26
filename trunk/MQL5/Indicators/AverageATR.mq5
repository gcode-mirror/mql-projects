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
#property indicator_type1 DRAW_LINE       // в качестве индикатора использованы линии
#property indicator_color1  clrWhite      // цвет линий
#property indicator_style1  STYLE_SOLID   // стиль линий
#property indicator_width1  1             // толщина линий
#property indicator_label1  "Среднее ATR" // наименование буфера

#property indicator_type1 DRAW_LINE       // в качестве индикатора использованы линии
#property indicator_color1  clrLightBlue  // цвет линий
#property indicator_style1  STYLE_SOLID   // стиль линий
#property indicator_width1  1             // толщина линий
#property indicator_label1  "ATR" // наименование буфера

//+------------------------------------------------------------------+
//| Индикатор усредняющий ATR                                        |
//+------------------------------------------------------------------+

// подключаем необходимые библиотеки
#include <Lib CisNewBar.mqh>  // для проверки формирования нового бара

// входные параметры индикатора 
input int ma_period   = 100;       // период усреднения 
input int aver_period = 100;       // период усреднения значений ATR


// системные переменные индикатора
int handleATR;                // хэндл индикатора ATR
int copiedATR = -1;           // переменная для получения количества скопированных данных индикатора ATR   
int startIndex;               // индекс с которого начать вычисление усреднения ATR                     
// индикаторные буферы
double averATRBuffer[];       // хранит значения усредненных значений ATR
double bufferATR[];           // хранит значение буфера ATR

// используемые объекты классов
CisNewBar *isNewBar;          // объект класса проверки появления нового бара


int OnInit()
  {
   int barsCount;             // для хранения количества баров в истории
   // вычисляем количество баров в истории
   barsCount = Bars(_Symbol,_Period); 
   // вычисляем стартовый индекс, с которого начнем вычислять усредненное значение ATR 
   startIndex = ma_period-1+aver_period;
   // если стартовый индекс превысил допустимое количество баров
   if (startIndex >= barsCount)
    {
     Print("Ошибка инициализации индикатора AverageATR. Не корректно заданы периоды усреднения");
     return (INIT_FAILED);
    }
   // задаем параметры индикаторных буферов
   SetIndexBuffer(0,averATRBuffer,INDICATOR_DATA);
   // загружаем хэндл ATR
   handleATR = iATR(_Symbol,_Period,ma_period);
   // создаем объект класса isNewBar
   isNewBar = new CisNewBar(_Symbol,_Period);
   if (handleATR == INVALID_HANDLE)
    {
     Print("Ошибка инициализации индикатора AverageATR. Не удалось создать индикатор ATR");
     return(INIT_FAILED);
    }
   return(INIT_SUCCEEDED);
  }
  
void OnDeinit (const int reason)
 {
  // очищаем буферы индикаторов
  ArrayFree(averATRBuffer);
  // освобождаем хэндл индикатора ATR
  IndicatorRelease(handleATR);
  // удаляем объект класса isNewBar
  delete isNewBar;
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

       // пытаемся скопировать данные индикатора ATR
       copiedATR = CopyBuffer(handleATR,0,0,rates_total,bufferATR);
       
       if (copiedATR < rates_total)
        {
         Print("Ошибка индикатора AverageATR. Не удалось прогрузить буфер индикатора ATR");
         return(0);  // снова отравляем на пересчет
        } 

         
     }
    // если не первых пересчет индикатора
    else 
     {
     /*  // если новый бар сформирован
       if ( isNewBar.isNewBar() > 0 )
        {
          copiedATR 
          averATRBuffer[0] = 
        }*/
     }
   return(rates_total);
  }
  
  // функция считает среднее значение индикаторного буфера ATR
  double  GetAverageATRValue (int start_pos)   // start_pos - откуда начать вычислять среднее значение индикаторного буфера 
   {
     double averValue = 0;   // переменная для хранения среднего значения 
     int    index;           // переменная для прохода по циклу
    // for (index=start_pos;index
   }