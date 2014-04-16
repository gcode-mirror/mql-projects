//+------------------------------------------------------------------+
//|                                                     smydMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window   // ����� ������������� �������� ���� ����������

//+------------------------------------------------------------------+
//| ���������, ������������ ����������� MACD                         |
//| 1) ������ MACD                                                   |
//| 2) ������ ������� ����������� �� MACD � �� ������� ����          |
//| 3) ������ ����������� ������ ������������� �������               |
//| 4) �������� ���������� �����������                               |
//+------------------------------------------------------------------+

// ���������� ���������� 
#include <Lib CisNewBar.mqh>                       // ��� �������� ������������ ������ ����
#include <Divergence/divergenceMACD.mqh>           // ���������� ���������� ��� ������ ����������� MACD
#include <ChartObjects/ChartObjectsLines.mqh>      // ��� ��������� ����� �����������
#include <CompareDoubles.mqh>                      // ��� �������� �����������  ���

// ������� ���������������� ��������� ����������
sinput string macd_params     = "";                // ��������� ���������� MACD
input  int    fast_ema_period = 12;                // ������ ������� ������� MACD
input  int    slow_ema_period = 26;                // ������ ��������� ������� MACD
input  int    signal_period   = 9;                 // ������ ���������� �������� MACD
input  ENUM_APPLIED_PRICE priceType = PRICE_CLOSE; // ��� ���, �� ������� ����������� MACD

sinput string stat_params     = "";                // ��������� ���������� ����������
input  int    actualBars      = 10;                // ���������� ����� ��� �������� ������������
input  string fileName        = "MACD_STAT.txt";   // ��� ����� ����������
input  datetime  start_time   = 0;                 // ����, � ������� ������ ��������� ����������

// ��������� ������������ ������� 
#property indicator_buffers 3                      // ������������� 3 ������������ ������
#property indicator_plots   2                      // 2 ������ ������������ �� ��������

// ��������� �������

// ��������� 1-�� ������ (MACD)
#property indicator_type1 DRAW_HISTOGRAM           // �����������
#property indicator_color1  clrWhite               // ���� �����������
#property indicator_width1  1                      // ������� �����������
#property indicator_label1  "MACD"                 // ������������ ������

// ��������� 2-�� ������ (���������� ����� MACD)
#property indicator_type2 DRAW_LINE                // �����
#property indicator_color2  clrRed                 // ���� �����
#property indicator_width2  1                      // ������� �����
#property indicator_style2  STYLE_DASHDOT          // ����� �����
#property indicator_label2  "SIGNAL"               // ������������ ������

// ��������� 3-�� ������ (������ �� ����������� MACD)
//#property indicator_type3 DRAW_NONE                // �� ����������

// ���������� ���������� ����������
int                handleMACD;                     // ����� MACD
int                lastBarIndex;                   // ������ ���������� ���� 
int                retCode;                        // ��� ������ ���������� ����������  �����������  
long               countDiv;                       // ������� ����� ����� (��� ��������� ����� �����������) 

PointDivMACD       divergencePoints;               // ����� ����������� MACD �� ������� ������� � �� ������� MACD
CChartObjectTrend  trendLine;                      // ������ ������ ��������� ����� (��� ����������� �����������)
CChartObjectVLine  vertLine;                       // ������ ������ ������������ �����
CisNewBar          isNewBar;                       // ��� �������� ������������ ������ ����

// ������ ���������� 
double bufferMACD[];                               // ����� ������� MACD
double signalMACD[];                               // ���������� ����� MACD
double bufferDiv[];                                // ����� �������� �����������

// ����� ����� ����������
int    fileHandle;

// ���������� ��� �������� ����������� ����������

double averActualProfitDivBuy   = 0;       // ������� ������������� ������� �� ����������� ����������� �� �������
double averActualLossDivBuy     = 0;       // ������� ������������� ������ ��� ���������� ����������� �� �������
double averActualProfitDivSell  = 0;       // ������� ������������� ������� �� ����������� ����������� �� �������
double averActualLossDivSell    = 0;       // ������� ������������� ������ ��� ���������� ����������� �� �������                     

// �������� �����������
int    countActualDivBuy        = 0;       // ���������� ���������� ����������� �� �������
int    countDivBuy              = 0;       // ����� ���������� ����������� �� �������     
int    countActualDivSell       = 0;       // ��������� ���������� ����������� �� �������
int    countDivSell             = 0;       // ����� ���������� ����������� �� �������                               

// �������������� ������� ������ ����������
void    DrawIndicator (datetime vertLineTime);     // ���������� ����� ����������. � ������� ���������� ����� ������������ �����
   
// ������������� ����������
int OnInit()
  {  
   // ������� ���� ���������� �� ������
   fileHandle = FileOpen(fileName,FILE_WRITE|FILE_COMMON|FILE_ANSI|FILE_TXT, "");
   if (fileHandle == INVALID_HANDLE) //�� ������� ������� ����
    {
     Print("������ ���������� ShowMeYourDivMACD. �� ������� ������� ���� ����������");
     return (INIT_FAILED);
    }  
   ArraySetAsSeries(bufferDiv,true);
   // ��������� ����� ���������� MACD
   handleMACD = iMACD(_Symbol, _Period, fast_ema_period,slow_ema_period,signal_period,PRICE_CLOSE);
   if ( handleMACD == INVALID_HANDLE)  // ���� �� ������� ��������� ����� MACD
    {
     return(INIT_FAILED);  // �� ������������� ����������� �� �������
    }  
   // ������� ��� ����������� ������� (����� �����������, � ����� ����� ��������� �������� �����������)  
   ObjectsDeleteAll(0,0,OBJ_TREND); // ��� ��������� ����� � �������� ������� 
   ObjectsDeleteAll(0,1,OBJ_TREND); // ��� ��������� ����� � ��������� �������
   ObjectsDeleteAll(0,0,OBJ_VLINE); // ��� ������������ �����, ������������ ������ ������������� �����������
   // ��������� ���������� � �������� 
   SetIndexBuffer(0,bufferMACD,INDICATOR_DATA);         // ����� MACD
   SetIndexBuffer(1,signalMACD,INDICATOR_DATA);         // ����� ���������� �����
   SetIndexBuffer(2,bufferDiv ,INDICATOR_CALCULATIONS); // ����� ����������� (�������� ������������� ��������)
   // ������������� ����������  ����������
   countDiv = 0;                                        // ���������� ��������� ���������� �����������
   return(INIT_SUCCEEDED); // �������� ���������� ������������� ����������
  }

// ��������������� ����������
void OnDeinit(const int reason)
 {
   // ������� ��� ����������� ������� (����� �����������, � ����� ����� ��������� �������� �����������)  
   ObjectsDeleteAll(0,0,OBJ_TREND); // ��� ��������� ����� � �������� ������� 
   ObjectsDeleteAll(0,1,OBJ_TREND); // ��� ��������� ����� � ��������� �������
   ObjectsDeleteAll(0,0,OBJ_VLINE); // ��� ������������ �����, ������������ ������ ������������� �����������
   // ������� ������������ ������
   ArrayFree(bufferMACD);
   ArrayFree(signalMACD);
   ArrayFree(bufferDiv);
   // ����������� ����� MACD
   IndicatorRelease(handleMACD);
   // ��������� ���� ���������� 
   if (fileHandle != INVALID_HANDLE)
   FileClose(fileHandle);
 }

// ������� ������� ������� ����������
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
   // ��������� ����������
   double maxPrice;          // ��������� �������� ���
   double minPrice;          // ��������� ������� ���
   
   if (prev_calculated == 0) // ���� �� ����. ������ ���� ���������� 0 �����, ������ ���� ����� ������
    {
      // �������� ����� MACD
      if ( CopyBuffer(handleMACD,0,0,rates_total,bufferMACD) < 0 ||
           CopyBuffer(handleMACD,1,0,rates_total,signalMACD) < 0 )
           {
             // ���� �� ������� ��������� ������ MACD
             Print("������ ���������� ShowMeYourDivMACD. �� ������� ��������� ������ MACD");
             return (0); 
           }                
      // ������� ���������� ������ �������� ��� � ���������
      if ( !ArraySetAsSeries (time,true) || 
           !ArraySetAsSeries (open,true) || 
           !ArraySetAsSeries (high,true) ||
           !ArraySetAsSeries (low,true)  || 
           !ArraySetAsSeries (close,true) )
          {
            // ���� �� ������� ����������� ���������� ��� � ��������� ��� ���� �������� ��� � �������
            Print("������ ���������� ShowMeYourDivMACD. �� ������� ���������� ���������� �������� ��� � ���������");
            return (0);
          }
       // �������� �� ���� ����� ������� � ���� ����������� MACD
       for (lastBarIndex = rates_total-101;lastBarIndex > 0; lastBarIndex--)
        {
          // �������� ����� �������� ����������� MACD
          bufferDiv[lastBarIndex] = 0;
          retCode = divergenceMACD (handleMACD,_Symbol,_Period,divergencePoints,lastBarIndex);  // �������� ������ �� �����������
          // ���� �� ������� ��������� ������ MACD
          if (retCode == -2)
           {
             Print("������ ���������� ShowMeYourDivMACD. �� ������� ��������� ������ MACD");
             return (0);
           }
          if (retCode)
           {                                          
             DrawIndicator (time[lastBarIndex]);   // ���������� ����������� �������� ����������     
             bufferDiv[lastBarIndex] = retCode;    // ��������� � ����� ��������    
             
             // ��������� �������������� ������ �� ������� �����������
             if (time[lastBarIndex] >= start_time)   // ���� ������� ����� �������� � ���� ���������� ����������
              {
             // ��������� �������� �� ������� ���������� ������������
             maxPrice =  high[ArrayMaximum(high,lastBarIndex-actualBars,actualBars)];  // ������� �������� �� high
             minPrice =  low[ArrayMinimum(low,lastBarIndex -actualBars,actualBars)];   // ������� ������� �� low

             // ��������� ������������ �����������
             
             if (retCode == 1)      // ���� ����������� �� SELL
              {
               FileWriteString(fileHandle,""+TimeToString(time[lastBarIndex])+" (����������� �� SELL): \n { \n" );   
                countDivSell ++;    // ����������� ���������� ����������� �� SELL
                
                maxPrice = maxPrice - close[lastBarIndex];   // ���������, ��������� ���� ���� ����� �� ���� ��������
                minPrice = close[lastBarIndex] - minPrice;   // ���������, ��������� ���� ���� ���� �� ���� ��������
                
                if (maxPrice < 0)
                  maxPrice = 0;
                if (minPrice < 0)
                  minPrice = 0;
                
                if (minPrice > maxPrice)  // ������ ����������� �������� ����������
                 {
                   countActualDivSell ++;   // ����������� ���������� ���������� ����������� �� SELL
                   
                   averActualProfitDivSell = averActualProfitDivSell + minPrice; // ����������� ����� ��� ������� �������
                   averActualLossDivSell   = averActualLossDivSell   + maxPrice; // ����������� ����� ��� �������� ������
                   FileWriteString(fileHandle,"\n ������: ����������");
                   FileWriteString(fileHandle,"\n ������������� �������: "+DoubleToString(minPrice));
                   FileWriteString(fileHandle,"\n ������������� ������: "+DoubleToString(maxPrice));
                   FileWriteString(fileHandle,"\n}\n");                     
                 }
                else
                 {
                   FileWriteString(fileHandle,"\n ������: �� ����������");
                   FileWriteString(fileHandle,"\n ������������� �������: "+DoubleToString(minPrice));
                   FileWriteString(fileHandle,"\n ������������� ������: "+DoubleToString(maxPrice));
                   FileWriteString(fileHandle,"\n}\n");                            
                 }
              }
             if (retCode == -1)     // ���� ����������� �� BUY
              {
               FileWriteString(fileHandle,""+TimeToString(time[lastBarIndex])+" (����������� �� BUY): \n { \n" );                 
                countDivBuy ++;     // ����������� ���������� ����������� �� BUY
                
                maxPrice = maxPrice - close[lastBarIndex];   // ���������, ��������� ���� ���� ����� �� ���� ��������
                minPrice = close[lastBarIndex] - minPrice;   // ���������, ��������� ���� ���� ���� �� ���� ��������  
                
                if (maxPrice < 0)
                  maxPrice = 0;
                if (minPrice < 0)
                  minPrice = 0;     
                
                if (maxPrice > minPrice)  // ������ ����������� �������� ����������
                 {
                   countActualDivBuy ++;    // ����������� ���������� ���������� ����������� �� BUY
                   
                   averActualProfitDivBuy = averActualProfitDivBuy + maxPrice;  // ����������� ����� ��� ������� �������
                   averActualLossDivBuy   = averActualLossDivBuy   + minPrice;  // ����������� ����� ��� �������� ������
                   FileWriteString(fileHandle,"\n ������: ����������");
                   FileWriteString(fileHandle,"\n ������������� �������: "+DoubleToString(maxPrice));
                   FileWriteString(fileHandle,"\n ������������� ������: "+DoubleToString(minPrice));
                   FileWriteString(fileHandle,"\n}\n");   
                 }
                else
                 {
                   FileWriteString(fileHandle,"\n ������: �� ����������");
                   FileWriteString(fileHandle,"\n ������������� �������: "+DoubleToString(maxPrice));
                   FileWriteString(fileHandle,"\n ������������� ������: "+DoubleToString(minPrice));
                   FileWriteString(fileHandle,"\n}\n");  
                 }
                          
              }
              
             } // end �������� �� ���� 
              
              
           }
        }
          
          // ������ � ���� ����� ����������
          if (countActualDivSell > 0)
              {
               averActualLossDivSell   = averActualLossDivSell   / countActualDivSell;
               averActualProfitDivSell = averActualProfitDivSell / countActualDivSell; 
              }
          if (countActualDivBuy > 0)
              {
               averActualLossDivBuy    = averActualLossDivBuy    / countActualDivBuy;
               averActualProfitDivBuy  = averActualProfitDivBuy  / countActualDivBuy;
              }
              
          FileWriteString(fileHandle,"\n\n ���������� ����������� SELL: "+IntegerToString(countDivSell));
          FileWriteString(fileHandle,"\n �� �� ����������: "+IntegerToString(countActualDivSell));
           
          FileWriteString(fileHandle,"\n ������� �������: "+DoubleToString(averActualProfitDivSell));
          FileWriteString(fileHandle,"\n ������� ������������� ������: "+DoubleToString(averActualLossDivSell));      
          
          FileWriteString(fileHandle,"\n\n ���������� ����������� BUY: "+IntegerToString(countDivBuy));
          FileWriteString(fileHandle,"\n �� �� ����������: "+IntegerToString(countActualDivBuy));
           
          FileWriteString(fileHandle,"\n ������� �������: "+DoubleToString(averActualProfitDivBuy));
          FileWriteString(fileHandle,"\n ������� ������������� ������: "+DoubleToString(averActualLossDivBuy));  
          
        // ��������� ���� ����������
        
        FileClose(fileHandle);                       
        fileHandle = INVALID_HANDLE;                     
    }
    else    // ���� ��� �� ������ ����� ���������� 
     {
       // ���� ������������� ����� ���
       if (isNewBar.isNewBar() > 0 )
        {
              // ������� ���������� ������ �������� ��� � ���������
          if ( !ArraySetAsSeries (time,true) || 
               !ArraySetAsSeries (open,true) || 
               !ArraySetAsSeries (high,true) ||
               !ArraySetAsSeries (low,true)  || 
               !ArraySetAsSeries (close,true) )
              {
               // ���� �� ������� ����������� ���������� ��� � ��������� ��� ���� �������� ��� � �������
               Print("������ ���������� ShowMeYourDivMACD. �� ������� ���������� ���������� �������� ��� � ���������");
               return (rates_total);
              }
          // �������� ����� ������� �����������
          bufferDiv[0] = 0;
          if ( CopyBuffer(handleMACD,0,0,rates_total,bufferMACD) < 0 ||
               CopyBuffer(handleMACD,1,0,rates_total,signalMACD) < 0 )
           {
             // ���� �� ������� ��������� ������ MACD
             Print("������ ���������� ShowMeYourDivMACD. �� ������� ��������� ������ MACD");
             return (rates_total);
           }   
          retCode = divergenceMACD (handleMACD,_Symbol,_Period,divergencePoints,1);  // �������� ������ �� �����������
          // ���� �� ������� ��������� ������ MACD
          if (retCode == -2)
           {
             Print("������ ���������� ShowMeYourDivMACD. �� ������� ��������� ������ MACD");
             return (0);
           }
          if (retCode)
           {                                        
             DrawIndicator (time[0]);       // ���������� ����������� �������� ����������    
             bufferDiv[0] = retCode;        // ��������� ������� ������
           }        
            
        }
     }
   return(rates_total);
  }
  
// ������� ����������� ����������� ��������� ����������
void DrawIndicator (datetime vertLineTime)
 {
   trendLine.Color(clrYellow);
   // ������� ����� ���������\�����������                    
   trendLine.Create(0,"MacdPriceLine_"+IntegerToString(countDiv),0,divergencePoints.timeExtrPrice1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2);           
   trendLine.Color(clrYellow);         
   // ������� ����� ���������\����������� �� MACD
   trendLine.Create(0,"MACDLine_"+IntegerToString(countDiv),1,divergencePoints.timeExtrMACD1,divergencePoints.valueExtrMACD1,divergencePoints.timeExtrMACD2,divergencePoints.valueExtrMACD2);            
   vertLine.Color(clrRed);
   // ������� ������������ �����, ������������ ������ ��������� ����������� MACD
   vertLine.Create(0,"MACDVERT_"+IntegerToString(countDiv),0,vertLineTime);
   countDiv++; // ����������� ���������� ������������ ���������
 }