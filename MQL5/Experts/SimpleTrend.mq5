//+------------------------------------------------------------------+
//|                                                  SimpleTrend.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Робот, торгующий на тренде                                       |
//+------------------------------------------------------------------+

// подключение необходимых библиотек
#include <Lib CisNewBarDD.mqh>           // для проверки формирования нового бара
#include <TradeManager\TradeManager.mqh> // торговая библиотека

// входные параметры
     
// системные переменные

// хэндлы индикаторов
int handleSmydMACD_D1;                   // хэндл индикатора расхождений MACD на дневнике
int handleSmydMACD_H1;                   // хэндл индикатора расхождений MACD на часовике
int handleSmydMACD_M15;                  // хэндл индикатора расхождений MACD на 15 минутах
int handleSmydSTOC_D1;                   // хэндл индикатора расхождений STOC на дневнике
int handleSmydSTOC_H1;                   // хэндл индикатора расхождений STOC на часовике
int handleSmydSTOC_M15;                  // хэндл индикатора расхождений STOC на 15 минутах

// таймфреймы
ENUM_TIMEFRAMES periodD1  = PERIOD_D1; 
ENUM_TIMEFRAMES periodH1  = PERIOD_H1;
ENUM_TIMEFRAMES periodM5  = PERIOD_M5;
ENUM_TIMEFRAMES periodM15 = PERIOD_M15;
ENUM_TIMEFRAMES periodM1  = PERIOD_M1; 

// объекты классов
CTradeManager *ctm;                      // объект торговой библиотеки
 

// описание системных функций робота

int OnInit()
  {
   int errorValue  = INIT_SUCCEEDED;  // результат инициализации эксперта
   // пытаемся инициализировать хэндлы расхождений MACD и Стохастика
   handleSmydMACD_D1  = iCustom(_Symbol,periodD1,"smydMACD");  
   handleSmydMACD_H1  = iCustom(_Symbol,periodH1,"smydMACD");  
   handleSmydMACD_M15 = iCustom(_Symbol,periodM15,"smydMACD");  
   handleSmydSTOC_D1  = iCustom(_Symbol,periodD1,"smydSTOC");  
   handleSmydSTOC_H1  = iCustom(_Symbol,periodH1,"smydSTOC");  
   handleSmydSTOC_M15 = iCustom(_Symbol,periodM15,"smydSTOC");  
       
   if (handleSmydMACD_D1  == INVALID_HANDLE)
    {
     Print("Ошибка при инициализации эксперта SimpleTrend. Не удалось создать хэндл индикатора MACD на D1");
     errorValue = INIT_FAILED;
    }       
   if (handleSmydMACD_H1  == INVALID_HANDLE)
    {
     Print("Ошибка при инициализации эксперта SimpleTrend. Не удалось создать хэндл индикатора MACD на H1");
     errorValue = INIT_FAILED;  
    }      
   if (handleSmydMACD_M15  == INVALID_HANDLE)
    {
     Print("Ошибка при инициализации эксперта SimpleTrend. Не удалось создать хэндл индикатора MACD на M15");
     errorValue = INIT_FAILED;     
    }      
   if (handleSmydSTOC_D1  == INVALID_HANDLE)
    {
     Print("Ошибка при инициализации эксперта SimpleTrend. Не удалось создать хэндл индикатора Стохастика на D1");
     errorValue = INIT_FAILED;     
    }      
   if (handleSmydSTOC_H1  == INVALID_HANDLE)
    {
     Print("Ошибка при инициализации эксперта SimpleTrend. Не удалось создать хэндл индикатора Стохастика на H1");
     errorValue = INIT_FAILED;     
    }      
   if (handleSmydSTOC_M15  == INVALID_HANDLE)
    {
     Print("Ошибка при инициализации эксперта SimpleTrend. Не удалось создать хэндл индикатора Стохастика на M15");
     errorValue = INIT_FAILED;     
    }     
   // создаем объект класса TradeManager
   ctm = new CTradeManager();                    
   return(errorValue);
  }

void OnDeinit(const int reason)
  {
   // удаляем все индикаторы
   IndicatorRelease(handleSmydMACD_D1);
   IndicatorRelease(handleSmydMACD_H1);
   IndicatorRelease(handleSmydMACD_M15);
   IndicatorRelease(handleSmydSTOC_D1);
   IndicatorRelease(handleSmydSTOC_H1);
   IndicatorRelease(handleSmydSTOC_M15);
   // удаляем объект класса TradeManager
   delete ctm;
  }

void OnTick()
  {
    ctm.OnTick();
  }
  
 