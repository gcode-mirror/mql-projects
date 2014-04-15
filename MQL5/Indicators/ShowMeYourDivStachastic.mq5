//+------------------------------------------------------------------+
//|                                                      DisMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#include <Lib CisNewBar.mqh>                   // для проверки формирования нового бара
#include <Divergence/divergenceStochastic.mqh> // подключаем библиотеку для поиска схождений и расхождений стохастика
#include <ChartObjects\ChartObjectsLines.mqh>  // для рисования линий схождения\расхождения
#include <CompareDoubles.mqh>                  // для проверки соотношения  цен

 // параметры индикатора
 
//---- всего задействовано 2 буфера
#property indicator_buffers 3
//---- использовано 2 графических построений
#property indicator_plots   3

//---- в качестве индикатора уровней  использованы линии
#property indicator_type1 DRAW_LINE
//---- цвет индикатора
#property indicator_color1  clrWhite
//---- толщина линии индикатора
#property indicator_width1  1
//---- стиль линий
#property indicator_style1 STYLE_SOLID
//---- отображение метки линии индикатора
#property indicator_label1  "StochasticTopLevel"

//---- в качестве индикатора уровней  использованы линии
#property indicator_type2 DRAW_LINE
//---- цвет индикатора
#property indicator_color2  clrRed
//---- толщина линии индикатора
#property indicator_width2  1
//---- стиль линий
#property indicator_style2  STYLE_DASHDOT
//---- отображение метки линии индикатора
#property indicator_label2  "StochasticBottomLevel"

//---- в качестве индикатора уровней  использованы 
#property indicator_type3 DRAW_ARROW
//---- отображение метки линии индикатора

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
input BARS_MODE           bars_mode=ALL_HISTORY;        // режим загрузки истории
input short               bars=20000;                   // начальное количество баров истории (K-период)
input ENUM_MA_METHOD      ma_method=MODE_SMA;           // тип сглаживания
input ENUM_STO_PRICE      price_field=STO_LOWHIGH;      // способ расчета стохастика           
input int                 top_level=80;                 // верхний уровень 
input int                 bottom_level=20;              // нижний уровень 


//+------------------------------------------------------------------+
//| Глобальные переменные                                            |
//+------------------------------------------------------------------+

bool               first_calculate;        // флаг первого вызова OnCalculate
int                handleStoc;             // хэндл стохастика
int                lastBarIndex;           // индекс последнего бара   
long               countTrend;             // счетчик тренд линий

PointDivSTOC       divergencePoints;       // схождения и расхождения стохастика
CChartObjectTrend  trendLine;              // объект класса трендовой линии
CChartObjectVLine  vertLine;               // объект класса вертикальной линии
CisNewBar          isNewBar;               // для проверки формирования нового бара

double             bufferStoc[];           // буфер стохастика 1
double             bufferStoc2[];          // буфер стохастика 2
double             bufferArrow[];          // буфер стрелочек
 
// временные параменные для хранения локальных минимумов и максимумов
 double localMax;
 double localMin;

// счетчик в цикле по глубины вычисления схождений\расхождений

int count;


//+------------------------------------------------------------------+
//| Базовые функции индикатора                                       |
//+------------------------------------------------------------------+

int OnInit()
  { 
   // удаляем все графические объекты     
   ObjectsDeleteAll(0,0,OBJ_TREND);
   ObjectsDeleteAll(0,1,OBJ_TREND);   
   ObjectsDeleteAll(0,0,OBJ_VLINE);
   // связываем индикатор с буфером
   SetIndexBuffer(0,bufferStoc,INDICATOR_DATA);
   SetIndexBuffer(1,bufferStoc2,INDICATOR_DATA);   
   SetIndexBuffer(2,bufferArrow,INDICATOR_DATA);
     
   //--- зададим код символа для отрисовки в PLOT_ARROW
   PlotIndexSetInteger(2,PLOT_ARROW,159);
   //--- зададим cмещение стрелок по вертикали в пикселях 
   PlotIndexSetInteger(2,PLOT_ARROW_SHIFT,0);
   //--- установим в качестве пустого значения 0
   PlotIndexSetDouble (2,PLOT_EMPTY_VALUE,0);

   
   // инициализация глобальных  переменных
   first_calculate = true;
   countTrend = 1;
   // загружаем хэндл индикатора стохастика
   handleStoc = iStochastic(_Symbol,_Period,5,3,3,ma_method,price_field);
   return(INIT_SUCCEEDED);
  }

void OnDeinit ()
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
       // загрузим буферы стохастика
       if ( CopyBuffer(handleStoc,0,0,bars,bufferStoc) < 0 ||
            CopyBuffer(handleStoc,1,0,bars,bufferStoc2) < 0 )
           {
             // если не удалось загрузить буфера стохастика
             return (0);
           }    
       for (;lastBarIndex > 0; lastBarIndex--)
        {
          bufferArrow[rates_total-lastBarIndex-1] = 0;
          // сканируем историю по хэндлу на наличие расхождений\схождений 
          retCode = divergenceSTOC (handleStoc,_Symbol,_Period,top_level,bottom_level,divergencePoints,lastBarIndex);
          // если не удалось загрузить буфер
          if (retCode == -2)
           return (0);
          // если схождение\расхождение обнаружено
          if (retCode)
           {                                     
            //создаем линию схождения\расхождения                    
            trendLine.Create(0,"StoPriceLine_"+countTrend,0,divergencePoints.timeExtrPrice1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2);           
            //создаем вертикальную линию 
            vertLine.Create(0,"VertLine_"+countTrend,0,time[rates_total-lastBarIndex-1]);    

            
           if (retCode == 1)
            bufferArrow[rates_total-lastBarIndex-1] = 1;
           if (retCode == -1)
            bufferArrow[rates_total-lastBarIndex-1] = -1;      
            
            //создаем линию схождения\расхождения на стохастике
            trendLine.Create(0,"StocLine_"+countTrend,4,divergencePoints.timeExtrSTOC1,divergencePoints.valueExtrSTOC1,divergencePoints.timeExtrSTOC2,divergencePoints.valueExtrSTOC2);            
            
            //увеличиваем количество тренд линий
            countTrend++;
             
            localMax = high[rates_total-1-lastBarIndex];
            localMin = low[rates_total-1-lastBarIndex];

             
  
                 }
                 }
                  
            
       first_calculate = false;
     }
    else  // если запуска не первый
     { 
       // загрузим буфер стохастика
       if ( CopyBuffer(handleStoc,0,0,rates_total,bufferStoc) < 0 ||
            CopyBuffer(handleStoc,1,0,rates_total,bufferStoc2) < 0 )
           {
             // если не удалось загрузить буфера стохастика
             return (0);
           }                 
       // если сформирован новый бар
       if (isNewBar.isNewBar() > 0)
        {        
         bufferArrow[rates_total-1] = 0;
         // распознаем схождение\расхождение стохастика
         retCode = divergenceSTOC (handleStoc,_Symbol,_Period,top_level,bottom_level,divergencePoints,0);         
         // если схождение\расхождение обнаружено
         if (retCode)
          {   
          // trendLine.Color(lineColors[countTrend % 5] );     
           // создаем линию схождения\расхождения              
           trendLine.Create(0,"StoPriceLine_"+countTrend,0,divergencePoints.timeExtrPrice1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2); 
          // trendLine.Color(lineColors[countTrend % 5] );
           //создаем вертикальную линию 
           vertLine.Create(0,"VertLine_"+countTrend,0,time[rates_total-1]);  
           if (retCode == 1)
            bufferArrow[rates_total] = 1;
           if (retCode == -1)
            bufferArrow[rates_total] = -1;                            
           //создаем линию схождения\расхождения на MACD
           trendLine.Create(0,"StocLine_"+countTrend,4,divergencePoints.timeExtrSTOC1,divergencePoints.valueExtrSTOC1,divergencePoints.timeExtrSTOC2,divergencePoints.valueExtrSTOC2);    

           // увеличиваем количество тренд линий
           countTrend++;
          }      
        }
     } 
       
    return(rates_total);
  }
