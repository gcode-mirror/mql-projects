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
#include <divergenceStochastic.mqh>           // подключаем библиотеку для поиска схождений и расхождений стохастика
#include <ChartObjects\ChartObjectsLines.mqh> // для рисования линий схождения\расхождения

 // параметры индикатора
 
//---- всего задействовано 2 буфера
#property indicator_buffers 2
//---- использовано 2 графических построений
#property indicator_plots   2

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
input int                 DEPTH_STOC=10;                // большой хвост буфера 
input int                 ALLOW_DEPTH_FOR_PRICE_EXTR=3; // малый хвост буфера


//+------------------------------------------------------------------+
//| Глобальные переменные                                            |
//+------------------------------------------------------------------+

bool               first_calculate;        // флаг первого вызова OnCalculate
int                handleStoc;             // хэндл стохастика
int                lastBarIndex;           // индекс последнего бара   
long               countTrend;             // счетчик тренд линий

PointDiv           divergencePoints;       // схождения и расхождения стохастика
CChartObjectTrend  trendLine;              // объект класса трендовой линии
CisNewBar          isNewBar;               // для проверки формирования нового бара

double bufferStoc[];    // буфер стохастика 1
double bufferStoc2[];   // буфер стохастика 2
 
//+------------------------------------------------------------------+
//| Базовые функции индикатора                                       |
//+------------------------------------------------------------------+

int OnInit()
  {
   // удаляем все графические объекты     
   ObjectsDeleteAll(0,0,OBJ_TREND);
   ObjectsDeleteAll(0,1,OBJ_TREND);   
   // связываем индикатор с буфером
   SetIndexBuffer(0,bufferStoc,INDICATOR_DATA);
   SetIndexBuffer(1,bufferStoc2,INDICATOR_DATA);   
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
          // сканируем историю по хэндлу на наличие расхождений\схождений 
          retCode = divergenceSTOC (handleStoc,_Symbol,_Period,top_level,bottom_level,DEPTH_STOC,ALLOW_DEPTH_FOR_PRICE_EXTR,divergencePoints,lastBarIndex);
          // если схождение\расхождение обнаружено
          if (retCode)
           {                                     
          //  trendLine.Color(lineColors[countTrend % 5] );
            //создаем линию схождения\расхождения                    
            trendLine.Create(0,"PriceLine_"+countTrend,0,divergencePoints.timeExtrPrice1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2);           
            
          //  trendLine.Color(lineColors[countTrend % 5] );         
            //создаем линию схождения\расхождения на стохастике
            trendLine.Create(0,"StocLine_"+countTrend,1,divergencePoints.timeExtrSTOC1,divergencePoints.valueExtrSTOC1,divergencePoints.timeExtrSTOC2,divergencePoints.valueExtrSTOC2);            
            //увеличиваем количество тренд линий
            countTrend++;
           }
           else
           {
            return (0);
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
         // распознаем схождение\расхождение стохастика
         retCode = divergenceSTOC (handleStoc,_Symbol,_Period,top_level,bottom_level,DEPTH_STOC,ALLOW_DEPTH_FOR_PRICE_EXTR,divergencePoints,1);         
         // если схождение\расхождение обнаружено
         if (retCode)
          {   
          // trendLine.Color(lineColors[countTrend % 5] );     
           // создаем линию схождения\расхождения              
           trendLine.Create(0,"PriceLine_"+countTrend,0,divergencePoints.timeExtrPrice1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2); 
          // trendLine.Color(lineColors[countTrend % 5] );           
           //создаем линию схождения\расхождения на MACD
           trendLine.Create(0,"StocLine_"+countTrend,1,divergencePoints.timeExtrSTOC1,divergencePoints.valueExtrSTOC1,divergencePoints.timeExtrSTOC2,divergencePoints.valueExtrSTOC2);    
           // увеличиваем количество тренд линий
           countTrend++;
          }      
        }
     } 
       
    return(rates_total);
  }
