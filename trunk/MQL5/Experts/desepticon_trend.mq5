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
#include <Trade\Trade.mqh>                                         //подключаем библиотеку для совершения торговых операций
#include <Trade\PositionInfo.mqh>                                  //подключаем библиотеку для получения информации о позициях
#include <CisNewBar.mqh>                                    //подключаем библиотеку для получения информации о появлении нового бара

//+------------------------------------------------------------------+
//| Expert variables                                                 |
//+------------------------------------------------------------------+
input int jrEMA = 12;
input int eldEMA = 26;

int               iMA_jr_handle;                                      //переменная для хранения хендла индикатора
double            iMA_jr_buf[];                                       //динамический массив для хранения значений индикатора
double            Close_jr_buf[];                                     //динамический массив для хранения цены закрытия каждого бара младшего ТФ

int               iMA_eld_handle;                                      //переменная для хранения хендла индикатора
double            iMA_eld_buf[];                                       //динамический массив для хранения значений индикатора
double            Close_eld_buf[];                                     //динамический массив для хранения цены закрытия каждого бара старшего ТФ

string            my_symbol;                                       //переменная для хранения символа
ENUM_TIMEFRAMES   my_jr_timeframe;                                    //переменная для хранения младшего таймфрейма
ENUM_TIMEFRAMES   my_eld_timeframe;                                    //переменная для хранения старшего таймфрейма

CTrade            m_Trade;                                         //структура для выполнения торговых операций
CPositionInfo     m_Position;                                      //структура для получения информации о позициях
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   my_symbol=Symbol();                                             //сохраним текущий символ графика для дальнейшей работы советника именно на этом символе
   my_jr_timeframe=PERIOD_M5;                                    
   my_eld_timeframe=PERIOD_H1;                                    
   iMA_jr_handle=iMA(my_symbol,my_jr_timeframe,12,0,MODE_SMA,PRICE_CLOSE);  //подключаем индикатор и получаем его хендл
   if(iMA_jr_handle==INVALID_HANDLE)                                  //проверяем наличие хендла индикатора
   {
      Print("Не удалось получить хендл индикатора");               //если хендл не получен, то выводим сообщение в лог об ошибке
      return(-1);                                                  //завершаем работу с ошибкой
   }
   
   iMA_eld_handle=iMA(my_symbol,my_jr_timeframe,26,0,MODE_SMA,PRICE_CLOSE);  //подключаем индикатор и получаем его хендл
   if(iMA_eld_handle==INVALID_HANDLE)                                  //проверяем наличие хендла индикатора
   {
      Print("Не удалось получить хендл индикатора");               //если хендл не получен, то выводим сообщение в лог об ошибке
      return(-1);                                                  //завершаем работу с ошибкой
   }
   //ChartIndicatorAdd(ChartID(),0,iMA_handle);                      //добавляем индикатор на ценовой график
   ArraySetAsSeries(iMA_jr_buf,true);                                 //устанавливаем индексация для массива iMA_buf как в таймсерии
   ArraySetAsSeries(iMA_eld_buf,true);                                 //устанавливаем индексация для массива iMA_buf как в таймсерии
   ArraySetAsSeries(Close_jr_buf,true);                               //устанавливаем индексация для массива Close_buf как в таймсерии
   ArraySetAsSeries(Close_eld_buf,true);                               //устанавливаем индексация для массива Close_buf как в таймсерии
   return(0);                                                      //возвращаем 0, инициализация завершена
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(iMA_jr_handle);                                   //удаляет хэндл индикатора и освобождает память занимаемую им
   ArrayFree(iMA_jr_buf);                                             //освобождаем динамический массив iMA_buf от данных
   IndicatorRelease(iMA_eld_handle);                                   //удаляет хэндл индикатора и освобождает память занимаемую им
   ArrayFree(iMA_eld_buf);                                             //освобождаем динамический массив iMA_buf от данных
   ArrayFree(Close_jr_buf);                                           //освобождаем динамический массив Close_buf от данных
   ArrayFree(Close_eld_buf);                                           //освобождаем динамический массив Close_buf от данных
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   int err1=0;                                                     //переменная для хранения результатов работы с буфером индикатора
   int err2=0;                                                     //переменная для хранения результатов работы с ценовым графиком

   static CIsNewBar isNewBarEld;
   static CIsNewBar isNewBarJr;
   if(isNewBarEld.isNewBar(my_symbol, my_eld_timeframe))
   {
    err1=CopyBuffer(iMA_eld_handle,0,1,2,iMA_eld_buf);                      //копируем данные из индикаторного массива в динамический массив iMA_buf для дальнейшей работы с ними
    err2=CopyClose(my_symbol,my_eld_timeframe,1,2,Close_eld_buf);           //копируем данные ценового графика в динамический массив Close_buf  для дальнейшей работы с ними
    if(err1<0 || err2<0)                                            //если есть ошибки
    {
     Print("Не удалось скопировать данные из индикаторного буфера или буфера ценового графика");  //то выводим сообщение в лог об ошибке
     return;                                                                                      //и выходим из функции
    }
   }
   
   if(isNewBarJr.isNewBar(my_symbol, my_jr_timeframe))
   {
    err1=CopyBuffer(iMA_jr_handle,0,1,2,iMA_jr_buf);                      //копируем данные из индикаторного массива в динамический массив iMA_buf для дальнейшей работы с ними
    err2=CopyClose(my_symbol,my_jr_timeframe,1,2,Close_jr_buf);           //копируем данные ценового графика в динамический массив Close_buf  для дальнейшей работы с ними
    if(err1<0 || err2<0)                                            //если есть ошибки
    {
     Print("Не удалось скопировать данные из индикаторного буфера или буфера ценового графика");  //то выводим сообщение в лог об ошибке
     return;                                                                                      //и выходим из функции
    }
   
    if(iMA_jr_buf[1]>Close_jr_buf[1] && iMA_jr_buf[0]<Close_jr_buf[0])          //если значение индикатора были больше цены закрытия и стали меньше
    {
     if(m_Position.Select(my_symbol))                             //если уже существует позиция по этому символу
      {
       if(m_Position.PositionType()==POSITION_TYPE_SELL) m_Trade.PositionClose(my_symbol);  //и тип этой позиции Sell, то закрываем ее
       if(m_Position.PositionType()==POSITION_TYPE_BUY) return;                             //а если тип этой позиции Buy, то выходим
      }
     m_Trade.Buy(1,my_symbol);                                  //если дошли сюда, значит позиции нет, открываем ее
    }
   if(iMA_jr_buf[1]<Close_jr_buf[1] && iMA_jr_buf[0]>Close_jr_buf[0])          //если значение индикатора были меньше цены закрытия и стали больше
    {
     if(m_Position.Select(my_symbol))                             //если уже существует позиция по этому символу
      {
       if(m_Position.PositionType()==POSITION_TYPE_BUY) m_Trade.PositionClose(my_symbol);   //и тип этой позиции Buy, то закрываем ее
       if(m_Position.PositionType()==POSITION_TYPE_SELL) return;                            //а если тип этой позиции Sell, то выходим
      }
     m_Trade.Sell(1,my_symbol);                                 //если дошли сюда, значит позиции нет, открываем ее
    }
   }
  }
