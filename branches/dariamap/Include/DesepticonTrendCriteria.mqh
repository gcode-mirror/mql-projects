//+------------------------------------------------------------------+
//|                                      DesepticonTrendCriteria.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
#include <CompareDoubles.mqh>
#include <SearchExtremum.mqh>
#define DEPTH 200                                   //глубина поиска для InitTrendDirection и SearchForTits

int InitTrendDirection (int handleMACD, int handleFastEMA, int handleSlowEMA, int deltaEMA, double channel_MACD)
{
 //Print("Инитим InitTrendDirection");
 int i = 0;                                                 
 double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
 
 double iMACD_buf[DEPTH] = {0};                       //инициализация буферных массивов
 double iMA_fast_buf[DEPTH] = {0};                    //
 double iMA_slow_buf[DEPTH] = {0};                    //
 
 ArraySetAsSeries(iMACD_buf, false);        //индексация в массивах как в таймсериях
 ArraySetAsSeries(iMA_fast_buf, false);     //настоящий момент времени = 0 элемент
 ArraySetAsSeries(iMA_slow_buf, false);     //
 
 if (handleMACD == INVALID_HANDLE || handleFastEMA == INVALID_HANDLE || handleSlowEMA == INVALID_HANDLE )
 {
  Alert(__FUNCTION__, "INVALID_HANDLE");
 }
 else
 {
  //Print(__FUNCTION__, "hMACD = ", handleMACD, "; hF_EMA = ", handleFastEMA, "; hS_EMA = ", handleSlowEMA);
 }
 
 //Print("Копируем буферы InitTrendDirection");
 //Print("Begin sleep");
 Sleep(10000);                                          //Нужен для того что бы индикаторы успели посчитаться
 //Print("End sleep");
 int sizeMACD, sizeF_EMA, sizeS_EMA, ERROR;
 sizeMACD = CopyBuffer(handleMACD, 0, 0, DEPTH, iMACD_buf);           //заполнение буферных массивов
 sizeF_EMA = CopyBuffer(handleFastEMA, 0, 0, DEPTH, iMA_fast_buf);    //
 sizeS_EMA = CopyBuffer(handleSlowEMA, 0, 0, DEPTH, iMA_slow_buf);    //
 //Alert (__FUNCTION__, "sizeMACD = ", sizeMACD, "; sizeF_EMA = ", sizeF_EMA, "; sizeS_EMA = ", sizeS_EMA, "; depth = ", DEPTH);
 if (sizeMACD < 0 || sizeF_EMA < 0 || sizeS_EMA < 0)
 {
  ERROR = GetLastError ();
  ResetLastError();
  Print (__FUNCTION__, "Не удалось скопировать данные в индикаторный буффер(MACD || EMA). ERROR = .", ERROR);
  return (0);
 }
 
 while (i < DEPTH)
 {
  //Alert("BEGIN OF WHILE");
  while ((i < sizeMACD) && GreatDoubles(channel_MACD, MathAbs (iMACD_buf[i]))) 
  {                                                             //пропускаем все моменты когда изменения проходят внутри channel_MACD
   i++;                                                      
  }
//  Alert("Пропустил все неинтересные нам значения. i = ", i , "  из ", depth);
  if ((i < sizeF_EMA) && (i < sizeS_EMA))
  {
   if (LessDoubles(iMA_fast_buf[i], (iMA_slow_buf[i] - deltaEMA*point))) 
   {                                                           //быстрая EMA ниже медленной EMA => нисходящий тренд
    //Alert ("DOWN, i = ", i, " (", depth, ") ; EMAfast = ", iMA_fast_buf[i], "; EMAslow = ", iMA_slow_buf[i]);
    return(-1);
   }
   else if (GreatDoubles(iMA_fast_buf[i], iMA_slow_buf[i] + deltaEMA*point)) 
        {                                                           //медленная EMA ниже быстрой EMA => восходящий тренд
         //Alert ("UP, i = ", i, " (", depth, ") ; EMAfast = ", iMA_fast_buf[i], "; EMAslow = ", iMA_slow_buf[i]);
         return(1);
        }
   i++;
  }
 }
 if (i >= DEPTH)
  Alert(__FUNCTION__, "ВНИМАНИЕ!!! Задан слишком широкий коридор MACD, начальное направление тренда не определено! Возможна некорректная работа эксперта!");
 
 return(0);
}

bool searchForTits(int handleMACD, double channel_MACD, bool bothTits)
{
 int i = 0;
 int extremum = 0;
 bool isMax = false;
 bool isMin = false;
 int sizeMACD = 0;
 double iMACD_buf[DEPTH];
 ArraySetAsSeries(iMACD_buf, true);
 sizeMACD = CopyBuffer(handleMACD, 0, 0, DEPTH, iMACD_buf);
 if (sizeMACD < 0)
 {
  Alert (__FUNCTION__, "Не удалось загрузить буфер индикатора MACD");
  return(false);
 }
 
 while ((i < sizeMACD) && LessDoubles(MathAbs(iMACD_buf[i]), channel_MACD))    
 {
  extremum = isMACDExtremum(handleMACD, i);
  if (extremum != 0)
  {
   if (extremum < 0)
   {
    //Alert (" Найден минимум ", i, " баров назад" );
    isMin = true;
   }
   else if (extremum > 0)
        {
         //Alert (" Найден максимум ", i, " баров назад" );
         isMax = true;
        } 
        
   if (isMin && isMax) break;
  }
  i++;
 }
 
 if (bothTits) // если нужны обе титьки для флэта
  return (isMin && isMax); // возвращаем тру только если обе титьки найдены
 else 
  return (isMin || isMax); // возвращаем тру если найдена хотя бы одна
}

int TwoTitsCriteria (int handleMACD, int handleFastEMA, int handleSlowEMA, int deltaEMA, double channel_MACD, int currentTrend, int historyTrend)
{                                               
 double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
 
 double iMACD_buf[1];                       //инициализация буферных массивов
 double iMA_fast_buf[1];                    //
 double iMA_slow_buf[1];                    //
 
 ArraySetAsSeries(iMACD_buf, true);        //индексация в массивах как в таймсериях
 ArraySetAsSeries(iMA_fast_buf, true);     //настоящий момент времени = 0 элемент
 ArraySetAsSeries(iMA_slow_buf, true);     //
 
 int sizeMACD, sizeF_EMA, sizeS_EMA;
 sizeMACD = CopyBuffer(handleMACD, 0, 1, 1, iMACD_buf);           //заполнение буферных массивов
 sizeF_EMA = CopyBuffer(handleFastEMA, 0, 1, 1, iMA_fast_buf);    //
 sizeS_EMA = CopyBuffer(handleSlowEMA, 0, 1, 1, iMA_slow_buf);    //
// Alert ("sizeMACD = ", sizeMACD, "; sizeF_EMA = ", sizeF_EMA, "; sizeS_EMA = ", sizeS_EMA);
 if (sizeMACD < 0 || sizeF_EMA < 0 || sizeS_EMA < 0)
 {
  Print (__FUNCTION__, "Не удалось скопировать данные в индикаторный буффер(MACD || EMA). Возможно проблемы с параметром depth.");
  return (0);
 }
 
 if (LessDoubles(MathAbs(iMACD_buf[0]), channel_MACD))
 {
  if (searchForTits(handleMACD, channel_MACD, true))
  {
   return(0);
  }
  return (currentTrend);
 }
  
 if (LessDoubles(iMA_fast_buf[0], iMA_slow_buf[0] - deltaEMA*point)) 
 {                                                           //быстрая EMA ниже медленной EMA => нисходящий тренд
  //Alert ("DOWN, i = ", i, " (", depth, ") ; EMAfast = ", iMA_fast_buf[i], "; EMAslow = ", iMA_slow_buf[i]);
  return(-1);
 }
 else if (GreatDoubles(iMA_fast_buf[0], iMA_slow_buf[0] + deltaEMA*point)) 
      {                                                           //медленная EMA ниже быстрой EMA => восходящий тренд
       //Alert ("UP, i = ", i, " (", depth, ") ; EMAfast = ", iMA_fast_buf[i], "; EMAslow = ", iMA_slow_buf[i]);
       return(1);
      }
      else
      {
       return(historyTrend);
      }

 return(0);
}