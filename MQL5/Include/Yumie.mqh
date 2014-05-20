//+------------------------------------------------------------------+
//|                                                       JYumie.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

// подключаем необходимые библиотеки
#include <CExtremum.mqh>   // дл€ вычислени€ экстремумов

//+------------------------------------------------------------------+
//|  ласс индикатора Yumie                                           |
//+------------------------------------------------------------------+

class CYumie 
 {
  private:
   // приватные буферы 
   SExtremum        _extremums[];      // буфер экстремумов
   double           _high[];           // буфер высоких цен
   double           _low[];            // буфер низких цен
   // приватные пол€ класса
   // 1) системные параметры 
   string           _symbol;           // символ
   ENUM_TIMEFRAMES  _period;           // период
   double           _difToNewExtremum; // разница по цене между экстремумами
   int              _historyDepth;     // глубина истории, на которую вычисл€ютс€ уровни
   
  public:
   // методы класса
   
   // конструкторы и деструкторы класса
   CYumie ();                   // конструктор класса Yumie
  ~CYumie ();                   // деструктор класса
 };
 
 // описание методов 
 
 
 // описание конструкторов и деструкторов
 
 CYumie::CYumie(void)           // конструтор класса
  {
   
  }
  
 CYumie::~CYumie(void)          // деструктор класса
  {
   // очищаем буферы 
   ArrayFree (_extremums);
   ArrayFree (_high);
   ArrayFree (_low);
  }