//+------------------------------------------------------------------+
//|                                          STATISTICS_19_lines.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs 

#include <ExtrLine\CExtremumCalc_NE.mqh>
#include <Lib CisNewBar.mqh>
#include <CheckHistory.mqh>


//+------------------------------------------------------------------+
//| Скрипт подсчета статистики 19 линий                              |
//+------------------------------------------------------------------+


// тип уровня
enum ENUM_LEVEL_TYPE
{
 EXTR_MN, 
 EXTR_W1,
 EXTR_D1,
 EXTR_H4,
 EXTR_H1
};

// перечисление типов положения цены относительно уровня
enum ENUM_LOCATION_TYPE
 {
  LOCATION_ABOVE=0,  // выше уровня
  LOCATION_BELOW,    // ниже уровня
  LOCATION_INSIDE    // внутри уровня
 };

// вводимые параметры скрипта
sinput string  stat_str="";                      // ПАРАМЕТРЫ ВЫЧИСЛЕНИЯ СТАТИСТИКИ
input datetime start_time = D'2012.01.01';       // начальная дата
input datetime end_time   = D'2014.04.01';       // конечная дата
input string   file_name  = "STAT_19_LINES.txt"; // имя файла статистики

sinput string atr_str = "";                      // ПАРАМЕТРЫ ИНДИКАТОРА АТR
input int    period_ATR = 100;                   // Период ATR для канала
input double percent_ATR = 0.03;                 // Ширина канала уровня в процентах от ATR
input double precentageATR_price = 1;            // Процентр ATR для нового экструмума
input ENUM_LEVEL_TYPE level = EXTR_H4;           // тип уровня

// локальные переменные скрипта
SExtremum estruct[3];
ENUM_TIMEFRAMES period_current = Period(); // текущий период
ENUM_TIMEFRAMES period_level;
CisNewBar is_new_level_bar;

int  countDownUp   = 0;                          // количество пробитий снизу вверх
int  countUpDown   = 0;                          // количество пробитий сверху вниз
int  countUpUp     = 0;                          // количество не пробитий сверху
int  countDownDown = 0;                          // количество не пробитий снизу
 
// хэндл индикатора 19 lines
int      handle_19Lines;

// индикаторные буферы
double   buffer_19Lines_price1[];
double   buffer_19Lines_price2[];
double   buffer_19Lines_price3[];
double   buffer_19Lines_atr1  [];
double   buffer_19Lines_atr2  [];
double   buffer_19Lines_atr3  [];
// буфер цен на заданному таймфрейме
MqlRates buffer_price[];  
       
// хранит предыдущее положение цены относительно уровней
ENUM_LOCATION_TYPE  prevLocLevel1;    // предыдущее положение цены относительно 1-го уровня
ENUM_LOCATION_TYPE  prevLocLevel2;    // предыдущее положение цены относительно 2-го уровня
ENUM_LOCATION_TYPE  prevLocLevel3;    // предыдущее положение цены относительно 3-го уровня
// хранит текущее положение цены относительно уровней
ENUM_LOCATION_TYPE  curLocLevel1;     // текущее положение цены относительно 1-го уровня
ENUM_LOCATION_TYPE  curLocLevel2;     // текущее положение цены относительно 2-го уровня
ENUM_LOCATION_TYPE  curLocLevel3;     // текущее положение цены относительно 3-го уровня
// флаги попадания цены в уровень
bool standOnLevel1;                   // флаг попадания в уровень 1
bool standOnLevel2;                   // флаг попадания в уровень 2
bool standOnLevel3;                   // флаг попадания в уровень 3


void OnStart()
  {
   // переменные для сохранения размеров загрузки буферов индикаторов
   int size1;
   int size2;
   int size3;
   int size4;
   int size5;
   int size6;
   int size_price;
   int start_index_buffer = 0; // первый номер набора буферов для 3 линий уровня 
   int bars;                   // количество баров всего 
   
   handle_19Lines = iCustom(Symbol(), PERIOD_M1, "NineteenLines_BB", period_ATR, percent_ATR, true, clrRed, true, clrRed, true, clrRed, true, clrRed, true, clrRed, true, clrRed); 
   if (handle_19Lines == INVALID_HANDLE)
     {
      PrintFormat("Не удалось создать хэндл индикатора");
      return;
     }
 
   for (int i = 0; i < 5; i++)
    {
     Sleep(1000);
     size1 = CopyBuffer(handle_19Lines, start_index_buffer    , start_time, end_time, buffer_19Lines_price1);
     size2 = CopyBuffer(handle_19Lines, start_index_buffer + 1, start_time, end_time, buffer_19Lines_atr1);
     size3 = CopyBuffer(handle_19Lines, start_index_buffer + 2, start_time, end_time, buffer_19Lines_price2);
     size4 = CopyBuffer(handle_19Lines, start_index_buffer + 3, start_time, end_time, buffer_19Lines_atr2);
     size5 = CopyBuffer(handle_19Lines, start_index_buffer + 4, start_time, end_time, buffer_19Lines_price3);
     size6 = CopyBuffer(handle_19Lines, start_index_buffer + 5, start_time, end_time, buffer_19Lines_atr3);
     size_price = CopyRates(_Symbol,PERIOD_M1,start_time,end_time,buffer_price);
     PrintFormat("bars = %d | size1=%d / size2=%d / size3=%d / size4=%d / size5=%d / size6=%d / sizePrice=%d", BarsCalculated(handle_19Lines), size1, size2, size3, size4, size5, size6,size_price);
    }   
    // получаем количество баров индикаторов
    bars = Bars(_Symbol,PERIOD_M1,start_time,end_time);
    // проверка на загрузку всех буферов 
    if ( size1!=bars || size2!=bars || size3!=bars ||size4!=bars||size5!=bars||size6!=bars||size_price!=bars)
      {
       Print("Не удалось прогрузить все буферы индикатора");
       return;
      }
    // сохраняем текущее положение цены относительно уровней
    prevLocLevel1 = GetCurrentPriceLocation(buffer_price[0].open,buffer_19Lines_price1[0],buffer_19Lines_atr1[0]);  
    // выставляем флаги нахождения в зоне уровня в false
    standOnLevel1  = false;
          Print("ЦЕНА НА УРОВНЕ = ",buffer_19Lines_price2[1]);   
    // проходим по всем барам цены  и считаем статистику проходов через уровни
    for (int index=1;index < bars; index++)
       {
       
        curLocLevel1 = GetCurrentPriceLocation(buffer_price[index].close,buffer_19Lines_price1[index],buffer_19Lines_atr1[index]);
        if (curLocLevel1 == LOCATION_INSIDE) standOnLevel1 = true;
        else 
         {
           if (curLocLevel1 == LOCATION_ABOVE && prevLocLevel1 == LOCATION_BELOW)
              {
               countDownUp ++;
               Print("Цена прошла снизу вверх в ",buffer_price[index].time);
              }
           if (curLocLevel1 == LOCATION_BELOW && prevLocLevel1 == LOCATION_ABOVE)
              {
               countUpDown ++;
               Print("Цена прошла сверху вниз в ",buffer_price[index].time); 
              }
           if (curLocLevel1 == LOCATION_ABOVE && prevLocLevel1 == LOCATION_ABOVE && standOnLevel1)
              {
               countUpUp ++;
               Print("Цена отбилась сверху вверх",buffer_price[index].time); 
              }
           if (curLocLevel1 == LOCATION_BELOW && prevLocLevel1 == LOCATION_BELOW && standOnLevel1)
              {
               countDownDown ++;
               
               Print("Цена отбилась снизу вниз",buffer_price[index].time);                
              }
           prevLocLevel1 = curLocLevel1;
           standOnLevel1 = false;
         }        
       }
Print("Количество пробитий снизу вверх = ",countDownUp);
Print("Количество пробитий сверху вниз = ",countUpDown);
Print("Количество отбитий сверху вверх = ",countUpUp);
Print("Количество отбитий снизу вниз = ",countDownDown);

  }
  
  
  
 // функция, возвращаюшая положение цены относительно заданного уровня
 
 ENUM_LOCATION_TYPE GetCurrentPriceLocation (double dPrice,double price19Lines,double atr19Lines)
  {
    ENUM_LOCATION_TYPE locType;  // переменная для хранения положения цены относительно уровня
     //if (dPrice 
    return(locType);
  }
  
  
 // функция сохранения результатов статистики по индикаторову 19 lines
 
 void SaveStatisticsToFile ()
  {
    
  }