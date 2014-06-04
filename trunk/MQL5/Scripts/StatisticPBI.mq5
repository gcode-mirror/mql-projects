//+------------------------------------------------------------------+
//|                                                 StatisticPBI.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs


#include <Lib CisNewBarDD.mqh>
//#include <ColoredTrend/ColoredTrend.mqh>
//#include <ColoredTrend/ColoredTrendUtilities.mqh>

#define DEPTH 100

input datetime start_time = D'2013.04.01';
input datetime end_time   = D'2013.09.01';
input double   percentage_ATR = 2;   
input double   difToTrend = 1.5;
input string   file_name = "StatisticPBI.csv";
 
void OnStart()
{
 CisNewBar isNewBarMN1 (_Symbol, PERIOD_MN1);   // для проверки формирования нового бара на месяце
 CisNewBar isNewBarW1  (_Symbol, PERIOD_W1 );   // для проверки формирования нового бара на неделе
 CisNewBar isNewBarD1  (_Symbol, PERIOD_D1 );   // для проверки формирования нового бара на дне
 CisNewBar isNewBarH4  (_Symbol, PERIOD_H4 );   // для проверки формирования нового бара на 4 часах
 CisNewBar isNewBarH1  (_Symbol, PERIOD_H1 );   // для проверки формирования нового бара на часе
 CisNewBar isNewBarM15 (_Symbol, PERIOD_M15);   // для проверки формирования нового бара на 15 минутах
 
 int handle_PBI_M15 = iCustom(Symbol(), PERIOD_M15, "PriceBasedIndicator", DEPTH, percentage_ATR, difToTrend);
 int handle_PBI_H1  = iCustom(Symbol(), PERIOD_H1 , "PriceBasedIndicator", DEPTH, percentage_ATR, difToTrend);
 int handle_PBI_H4  = iCustom(Symbol(), PERIOD_H4 , "PriceBasedIndicator", DEPTH, percentage_ATR, difToTrend);
 int handle_PBI_D1  = iCustom(Symbol(), PERIOD_D1 , "PriceBasedIndicator", DEPTH, percentage_ATR, difToTrend);
 int handle_PBI_W1  = iCustom(Symbol(), PERIOD_W1 , "PriceBasedIndicator", DEPTH, percentage_ATR, difToTrend);
 int handle_PBI_MN1 = iCustom(Symbol(), PERIOD_MN1, "PriceBasedIndicator", DEPTH, percentage_ATR, difToTrend);
 
 int file_handle = FileOpen(file_name, FILE_WRITE|FILE_CSV|FILE_COMMON);
 
 double buffer_PBI_M15[];
 double buffer_PBI_H1 [];
 double buffer_PBI_H4 [];
 double buffer_PBI_D1 [];
 double buffer_PBI_W1 [];
 double buffer_PBI_MN1[];
 datetime time[];
 
 int size1 = CopyBuffer(handle_PBI_M15, 4, start_time, end_time, buffer_PBI_M15);
 int size2 = CopyBuffer(handle_PBI_H1 , 4, start_time, end_time, buffer_PBI_H1 );
 int size3 = CopyBuffer(handle_PBI_H4 , 4, start_time, end_time, buffer_PBI_H4 ); 
 int size4 = CopyBuffer(handle_PBI_D1 , 4, start_time, end_time, buffer_PBI_D1 );
 int size5 = CopyBuffer(handle_PBI_W1 , 4, start_time, end_time, buffer_PBI_W1 );
 int size6 = CopyBuffer(handle_PBI_MN1, 4, start_time, end_time, buffer_PBI_MN1);
 int size7 = CopyTime(Symbol(), PERIOD_M15, start_time, end_time, time);
 
/*
 Сделано: расчет размеров буферов для каждого хэндла
 Далее: 1)копирование в локальные буфера данных
        2)6 циклов(так как заполняем построчно) размера size_M15 с хитрой индексацией так что бы в итоге все строки были одинаковой длины
        т.е. в часовом баре содержится 4 15-минутки следовательно один часой бар будет представлен 4 позициями с одинаковыми значениями
        параллельно с выполнением цикла будет идти запись в файл
*/

 string tmp_str = "datetime; ";
 for(int i = 0; i < size1; i++)
 {
  StringConcatenate(tmp_str, tmp_str, StringFormat("%s;", TimeToString(time[i])));
 }
 FileWrite(file_handle, tmp_str);
 
 tmp_str = "PERIOD M15; ";
 for(int i = 0; i < size1; i++)
 {
  StringConcatenate(tmp_str, tmp_str, StringFormat("%d;", buffer_PBI_M15[i]));
 }
 FileWrite(file_handle, tmp_str);
 
 tmp_str = "PERIOD H1; ";
 int index_H1 = 0;
 for(int i = 0; i < size1; i++)
 {
  StringConcatenate(tmp_str, tmp_str, StringFormat("%d;", buffer_PBI_H1[index_H1]));
  if(isNewBarH1.isNewBar(time[i])) index_H1++;
 }
 FileWrite(file_handle, tmp_str);
 
 tmp_str = "PERIOD H4; ";
 int index_H4 = 0;
 for(int i = 0; i < size1; i++)
 {
  if(isNewBarH4.isNewBar(time[i])) index_H4++;
  StringConcatenate(tmp_str, tmp_str, StringFormat("%d;", buffer_PBI_H4[index_H4]));
 }
 FileWrite(file_handle, tmp_str);
 
 tmp_str = "PERIOD D1; ";
 int index_D1 = 0;
 for(int i = 0; i < size1; i++)
 {
  if(isNewBarD1.isNewBar(time[i])) index_D1++;
  StringConcatenate(tmp_str, tmp_str, StringFormat("%d;", buffer_PBI_D1[index_D1]));
 }
 FileWrite(file_handle, tmp_str);
 
 tmp_str = "PERIOD W1; ";
 int index_W1 = 0;
 for(int i = 0; i < size1; i++)
 {
  if(isNewBarW1.isNewBar(time[i])) index_W1++;
  StringConcatenate(tmp_str, tmp_str, StringFormat("%d;", buffer_PBI_W1[index_W1]));
 }
 FileWrite(file_handle, tmp_str);
 
  tmp_str = "PERIOD MN1; ";
 int index_MN1 = 0;
 for(int i = 0; i < size1; i++)
 {
  if(isNewBarMN1.isNewBar(time[i])) index_MN1++;
  StringConcatenate(tmp_str, tmp_str, StringFormat("%d;", buffer_PBI_MN1[index_MN1]));
 }
 FileWrite(file_handle, tmp_str);

 Alert(StringFormat("Gutten tag M15=%d; H1=%d; H4=%d; D1=%d; W1=%d; MN1=%d time: %d", size1, size2, size3, size4, size5, size6, size7));     
 
 FileClose(file_handle);
 IndicatorRelease(handle_PBI_M15);
 IndicatorRelease(handle_PBI_H1);
 IndicatorRelease(handle_PBI_H4);
 IndicatorRelease(handle_PBI_D1);
 IndicatorRelease(handle_PBI_W1);
 IndicatorRelease(handle_PBI_MN1);
 ArrayFree(buffer_PBI_M15);
 ArrayFree(buffer_PBI_H1);
 ArrayFree(buffer_PBI_H4);
 ArrayFree(buffer_PBI_D1);
 ArrayFree(buffer_PBI_W1);
 ArrayFree(buffer_PBI_MN1);
 ArrayFree(time);
 
}
//+------------------------------------------------------------------+
