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


// входные параметры робота  
input double lot           = 1.0;    // лот   - отказаться смело, будет вычисляться   
//input bool   useTF_M5      = true;
//input bool   useTF_M15     = true;
//input bool   useTF_H1      = true;
int const    skipLastBar   = true; // пропустить последний бар при расчете канала
// переменные
bool is_flat_now;            // флаг, показывающий, флэт ли сейчас на графике или нет 
int countBars;
int countTFs = 0;
int tradeSignal = 0;
// переменные для хранения времени движения цены
datetime signal_time;         // время получения сигнала пробития ценой уровня на расстояние H
datetime open_pos_time;       // время открытия позиции   
// объекты классов
CTradeManager     *ctm;       // объект торгового класса
CContainerBuffers *conbuf;    // контейнер буферов
CHvostBrain       *hvostBrain;// класс вычисления сигнала торговли на каждом ТФ
CArrayObj         *hvostiki;  // массив классов по вычислению торговых сигналов типа HvostBrain

// структуры позиции и трейлинга
SPositionInfo pos_info;      // структура информации о позиции
STrailing     trailing;      // структура информации о трейлинге

int OnInit()
  {
   ENUM_TIMEFRAMES TFs[] = {PERIOD_M5, PERIOD_M15, PERIOD_H1, PERIOD_H4, PERIOD_D1};
   conbuf = new CContainerBuffers(TFs);
   hvostiki = new CArrayObj();
   hvostiki.Add( new CHvostBrain(_Symbol,PERIOD_M5,conbuf));
   hvostiki.Add( new CHvostBrain(_Symbol,PERIOD_M15,conbuf));
   hvostiki.Add( new CHvostBrain(_Symbol,PERIOD_H1,conbuf));
   log_file.Write(LOG_DEBUG, "Эксперт был запущен");
   
   /*if(!useTF_M5 && !useTF_M15 && !useTF_H1)  // проверка на включеннность таймфремов (не может быть ни одного включенного ТФ)
   {
    PrintFormat("useTF_M5 = %b, useTF_M15 = %b, useTF_H1 = %b", useTF_M5, useTF_M15, useTF_H1);
    return(INIT_FAILED);
   }*/
   
   // создаем объект торгового класса для открытия и закрытия позиций
   ctm = new CTradeManager();
   if (ctm == NULL)
   {
    log_file.Write(LOG_DEBUG, "Не удалось создать объект класса CTradeManager");
    //Print("Не удалось создать объект класса CTradeManager");
    return (INIT_FAILED);
   }  
   //------- не нужная проверка. отладка. удалить----
   for(int i = 0; i < hvostiki.Total(); i++)
   {
    if(hvostiki.At(i) == NULL)
     { 
      log_file.Write(LOG_DEBUG, "Не удалось создать объект класса CHvostBrain");
      //Print("Не удалось создать объект класса CHvostBrain");
      return (INIT_FAILED);
     } 
   } 
   //--------------------------------------------------            
   // заполняем поля позиции
   pos_info.volume = lot;
   pos_info.expiration = 0;
   trailing.trailingType = TRAILING_TYPE_NONE;
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   Print("Код ошибки = ",reason);
   // удаляем объекты
   hvostiki.Clear();
   delete hvostiki;
   delete ctm;
  }

void OnTick()
  { 
   ctm.OnTick();
   if(conbuf.Update())
   {
    for(int i = 0; i < hvostiki.Total(); i++)
    {
     //PrintFormat("%s Обновился прекрасно тф = %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(tradeTF[i].period));
     // если пришел новый бар на старшем ТФ
     hvostBrain = hvostiki.At(i);
     tradeSignal = hvostBrain.GetSignal();
     if(tradeSignal == SELL)
     {
      log_file.Write(LOG_DEBUG, "Получен сигнал SELL");
      Print(__FUNCTION__,"Получен сигнал SELL");
      // вычисляем стоп лосс, тейк профит и открываем позицию на SELL
      pos_info.type = OP_SELL;
      pos_info.sl = hvostBrain.GetStopLoss();
      pos_info.tp = hvostBrain.GetTakeProfit();
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
      pos_info.sl = hvostBrain.GetStopLoss();
      pos_info.tp = hvostBrain.GetTakeProfit();        
      pos_info.priceDifference = 0;       
      ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);
      // сохраняем время открытия позиции
      open_pos_time = TimeCurrent();   
     }  
     // если нет открытых позиций то сбрасываем тип позиции на нуль
     // где закрытие позиций?!
     if (ctm.GetPositionCount() == 0)
     {
      hvostBrain.SetOpenedPosition(0);   
     }
    }
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
//---
   
}
//+------------------------------------------------------------------+
