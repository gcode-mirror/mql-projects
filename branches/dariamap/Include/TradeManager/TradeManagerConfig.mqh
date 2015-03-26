//+------------------------------------------------------------------+
//|                                    VirtualOrderManagerConfig.mqh |
//|                                     Copyright Paul Hampton-Smith |
//|                            http://paulsfxrandomwalk.blogspot.com |
//+------------------------------------------------------------------+
#property copyright "Paul Hampton-Smith"
#property link      "http://paulsfxrandomwalk.blogspot.com"
//+------------------------------------------------------------------+
/// A central storage of hard-coded configuration items.
//+------------------------------------------------------------------+
class CConfig
  {
public:

                     CConfig();

   color             EntryPriceLineColor;
   color             StopLossLineColor;
   color             TakeProfitLineColor;

   string            FileBase;
   string            ClosedVirtualOrdersFilename;
   short             VirtualOrdersFileCsvDelimiter;
   string            VirtualOrderTicketGlobalVariable;
   int               Deviation;

   int               OrderCompletionSleepSeconds;
   int               OrderCompletionRetries;

   int               FileAccessSleep_mSec;
   int               FileAccessRetries;

   int               ServerStopLossMargin;

   string            GlobalVirtualStopListIdentifier;

   ushort            CustomVirtualOrderEvent;
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CConfig::CConfig()
  {
   EntryPriceLineColor=DarkBlue;
   StopLossLineColor=DarkOrange;
   TakeProfitLineColor=Brown;

   FileBase="VOM\\";

   VirtualOrdersFileCsvDelimiter='\t';
   VirtualOrderTicketGlobalVariable="LastVirtualOrderTicketNumber";
   Deviation=50;

   OrderCompletionSleepSeconds=1;
   OrderCompletionRetries=30;

   FileAccessSleep_mSec=100;
   FileAccessRetries=50;

   ServerStopLossMargin=1000;

   GlobalVirtualStopListIdentifier="_VOM_StopLoss_";

   CustomVirtualOrderEvent=99;
  }

CConfig Config;
//+------------------------------------------------------------------+
