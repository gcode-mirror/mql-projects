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
//| Публичные методы                                                 |
//+------------------------------------------------------------------+
   //---- вычисление тангенса наклона тренда 
   double   GetTan(bool trend_type);
   //---- вычисление значение линии тренда по заданному бару
   double   GetLineY (bool trend_type,uint n_bar);
   //---- вычисляет экстремумы
   
   //---- сохраняет значение экстремума
   void     SetExtrem(uint n_bar,double price);
   
  };
  
//+------------------------------------------------------------------+
//| Публичные методы                                                 |
//+------------------------------------------------------------------+

   double  CKatana::GetTan(bool trend_type)
   //вычисляет значение тангенса наклона линии
    {
     //если хотим вычислить тангенс наклона тренда вверх (нижней линии)
     if (trend_type == true)
      return ( right_extr_up.price - left_extr_up.price ) / ( right_extr_up.n_bar - left_extr_up.n_bar );
     //если хотим вычислить тангенс наклона тренда вниз (верхней линии)
     return ( right_extr_down.price - left_extr_down.price ) / ( right_extr_down.n_bar - left_extr_down.n_bar );   
    } 
 
   double  CKatana::GetLineY (bool trend_type,uint n_bar)
   //возвращает значение Y точки текущей линии
   {
   //если хотим вычислить значение точки на линии тренда вверх
    if (trend_type == true)
     return (left_extr_up.price + (n_bar-left_extr_up.n_bar)*tg_up);
   //если хотим вычислить значение точки на линии тренда вниз
    return (right_extr_down.price + (n_bar-right_extr_down.n_bar)*tg_down);
   }
   
   void   CKatana::SetExtrem(uint n_bar,double price)
   //сохраняет значение экстремума
    {
    
    }