//+------------------------------------------------------------------+
//|                                                     smydMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window   // будем задействовать побочное окно индикатора

//+------------------------------------------------------------------+
//| Индикатор, показывающий расхождения Стохастика                   |
//| 1) рисует линии Стохастика                                       |
//| 2) рисует линиями расхождения на Стохастике и на графике цены    |
//| 3) рисует стрелочками момент возникновения сигнала               |
//| 4) хранит значения расхождений и экстремумов на цене             |
//+------------------------------------------------------------------+


// подключаем библиотеки 
#include <Lib CisNewBar.mqh>                          // для проверки формирования нового бара
#include <Divergence/divergenceStochastic.mqh>        // подключаем библиотеку для поиска расхождений MACD
#include <ChartObjects/ChartObjectsLines.mqh>         // для рисования линий расхождения
#include <CompareDoubles.mqh>                         // для проверки соотношения  цен
#include <CEventBase.mqh>                             // для генерации событий     


// входные пользовательские параметры индикатора
sinput string             stoc_params  = "";          // ПАРАМЕТРЫ ИНДИКАТОРА STOC
input int                 Kperiod      = 5;           // K-период (количество баров для расчетов)
input int                 Dperiod      = 3;           // D-период (период первичного сглаживания)
input int                 slowing      = 3;           // период для окончательного сглаживания
input ENUM_MA_METHOD      ma_method    = MODE_SMA;    // тип сглаживания
input ENUM_STO_PRICE      price_field  = STO_LOWHIGH; // способ расчета стохастика           
input int                 top_level    = 80;          // верхний уровень 
input int                 bottom_level = 20;          // нижний уровень 

// параметры индикаторных буферов 
#property indicator_buffers 5                         // задействовано 3 индикаторных буфера
#property indicator_plots   2                         // 2 буфера отображаются на графиках

// параметры буферов

// top level буфер
#property indicator_type1   DRAW_LINE               // линии
#property indicator_color1  clrWhite                // цвет линий
#property indicator_width1  1                       // толщина линий
#property indicator_style1  STYLE_SOLID             // стиль линий
#property indicator_label1  "StochasticLine"        // наименование буфера 
// bottom level буфер
#property indicator_type2   DRAW_LINE               // линии
#property indicator_color2  clrRed                  // цвет линий
#property indicator_width2  1                       // толщина линий
#property indicator_style2  STYLE_SOLID             // стиль линий
#property indicator_label2  "SignalLine"            // наименование буфера 


// глобальные переменные индикатора
int                handleSTOC;                      // хэндл Стохастика
int                lastBarIndex;                    // индекс последнего бара 
int                retCode;                         // для записи результата вычисления  расхождения  
long               countDiv;                        // счетчик тренд линий (для рисования линий расхождений) 

CChartObjectTrend  trendLine;                       // объект класса трендовой линии (для отображения расхождений)
CChartObjectVLine  vertLine;                        // объект класса вертикальной линии
CDivergenceSTOC    *divSTOC;                        // для поиска точек расхождения 

CEventBase         *event;                         // для генерации событий 
SEventData         eventData;                      // структура полей событий

// буферы индикатора 
double bufferMainLine[];                            // буфер уровней StochasticLine
double bufferSignalLine[];                          // буфер уровней SignalLine
double bufferDiv[];                                 // буфер моментов расхождения
double bufferExtrLeft[];                            // буфер времени левых  экстремумов
double bufferExtrRight[];                           // буфер времени правых экстремумов


// точки для хранения времени экстремумов цены   

datetime lastRightPriceBuy  = 0;  
datetime lastRightPriceSell = 0;

bool firstTimeUse = true;                          //Флаг, по которому происходит лтбо полное обновление массива экстремумов Стохастика 
                                                   //либо добавление нового экстремум при его наличии на каждом новом баре
// дополнительные функции работы индикатора
void    DrawIndicator (datetime vertLineTime);     // отображает линии индикатора. В функцию передается время вертикальной линии
   
// инициализация индикатора
int OnInit()
{  
 ArraySetAsSeries(bufferDiv,true);
 ArraySetAsSeries(bufferExtrLeft,true);
 ArraySetAsSeries(bufferExtrRight,true);   
 // загружаем хэндл индикатора Стохастика
 handleSTOC = iStochastic(_Symbol, _Period, Kperiod, Dperiod, slowing, ma_method, price_field);
 if (handleSTOC == INVALID_HANDLE)  // если не удалось загрузить хэндл Стохастика
 {
  return(INIT_FAILED);  // то инициализация завершилась не успешно
 }  
 // удаляем все графические объекты (линии расхождений, а также линии появления сигналов расхождений)  
 ObjectsDeleteAll(0, 0, OBJ_TREND); // все трендовые линии с ценового графика 
 ObjectsDeleteAll(0, 1, OBJ_TREND); // все трендовые линии с побочного графика
 ObjectsDeleteAll(0, 0, OBJ_VLINE); // все вертикальные линии, обозначающие момент возникновения расхождения
 // связываем индикаторы с буферами 
 SetIndexBuffer(0, bufferMainLine,     INDICATOR_DATA);           // буфер top level Стохастика
 SetIndexBuffer(1, bufferSignalLine,   INDICATOR_DATA);           // буфер bottom level Стохастика
 SetIndexBuffer(2, bufferDiv ,         INDICATOR_CALCULATIONS);   // буфер расхождений (моментов возникновения сигналов)
 SetIndexBuffer(3, bufferExtrLeft,     INDICATOR_CALCULATIONS);   // буфер времени левых экстремумов
 SetIndexBuffer(4, bufferExtrRight,    INDICATOR_CALCULATIONS);   // буфер времени правых экструмумов
 
 event = new CEventBase(100);                            // не оч удобная штука 100                         
 if (event == NULL)
 {
  Print("Ошибка при инициализации индикатора DrawExtremums. Не удалось создать объект класса CEventBase");
  return (INIT_FAILED);
 }
 // создаем события
 event.AddNewEvent(_Symbol, _Period, "SELL");
 event.AddNewEvent(_Symbol, _Period, "BUY");
 // инициализация глобальных  переменных
 countDiv = 0;                                             // выставляем начальное количество расхождений
 int lastbars  = Bars(_Symbol, _Period) - DEPTH_STOC;
 divSTOC       = new CDivergenceSTOC(handleSTOC, _Symbol, _Period, top_level, bottom_level, lastbars);
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
 ArrayFree(bufferMainLine);
 ArrayFree(bufferSignalLine);
 ArrayFree(bufferDiv);
 ArrayFree(bufferExtrLeft);
 ArrayFree(bufferExtrRight);
 // освобождаем хэндл Стохастика
 IndicatorRelease(handleSTOC);
 delete divSTOC;
 delete event;
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
{// положим индексацию нужных массивов как в таймсерии  
 ArraySetAsSeries (time, true); 
 ArraySetAsSeries (open, true); 
 ArraySetAsSeries (high, true);
 ArraySetAsSeries (low,  true); 
 ArraySetAsSeries (close,true);
 
 CopyBuffer(handleSTOC, 0, 0, rates_total, bufferMainLine);
 CopyBuffer(handleSTOC, 1, 0, rates_total, bufferSignalLine);

 if (prev_calculated == 0) // если на пред. вызове было обработано 0 баров, значит этот вызов первый
 {
  ArrayInitialize  (bufferDiv,0);
  ArrayInitialize  (bufferExtrLeft,0);
  ArrayInitialize  (bufferExtrRight,0);
  // загрузим буфер Стохастика
  firstTimeUse = true;              
  // проходим по всем барам истории и ищем расхождения Стохастика  
  for (lastBarIndex = rates_total - DEPTH_STOC - 1; lastBarIndex > 0; lastBarIndex--) 
  {
   // обнуляем текущее значение сигнала расхождений Стохастика
   bufferDiv[lastBarIndex] = 0;
   // обнуляем текущие значения экстремумов
   bufferExtrLeft[lastBarIndex]  = 0;
   bufferExtrRight[lastBarIndex] = 0;
   // найти расхождение на данном баре и получить сигнал                      
   retCode = divSTOC.countDivergence(lastBarIndex, firstTimeUse);
   firstTimeUse = false;     
   // если не удалось загрузить буферы Стохастика
   if (retCode == -2)
   {
    Print("Ошибка индикатора ShowMeYourDivSTOC. Не удалось загрузить буферы Стохастика");
    return (0);
   }
   // если BUY и точки экстремумов цены не совпадают с предыдущим расхождением 
   if (retCode == BUY && datetime(divSTOC.timeExtrPrice2) != lastRightPriceBuy)
   {             
    DrawIndicator(time[lastBarIndex]);                               // отображаем графические элементы индикатора     
    bufferDiv[lastBarIndex] = retCode;                               // сохраняем в буфер значение  
    bufferExtrLeft[lastBarIndex]  = double(divSTOC.timeExtrPrice2);  // сохраним время левого  экстремума
    bufferExtrRight[lastBarIndex] = double(divSTOC.timeExtrPrice1);  // сохраним время правого экстремума    
    lastRightPriceBuy =  divSTOC.timeExtrPrice2;                     // сохраняем время экстремумов цен
   }
   // если SELL и точки экстремумов цены не совпадают с предыдущим расхождением 
   if (retCode == SELL && datetime(divSTOC.timeExtrPrice2) != lastRightPriceSell)
   {             
    DrawIndicator (time[lastBarIndex]);   // отображаем графические элементы индикатора     
    bufferDiv[lastBarIndex] = retCode;    // сохраняем в буфер значение 
    bufferExtrLeft[lastBarIndex]  = double(divSTOC.timeExtrPrice2); // сохраним время левого  экстремума
    bufferExtrRight[lastBarIndex] = double(divSTOC.timeExtrPrice1); // сохраним время правого экстремума      
    // сохраняем время экстремумов цен
    lastRightPriceSell =  divSTOC.timeExtrPrice2;
   }           
  }firstTimeUse = true;
 }
 else    // если это не первый вызов индикатора 
 {
  // обнуляем текущее значение сигнала расхождений Стохастика
  bufferDiv[0] = 0;
  // обнуляем текущие значения экстремумов
  bufferExtrLeft[0]  = 0;
  bufferExtrRight[0] = 0; 
  
  //проверь Print("bufferDiv[0] = ", bufferDiv[0]);       
  retCode = divSTOC.countDivergence(0, firstTimeUse);    // получаем сигнал на расхождение
  firstTimeUse = false;
  // если не удалось загрузить буферы Стохастика
  if (retCode == -2)
  {
   Print(__FUNCTION__,"Ошибка индикатора ShowMeYourDivSTOC. Не удалось загрузить буферы Стохастика");
   return (0);
  }
  if (retCode == BUY && datetime(divSTOC.timeExtrPrice1) != lastRightPriceBuy)       
  {             
   DrawIndicator (time[0]);                              // отображаем графические элементы индикатора     
   bufferDiv[0] = retCode;                               // сохраняем в буфер значение    
   bufferExtrLeft[0]  = double(divSTOC.timeExtrPrice2);  // сохраним время левого  экстремума
   bufferExtrRight[0] = double(divSTOC.timeExtrPrice1);  // сохраним время правого экстремума  
   lastRightPriceBuy =  divSTOC.timeExtrPrice1;          // сохраняем время экстремумов цен
   
   eventData.dparam = divSTOC.valueExtrPrice2;           // сохраняем цену , на которой было найдено расхождение
   Generate("BUY", eventData, true);
  }
  // если SELL и точки экстремумов цены не совпадают с предыдущим расхождением 
  if (retCode == SELL && datetime(divSTOC.timeExtrPrice1) != lastRightPriceSell)
  {                               
   DrawIndicator (time[0]);                               // отображаем графические элементы индикатора     
   bufferDiv[0] = retCode;                                // сохраняем в буфер значение
   bufferExtrLeft[0]  = double(divSTOC.timeExtrPrice2);   // сохраним время левого  экстремума
   bufferExtrRight[0] = double(divSTOC.timeExtrPrice1);   // сохраним время правого экстремума      
   lastRightPriceSell =  divSTOC.timeExtrPrice1;          // сохраняем время экстремумов цен   
   
   eventData.dparam = divSTOC.valueExtrPrice2;            // сохраняем цену , на которой было найдено расхождение
   Generate("SELL", eventData, true);
  }                    
 }
 return(rates_total);
}

  
// функция отображения графических элементов индикатора
void DrawIndicator (datetime vertLineTime)
 {
   trendLine.Color(clrYellow);
   // создаем линию схождения\расхождения                    
   trendLine.Create(0,"STOCPriceLine_" + IntegerToString(countDiv),0,divSTOC.timeExtrPrice1,divSTOC.valueExtrPrice1,divSTOC.timeExtrPrice2,divSTOC.valueExtrPrice2);           
   trendLine.Color(clrYellow);         
   // создаем линию схождения\расхождения на Стохастике
   trendLine.Create(0,"STOCLine_" + IntegerToString(countDiv),1,divSTOC.timeExtrSTOC1,divSTOC.valueExtrSTOC1,divSTOC.timeExtrSTOC2,divSTOC.valueExtrSTOC2);            
   vertLine.Color(clrRed);
   // создаем вертикальную линию, показывающий момент появления расхождения Стохастика
   vertLine.Create(0,"STOCVERT_"+IntegerToString(countDiv),0,vertLineTime);
   countDiv++; // увеличиваем количество отображаемых схождений
 }
 
 
void Generate(string id_nam, SEventData &_data, const bool _is_custom = true)
{
 // проходим по всем открытым графикам с текущим символом и ТФ и генерируем для них события
 long z = ChartFirst();
 while (z >= 0)
 {
  if (ChartSymbol(z) == _Symbol && ChartPeriod(z)==_Period)  // если найден график с текущим символом и периодом 
  {
   // генерим событие для текущего графика
   event.Generate(z,id_nam,_data,_is_custom);
  }
  z = ChartNext(z);      
 }     
}