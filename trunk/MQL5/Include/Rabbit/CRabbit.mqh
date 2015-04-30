//+------------------------------------------------------------------+
//|                                                      CRabbit.mqh |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| Класс робота "Кролик"                                            |
//+------------------------------------------------------------------+
#include <CTrendChannel.mqh> // контейнер трендов 
#include <CompareDoubles.mqh> // для сравнения вещественных чисел
#include <SystemLib/IndicatorManager.mqh> // библиотека по работе с индикаторами
#include <CTrendChannel.mqh> // трендовый контейнер
//константы
#define KO 3 //коэффициент для условия открытия позиции, во сколько как минимум вычисленный тейк профит должен превышать вычисленный стоп лосс
#define SPREAD 30 // размер спреда 

class CRabbit 
 {
  private:
   string _symbol; // символ
   ENUM_TIMEFRAMES _period; // период
   int _handleDE; // хэндл DrawExtremums
   int _handleATR; // хэндл ATR  
   int _stopLoss; // стоп лосс
   int _takeProfit; // тейк профит 
   double _percent; // процент вычисления трендов 
   double _supremacyPercent; // процент, на сколько бар больше среднего значения
   double _profitPercent; // процент прибыли
   CTrendChannel *_trendChannel; // контейнер трендов
   // приватные методы класса
   int CountStopLoss (int point); // вычисляет стоп лосс
  public:
   CRabbit (string symbol, ENUM_TIMEFRAMES period,double supremacyPercent,double profitPercent); // конструктор 
  ~CRabbit (); // деструктор
  // методы класса
  int GetSignal (); // метод возвращает сигнал открытия 
  int GetStopLoss () { return(_stopLoss); }; // возвращает стоп лосс
  int GetTakeProfit () { return (_takeProfit); }; // возвращает тейк профит
  // фильтры кролика 
 };
 
 // кодирование методов класса 
 int CRabbit::CountStopLoss(int point)  // вычисляет стоп лосс
  {
   MqlRates rates[];
   double price;
   if (CopyRates(_symbol,_period,1,1,rates) < 1)
    {
     return (0);
    }
   // если нужно открываться вверх
   if (point == 1)
    {
     price = SymbolInfoDouble(_Symbol,SYMBOL_BID);
    }
   // если нужно открыться вниз
   if (point == -1)
    {
     price = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
    }    
   return( int( MathAbs(price - (rates[0].open+rates[0].close)/2) / _Point) );   
  }

 
 CRabbit::CRabbit(string symbol,ENUM_TIMEFRAMES period,double supremacyPercent,double profitPercent) // конструктор Кролика
  {
   // сохраняем поля класса
   _symbol = symbol;
   _period = period;
   _supremacyPercent = supremacyPercent;
   _percent = 0.1;
   // создаем индикатор DrawExtremums
   _handleDE = DoesIndicatorExist(_symbol,_period,"DrawExtremums");
   if (_handleDE == INVALID_HANDLE)
    {
     _handleDE = iCustom(_Symbol,_period,"DrawExtremums");
     if (_handleDE == INVALID_HANDLE)
      {
       Print("Не удалось создать хэндл индикатора DrawExtremums");
       return;
      }
     SetIndicatorByHandle(_symbol,_period,_handleDE);
    }
   // индикатор ATR
   _handleATR = iMA(_symbol,_period,100,0,MODE_EMA,iATR(_symbol,_period,30));         
   _trendChannel = new CTrendChannel(0,_symbol,_period,_handleDE,_percent);
  }
 
 CRabbit::~CRabbit(void) // деструктор Кролика
  {
   // удаление объектов
   delete _trendChannel; 
  }
  
 
 // метод возвращает сигнал открытия 
 int CRabbit::GetSignal(void)
  {
   double close_buf[];
   double open_buf[];
   double ave_atr_buf[]; 
   int type = 0;
   //если не удалось прогрузить все буферы 
   if (CopyClose  (_symbol,_period,1,1,close_buf)<1 ||
       CopyOpen   (_symbol,_period,1,1,open_buf)<1 ||
       CopyBuffer (_handleATR,0,0,1,ave_atr_buf)<1)
      {
       //то выводим сообщение в лог об ошибке
       log_file.Write(LOG_DEBUG,StringFormat("%s Не удалось скопировать данные из буфера ценового графика", MakeFunctionPrefix(__FUNCTION__)));    
       return (0);//и выходим из функции 
      }
      
   if (GreatDoubles(MathAbs(open_buf[0] - close_buf[0]), ave_atr_buf[0]*(1 + _supremacyPercent)))
    {
     if(LessDoubles(close_buf[0], open_buf[0])) // на последнем баре close < open (бар вниз)
      {     
       _takeProfit=(int)MathCeil((MathAbs(open_buf[0] - close_buf[0])/_Point)*(1+_profitPercent));
       _stopLoss=CountStopLoss(-1);        
       //если вычисленный тейк профит в kp раза или более раз больше, чем вычисленный стоп лосс
       if(_takeProfit >= KO*_stopLoss)
        type = -1; // можно открывать на SELL
       else
        {
         return (0); // не получили сигнал на открытие
        }   
       }
       
  if (GreatDoubles(close_buf[0], open_buf[0]))
   {     
    _takeProfit = (int)MathCeil((MathAbs(open_buf[0] - close_buf[0])/_Point)*(1+_profitPercent));
    _stopLoss = CountStopLoss(1);
    // если вычисленный тейк профит в kp раза или более раз больше, чем вычисленный стоп лосс
    if(_takeProfit >= KO*_stopLoss)
     type = 1; // можно открывать на BUY
    else
     {
      return (0); // не получили сигнал на открытие
     }
   }

  }
   return ( type ); // возвращаем сигнал на открытие
 }