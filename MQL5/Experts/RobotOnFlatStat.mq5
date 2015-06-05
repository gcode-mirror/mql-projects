//+------------------------------------------------------------------+
//|                                        TesterOfMoveContainer.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

// РОБОТ ОСНОВАННЫЙ НА СТАТИСТИКЕ

#include <DrawExtremums/CExtrContainer.mqh> // контейнер экстремумов
#include <DrawExtremums/CExtremum.mqh> // объект экстремумов
#include <SystemLib/IndicatorManager.mqh> // библиотека по работе с индикаторами
#include <ChartObjects/ChartObjectsLines.mqh> // для рисования линий тренда
#include <TradeManager/TradeManager.mqh> // торговая библиотека

input double percent = 0.1; // процент рассчета тренда
input double volume = 1.0; // лот
// объекты классов
CExtrContainer *extr_container;
CTradeManager *ctm;
bool firstUploadedExtr = false;
int handleDE;
string cameHighEvent;  // имя события прихода верхнего экстремума
string cameLowEvent;   // имя события прихода нижнего экстремума
// переменные канала
double h; // ширина канала флэта
double bottom_price; // цена нижней границы канала
double top_price; // цена верхней границы канала
// экстремумы движений
CExtremum trend_high0,trend_high1; 
CExtremum trend_low0,trend_low1;

CExtremum flat_high0,flat_high1;
CExtremum flat_low0,flat_low1;

// объекты отображения канала флэтов
CChartObjectTrend flatLine;    // объект класса флэтовой линии
CChartObjectTrend trendLine;   // объект класса трендовой линии
// параметры позиции
SPositionInfo pos_info;
STrailing trailing;
int mode = 0;  // 0 - режим поиска ситуации, 1 - режим ожидания пробития
int flat = 0; // тип флэта
int trend = 0; // тип тренда

int OnInit()
  {  
   // если 
   
   // создаем объект торгового класса
   ctm = new CTradeManager ();
   // сохраняем имена событий
   cameHighEvent = GenUniqEventName("EXTR_UP_FORMED");
   cameLowEvent  = GenUniqEventName("EXTR_DOWN_FORMED");
   // привязка индикатора DrawExtremums
   handleDE = DoesIndicatorExist(_Symbol, _Period, "DrawExtremums");
   if (handleDE == INVALID_HANDLE)
    {
     handleDE = iCustom(_Symbol, _Period, "DrawExtremums");
     if (handleDE == INVALID_HANDLE)
      {
       Print("Не удалось создать хэндл индикатора DrawExtremums");
       return (INIT_FAILED);
      }
     SetIndicatorByHandle(_Symbol, _Period, handleDE);
    }  
   extr_container = new CExtrContainer(handleDE,_Symbol,_Period);
   
   pos_info.volume = volume;
   pos_info.expiration = 0;
 
   trailing.trailingType = TRAILING_TYPE_NONE;
   trailing.handleForTrailing = 0;   
   
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   // удаляем объекты из памяти
   delete extr_container;
   delete ctm;
  }

void OnTick()
  {
    ctm.OnTick();
    if (!firstUploadedExtr)
    {
     firstUploadedExtr = extr_container.Upload();
    }    
   if (!firstUploadedExtr)
    return;    
   // если есть режим mode = 1
   if (mode == 1)
    {
     // если позиция закрылась (очевидно по стопу или тейку)
     if (ctm.GetPositionCount() == 0)
      mode = 0;
     
     /*
     // если сейчас тренд и он противоположен предыдущему
     if ( IsItTrend(extr_container.GetFormedExtrByIndex(0,EXTR_HIGH),extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),
                    extr_container.GetFormedExtrByIndex(0,EXTR_LOW),extr_container.GetFormedExtrByIndex(1,EXTR_LOW) ) == -trend)
                    {
                     // то закрываем позицию
                     ctm.ClosePosition(0);
                     mode = 0;
                    }
     */
    }
  }
  
// функция обработки внешних событий
void OnChartEvent(const int id,         // идентификатор события  
                  const long& lparam,   // параметр события типа long
                  const double& dparam, // параметр события типа double
                  const string& sparam  // параметр события типа string 
                 )
  {
    // обновляем контейнер экстремумов
    extr_container.UploadOnEvent(sparam,dparam,lparam);
    // если пришло событие, что сформировался верхний экстремум
    if (sparam == cameHighEvent)
     {
      // если сейчас режим 0, то ищем флэт
      if (mode == 0)
       {
        // если сейчас флэт 
        if (flat = GetFlatMove(extr_container.GetFormedExtrByIndex(0,EXTR_HIGH),extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),
                     extr_container.GetFormedExtrByIndex(0,EXTR_LOW),extr_container.GetFormedExtrByIndex(1,EXTR_LOW) ) )
                    {
                     // проверяем, что предыдущее движение не является трендом
                     if (!IsItTrend(extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),extr_container.GetFormedExtrByIndex(2,EXTR_HIGH),
                         extr_container.GetFormedExtrByIndex(0,EXTR_LOW),extr_container.GetFormedExtrByIndex(1,EXTR_LOW) ) )
                         {
                          // проверяем, что пред предыщушиее движение - тренд
                          if (trend = IsItTrend(extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),extr_container.GetFormedExtrByIndex(2,EXTR_HIGH),
                                         extr_container.GetFormedExtrByIndex(1,EXTR_LOW),extr_container.GetFormedExtrByIndex(2,EXTR_LOW) ) )
                                         {
                                           // вычисляем параметры канала
                                           CountFlatChannel();       
                                           // пытаемся открыть позицию     
                                           if ( PositionOpen(flat,trend,1) )
                                            {
                                             DrawChannel ();                                
                                             mode = 1;
                                            }
                                         }
                         }
                    }
                    
       } // END OF MODE
     } // END OF SPARAM
    // если пришло событие, что сформировался нижний экстремум
    if (sparam == cameLowEvent)
     {
      // если сейчас режим 0, то ищем флэт
      if (mode == 0)
       {
        // если сейчас флэт 
        if (flat =  GetFlatMove(extr_container.GetFormedExtrByIndex(0,EXTR_HIGH),extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),
                     extr_container.GetFormedExtrByIndex(0,EXTR_LOW),extr_container.GetFormedExtrByIndex(1,EXTR_LOW) ) )
                    {
                     // проверяем, что предыдущее движение не является трендом
                     if (!IsItTrend(extr_container.GetFormedExtrByIndex(0,EXTR_HIGH),extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),
                         extr_container.GetFormedExtrByIndex(1,EXTR_LOW),extr_container.GetFormedExtrByIndex(2,EXTR_LOW) ) )
                         {
                          // проверяем, что пред предыщушиее движение - тренд
                          if (trend = IsItTrend(extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),extr_container.GetFormedExtrByIndex(2,EXTR_HIGH),
                                         extr_container.GetFormedExtrByIndex(1,EXTR_LOW),extr_container.GetFormedExtrByIndex(2,EXTR_LOW) ) )
                                         {
                                           // вычисляем параметры канала
                                           CountFlatChannel();      
                                           // пытаемся открыть позицию
                                           if ( PositionOpen(flat,trend,-1) )
                                            {
                                             DrawChannel ();
                                             mode = 1;
                                            }
                                         }
                         }
                    }
                    
       } // END OF MODE
     } // END OF SPARAM     
  }
  
 // функция вычисляет параметры канала флэта
 void CountFlatChannel ()
  {
   h = MathMax(extr_container.GetFormedExtrByIndex(0,EXTR_HIGH).price,extr_container.GetFormedExtrByIndex(1,EXTR_HIGH).price) -
       MathMin(extr_container.GetFormedExtrByIndex(0,EXTR_LOW).price,extr_container.GetFormedExtrByIndex(1,EXTR_LOW).price);
   top_price = extr_container.GetFormedExtrByIndex(0,EXTR_HIGH).price + 0.75*h;
   bottom_price = extr_container.GetFormedExtrByIndex(0,EXTR_LOW).price - 0.75*h;
  } 
  
  
 // дополнительные функции
 void  DrawChannel ()  // создает линии флэта
  {
   DeleteAllLines ();
   flatLine.Create(0, "flatUp", 0, extr_container.GetFormedExtrByIndex(0,EXTR_HIGH).time, extr_container.GetFormedExtrByIndex(0,EXTR_HIGH).price, 
                                   extr_container.GetFormedExtrByIndex(1,EXTR_HIGH).time, extr_container.GetFormedExtrByIndex(1,EXTR_HIGH).price); // верхняя линия  
   
   flatLine.Color(clrYellow);
   flatLine.Width(2);
   flatLine.Create(0, "flatDown", 0, extr_container.GetFormedExtrByIndex(0,EXTR_LOW).time, extr_container.GetFormedExtrByIndex(0,EXTR_LOW).price, 
                                     extr_container.GetFormedExtrByIndex(1,EXTR_LOW).time, extr_container.GetFormedExtrByIndex(1,EXTR_LOW).price); // нижняя линия  
   flatLine.Color(clrYellow);
   flatLine.Width(2);
   
   
   trendLine.Create(0, "trendUp", 0, extr_container.GetFormedExtrByIndex(1,EXTR_HIGH).time, extr_container.GetFormedExtrByIndex(1,EXTR_HIGH).price, 
                                   extr_container.GetFormedExtrByIndex(2,EXTR_HIGH).time, extr_container.GetFormedExtrByIndex(2,EXTR_HIGH).price); // верхняя линия  
   
   trendLine.Color(clrLightBlue);
   trendLine.Width(2);
   trendLine.Create(0, "trendDown", 0, extr_container.GetFormedExtrByIndex(1,EXTR_LOW).time, extr_container.GetFormedExtrByIndex(1,EXTR_LOW).price, 
                                     extr_container.GetFormedExtrByIndex(2,EXTR_LOW).time, extr_container.GetFormedExtrByIndex(2,EXTR_LOW).price); // нижняя линия  
   trendLine.Color(clrLightBlue);
   trendLine.Width(2);   
   
  }
  
 // функция удаляет линии с графика
 void DeleteAllLines ()
  {
   ObjectDelete(0,"flatUp");
   ObjectDelete(0,"flatDown");
   ObjectDelete(0,"trendUp");
   ObjectDelete(0,"trendDown");
  }

// вычисляет движение 
int GetFlatMove (CExtremum *high0,CExtremum *high1,CExtremum *low0, CExtremum *low1)
 {
  double height = MathMax(high0.price,high1.price) - MathMin(low0.price,low1.price);
   
  if ( LessOrEqualDoubles (MathAbs(high1.price-high0.price),percent*height) &&
       LessOrEqualDoubles (MathAbs(low0.price - low1.price),percent*height)
     )
     {
      return (1); // флэт C
     }

  /*
  
  if ( GreatOrEqualDoubles (high1.price - high0.price,percent*height) &&
       GreatOrEqualDoubles (low0.price - low1.price,percent*height)
     )
     {
      return (2); // флэт D
     }
  if ( GreatOrEqualDoubles (high0.price-high1.price,percent*height) &&
       GreatOrEqualDoubles (low1.price - low0.price,percent*height)
     )
     {
      return (3); // флэт E
     }

  if ( LessOrEqualDoubles (MathAbs(high1.price-high0.price), percent*height) &&
       GreatOrEqualDoubles (low1.price -low0.price , percent*height)
     )
     {
      return (4); // флэт F
     }
  
  */
  
  return (0);
 }  
     
int IsItTrend(CExtremum *high0,CExtremum *high1,CExtremum *low0, CExtremum *low1) // проверяет, является ли данный канал трендовым
 {
  double h1,h2;
  double H1,H2;
  // если тренд вверх 
  if ( GreatDoubles(high0.price,high1.price) && GreatDoubles(low0.price,low1.price))
   {
    // если последний экстремум - вниз
    if (low0.time > high0.time)
     {
      H1 = high0.price - low1.price;
      H2 = high1.price - low1.price;
      h1 = MathAbs(low0.price - low1.price);
      h2 = MathAbs(high0.price - high1.price);
      // если наша трендовая линия нас удовлетворяет
      if (GreatDoubles(h1,H1*percent) && GreatDoubles(h2,H2*percent) )
       return (1);
     }
    // если последний экстремум - вверх
    if (low0.time < high0.time)
     {
      H1 = high1.price - low0.price;
      H2 = high1.price - low1.price;
      h1 = MathAbs(low0.price - low1.price);
      h2 = MathAbs(high0.price - high1.price);
      // если наша трендовая линия нас удовлетворяет
      if (GreatDoubles(h1,H1*percent) && GreatDoubles(h2,H2*percent) )
       return (1);
     }
      
   }
  // если тренд вниз
  if ( LessDoubles(high0.price,high1.price) && LessDoubles(low0.price,low1.price))
   {
    
    // если  последний экстремум - вверх
    if (high0.time > low0.time)
     {
      H1 = high1.price - low0.price;    
      H2 = high1.price - low1.price;
      h1 = MathAbs(high0.price - high1.price);
      h2 = MathAbs(low0.price - low1.price);
      // если наша трендования линия нас удовлетворяет
      if (GreatDoubles(h1,H1*percent) && GreatDoubles(h2,H2*percent) )    
       return (-1);
     }
    // если последний экстремум - вниз
    else if (high0.time < low0.time)
     {
      H1 = high0.price - low1.price;    
      H2 = high1.price - low1.price;
      h1 = MathAbs(high0.price - high1.price);
      h2 = MathAbs(low0.price - low1.price);
      // если наша трендования линия нас удовлетворяет
      if (GreatDoubles(h2,H1*percent) && GreatDoubles(h1,H2*percent) )    
       return (-1);
     }
     
   }   
   
  return (0);
 } 
 
// генерирует имя события 
string  GenUniqEventName(string eventName)
 {
  return (eventName + "_" + _Symbol + "_" + PeriodToString(_Period));
 }
 
// функция открывает позицию
bool PositionOpen (int flat,int trend,int extr)
 { 
   // если флэт C, тренд вверх и последний экстремум - нижний
   if (flat == 1 && trend == 1 && extr == -1)
    {
     pos_info.type = OP_BUY;
     pos_info.sl = int ( MathAbs ( (SymbolInfoDouble(_Symbol,SYMBOL_ASK) - bottom_price) /_Point)  );
     pos_info.tp = int ( MathAbs ( (SymbolInfoDouble(_Symbol,SYMBOL_ASK) - top_price)/_Point)  );
     pos_info.priceDifference = 0;
     pos_info.expiration = 0;
     trailing.minProfit = 0;                                         
     ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);  
     return (true);   
    }
    
   /* 
    
   // если флэт D, тренд вверх и последний экстремум - нижний
   if (flat == 2 && trend == 1 && extr == -1)
    {
     pos_info.type = OP_BUY;
     pos_info.sl = int (  MathAbs ( (SymbolInfoDouble(_Symbol,SYMBOL_ASK) - bottom_price) /_Point)  );
     pos_info.tp = int ( MathAbs ( (SymbolInfoDouble(_Symbol,SYMBOL_ASK) - top_price)/_Point)  );
     pos_info.priceDifference = 0;
     pos_info.expiration = 0;
     trailing.minProfit = 0;                                         
     ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);   
     return (true);  
    }
        
   // если флэт E, тренд вверх и последний экстремум - нижний
   if (flat == 3 && trend == 1 && extr == 1)
    {
     pos_info.type = OP_BUY;
     pos_info.sl = int (  MathAbs ( (SymbolInfoDouble(_Symbol,SYMBOL_ASK) - bottom_price) /_Point)  );
     pos_info.tp = int ( MathAbs ( (SymbolInfoDouble(_Symbol,SYMBOL_ASK) - top_price)/_Point)  );
     pos_info.priceDifference = 0;
     pos_info.expiration = 0;
     trailing.minProfit = 0;                                         
     ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);     
     return (true);
    } 
   // если флэт F, тренд вверх и последний экстремум - нижний
   if (flat == 4 && trend == 1 && extr == -1)
    {
     pos_info.type = OP_SELL;
     pos_info.sl = int (  MathAbs ( (SymbolInfoDouble(_Symbol,SYMBOL_ASK) - top_price) /_Point)  );
     pos_info.tp = int ( MathAbs ( (SymbolInfoDouble(_Symbol,SYMBOL_ASK) - bottom_price)/_Point)  );
     pos_info.priceDifference = 0;
     pos_info.expiration = 0;
     trailing.minProfit = 0;                                         
     ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);   
     return (true);  
    }   
     
   */
       
  return (false);    
 }