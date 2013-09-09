#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include  <ColoredTrend/ColoredTrendUtilities.mqh> //загружаю бибилиотеку цветов
#include <CompareDoubles.mqh>    //для сравнения действительных переменных
#include <Lib CisNewBar.mqh>     //для проверки баров
#include<TradeManager/TradeManager.mqh> //для совершения сделок
#include<ma_value.mqh> //подключаем библиотеку для отображения параметров

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

int check=0; //проверка заполнения формы

bool first_disp = true; //первое отображение

double my_max;
double my_sec_max;
double my_return;
double my_min;
double my_sec_min;




void PrintInfo (bool what) 
{
 if (first_disp )
  {
 CreateEdit(0,0,"InfoPanelBackground","",corner,font_name,8,clrWhite,x_first_column,200,331,y_bg,0,C'15,15,15',true);
 CreateEdit(0,0,"InfoPanelHeader","Параметры сделки",corner,font_name,8,clrWhite,x_first_column,200,231,y_bg,1,clrFireBrick,true);
  first_disp  = false;
  }
 switch (what)
  {
   case true: 
   Print("fuck");
 CreateLabel(0,0,"ololo","Пред. максимум: "+DoubleToString(my_max),anchor,corner,font_name,font_size,font_color,x_first_column,60,2);   
 CreateLabel(0,0,"ololo2","Второй. максимум: "+DoubleToString(my_sec_max),anchor,corner,font_name,font_size,font_color,x_first_column,90,2);   
 CreateLabel(0,0,"ololo3","Возвратное значение: "+DoubleToString(my_return),anchor,corner,font_name,font_size,font_color,x_first_column,120,2);  
   break;
   case false: 
 CreateLabel(0,0,"ololo","Пред. минимум: "+DoubleToString(my_min),anchor,corner,font_name,font_size,font_color,x_first_column,60,2);   
 CreateLabel(0,0,"ololo2","Второй. минимум: "+DoubleToString(my_sec_min),anchor,corner,font_name,font_size,font_color,x_first_column,90,2);   
 CreateLabel(0,0,"ololo3","Возвратное значение: "+DoubleToString(my_return),anchor,corner,font_name,font_size,font_color,x_first_column,120,2);  
 
   break;   
  }
  

}


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
      if (CopyBuffer(handle_PBI, 1, tn, tN-tn, high) <= 0 || //если загрузка прошла не успешно
          CopyBuffer(handle_PBI, 2, tn, tN-tn, low) <= 0)
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
        else if (tick.ask < max_value) //если цена вернулась за max_value
           {
    sl = NormalizeDouble(MathMax(SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL)*_Point,
                         new_max_value - tick.ask) / _Point, SymbolInfoInteger(sym, SYMBOL_DIGITS));
    tp = 0; 
      if (new_trade.OpenPosition(sym, OP_SELL, volume, sl, tp, 0.0, 0.0, 0.0))
    {
    
          
        my_max = max_value;
        my_return = tick.ask;
        my_sec_max = new_max_value;
        
   
        PrintInfo(true);
       

    }
       max_value = DBL_MAX;
       proboy_max = false;
           }  
         else 
           {
            if (tick.bid > new_max_value) new_max_value = tick.bid;
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
       else   if (tick.bid > min_value)  //если цена вернулась за минимум
          {
    sl = NormalizeDouble(MathMax(SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL)*_Point,
                         tick.bid-new_min_value) / _Point, SymbolInfoInteger(sym, SYMBOL_DIGITS));
    tp = 0; 
    if (new_trade.OpenPosition(sym, OP_BUY, volume, sl, tp, 0.0, 0.0, 0.0))
    {
     Print("BUY");
     

        my_min = min_value;
        my_return = tick.bid;
        my_sec_min = new_min_value;


        PrintInfo(false);
    
    }
       min_value = DBL_MIN;
       proboy_min = false;
    
          } 
         else 
           {
            if (tick.ask < new_min_value) new_min_value = tick.ask;
           }    
        }     
  }

