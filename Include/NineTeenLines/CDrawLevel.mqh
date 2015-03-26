//+------------------------------------------------------------------+
//|                                                   CDrawLevel.mqh |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
// подключаем необходимые библиотеки
#include <ExtrLine\HLine.mqh>
// класс отрисовки линий уровня
class CDrawLevel 
 {
  private:
   // буферы уровней
   double _levelPrices[];   // буфер цен уровней
   double _levelATR[];      // буфер ширины каналов уровней
   color  _levelColor[];    // буфер цветов уровней
   string _levelNames[];    // буфер имен уровней
   // приватные параметры класса уровней
   int    _levelCount;      // количество уровней 
   long   _chart_ID;        // id графика
   int    _sub_window;      // номер подокна
   bool   _back;   
   // приватные методы класса  
   int    GetIndexByName(string name);                                 // метод возвращает индекс уровня в буфере по имени        
  public:
   // методы отрисовки уровней
   bool SetLevel (string name,double price,double atr,color clr);      // метод добавляет графическое отображение уровня
   bool MoveLevel (int index,double price);                            // перемещает уровнень по индексу на заданную цену
   bool MoveLevel (string name,double price);                          // перемещает уровень по имени уровня
   bool DeleteLevel (int index);                                       // удаляет уровень по индексу
   bool DeleteLevel (string name);                                     // удаляет уровень по имени уровня
   bool ChangeLevel (int index,double atr);                            // изменяет ширину уровня по индексу
   bool ChangeLevel (int index,color clr);                             // изменяет цвет уровня по индексу       
   bool ChangeLevel (string name, double atr);                         // изменяет ширину уровня по имени
   bool ChangeColor (string name, color clr);                          // изменяет цвет уровня по имени  
   void DeleteAll   ();                                                // удаляет все уровни      
   CDrawLevel    (const long            chart_ID=0,                    // ID графика
                  const int             sub_window=0,                  // номер подокна
                  const bool            back=true                      // на заднем плане
               );                                                      // конструктор класса рисования уровней
  ~CDrawLevel ();                                                      // деструктор класса рисования уровней
 };
 
 // кодирование методов класса
 
 ////// приватные методы класса
 
 // метод возвращает индекс уровня в буфере  по имени
 int CDrawLevel::GetIndexByName(string name)
  {
   // проходим по буферу и ищем уровень с заданным уровнем
   for (int ind=0;ind<_levelCount;ind++)
    {
     //если нашли уровень по заданному имени, то возвращаем индекс данного уровня
     if (_levelNames[ind] == name)
      return (ind);
    }
   return (-1); // не нашли уровень
  }
 
 ////// публичные методы класса 
 
 // метод добавления графического отображения уровня
 bool CDrawLevel::SetLevel(string name,double price,double atr,color clr)
  {
   // если удалось нарисовать линию
   if ( HLineCreate(_chart_ID,name,_sub_window,price,clr,1,STYLE_DASHDOT,_back) &&
        HLineCreate(_chart_ID,name+"+",_sub_window,price+atr,clr,1,STYLE_SOLID,_back) &&
        HLineCreate(_chart_ID,name+"-",_sub_window,price-atr,clr,1,STYLE_SOLID,_back)   
        )
        {
         ArrayResize(_levelPrices,_levelCount+1);
         ArrayResize(_levelColor,_levelCount+1);
         ArrayResize(_levelATR,_levelCount+1);   
         ArrayResize(_levelNames,_levelCount+1);
         _levelPrices[_levelCount] = price; // сохраняем цену уровня
         _levelATR[_levelCount]    = atr;   // сохраняем ширину уровня
         _levelColor[_levelCount]  = clr;   // сохраняем цвет линий
         _levelNames[_levelCount]  = name;  // сохраняем имя уровня
         _levelCount ++;                    // увеличиваем количество уровней
         return (true);
        }
   return (false);
  }
  
 // метод перемещает уровень по индексу на заданную цену
 bool CDrawLevel::MoveLevel(int index,double price)
  {
   // если корректно задан индекс уровня
   if (index >= 0 && index < _levelCount)
    {
      if ( HLineMove(_chart_ID,_levelNames[index],price)  &&
           HLineMove(_chart_ID,_levelNames[index]+"+",price+_levelATR[index])  &&
           HLineMove(_chart_ID,_levelNames[index]+"-",price-_levelATR[index]) 
         ) 
          {  
           _levelPrices[index] = price;
           return (true);
          }
    }
   return (false);
  }
  
 // метод перемещает уровень по имени на заданную цену
 bool CDrawLevel::MoveLevel(string name,double price)
  {
   // получаем индекс уровня по имени уровня
   int ind = GetIndexByName(name);
   // если индекс удалось найти
   if (ind > -1)
    { 
     // то перемещаем уровень по индексу 
     return (MoveLevel(ind,price));
    }
   return (false);
  }
 
 // удаляет уровень по индексу
 bool CDrawLevel::DeleteLevel(int index)
  {
   // если корректно задан индекс уровня
   if (index >=0 && index < _levelCount)
    {
     // если удалось удалить графические объекты
     if ( HLineDelete(_chart_ID, _levelNames[index]) &&
          HLineDelete(_chart_ID, _levelNames[index]+"+") &&
          HLineDelete(_chart_ID, _levelNames[index]+"-")
        )
         {
          // свигаем массив на один элемент влево
          for (int ind=index+1;ind<_levelCount;ind++)
           {

            _levelATR    [ind-1]  = _levelATR    [ind];
            _levelColor  [ind-1]  = _levelColor  [ind];
            _levelPrices [ind-1]  = _levelPrices [ind]; 
            _levelNames  [ind-1]  = _levelNames  [ind];
           }
          _levelCount--;  // уменьшаем количество уровней на единицу
          // изменяем размеры массивов
          ArrayResize(_levelATR,_levelCount);
          ArrayResize(_levelColor,_levelCount);
          ArrayResize(_levelNames,_levelCount);
          ArrayResize(_levelPrices,_levelCount);
          return (true);
         }
     }
   return (false);
  }
 
 // удаляет уровень по имени уровня
 bool CDrawLevel::DeleteLevel(string name)
  {
   // получаем индекс уровня по имени уровня
   int ind = GetIndexByName(name);
   // если индекс удалось найти
   if (ind > -1)
    { 
     // то удаляем уровень по индексу
     return (DeleteLevel(ind));
    }
   return (false);  
  }
  
 // изменяет ширину уровня по индексу
 bool CDrawLevel::ChangeLevel(int index,double atr)
  {
   // если корректный индекс уровня в буфере
   if (index >=0 && index < _levelCount)
    {
     _levelATR[index] = atr;
     HLineMove(_chart_ID,_levelNames[index]+"+",_levelPrices[index]+atr);  
     HLineMove(_chart_ID,_levelNames[index]+"-",_levelPrices[index]-atr); 
     return (true);        
    }
   return (false);
  }
  
 // удаляет все уровни
 void CDrawLevel::DeleteAll(void)
  {
   // проходим по циклу и удаляем все уровни
   for (int ind=0;ind<_levelCount;ind++)
    {
     HLineDelete(_chart_ID,_levelNames[ind]);
     HLineDelete(_chart_ID,_levelNames[ind]+"+");
     HLineDelete(_chart_ID,_levelNames[ind]+"-");
    }
    ArrayResize(_levelATR,0);
    ArrayResize(_levelColor,0);
    ArrayResize(_levelNames,0);
    ArrayResize(_levelPrices,0);
    _levelCount = 0;
  } 
  
 // изменяет ширину уровня по имени уровня
 bool CDrawLevel::ChangeLevel(string name,double atr)
  {
   // получаем индекс уровня по имени уровня
   int ind = GetIndexByName(name);
   // если индекс удалось найти
   if (ind > -1)
    { 
     // то изменяем ширину уровня по индексу
     ChangeLevel(ind,atr);
    }
   return (false);    
  }
 
 // конструктор класса
 CDrawLevel::CDrawLevel(const long chart_ID=0,const int sub_window=0,const bool back=true)
  {
   _levelCount = 0;
  }
 
 // деструктор класса
 CDrawLevel::~CDrawLevel(void)
  {
   // освобождаем буферы уровней
   ArrayFree (_levelATR);
   ArrayFree (_levelColor);
   ArrayFree (_levelPrices);
  }