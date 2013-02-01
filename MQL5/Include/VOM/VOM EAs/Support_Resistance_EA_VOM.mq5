//+------------------------------------------------------------------+
//|                                           FraMA Cross EA VOM.mq5 |
//|                                     Copyright Paul Hampton-Smith |
//|                            http://paulsfxrandomwalk.blogspot.com |
//+------------------------------------------------------------------+
#property copyright "Paul Hampton-Smith"
#property link      "http://paulsfxrandomwalk.blogspot.com"
#property version   "1.01"

#include "..\VirtualOrderManager.mqh"
#include <ChartObjects/ChartObjectsLines.mqh>

input double   Lots=0.1;
input int      Lookback=350;
input int      Width=15;
input int      SR_Margin=250;
input int      Stop_Loss=800;
input int      Take_Profit=3600;
input ENUM_LOG_LEVEL Log_Level=LOG_VERBOSE;

double g_dblClose1,g_dblClose2,g_dblPeak,g_dblDip,g_dblPeakTrigger,g_dblDipTrigger,g_dblPoint;
CChartObjectHLine cPeak,cDip,cPeakTrigger,cDipTrigger;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   LogFile.LogLevel(Log_Level);

// Need to include this line in all EAs using CVirtualOrderManager  
   VOM.Initialise();
   Comment(VOM.m_OpenOrders.SummaryList());

// for publishing screenshots
   EventSetTimer(600);

   g_dblPoint=SymbolInfoDouble(Symbol(),SYMBOL_POINT);

   cPeakTrigger.Create(0,"PeakTrigger",0,0);
   cPeakTrigger.Color(Indigo);
   cPeakTrigger.Style(STYLE_DOT);
   cPeak.Create(0,"Peak",0,0);
   cPeak.Color(Blue);
   cPeak.Style(STYLE_DOT);
   cDipTrigger.Create(0,"DipTrigger",0,0);
   cDipTrigger.Color(Indigo);
   cDipTrigger.Style(STYLE_DOT);
   cDip.Create(0,"Dip",0,0);
   cDip.Color(Blue);
   cDip.Style(STYLE_DOT);
   LoadAndDisplayValues();
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
// Need to include this line in all EAs using CVirtualOrderManager  
   Comment(VOM.m_OpenOrders.SummaryList());
   VOM.OnTick();
   if(!VOM.NewBar()) return;

   LoadAndDisplayValues();
   if(g_dblPeak==-1 || g_dblDip==-1) return;

// buy?
   if(g_dblClose2>=g_dblDipTrigger)
      if(g_dblClose1<g_dblDipTrigger)
         if(g_dblClose2>iLowestLow(Symbol(),Period(),Width,1)+SR_Margin*g_dblPoint)
            if(VOM.OpenOrders()==0)
              {
               VOM.Buy(Symbol(),Lots,Stop_Loss,Take_Profit);
              }

// sell?
   if(g_dblClose2<=g_dblPeakTrigger)
      if(g_dblClose1>g_dblPeakTrigger)
         if(g_dblClose2<iHighestHigh(Symbol(),Period(),Width,1)-SR_Margin*g_dblPoint)
            if(VOM.OpenOrders()==0)
              {
               VOM.Sell(Symbol(),Lots,Stop_Loss,Take_Profit);
              }
  }
//+------------------------------------------------------------------+
/// OnTimer() used here to publish screenshots.
//+------------------------------------------------------------------+
void OnTimer()
  {
   string strScreenshotName=MQL5InfoString(MQL5_PROGRAM_NAME)+".gif";
   ChartScreenShot(0,strScreenshotName,800,600);
   SendFTP(strScreenshotName);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Peak(int nStart,int nLookback,int nWidth)
  {
   for(int i=nStart+nWidth;i<nStart+nLookback;i++)
     {
      int nHighest= iHighestHigh(Symbol(),Period(),i,nStart);
      if(nHighest>=nStart+nWidth && nHighest<=i-nWidth) return(iHigh(Symbol(),Period(),nHighest));
     }
   return(-1);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Dip(int nStart,int nLookback,int nWidth)
  {
   for(int i=nStart+nWidth;i<nStart+nLookback;i++)
     {
      int nLowest= iLowestLow(Symbol(),Period(),i,nStart);
      if(nLowest>=nStart+nWidth && nLowest<=i-nWidth) return(iLow(Symbol(),Period(),nLowest));
     }
   return(-1);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void LoadAndDisplayValues()
  {
   g_dblPeak=Peak(0,Lookback,Width);
   g_dblPeakTrigger=g_dblPeak-SR_Margin*g_dblPoint;
   g_dblDip=Dip(0,Lookback,Width);
   g_dblDipTrigger=g_dblDip+SR_Margin*g_dblPoint;
   g_dblClose1 = iClose(Symbol(),Period(),1);
   g_dblClose2 = iClose(Symbol(),Period(),2);

   cPeakTrigger.Price(0,g_dblPeakTrigger);
   cPeak.Price(0,g_dblPeak);
   cDipTrigger.Price(0,g_dblDipTrigger);
   cDip.Price(0,g_dblDip);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int iHighestHigh(string symbol,ENUM_TIMEFRAMES timeframe,int count=WHOLE_ARRAY,int start=0)
  {
   if(count==0) count=Bars(symbol,timeframe);
   double Arr[];
   if(CopyHigh(symbol,timeframe,start,count,Arr)>0) return((count-ArrayMaximum(Arr)-1)+start);
   else return(-1);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int iLowestLow(string symbol,ENUM_TIMEFRAMES timeframe,int count=WHOLE_ARRAY,int start=0)
  {
   if(count==0) count=Bars(symbol,timeframe);
   double Arr[];
   if(CopyLow(symbol,timeframe,start,count,Arr)>0) return((count-ArrayMinimum(Arr)-1)+start);
   else return(-1);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iLow(string symbol,ENUM_TIMEFRAMES timeframe,int index)
  {
   double Arr[];
   if(CopyLow(symbol,timeframe,index,1,Arr)>0) return(Arr[0]);
   else return(-1);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iHigh(string symbol,ENUM_TIMEFRAMES timeframe,int index)
  {
   double Arr[];
   if(CopyHigh(symbol,timeframe,index,1,Arr)>0) return(Arr[0]);
   else return(-1);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iClose(string symbol,ENUM_TIMEFRAMES timeframe,int index)
  {
   double Arr[];
   if(CopyClose(symbol,timeframe,index,1,Arr)>0) return(Arr[0]);
   else return(-1);
  }

//+------------------------------------------------------------------+
