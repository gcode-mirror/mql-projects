#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include  <ColoredTrend/ColoredTrendUtilities.mqh> //загружаю бибилиотеку цветов
#include <CompareDoubles.mqh>    //для сравнения действительных переменных
#include <Lib CisNewBar.mqh>     //для проверки баров
#include<TradeManager/TradeManager.mqh> //для совершения сделок

input uint n=4; //количество баров, после которых идет проверка пробоя
input uint N=20; //количество баров, до которых идет проверка пробоя
input double diff=0.3; //разница между ценами

double high[];   // массив высоких цен 
double low[];   // массив низких цен
double cur_color[]; //массив текущих цветов свечей 
double max_value=DBL_MIN;   //максимальное значение в массиве high
double min_value=DBL_MAX;   //минимальное значение в массиве low
double sl, tp;
datetime date_buffer[];          //буфер времени
int handle_PBI;     //хэндл PriceBasedIndicator
int tn; //действительное значение малого количества баров
int tN; //действительное значение большого количества баров
uint MaxPos;     //позиция максимума в массиве high
uint MinPos;     //позиция минимума в массиве low
CisNewBar newCisBar;     //массив по обработке баров
CTradeManager new_trade; //класс совершения сделок

string sym  =  _Symbol;
ENUM_TIMEFRAMES timeFrame=_Period;   //таймфрейм
MqlTick tick;
//флаги о загрузке поиске максимума и минимума среди N текущих баров
bool flagMax = true;  //флаг о поиске максимума 
bool flagMin = true;  //флаг о поиске минимума
//
bool sellTest = false;
bool buyTest = false;

bool proboy_max = true;  //условие пробоя максимума
bool proboy_min = true;  //условие пробоя минимума



int OnInit()
  {

   handle_PBI = iCustom(sym,timeFrame,"PriceBasedIndicator"); //загружаем хэндл индикатора PriceBasedIndicator
     
   if(handle_PBI<0)
    {
     Print("Не возможно проинициализировать индиктор PriceBasedIndicator");
     return INIT_FAILED;
    }
    
   new_trade.Initialization(); //инициализация объекта класса библиотеки TradeManeger  
    
   if (n>=N) //если параметры не корректны, то выставляем их по умолчанию
    {
     tn = 4;
     tN = 20;
    }
   else  //иначе сохраняем введенные пользователем
    {
     tn = n;
     tN = N;
    }     
    //переворачивания массивов
    ArraySetAsSeries(high,true); 
    ArraySetAsSeries(low,true); 
    ArraySetAsSeries(cur_color,true);
    ArraySetAsSeries(date_buffer,true);    
    
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   ArrayFree(high); 
   ArrayFree(low);
   ArrayFree(cur_color);
   ArrayFree(date_buffer);   
   new_trade.Deinitialization();  //деинициализация объекта класса библиотеки TradeManager
   
  }

void OnTick()
  {
new_trade.OnTick();
  //редим обработки баров
  if (  newCisBar.isNewBar()>0 )  //если сформировался новый бар
    {

     if( CopyBuffer(handle_PBI, 4, 1, 1, cur_color) <= 0)
        return;  
     if (cur_color[0]==MOVE_TYPE_FLAT ||    //если цвет совпал с требованиями
         cur_color[0]==MOVE_TYPE_CORRECTION_UP || 
         cur_color[0]==MOVE_TYPE_CORRECTION_DOWN)
         {       
      if (CopyBuffer(handle_PBI, 1, 1, tN, high) <= 0 || //если загрузка прошла не успешно
          CopyBuffer(handle_PBI, 2, 1, tN, low) <= 0)
          return;
          if (flagMax)  //если требуется найти максимум
           {
            MaxPos = ArrayMaximum(high);
            max_value = high[MaxPos];
            flagMax = false; //значит максимум найден
            proboy_max = true; //значит пробой еще не найден
            MaxPos--;
           }
          if (flagMin) //если требуется найти минимум
           {
            MinPos = ArrayMinimum(low);
            min_value = low[MinPos];
            flagMin = false; //значит минимум найден
            proboy_min = true;  //значит пробой еще не найден
            MinPos--;
           }             
         }

       if (!flagMax && proboy_max)  //если максимум найден а пробоя еще не было
        {
        MaxPos++; //смещаем текущее положение максимума влево
        if (MaxPos > tN) //если положение максимума от текущего бара превысило N
          flagMax = true; //то переходим в режим поиска нового максимума
        }
        
       if (!flagMin && proboy_min)  //если минимум найден а пробоя еще не было
        {
        MinPos++; //смещаем текущее положение минимума влево
        if (MinPos > tN) //если положение максимума от текущего бара превысило N
          flagMin = true; //то переходим в режим поиска нового максимума
        }        
        
     }
    //режим обработки тиков
    //поиск пробоев  
      
      if (!proboy_max) //если был пробой максимума
       {      
        if (diff >= (max_value-tick.ask) ) //проверка, что цена не двинулась замено дальше
         {
            if (!sellTest && tick.ask > max_value) //если цена вернулась назад
             {
           //   Alert("Трейлинг");
              tp = 0;
              
              sl = NormalizeDouble(MathMax(SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL)*_Point,
                         max_value-tick.ask) / _Point, SymbolInfoInteger(sym, SYMBOL_DIGITS));
               
              trade.OpenPosition(symbol, OP_SELL, volume, sl, tp, 0.0, 0.0, 0.0))
            
                 Alert("Продавать");
            
             }
            if (sellTest && tick.ask < max_value) //если цена опустилась
                sellTest = false; //переводим в режим проверки того, что цена вернулась
             
         }
        else
         {
          flagMax = true;
         }       
       }
       
      if (!proboy_min) //если был пробой минимума
       {      
        if (diff >= (tick.bid-min_value) ) //проверка, что цена не двинулась замено дальше
         {
            if (!buyTest && tick.bid < min_value) //если цена вернулась назад
             {
            //   Alert("Трейлинг");
              tp = 0;
              sl = NormalizeDouble(MathMax(SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL)*_Point,
                         tick.bid - min_value) / _Point, SymbolInfoInteger(sym, SYMBOL_DIGITS)); 
                         
              trade.OpenPosition(symbol, OP_BUY, volume, sl, tp, 0.0, 0.0, 0.0))           
             Alert("Покупать");
             }
            if (buyTest && tick.bid > min_value) //если цена поднялась
             buyTest = false; //переводим в режим проверки того, что цена вернулась
         }
        else
         {
          flagMin = true;
         }       
       }       
      
      if (!flagMax && proboy_max) //если максимум найден
       {
        //то ищем пробой по максиму
         if (MaxPos>=tn && tick.ask > max_value ) //если найден пробой
          {
           proboy_max = false;
           sellTest = true;
          }
       } 
      if (!flagMin && proboy_min) //если минимум найден
       {
        //то ищем пробой по минимуму
         if (MinPos>=tn && tick.bid < min_value ) //если найден пробой
          {
           proboy_min = false;
           buyTest = true;
          }
       }        
  }

