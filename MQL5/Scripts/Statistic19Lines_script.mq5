//+------------------------------------------------------------------+
//|                                             Statistic19Lines.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs

#include <CExtremumCalc.mqh>
#include <Lib CisNewBar.mqh>

input datetime start_time = D'2014.03.10';
input datetime end_time =   D'2014.03.20';

 enum LevelType
 {
  EXTR_MN, 
  EXTR_W1,
  EXTR_D1,
  EXTR_H4,
  EXTR_H1
 };
 
 input int epsilon = 25;          //Погрешность для поиска экстремумов
 input int depth = 25;            //Глубина поиска трех экстремумов
 input int period_ATR = 100;      //Период ATR
 input double percent_ATR = 0.03; //Ширина канала уровня в процентах от ATR 

 input LevelType level  = EXTR_H4;
 CExtremumCalc calc(epsilon, depth);
 SExtremum estruct[3];
 
 string symbol = Symbol();
 ENUM_TIMEFRAMES period_current = Period();
 ENUM_TIMEFRAMES period_level;
 int handle_ATR;
 double buffer_ATR [];
 
 bool level_one_UD   = false;
 bool level_one_DU   = false;
 bool level_two_UD   = false;
 bool level_two_DU   = false;
 bool level_three_UD = false;
 bool level_three_DU = false;
 
 double count_DUU = 0;
 double count_DUD = 0;
 double count_UDD = 0;
 double count_UDU = 0;
 
 
 MqlRates buffer_rates[];
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
 PrintFormat("BEGIN");
 period_level = GetTFbyLevel(level);
 handle_ATR = iATR(symbol, period_level, period_ATR);
 int copied = CopyRates(symbol, period_current, start_time, end_time, buffer_rates);
 FillATRbuffer();
 datetime start_pos_time = start_time;
 int factor = PeriodSeconds(period_level)/PeriodSeconds();
 for(int i = 0; i < copied-1;i++)
 {  
  if(MathMod(i, factor) == 0)  //симуляция появления нового бара на тайфреме для которого вычисленны уровни
  {
   FillThreeExtr(symbol, period_level, calc, estruct, buffer_ATR, start_pos_time);
   //PrintFormat("%s one = %f; two = %f; three = %f", TimeToString(start_pos_time), estruct[0].price, estruct[1].price, estruct[2].price);
   start_pos_time += PeriodSeconds(period_level);
   //PrintFormat("%s DUU = %.0f; DUD = %.0f; UDU = %.0f; UDD = %.0f", __FUNCTION__, count_DUU, count_DUD, count_UDU, count_UDD);
  }
  CalcStatistic(buffer_rates[i]);
 }
 
 //PrintFormat("%s END start time = %s; end time = %s; copied = %d", __FUNCTION__, TimeToString(start_time), TimeToString(end_time), copied);
 PrintFormat("%s END DUU = %.0f; DUD = %.0f; UDU = %.0f; UDD = %.0f", __FUNCTION__, count_DUU, count_DUD, count_UDU, count_UDD);
}
//+------------------------------------------------------------------+
void FillThreeExtr (string symbol, ENUM_TIMEFRAMES tf, CExtremumCalc &extrcalc, SExtremum &resArray[], double &buffer_ATR[], datetime start_pos_time)
{
 extrcalc.FillExtremumsArray(symbol, tf, start_pos_time);
 if (extrcalc.NumberOfExtr() < 3)
 {
  Alert(__FUNCTION__, "Не удалось рассчитать три экстремума на таймфрейме ", EnumToString((ENUM_TIMEFRAMES)tf));
  return;
 }
  
 int count = 0;
 for(int i = 0; i < depth && count < 3; i++)
 {
  if(extrcalc.getExtr(i).price > 0)
  {
   resArray[count] = extrcalc.getExtr(i);
   resArray[count].channel = (buffer_ATR[i]*percent_ATR)/2;
   count++;
  }
 }
}

bool FillATRbuffer()
{
 if(handle_ATR != INVALID_HANDLE)
 {
  int copiedATR = CopyBuffer(handle_ATR, 0, 1, depth, buffer_ATR); 
   
  if (copiedATR != depth) 
  {
   Print(__FUNCTION__, "Не удалось полностью скопировать буффер ATR. Error = ", GetLastError());
   if(GetLastError() == 4401) 
    Print(__FUNCTION__, "Подождите некоторое время или подгрузите историю вручную.");
     return false;
  }
  return true;
 }
 return false;
}
  
ENUM_TIMEFRAMES GetTFbyLevel(LevelType lt)
{
 ENUM_TIMEFRAMES result = Period();
 if(lt == EXTR_MN) result = PERIOD_MN1;
 if(lt == EXTR_W1) result = PERIOD_W1;
 if(lt == EXTR_D1) result = PERIOD_D1;
 if(lt == EXTR_H4) result = PERIOD_H4;
 if(lt == EXTR_H1) result = PERIOD_H4;
 
 return(result);
}


void CalcStatistic (MqlRates &price)
{
 bool print = false;
//---------------ПЕРВЫЙ-УРОВЕНЬ------------------------------------
//проверка первого уровня на прохождение ценой снизу вверх DOWN-UP 
 if(!level_one_DU && price.open < estruct[0].price - estruct[0].channel && price.close > estruct[0].price - estruct[0].channel)
 {
  level_one_DU = true;
  if(print)PrintFormat("DU НОВОЕ Цена зашла в коридор уровня снизу вверх");
 }
 if(level_one_DU)
 {
  if(price.open < estruct[0].price + estruct[0].channel && price.close > estruct[0].price + estruct[0].channel)
  {
   count_DUU++;
   level_one_DU = false;
   if(print)PrintFormat("DU Цена вышла из коридора уровня сверху");
  }
  else if(price.open > estruct[0].price - estruct[0].channel && price.close < estruct[0].price - estruct[0].channel)
  {
   count_DUD++;
   level_one_DU = false;
   if(print)PrintFormat("DU Цена вышла из коридора уровня снизу");
  }
 }
 
//проверка первого уровня на прохождение ценой сверху вниз UP-DOWN 
 if(!level_one_UD && price.open > estruct[0].price + estruct[0].channel && price.close < estruct[0].price + estruct[0].channel)
 {
  level_one_UD = true;
  if(print)PrintFormat("UD НОВОЕ Цена зашла в коридор уровня сверху вниз");
 }
 if(level_one_UD)
 {
  if(price.open < estruct[0].price + estruct[0].channel && price.close > estruct[0].price + estruct[0].channel)
  {
   count_UDU++;
   level_one_UD = false;
   if(print)PrintFormat("UD Цена вышла из коридора уровня сверху");
  }
  else if(price.open > estruct[0].price - estruct[0].channel && price.close < estruct[0].price - estruct[0].channel)
  {
   count_UDD++;
   level_one_UD = false;
   if(print)PrintFormat("UD Цена вышла из коридора уровня снизу");
  } 
 }

//---------------ВТОРОЙ-УРОВЕНЬ------------------------------------
//проверка второго уровня на прохождение ценой снизу вверх DOWN-UP 
 if(!level_two_DU && price.open < estruct[1].price - estruct[1].channel && price.close > estruct[1].price - estruct[1].channel)
 {
  level_two_DU = true;
  if(print)PrintFormat("DU НОВОЕ Цена зашла в коридор уровня снизу вверх");
 }
 if(level_two_DU)
 {
  if(price.open < estruct[1].price + estruct[1].channel && price.close > estruct[1].price + estruct[1].channel)
  {
   count_DUU++;
   level_two_DU = false;
   if(print)PrintFormat("DU Цена вышла из коридора уровня сверху");
  }
  else if(price.open > estruct[1].price - estruct[1].channel && price.close < estruct[1].price - estruct[1].channel)
  {
   count_DUD++;
   level_two_DU = false;
   if(print)PrintFormat("DU Цена вышла из коридора уровня снизу");
  }
 }
 
//проверка первого уровня на прохождение ценой сверху вниз UP-DOWN 
 if(!level_two_UD && price.open > estruct[1].price + estruct[1].channel && price.close < estruct[1].price + estruct[1].channel)
 {
  level_two_UD = true;
  if(print)PrintFormat("UD НОВОЕ Цена зашла в коридор уровня сверху вниз");
 }
 if(level_two_UD)
 {
  if(price.open < estruct[1].price + estruct[1].channel && price.close > estruct[1].price + estruct[1].channel)
  {
   count_UDU++;
   level_two_UD = false;
   if(print)PrintFormat("UD Цена вышла из коридора уровня сверху");
  }
  else if(price.open > estruct[1].price - estruct[1].channel && price.close < estruct[1].price - estruct[1].channel)
  {
   count_UDD++;
   level_two_UD = false;
   if(print)PrintFormat("UD Цена вышла из коридора уровня снизу");
  } 
 }

//---------------ТРЕТИЙ-УРОВЕНЬ------------------------------------
//проверка третьего уровня на прохождение ценой снизу вверх DOWN-UP 
 if(!level_three_DU && price.open < estruct[2].price - estruct[2].channel && price.close > estruct[2].price - estruct[2].channel)
 {
  level_three_DU = true;
  if(print)PrintFormat("DU НОВОЕ Цена зашла в коридор уровня снизу вверх");
 }
 if(level_three_DU)
 {
  if(price.open < estruct[2].price + estruct[2].channel && price.close > estruct[2].price + estruct[2].channel)
  {
   count_DUU++;
   level_three_DU = false;
   if(print)PrintFormat("DU Цена вышла из коридора уровня сверху");
  }
  else if(price.open > estruct[2].price - estruct[2].channel && price.close < estruct[2].price - estruct[2].channel)
  {
   count_DUD++;
   level_three_DU = false;
   if(print)PrintFormat("DU Цена вышла из коридора уровня снизу");
  }
 }
 
//проверка первого уровня на прохождение ценой сверху вниз UP-DOWN 
 if(!level_three_UD && price.open > estruct[2].price + estruct[2].channel && price.close < estruct[2].price + estruct[2].channel)
 {
  level_three_UD = true;
  if(print)PrintFormat("UD НОВОЕ Цена зашла в коридор уровня сверху вниз");
 }
 if(level_three_UD)
 {
  if(price.open < estruct[2].price + estruct[2].channel && price.close > estruct[2].price + estruct[2].channel)
  {
   count_UDU++;
   level_three_UD = false;
   if(print)PrintFormat("UD Цена вышла из коридора уровня сверху");
  }
  else if(price.open > estruct[2].price - estruct[2].channel && price.close < estruct[2].price - estruct[2].channel)
  {
   count_UDD++;
   level_three_UD = false;
   if(print)PrintFormat("UD Цена вышла из коридора уровня снизу");
  } 
 }
}

void SavePorabolistic(string filename)
{
 int file_handle = FileOpen(filename, FILE_WRITE|FILE_ANSI|FILE_TXT|FILE_COMMON);
 if (file_handle == INVALID_HANDLE) //не удалось открыть файл
 {
  Alert("Ошибка открытия файла");
  return;
 }
 
 FileWriteString(file_handle, StringFormat("%s %s %s %s\r\n", __FILE__, EnumToString(Period()), Symbol(), TimeToString(TimeCurrent())));
 FileWriteString(file_handle, StringFormat("Parametrs: level = %s\r\n", EnumToString((ENUM_TIMEFRAMES)GetTFbyLevel(level))));
 //FileWriteString(file_handle, StringFormat("    TOP TF: percentage ATR = %.03f, ATR ma period = %d, dif to trend = %.03f\r\n", percentage_ATR_top, ATR_ma_period_top, difToTrend_top));
 FileWriteString(file_handle, "Возможные ситуации как цена проходит через уровень: \r\n");
 FileWriteString(file_handle, StringFormat("Цена идет снизу вверх, а после:вверх = %f, вниз = %f \r\n", count_DUU, count_DUD));
 FileWriteString(file_handle, StringFormat("Цена идет сверху вниз, а после:вверх = %f, вниз = %f \r\n", count_UDU, count_UDD));
 FileWriteString(file_handle, "Процентное соотношение ситуация когда цена продолжает идти в том же направлении после прохождения уровня:\r\n");
 FileWriteString(file_handle, StringFormat("Если идет снизву вверх %.02f % и сверху вниз %.02f \r\n", 100*(count_DUU)/(count_DUU + count_UDD), 100*(count_UDD)/(count_DUU + count_UDD)));
 FileWriteString(file_handle, "Процентное соотношение ситуация когда цена продолжает идти в противоположном направлении после прохождения уровня:\r\n");
 FileWriteString(file_handle, StringFormat("Если идет снизву вверх %.02f % и сверху вниз %.02f \r\n", 100*(count_DUD)/(count_DUD + count_UDU), 100*(count_UDU)/(count_DUD + count_UDU)));

 FileClose(file_handle); 
}