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

uint mode = 0; //режим расчета

MqlTick tick;


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
  if (  newCisBar.isNewBar()>0 )  //если сформировался новый бар
    {
    if (mode == 0) //режим загрузки баров
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
          mode=1;
          MaxPos = ArrayMaximum(high);
          MinPos = ArrayMaximum(low);
          max_value = high[MaxPos];
          min_value = low[MinPos];
          MaxPos--;
          MinPos--;
         }
     } 
     else if (mode == 1) //режим отступов
      {
        MaxPos++;
        MinPos++;
        if (MaxPos > tN && MinPos>tN)
          mode = 0; 
      }    
    }
  //режим тиков
    switch (mode)
     {
      case 1:
      if (MaxPos>=tn && MaxPos<=tN && tick.bid > max_value) //пробой максимума
        {
         mode=2; //перевод в режим ожидания продажи
        }
      
      if (MinPos>=tn && MinPos<=tN && tick.ask < min_value) //пробой минимума 
        {
         mode=3; //перевод в режим ожидания покупки
        }    
      break;
      case 2: //ожидание продажи
      
      if (tick.bid < max_value)  //если цена вернулась назад
        {
          //сделка о продаже совершена     
        }
      if (diff < MathAbs(max_value-tick.bid) && max_value < tick.bid)
        {
          mode = 0;
          //переход в начальный режим. Сделка не совершена
        }
      
      break;   
      case 3: //ожидание покупки
      
      if (tick.ask > min_value) //если цена вернулась назад
        {
          //сделка о покупке совершена
        }
      if (diff < MathAbs(min_value-tick.ask) && min_value < tick.ask)
        {
          mode = 0;
          //переход в начальный режим. Сделка не совершена
        }   
      
      break;
       
     }  
    
  
  }

