//+------------------------------------------------------------------+
//|                                                    SymbolSys.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include "SymbolEnum.mqh"
//+------------------------------------------------------------------+
//| класс функций работы с параметрами символа                       |
//+------------------------------------------------------------------+
class SymbolSys  //класс работающий с параметрами символа
  {
   public:
   symbol_properties    symb;   
   int CorrectValueBySymbolDigits(int value);
   double CorrectValueBySymbolDigits(double value);
   void GetSymbolProperties(string mask); //получает свойство символа
   SymbolSys(); //конструктор класса
  ~SymbolSys(); //деструктор класса
  };
//+------------------------------------------------------------------+
//| Коррекция значения по количеству знаков в цене (int)             |
//+------------------------------------------------------------------+  
int SymbolSys::CorrectValueBySymbolDigits(int value)
  {
   return(symb.digits==3 || symb.digits==5) ? value*=10 : value;
  }
  
//+------------------------------------------------------------------+
//| Коррекция значения по количеству знаков в цене (double)          |
//+------------------------------------------------------------------+
double SymbolSys::CorrectValueBySymbolDigits(double value)
  {
   return(symb.digits==3 || symb.digits==5) ? value*=10 : value;
  }  
//+------------------------------------------------------------------+
//| Коррекция значения по количеству знаков в цене (double)          |
//+------------------------------------------------------------------+
void SymbolSys::GetSymbolProperties(string mask)
  {
   int lot_offset=1; // Количество пунктов для отступа от уровней stops level
   if (StringGetCharacter(mask,0)=='1') symb.digits=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);                 
   if (StringGetCharacter(mask,1)=='1') symb.spread=(int)SymbolInfoInteger(_Symbol,SYMBOL_SPREAD);                  
   if (StringGetCharacter(mask,2)=='1') symb.stops_level=(int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);   
   if (StringGetCharacter(mask,3)=='1') symb.point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);                           
   if (StringGetCharacter(mask,4)=='1')           
      {
       symb.digits=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
       symb.ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),symb.digits);  
      }                    
   if (StringGetCharacter(mask,5)=='1')           
      {
       symb.digits=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
       symb.bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),symb.digits);                       
      }
   if (StringGetCharacter(mask,6)=='1') symb.volume_min=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);                
   if (StringGetCharacter(mask,7)=='1') symb.volume_max=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);                 
   if (StringGetCharacter(mask,8)=='1') symb.volume_limit=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_LIMIT);             
   if (StringGetCharacter(mask,9)=='1') symb.volume_step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);               
   if (StringGetCharacter(mask,10)=='1')        
      {
       symb.digits=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
       symb.point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
       symb.offset=NormalizeDouble(CorrectValueBySymbolDigits(lot_offset*symb.point),symb.digits);       
      }
   if (StringGetCharacter(mask,11)=='1')      
      {
       symb.digits=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
       symb.stops_level=(int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
       symb.point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
       symb.ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),symb.digits);
       symb.up_level=NormalizeDouble(symb.ask+symb.stops_level*symb.point,symb.digits);                  
      }
   if (StringGetCharacter(mask,12)=='1')    
      {
       symb.digits=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
       symb.stops_level=(int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
       symb.point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
       symb.bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),symb.digits);
       symb.down_level=NormalizeDouble(symb.bid-symb.stops_level*symb.point,symb.digits);                
      }
  }
//+------------------------------------------------------------------+
//| Конструктор класса                                               |
//+------------------------------------------------------------------+  
SymbolSys::SymbolSys() 
   {
   
   }
//+------------------------------------------------------------------+
//| Деструктор класса                                                |
//+------------------------------------------------------------------+   
SymbolSys::~SymbolSys() 
   {
   
   }