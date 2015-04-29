//+------------------------------------------------------------------+
//|                                                      CondomA.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Шаблон переходного периода категории А                           |
//+------------------------------------------------------------------+

// подключение необходимых библиотек
#include <SystemLib/IndicatorManager.mqh>   // библиотека по работе с индикаторами
#include <CLog.mqh>                         // для лога
#include <Hvost/HvostBrain.mqh>
//#include <ChartObjects/ChartObjectsLines.mqh>      // для рисования линий расхождения
#include <Chicken/ContainerBuffers.mqh>     // контейнер буферов данных

struct STradeTF
{
 bool used;
 ENUM_TIMEFRAMES period;
 STrailing trailing;
 CHvostBrain *hvostBrain;
};
STradeTF    tradeM5;
STradeTF    tradeM15;
STradeTF    tradeH1;
// входные параметры робота  
input double lot           = 1.0;    // лот   - отказаться смело, будет вычисляться   
input bool   useTF_M5      = true;
input bool   useTF_M15     = true;
input bool   useTF_H1      = true;
int const    skipLastBar   = true; // пропустить последний бар при расчете канала
// переменные
bool is_flat_now;            // флаг, показывающий, флэт ли сейчас на графике или нет 
int countBars;
int countTFs = 0;
int tradeSignal = 0;
// переменные для хранения времени движения цены
datetime signal_time;        // время получения сигнала пробития ценой уровня на расстояние H
datetime open_pos_time;      // время открытия позиции   
// объекты классов
CTradeManager *ctm;          // объект торгового класса
CContainerBuffers *conbuf;   // контейнер буферов
// структуры позиции и трейлинга
SPositionInfo pos_info;      // структура информации о позиции
STrailing     trailing;      // структура информации о трейлинге
STradeTF tradeTF[3];         // массив структура для торговли на разных таймфреймах
int OnInit()
  {
   ENUM_TIMEFRAMES TFs[] = {PERIOD_M5, PERIOD_M15, PERIOD_H1, PERIOD_H4};
   conbuf = new CContainerBuffers(TFs);
   log_file.Write(LOG_DEBUG, "Эксперт был запущен");
   if(!useTF_M5 && !useTF_M15 && !useTF_H1)
   {
    PrintFormat("useTF_M5 = %b, useTF_M15 = %b, useTF_H1 = %b", useTF_M5, useTF_M15, useTF_H1);
    return(INIT_FAILED);
   }
   tradeM5.used    = useTF_M5;
   tradeM5.period  = PERIOD_M5;
   tradeM15.used   = useTF_M15;
   tradeM15.period = PERIOD_M15;
   tradeH1.used    = useTF_H1;
   tradeH1.period  = PERIOD_H1;
   tradeTF[0] = tradeM5;  // 0 - индекс таймфрейма М5
   tradeTF[1] = tradeM15; // 1 - индекс таймфрейма М15
   tradeTF[2] = tradeH1;  // 2 - индекс таймфрейма H1
   
   // создаем объект торгового класса для открытия и закрытия позиций
   ctm = new CTradeManager();
   if (ctm == NULL)
   {
    log_file.Write(LOG_DEBUG, "Не удалось создать объект класса CTradeManager");
    //Print("Не удалось создать объект класса CTradeManager");
    return (INIT_FAILED);
   }  
   
   for(int i = 0; i < 3; i++)
   {
    if(tradeTF[i].used == true)
    {
     tradeTF[i].hvostBrain = new CHvostBrain( _Symbol, tradeTF[i].period, conbuf);
     if(tradeTF[i].hvostBrain == NULL)
     { 
      log_file.Write(LOG_DEBUG, "Не удалось создать объект класса CHvostBrain");
      //Print("Не удалось создать объект класса CHvostBrain");
      return (INIT_FAILED);
     } 
     tradeTF[i].trailing.trailingType = TRAILING_TYPE_NONE;
     //countTFs++;
    }
   } 
               
   // заполняем поля позиции
   pos_info.volume = lot;
   pos_info.expiration = 0;

   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   Print("Код ошибки = ",reason);
   // удаляем объекты
   for(int i = 0; i < 3 && tradeTF[i].used ; i++)
   {
    delete tradeTF[i].hvostBrain;
   }
   delete ctm;
  }

void OnTick()
  { 
   ctm.OnTick();
   if(conbuf.Update())
   {
    for(int i = 0; i < 3 && tradeTF[i].used; i++)
    {
     //PrintFormat("%s Обновился прекрасно тф = %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(tradeTF[i].period));
     // если пришел новый бар на старшем ТФ
     tradeSignal = tradeTF[i].hvostBrain.GetSignal();
     if(tradeSignal == SELL)
     {
      log_file.Write(LOG_DEBUG, "Получен сигнал SELL");
      Print(__FUNCTION__,"Получен сигнал SELL");
      // вычисляем стоп лосс, тейк профит и открываем позицию на SELL
      pos_info.type = OP_SELL;
      pos_info.sl = CountStopLoss(-1, tradeTF[i].hvostBrain, tradeTF[i].period);       
      pos_info.tp = CountTakeProfit(-1, tradeTF[i].hvostBrain);
      pos_info.priceDifference = 0;     
      ctm.OpenUniquePosition(_Symbol,_Period, pos_info, trailing);  
     
      // сохраняем время открытия позиции
      open_pos_time = TimeCurrent();  
     }
     if(tradeSignal == BUY)
     { 
      log_file.Write(LOG_DEBUG, "Получен сигнал BUY");
      Print(__FUNCTION__,"Получен сигнал BUY");
      // вычисляем стоп лосс, тейк профит и открываем позицию на BUY
      pos_info.type = OP_BUY;
      pos_info.sl = CountStopLoss(1, tradeTF[i].hvostBrain, tradeTF[i].period);       
      pos_info.tp = CountTakeProfit(1, tradeTF[i].hvostBrain);           
      pos_info.priceDifference = 0;       
      ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);
      // сохраняем время открытия позиции
      open_pos_time = TimeCurrent();   
     }  
     // если нет открытых позиций то сбрасываем тип позиции на нуль
     if (ctm.GetPositionCount() == 0)
     {
      tradeTF[i].hvostBrain.SetOpenedPosition(0);   
     }
    }
   }
  }

   // вычисляет стоп лосс
int  CountStopLoss (int type, CHvostBrain *hvostBrain, ENUM_TIMEFRAMES period)
{
 int copied;
 double prices[];
 double price_bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
 double price_ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
 if (type == 1)
 {
  copied = CopyLow(_Symbol, period, 1, 2, prices);
  if (copied < 2)
  {
   log_file.Write(LOG_DEBUG, "Не удалось скопировать цены");
   Print("Не удалось скопировать цены");
   return (0);
  } 
  // ставим стоп лосс на уровне минимума
  return ( int( (price_bid-prices[ArrayMinimum(prices)])/_Point) + 50 );   
 }
 if (type == -1)
 {
  copied = CopyHigh(_Symbol, period, 1, 2, prices);
  if (copied < 2)
  {
   log_file.Write(LOG_DEBUG, "Не удалось скопировать цены");
   Print("Не удалось скопировать цены");
   return (0);
  }
  // ставим стоп лосс на уровне максимума
  return ( int( (prices[ArrayMaximum(prices)] - price_ask)/_Point) + 50 );
 }
 return (0);
}
  
// вычисляет тейк профит
int CountTakeProfit (int type, CHvostBrain *hvostBrain)
{
 double price_bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
 double price_ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
 if (type == 1)
 {
  return ( int ( MathAbs(price_ask - hvostBrain.GetMaxChannelPrice())/_Point ) );  
 }
 if (type == -1)
 {
  return ( int ( MathAbs(price_bid - hvostBrain.GetMinChannelPrice())/_Point ) );    
 }
 return (0);
}
  
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
//---
   
}
//+------------------------------------------------------------------+
