//+------------------------------------------------------------------+
//|                                                      DisMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#include <Lib CisNewBar.mqh>                  // ��� �������� ������������ ������ ����
#include <divergenceMACD.mqh>                 // ���������� ���������� ��� ������ ��������� � ����������� MACD
#include <ChartObjects\ChartObjectsLines.mqh> // ��� ��������� ����� ���������\�����������

 // ������������ ������ �������� ����� �������
 enum BARS_MODE
 {
  ALL_HISTORY=0, // ��� �������
  INPUT_BARS     // �������� ���������� ����� ������������
 };
//+------------------------------------------------------------------+
//| �������� ��������� ����������                                    |
//+------------------------------------------------------------------+
input BARS_MODE           bars_mode=ALL_HISTORY;     // ����� �������� �������
input short               bars=20000;                // ��������� ���������� ����� �������
input int                 fast_ema_period=12;        // ������ ������� ������� MACD
input int                 slow_ema_period=26;        // ������ ��������� ������� MACD
input int                 signal_period=9;           // ������ ���������� �������� MACD

//+------------------------------------------------------------------+
//| ���������� ����������                                            |
//+------------------------------------------------------------------+

bool               first_calculate;        // ���� ������� ������ OnCalculate
int                handleMACD;             // ����� MACD
int                lastBarIndex;           // ������ ���������� ����   
long               countTrend;             // ������� ����� �����

PointDiv           divergencePoints;       // ��������� � ����������� MACD
CChartObjectTrend  trendLine;              // ������ ������ ��������� �����
CisNewBar          isNewBar;               // ��� �������� ������������ ������ ����
 
//+------------------------------------------------------------------+
//| ������� ������� ����������                                       |
//+------------------------------------------------------------------+

int OnInit()
  {     
   // ������������� ����������  ����������
   first_calculate = true;
   countTrend = 0;
   // ��������� ����� ���������� MACD
   handleMACD = iMACD(_Symbol, _Period, fast_ema_period,slow_ema_period,signal_period,PRICE_CLOSE);
   return(INIT_SUCCEEDED);
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
    int retCode;  // ��������� ���������� ��������� � �����������
    // ���� ��� ������ ������ ������ ��������� ����������
    if (first_calculate)
     {
      if (bars_mode == ALL_HISTORY)
       {
        lastBarIndex = rates_total - 101;
       }
      else
       {
       if (bars < 100)
        {
         lastBarIndex = 1;
        }
       else if (bars > rates_total)
        {
         lastBarIndex = rates_total-101;
        }
       else
        {
         lastBarIndex = bars-101;
        }
       }
       for (;lastBarIndex > 0; lastBarIndex--)
        {
          // ��������� ������� �� ������ �� ������� �����������\��������� 
          retCode = divergenceMACD (handleMACD,_Symbol,_Period,lastBarIndex,divergencePoints);
          // ���� ���������\����������� ����������
          if (retCode)
           {    
            //������� ����� ���������\�����������                    
            trendLine.Create(0,"TrendLine_"+countTrend,0,divergencePoints.timeExtrPrice1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2);           
            //����������� ���������� ����� �����
            countTrend++;
           }
        }
       first_calculate = false;
     }
    else  // ���� ������� �� ������
     {
       // ���� ����������� ����� ���
       if (isNewBar.isNewBar() > 0)
        {
         // ���������� ���������\�����������
         retCode = divergenceMACD (handleMACD,_Symbol,_Period,1,divergencePoints);
         // ���� ���������\����������� ����������
         if (retCode)
          {          
           // ������� ����� ���������\�����������              
           trendLine.Create(0,"TrendLine_"+countTrend,0,divergencePoints.timeExtrMACD1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2); 
           // ����������� ���������� ����� �����
           countTrend++;
          }        
        }
     } 
    
    return(rates_total);
  }