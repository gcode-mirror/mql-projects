//+------------------------------------------------------------------+
//|                                                 StatisticPBI.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs

#include <ColoredTrend/ColoredTrendNE.mqh>
#include <ColoredTrend/ColoredTrendUtilities.mqh>

input datetime start_time = D'2013.01.01';
input datetime end_time   = D'2013.12.01';
input double   percentage_ATR = 2;   
input double   difToTrend = 1.5;
input string   file_name = "StatisticPBI.csv";
 
void OnStart()
{
 int seconds_M15 = PeriodSeconds(PERIOD_M15);
 int seconds_H1  = PeriodSeconds(PERIOD_H1);
 int seconds_H4  = PeriodSeconds(PERIOD_H4);
 int seconds_D1  = PeriodSeconds(PERIOD_D1);
 int seconds_W1  = PeriodSeconds(PERIOD_W1);
 int seconds_MN1 = PeriodSeconds(PERIOD_MN1);
 
 int size_M15 = (int)(end_time - start_time)/seconds_M15;
 int size_H1  = (int)(end_time - start_time)/seconds_H1;
 int size_H4  = (int)(end_time - start_time)/seconds_H4;
 int size_D1  = (int)(end_time - start_time)/seconds_D1;
 int size_W1  = (int)(end_time - start_time)/seconds_W1;
 int size_MN1 = (int)(end_time - start_time)/seconds_MN1;
 
 int handle_PBI_M15 = iCustom(Symbol(), PERIOD_M15, "PriceBasedIndicator", size_M15, percentage_ATR, difToTrend, percentage_ATR, difToTrend);
 int handle_PBI_H1  = iCustom(Symbol(), PERIOD_H1 , "PriceBasedIndicator", size_H1 , percentage_ATR, difToTrend, percentage_ATR, difToTrend);
 int handle_PBI_H4  = iCustom(Symbol(), PERIOD_H4 , "PriceBasedIndicator", size_H4 , percentage_ATR, difToTrend, percentage_ATR, difToTrend);
 int handle_PBI_D1  = iCustom(Symbol(), PERIOD_D1 , "PriceBasedIndicator", size_D1 , percentage_ATR, difToTrend, percentage_ATR, difToTrend);
 int handle_PBI_W1  = iCustom(Symbol(), PERIOD_W1 , "PriceBasedIndicator", size_W1 , percentage_ATR, difToTrend, percentage_ATR, difToTrend);
 int handle_PBI_MN1 = iCustom(Symbol(), PERIOD_MN1, "PriceBasedIndicator", size_MN1, percentage_ATR, difToTrend, percentage_ATR, difToTrend);
 
 int file_handle = FileOpen(file_name, FILE_WRITE|FILE_CSV|FILE_COMMON);
 
 double buffer_PBI_M15[];
 double buffer_PBI_H1 [];
 double buffer_PBI_H4 [];
 double buffer_PBI_D1 [];
 double buffer_PBI_W1 [];
 double buffer_PBI_MN1[];
 datetime 
 
 int size1 = CopyBuffer(handle_PBI_M15, 4, 0, size_M15, buffer_PBI_M15);
 int size2 = CopyBuffer(handle_PBI_H1 , 4, 0, size_H1 , buffer_PBI_H1 );
 int size3 = CopyBuffer(handle_PBI_H4 , 4, 0, size_H4 , buffer_PBI_H4 ); 
 int size4 = CopyBuffer(handle_PBI_D1 , 4, 0, size_D1 , buffer_PBI_D1 );
 int size5 = CopyBuffer(handle_PBI_W1 , 4, 0, size_W1 , buffer_PBI_W1 );
 int size6 = CopyBuffer(handle_PBI_MN1, 4, 0, size_MN1, buffer_PBI_MN1);
 
 PrintFormat("Gutten tag %d/%d/%d/%d/%d/%d", size1, size2, size3, size4, size5, size6);    
/*
 Сделано: расчет размеров буферов для каждого хэндла
 Далее: 1)копирование в локальные буфера данных
        2)6 циклов(так как заполняем построчно) размера size_M15 с хитрой индексацией так что бы в итоге все строки были одинаковой длины
        т.е. в часовом баре содержится 4 15-минутки следовательно один часой бар будет представлен 4 позициями с одинаковыми значениями
        параллельно с выполнением цикла будет идти запись в файл
*/

 //for(int i = 0; i < size_M15; )
 //{
  
 //}
 
}
//+------------------------------------------------------------------+
