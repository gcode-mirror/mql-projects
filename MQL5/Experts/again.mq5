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
input double   volume = 1;

double high[];   // массив высоких цен 
double low[];   // массив низких цен
double cur_color[]; //массив текущих цветов свечей 
double max_value=DBL_MAX;   //максимальное значение в массиве high
double min_value=DBL_MIN;   //минимальное значение в массиве low
double new_max_value;
double new_min_value;
double sl, tp;
datetime date_buffer[];          //буфер времени
int handle_PBI;     //хэндл PriceBasedIndicator
int tn; //действительное значение малого количества баров
int tN; //действительное значение большого количества баров
uint maxPos;     //позиция максимума в массиве high
uint minPos;     //позиция минимума в массиве low
CisNewBar newCisBar;     //массив по обработке баров
CTradeManager new_trade; //класс совершения сделок

string sym  =  _Symbol;
ENUM_TIMEFRAMES timeFrame=_Period;   //таймфрейм
MqlTick tick;
//флаги о загрузке поиске максимума и минимума среди N текущих баров
bool flagMax = false;  //флаг о поиске максимума 
bool flagMin = false;  //флаг о поиске минимума


bool proboy_max = false;  //условие пробоя максимума
bool proboy_min = false;  //условие пробоя минимума



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
  SymbolInfoTick(sym, tick);
  //режим обработки баров
  if (  newCisBar.isNewBar()>0 )  //если сформировался новый бар
    {
    
    if (!proboy_max) max_value = DBL_MAX;
    if (!proboy_min) min_value = DBL_MIN;
     if( CopyBuffer(handle_PBI, 4, 1, 1, cur_color) <= 0)
        return; 

     if (cur_color[0]==MOVE_TYPE_FLAT ||    //если цвет совпал с требованиями
         cur_color[0]==MOVE_TYPE_CORRECTION_UP || 
         cur_color[0]==MOVE_TYPE_CORRECTION_DOWN)
         {      
            
      if (CopyBuffer(handle_PBI, 1, tn, tN, high) <= 0 || //если загрузка прошла не успешно
          CopyBuffer(handle_PBI, 2, tn, tN, low) <= 0)
          return;
           if (!proboy_max)    //если пробой максимума не найден
            {
            maxPos = ArrayMaximum(high);
            max_value = high[maxPos];
            }
           if (!proboy_min)   //если пробой минимума не найден
            {
            minPos = ArrayMinimum(low,1);
            min_value = low[minPos];
            }
         }       
     }
    //режим обработки тиков
      if (!proboy_max) //если пробой максимума еще не найден
       {
        //то ищем пробой по максиму
         if (maxPos < tN && tick.bid > max_value ) //если найден пробой
          {
           proboy_max = true;
           new_max_value = tick.bid;
          }
       } 
     else
       {
         if (diff < (tick.bid-new_max_value) ) //если цена значительно двинулась вверх
           {
             proboy_max = false; //то переходим в режим поиска максимума
             max_value = DBL_MAX;
           }
         if (tick.ask < max_value) //если цена вернулась за max_value
           {
             Alert("Заявка исполнена");
           }  
       }  
      if (!proboy_min) //если пробой минимума еще не найден
       {
        //то ищем пробой по минимуму
         if (minPos>=tn && tick.ask < min_value ) //если найден пробой
          {
           proboy_min = false;
           new_min_value = tick.bid;
          }
       }    
      else
        {
         if (diff > (new_min_value-tick.ask) ) //если цена значительно двинулась вниз
          {
            proboy_min = false; //то переходим в режим поиска минимума
            min_value = DBL_MIN;
          }
         if (tick.bid > min_value)  //если цена вернулась за минимум
          {
            Alert("Заявка исполнена");
          } 
        }     
  }

