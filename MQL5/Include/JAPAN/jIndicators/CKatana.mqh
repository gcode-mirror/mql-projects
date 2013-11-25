//+------------------------------------------------------------------+
//|                                                      CKatana.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| Класс индикатора KATANA                                          |
//+------------------------------------------------------------------+

//---- структура экстремумов 
 struct Extrem
  {
   uint   n_bar;             //номер бара 
   double price;             //ценовое положение экстремума
  };
  
 class CKatana
  {
   private:
    //---- массивы цен
    double _high[];
    double _low[];
    //---- разница цен для поиска экстремумов
    double _priceDifference;
    //---- тангенсы угла наклона линий тренда
    double _tg_up; 
    double _tg_down;
   public:
    //---- точки экстремума
    Extrem _left_extr_up;         //левый экстремум тренда вверх (нижняя линия)
    Extrem _right_extr_up;        //правый экстремум тренда вверх (нижняя линия)
    Extrem _left_extr_down;       //левый экстремум тренда вниз (верхняя линия)
    Extrem _right_extr_down;      //правый экстремум тренда вниз (верхняя линия)
    //---- 
    
   public:
   
//+------------------------------------------------------------------+
//| Конструктор и деструктор                                         |
//+------------------------------------------------------------------+

   CKatana (double &high[],double &low[]):
   _high(high),
   _low(low) 
   //конструктор класса
     {
     
     }
   ~CKatana ()
   //деструктор класса
     {
      //очищаем память под динамические массивы
      ArrayFree(_high);
      ArrayFree(_low);
     }
   private:
   
//+------------------------------------------------------------------+
//| Приватные методы                                                 |
//+------------------------------------------------------------------+
  //---- вычисляет разницы между ценами 
  void   GetPriceDifferences(bool trend_type);
   
//+------------------------------------------------------------------+
//| Публичные методы                                                 |
//+------------------------------------------------------------------+
   //---- вычисление тангенса наклона тренда 
   double   GetTan(bool trend_type);
   //---- вычисление значение линии тренда по заданному бару
   double   GetLineY (bool trend_type,uint n_bar);
   //---- вычисляет экстремумы
   void     GetExtrem();
   //---- сохраняет значение экстремума
   void     SetExtrem(uint extr_type,uint n_bar,double price);
   
  };
  
//+------------------------------------------------------------------+
//| Описание приватных методов                                       |
//+------------------------------------------------------------------+  

   void CKatana::GetPriceDifferences(bool trend_type)
   //вычисление разниц цен
    {
     switch (trend_type)
      {
       //---- тренд вверх (нижняя линия)
       case 0:  
        priceDiff_left  = low[index+1]-low[index];
        priceDiff_right = low[index-1]-low[index]; 
       break;
       //---- тренд вниз (верхняя линия)
       case 1:
        priceDiff_left  = high[index]-high[index+1];
        priceDiff_right = high[index]-high[index-1];
       break;
      }
    }
  
//+------------------------------------------------------------------+
//| Описание публичных методов                                       |
//+------------------------------------------------------------------+

   double  CKatana::GetTan(bool trend_type)
   //вычисляет значение тангенса наклона линии
    {
     //если хотим вычислить тангенс наклона тренда вверх (нижней линии)
     if (trend_type == true)
      return ( _right_extr_up.price - _left_extr_up.price ) / ( _right_extr_up.n_bar - _left_extr_up.n_bar );
     //если хотим вычислить тангенс наклона тренда вниз (верхней линии)
     return ( _right_extr_down.price - _left_extr_down.price ) / ( _right_extr_down.n_bar - _left_extr_down.n_bar );   
    } 
 
   double  CKatana::GetLineY (bool trend_type,uint n_bar)
   //возвращает значение Y точки текущей линии
   {
   //если хотим вычислить значение точки на линии тренда вверх
    if (trend_type == true)
     return (_left_extr_up.price + (n_bar-_left_extr_up.n_bar)*_tg_up);
   //если хотим вычислить значение точки на линии тренда вниз
    return (_right_extr_down.price + (n_bar-_right_extr_down.n_bar)*_tg_down);
   }
   
   void   CKatana::GetExtrem()
   //вычисляет экстремумы
    {
      
    }
   
   void   CKatana::SetExtrem(uint extr_type,uint n_bar,double price)
   //сохраняет значение экстремума
    {
      switch (extr_type)
       {
        case 0:
         _left_extr_down.n_bar = n_bar;
         _left_extr_down.price = price;
        break;
        case 1:
         _right_extr_down.n_bar = n_bar;
         _right_extr_down.price = price;        
        break;
        case 2:
         _left_extr_up.n_bar = n_bar;
         _left_extr_up.price = price;        
        break;
        case 3:
         _right_extr_up.n_bar = n_bar;
         _right_extr_up.price = price;        
        break;
       }
    }