//+------------------------------------------------------------------+
//|                                                     MEGATRON.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Эксперт МЕГАТРОН - объединенный дисептикон                       |
//+------------------------------------------------------------------+

#define ADD_TO_STOPPLOSS 50

//-------- подключение библиотек
#include <Lib CisNewBar.mqh>                // для проверки формирования нового бара
#include <TradeManager/TradeManager.mqh>    // торговая библиотека
#include <PointSystem/PointSystem.mqh>            // класс бальной системы
#include <ColoredTrend/ColoredTrendUtilities.mqh>

//-------- входные параметры индикаторов
sinput string stoc_string="";                                           // параметры Stochastic 
input int    kPeriod = 5;                                               // К-период стохастика
input int    dPeriod = 3;                                               // D-период стохастика
input int    slow  = 3;                                                 // Сглаживание стохастика. Возможные значения от 1 до 3.
input int    top_level = 80;                                            // Top-level стохастка
input int    bottom_level = 20;                                         // Bottom-level стохастика

sinput string macd_string="";                                           // параметры MACD
input int fast_EMA_period = 12;                                         // быстрый период EMA для MACD
input int slow_EMA_period = 26;                                         // медленный период EMA для MACD
input int signal_period = 9;                                            // период сигнальной линии для MACD
input ENUM_APPLIED_PRICE applied_price=PRICE_CLOSE; // тип цены  

sinput string ema_string="";                                            // параметры для EMA
input int    periodEMAfastEld = 26;                                     // период быстрой   EMA на старшем таймфрейме 
input int    periodEMAfastJr = 9;                                       // период быстрой   EMA на младшем таймфрейме
input int    periodEMAslowJr = 15;                                      // период медленной EMA на младшем таймфрейме

sinput string pbi_string ="";                                           // параметры PriceBased indicator
input int    historyDepth = 1000;                                       // глубина истории для расчета
input double   percentage_ATR = 1;                                    // процент АТР для появления нового экстремума
input double   difToTrend = 1.5;                                        // разница между экстремумами для появления тренда

sinput string deal_string="";                                           // параметры сделок  
input double orderVolume = 0.1;                                         // Объём сделки
input int    sl = 100;                                             // Stop Loss
input int    tp = 100;                                             // Take Profit
input ENUM_USE_PENDING_ORDERS pending_orders_type = USE_NO_ORDERS;      // Тип отложенного ордера                    
input int    priceDifference = 50;                                      // Price Difference

/*
sinput string base_string ="";                                          // базовые параметры робота
input bool    useJrEMAExit = false;                                     // будем ли выходить по ЕМА
input int     posLifeTime = 10;                                         // время ожидания сделки в барах
input int     deltaPriceToEMA = 7;                                      // допустимая разница между ценой и EMA для пересечения
input int     deltaEMAtoEMA = 5;                                        // необходимая разница для разворота EMA
input int     waitAfterDiv = 4;                                         // ожидание сделки после расхождения (в барах)
*/
input        ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_PBI;      // тип трейлинга
input int    trStop = 100;                                              // Trailing Stop
input int    trStep = 100;                                              // Trailing Step
input int    minProfit = 250;                                           // Minimal Profit 

// объявление структур данных
sEmaParams    ema_params;          // параметры EMA
sMacdParams   macd_params;         // параметры MACD
sStocParams   stoc_params;         // параметры стохастика
sPbiParams    pbi_params;          // параметры PriceBased indicator
sDealParams   deal_params;          // параметры сделок
sBaseParams   base_params;          // базовые параметры

int handlePBI, handleMACD, handleStochastic, handleEMA3, handleEMAfast, handleEMAfastJr, handleEMAslowJr;

// глобальные объекты
CTradeManager  *ctm;                // указатель на объект класса TradeManager
CPointSys      *pointsys;           // указатель на объект класса бальной системы

// глобальные системные переменные
string symbol;                       // переменная для хранения символа
ENUM_TIMEFRAMES curTF, jrTF, eldTF;              // переменная для хранения таймфрейма
ENUM_TM_POSITION_TYPE deal_type;     // тип совершения сделки
ENUM_TM_POSITION_TYPE opBuy, opSell; // сигнал на покупку 

//+------------------------------------------------------------------+
//| функция иницициализации                                          |
//+------------------------------------------------------------------+
int OnInit()
{
  Print("ОнИнит");
  // сохраняем символ и период
  symbol = Symbol();
  curTF = Period();
  jrTF = GetBottomTimeframe(curTF);
  eldTF = GetTopTimeframe(curTF);
  
 ////// инициализаруем индикаторы
  handlePBI = iCustom(symbol, curTF, "PriceBasedIndicator", historyDepth, percentage_ATR, difToTrend);
  handleMACD = iMACD(symbol, curTF, fast_EMA_period,  slow_EMA_period, signal_period, applied_price);
  handleStochastic = iStochastic(symbol, curTF, kPeriod, dPeriod, slow, MODE_SMA, STO_LOWHIGH);
  handleEMA3 = iMA(symbol,  eldTF, 3, 0, MODE_EMA, PRICE_CLOSE);
  handleEMAfast = iMA(symbol,  curTF, periodEMAfastEld, 0, MODE_EMA, PRICE_CLOSE); 
  handleEMAfastJr = iMA(symbol,  jrTF, periodEMAfastJr, 0, MODE_EMA, PRICE_CLOSE);
  handleEMAslowJr = iMA(symbol,  jrTF, periodEMAslowJr, 0, MODE_EMA, PRICE_CLOSE);    

 //////// вспомогательные индикаторы
  int handleShowDivMACD = iCustom(symbol, curTF, "ShowMeYourDivMACD");
  int handleShowDivSto = iCustom(symbol, curTF, "ShowMeYourDivStachastic");
  
 /////// проверка создания хэндлов 
  if (handlePBI == INVALID_HANDLE || 
      handleEMA3 == INVALID_HANDLE ||
      handleEMAfast == INVALID_HANDLE ||
      handleEMAfastJr == INVALID_HANDLE || 
      handleEMAslowJr == INVALID_HANDLE || 
      handleMACD == INVALID_HANDLE || 
      handleStochastic    == INVALID_HANDLE   )
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s INVALID_HANDLE (handleTrend). Error(%d) = %s" 
                                         , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
  }   
   
 //------- заполняем структуры данных 
 // заполняем парметры EMA
  ema_params.handleEMA3 = handleEMA3;
  ema_params.handleEMAfast = handleEMAfast;
  ema_params.handleEMAfastJr = handleEMAfastJr;
  ema_params.handleEMAslowJr = handleEMAslowJr;
  
  // заполняем параметры MACD
  macd_params.handleMACD = handleMACD; 
  ///////////////////////////////////////////////////////////////
 
  // заполняем параметры Стохастика
  stoc_params.handleStochastic = handleStochastic;
  stoc_params.bottom_level = bottom_level;
  stoc_params.top_level = top_level;
  //////////////////////////////////////////////////////////////
  
  // заполняем параметры PBI
  pbi_params.handlePBI = handlePBI;
  pbi_params.historyDepth = historyDepth;
  //////////////////////////////////////////////////////////////
  
  // заполняем параметры сделок
  deal_params.minProfit    = minProfit;
  deal_params.orderVolume  = orderVolume;
  deal_params.sl           = sl;
  deal_params.tp           = tp;
  deal_params.trStep       = trStep;
  deal_params.trStop       = trStop;
  /////////////////////////////////////////////////////////////
  
  // заполняем базовые параметры
  base_params.eldTF                      = eldTF;
  base_params.curTF                      = curTF;
  base_params.jrTF                       = jrTF;
  /*
  base_params.deltaEMAtoEMA              = deltaEMAtoEMA;
  base_params.deltaPriceToEMA            = deltaPriceToEMA;
  base_params.posLifeTime                = posLifeTime;
  base_params.useJrEMAExit               = useJrEMAExit;
  base_params.waitAfterDiv               = waitAfterDiv;
  */
  //------- выделяем память под динамические объекты
  ctm      = new CTradeManager(); // выделяем память под объект класса TradeManager
  pointsys = new CPointSys(base_params,ema_params,macd_params,stoc_params,pbi_params);      // выделяем память под объект класса бальной системы  
   
  switch (pending_orders_type)  //вычисление priceDifference
  {
   case USE_LIMIT_ORDERS: //useLimitsOrders = true;
    opBuy  = OP_BUYLIMIT;
    opSell = OP_SELLLIMIT;
   break;
   case USE_STOP_ORDERS:
    opBuy  = OP_BUYSTOP;
    opSell = OP_SELLSTOP;
   break;
   case USE_NO_ORDERS:
    opBuy  = OP_BUY;
    opSell = OP_SELL;      
   break;
  }     
  
  return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| функция деиницициализации                                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(handlePBI);
   IndicatorRelease(handleEMAfast);
   IndicatorRelease(handleEMAfastJr);
   IndicatorRelease(handleEMAslowJr);
   IndicatorRelease(stoc_params.handleStochastic);
   IndicatorRelease(handleMACD);
   // очищаем память, выделенную под динамические объекты
   delete ctm;      // удаляем объект класса торговой библиотеки
   delete pointsys; // удаляем объект класса балльной системы*/
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
 int stopLoss = 0;
 ctm.OnTick();
 ctm.DoTrailing();  
 // пробуем обновить буферы
 int point = pointsys.GetFlatSignals();
 if (point >= 2)
 {
  if (ctm.GetPositionCount() == 0)
  {
   Print("point = ",point);
   stopLoss = CountStoploss(point);
   ctm.OpenUniquePosition(symbol,curTF, opBuy, orderVolume, stopLoss, 0, trailingType, minProfit, trStop, trStep, handlePBI, priceDifference);        
  }
  else
  {
   ctm.PositionChangeSize(symbol, orderVolume);
  }
 }
 if (point <= -2)
 {
  if (ctm.GetPositionCount() == 0)
  {
   Print("point = ",point);
   stopLoss = CountStoploss(point);
   ctm.OpenUniquePosition(symbol,curTF, opSell, orderVolume, stopLoss, 0, trailingType, minProfit, trStop, trStep, handlePBI, priceDifference);        
  }
  else
  {
   ctm.PositionChangeSize(symbol, orderVolume);
  }
 }
}

int CountStoploss(int point)
{
 int stopLoss = 0;
 int direction;
 double priceAB;
 double bufferStopLoss[];
 ArraySetAsSeries(bufferStopLoss, true);
 ArrayResize(bufferStopLoss, pbi_params.historyDepth);
 
 int extrBufferNumber;
 if (point > 0)
 {
  extrBufferNumber = 6;
  priceAB = SymbolInfoDouble(symbol, SYMBOL_ASK);
  direction = 1;
 }
 else
 {
  extrBufferNumber = 5; // Если point > 0 возьмем буфер с минимумами, иначе с максимумами
  priceAB = SymbolInfoDouble(symbol, SYMBOL_BID);
  direction = -1;
 }
 
 int copiedPBI = -1;
 for(int attempts = 0; attempts < 25; attempts++)
 {
  Sleep(100);
  copiedPBI = CopyBuffer(pbi_params.handlePBI, extrBufferNumber, 0, pbi_params.historyDepth, bufferStopLoss);
 }
 if (copiedPBI < 0)
 {
  PrintFormat("%s Не удалось скопировать буфер bufferStopLoss", MakeFunctionPrefix(__FUNCTION__));
  return(false);
 }
 
 for(int i = 0; i < pbi_params.historyDepth; i++)
 {
  if (bufferStopLoss[i] > 0)
  {
   Print("Найден экстремум");
   if (LessDoubles(direction*bufferStopLoss[i], direction*priceAB))
   {
    Print("Экстремум (%.05f) меньше цены (%.05f)");
    stopLoss = (int)(MathAbs(bufferStopLoss[i] - priceAB)/Point()) + ADD_TO_STOPPLOSS;
    break;
   }
  }
 }
 
 if (stopLoss <= 0)
 {
  PrintFormat("Не поставили стоп на экстремуме");
  stopLoss = SymbolInfoInteger(symbol, SYMBOL_SPREAD) + ADD_TO_STOPPLOSS;
 }
 PrintFormat("%s StopLoss = %d",MakeFunctionPrefix(__FUNCTION__), stopLoss);
 return(stopLoss);
}

/*
/////////////////////////////////////
/////////////////////////////////////
double iHigh(string symbol,ENUM_TIMEFRAMES timeframe,int index)
  {
   double high=0;
   ArraySetAsSeries(High,true);
   int copied=CopyHigh(symbol,timeframe,0,Bars(symbol,timeframe),High);
   if(copied>0 && index<copied) high=High[index];
   return(high);
  }


int iHighest(string symbol,ENUM_TIMEFRAMES tf,int count=WHOLE_ARRAY,int start=0)
  {
      double High[];
      ArraySetAsSeries(High,true);
      CopyHigh(symbol,tf,start,count,High);
      return(ArrayMaximum(High,0,count)+start);
     
     return(0);
}

double iLow(string symbol,ENUM_TIMEFRAMES timeframe,int index)
  {
   double low=0;
   ArraySetAsSeries(Low,true);
   int copied=CopyLow(symbol,timeframe,0,Bars(symbol,timeframe),Low);
   if(copied>0 && index<copied) low=Low[index];
   return(low);
  }


int iLowest(string symbol,ENUM_TIMEFRAMES tf,int count=WHOLE_ARRAY,int start=0)
  {
      double Low[];
      ArraySetAsSeries(Low,true);
      CopyLow(symbol,tf,start,count,Low);
      return(ArrayMinimum(Low,0,count)+start);
     
     return(0);
}*/