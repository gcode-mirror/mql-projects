//+------------------------------------------------------------------+
//|                                                     FlatStat.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| ����� ���������� �� ������                                       |
//+------------------------------------------------------------------+
// ����������
#include <SystemLib/IndicatorManager.mqh> // ���������� �� ������ � ������������
#include <ChartObjects/ChartObjectsLines.mqh> // ��� ��������� ����� ������
#include <ColoredTrend/ColoredTrendUtilities.mqh> 
#include <DrawExtremums/CExtrContainer.mqh> // ��������� �����������
#include <CTrendChannel.mqh> // ��������� ���������
#include <CompareDoubles.mqh> // ��� ��������� ������������ �����
#include <StringUtilities.mqh> // ��������� ���������
// ���������
input double percent = 0.1; // �������
// ������� ����������
bool trendNow = false;
bool firstUploaded = false; // ���� �������� ������� �����������
bool firstUploadedTrend = false; // ���� �������� ������� �������
int  calcMode = 0;  // ����� ����������
int  flatType = 0;
int  trendType = 0;
int  countFlat = 0;
// ������
int handleDE;
// �������� �������� ��� �������, ����� ��������� ��������� - �������
int flat_a_up_tup = 0,flat_a_down_tup = 0;      
int flat_a_up_tdown = 0,flat_a_down_tdown = 0;   

// ���������� ��� �������� ���� � ������
double extrUp0,extrUp1;
datetime timeUp0,timeUp1;
double extrDown0,extrDown1;
datetime timeDown0,timeDown1;

datetime lastExtrTime;
datetime tempLastExtrTime;  

double H; // ������ �����
double top_point; // ������� �����, ������� ����� �������
double bottom_point; // ������ �����, ������� ����� �������
// ������� �������
CExtrContainer *container;
CTrendChannel *trend;
CChartObjectTrend flatLine; // ������ ������ �������� �����
CChartObjectHLine topLevel; // ������� �������
CChartObjectHLine bottomLevel; // ������ �������

int fileTestStat; // ����� �����

int OnInit()
  {
   // �������� ���������� DrawExtremums
   handleDE = DoesIndicatorExist(_Symbol, _Period, "DrawExtremums");
   if (handleDE == INVALID_HANDLE)
    {
     handleDE = iCustom(_Symbol, _Period, "DrawExtremums");
     if (handleDE == INVALID_HANDLE)
      {
       Print("�� ������� ������� ����� ���������� DrawExtremums");
       return (INIT_FAILED);
      }
     SetIndicatorByHandle(_Symbol, _Period, handleDE);
    }
    // ������� ����� ����� ������������ ���������� ����������� �������
    fileTestStat = FileOpen("True FlatStat/FlatStat_" + _Symbol+"_" + PeriodToString(_Period) + ".txt", FILE_WRITE|FILE_COMMON|FILE_ANSI|FILE_TXT, "");
    if (fileTestStat == INVALID_HANDLE) //�� ������� ������� ����
     {
      Print("�� ������� ������� ���� ������������ ���������� ����������� �������");
      return (INIT_FAILED);
     }           
   // ������� ������� �������
   container = new CExtrContainer(handleDE, _Symbol, _Period);
   trend = new CTrendChannel(0, _Symbol, _Period, handleDE, percent);

   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  { 
   FileClose(fileTestStat); 
   // ������� �������
   delete trend; 
   delete container;
  }

void OnTick()
  {
   if (!firstUploaded)
    {
     firstUploaded = container.Upload();
    }
   if (!firstUploadedTrend)
    {
     firstUploadedTrend = trend.UploadOnHistory();
    }
   if (!firstUploaded || !firstUploadedTrend)
    return;
    
 if (calcMode == 3)
    {      
      // ���� ���� �������� �������� ������
      if ( GreatOrEqualDoubles (SymbolInfoDouble(_Symbol,SYMBOL_BID),top_point) )
       {
        switch (flatType)
         {
          case 1: 
           if (trendType == 1) 
            {
             if (timeUp0 > timeDown0)
             {
              flat_a_up_tup ++;
             }
            }
           if (trendType == -1)
            {
             if (timeUp0 > timeDown0)
              flat_a_up_tdown ++;
            }
          break;

         }    
        calcMode = 0; // ����� ������������ � ������ �����  
        topLevel.Delete();           
        bottomLevel.Delete();        
       }
      // ���� ���� �������� ������� ������
      if ( LessOrEqualDoubles (SymbolInfoDouble(_Symbol,SYMBOL_BID),bottom_point) )
       {
        switch (flatType)
         {
          case 1: 
           if (trendType == 1) 
            {
             if (timeUp0 > timeDown0)                
              flat_a_down_tup ++;
            }
           if (trendType == -1)
            {
             if (timeUp0 > timeDown0)                
              flat_a_down_tdown ++;
            }
          break;

         }      
        calcMode = 0; // ����� ������������ � ������ �����
        topLevel.Delete();           
        bottomLevel.Delete();
       } 
      }       
  }
  
// ������� ��������� ������� �������
void OnChartEvent(const int id,         // ������������� �������  
                  const long& lparam,   // �������� ������� ���� long
                  const double& dparam, // �������� ������� ���� double
                  const string& sparam  // �������� ������� ���� string 
                 )
  {
   int newDirection;
   trend.UploadOnEvent(sparam,dparam,lparam);
   container.UploadOnEvent(sparam,dparam,lparam);
   // ���� ������ ����� "���� �� ���� ������"
   if (calcMode == 0)
    { 
     trendNow = trend.IsTrendNow();
     // ���� ������ ���� ����� 
     if (trendNow)
       {
        // ��������� � ����� ��������� �������� ��������
        calcMode = 1;
        trendType = trend.GetTrendByIndex(0).GetDirection();
       }
    }
   // ���� ������ ����� "����� �����, ����� ������ ��������� ����"
   else if (calcMode == 1)
    {
     trendNow = trend.IsTrendNow();
     // ���� ������ �� �����
     if (!trendNow)
      {
       // �� ������ ������ ���� � �� ��������� � ����� ��������� ����������
       calcMode = 2;
      }
    }
   // ���� ������ ����� "������������ ����"
   else if (calcMode == 2)
    {
     // ��������� ��������� ����������
     extrUp0 = container.GetExtrByIndex(1,EXTR_HIGH).price;
     extrUp1 = container.GetExtrByIndex(2,EXTR_HIGH).price;
     timeUp0 = container.GetExtrByIndex(1,EXTR_HIGH).time;
     timeUp1 = container.GetExtrByIndex(2,EXTR_HIGH).time;
     extrDown0 = container.GetExtrByIndex(1,EXTR_LOW).price;
     extrDown1 = container.GetExtrByIndex(2,EXTR_LOW).price;
     timeDown0 = container.GetExtrByIndex(1,EXTR_LOW).time;
     timeDown1 = container.GetExtrByIndex(2,EXTR_LOW).time;
     
     lastExtrTime = container.GetExtrByIndex(0,EXTR_BOTH).time; // ����� ���������� ����������
     
     H = MathMax(extrUp0,extrUp1) - MathMin(extrDown0,extrDown1);
     top_point = extrUp0 + H*0.75;
     bottom_point = extrDown0 - H*0.75;     
     flatType = 0;
     // ��������� ��� �����
     if (IsFlatA())
      flatType = 1;
     // ���� ������� ��������� ����
     if (flatType != 0)
      {
       // ��������� � ����� �������� ����������
       calcMode = 3;
       countFlat ++; // ����������� ���������� ������
       GenFlatName (); // ������������ ����
      }
    }

  }   
  
// ������� ��������� ����� ������

bool IsFlatA ()
 {
  //  ���� 
  if ( LessOrEqualDoubles (MathAbs(extrUp1 - extrUp0),percent*H) &&
       GreatOrEqualDoubles (extrDown0 - extrDown1,percent*H)
     )
    {
     return (true);
    }
  return (false);
 }  
 
 // �������������� �������
 void GenFlatName ()  // ������� ����� �����
  {
   flatLine.Create(0, "flatUp_" + countFlat, 0, timeUp0, extrUp0, timeUp1, extrUp1); // ������� �����  
   flatLine.Color(clrYellow);
   flatLine.Width(5);
   flatLine.Create(0,"flatDown_" + countFlat, 0, timeDown0, extrDown0, timeDown1, extrDown1); // ������ �����
   flatLine.Color(clrYellow);
   flatLine.Width(5);
     
   topLevel.Delete();
   topLevel.Create(0, "topLevel", 0, top_point);
   bottomLevel.Delete();
   bottomLevel.Create(0, "bottomLevel", 0, bottom_point);   
  }
  
  // ���������� ���������� ��� �������
 string GenUniqEventName(string eventName)
 {
  return (eventName + "_" + _Symbol + "_" + PeriodToString(_Period));
 }