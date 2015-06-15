//+------------------------------------------------------------------+
//|                                              EvgenyWithBrain.mq5 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <SystemLib/IndicatorManager.mqh>     // библиотека по работе с индикаторами
#include <TradeManager/TradeManager.mqh>      // торговая библиотека
#include <RobotEvgeny/EvgenysBrain.mqh>


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
input double lot = 1; // лот
//input double percent = 0.1; // для контейнера движений (скорее всего станет константой)

// объекты классов 
CTradeManager *ctm; 
CEvgenysBrain *evgeny;
CExtrContainer *extremums;
CContainerBuffers *conbuf;
// хэндлы индикаторов
int  handleDE;
int  handlePBI;  // Для дальнейшего использования предполагается объявление всех индикаторов на OnInit()
int  evgenySignal;
int  trend;
// имена событий 
string eventExtrUpName;    // событие прихода верхнего экстремума
string eventExtrDownName;  // собы
string eventMoveChanged;

ENUM_TIMEFRAMES TFs[3] = {PERIOD_M5,PERIOD_M15,PERIOD_H1};

// структуры позиции и трейлинга
SPositionInfo pos_info;      // структура информации о позиции
STrailing     trailing;      // структура информации о трейлинге
int OnInit()
{ 
 // сохраняем имена событий
 eventExtrDownName = "EXTR_DOWN_FORMED_" + _Symbol + "_"   + PeriodToString(_Period);
 eventExtrUpName   = "EXTR_UP_FORMED_"   + _Symbol + "_"   + PeriodToString(_Period); 
 eventMoveChanged  = "MOVE_CHANGED_"     + _Symbol + "_"   + PeriodToString(_Period); 
 evgenySignal = NO_SIGNAL;
 ctm = new CTradeManager(); 
 // привязка индикатора DrawExtremums 
 handleDE = DoesIndicatorExist(_Symbol, _Period, "DrawExtremums");
 if (handleDE == INVALID_HANDLE)
 {
  handleDE = iCustom(_Symbol, _Period, "DrawExtremums");
  if (handleDE == INVALID_HANDLE)
  {
   Print("Не удалось создать хэндл индикатора DrawExtremums");
   return (INIT_FAILED);
  }
  SetIndicatorByHandle(_Symbol, _Period, handleDE);
 } 
 /*handlePBI = DoesIndicatorExist(_Symbol, _Period, "PriceBasedIndicator");
 if (handlePBI == INVALID_HANDLE)
 {
  handlePBI = iCustom(_Symbol, _Period, "PriceBasedIndicator");
  if (handlePBI == INVALID_HANDLE)
  {
   Print("Не удалось создать хэндл индикатора PriceBasedIndicator");
   return (INIT_FAILED);
  }
  //SetIndicatorByHandle(_Symbol, _Period, handlePBI);
 } */
 conbuf = new CContainerBuffers(TFs);
 for (int attempts = 0; attempts < 25; attempts++)
 {
  conbuf.Update();
  Sleep(100);
  if(conbuf.isFullAvailable())
  {
   PrintFormat("Наконец-то загрузился! attempts = %d", attempts);
   break;
  }
 }
  if(!conbuf.isFullAvailable())
   return (INIT_FAILED);
  extremums = new CExtrContainer(handleDE, _Symbol, _Period);
  evgeny = new CEvgenysBrain(_Symbol, _Period, extremums, conbuf);   

 // заполняем поля позиции
 pos_info.expiration = 0;
 // заполняем 
 trailing.trailingType = TRAILING_TYPE_NONE;
 trailing.handleForTrailing = 0;     
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 delete ctm;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
 ctm.OnTick();
 conbuf.Update();
 if(!extremums.isUploaded())
 PrintFormat("%s Не загрузился контейнер экстремумов, так не должно быть.");
 //log_file.Write(LOG_DEBUG, StringFormat("%s Не загрузился контейнер экстремумов, так не должно быть.", MakeFunctionPrefix(__FUNCTION__)));
 
 if (evgeny.CheckClose() && ctm.GetPositionCount() > 0)
 { 
  // то закрываем позицию
  ctm.ClosePosition(0);
 }
 evgenySignal = evgeny.GetSignal();
 if(evgenySignal == BUY)
 {
  //Print("Пришел сигнал на BUY");
  log_file.Write(LOG_DEBUG, "Пришел сигнал на BUY");
  pos_info.sl = evgeny.CountStopLossForTrendLines();
  pos_info.tp = pos_info.sl*10;
  pos_info.volume = lot;
  pos_info.type = OP_BUY;
  ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing);
 }
 if(evgenySignal == SELL)
 {
  //Print("Пришел сигнал на SELL");
  log_file.Write(LOG_DEBUG, "Пришел сигнал на SELL");
  pos_info.sl = evgeny.CountStopLossForTrendLines();
  pos_info.tp = pos_info.sl*10;
  pos_info.volume = lot;
  pos_info.type = OP_SELL;
  ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing);
 } 
  
}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
 extremums.UploadOnEvent(sparam, dparam, lparam);
 double price;
 if (sparam == eventExtrDownName)
 {
  price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
  pos_info.type = OP_BUY; 
 }
 if (sparam == eventExtrUpName)
 {
  price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
  pos_info.type = OP_SELL;
 }
 // пришло событие "сформировался новых экстремум"
 if (sparam == eventExtrDownName || sparam == eventExtrUpName)
 {
  evgeny.UploadOnEvent();

 }
 // пришло событие "изменилось движение на PBI"
 if (sparam == eventMoveChanged)
 {
  // если тренд вверх
  if (dparam == 1.0 || dparam == 2.0)
  {
  
  }
  // если тренд вниз
  if (dparam == 3.0 || dparam == 4.0)
  {
   
  }
 }   
}
//+------------------------------------------------------------------+

