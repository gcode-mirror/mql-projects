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
//| Индикатор, показывающий расхождения MACD                         |
//| 1) рисует MACD                                                   |
//| 2) рисует линиями расхождения на MACD и на графике цены          |
//| 3) рисует вертикальную линию в момент возникновения сигнала      |
//+------------------------------------------------------------------+

//#define _Buy 1
//#define _Sell -1

// подключаем библиотеки 
#include <Lib CisNewBar.mqh>                       // для проверки формирования нового бара
#include <Divergence/divergenceMACD.mqh>           // подключаем библиотеку для поиска расхождений MACD
#include <ChartObjects/ChartObjectsLines.mqh>      // для рисования линий расхождения
#include <CompareDoubles.mqh>                      // для проверки соотношения  цен
#include <CEventBase.mqh>                          // для генерации событий     


// входные пользовательские параметры индикатора
sinput string macd_params     = "";                // ПАРАМЕТРЫ ИНДИКАТОРА MACD
input  int    fast_ema_period = 12;                // период быстрой средней MACD
input  int    slow_ema_period = 26;                // период медленной средней MACD
input  int    signal_period   = 9;                 // период усреднения разности MACD
input  ENUM_APPLIED_PRICE priceType = PRICE_CLOSE; // тип цен, по которым вычисляется MACD

// параметры индикаторных буферов 
#property indicator_buffers 3                      // задействовано 2 индикаторных буфера
#property indicator_plots   1                      // 1 буфер отображаются на графиках

// параметры  буфера (MACD)
#property indicator_type1 DRAW_HISTOGRAM           // гистограммы
#property indicator_color1  clrWhite               // цвет гистограммы
#property indicator_width1  1                      // толщина гистограммы
#property indicator_label1  "MACD"                 // наименование буфера

// глобальные переменные индикатора
int                handleMACD;                     // хэндл MACD
int                lastBarIndex;                   // индекс последнего бара 
int                retCode;                        // для записи результата вычисления  расхождения  
long               countDiv;                       // счетчик тренд линий (для рисования линий расхождений) 

CChartObjectTrend  trendLine;                      // объект класса трендовой линии (для отображения расхождений)
CChartObjectVLine  vertLine;                       // объект класса вертикальной линии
CisNewBar          *isNewBar;                      // для проверки формирования нового бара

CEventBase         *event;                         // для генерации событий 
SEventData         eventData;                      // структура полей событий

CDivergenceMACD    *divMACD;
// буферы индикатора 
double bufferMACD[];                               // буфер уровней MACD
double bufferDiv[];                                // буфер сигналов расхождения
double lastPriceDiv[];                            // буфер цены конца расхождения 

// переменные для хранения времени последних отрицательных и положительных значений MACD
datetime  lastExtrMinMACD    = 0;                   // время последнего отрицательного MACD
datetime  lastExtrMaxMACD    = 0;                   // время последнего отрицательного MACD

// переменные для хранения времени перехода через ноль для расхождений MACD
datetime  lastMaxWithDiv = 0;                      // время последнего минуса расхождения на SELL
datetime  lastMinWithDiv  = 0;                    // время последнего плюса расхождения на BUY

bool firstTimeUse = true;                          //Флаг, по которому происходит лтбо полное обновление массива экстремумов Стохастика 
                                                   //либо добавление нового экстремум при его наличии на каждом новом баре

// дополнительные функции работы индикатора
void    DrawIndicator (datetime vertLineTime);     // отображает линии индикатора. В функцию передается время вертикальной линии (сигнала расхождения)

   
// инициализация индикатора
int OnInit()
{  
 // буфер сигналов расхождений устанавливаем как в таймсерии
 ArraySetAsSeries(bufferDiv,true);
 // буфер MACD устанавливаем как в таймсерии
 ArraySetAsSeries(bufferMACD,true);
 // буфер цен начала расхождения устанавливаем как в таймсерии
 ArraySetAsSeries(lastPriceDiv,true);
 // загружаем хэндл индикатора MACD
 handleMACD = iMACD(_Symbol, _Period, fast_ema_period,slow_ema_period,signal_period,PRICE_CLOSE);
 if ( handleMACD == INVALID_HANDLE)  // если не удалось загрузить хэндл MACD
 {
  return(INIT_FAILED);  // то инициализация завершилась не успенно
 }  
     
 int bars = Bars(_Symbol, _Period);
 divMACD = new CDivergenceMACD(_Symbol, _Period, handleMACD, bars - DEPTH_MACD, DEPTH_MACD);  
 isNewBar = new CisNewBar(_Symbol, _Period);
 // удаляем все графические объекты (линии расхождений, а также линии появления сигналов расхождений)  
 ObjectsDeleteAll(0,0,OBJ_TREND); // все трендовые линии с ценового графика 
 ObjectsDeleteAll(0,1,OBJ_TREND); // все трендовые линии с побочного графика
 ObjectsDeleteAll(0,0,OBJ_VLINE); // все вертикальные линии, обозначающие момент возникновения расхождения
 // связываем индикаторы с буферами 
 SetIndexBuffer(0,bufferMACD,INDICATOR_DATA);            // буфер MACD
 SetIndexBuffer(1,bufferDiv ,INDICATOR_CALCULATIONS);    // буфер расхождений (моментов возникновения сигналов)
 SetIndexBuffer(2,lastPriceDiv ,INDICATOR_CALCULATIONS); // буфер расхождений (моментов возникновения сигналов)
 // инициализация глобальных  переменных
 countDiv = 0; // выставляем начальное количество расхождений
   
 event = new CEventBase(_Symbol, _Period, 100);                            // не оч удобная штука 100                         
 if (event == NULL)
 {
  Print("Ошибка при инициализации индикатора DrawExtremums. Не удалось создать объект класса CEventBase");
  return (INIT_FAILED);
 }
 // создаем события
 event.AddNewEvent("SELL");
 event.AddNewEvent("BUY");
                                      
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
 ArrayFree(lastPriceDiv);
 // освобождаем хэндл MACD
 IndicatorRelease(handleMACD);
 delete divMACD;
 delete isNewBar;
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
{
 ArraySetAsSeries (time, true); 
 ArraySetAsSeries (open, true); 
 ArraySetAsSeries (high, true);
 ArraySetAsSeries (low,  true); 
 ArraySetAsSeries (close,true);
  
 if (prev_calculated == 0) // если на пред. вызове было обработано 0 баров, значит этот вызов первый
 {  
 
  firstTimeUse = true;
  //Обнулим буферы индикатора (в надежде на то, что каждый последующий элемент тоже обнулится)
  ArrayInitialize(bufferDiv, 0);       // обнуляем буфер сигналов расхождений MACD
  ArrayInitialize(lastPriceDiv, 0);   // обнуляем буфер цен начала расхождения
   
  
  // проходим по всем барам истории и ищем расхождения MACD
  for (lastBarIndex = rates_total - DEPTH_MACD - 1; lastBarIndex >= 1; lastBarIndex--)
  {       
   //Заполним массив экстремумов MACD        
   retCode = divMACD.countDivergence(lastBarIndex, firstTimeUse); // получаем сигнал на расхождение
   firstTimeUse = false; 
   if (retCode == -2)
   {
    Print("Ошибка индикатора ShowMeYourDivMACD. Не удалось загрузить буферы MACD");
    return (0);
   }
   lastExtrMinMACD = divMACD.getLastExtrMinTime();           //  сохраняем время последнего нижнего экстремума MACD     
   lastExtrMaxMACD = divMACD.getLastExtrMaxTime();           //  сохраняем время последнего верхнего экстремума MACD 
       
   // если расхождение на SELL и время последнего расхождения отличается от времени последнего максимума
   if (retCode == _Sell && lastMaxWithDiv != lastExtrMaxMACD)
   {       
    DrawIndicator (time[lastBarIndex]);               // отображаем графические элементы индикатора    
    bufferDiv[lastBarIndex] = _Sell;  
    lastPriceDiv[lastBarIndex] = divMACD.valueExtrPrice2;                  // сохраняем в буфер значение       
    lastMaxWithDiv = lastExtrMaxMACD;              // сохраняем время последнего минуса MACD 
    
   }
   // если расхождение на BUY и время последнего расхождения отличается от времени последнего минимума
   if (retCode == _Buy && lastMinWithDiv != lastExtrMinMACD)
   {   
    DrawIndicator (time[lastBarIndex]);        // отображаем графические элементы индикатора     
    bufferDiv[lastBarIndex] = _Buy;            // сохраняем в буфер значение 
    lastPriceDiv[lastBarIndex] = divMACD.valueExtrPrice2; 
    lastMinWithDiv = lastExtrMinMACD;             // сохраняем время последнего плюса MACD
   }         
  }firstTimeUse = true;
 }
 else    // если это не первый вызов индикатора 
 {
  bufferDiv[0] = 0;
  lastPriceDiv[0] = 0;
  if (CopyBuffer(handleMACD, 0, 0, rates_total, bufferMACD) < 0  )
  {
   // если не удалось загрузить буфера MACD
   Print("Ошибка индикатора ShowMeYourDivMACD. Не удалось загрузить буферы MACD");
   return (rates_total);
  }     // сохраняем последние времена MACD
 
  retCode = divMACD.countDivergence(0, firstTimeUse);                     // получаем сигнал на расхождение
  lastExtrMinMACD = divMACD.getLastExtrMinTime();           //  сохраняем время последнего нижнего экстремума MACD     
  lastExtrMaxMACD = divMACD.getLastExtrMaxTime();           //  сохраняем время последнего верхнего экстремума MACD     
  firstTimeUse = false;
  // если не удалось загрузить буферы MACD
  if (retCode == -2)
  {
   Print("Ошибка индикатора ShowMeYourDivMACD. Не удалось загрузить буферы MACD");
   return (0);
  }

  // если расхождение на SELL и время предыдущего расхождения отличается от последнего максимума MACD
  if (retCode == _Sell && lastMaxWithDiv != lastExtrMaxMACD )
  {                                      
   DrawIndicator (time[0]);                  // отображаем графические элементы индикатора    
   bufferDiv[0] = _Sell;                     // сохраняем текущий сигнал
   lastPriceDiv[0] = divMACD.valueExtrPrice2;
   lastMaxWithDiv = lastExtrMaxMACD;         // сохраняем время последнего максимального экстремума
   
   eventData.dparam = divMACD.valueExtrPrice2;
   eventData.lparam = 1;                  //пока что не нужно?
   Generate("SELL",eventData,true);
  }    
  // если расхождение на BUY и время предыдущего расхождения отличается от последнего минимума MACD
  if (retCode == _Buy && lastMinWithDiv != lastExtrMinMACD)
  {                                        
   DrawIndicator (time[0]);               // отображаем графические элементы индикатора    
   bufferDiv[0] = _Buy;                   // сохраняем текущий сигнал
   lastPriceDiv[0] = divMACD.valueExtrPrice2;
   lastMinWithDiv = lastExtrMinMACD;      // сохраняем время последнего плюса
   
   eventData.dparam = divMACD.valueExtrPrice2;
   eventData.lparam = -1;                 //пока что не нужно?
   Generate("BUY",eventData,true);
  }                  
 }
 return(rates_total);
}

  
// функция отображения графических элементов индикатора
void DrawIndicator (datetime vertLineTime)
{
  trendLine.Color(clrYellow);
  // создаем линию схождения\расхождения                    
  trendLine.Create(0,"PriceLine_"+IntegerToString(countDiv)+" "+TimeToString(divMACD.timeExtrPrice2),0,divMACD.timeExtrPrice1,divMACD.valueExtrPrice1,divMACD.timeExtrPrice2,divMACD.valueExtrPrice2);           
  trendLine.Color(clrYellow);         
  // создаем линию схождения\расхождения на MACD
  trendLine.Create(0,"MACDLine_"+IntegerToString(countDiv),1,divMACD.timeExtrMACD1,divMACD.valueExtrMACD1,divMACD.timeExtrMACD2,divMACD.valueExtrMACD2);            
  vertLine.Color(clrRed);
  // создаем вертикальную линию, показывающий момент появления расхождения MACD
   vertLine.Create(0,"MACDVERT_"+IntegerToString(countDiv),0,vertLineTime);
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