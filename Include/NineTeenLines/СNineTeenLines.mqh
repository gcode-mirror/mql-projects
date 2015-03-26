//+------------------------------------------------------------------+
//|                                               СNineTeenLines.mqh |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include <NineTeenLines/CDrawLevel.mqh>
#include <ExtrLine\CLevel.mqh>
// класс работы инрдикатора NineTeenLines
class CNineTeenLines
 {
  private:
   CDrawLevel *    _level;    // класс уровней
   ENUM_TIMEFRAMES _period;   // период отрисовки уровней
   string          _name;     // имя уровней
  public:
   // публичные методы класса 
   void MoveExtrLines(const SLevel &te[]);
   void DeleteExtrLines();
   CNineTeenLines (ENUM_TIMEFRAMES period,const SLevel &te,color clr=clrRed,const long chart_ID=0,const int sub_window=0,const bool back=true);  // конструктор класса
  ~CNineTeenLines ();  // деструктор класса
 };  
 
 // кодирование методов 
 
 // перемещает уровни 
 void CNineTeenLines::MoveExtrLines(const SLevel &te[])
  {
    _level.MoveLevel(_name+"one",te[0].extr.price);
    _level.ChangeLevel(_name+"one",te[0].channel);
    _level.MoveLevel(_name+"two",te[1].extr.price);
    _level.ChangeLevel(_name+"two",te[1].channel); 
    _level.MoveLevel(_name+"three",te[2].extr.price);
    _level.ChangeLevel(_name+"three",te[2].channel); 
    _level.MoveLevel(_name+"four",te[3].extr.price);
    _level.ChangeLevel(_name+"four",te[3].channel); 
  }
 // удаляет уровни 
 void CNineTeenLines::DeleteExtrLines(void)
  {
   // вызываем метод удаления всех уровней
   _level.DeleteAll();
  }
 // конструктор класса
 CNineTeenLines::CNineTeenLines(ENUM_TIMEFRAMES period,const SLevel &te,color clr=clrRed,const long chart_ID=0,const int sub_window=0,const bool back=true)
  {
   _name = "extr_" + EnumToString(period) + "_"; 
   _period = period;
   // создаем объекты уровней
   _level.CDrawLevel(chart_ID,sub_window,back);
   // создаем уровни
   _level.SetLevel(_name+"one",te[0].extr.price,te[0].channel,clr);   // первый уровень
   _level.SetLevel(_name+"two",te[1].extr.price,te[1].channel,clr);   // первый уровень
   _level.SetLevel(_name+"three",te[2].extr.price,te[2].channel,clr); // первый уровень
   _level.SetLevel(_name+"four",te[3].extr.price,te[3].channel,clr);  // первый уровень            
  }
 
 // деструктор класса
 CNineTeenLines::~CNineTeenLines()
  {
   delete _level;
  }
 