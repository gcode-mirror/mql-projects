//+------------------------------------------------------------------+
//|                                                      Chicken.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <ColoredTrend/ColoredTrendUtilities.mqh>
#include <Lib CisNewBarDD.mqh>
#include <TradeManager\TradeManager.mqh>

#define DEPTH 20
#define ALLOW_INTERVAL 16

// константы сигналов
#define BUY   1    
#define SELL -1 
#define NO_POSITION 0
//+------------------------------------------------------------------+
//| Expert parametrs                                                 |
//+------------------------------------------------------------------+
input double  volume  = 0.1;
input int     spread  = 30;         // максимально допустимый размер спреда в пунктах на открытие и доливку позиции
input bool    use_tp  = false;
input double   tp_ko  = 2;
input bool tradeTFM5  = true;
input bool tradeTFM15 = true;
input bool tradeTFH1  = true;
input ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_PBI;
/*
input int minProfit = 250;
input int trailingStop = 150;
input int trailingStep = 5;
*/
struct STradeTF
{
 CisNewBar *isNewBar;
 int handle_pbi;
 int lastTrend;   // тип последнего тренда по PBI Видbмо нужно запоминать....
 bool used;
 bool recountInterval;
 ENUM_TIMEFRAMES period;
 STrailing trailing;
 CTradeManager *ctm;
};

CisNewBar *isNewBarM5;
CisNewBar *isNewBarM15;
CisNewBar *isNewBarH1;
SPositionInfo pos_info;
STrailing trailing;
STradeTF  tradeTF[3];

STradeTF    tradeM5;
STradeTF    tradeM15;
STradeTF    tradeH1;
double      buffer_pbi[];
double      buffer_high[];
double      buffer_low[];


double highPrice[], lowPrice[], closePrice[];
bool   recountInterval;
int    tmpLastBar;
            
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
 if(!tradeTFM5 && !tradeTFM15 && !tradeTFH1)
 {
  PrintFormat("tradeTFM5 = %b, tradeTFM15 = %b, tradeTFH1 = %b",tradeTFM5,tradeTFM15,tradeTFH1);
  return(INIT_FAILED);
 }
  
 tradeM5.used    = tradeTFM5;
 tradeM5.period  = PERIOD_M5;
 tradeM15.used   = tradeTFM15;
 tradeM15.period = PERIOD_M15;
 tradeH1.used    = tradeTFH1;
 tradeH1.period  = PERIOD_H1;
 tradeTF[0] = tradeM5;  // 0 - индекс таймфрейма М5
 tradeTF[1] = tradeM15; // 1 - индекс таймфрейма М15
 tradeTF[2] = tradeH1;  // 2 - индекс таймфрейма H1

 for(int i = 0; i < 3; i++)
 {
  if(tradeTF[i].used == true)
  {
   tradeTF[i].ctm = new CTradeManager();
   tradeTF[i].isNewBar = new CisNewBar(_Symbol, tradeTF[i].period);
   tradeTF[i].handle_pbi = iCustom(_Symbol, tradeTF[i].period, "PriceBasedIndicator");
   if(tradeTF[i].handle_pbi == INVALID_HANDLE)
   {
    Print("Ошибка при иниализации эксперта. Не удалось создать хэндл индикатора PriceBasedIndicator");
    return (INIT_FAILED);
   } 
   tradeTF[i].trailing.trailingType = trailingType;
   tradeTF[i].trailing.handleForTrailing = tradeTF[i].handle_pbi;
   /*
   trailing.minProfit    = minProfit;
   trailing.trailingStop = trailingStop;
   trailing.trailingStep = trailingStep;
   */
   tradeTF[i].recountInterval = false;
   tradeTF[i].lastTrend = 0;
  } 
 }
 //recountInterval = false;
 pos_info.volume = volume;
 pos_info.expiration = 0;

 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 for(int i = 0; i < 3 && tradeTF[i].used == true; i++)
 {
  IndicatorRelease(tradeTF[i].handle_pbi); 
 }
 ArrayFree(buffer_high);
 ArrayFree(buffer_low);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
 MqlDateTime timeCurrent;
 int diff_high, diff_low, sl_min, tp;
 double slPrice;
 double highBorder, lowBorder;
 double stoplevel;
 static int index_max;
 static int index_min;
 double curAsk;
 double curBid;
 for(int i = 0; i < 3; i++)
 { 
  if(tradeTF[i].used == true)
  {
   tradeTF[i].ctm.OnTick();
   tradeTF[i].ctm.DoTrailing();
  }
 }
 for(int i = 0; i < 3; i++)
 { 
  if(tradeTF[i].used == true)
  {
   index_max = -1;
   index_min = -1;
   curAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   curBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(tradeTF[i].isNewBar.isNewBar()>0 || tradeTF[i].recountInterval)
   {
    ArraySetAsSeries(buffer_high, false);
    ArraySetAsSeries(buffer_low, false);
    if(CopyClose(_Symbol, tradeTF[i].period, 1, 1, closePrice)     < 1 ||      // цена закрытия последнего сформированного бара
       CopyHigh(_Symbol, tradeTF[i].period, 1, DEPTH, buffer_high) < DEPTH ||  // буфер максимальных цен всех сформированных баров на заданую глубину
       CopyLow(_Symbol, tradeTF[i].period, 1, DEPTH, buffer_low)   < DEPTH ||  // буфер минимальных цен всех сформированных баров на заданую глубину
       CopyBuffer(tradeTF[i].handle_pbi, 4, 0, 1, buffer_pbi)       < 1)        // последнее полученное движение
    {
     index_max = -1;
     index_min = -1;  // если не получилось посчитать максимумы не будем открывать сделок
     tradeTF[i].recountInterval = true;
    }
    index_max = ArrayMaximum(buffer_high, 0, DEPTH - 1);
    index_min = ArrayMinimum(buffer_low, 0, DEPTH - 1);
    tradeTF[i].recountInterval = false;
    
    tmpLastBar = GetLastMoveType(tradeTF[i].handle_pbi);
    if (tmpLastBar != 0)
    {
     tradeTF[i].lastTrend = tmpLastBar;
    }
    if (buffer_pbi[0] == MOVE_TYPE_FLAT && index_max != -1 && index_min != -1)
    {
     highBorder = buffer_high[index_max];
     lowBorder = buffer_low[index_min];
     sl_min = MathMax((int)MathCeil((highBorder - lowBorder)*0.10/Point()), 50);
     tp = (use_tp) ? (int)MathCeil((highBorder - lowBorder)*0.75/Point()) : 0;
     diff_high = (buffer_high[DEPTH - 1] - highBorder)/Point();
     diff_low = (lowBorder - buffer_low[DEPTH - 1])/Point();
     stoplevel = MathMax(sl_min, SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL))*Point();
     pos_info.tp = 0;
     
     if(index_max < ALLOW_INTERVAL && GreatDoubles(closePrice[0], highBorder) && diff_high > sl_min && tradeTF[i].lastTrend == SELL)
     { 
      PrintFormat("Цена закрытия пробила цену максимум = %s, Время = %s, цена = %.05f, sl_min = %d, diff_high = %d",
            DoubleToString(highBorder, 5),
            TimeToString(TimeCurrent()),
            closePrice[0],
            sl_min, diff_high);
      pos_info.type = OP_SELLSTOP;
      pos_info.sl = diff_high;
      pos_info.tp = tp;
      pos_info.priceDifference = (closePrice[0] - highBorder)/Point();
      pos_info.expiration = MathMax(DEPTH - index_max, DEPTH - index_min);
      tradeTF[i].trailing.minProfit = 2*diff_high;
      tradeTF[i].trailing.trailingStop = diff_high;
      tradeTF[i].trailing.trailingStep = 5;
      if (pos_info.tp == 0 || pos_info.tp > pos_info.sl*tp_ko)
      {
       PrintFormat("%s, tp=%d, sl=%d", MakeFunctionPrefix(__FUNCTION__), pos_info.tp, pos_info.sl);
       Print(" TF = ", tradeTF[i].period);
       tradeTF[i].ctm.OpenUniquePosition(_Symbol, tradeTF[i].period, pos_info, tradeTF[i].trailing, spread);
      }
     }
      
     if(index_min < ALLOW_INTERVAL && LessDoubles(closePrice[0], lowBorder) && diff_low > sl_min && tradeTF[i].lastTrend == BUY)
     {
      PrintFormat("Цена закрытия пробила цену минимум = %s, Время = %s, цена = %.05f, sl_min = %d, diff_low = %d",
            DoubleToString(lowBorder, 5),
            TimeToString(TimeCurrent()),
            closePrice[0],
            sl_min, diff_low);
               
      pos_info.type = OP_BUYSTOP;
      pos_info.sl = diff_low;
      pos_info.tp = tp;
      pos_info.priceDifference = (lowBorder - closePrice[0])/Point();
      pos_info.expiration = MathMax(DEPTH - index_max, DEPTH - index_min);
      tradeTF[i].trailing.minProfit = 2*diff_low;
      tradeTF[i].trailing.trailingStop = diff_low;
      tradeTF[i].trailing.trailingStep = 5;
      if (pos_info.tp == 0 || pos_info.tp > pos_info.sl*tp_ko)
      {
       PrintFormat("%s, tp=%d, sl=%d", MakeFunctionPrefix(__FUNCTION__), pos_info.tp, pos_info.sl);
       tradeTF[i].ctm.OpenUniquePosition(_Symbol, tradeTF[i].period, pos_info, tradeTF[i].trailing, spread);
      }
     }
     
     if(tradeTF[i].ctm.GetPositionCount() != 0)
     {
      ENUM_TM_POSITION_TYPE type = tradeTF[i].ctm.GetPositionType(_Symbol);
       if(type == OP_SELLSTOP && tradeTF[i].ctm.GetPositionStopLoss(_Symbol) < curAsk) 
       {
        slPrice = curAsk;
        tradeTF[i].ctm.ModifyPosition(_Symbol, slPrice, 0); 
       }
       if(type == OP_BUYSTOP  && tradeTF[i].ctm.GetPositionStopLoss(_Symbol) > curBid) 
       {
        slPrice = curBid;
        tradeTF[i].ctm.ModifyPosition(_Symbol, slPrice, 0); 
       }
       if((type == OP_BUYSTOP || type == OP_SELLSTOP) && (pos_info.tp >0 && pos_info.tp <= pos_info.sl*tp_ko))
       {
        tradeTF[i].ctm.ClosePendingPosition(_Symbol);
       } 
      }
     } 
     else
     {
      tradeTF[i].ctm.ClosePendingPosition(_Symbol);
     } 
    }
   ArrayFree(buffer_pbi); 
   ArrayFree(buffer_high);
   ArrayFree(buffer_low);
   ArrayFree(closePrice); 
  }
 }
}
//+------------------------------------------------------------------+

int GetLastTrendDirection (int handle, ENUM_TIMEFRAMES period)   // возвращает true, если тендекция не противоречит последнему тренду на текущем таймфрейме
{
 int copiedPBI=-1;     // количество скопированных данных PriceBasedIndicator
 int signTrend=-1;     // переменная для хранения знака последнего тренда
 int index=1;          // индекс бара
 int nBars;            // количество баров
 
 ArraySetAsSeries(buffer_pbi, true);
 
 nBars = Bars(_Symbol,period);
 
 for (int attempts = 0; attempts < 5; attempts++)
 {
  copiedPBI = CopyBuffer(handle, 4, 1, nBars - 1, buffer_pbi);
  Sleep(100);
 }
 if (copiedPBI < (nBars-1))
 {
 // Comment("Не удалось скопировать все бары");
  return (0);
 }
 
 for (index = 0; index < nBars - 1; index++)
 {
  signTrend = int(buffer_pbi[index]);
  // если найден последний тренд вверх
  if (signTrend == 1 || signTrend == 2)
   return (1);
  // если найден последний тренд вниз
  if (signTrend == 3 || signTrend == 4)
   return (-1);
 }
 return (0);
}

int  GetLastMoveType (int handle) // получаем последнее значение PriceBasedIndicator
{
 int copiedPBI;
 int signTrend;
 copiedPBI = CopyBuffer(handle, 4, 1, 1, buffer_pbi);
 if (copiedPBI < 1)
  return (0);
 signTrend = int(buffer_pbi[0]);
 // если тренд вверх
 if (signTrend == 1 || signTrend == 2)
  return (1);
 // если тренд вниз
 if (signTrend == 3 || signTrend == 4)
  return (-1);
 return (0);
}