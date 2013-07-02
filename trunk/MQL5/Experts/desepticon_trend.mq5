//+------------------------------------------------------------------+
//|                                           fast-start-example.mq5 |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert includes                                                  |
//+------------------------------------------------------------------+
//-------------------Include----------------------------------------
#include <Trade\Trade.mqh>                                         //подключаем библиотеку для совершения торговых операций
#include <Trade\PositionInfo.mqh>                                  //подключаем библиотеку для получения информации о позициях
#include <CisNewBar.mqh>                                           //подключаем библиотеку для получения информации о появлении нового бара
#include <DesepticonTrendCriteria.mqh>                             //подключаем библиотеку для поиска направлений тренда
#include <CompareDoubles.mqh>
//-------------------Define-----------------------------------------
#define JUNIOR 0                                                   //индекс младшего таймфрейма в массиве TrendDirection
#define ELDER  1                                                   //индекс старшего таймфрейма в массиве TrendDirection
#define CURRENT 0                                                  //для обращения к текущему направлению тренда в массиве TrendDirection
#define HISTORY 1                                                  //для обращения к предыдущему направлению тренда в массиве TrendDirection     
//+------------------------------------------------------------------+
//| Expert variables                                                 |
//+------------------------------------------------------------------+
input int jrfastEMA = 12;
input int jrslowEMA = 26;
input int eldfastEMA = 12;
input int eldslowEMA = 26;
input int fastMACDperiod = 12;
input int slowMACDperiod = 26;
input int deltaEMAtoEMA = 0;
input int deltaPricetoEMA = 0;
input double channelJrMACD = 0.0002;
input double channelEldMACD = 0.002;
input int stoploss = 200;
input int takeprofit = 800;

//JUNIOR
int             iMA_fast_jr_handle;                                 //переменная для хранения хендла индикатора
int             iMA_slow_jr_handle;                                 //переменная для хранения хендла индикатора
int             iMACD_jr_handle;                                    //переменная для хранения хендла индикатора

double          iMA_fast_jr_buf[2];                                  //массив для хранения значений индикатора
double          iMA_slow_jr_buf[2];                                  //массив для хранения значений индикатора
double          Close_jr_buf[2];                                     //массив для хранения цены закрытия каждого бара младшего ТФ

//ELDER
int             iMA_fast_eld_handle;                                 //переменная для хранения хендла индикатора
int             iMA_slow_eld_handle;                                 //переменная для хранения хендла индикатора
int             iMACD_eld_handle;                                    //переменная для хранения хендла индикатора

double          iMA_fast_eld_buf[2];                                  //массив для хранения значений индикатора
double          iMA_slow_eld_buf[2]; 
double          Close_eld_buf[2];                                     //массив для хранения цены закрытия каждого бара старшего ТФ
double          Low_eld_buf[2];                                       //массив для хранения минимальных цен каждого бара старшего ТФ
double          High_eld_buf[2];                                      //массив для хранения максимальных каждого бара старшего ТФ 


int             iMA_daily_handle;
double          iMA_daily_buf[1];
string          my_symbol;                                           //переменная для хранения символа
ENUM_TIMEFRAMES my_jr_timeframe;                                     //переменная для хранения младшего таймфрейма
ENUM_TIMEFRAMES my_eld_timeframe;                                    //переменная для хранения старшего таймфрейма

int             trendDirection[2][2];                                //массив хранящий направления трендов на обоих таймфреймах. [TIMEFRAME][CURRENT | HISTORY]

CTrade          m_Trade;                                         //класс для выполнения торговых операций
CPositionInfo   m_Position;                                      //класс для получения информации о позициях
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   Alert("Инициализация.");
   my_symbol = Symbol();                  //сохраним текущий символ графика для дальнейшей работы советника именно на этом символе
   my_jr_timeframe = PERIOD_M5;                                    
   my_eld_timeframe = PERIOD_H1;                                   
   iMA_fast_jr_handle  = iMA(my_symbol,  my_jr_timeframe,  jrfastEMA, 0, MODE_SMA, PRICE_CLOSE);  //подключаем индикатор и получаем его хендл
   iMA_slow_jr_handle  = iMA(my_symbol,  my_jr_timeframe,  jrslowEMA, 0, MODE_SMA, PRICE_CLOSE);  //подключаем индикатор и получаем его хендл
   iMA_fast_eld_handle = iMA(my_symbol, my_eld_timeframe, eldfastEMA, 0, MODE_SMA, PRICE_CLOSE);  //подключаем индикатор и получаем его хендл
   iMA_slow_eld_handle = iMA(my_symbol, my_eld_timeframe, eldslowEMA, 0, MODE_SMA, PRICE_CLOSE);  //подключаем индикатор и получаем его хендл
   iMA_daily_handle = iMA(my_symbol, PERIOD_D1, 3, 0, MODE_SMA, PRICE_CLOSE);
   iMACD_jr_handle  = iMACD(my_symbol,  my_jr_timeframe, fastMACDperiod, slowMACDperiod, 9, PRICE_CLOSE);
   iMACD_eld_handle = iMACD(my_symbol, my_eld_timeframe, fastMACDperiod, slowMACDperiod, 9, PRICE_CLOSE);
   if( iMA_fast_jr_handle == INVALID_HANDLE ||  iMA_slow_jr_handle == INVALID_HANDLE ||
      iMA_fast_eld_handle == INVALID_HANDLE || iMA_slow_eld_handle == INVALID_HANDLE ||
          iMACD_jr_handle == INVALID_HANDLE ||    iMACD_eld_handle == INVALID_HANDLE ||
         iMA_daily_handle == INVALID_HANDLE )
   {
      Print("Не удалось получить хендл индикатора");                     //если хендл не получен, то выводим сообщение в лог об ошибке
      return(INIT_FAILED);                                               //завершаем работу с ошибкой
   }
   //Alert(__FUNCTION__, ";JR@hMACD = ", iMACD_jr_handle, "; hF_EMA = ", iMA_fast_jr_handle, "; hS_EMA = ", iMA_slow_jr_handle);
   //Alert(__FUNCTION__, ";ELD@hMACD = ", iMACD_eld_handle, "; hF_EMA = ", iMA_fast_eld_handle, "; hS_EMA = ", iMA_slow_eld_handle);
   trendDirection[JUNIOR][CURRENT] = InitTrendDirection( iMACD_jr_handle,  iMA_fast_jr_handle,  iMA_slow_jr_handle, deltaEMAtoEMA, channelJrMACD);
   trendDirection[ELDER][CURRENT]  = InitTrendDirection(iMACD_eld_handle, iMA_fast_eld_handle, iMA_slow_eld_handle, deltaEMAtoEMA, channelEldMACD);
   
   //ChartIndicatorAdd(ChartID(),0,iMA_handle);                      //добавляем индикатор на ценовой график
   ArraySetAsSeries(iMA_fast_jr_buf,true);                           //устанавливаем индексация для массива iMA_buf как в таймсерии
   ArraySetAsSeries(iMA_slow_jr_buf,true);                           //устанавливаем индексация для массива iMA_buf как в таймсерии
   ArraySetAsSeries(iMA_fast_eld_buf,true);                          //устанавливаем индексация для массива iMA_buf как в таймсерии
   ArraySetAsSeries(iMA_slow_eld_buf,true);                          //устанавливаем индексация для массива iMA_buf как в таймсерии
   ArraySetAsSeries(Close_jr_buf,true);                              //устанавливаем индексация для массива Close_buf как в таймсерии
   ArraySetAsSeries(Close_eld_buf,true);                             //устанавливаем индексация для массива Close_buf как в таймсерии
   ArraySetAsSeries(iMA_daily_buf,true);                             //устанавливаем индексация для массива iMA_buf как в таймсерии   
   return(INIT_SUCCEEDED);                                           //возвращаем 0, инициализация завершена
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Alert("Деинициализация.");
   IndicatorRelease(iMA_fast_jr_handle);                              //удаляет хэндл индикатора и освобождает память занимаемую им
   IndicatorRelease(iMA_slow_jr_handle);                              //удаляет хэндл индикатора и освобождает память занимаемую им
   IndicatorRelease(iMA_fast_eld_handle);                             //удаляет хэндл индикатора и освобождает память занимаемую им
   IndicatorRelease(iMA_slow_eld_handle);                             //удаляет хэндл индикатора и освобождает память занимаемую им
   IndicatorRelease(iMACD_jr_handle);                                 //удаляет хэндл индикатора и освобождает память занимаемую им
   IndicatorRelease(iMACD_eld_handle);                                //удаляет хэндл индикатора и освобождает память занимаемую им
   IndicatorRelease(iMA_daily_handle);                                //удаляет хэндл индикатора и освобождает память занимаемую им
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   
   static CIsNewBar isNewBarEld;
   static CIsNewBar isNewBarJr;
   
   if (CopyHigh(my_symbol, my_eld_timeframe, 1, 2, High_eld_buf) < 0 ||
       CopyLow (my_symbol, my_eld_timeframe, 1, 2, Low_eld_buf)  < 0 ||
       CopyClose(my_symbol,  my_jr_timeframe, 1, 2,  Close_jr_buf) < 0 ||
       CopyClose(my_symbol, my_eld_timeframe, 1, 2, Close_eld_buf) < 0 ||
       CopyBuffer(   iMA_daily_handle, 0, 0, 1,    iMA_daily_buf) < 0 ||
       CopyBuffer(iMA_fast_eld_handle, 0, 1, 2, iMA_fast_eld_buf) < 0 ||
       CopyBuffer(iMA_slow_eld_handle, 0, 1, 2, iMA_slow_eld_buf) < 0 ||  
       CopyBuffer( iMA_fast_jr_handle, 0, 1, 2,  iMA_fast_jr_buf) < 0 ||
       CopyBuffer( iMA_slow_jr_handle, 0, 1, 2,  iMA_slow_jr_buf) < 0 ) 
   {
     Print("Не удалось скопировать данные из индикаторного буфера или буфера ценового графика");  //то выводим сообщение в лог об ошибке
     return;       
   }

//--------------------------------------
// новый бар на старшем ТФ
//--------------------------------------   
   if(isNewBarEld.isNewBar(my_symbol, my_eld_timeframe))
   {
    trendDirection[ELDER][CURRENT] = TwoTitsCriteria(iMACD_eld_handle, iMA_fast_eld_handle, iMA_slow_eld_handle, deltaEMAtoEMA, channelEldMACD, trendDirection[ELDER][CURRENT], trendDirection[ELDER][HISTORY]);
    //обработка случая коррекции
   }
   
//--------------------------------------
// новый бар на младшем ТФ
//--------------------------------------   
   if(isNewBarJr.isNewBar(my_symbol, my_jr_timeframe))
   {
    trendDirection[JUNIOR][CURRENT] = TwoTitsCriteria(iMACD_jr_handle, iMA_fast_jr_handle, iMA_slow_jr_handle, deltaEMAtoEMA, channelJrMACD, trendDirection[JUNIOR][CURRENT], trendDirection[JUNIOR][HISTORY]);
    if(trendDirection[JUNIOR][CURRENT] > 0) // Есть тренд вверх на младшем таймфрейме
    { 
     trendDirection[JUNIOR][HISTORY] = 1;
    } 
    else if(trendDirection[JUNIOR][CURRENT] < 0) // Есть тренд вниз на младшем таймфрейме
    {
     trendDirection[JUNIOR][HISTORY] = -1;
    }
    else if(trendDirection[JUNIOR][CURRENT] == 0) // если на младшем флэт не торгуем
    {
     //Alert("флэт на младшем");
     return; // торговать все равно не будем
    }
   }
   
//--------------------------------------
// Большой тренд вверх
//--------------------------------------
   if(trendDirection[ELDER][CURRENT] > 0)
   {
    trendDirection[ELDER][HISTORY] = 1;
    //проверка на коррекцию вверх
    if(LessDoubles(bid, iMA_daily_buf[0] + deltaPricetoEMA*point))
    {
     if(LessDoubles(Low_eld_buf[0], iMA_fast_eld_buf[0] + deltaPricetoEMA*point) &&
        LessDoubles(Low_eld_buf[1], iMA_fast_eld_buf[1] + deltaPricetoEMA*point))
     {
      if(GreatDoubles(iMA_fast_jr_buf[0], iMA_slow_jr_buf[0]) &&
          LessDoubles(iMA_fast_jr_buf[1], iMA_slow_jr_buf[1]))
      {
       if(m_Position.Select(my_symbol))                             //если уже существует позиция по этому символу
       {

        if(m_Position.PositionType()==POSITION_TYPE_SELL)
        {
         Alert("Закрываем позицию SELL. Тренд вверх.");
         m_Trade.PositionClose(my_symbol);  //и тип этой позиции Sell, то закрываем ее
        }
        if(m_Position.PositionType()==POSITION_TYPE_BUY)  return;                            //а если тип этой позиции Buy, то выходим
       }
       Alert("Открываем позицию BUY");
       //m_Trade.Buy(1, my_symbol);
       m_Trade.Buy(1, my_symbol, ask, bid-stoploss*point, ask+takeprofit*point); 
      }
     }
    }
   }
   
//--------------------------------------
// Большой тренд вниз
//--------------------------------------
   if(trendDirection[ELDER][CURRENT] < 0)
   {
    trendDirection[ELDER][HISTORY] = -1;
    //проверка на коррекцию вверх
    if(GreatDoubles(ask, iMA_daily_buf[0] - deltaPricetoEMA*point))
    {
     if(GreatDoubles(High_eld_buf[0], iMA_fast_eld_buf[0] - deltaPricetoEMA*point) &&
        GreatDoubles(High_eld_buf[1], iMA_fast_eld_buf[1] - deltaPricetoEMA*point))
     {
      if( LessDoubles(iMA_fast_jr_buf[0], iMA_slow_jr_buf[0]) &&
         GreatDoubles(iMA_fast_jr_buf[1], iMA_slow_jr_buf[1]))
      {
       if(m_Position.Select(my_symbol))                             //если уже существует позиция по этому символу
       {
        if(m_Position.PositionType()==POSITION_TYPE_BUY)  
        {
         Alert("Закрываем позицию BUY. Тренд вниз.");
         m_Trade.PositionClose(my_symbol);   //и тип этой позиции Buy, то закрываем ее
        }
        if(m_Position.PositionType()==POSITION_TYPE_SELL) return;                             //а если тип этой позиции Sell, то выходим
       }
       Alert("Открываем позицию SELL");
       //m_Trade.Sell(1,my_symbol);
       m_Trade.Sell(1,my_symbol, bid, ask+stoploss*point, bid-takeprofit*point);
      }
     }
    }
   }   
  }
