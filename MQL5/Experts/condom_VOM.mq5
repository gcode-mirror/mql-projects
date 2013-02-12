//+------------------------------------------------------------------+
//|                                                   condom_VOM.mq5 |
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
#include <VOM\VirtualOrderManager.mqh>

//+------------------------------------------------------------------+
//| Expert variables                                                 |
//+------------------------------------------------------------------+
input ulong _magic = 1122;
input int SL = 150;
input int TP = 500;
input double _lot = 1;
input int historyDepth = 40;
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

MqlTick tick;

int total;  // количество ордеров
int handleMACD;
double MACD_buf[1], high_buf[], low_buf[], close_buf[2];

double globalMax;
double globalMin;
bool waitForSell;
bool waitForBuy;
long positionType;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if (trailing)
   {
    VOM.Initialise(-1, minProfit, trailingStop, trailingStep);
   }
   else
   {
    VOM.Initialise();
   }

   my_symbol=Symbol();                                             //сохраним текущий символ графика для дальнейшей работы советника именно на этом символе
   my_timeframe=timeframe;                                      //сохраним текущий таймфрейм графика для дальнейшей работы советника именно на этом таймфрейме
   
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

   globalMax = 0;
   globalMin = 0;
   waitForSell = false;
   waitForBuy = false;
   positionType = -1;
   
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // Освобождаем динамические массивы от данных
   ArrayFree(MACD_buf);
   ArrayFree(low_buf);
   ArrayFree(high_buf);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   VOM.OnTick();
   double ask = SymbolInfoDouble(my_symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(my_symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(my_symbol, SYMBOL_POINT);
   int deviation = SymbolInfoInteger(my_symbol,SYMBOL_SPREAD);

   //переменные для хранения результатов работы с ценовым графиком
   int errLow = 0;                                                   
   int errHigh = 0;                                                   
   int errClose = 0;
   int errMACD = 0;
   int i = 0;   // счетчик
   
   static CIsNewBar isNewBar;
   
   if(isNewBar.isNewBar(my_symbol, my_timeframe))
   {
    if (tradeOnTrend)
    {
     //копируем данные из индикаторного массива в динамический массив MACD_buf для дальнейшей работы с ними
     errMACD=CopyBuffer(handleMACD, 0, 1, 1, MACD_buf);
     //Print("MACD_buf[0] = ", MACD_buf[0]); 
     if(errMACD < 0)
     {
      Alert("Не удалось скопировать данные из индикаторного буфера"); 
      return; 
     }
    } 
    //копируем данные ценового графика в динамические массивы для дальнейшей работы с ними
    errLow=CopyLow(my_symbol, my_timeframe, 2, historyDepth, low_buf);
    errHigh=CopyHigh(my_symbol, my_timeframe, 2, historyDepth, high_buf);
    errClose=CopyClose(my_symbol, my_timeframe, 1, 2, close_buf);
             
    if(errLow < 0 || errHigh < 0 || errClose < 0)                                            //если есть ошибки
    {
     Alert("Не удалось скопировать данные из буфера ценового графика");  //то выводим сообщение в лог об ошибке
     return;                                                                                      //и выходим из функции
    }
    
    globalMax = high_buf[ArrayMaximum(high_buf)];
    globalMin = low_buf[ArrayMinimum(low_buf)];
    //Alert("max = ", globalMax, " min= ", globalMin, " close_buf[0] = ", close_buf[0], " close_buf[1]= ", close_buf[1]);
    
    if(close_buf[1] < globalMin)
    {
     waitForSell = false;
     waitForBuy = true;
     //Alert("WTB");
    }
    
    if(close_buf[1] > globalMax)
    {
     waitForBuy = false;
     waitForSell = true;
     //Alert("WTS");
    }
   }
   
   if (tradeOnTrend)
   {
    if (GreatDoubles(MACD_buf[0], levelMACD) || LessDoubles (MACD_buf[0], -levelMACD))
    {
     if (trailing)
     {
      VOM.DoTrailing(my_symbol);
     }
     return;
    }
   }
   
   if(!SymbolInfoTick(Symbol(),tick))
   {
    Alert("SymbolInfoTick() failed, error = ",GetLastError());
   }
   
   total = VOM.OrdersTotal();
   
   if (waitForBuy)
   { 
    if (tick.ask > close_buf[0] && tick.ask > close_buf[1])
    {
     if (total <= 0)
     {
      VOM.OrderSend(my_symbol, VIRTUAL_ORDER_TYPE_BUY, _lot, ask, deviation, bid - SL*point, ask + TP*point);
     }
     else
     {
      for (i=0; i<total; i++)
      {
       if(VOM.OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
       {
        if (VOM.OrderMagicNumber() == VOM.MagicNumber())  
        {
         if (VOM.OrderType() == VIRTUAL_ORDER_TYPE_SELL)   // Открыта короткая позиция SELL
         {
          VOM.OrderClose(VOM.OrderTicket(), deviation, clrRed); // закрываем позицию SELL
          VOM.OrderSend(my_symbol, VIRTUAL_ORDER_TYPE_BUY, _lot, ask, deviation, bid - SL*point, ask + TP*point);
         }
        }
       }
      }
     }
     waitForBuy = false;
     waitForSell = false;
    }
   } 

   if (waitForSell)
   { 
    if (tick.bid < close_buf[0] && tick.bid < close_buf[1])
    {
     if (total <= 0)
     {
      VOM.OrderSend(my_symbol, VIRTUAL_ORDER_TYPE_SELL, _lot, bid, deviation, ask + SL*point, bid - TP*point);
     }
     else
     {
      for (i=0; i<total; i++)
      {
       if(VOM.OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
       {
        if (VOM.OrderMagicNumber() == VOM.MagicNumber())  
        {
         if (VOM.OrderType() == VIRTUAL_ORDER_TYPE_BUY)   // Открыта длинная позиция BUY
         {
          VOM.OrderClose(VOM.OrderTicket(), deviation, clrRed); // закрываем позицию BUY
          VOM.OrderSend(my_symbol, VIRTUAL_ORDER_TYPE_SELL, _lot, bid, deviation, ask + SL*point, bid - TP*point);
         }
        }
       }
      }
     }
     waitForBuy = false;
     waitForSell = false;
    }
   } 
   
   if (trailing)
   {
    VOM.DoTrailing(my_symbol);
   }
   return;   
  }
//+------------------------------------------------------------------+

