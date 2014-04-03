//+------------------------------------------------------------------+
//|                                                   DISEPTICON.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

// подключение библиотек

#include <TradeManager/TradeManager.mqh>    // торговая библиотека
#include "STRUCTS.mqh"                      // библиотека структур данных для получения сигналов

// класс Дисептикона
class DISEPTICON
 { 
  private:
   // приватные методы класса Дисептикона
   ENUM_TIMEFRAMES eldTF;
   ENUM_TIMEFRAMES jrTF;      
   
   
  public:
  // методы 
  
  // конструкторы и дестрикторы класса Дисептикона
  DISEPTICON (); // конструктор класса
 ~DISEPTICON (); // деструктор класса 
 };
 
 // кодирование конструктора и деструктора
 
 // конструктор класса Дисептикона
 DISEPTICON::DISEPTICON(void)
  {
   // инициализируем параметры, буферы, индикаторы и прочее
  }
  
 // деструктор класса дисептикона
 
 DISEPTICON::~DISEPTICON(void)
  {
  
  }