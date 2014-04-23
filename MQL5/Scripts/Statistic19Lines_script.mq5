//+------------------------------------------------------------------+
//|                                             Statistic19Lines.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs

#include <ExtrLine\CExtremumCalc_NE.mqh>
#include <Lib CisNewBar.mqh>
#include <CheckHistory.mqh>

enum LevelType
{
 EXTR_MN, 
 EXTR_W1,
 EXTR_D1,
 EXTR_H4,
 EXTR_H1
};

input datetime start_time = D'2012.01.01';
input datetime end_time =   D'2014.04.01';

input int    period_ATR = 100;      //Период ATR для канала
input double percent_ATR = 0.03; //Ширина канала уровня в процентах от ATR
input double precentageATR_price = 1; //Процентр ATR для нового экструмума
input LevelType level = EXTR_H4;
 
SExtremum estruct[3];
ENUM_TIMEFRAMES period_current = Period();
ENUM_TIMEFRAMES period_level;
CisNewBar is_new_level_bar;

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
 
 
int handle_19Lines;
datetime buffer_time[];
double buffer_19Lines_price1[];
double buffer_19Lines_price2[];
double buffer_19Lines_price3[];
double buffer_19Lines_atr1[];
double buffer_19Lines_atr2[];
double buffer_19Lines_atr3[];
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
 PrintFormat("BEGIN");
 int start_index_buffer = 0; //первый номер набора буферов для 3 линий уровня 
 handle_19Lines = iCustom(Symbol(), PERIOD_M1, "NineteenLines_BB", period_ATR, percent_ATR, true, clrRed, true, clrRed, true, clrRed, true, clrRed, true, clrRed, true, clrRed); 

 PrintFormat("Хэндл создал. молодец");
 for(int i = 0; i < 5; i++)
 {
 Sleep(1000);
 int size1 = CopyBuffer(handle_19Lines, start_index_buffer    , start_time, end_time, buffer_19Lines_price1);
 int size2 = CopyBuffer(handle_19Lines, start_index_buffer + 1, start_time, end_time, buffer_19Lines_atr1);
 int size3 = CopyBuffer(handle_19Lines, start_index_buffer + 2, start_time, end_time, buffer_19Lines_price2);
 int size4 = CopyBuffer(handle_19Lines, start_index_buffer + 3, start_time, end_time, buffer_19Lines_atr2);
 int size5 = CopyBuffer(handle_19Lines, start_index_buffer + 4, start_time, end_time, buffer_19Lines_price3);
 int size6 = CopyBuffer(handle_19Lines, start_index_buffer + 5, start_time, end_time, buffer_19Lines_atr3);
 
 PrintFormat("bars = %d | %d / %d / %d / %d / %d / %d", BarsCalculated(handle_19Lines), size1, size2, size3, size4, size5, size6);
 }
 //int size = (end_time - start_time)/PeriodSeconds(PERIOD_M1);
 //for(int i = )
 
 PrintFormat("%s END вошла снизу вврех вышла вверх = %.0f; вошла снизу вврех вышла вниз = %.0f; вошла сверху вниз вышла вверх = %.0f; вошла сверху вниз вышла вниз = %.0f", __FUNCTION__, count_DUU, count_DUD, count_UDU, count_UDD);
}


ENUM_TIMEFRAMES GetTFbyLevel(LevelType lt)
{
 ENUM_TIMEFRAMES result = Period();
 if(lt == EXTR_MN) result = PERIOD_MN1;
 if(lt == EXTR_W1) result = PERIOD_W1;
 if(lt == EXTR_D1) result = PERIOD_D1;
 if(lt == EXTR_H4) result = PERIOD_H4;
 if(lt == EXTR_H1) result = PERIOD_H1;
 
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