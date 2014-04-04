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
 
 int hadle_PBI_M15 = iCustom(Symbol(), PERIOD_M15, "PriceBasedIndicator", size_M15, percentage_ATR, difToTrend, percentage_ATR, difToTrend);
 int hadle_PBI_H1  = iCustom(Symbol(), PERIOD_H1 , "PriceBasedIndicator", size_H1 , percentage_ATR, difToTrend, percentage_ATR, difToTrend);
 int hadle_PBI_H4  = iCustom(Symbol(), PERIOD_H4 , "PriceBasedIndicator", size_H4 , percentage_ATR, difToTrend, percentage_ATR, difToTrend);
 int hadle_PBI_D1  = iCustom(Symbol(), PERIOD_D1 , "PriceBasedIndicator", size_D1 , percentage_ATR, difToTrend, percentage_ATR, difToTrend);
 int hadle_PBI_W1  = iCustom(Symbol(), PERIOD_W1 , "PriceBasedIndicator", size_W1 , percentage_ATR, difToTrend, percentage_ATR, difToTrend);
 int hadle_PBI_MN1 = iCustom(Symbol(), PERIOD_MN1, "PriceBasedIndicator", size_MN1, percentage_ATR, difToTrend, percentage_ATR, difToTrend);
 
/*
 �������: ������ �������� ������� ��� ������� ������
 �����: 1)����������� � ��������� ������ ������
        2)6 ������(��� ��� ��������� ���������) ������� size_M15 � ������ ����������� ��� ��� �� � ����� ��� ������ ���� ���������� �����
        �.�. � ������� ���� ���������� 4 15-������� ������������� ���� ����� ��� ����� ����������� 4 ��������� � ����������� ����������
        ����������� � ����������� ����� ����� ���� ������ � ����
*/
}
//+------------------------------------------------------------------+