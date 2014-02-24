//+------------------------------------------------------------------+
//|                                                    CExpertID.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include <GlobalVariable.mqh>
#include <StringUtilities.mqh>
//+------------------------------------------------------------------+
//| Класс для создания глобальных переменных параметров экспертов    |
//+------------------------------------------------------------------+

class CExpertID: public CGlobalVariable 
 {
  private:

  public:
  // публичные методы класса
  bool IsContinue();    // возвращает сигнал о том, стоит ли продолжать торговлю или нет
  // конструктор класса переменных параметров эксперта
  CExpertID(string expert_name,string symbol,ENUM_TIMEFRAMES period);   
  // деструктор класса 
 ~CExpertID();
 };
 // возвращает сигнал о том, стоит ли продолжать торговлю или нет
 bool CExpertID::IsContinue(void)
  {
   // если тоговать всё еще дозволительно 
   if ( IntValue() != 0 )
    return true;
   return false;
  }
 
 // конструктор класса
 CExpertID::CExpertID(string expert_name,string symbol,ENUM_TIMEFRAMES period)
  {
   string var_name = "&"+expert_name+"_"+symbol+"_"+PeriodToString(period); // формируем имя переменной   
   Name(var_name); // сохраняем переменную
   IntValue(2);    // кладем значение 1 (робот запущен и готов торговать)
  }
  
 // деструктор класса
 CExpertID::~CExpertID(void)
  {
   Delete(); // удаляем переменную
  }