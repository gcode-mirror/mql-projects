//+------------------------------------------------------------------+
//|                                                      CTihiro.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include "Extrem.mqh" 
//+------------------------------------------------------------------+
//| Класс для эксперта TIHIRO                                        |
//+------------------------------------------------------------------+

class CTihiro 
 {
    //приватные поля класса
   private:
    //количество баров истории
    uint   _bars;  
    //тангенс линии тренда
    double _tg;
    //расстояние от линии тренда до последнего экстремума
    double _range;
    //экстремумы
    Extrem extr_past,extr_present,extr_last;
    //приватные методы класса
   private:
    //получает значение тангенса угла наклона линии трейда   
    double GetTan(Extrem * ext_past,Extrem * ext_present);  
    //возвращает расстояние от экстремума до линии трейда
    double GetRange(Extrem * ext_past,Extrem * ext_present,double tg);
    //проверяет, выше или ниже линии трейда находится текущая точка
    int   TestPointLocate(Extrem * ext_past,Extrem * cur_point,double tg);
    
   public:
   //конструктор класса 
   CTihiro(uint bars):
     _bars(bars)
    {
    }; 
   //получает от эксперта указатели на массивы максимальных и минимальных цен баров
   //и вычисляет все необходимые значения по ним
   //а имеено - экстремумы, тангенс трендовой линии, расстояние от линии тренда до последнего экстремума 
   void OnNewBar(double  &price_max[],double  &price_min[]);
 };

//+------------------------------------------------------------------+
//| Описание приватных методов                                       |
//+------------------------------------------------------------------+

double CTihiro::GetTan(Extrem *ext1,Extrem *ext2) 
//получает значение тангенса угла наклона линии трейда
 {
  return (ext2.price-ext1.price)/(ext2.time - ext1.time);
 }
 
double CTihiro::GetRange(Extrem *ext_past,Extrem *ext_present,double tg)
//возвращает расстояние от экстремума до линии трейда
 {
  double L=ext_present.time-ext_past.time;  
  double H=ext_present.price-ext_past.price;
  return H-tg*L;
 }
 
int CTihiro::TestPointLocate(Extrem *ext_past,Extrem *cur_point,double tg)
//проверяет, выше или ниже линии трейда находится текущая точка
 {
   double line_level=ext_past.price+(cur_point.time-ext_past.time)*tg;  //значение  линии трейда в данной точке 
   if (cur_point.price>line_level)
    return 1;  //точка находится выше линии трейда
   if (cur_point.price<line_level)
    return -1; //точка находится ниже линии трейда
   return 0;   //точка находится на линии трейда
 }
 
//+------------------------------------------------------------------+
//| Описание публичных методов                                       |
//+------------------------------------------------------------------+ 

