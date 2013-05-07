//+------------------------------------------------------------------+
//|                                            FollowWhiteRabbit.mq5 |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert includes                                                  |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh> //подключаем библиотеку для совершения торговых операций
#include <Trade\PositionInfo.mqh> //подключаем библиотеку для получения информации о позициях
#include <CompareDoubles.mqh>
#include <CIsNewBar.mqh>
#include <TradeManager\CTradeManager.mqh>

//+------------------------------------------------------------------+
//| Expert variables                                                 |
//+------------------------------------------------------------------+
input ulong _magic = 1122;
input int SL = 150;
input int TP = 500;
input double _lot = 1;
input int historyDepth = 40;
input double supremacyPercent = 0.2;
input ENUM_TIMEFRAMES timeframe = PERIOD_M1;
input bool trailing = false;
input int minProfit = 250;
input int trailingStop = 150;
input int trailingStep = 5;
input bool tradeOnTrend = false;
input int fastMACDPeriod = 12;
input int slowMACDPeriod = 26;
input int signalPeriod = 9;
input double levelMACD = 0.02;

string my_symbol;                                       //переменная для хранения символа
ENUM_TIMEFRAMES my_timeframe;                                    //переменная для хранения младшего таймфрейма

CTradeManager order(_magic, Symbol(), timeframe, SL, TP, minProfit, trailingStop, trailingStep);
MqlTick tick;

int handleMACD;
double MACD_buf[1], high_buf[], low_buf[], close_buf[1], open_buf[1];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   my_symbol=Symbol();                                             //сохраним текущий символ графика для дальнейшей работы советника именно на этом символе
   
   if (tradeOnTrend)
   {
    handleMACD = iMACD(my_symbol, my_timeframe, fastMACDPeriod, slowMACDPeriod, signalPeriod, PRICE_CLOSE);  //подключаем индикатор и получаем его хендл
    if(handleMACD == INVALID_HANDLE)                                  //проверяем наличие хендла индикатора
    {
     Print("Не удалось получить хендл MACD");               //если хендл не получен, то выводим сообщение в лог об ошибке
     return(-1);                                                  //завершаем работу с ошибкой
    }
   }

   //устанавливаем индексацию для массивов ХХХ_buf
   ArraySetAsSeries(MACD_buf, false);
   ArraySetAsSeries(low_buf, false);
   ArraySetAsSeries(high_buf, false);
   ArraySetAsSeries(close_buf, false);
   ArraySetAsSeries(open_buf, false);
   
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // Освобождаем динамические массивы от данных
   ArrayFree(low_buf);
   ArrayFree(high_buf);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   //переменные для хранения результатов работы с ценовым графиком
   int errLow = 0;                                                   
   int errHigh = 0;                                                   
   int errClose = 0;
   int errOpen = 0;
   int errMACD = 0;
   
   double sum = 0;
   double avgBar = 0;
   double lastBar = 0;
   int i = 0;   // счетчик
   long positionType;

   static CIsNewBar isNewBar;
   
   if(isNewBar.isNewBar(my_symbol, my_timeframe))
   {
    if (tradeOnTrend)
    {
     //копируем данные из индикаторного массива в динамический массив MACD_buf для дальнейшей работы с ними
     errMACD = CopyBuffer(handleMACD, 0, 1, 1, MACD_buf);
     //Print("MACD_buf[0] = ", MACD_buf[0]); 
     if(errMACD < 0)
     {
      Alert("Не удалось скопировать данные из индикаторного буфера"); 
      return; 
     }
    } 
    //копируем данные ценового графика в динамические массивы для дальнейшей работы с ними
    errLow = CopyLow(my_symbol, my_timeframe, 1, historyDepth, low_buf);
    errHigh = CopyHigh(my_symbol, my_timeframe, 1, historyDepth, high_buf);
    errClose = CopyClose(my_symbol, my_timeframe, 1, 1, close_buf);          
    errOpen = CopyOpen(my_symbol, my_timeframe, 1, 1, open_buf);
    
    if(errLow < 0 || errHigh < 0 || errClose < 0 || errOpen < 0)         //если есть ошибки
    {
     Alert("Не удалось скопировать данные из буфера ценового графика");  //то выводим сообщение в лог об ошибке
     return;                                                                                      //и выходим из функции
    }
    
    for(i = 0; i < historyDepth; i++)
    {
     //Print("high_buf[",i,"] = ", NormalizeDouble(high_buf[i],8), " low_buf[",i,"] = ", NormalizeDouble(low_buf[i],8));
     sum = sum + high_buf[i] - low_buf[i];  
    }
    avgBar = sum / historyDepth;
    lastBar = high_buf[i-1] - low_buf[i-1];
    
    if(GreatDoubles(lastBar, avgBar*(1 + supremacyPercent)))
    {
     Print("last bar = ", NormalizeDouble(lastBar,8), " avg Bar = ", NormalizeDouble(avgBar,8));
     if(!SymbolInfoTick(Symbol(),tick))
     {
      Alert("SymbolInfoTick() failed, error = ",GetLastError());
     }
   
     if(PositionSelect(my_symbol))
     {
      positionType = PositionGetInteger(POSITION_TYPE);
     }
     else
     {
      positionType = -1;
     }
     
     if(close_buf[0] < open_buf[0])
     {
      if (positionType == POSITION_TYPE_BUY)
      {
       Alert("WTS, positionType =",positionType);
       order.SendOrder(ORDER_TYPE_SELL, _lot*2);
      }
      if (positionType == -1)
      {
       Alert("WTS, positionType =",positionType);
       order.SendOrder(ORDER_TYPE_SELL, _lot);
      } 
     }
     
     if(close_buf[0] > open_buf[0])
     {
      if (positionType == POSITION_TYPE_SELL)
      { 
       Alert("WTB, positionType =",positionType);
       order.SendOrder(ORDER_TYPE_BUY, _lot*2);
      }
      if (positionType == -1)
      {
       Alert("WTB, positionType =",positionType);
       order.SendOrder(ORDER_TYPE_BUY, _lot);
      }      
     }
    }
   }
   
   if (trailing)
   {
    order.DoTrailing();
   }
   return;   
  }
//+------------------------------------------------------------------+
