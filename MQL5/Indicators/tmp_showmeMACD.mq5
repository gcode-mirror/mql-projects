//+------------------------------------------------------------------+
//|                                                      DisMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#include <Lib CisNewBar.mqh>                  // для проверки формирования нового бара
#include <divergenceMACD.mqh>                 // подключаем библиотеку для поиска схождений и расхождений Стохастика
#include <ChartObjects\ChartObjectsLines.mqh> // для рисования линий схождения\расхождения
#include <CompareDoubles.mqh>                 // для проверки соотношения  цен
#include <kernel32.mqh>                       // библиотека kernel32

// параметры индикатора
 
//---- всего задействовано 2 буфера
#property indicator_buffers 2
//---- использовано 2 графических построений
#property indicator_plots   2

//---- в качестве индикатора уровней MACD использованы гистограммы
#property indicator_type1 DRAW_HISTOGRAM
//---- цвет индикатора
#property indicator_color1  clrWhite
//---- толщина линии индикатора
#property indicator_width1  1
//---- отображение метки линии индикатора
#property indicator_label1  ""

//---- в качестве индикатора сигнала MACD использованы линии
#property indicator_type2 DRAW_LINE
//---- цвет индикатора
#property indicator_color2  clrRed
//---- стиль линии индикатора
#property indicator_style2  STYLE_DOT
//---- толщина линии индикатора
#property indicator_width2  1
//---- отображение метки линии индикатора
#property indicator_label2  "SIGNAL"

 // перечисление режима загрузки баров истории
 enum BARS_MODE
 {
  ALL_HISTORY=0, // вся история
  INPUT_BARS     // вводимое количество баром пользователя
 };
 // массив цветов тренд линий
 color lineColors[5]=
  {
   clrRed,
   clrBlue,
   clrYellow,
   clrGreen,
   clrGray
  };
//+------------------------------------------------------------------+
//| Вводимые параметры индикатора                                    |
//+------------------------------------------------------------------+
input BARS_MODE           bars_mode=ALL_HISTORY;     // режим загрузки истории
input short               bars=20000;                // начальное количество баров истории
input int                 fast_ema_period=12;        // период быстрой средней MACD
input int                 slow_ema_period=26;        // период медленной средней MACD
input int                 signal_period=9;           // период усреднения разности MACD
input int                 depth=10;                  // грубина рассчета актуальности
input string              file_url;                  // url адрес файла статистики 


//+------------------------------------------------------------------+
//| Глобальные переменные                                            |
//+------------------------------------------------------------------+

bool               first_calculate;        // флаг первого вызова OnCalculate
int                handleMACD;             // хэндл MACD
int                lastBarIndex;           // индекс последнего бара   
long               countTrend;             // счетчик тренд линий

PointDiv           divergencePoints;       // схождения и расхождения MACD
CChartObjectTrend  trendLine;              // объект класса трендовой линии
CisNewBar          isNewBar;               // для проверки формирования нового бара

//+------------------------------------------------------------------+
//| Буферы индикаторов                                               |
//+------------------------------------------------------------------+

double bufferMACD[];   // буфер уровней MACD
double signalMACD[];   // сигнальный буфер MACD

 int countConvPos = 0;       // количество положительных сигналов схождения
 int countConvNeg = 0;       // количество негативный сигналов схождения
 int countDivPos  = 0;       // количество положительный сигналов расхождения
 int countDivNeg  = 0;       // количество негативных сигналов расхождения 
 
// временные параменные для хранения локальных минимумов и максимумов
 double localMax;
 double localMin;

// хэндл файла статистики схождений \ расхождений 
 int file_handle;   
 
//+------------------------------------------------------------------+
//| Базовые функции индикатора                                       |
//+------------------------------------------------------------------+

int OnInit()
  {     
   // создает файл статистики 
   file_handle = CreateFileW(file_url, _GENERIC_WRITE_, _FILE_SHARE_WRITE_, 0, _CREATE_ALWAYS_, 128, NULL); 
   if(file_handle <= 0 )
    {
     Alert("Не возможно создать файл результатов бэктеста");
     return(INIT_FAILED);
    }
   // удаляем все графические объекты     
   ObjectsDeleteAll(0,0,OBJ_TREND);
   ObjectsDeleteAll(0,1,OBJ_TREND);     
   // связываем индикаторы с буферами 
   SetIndexBuffer(0,bufferMACD,INDICATOR_DATA);
   SetIndexBuffer(1,signalMACD,INDICATOR_DATA);   
   // инициализация глобальных  переменных
   first_calculate = true;
   countTrend = 1;
   // загружаем хэндл индикатора MACD
   handleMACD = iMACD(_Symbol, _Period, fast_ema_period,slow_ema_period,signal_period,PRICE_CLOSE);
   return(INIT_SUCCEEDED);
  }

void OnDeinit()
 {

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
    int retCode;  // результат вычисления схождения и расхождения
    int count;    // индекс цикла для поиска максимума и минимума
    // если это первый запуск фунции пересчета индикатора
    if (first_calculate)
     {
      if (bars_mode == ALL_HISTORY)
       {
        lastBarIndex = rates_total - 101;
       }
      else
       {
       if (bars < 100)
        {
         lastBarIndex = 1;
        }
       else if (bars > rates_total)
        {
         lastBarIndex = rates_total-101;
        }
       else
        {
         lastBarIndex = bars-101;
        }
       }
       // загрузим буфер MACD
       if ( CopyBuffer(handleMACD,0,0,rates_total,bufferMACD) < 0 ||
            CopyBuffer(handleMACD,1,0,rates_total,signalMACD) < 0 )
           {
             // если не удалось загрузить буфера MACD
             return (0);
           }  
       for (;lastBarIndex > depth; lastBarIndex--)
        {
          // сканируем историю по хэндлу на наличие расхождений\схождений 
          retCode = divergenceMACD (handleMACD,_Symbol,_Period,lastBarIndex,divergencePoints);
          // если не удалось загрузить буферы MACD)
          if (retCode == -2)
           return (0);
          // если схождение\расхождение обнаружено
          if (retCode)
           {                                          
            trendLine.Color(lineColors[countTrend % 5] );
            //создаем линию схождения\расхождения                    
            trendLine.Create(0,"PriceLine_"+countTrend,0,divergencePoints.timeExtrPrice1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2);           
            trendLine.Color(lineColors[countTrend % 5] );         
            //создаем линию схождения\расхождения на MACD
            trendLine.Create(0,"MACDLine_"+countTrend,1,divergencePoints.timeExtrMACD1,divergencePoints.valueExtrMACD1,divergencePoints.timeExtrMACD2,divergencePoints.valueExtrMACD2);            
            //увеличиваем количество тренд линий
            countTrend++;
            
            localMax = high[lastBarIndex];
            localMin = low[lastBarIndex];
            for (count=1;count<=depth;count++)
             {
              if (high[lastBarIndex-count] > localMax)
               localMax = high[lastBarIndex-count];
              if (low[lastBarIndex-count] < localMin)
               localMin = low[lastBarIndex-count];
             } 
             
            if (retCode == 1)
             {
               if ( GreatDoubles ( (localMax - close[lastBarIndex]), (close[lastBarIndex] - localMin) ) )
                 {
                   countDivPos ++; // увеличиваем счетчик положительных схождений
                 }
               else
                 {
                   countDivNeg ++; // иначе увеличиваем счетчик отрицательных схождений
                 }
             }
            if (retCode == -1)
             {
               if (LessDoubles ( (localMax - close[lastBarIndex]), (close[lastBarIndex] - localMin) ) )
                 {
                  countConvPos ++; // увеличиваем счетчик положительных расхождений
                 }
               else
                 {
                  countConvNeg ++; // иначе увеличиваем счетчик отрицательных расхождений
                 }   
             }
        
           }
        }
        
    Alert("________________________________________");
    Alert("Не актуальных расхождений: ",countDivNeg);
    Alert("Актуальных расхождений: ",countDivPos);
    Alert("Всего расхождений: ",countDivPos+countDivNeg);
    Alert("Не актуальных схождений: ",countConvNeg);
    Alert("Актуальных схождений: ",countConvPos);
    Alert("Всего схождений: ",countConvPos+countConvNeg);
    Alert("Результаты поиска схождений\расхождений:");
        
       first_calculate = false;
     }
    else  // если запуска не первый
     { 
       // загрузим буфер MACD
       if ( CopyBuffer(handleMACD,0,0,rates_total,bufferMACD) < 0 ||
            CopyBuffer(handleMACD,1,0,rates_total,signalMACD) < 0 )
           {
             // если не удалось загрузить буфера MACD
             Alert("такие дела");
             return (0);
           }                 
       // если сформирован новый бар
       if (isNewBar.isNewBar() > 0)
        {        
         // распознаем схождение\расхождение
         retCode = divergenceMACD (handleMACD,_Symbol,_Period,1,divergencePoints);
         // если схождение\расхождение обнаружено
         if (retCode)
          {   
           trendLine.Color(lineColors[countTrend % 5] );     
           // создаем линию схождения\расхождения              
           trendLine.Create(0,"PriceLine_"+countTrend,0,divergencePoints.timeExtrPrice1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2); 
           //создаем линию схождения\расхождения на MACD
           trendLine.Create(0,"MACDLine_"+countTrend,1,divergencePoints.timeExtrMACD1,divergencePoints.valueExtrMACD1,divergencePoints.timeExtrMACD2,divergencePoints.valueExtrMACD2);    
           // увеличиваем количество тренд линий
           countTrend++;     
          
          }        
        }
     } 
    
    return(rates_total);
  }
