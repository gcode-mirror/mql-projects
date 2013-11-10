//+------------------------------------------------------------------+
//|                                                       Extrem.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| Дополнительная библиотека для класса CTihiro                     |
//+------------------------------------------------------------------+

//константы 
#define UNKNOWN    0
#define BUY        1
#define SELL       2
#define TREND_UP   3
#define TREND_DOWN 4
#define NOTREND    5

//перечисление режимов
enum  TIHIRO_MODE
 {
  TM_WAIT_FOR_CROSS=0, //режим ожидания перехода цены за линиию тренда
  TM_REACH_THE_RANGE   //режим перехода на Range
 };
//класс экстремумов
 class Extrem
  {
   public:
   datetime time;   //временное положение экстремума
   double price;    //ценовое положение экстремума
   void SetExtrem(datetime t,double p){ time=t; price=p; }; //сохраняет экстремум
   Extrem(datetime t=0,double p=0):time(t),price(p){};      //конструктор
  };