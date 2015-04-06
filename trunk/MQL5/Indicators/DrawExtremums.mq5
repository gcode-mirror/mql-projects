//+------------------------------------------------------------------+
//|                                                           DE.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 6   // задействовано 6 буферов
#property indicator_plots   2   // два из которых отрисовываются на графике

#property indicator_type1   DRAW_ARROW
#property indicator_type2   DRAW_ARROW

//+------------------------------------------------------------------+
//| Индикатор, отображающий экстремумы                               |
//+------------------------------------------------------------------+
// подключение необходимых библиотек
//#include <DrawExtremums/CCalcExtremums.mqh>// вычисление экстремумов
#include <CLog.mqh>                        // для сохранения в лог
#include <CompareDoubles.mqh>              // для сравнения действительных чисел
#include <CEventBase.mqh>                  // для генерации событий     
#include <DrawExtremums\CExtremum.mqh>      // Класс эестремумов
#include <StringUtilities.mqh>             
#include <CLog.mqh>                        // для лога

#define DEFAULT_PERCENTAGE_ATR 1.0   // по умолчанию новый экстремум появляется когда разница больше среднего бара

// перечисление для типа пришедшего экстремума
enum ENUM_CAME_EXTR
{
 CAME_HIGH = 0,
 CAME_LOW = 1,
 CAME_BOTH = 2,
 CAME_NOTHING = 3
};

// индикаторные буферы
double bufferFormedExtrHigh[];  // буфер сформированных верхних экстремумов
double bufferFormedExtrLow[];   // буфер сформированных нижних экстремумов
double bufferAllExtrHigh[];     // буфер, хранящий все верхние экстремумы на истории
double bufferAllExtrLow[];      // буфер, хранящий все нижние экстремумы на истории
double bufferTimeExtrHigh[];    // буфер времени сформированных верхних экстремумов
double bufferTimeExtrLow[];     // буфер времени сформированных нижних экстремумов
 
// системные переменные

// хэндлы индикаторов
int handleForAverBar;      // хэндл индикатора для вычисления среднего бара 
int handleIsNewBar;        // хэндл индикатора IsNewBar
// другие переменные
int indexPrevUp   = -1;    // индекс последнего верхнего экстремума, которого нужно затереть
int indexPrevDown = -1;    // индекс последнего нижнего экстремума, которого нужно затереть
int depth;                 // глубина истории
int jumper=0;              // переменная для чередования экстремумов
int prevJumper=0;          // предыдущее значение jumper
double averageATR;        // среднее значение бара
double percentage_ATR;     // коэфициент отвечающий за то во сколько раз движение цены должно
                           // превысить средний бар что бы появился новый экстремум 
                           
double lastExtrUpValue;    // значение последнего экстремума
double lastExtrDownValue;  // значение последнего экстемума   
datetime lastExtrUpTime;   // время последнего экстремума HIGH
datetime lastExtrDownTime; // время последнего экстремума LOW
datetime lastBarTime = 0;  // время последнего бара

// объекты 
CEventBase *event;         // для генерации событий 
SEventData eventData;      // структура полей событий
// структуры экстремумов
CExtremum *extrHigh;       // структура для хранения верхнего экстремума
CExtremum *extrLow;        // структура для хранения нижнего экстремума

ENUM_CAME_EXTR came_extr;  // переменная для хранения типа пришедшего экстремума

int OnInit()
{
 // задаем индикаторную глубину на все бары
 depth = Bars(_Symbol,_Period);
 // создаем хэндл индикатора для вычисления среднего бара
 handleForAverBar = iMA(_Symbol, _Period, 100, 0, MODE_EMA, iATR(Symbol(), _Period, 30));
 if (handleForAverBar == INVALID_HANDLE)
 {
  Print("Ошибка при инициализации индикатора DrawExtremums. Не удалось создать хэндл индикатора AverageATR");
  return (INIT_FAILED);
 }
 //получение коэфициента ATR в зависимости от периода
 GetATRCoefficient(_Period);
 
 // вычисление среднего значения бара
 averageATR = AverageBar(TimeCurrent());

 // создаем объект генерации событий 
 extrHigh = new CExtremum(0,-1);
 extrLow = new CExtremum(0,-1);
 event = new CEventBase(_Symbol, _Period, 100);
 if (event == NULL)
 {
  Print("Ошибка при инициализации индикатора DrawExtremums. Не удалось создать объект класса CEventBase");
  return (INIT_FAILED);
 }
 // создаем события
 event.AddNewEvent("EXTR_UP");
 event.AddNewEvent("EXTR_UP_FORMED");
 event.AddNewEvent("EXTR_DOWN");
 event.AddNewEvent("EXTR_DOWN_FORMED");      
 // задаем индексацию индикаторных буферов
 SetIndexBuffer(0, bufferFormedExtrHigh, INDICATOR_DATA);
 SetIndexBuffer(1, bufferFormedExtrLow, INDICATOR_DATA);
 SetIndexBuffer(2, bufferAllExtrHigh,INDICATOR_CALCULATIONS);
 SetIndexBuffer(3, bufferAllExtrLow,INDICATOR_CALCULATIONS);
 SetIndexBuffer(4, bufferTimeExtrHigh,INDICATOR_CALCULATIONS);
 SetIndexBuffer(5, bufferTimeExtrLow,INDICATOR_CALCULATIONS);
 
 // выставляем индексацию буферов
 ArraySetAsSeries(bufferAllExtrHigh,false);
 ArraySetAsSeries(bufferAllExtrLow,false);
 ArraySetAsSeries(bufferFormedExtrHigh,false);
 ArraySetAsSeries(bufferFormedExtrLow,false);
 ArraySetAsSeries(bufferTimeExtrHigh,false);
 ArraySetAsSeries(bufferTimeExtrLow,false);
  
 // задаем тип графическ
 PlotIndexSetInteger(0, PLOT_ARROW, 218);
 PlotIndexSetInteger(1, PLOT_ARROW, 217); 
 //
 return(INIT_SUCCEEDED);
}
  
void OnDeinit (const int reason)
  {   
   //--- Первый способ получить код причины деинициализации
   Print(__FUNCTION__,"_Код причины деинициализации = ",reason);  
   // освобождаем индикаторные буферы
   ArrayFree(bufferFormedExtrHigh);
   ArrayFree(bufferFormedExtrLow);
   ArrayFree(bufferAllExtrHigh);
   ArrayFree(bufferAllExtrLow);
   ArrayFree(bufferTimeExtrHigh);
   ArrayFree(bufferTimeExtrLow);
   // освобождаем индикаторный хэндл
   IndicatorRelease(handleForAverBar);
   // удаляем объекты
   delete event;
   delete extrHigh;
   delete extrLow;
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
   // если это первый расчет индикатора
   if(prev_calculated == 0) 
   {   
    if (BarsCalculated(handleForAverBar) < 1)
    {
     return (0);
    }
    // проходим по всей истории и вычисляем экстремум\экстремумы
    for(int i = 0; i < rates_total;  i++)    
    {
     // обнуляем значения экстремумов
     bufferAllExtrHigh[i]    = 0;
     bufferAllExtrLow[i]     = 0;
     bufferFormedExtrHigh[i] = 0;
     bufferFormedExtrLow[i]  = 0;
     // получаем тип вычисленного экстремума
     came_extr = isExtremum(time[i],false);
    
     // если обновились оба экстремума
     if (came_extr == CAME_BOTH)
     {
      bufferAllExtrHigh[i] = extrHigh.price;
      bufferAllExtrLow[i]  = extrLow.price;            
      bufferTimeExtrHigh[i] = double(extrHigh.time);
      bufferTimeExtrLow[i] = double(extrLow.time);
      // если верхний экстремум пришел раньше нижнего
      if (extrHigh.time > extrLow.time)
      {
       // сохраняем последнее значение нижнего экстремума
       lastExtrDownValue = extrLow.price;
       lastExtrDownTime  = extrLow.time;
       indexPrevDown = i;
       // если до этого был верхний экстремум
       if (jumper == 1)
       {
        jumper = -1;             
       }  
      }
      // если нижний экстремум пришел раньше верхнего
      if (extrLow.time > extrHigh.time)
      {
       // сохраняем последнее значение нижнего экстремума
       lastExtrUpValue = extrHigh.price;
       lastExtrUpTime  = extrHigh.time;
       indexPrevUp = i;
       // если до этого был нижний экстремум
       if (jumper == -1)
       {
        jumper = 1;             
       }  
      }             
     }    
              
     // если обновился верхний экстремум 
     if (came_extr == CAME_HIGH)
     {
      bufferAllExtrHigh[i] = extrHigh.price;       // сохраняем в буфер значение полученного экстремума
      bufferTimeExtrHigh[i] = double(extrHigh.time);          
      lastExtrUpValue = extrHigh.price;
      lastExtrUpTime  = extrHigh.time;
            
      if (jumper == -1)
      {
       bufferFormedExtrLow[indexPrevDown] = lastExtrDownValue; // сохраняем сформированный экстремум         
       bufferTimeExtrLow[indexPrevDown] = double(lastExtrDownTime);    // сохраняем время сформированного экстремума             
       prevJumper = jumper;   
      } 
              
      jumper = 1;
      indexPrevUp = i;  // обновляем предыдущий индекс             
     }
     // если обновился нижний экстремум
     if (came_extr == CAME_LOW)
     {        
      bufferAllExtrLow[i] = extrLow.price;
      bufferTimeExtrLow[i] = double(extrLow.time);
      lastExtrDownValue = extrLow.price;
      lastExtrDownTime  = extrLow.time;
            
      if (jumper == 1)
      {
       bufferFormedExtrHigh[indexPrevUp] = lastExtrUpValue; // сохраняем сформированный экстремум
       bufferTimeExtrHigh[indexPrevUp] = double(lastExtrUpTime);  // сохраняем время сформированного экстремума                    
       prevJumper = jumper;
      }
      jumper = -1;
      indexPrevDown = i; // обновляем предыдущий индекс
     }
    }
    lastBarTime = time[rates_total-1];   // сохраняем время последнего бара
   }
   // если в реальном времени
   else
   {              
    // получаем тип пришедшего экстремума
    came_extr = isExtremum(time[rates_total-1],true);
      
    // если обновился верхний экстремум
    if (came_extr == CAME_HIGH )
    {            
     bufferAllExtrHigh[rates_total-1] = extrHigh.price;
     bufferTimeExtrHigh[rates_total-1] = double(extrHigh.time);
          
     lastExtrUpValue = extrHigh.price;
     lastExtrUpTime = extrHigh.time;
     // запись информации об экстремуме
     eventData.dparam = extrHigh.price;
     eventData.lparam = long(extrHigh.time);
     event.Generate("EXTR_UP",eventData,true);
     if (jumper == -1)
     {   
      bufferFormedExtrLow[indexPrevDown] = lastExtrDownValue;        // сохраняем сформированный экстремум
      bufferTimeExtrLow[indexPrevDown] = long(lastExtrDownTime);     // сохраняем время сформированного экстремума
      // запись инмормации об экстремуме
      eventData.dparam = lastExtrDownValue;
      eventData.lparam = long(lastExtrDownTime);  
      prevJumper = jumper;
      event.Generate("EXTR_DOWN_FORMED",eventData,true);
     }
     jumper = 1;
     indexPrevUp = rates_total-1;
    }
    // если обновился нижний экстремум
    if (came_extr == CAME_LOW)
    {
     bufferAllExtrLow[rates_total-1] = extrLow.price;
     bufferTimeExtrLow[rates_total-1] = double(extrLow.time);
          
     lastExtrDownValue = extrLow.price;
     lastExtrDownTime = extrLow.time;   
     // запись информации об экстремуме
     eventData.dparam = extrLow.price;
     eventData.lparam = long(extrLow.time);
     event.Generate("EXTR_DOWN",eventData,true);               
     if (jumper == 1)
     {             
      bufferFormedExtrHigh[indexPrevUp] = lastExtrUpValue;        // сохраняемт сформированный экстремум
      bufferTimeExtrHigh[indexPrevUp] = long(lastExtrUpTime);     // сохраняем время сформированного экстремума
      // запись инмормации об экстремуме
      eventData.dparam = lastExtrUpValue;  
      eventData.lparam = long(lastExtrUpTime);      
      prevJumper = jumper;          
      event.Generate("EXTR_UP_FORMED",eventData,true);         
     }
     jumper = -1;
     indexPrevDown = rates_total-1;
    }      
   }
   return(rates_total);
  } 
   
//+------------------------------------------------------------------+
//|       Дополнительные функции индикатора                          |
//+------------------------------------------------------------------+
 
// метод выбора ATR при инициализации
// выбираем коэфициент в зафисимости от ТФ 
void GetATRCoefficient(ENUM_TIMEFRAMES period)
{
 switch(period)
 {
  case(PERIOD_M1):
    percentage_ATR = 3.0;
    break;
  case(PERIOD_M5):
    percentage_ATR = 3.0;
    break;
  case(PERIOD_M15):
    percentage_ATR = 2.2;
    break;
  case(PERIOD_H1):
    percentage_ATR = 2.2;
    break;
  case(PERIOD_H4):
    percentage_ATR = 2.2;
    break;
  case(PERIOD_D1):
    percentage_ATR = 2.2;
    break;
  case(PERIOD_W1):
    percentage_ATR = 2.2;
    break;
  case(PERIOD_MN1):
    percentage_ATR = 2.2;
    break;
  default:
    percentage_ATR = DEFAULT_PERCENTAGE_ATR;
    break;
 }  
} 

// метод вычисления экстремума на текущем баре
ENUM_CAME_EXTR isExtremum(datetime start_pos_time=__DATETIME__,bool now=true)
{
 double high = 0, low = 0;                     // временная переменная в которой будет хранится цена для расчета max и min соответственно
 double averageBarNow;                         // для хранения среднего размера бара
 double difToNewExtremum;                      // для хранения минимального расстояния между экстремумами
 datetime extrHighTime = 0;                    // время прихода верхнего экстремума 
 datetime extrLowTime = 0;                     // время прихода нижнего экстремума
 MqlRates bufferRates[2];                      // котировки
 came_extr = CAME_NOTHING;      // тип пришедшего экстремума (возвращаемое значение)
 // пытаемся скопировать два бара 
 if(CopyRates(_Symbol, _Period, start_pos_time, 2, bufferRates) < 2)
  {
   log_file.Write(LOG_CRITICAL, StringFormat("%s Не удалось скопировать котировки. symbol = %s, Period = %s, time = %s"
                                            ,MakeFunctionPrefix(__FUNCTION__), _Symbol, PeriodToString(_Period), TimeToString(start_pos_time)));
   return(came_extr); 
  }
 // вычисляем средний размер бара
 averageBarNow = AverageBar(start_pos_time);
 // если удалось вычислить среднее значение и
 if (averageBarNow > 0) averageATR = averageBarNow; 
 // вычисляем минимальное расстояние между экстремумами
 difToNewExtremum = averageATR * percentage_ATR;  
 
 if (extrHigh.time > extrLow.time && bufferRates[1].time < extrHigh.time && !now) return (came_extr); 
 if (extrHigh.time < extrLow.time && bufferRates[1].time < extrLow.time && !now) return (came_extr); 
 
 if (now) // за время жизни бара цена close проходит все его значения от low до high
 {        // соответсвено если на данном баре есть верхний экстремум то он будет достигнут когда close будет max  и наоборот с low
  high = bufferRates[1].close;
  low = bufferRates[1].close;
 }
 else    // во время работы на истории мы смотрим на бар один раз соотвественно нам сразу нужно узнать его максимум и минимум
 {
  high = bufferRates[1].high;
  low = bufferRates[1].low;
 }
 
 if ( (extrHigh.direction == 0  && extrLow.direction == 0)                         // Если экстремумов еще нет то говорим что сейчас экстремум
   || ((extrHigh.time > extrLow.time) && (GreatDoubles(high, extrHigh.price) ))    // Если последний экстремум - High, и цена пробила экстремум в ту же сторону 
   || ((extrHigh.time < extrLow.time) && (GreatDoubles(high,extrLow.price + difToNewExtremum) && GreatDoubles(high,bufferRates[0].high) )  )  ) // Если последний экстремум - Low, и цена отошла от экстремума на мин. расстояние в обратную сторону  
 {
  // сохраняем время прихода верхнего экстремума
  if (now) // если экстремумы вычисляются в реальном времени
   extrHighTime = TimeCurrent();
  else  // если экстремумы вычисляются на истории
   extrHighTime = bufferRates[1].time;
  came_extr = CAME_HIGH;  // типо пришел верхний экстремум   
 }
 
 if ( ( extrLow.direction == 0 && extrHigh.direction == 0)                      // Если экстремумов еще нет то говорим что сейчас экстремум
   || ((extrLow.time > extrHigh.time) && (LessDoubles(low,extrLow.price)))    // Если последний экстремум - Low, и цена пробила экстремум в ту же сторону
   || ((extrLow.time < extrHigh.time) && (LessDoubles(low,extrHigh.price - difToNewExtremum) && LessDoubles(low,bufferRates[0].low) ) ) )  // Если последний экстремум - High, и цена отошла от экстремума на мин. расстояние в обратную сторону
 {
  // если на этом баре пришел верхний экстремум
  if (extrHighTime > 0)
  {
   // если close ниже open, то говорим, что верхний экстремум пришел раньше нижнего
   if(bufferRates[1].close <= bufferRates[1].open) 
   {
    extrLowTime = bufferRates[1].time + datetime(100);
   }
   else // иначе полагаем, что нижний пришел раньше верхнего
   {
    extrHighTime = bufferRates[1].time + datetime(100);
    extrLowTime  = bufferRates[1].time;
   }
   came_extr = CAME_BOTH;   // типо пришли оба экстремума     
  }
  else // иначе просто сохраняем время прихода нижнего экстремума
  {
   if (now) // если экстремумы вычисляются в реальном времени
    extrLowTime = TimeCurrent();
   else // если экстремумы вычисляются на истории
    extrLowTime = bufferRates[1].time;
   came_extr = CAME_LOW; // типо пришел нижний экстремум     
  }
 }

 // заполняем поля структур экстремумов
 
 // если пришел новый верхний экстремум
 if (extrHighTime > 0)
 {
  // заполняем поля экстремума
  extrHigh.direction = 1;
  extrHigh.price = high;
  extrHigh.time = extrHighTime;
 }
 // если пришел новый нижний экстремум
 if (extrLowTime > 0)
 {
  // заполняем поля экстремума
  extrLow.direction = -1;
  extrLow.price = low;
  extrLow.time = extrLowTime;
 }  
 return (came_extr);
}

// метод вычисления среднего размера бара
double AverageBar(datetime start_pos)
{
 int copied = 0;
 double buffer_atr[1];
 if (handleForAverBar == INVALID_HANDLE)
 {
  log_file.Write(LOG_CRITICAL, StringFormat("%s ERROR %d. INVALID HANDLE ATR %s", MakeFunctionPrefix(__FUNCTION__), GetLastError(), EnumToString((ENUM_TIMEFRAMES)_Period)));
  return (-1);
 }
 copied = CopyBuffer(handleForAverBar, 0, start_pos, 1, buffer_atr);
 if (copied < 1) 
 {
  log_file.Write(LOG_CRITICAL, StringFormat("%s ERROR %d. Period = %s. copied = %d, calculated = %d, start time = %s"
                                           , MakeFunctionPrefix(__FUNCTION__)
                                           , GetLastError()
                                           , EnumToString((ENUM_TIMEFRAMES)_Period), copied
                                           , BarsCalculated(handleForAverBar), TimeToString(start_pos)));
  return(-1);
 }
 return (buffer_atr[0]);
}
