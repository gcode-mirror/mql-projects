//+------------------------------------------------------------------+
//|                                               StatisticRobot.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

// сбор статистики пробития линий

#include <ChartObjects/ChartObjectsLines.mqh> // для рисования линий тренда
#include <SystemLib/IndicatorManager.mqh>     // библиотека по работе с индикаторами
#include <CompareDoubles.mqh>                 // для сравнения вещественных чисел
#include <TradeManager/TradeManager.mqh>      // торговая библиотека
#include <Lib CisNewBarDD.mqh>                // для проверки формирования нового бара

input double lot = 1; // лот
input double percent = 0.1; // процент

// структура точек для построения линии
struct pointLine
 {
  int direction;
  int bar;
  double price;
  datetime time;
 };
// объекты классов 
CTradeManager *ctm; 
CisNewBar *isNewBar;
// хэндлы индикаторов
int  handleDE;
int  handlePBI;
// счетчики 
int countTotal = 0; // всего экстремумов
int trend = 0; // текущий тренд 1-й типа
int prevTrend = 0; // предыдущий тренд
double curBid; // текущая цена bid
double curAsk; // текущая цена Ask
double prevBid; // предыдущая цена bid
double priceTrendUp; // цена верхней линии тренда
double priceTrendDown; // цена нижней линии тренда
double H1,H2; // расстояния между экстремумами
double channelH; // ширина канала
double horPrice;
double pbiMove; // значение движение на PBI в текущий момент
// имена событий 
string eventExtrUpName;    // событие прихода верхнего экстремума
string eventExtrDownName;  // собы
string eventMoveChanged;
// массивы и буфера
pointLine extr[4]; // точки для отображения линий
MqlRates rates[]; // буфер котировок
CChartObjectTrend  trendLine; // объект класса трендовой линии
CChartObjectHLine  horLine; // объект класса горизонтальной линии
// структуры позиции и трейлинга
SPositionInfo pos_info;      // структура информации о позиции
STrailing     trailing;      // структура информации о трейлинге

int OnInit()
 {
  isNewBar = new CisNewBar(_Symbol, _Period); 
  // сохраняем имена событий
  eventExtrDownName = "EXTR_DOWN_FORMED_" + _Symbol + "_"   + PeriodToString(_Period);
  eventExtrUpName   = "EXTR_UP_FORMED_"   + _Symbol + "_"   + PeriodToString(_Period); 
  eventMoveChanged  = "MOVE_CHANGED_"     + _Symbol + "_"   + PeriodToString(_Period); 
  ctm = new CTradeManager(); 
   // привязка индикатора DrawExtremums 
  handleDE = DoesIndicatorExist(_Symbol,_Period,"DrawExtremums");
  if (handleDE == INVALID_HANDLE)
  {
   handleDE = iCustom(_Symbol,_Period,"DrawExtremums");
   if (handleDE == INVALID_HANDLE)
   {
    Print("Не удалось создать хэндл индикатора DrawExtremums");
    return (INIT_FAILED);
   }
   SetIndicatorByHandle(_Symbol,_Period,handleDE);
  }    
    
   // привязка индикатора PriceBasedIndicator
  handlePBI = DoesIndicatorExist(_Symbol,_Period,"PriceBasedIndicator");
  if (handlePBI == INVALID_HANDLE)
  {
   handlePBI = iCustom(_Symbol,_Period,"PriceBasedIndicator");
   if (handlePBI == INVALID_HANDLE)
   {
    Print("Не удалось создать хэндл индикатора PriceBasedIndicator");
    return (INIT_FAILED);
   }
   SetIndicatorByHandle(_Symbol,_Period,handlePBI);
  }     
  
  // если удалось прогрузить последние экстремумы
  if (UploadExtremums())
  {
   trend = IsTrendNow();
   if (trend)
   {
    // строим линии 
    DrawLines ();    
   }
  }
  
   // сохраняем цены  
  curBid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
  curAsk = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
  prevBid = curBid;
   // заполняем поля позиции
  pos_info.expiration = 0;
   // заполняем 
  trailing.trailingType = TRAILING_TYPE_NONE;
  trailing.handleForTrailing = 0;     
  return(INIT_SUCCEEDED);
 }

void OnDeinit(const int reason)
  {
   DeleteLines ();
   delete isNewBar;
   delete ctm;
  }
  
void OnTick()
  {     
   ctm.OnTick();
   curBid = SymbolInfoDouble(_Symbol,SYMBOL_BID); 
   curAsk = SymbolInfoDouble(_Symbol,SYMBOL_ASK); 
   // если в текущий момент открыта позиция и тренд противоположный
   if (prevTrend == -trend && ctm.GetPositionCount() > 0)
     { 
      // то закрываем позицию
      ctm.ClosePosition(0);
     }
   // если текущее движение - тренд 1-й типа вверх
   if (trend == 1)
    {
     // если сформировался новый бар
     if (isNewBar.isNewBar() > 0)
      {
       // копируем котировки последних двух баров
       if (CopyRates(_Symbol,_Period,1,2,rates) == 2)
        {
         priceTrendUp = ObjectGetValueByTime(0,"trendUp",TimeCurrent());
         priceTrendDown = ObjectGetValueByTime(0,"trendDown",TimeCurrent());   
         channelH = priceTrendUp - priceTrendDown;   // вычисляю ширину канала   
         // если цена закрытия на последнем баре выше цены открытия (в нашу сторону), а на предыдущем баре - обратная ситуевина
         if ( GreatDoubles(rates[1].close,rates[1].open) && LessDoubles(rates[0].close,rates[0].open) &&  // если последний бар закрылся в нашу сторону, а прошлый - в противоположную
              LessOrEqualDoubles(MathAbs(curBid-priceTrendDown),channelH*0.2)                             // если текущая цена находится возле нижней границы канала тренда 
            )
             {
              pos_info.sl = CountStopLossForTrendLines ();
              pos_info.tp = pos_info.sl*10;
              pos_info.volume = lot;
              pos_info.type = OP_BUY;
              ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);
             }
        }
      }
    }
   // если текущее движение - тренд 1-й типа вниз
   if (trend == -1)
    {
     // если сформировался новый бар
     if (isNewBar.isNewBar() > 0)
      {
       // копируем котировки последних двух баров
       if (CopyRates(_Symbol, _Period, 1, 2, rates) == 2)
        {
         priceTrendUp = ObjectGetValueByTime(0,"trendUp", TimeCurrent());
         priceTrendDown = ObjectGetValueByTime(0,"trendDown", TimeCurrent());   
         channelH = priceTrendUp - priceTrendDown;   // вычисляю ширину канала   
         // если цена закрытия на последнем баре ниже цены открытия (в нашу сторону), а на предыдущем баре - обратная ситуевина
         if ( LessDoubles(rates[1].close,rates[1].open) && GreatDoubles(rates[0].close,rates[0].open) &&  // если последний бар закрылся в нашу сторону, а прошлый - в противоположную
              LessOrEqualDoubles(MathAbs(curBid-priceTrendUp),channelH * 0.2)                             // если текущая цена находится возле нижней границы канала тренда 
            )
             {
              pos_info.sl = CountStopLossForTrendLines ();
              pos_info.tp = pos_info.sl*10;
              pos_info.volume = lot;
              pos_info.type = OP_SELL;
              ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);
             }
        }
      }
    }    
   prevBid = curBid;
   if (trend != 0)
    prevTrend = trend;
  }

// функция обработки внешних событий
void OnChartEvent(const int id,         // идентификатор события  
                  const long& lparam,   // параметр события типа long
                  const double& dparam, // параметр события типа double
                  const string& sparam  // параметр события типа string 
                 )
  {
   double price;
   
   if (sparam == eventExtrDownName)
    {
     price = SymbolInfoDouble(_Symbol,SYMBOL_BID);
     pos_info.type = OP_BUY; 
    }
   if (sparam == eventExtrUpName)
    {
     price = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
     pos_info.type = OP_SELL;
    }
   // пришло событие "сформировался новых экстремум"
   if (sparam == eventExtrDownName || sparam == eventExtrUpName)
    {
     // удаляем линии с графика
     DeleteLines();
     // получаем новые значение экстремумов и смещаем
     UploadExtremums ();

     trend = IsTrendNow();
     if (trend)
      {  
       // перерисовываем линии
       DrawLines ();     
      }
       
    }
   // пришло событие "изменилось движение на PBI"
   if (sparam == eventMoveChanged)
   {
    // если тренд вверх
    if (dparam == 1.0 || dparam == 2.0)
    {
     
    }
    // если тренд вниз
    if (dparam == 3.0 || dparam == 4.0)
    {
     
    }
   }
  } 

// функция закрузки экстремумов на OnInit
bool UploadExtremums ()
 {
  double extrHigh[];
  double extrLow[];
  double extrHighTime[];
  double extrLowTime[];
  int count = 0;           // счетчик экстремумов
  int bars = Bars(_Symbol,_Period);
  for (int ind = 0; ind < bars;)
   {
    if (CopyBuffer(handleDE, 0, ind, 1, extrHigh) < 1 || CopyBuffer(handleDE, 1, ind, 1, extrLow) < 1 ||
        CopyBuffer(handleDE, 4, ind, 1, extrHighTime) < 1 || CopyBuffer(handleDE, 5, ind, 1, extrLowTime) < 1 )
       {
        Sleep(100);
        continue;
       }
    // если найден новый эктсремум high
    if (extrHigh[0] != 0)
     {
      extr[count].price = extrHigh[0];
      extr[count].time = datetime(extrHighTime[0]);
      extr[count].direction = 1;
      extr[count].bar = ind;
      count++;
     }
    // если найдено все 3 экстремума
    if (count == 4)
     return (true);     
    // если найден новый эктсремум low
    if (extrLow[0] != 0)
     {
      extr[count].price = extrLow[0];
      extr[count].time = datetime(extrLowTime[0]);
      extr[count].direction = -1;
      extr[count].bar = ind;
      count++;
     }     
    // если найдено все 4 экстремума
    if (count == 4)
     return (true);
    ind++;
   }
  return(false);
 }
 
// функция смещает экстремумы в массиве
void DragExtremums (int direction,double price,datetime time)
 {
  for (int ind=3;ind>0;ind--)
   {
    extr[ind] = extr[ind-1];
   }
  extr[0].direction = direction;
  extr[0].price = price;
  extr[0].time = time;
 }

// функция удаляет линии с графика
void DeleteLines ()
 {
  ObjectDelete(0,"trendUp");
  ObjectDelete(0,"trendDown");
  ObjectDelete(0,"horLine");
 }
 
// вернет true, если тренд валиден
int  IsTrendNow ()
 {
  double h1,h2;
  
  // вычисляем расстояния h1,h2
  h1 = MathAbs(extr[0].price - extr[2].price);
  h2 = MathAbs(extr[1].price - extr[3].price);
  // если тренд вверх 
  if (GreatDoubles(extr[0].price,extr[2].price) && GreatDoubles(extr[1].price,extr[3].price))
   {
    // если последний экстремум - вниз
    if (extr[0].direction == -1)
     {
      H1 = extr[1].price - extr[2].price;
      H2 = extr[3].price - extr[2].price;
      // если наша трендовая линия нас удовлетворяет
      if (GreatDoubles(h1, H1*percent) && GreatDoubles(h2, H2*percent) )
       return (1);
     }
   }
  // если тренд вниз
  if (LessDoubles(extr[0].price,extr[2].price) && LessDoubles(extr[1].price,extr[3].price))
   {
    // если  последний экстремум - вверх
    if (extr[0].direction == 1)
     {
      H1 = extr[1].price - extr[2].price;
      H2 = extr[3].price - extr[2].price;
      // если наша трендования линия нас удовлетворяет
      if (GreatDoubles(h1,H1*percent) && GreatDoubles(h2,H2*percent) )    
       return (-1);
     }
   }   
  return (0);   
 }
 
// функция вычисляет стоп лосс для трендовых линий
int CountStopLossForTrendLines ()
 {
  // если тренд вверх
  if (trend == 1)
   {
    return (int((MathAbs(curBid-extr[0].price) + H1*percent)/_Point));
   }
  // если тренд вниз
  if (trend == -1)
   {
    return (int((MathAbs(curAsk-extr[0].price) - H1*percent)/_Point));
   }   
  return (0);
 }

// функция вычисляет стоп лосс для PBI
int CountStopLossForPBI ()
 {
  // если тренд вверх
  if (trend == 1)
   {
    return ( int(MathAbs( ((curBid-extr[0].price)/2)/_Point )) );
   }
  // если тренд вниз
  if (trend == -1)
   {
    return (int(MathAbs( ((curAsk-extr[0].price)/2)/_Point )) );   
   }
  return (0);
 }
 
 // функция отрисовывает линии по экстремумам  
void DrawLines ()
 {
    Print ("Рисуем линию");
    // то создаем линии по точкам
    if (extr[0].direction == 1)
     {
      trendLine.Create(0,"trendUp",0,extr[2].time,extr[2].price,extr[0].time,extr[0].price); // верхняя  линия
      ObjectSetInteger(0,"trendUp",OBJPROP_RAY_RIGHT,1);
      trendLine.Create(0,"trendDown",0,extr[3].time,extr[3].price,extr[1].time,extr[1].price); // нижняя  линия
      ObjectSetInteger(0,"trendDown",OBJPROP_RAY_RIGHT,1);   
      if (trend == 1)
      {
       horLine.Create(0,"horLine",0,extr[0].price); // горизонтальная линия    
       horPrice = extr[0].price;    
      } 
      if (trend == -1)
      {
       horLine.Create(0,"horLine",0,extr[1].price); // горизонтальная линия       
       horPrice = extr[1].price;         
      }        
     }
    // то создаем линии по точкам
    if (extr[0].direction == -1)
     {
      trendLine.Create(0,"trendDown", 0, extr[2].time, extr[2].price, extr[0].time, extr[0].price); // нижняя  линия
      ObjectSetInteger(0,"trendDown", OBJPROP_RAY_RIGHT, 1);
      trendLine.Create(0,"trendUp", 0, extr[3].time, extr[3].price, extr[1].time, extr[1].price); // верхняя  линия
      ObjectSetInteger(0,"trendUp", OBJPROP_RAY_RIGHT, 1);   
      if (trend == 1)
       {
        horLine.Create(0,"horLine", 0, extr[1].price); // горизонтальная линия     
        horPrice = extr[1].price;           
       } 
      if (trend == -1)
       {
        horLine.Create(0,"horLine", 0, extr[0].price); // горизонтальная линия      
        horPrice = extr[0].price;          
       }          
     }   
 }