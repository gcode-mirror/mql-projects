//+------------------------------------------------------------------+
//|                                     ChickenMultiTFwithBrains.mq5 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <TradeManager/TradeManager.mqh>
#include <Chicken/ChickensBrain.mqh>                 // объект по вычислению сигналов для торговли
#include <SystemLib/IndicatorManager.mqh>            // библиотека по работе с индикаторами
#include <CLog.mqh>                                  // для лога
#include <Chicken/ContainerBuffers.mqh>

//+------------------------------------------------------------------+
//| Expert parametrs                                                 |
//+------------------------------------------------------------------+
input double  volume  = 0.1;        // размер лота
input int     spread  = 30;         // максимально допустимый размер спреда в пунктах на открытие и доливку позиции
input bool    use_tp  = false;      // использование takeProfit
input double   tp_ko  = 2;          //
input bool tradeTFM5  = true;       // осуществление торговли на  М5
input bool tradeTFM15 = true;       // осуществление торговли на  M15
input bool tradeTFH1  = true;       // осуществление торговли на Н1
input ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_PBI;
/*
input int minProfit = 250;
input int trailingStop = 150;
input int trailingStep = 5;
*/
struct STradeTF  // хранение данных, соотносимых к определенному Тф
{
 ENUM_TIMEFRAMES period;   // период Тф
 bool used;                // использование данного Тф                           
 STrailing trailing;       // трэйлинг, используемый на этом Тф 
 CChickensBrain *chicken;  // chicken - класс, производящий основные рассчеты 
                           // и возвращающий сигнал на торговлю (SELL/BUY)
};

SPositionInfo pos_info;    
STrailing trailing;
STradeTF  tradeTF[3];      // массив Тф, на которых может производииться торговля

STradeTF    tradeM5;
STradeTF    tradeM15;
STradeTF    tradeH1;

CTradeManager *ctm;
CContainerBuffers *conbuf; // буфер контейнеров на различных Тф, заполняемый на OnTick()
                           // highPrice[], lowPrice[], closePrice[] и т.д;
bool   closePosition;
int    tmpLastBar;
int    handle;
int    fileTrade; // хэндл файла
            
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
 log_file.Write(LOG_DEBUG,"ChickenMultiTFwithBrains запущен");
 ENUM_TIMEFRAMES TFs[] = {PERIOD_M5, PERIOD_M15, PERIOD_H1};
 conbuf = new CContainerBuffers(TFs);
 if(!tradeTFM5 && !tradeTFM15 && !tradeTFH1)
 {
  PrintFormat("tradeTFM5 = %b, tradeTFM15 = %b, tradeTFH1 = %b", tradeTFM5, tradeTFM15, tradeTFH1);
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
 ctm = new CTradeManager();
 fileTrade = FileOpen("ChickenMultiTFwithBrains/Chicken 8.05.15/Trade" + _Symbol +".txt", FILE_WRITE|FILE_COMMON|FILE_ANSI|FILE_TXT, "");
 if (fileTrade == INVALID_HANDLE) //не удалось открыть файл
 {
  Print("Не удалось создать файл тестирования статистики прохождения уровней");
  return (INIT_FAILED);
 }      
      
 for(int i = 0; i < 3; i++)  // проходим по каждому Тф
 {
  if(tradeTF[i].used == true) // если Тф включен в число используемых
  {
   if(trailingType == TRAILING_TYPE_PBI) 
   {
    //handle = DoesIndicatorExist(_Symbol, tradeTF[i].period, "PriceBasedIndicator");
    //if (handle == INVALID_HANDLE)
    //{
     handle = iCustom(_Symbol, tradeTF[i].period, "PriceBasedIndicator");
     if (handle == INVALID_HANDLE)
     {
      log_file.Write(LOG_DEBUG,"Не удалось создать хэндл индикатора PriceBasedIndicator");
      Print(__FUNCTION__,"Не удалось создать хэндл индикатора PriceBasedIndicator");
      return (INIT_FAILED);
     }
     //SetIndicatorByHandle(_Symbol,tradeTF[i].period,handle);
     //}
   }   
   if(trailingType == TRAILING_TYPE_EXTREMUMS)
   {
    handle = iCustom(_Symbol, tradeTF[i].period, "DrawExtremums");
    if (handle == INVALID_HANDLE)
    {
     log_file.Write(LOG_DEBUG,"Не удалось создать хэндл индикатора DrawExtremums");
     Print(__FUNCTION__,"Не удалось создать хэндл индикатора DrawExtremums");
     return (INIT_FAILED);
    }
   }
   tradeTF[i].trailing.trailingType = trailingType; //заполняем тип трэйлинга для i-ого Тф
   tradeTF[i].trailing.handleForTrailing = handle;
   /*
   trailing.minProfit    = minProfit;
   trailing.trailingStop = trailingStop;
   trailing.trailingStep = trailingStep;
   */
   tradeTF[i].chicken = new CChickensBrain(_Symbol, tradeTF[i].period, conbuf);
  } 
 }
 //recountInterval = false;
 pos_info.volume = volume;
 pos_info.expiration = 0;

 return(INIT_SUCCEEDED);
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 for(int i = 0; i < 3; i++)
 {
  if(tradeTF[i].used == true)
  { 
   delete ctm;
   IndicatorRelease(tradeTF[i].trailing.handleForTrailing);
  } 
 }
 FileClose(fileTrade); 
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
 int chickenSignal;
 //MqlDateTime timeCurrent;
 int tp;
 double slPrice;
 double curAsk;
 double curBid;
 ctm.OnTick();
 ctm.DoTrailing();
 if(conbuf.Update()) // если удалось прогрузить буферы на всех таймфреймах переходим к алгоритму(BarsCalculated(handle)>0 )
 {
  for(int i = 0; i < 3; i++)
  { 
   // если i-ый таймфрейм используется
   if(tradeTF[i].used == true)
   {
    long magic = ctm.MakeMagic(_Symbol, tradeTF[i].period);// создаем уникальный номер для позиции на Тф
    curAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    curBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    chickenSignal = tradeTF[i].chicken.GetSignal();        // получаем сигнал с ChickensBrain
    if(chickenSignal == SELL || chickenSignal == BUY)
    {
     if(chickenSignal == SELL)
     {// запоняем позицию на SELL
      log_file.Write(LOG_DEBUG, StringFormat("%s%s Получили сигнал на продажу SELL", SymbolInfoString(_Symbol,SYMBOL_DESCRIPTION),PeriodToString(tradeTF[i].period)));
      pos_info.type = OP_SELLSTOP; 
      pos_info.sl = tradeTF[i].chicken.GetDiffHigh();
      tradeTF[i].trailing.minProfit = 2 * tradeTF[i].chicken.GetDiffHigh();
      tradeTF[i].trailing.trailingStop = tradeTF[i].chicken.GetDiffHigh();
     }
     if(chickenSignal == BUY)
     {// запоняем позицию на BUY
      log_file.Write(LOG_DEBUG, StringFormat("%s%s Получили сигнал на продажу BUY", SymbolInfoString(_Symbol,SYMBOL_DESCRIPTION),PeriodToString(tradeTF[i].period)));
      pos_info.type = OP_BUYSTOP;
      pos_info.sl   = tradeTF[i].chicken.GetDiffLow();
      tradeTF[i].trailing.minProfit = 2 * tradeTF[i].chicken.GetDiffLow();
      tradeTF[i].trailing.trailingStop = tradeTF[i].chicken.GetDiffLow();
     }
     //stoplevel = MathMax(chicken.sl_min, SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL))*Point();
     tp = (use_tp) ? (int)MathCeil((tradeTF[i].chicken.GetHighBorder() - tradeTF[i].chicken.GetLowBorder())*0.75/Point()) : 0; 
     pos_info.tp = tp;
     pos_info.magic = magic;
     pos_info.priceDifference = tradeTF[i].chicken.GetPriceDifference();
     pos_info.expiration = MathMax(DEPTH - tradeTF[i].chicken.GetIndexMax(), DEPTH - tradeTF[i].chicken.GetIndexMin());
     tradeTF[i].trailing.trailingStep = 5;
     if (pos_info.tp == 0 || pos_info.tp > pos_info.sl * tp_ko) //елси tp вычислен верно открываем позицию
     {
      log_file.Write(LOG_DEBUG, StringFormat("%s, tp=%d, sl=%d", MakeFunctionPrefix(__FUNCTION__), pos_info.tp, pos_info.sl));
      FileWriteString(fileTrade, "Была открыта позиция на" + _Symbol+ "на" + PeriodToString(tradeTF[i].period) +" \n");
      FileWriteString(fileTrade, StringFormat("%s, date = %s ,tp = %d, sl = %d", MakeFunctionPrefix(__FUNCTION__), TimeToString(TimeCurrent()), pos_info.tp, pos_info.sl)); 
      ctm.OpenMultiPosition(_Symbol, _Period, pos_info, tradeTF[i].trailing, spread);
     }
    }
    if(chickenSignal == NO_POSITION) // если пришел сигнал NO_POSITION закрываем текущую позицию
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s%s Получили сигнал NO_POSITION", SymbolInfoString(_Symbol,SYMBOL_DESCRIPTION), PeriodToString(tradeTF[i].period)));
     ctm.ClosePendingPosition(_Symbol, magic);
    }
    else if(ctm.GetPositionCount() != 0) //если сигнала NO_POSITION не было, меняем стоплосс и закрываем позицию по условию
    {
     ENUM_TM_POSITION_TYPE type = ctm.GetPositionType(_Symbol, magic);
     if(type == OP_SELLSTOP && ctm.GetPositionStopLoss(_Symbol, magic) < curAsk) 
     {
      slPrice = curAsk;
      ctm.ModifyPosition(_Symbol, magic, slPrice, 0);  
     }
     if(type == OP_BUYSTOP  && ctm.GetPositionStopLoss(_Symbol, magic) > curBid) 
     {
      slPrice = curBid;
      ctm.ModifyPosition(_Symbol, magic, slPrice, 0); 
     }
     if((type == OP_BUYSTOP || type == OP_SELLSTOP) && (pos_info.tp >0 && pos_info.tp <= pos_info.sl*tp_ko))
     {
      ctm.ClosePendingPosition(_Symbol, magic);
     } 
    }
   } 
  }   
 } 
 else
 log_file.Write(LOG_DEBUG, StringFormat("%s conbuf.Update() не успешен ", MakeFunctionPrefix(__FUNCTION__)));
} 
 //+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{

   
}
//+------------------------------------------------------------------+
