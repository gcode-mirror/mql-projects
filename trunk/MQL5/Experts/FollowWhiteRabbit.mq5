//+------------------------------------------------------------------+
//|                                            FollowWhiteRabbit.mq5 |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Эксперт FollowWhiteRabbit                                        |
//+------------------------------------------------------------------+
// подключение необходимых библиотек
#include <Lib CIsNewBar.mqh>
#include <TradeManager\TradeManager.mqh> 
// константы
#define ADD_TO_STOPLOSS 50 
#define DEPTH 30
#define SPREAD 30
// вводимые пользователем параметры
input string baseParams = "";                                                   // БАЗОВЫЕ ПАРАМЕТРЫ
input double M1_supremacyPercent  = 5;
input double M5_supremacyPercent  = 3;
input double M15_supremacyPercent = 1;
input double profitPercent = 0.5;                                               
input string trailParams = "";                                                  // ПАРАМЕТРЫ ТРЕЙЛИНГА
input ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_PBI;                      // тип трейлинга
input int minProfit = 250;                                                      // минимальная прибыль
input int trailingStop = 150;                                                   // трейлинг стоп
input int trailingStep = 5;                                                     // шаг трейлинга
input string orderParams = "";                                                  // ПАРАМЕТРЫ ОРДЕРОВ
input ENUM_USE_PENDING_ORDERS pending_orders_type = USE_LIMIT_ORDERS;           // Тип отложенного ордера                    
input int priceDifference = 50;                                                 // Price Difference
// глобальные переменные 
datetime history_start;
//торговый класс
CTradeManager ctm;          
// массивы
double ave_atr_buf[1], close_buf[1], open_buf[1], pbi_buf[1];

ENUM_TM_POSITION_TYPE opBuy, opSell;

CisNewBar *isNewBarM1;
CisNewBar *isNewBarM5;
CisNewBar *isNewBarM15;
// хэндлы индикаторов
int handle_PBI;
int handle_aATR_M1;
int handle_aATR_M5;
int handle_aATR_M15;
// параметры позиции и трейлинга
SPositionInfo pos_info;
STrailing     trailing;

double volume = 1.0;
//+------------------------------------------------------------------+
//| Инициализация эксперта                                           |
//+------------------------------------------------------------------+

int OnInit()
  {
   history_start=TimeCurrent();        //--- запомним время запуска эксперта для получения торговой истории

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
   
   // создаем объекты класса для обнаружения появления нового бара
   isNewBarM1      = new CisNewBar(_Symbol, PERIOD_M1);
   isNewBarM5      = new CisNewBar(_Symbol, PERIOD_M5);
   isNewBarM15     = new CisNewBar(_Symbol, PERIOD_M15);
   // создаем хэндл PriceBasedIndicator
   handle_PBI      = iCustom(_Symbol, PERIOD_M15, "PriceBasedIndicator");
   handle_aATR_M1  = iMA(_Symbol,  PERIOD_M1, 100, 0, MODE_EMA, iATR(_Symbol,  PERIOD_M1,  30));
   handle_aATR_M5  = iMA(_Symbol,  PERIOD_M5, 100, 0, MODE_EMA, iATR(_Symbol,  PERIOD_M5,  30)); 
   handle_aATR_M15 = iMA(_Symbol, PERIOD_M15, 100, 0, MODE_EMA, iATR(_Symbol,  PERIOD_M15, 30));  
     
   if ( handle_PBI == INVALID_HANDLE )
    {
     PrintFormat("%s Не удалось получить хэндл одного из вспомогательных индикаторов", MakeFunctionPrefix(__FUNCTION__));
    }       
     
   trailing.trailingType      = trailingType;
   trailing.minProfit         = minProfit;
   trailing.trailingStop      = trailingStop;
   trailing.trailingStep      = trailingStep;
   trailing.handleForTrailing = handle_PBI;
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

  }

void OnTick()
  {
   ctm.OnTick();
   pos_info.type = OP_UNKNOWN;
   if(isNewBarM1.isNewBar())
   {
    GetTradeSignal(PERIOD_M1, handle_aATR_M1, M1_supremacyPercent, pos_info); //свой коэффициент
   }
   if(isNewBarM5.isNewBar())
   {
    GetTradeSignal(PERIOD_M5, handle_aATR_M5, M5_supremacyPercent, pos_info);
   }  
   if(isNewBarM15.isNewBar())
   {
    GetTradeSignal(PERIOD_M15, handle_aATR_M15, M15_supremacyPercent, pos_info);
   }
   if (pos_info.type == opBuy || pos_info.type == opSell)
    {
     ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing,SPREAD);
    }
  }

void OnTrade()
  {
   ctm.OnTrade();
   if (history_start != TimeCurrent())
   {
    history_start = TimeCurrent() + 1;
   }
  }

// функция получения торгового сигнала (возвращает заполненную структуру позиции) 
void GetTradeSignal(ENUM_TIMEFRAMES tf, int handle_atr, double supremacyPercent,SPositionInfo &pos)
{   
 // если не удалось прогрузить все буферы 
 if ( CopyClose  (_Symbol,tf,1,1, close_buf)    < 1 ||
      CopyOpen   (_Symbol,tf,1,1,open_buf)      < 1 ||
      CopyBuffer (handle_atr,0,0,1,ave_atr_buf) < 1 )
 {
  Print("Не удалось скопировать данные из буфера ценового графика");  //то выводим сообщение в лог об ошибке
  return;                                                 //и выходим из функции
 }
 // если не удалось прогрузить буфер PBI  
 if( CopyBuffer(handle_PBI,4,1,1,pbi_buf) < 1)   
 {
  Print("Не удалось скопировать данные из вспомогательного индикатора");  //то выводим сообщение в лог об ошибке
  return;                                                                 //и выходим из функции
 }
   
 if(GreatDoubles(MathAbs(open_buf[0] - close_buf[0]), ave_atr_buf[0]*(1 + supremacyPercent)))
 {
  if(LessDoubles(close_buf[0], open_buf[0])) // на последнем баре close < open (бар вниз)
  {  
 //  Print("Получили торговый сигнал SELL");
   pos.type = opSell;
   pos.sl = CountStoploss(-1);
  }
  if(GreatDoubles(close_buf[0], open_buf[0]))
  { 
 //  Print("Получили торговый сигнал BUY");
   pos.type = opBuy;
   pos.sl = CountStoploss(1);
  }
   pos.tp = (int)MathCeil((MathAbs(open_buf[0] - close_buf[0]) / _Point) * (1 + profitPercent));
   pos.expiration = 0; 
   pos.expiration_time = 0;
   pos.volume     = volume;
   pos.priceDifference = priceDifference; 
  }
  ArrayInitialize(ave_atr_buf, EMPTY_VALUE);
  ArrayInitialize(close_buf,   EMPTY_VALUE);
  ArrayInitialize(open_buf,    EMPTY_VALUE);
  ArrayInitialize(pbi_buf,     EMPTY_VALUE);
  return;
}
  
// функция вычисляет стоп лосс
int CountStoploss(int point)
{
 int stopLoss = 0;
 int direction;
 double priceAB;
 double bufferStopLoss[];
 ArraySetAsSeries(bufferStopLoss, true);
 ArrayResize(bufferStopLoss, DEPTH);
 int extrBufferNumber;
 if (point > 0)
 {
  extrBufferNumber = 6; //minimum
  priceAB = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
  direction = 1;
 }
 else
 {
  extrBufferNumber = 5; // maximum
  priceAB = SymbolInfoDouble(_Symbol, SYMBOL_BID);
  direction = -1;
 }
 int copiedPBI = -1;
 for(int attempts = 0; attempts < 25; attempts++)
 {
  Sleep(100);
  copiedPBI = CopyBuffer(handle_PBI, extrBufferNumber, 0,DEPTH, bufferStopLoss);
 }
 if (copiedPBI < DEPTH)
 {
  PrintFormat("%s Не удалось скопировать буфер bufferStopLoss", MakeFunctionPrefix(__FUNCTION__));
  return(0);
 }
 for(int i = 0; i < DEPTH; i++)
 {
  if (bufferStopLoss[i] > 0)
  {
   if (LessDoubles(direction*bufferStopLoss[i], direction*priceAB))
   {
    PrintFormat("price = %f; extr = %f", priceAB, bufferStopLoss[i]);
    stopLoss = (int)(MathAbs(bufferStopLoss[i] - priceAB)/Point());// + ADD_TO_STOPPLOSS;
    break;
   }
  }
 }
 if (stopLoss <= 0)  
 {
  PrintFormat("Не поставили стоп на экстремуме");
  stopLoss = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) + ADD_TO_STOPLOSS;
 }
 return(stopLoss);
}