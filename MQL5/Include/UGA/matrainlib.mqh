//+------------------------------------------------------------------+
//| ������������ ��������� ��������                                  |
//+------------------------------------------------------------------+
#include        "UGAlib.mqh"
#include        "MustHaveLib.mqh"
#include        <TradeBlocks/CrossEMA.mq5>

//---
double          cap=10000;           // ��������� �������
double          optF=0.3;            // ����������� F
long            leverage;            // ����� �����
double          contractSize;        // ������ ���������
double          dig;                 // ���-�� ������ ����� ������� � ��������� (��� ����������� �������� ������ ������� �� �������� ����� � ������ ���-��� ������)
//---
int             OptParamCount=2;     // ���-�� �������������� ����������
int             MaxMAPeriod=250;     // ������������ ������ ���������� �������
//---
int             depth=250;           // ������� ������� (�� ��������� - 250, ���� ���� ���� - �������� � �������������� ��������/�������)
int             from=0;              // ������ �������� ���������� (����������� ���������������� ����� ������ ���������� � ������� InitFirstLayer())
int             count=2;             // ������� �� ��� �������� (�� ��������� - 2, ���� ���� ���� - �������� � �������������� ��������/�������)
//---
double          ERROR=0.0;           // ������� ������ �� ��� (��� ��� ������������� ������������, �������� ��� ����������)

CrossEMA        trade;               //������ ������ CrossEMA

double          traindd;             // ����������� ��������� �������� ������� � ����������

ENUM_TM_POSITION_TYPE   my_signal;   //���������� ��� �������� ��������� �������

//+------------------------------------------------------------------+
//| InitArrays()                                                     |
//| ����������� �������� � �������������� ��������/�������           |
//+------------------------------------------------------------------+
void InitArrays()
  {
//--- ��������������� ������ ��� ����������� ��������� �� ������������ ������
   ArrayResize(d,count);
//--- ��������������� ������ ��� ����������� ��������� �� ������������ ������
   ArrayResize(o,count);
//--- ��������������� ������ ��� ����������� ��������� �� ������������ ������
   ArrayResize(h,count);
//--- ��������������� ������ ��� ����������� ��������� �� ������������ ������
   ArrayResize(l,count);
//--- ��������������� ������ ��� ����������� ��������� �� ������������ ������
   ArrayResize(c,count);
//--- ��������������� ������ ��� ����������� ��������� �� ������������ ������
   ArrayResize(v,count);
  }
//+------------------------------------------------------------------+
//| �������-������� ��� ������������� ������������ ���������:        |
//| �������� ����, optF, ���� ��������;                              |
//| ����� �������������� ��� ������, �� ����������                   |
//| ����������� ������� �� ������������ �����                        |
//+------------------------------------------------------------------+
void FitnessFunction(int chromos)
  {
   int    b;
//--- ���� �������� �������?   
   bool   trig=false;
//--- ����������� �������� �������
   string dir="";
//--- ���� �������� �������
   double OpenPrice=0;
//--- ������������� ����� ����� �������� ����� � ��������������� �����������
   int    z;
//--- ������� ������
   double t=cap;
//--- ������������ ������
   double maxt=t;
//--- ���������� ��������
   double aDD=0;
//--- ������������� ��������
   double rDD=0.000001;
//--- ��������������� �������-�������
   double ff=0;
//--- �� �������� ����
   z=(int)MathRound(Colony[GeneCount-1][chromos]*12);
   switch(z)
     {
      case  0: {s="AUDUSD"; break;};
      case  1: {s="AUDUSD"; break;};
      case  2: {s="EURAUD"; break;};
      case  3: {s="EURCHF"; break;};
      case  4: {s="EURGBP"; break;};
      case  5: {s="EURJPY"; break;};
      case  6: {s="EURUSD"; break;};
      case  7: {s="GBPCHF"; break;};
      case  8: {s="GBPJPY"; break;};
      case  9: {s="GBPUSD"; break;};
      case 10: {s="USDCAD"; break;};
      case 11: {s="USDCHF"; break;};
      case 12: {s="USDJPY"; break;};
      default: {s="EURUSD"; break;};
     }
  // MAshort=iMA(s,tf,(int)MathRound(Colony[1][chromos]*MaxMAPeriod)+1,0,MODE_SMA,PRICE_OPEN);
  // MAlong =iMA(s,tf,(int)MathRound(Colony[2][chromos]*MaxMAPeriod)+1,0,MODE_SMA,PRICE_OPEN);
   
   trade.UpdateHandle(SLOW_EMA,(int)MathRound(Colony[1][chromos]*MaxMAPeriod)+1); //����������� ������ ���������� EMA
   trade.UpdateHandle(FAST_EMA,(int)MathRound(Colony[1][chromos]*MaxMAPeriod)+1); //����������� ������ �������� EMA   
      
   dig=MathPow(10.0,(double)SymbolInfoInteger(s,SYMBOL_DIGITS));
//--- �� �������� ����������� F
   optF=Colony[GeneCount][chromos];
   leverage=AccountInfoInteger(ACCOUNT_LEVERAGE);
   contractSize=SymbolInfoDouble(s,SYMBOL_TRADE_CONTRACT_SIZE);
   b=MathMin(Bars(s,tf)-1-count-MaxMAPeriod,depth);
//--- ��� ���������, ������������ ������������ ������ - ������ �������� �� ����������
   for(from=b;from>=1;from--)
     {
      my_signal = trade.GetSignal(true,from);  //�������� �������� ������
     
      // CopyBuffer(MAshort,0,from,count,ShortBuffer);
      // CopyBuffer(MAlong,0,from,count,LongBuffer);
      //if(LongBuffer[0]>LongBuffer[1] && ShortBuffer[0]>LongBuffer[0] && ShortBuffer[1]<LongBuffer[1])
        if(my_signal == OP_SELL)
        {
         if(trig==false)
           {
            CopyOpen(s,tf,from,count,o);
            OpenPrice=o[1];
            dir="SELL";
            trig=true;
           }
         else
           {
            if(dir=="BUY")
              {
               CopyOpen(s,tf,from,count,o);
               if(t>0) t=t+t*optF*leverage*(o[1]-OpenPrice)*dig/contractSize; else t=0;
               if(t>maxt) {maxt=t; aDD=0;} else if((maxt-t)>aDD) aDD=maxt-t;
               if((maxt>0) && (aDD/maxt>rDD)) rDD=aDD/maxt;
               OpenPrice=o[1];
               dir="SELL";
               trig=true;
              }
           }
        }
    //  if(LongBuffer[0]<LongBuffer[1] && ShortBuffer[0]<LongBuffer[0] && ShortBuffer[1]>LongBuffer[1])
       if(my_signal == OP_BUY)
        {
         if(trig==false)
           {
            CopyOpen(s,tf,from,count,o);
            OpenPrice=o[1];
            dir="BUY";
            trig=true;
           }
         else
           {
            if(dir=="SELL")
              {
               CopyOpen(s,tf,from,count,o);
               if(t>0) t=t+t*optF*leverage*(OpenPrice-o[1])*dig/contractSize; else t=0;
               if(t>maxt) {maxt=t; aDD=0;} else if((maxt-t)>aDD) aDD=maxt-t;
               if((maxt>0) && (aDD/maxt>rDD)) rDD=aDD/maxt;
               OpenPrice=o[1];
               dir="BUY";
               trig=true;
              }
           }
        }
     }
   if(rDD<=traindd) ff=t; else ff=0.0;
   AmountStartsFF++;
   Colony[0][chromos]=ff;
  }
//+------------------------------------------------------------------+
//| ServiceFunction                                                  |
//+------------------------------------------------------------------+
void ServiceFunction()
  {
  }
//+------------------------------------------------------------------+
//| ���������� � ����� ������������� ������������                    |
//+------------------------------------------------------------------+
void GA()
  {
//--- ���-�� ����� (����� ���-�� �������������� ����������, 
//--- ���� �� ���������� �� �������� ��������� � FitnessFunction())
   GeneCount=OptParamCount+2;
//--- ���-�� �������� � �������
   ChromosomeCount=GeneCount*11;
//--- ������� ��������� ������
   RangeMinimum=0.0;
//--- �������� ��������� ������
   RangeMaximum=1.0;
//--- ��� ������
   Precision=0.0001;
//--- 1-�������, ����� ������-��������
   OptimizeMethod=2;
   ArrayResize(Chromosome,GeneCount+1);
   ArrayInitialize(Chromosome,0);
//--- ���-�� ���� ��� ���������
   Epoch=100;
//--- ���� ����������, ������������ �������, ������������� �������, ������������� �����, 
//--- �������������, ����������� �������� ������ ���������, ����������� ������� ������� ���� � %
   UGA(100.0,1.0,1.0,1.0,1.0,0.5,1.0);
  }
//+------------------------------------------------------------------+
//| �������� ���������������� ��������� ���������                    |
//| � ������ ����������; ������ ������ ���� ����� ���-�� �����       |
//+------------------------------------------------------------------+
void GetTrainResults() //
  {
//--- ������������� ����� ����� �������� ����� � ��������������� �����������
   int z;
   trade.UpdateHandle(SLOW_EMA,(int)MathRound(Chromosome[1]*MaxMAPeriod)+1);
   trade.UpdateHandle(FAST_EMA,(int)MathRound(Chromosome[2]*MaxMAPeriod)+1);
      
  // MAshort=iMA(s,tf,(int)MathRound(Chromosome[1]*MaxMAPeriod)+1,0,MODE_SMA,PRICE_OPEN);
  // MAlong =iMA(s,tf,(int)MathRound(Chromosome[2]*MaxMAPeriod)+1,0,MODE_SMA,PRICE_OPEN);
  // CopyBuffer(MAshort,0,from,count,ShortBuffer);
  // CopyBuffer(MAlong,0,from,count,LongBuffer);
   
  if(!trade.UploadBuffers(from)) //�������� �������� ������
    return;
   
//--- ���������� ������ ����
   z=(int)MathRound(Chromosome[GeneCount-1]*12);
   switch(z)
     {
      case  0: {s="AUDUSD"; break;};
      case  1: {s="AUDUSD"; break;};
      case  2: {s="EURAUD"; break;};
      case  3: {s="EURCHF"; break;};
      case  4: {s="EURGBP"; break;};
      case  5: {s="EURJPY"; break;};
      case  6: {s="EURUSD"; break;};
      case  7: {s="GBPCHF"; break;};
      case  8: {s="GBPJPY"; break;};
      case  9: {s="GBPUSD"; break;};
      case 10: {s="USDCAD"; break;};
      case 11: {s="USDCHF"; break;};
      case 12: {s="USDJPY"; break;};
      default: {s="EURUSD"; break;};
     }
//--- ���������� ������ �������� ������������ F
   optF=Chromosome[GeneCount];
  }
//+------------------------------------------------------------------+
