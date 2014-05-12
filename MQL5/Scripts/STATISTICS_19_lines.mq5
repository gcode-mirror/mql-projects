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
#include <CheckHistory.mqh>


//+------------------------------------------------------------------+
//| Скрипт подсчета статистики 19 линий                              |
//+------------------------------------------------------------------+

// перечисления режима вычисления статистики (по уровням)

enum ENUM_CALCULATE_TYPE
 {      
  CALC_H1 = 0,                                   // часовые уровни
  CALC_H4,                                       // 4-х часовые уровни
  CALC_D1,                                       // дневные уровни 
  CALC_W1,                                       // недельные уровни
  CALC_MN1                                       // месячные уровни
 };

// перечисление типов положения цены относительно уровня
enum ENUM_LOCATION_TYPE
 {
  LOCATION_ABOVE=0,                              // выше уровня
  LOCATION_BELOW,                                // ниже уровня
  LOCATION_INSIDE                                // внутри уровня
 };

// вводимые параметры скрипта
sinput string  stat_str="";                      // ПАРАМЕТРЫ ВЫЧИСЛЕНИЯ СТАТИСТИКИ
input datetime start_time = D'2012.01.01';       // начальная дата
input datetime end_time   = D'2014.04.01';       // конечная дата
input ENUM_CALCULATE_TYPE calc_type = CALC_W1;   // уровни, по которым вычислять статистику
input string   file_name  = "STAT_19_LINES";     // имя файла статистики

sinput string atr_str = "";                      // ПАРАМЕТРЫ ИНДИКАТОРА АТR
input int    period_ATR = 30;                    // Период ATR для канала
input double percent_ATR = 0.5;                  // Ширина канала уровня в процентах от ATR

int  countDownUp   = 0;                          // количество пробитий снизу вверх
int  countUpDown   = 0;                          // количество пробитий сверху вниз
int  countUpUp     = 0;                          // количество не пробитий сверху
int  countDownDown = 0;                          // количество не пробитий снизу
int  countDone     = 0;                          // количество сработавших уровней
int  countUnDone   = 0;                          // количество не сработавших уровней
 
// хэндл индикатора 19 lines
int      handle_19Lines;

// индикаторные буферы
double   buffer_19Lines_price4[];
double   buffer_19Lines_price3[];
double   buffer_19Lines_atr4  [];
double   buffer_19Lines_atr3  [];
// буфер цен на заданному таймфрейме
MqlRates buffer_price[];  
       
// хранит предыдущее положение цены относительно уровней
ENUM_LOCATION_TYPE  prevLocLevel4;    // предыдущее положение цены относительно 4-го уровня
ENUM_LOCATION_TYPE  prevLocLevel3;    // предыдущее положение цены относительно 3-го уровня
// хранит текущее положение цены относительно уровней
ENUM_LOCATION_TYPE  curLocLevel4;     // текущее положение цены относительно 4-го уровня
ENUM_LOCATION_TYPE  curLocLevel3;     // текущее положение цены относительно 3-го уровня
// флаги попадания цены в уровень
bool standOnLevel4;                   // флаг попадания в уровень 4
bool standOnLevel3;                   // флаг попадания в уровень 3
// счетчики подсчета количества баров внутри уровней
int countBarsInsideLevel4=0;          // внутри четвертого уровня
int countBarsInsideLevel3=0;          // внутри третьего уровня

// хэндлы файлов статистики
int fileHandle;                       // хэндл файла статистики
int fileTestStat;                     // хэндл файла проверки статистики прохождения уровней

// текущие значения буферов
double curBuf4;                       // текущее значение 4-го буфера
double curBuf3;                       // текущее значение 3-го буфера

void OnStart()
  {
   // переменные для сохранения размеров загрузки буферов индикаторов
   int size3;
   int size4;
   int size5;
   int size6;
   int size_price;
   int start_index_buffer;            // первый номер набора буферов для 3 линий уровня 
   int bars;                          // количество баров всего 
    
   // создаем хэндл индикатора 19 линий (в зависимости от параметра calc_type)  
   
   switch (calc_type)
    {
     case CALC_D1:   // дневник
      handle_19Lines = iCustom(Symbol(), PERIOD_M1, "NineteenLines_BB", period_ATR, percent_ATR, 
      false, clrRed, false, clrRed, true, clrRed, false, clrRed, false, clrRed, false, clrRed);   
      start_index_buffer = 12;  
     break;
     case CALC_H1:   // часовик
      handle_19Lines = iCustom(Symbol(), PERIOD_M1, "NineteenLines_BB", period_ATR, percent_ATR, 
      false, clrRed, false, clrRed, false, clrRed, false, clrRed, true, clrRed, false, clrRed);
      start_index_buffer = 24;      
     break;
     case CALC_H4:   // четырех часовик
      handle_19Lines = iCustom(Symbol(), PERIOD_M1, "NineteenLines_BB", period_ATR, percent_ATR, 
      false, clrRed, false, clrRed, false, clrRed, true, clrRed, false, clrRed, false, clrRed);  
      start_index_buffer = 18;   
     break;
     case CALC_MN1:  // месяц
      handle_19Lines = iCustom(Symbol(), PERIOD_M1, "NineteenLines_BB", period_ATR, percent_ATR, 
      true, clrRed, false, clrRed, false, clrRed, false, clrRed, false, clrRed, false, clrRed);  
      start_index_buffer = 0;    
     break;
     case CALC_W1:   // неделька
      handle_19Lines = iCustom(Symbol(), PERIOD_M1, "NineteenLines_BB", period_ATR, percent_ATR, 
      false, clrRed, true, clrRed, false, clrRed, false, clrRed, false, clrRed, false, clrRed); 
      start_index_buffer = 6;    
     break;
    }
            

   if (handle_19Lines == INVALID_HANDLE)
     {
      PrintFormat("Не удалось создать хэндл индикатора");
      return;
     }
    // создаем хэндл файла тестирования статистики прохождения уровней
    fileTestStat = FileOpen(file_name+"_test.txt",FILE_WRITE|FILE_COMMON|FILE_ANSI|FILE_TXT, "");
    if (fileTestStat == INVALID_HANDLE) //не удалось открыть файл
     {
      Print("Не удалось создать файл тестирования статистики прохождения уровней");
      return;
     }       
 
   for (int i = 0; i < 5; i++)
    {
     Sleep(1000);
     size3 = CopyBuffer(handle_19Lines, start_index_buffer + 2, start_time, end_time, buffer_19Lines_price4);
     size4 = CopyBuffer(handle_19Lines, start_index_buffer + 3, start_time, end_time, buffer_19Lines_atr4);
     size5 = CopyBuffer(handle_19Lines, start_index_buffer + 4, start_time, end_time, buffer_19Lines_price3);
     size6 = CopyBuffer(handle_19Lines, start_index_buffer + 5, start_time, end_time, buffer_19Lines_atr3);
     size_price = CopyRates(_Symbol,PERIOD_M1,start_time,end_time,buffer_price);
     PrintFormat("bars = %d |  size3=%d / size4=%d / size5=%d / size6=%d / sizePrice=%d", BarsCalculated(handle_19Lines), size3, size4, size5, size6,size_price);
    }   
    // получаем количество баров индикаторов
    bars = Bars(_Symbol,PERIOD_M1,start_time,end_time);
    
    // проверка на загрузку всех буферов 
    if ( size3!=bars ||size4!=bars||size5!=bars||size6!=bars||size_price!=bars)
      {
       Print("Не удалось прогрузить все буферы индикатора");
       return;
      }
    // сохраняем текущее положение цены относительно уровней
    prevLocLevel4  =  GetCurrentPriceLocation(buffer_price[0].open,buffer_19Lines_price4[0],buffer_19Lines_atr4[0]);  
    prevLocLevel3  =  GetCurrentPriceLocation(buffer_price[0].open,buffer_19Lines_price3[0],buffer_19Lines_atr3[0]);               
    // выставляем флаги нахождения в зоне уровня в false
    standOnLevel4  = false;
    standOnLevel3  = false;
    // сохраним текущую цену на уровнях
    curBuf4        = buffer_19Lines_price4[0];
    curBuf3        = buffer_19Lines_price3[0];
  
    // проходим по всем барам цены  и считаем статистику проходов через уровни
    for (int index=1;index < bars; index++)
       {
  
        /////ДЛЯ ЧЕТВЕРТОГО УРОВНЯ//////  
      
        if ( curBuf4 != buffer_19Lines_price4[index] ) // если значения буферов отличаются
         {
           // то сохраним текущую цену уровня
           curBuf4 = buffer_19Lines_price4[index];
           // и предыдущее положение цены относительно уровня
           prevLocLevel4  = GetCurrentPriceLocation(buffer_price[index].open,buffer_19Lines_price4[index],buffer_19Lines_atr4[index]);  
           // обнуляем флаг нахождения в зоне уровня 
           standOnLevel4 = false;
           // обнуляем счетчик баров внутри уровня
           countBarsInsideLevel4 = 0;        
         }  
        else   // если буфер не изменил своего предыдушего положения
        {       
          curLocLevel4 = GetCurrentPriceLocation(buffer_price[index].close,buffer_19Lines_price4[index],buffer_19Lines_atr4[index]);
        
          if (curLocLevel4 == LOCATION_INSIDE) 
            {
             // если еще и Open находится внутри уровня
             if (GetCurrentPriceLocation(buffer_price[index].open,buffer_19Lines_price4[index],buffer_19Lines_atr4[index])  == LOCATION_INSIDE)
                 countBarsInsideLevel4++;  // то увеличиваем количество баров внутри уровня
             standOnLevel4 = true;
            }
          else 
            {   
             if (curLocLevel4 == LOCATION_ABOVE && prevLocLevel4 == LOCATION_BELOW)
               {
                countDownUp ++;
                if (standOnLevel4)  // если бары находились внутри уровня. то уровень сработавший
                 countDone ++;
                else
                 countUnDone ++;
                if (standOnLevel4)
                 FileWriteString(fileTestStat,"\n(4) Сработал Цена прошла снизу вверх в "+TimeToString(buffer_price[index].time)+" количество баров внутри уровня = "+IntegerToString(countBarsInsideLevel4)+" ATR = "+DoubleToString(buffer_19Lines_atr4[index])+" PRICE = "+DoubleToString(buffer_19Lines_price4[index]));
                else
                 FileWriteString(fileTestStat,"\n(4) Не сработал Цена прошла снизу вверх в "+TimeToString(buffer_price[index].time)+" количество баров внутри уровня = "+IntegerToString(countBarsInsideLevel4)+" ATR = "+DoubleToString(buffer_19Lines_atr4[index])+" PRICE = "+DoubleToString(buffer_19Lines_price4[index]));                 
               }
             if (curLocLevel4 == LOCATION_BELOW && prevLocLevel4 == LOCATION_ABOVE)
               {
                countUpDown ++;
                if (standOnLevel4)  // если бары находились внутри уровня. то уровень сработавший
                 countDone ++;
                else
                 countUnDone ++;
                 if (standOnLevel4)                
                  FileWriteString(fileTestStat,"\n(4) Сработал Цена прошла сверху вниз в "+TimeToString(buffer_price[index].time)+" количество баров внутри уровня = "+IntegerToString(countBarsInsideLevel4)+" ATR = "+DoubleToString(buffer_19Lines_atr4[index])+" PRICE = "+DoubleToString(buffer_19Lines_price4[index])); 
                 else
                  FileWriteString(fileTestStat,"\n(4) Не сработал Цена прошла сверху вниз в "+TimeToString(buffer_price[index].time)+" количество баров внутри уровня = "+IntegerToString(countBarsInsideLevel4)+" ATR = "+DoubleToString(buffer_19Lines_atr4[index])+" PRICE = "+DoubleToString(buffer_19Lines_price4[index]));                  
               }
             if (curLocLevel4 == LOCATION_ABOVE && prevLocLevel4 == LOCATION_ABOVE && standOnLevel4)
               {
                countUpUp ++;
                countDone ++; 
                FileWriteString(fileTestStat,"\n(4) Сработал Цена отбилась сверху вверх в "+TimeToString(buffer_price[index].time)+" количество баров внутри уровня = "+IntegerToString(countBarsInsideLevel4)+" ATR = "+DoubleToString(buffer_19Lines_atr4[index])+" PRICE = "+DoubleToString(buffer_19Lines_price4[index])); 
               }
             if (curLocLevel4 == LOCATION_BELOW && prevLocLevel4 == LOCATION_BELOW && standOnLevel4)
               {
                countDownDown ++;
                countDone     ++;  
                FileWriteString(fileTestStat,"\n(4) Сработал Цена отбилась снизу вниз в "+TimeToString(buffer_price[index].time)+" количество баров внутри уровня = "+IntegerToString(countBarsInsideLevel4)+" ATR = "+DoubleToString(buffer_19Lines_atr4[index])+" PRICE = "+DoubleToString(buffer_19Lines_price4[index]));                
               }
             // обнуляем подсчет баров внутри уровня
             countBarsInsideLevel4 = 0;   
             prevLocLevel4 = curLocLevel4;
             standOnLevel4 = false;
            }  
           } ///END ДЛЯ ЧЕТВЕРТОГО УРОВНЯ
        
        
        
         /////ДЛЯ ТРЕТЬЕГО УРОВНЯ//////        
        if ( curBuf3 != buffer_19Lines_price3[index]  ) // если значения буферов отличаются
         {
           // то сохраним текущую цену уровня
           curBuf3 = buffer_19Lines_price3[index];
           // и предыдущее положение цены относительно уровня
           prevLocLevel3  = GetCurrentPriceLocation(buffer_price[index].open,buffer_19Lines_price3[index],buffer_19Lines_atr3[index]);  
           // обнуляем флаг нахождения в зоне уровня 
           standOnLevel3 = false;
           // обнуляем счетчик баров внутри уровня
           countBarsInsideLevel3 = 0;                        
         }     
        else // иначе
         { 
          curLocLevel3 = GetCurrentPriceLocation(buffer_price[index].close,buffer_19Lines_price3[index],buffer_19Lines_atr3[index]);
        
          if (curLocLevel3 == LOCATION_INSIDE) 
            {
             // если еще и Open находится внутри уровня
             if (GetCurrentPriceLocation(buffer_price[index].open,buffer_19Lines_price3[index],buffer_19Lines_atr3[index])  == LOCATION_INSIDE)
              countBarsInsideLevel3++;  // то увеличиваем количество баров внутри уровня
             standOnLevel3 = true;
            }
          else 
            {   
             if (curLocLevel3 == LOCATION_ABOVE && prevLocLevel3 == LOCATION_BELOW)
                {
                 countDownUp ++;
                if (standOnLevel3)  // если бары находились внутри уровня. то уровень сработавший
                 countDone ++;
                else
                 countUnDone ++;  
                 if (standOnLevel3)               
                  FileWriteString(fileTestStat,"\n(3) Сработал Цена прошла снизу вверх в "+TimeToString(buffer_price[index].time)+"; количество баров внутри уровня = "+IntegerToString(countBarsInsideLevel3)+" ATR = "+DoubleToString(buffer_19Lines_atr3[index])+" PRICE = "+DoubleToString(buffer_19Lines_price3[index]));
                 else
                  FileWriteString(fileTestStat,"\n(3) Не сработал Цена прошла снизу вверх в "+TimeToString(buffer_price[index].time)+"; количество баров внутри уровня = "+IntegerToString(countBarsInsideLevel3)+" ATR = "+DoubleToString(buffer_19Lines_atr3[index])+" PRICE = "+DoubleToString(buffer_19Lines_price3[index]));                  
                }
             if (curLocLevel3 == LOCATION_BELOW && prevLocLevel3 == LOCATION_ABOVE)
                {
                 countUpDown ++;
                if (standOnLevel3)  // если бары находились внутри уровня. то уровень сработавший
                 countDone ++;
                else
                 countUnDone ++;
                 if (standOnLevel3)                 
                  FileWriteString(fileTestStat,"\n(3) Сработал Цены прошла сверху вниз в "+TimeToString(buffer_price[index].time)+";количество баров внутри уровня = "+IntegerToString(countBarsInsideLevel3)+" ATR = "+DoubleToString(buffer_19Lines_atr3[index])+" PRICE = "+DoubleToString(buffer_19Lines_price3[index])); 
                 else
                  FileWriteString(fileTestStat,"\n(3) Не сработал Цены прошла сверху вниз в "+TimeToString(buffer_price[index].time)+";количество баров внутри уровня = "+IntegerToString(countBarsInsideLevel3)+" ATR = "+DoubleToString(buffer_19Lines_atr3[index])+" PRICE = "+DoubleToString(buffer_19Lines_price3[index]));                  
                }
             if (curLocLevel3 == LOCATION_ABOVE && prevLocLevel3 == LOCATION_ABOVE && standOnLevel3)
                {
                 countUpUp ++;
                 countDone ++;  
                 FileWriteString(fileTestStat,"\n(3) Сработал Цена отбилась сверху вверх в "+TimeToString(buffer_price[index].time)+"; количество баров внутри уровня = "+IntegerToString(countBarsInsideLevel3)+" ATR = "+DoubleToString(buffer_19Lines_atr3[index])+" PRICE = "+DoubleToString(buffer_19Lines_price3[index])); 
                }
             if (curLocLevel3 == LOCATION_BELOW && prevLocLevel3 == LOCATION_BELOW && standOnLevel3)
                {
                 countDownDown ++;
                 countDone     ++;  
                 FileWriteString(fileTestStat,"\n(3) Сработал Цена отбилась снизу вниз в "+TimeToString(buffer_price[index].time)+"; количество баров внутри уровня = "+IntegerToString(countBarsInsideLevel3)+" ATR = "+DoubleToString(buffer_19Lines_atr3[index])+" PRICE = "+DoubleToString(buffer_19Lines_price3[index]));                
                }
            // обнуляем подсчет баров внутри уровня
            countBarsInsideLevel3 = 0;   
            prevLocLevel3 = curLocLevel3;
            standOnLevel3 = false;
           } 
          }  ///END ДЛЯ ТРЕТЬЕГО УРОВНЯ        
          
           
       }

   // закрываем файл тестирования статистики прохождения уровней
   FileClose(fileTestStat);
   // сохраним результаты статистики в файл
   SaveStatisticsToFile ();
 
  }
  
  
  
 // функция, возвращаюшая положение цены относительно заданного уровня
 
 ENUM_LOCATION_TYPE GetCurrentPriceLocation (double dPrice,double price19Lines,double atr19Lines)
  {
    ENUM_LOCATION_TYPE locType = LOCATION_INSIDE;  // переменная для хранения положения цены относительно уровня
     if ( GreatDoubles (dPrice,(price19Lines+atr19Lines) ) )
      locType = LOCATION_ABOVE;
     if ( LessDoubles (dPrice,(price19Lines-atr19Lines) ) )     
      locType = LOCATION_BELOW;
     
    return(locType);
  }
  
 // функция возвращает строку по 
 
 string GetLevelString ()
  {
   string str;
   switch (calc_type)
    {
     case CALC_D1:
      str = "D1";
     break;
     case CALC_H1:
      str = "H1";
     break;
     case CALC_H4:
      str = "H4";
     break;
     case CALC_MN1:
      str = "MN1";
     break;
     case CALC_W1:
      str = "W1";
     break; 
     
    }
   return (str);
  }
  
 // функция сохранения результатов статистики по индикаторову 19 lines
 
 void SaveStatisticsToFile ()
  {
    // создаем хэндл файла статистики
    fileHandle = FileOpen(file_name+".txt",FILE_WRITE|FILE_COMMON|FILE_ANSI|FILE_TXT, "");
    if (fileHandle == INVALID_HANDLE) //не удалось открыть файл
     {
      Print("Не удалось создать файл статистики");
      return;
     }  
    FileWriteString(fileHandle,"Статистика по уровням (Уровни на "+GetLevelString ()+"):\n\n");
    FileWriteString(fileHandle,"Количество прохождений через уровень сверху вниз: "+IntegerToString(countUpDown));
    FileWriteString(fileHandle,"\nКоличество прохождений через уровень снизу вверх: "+IntegerToString(countDownUp));
    FileWriteString(fileHandle,"\nКоличество отбитий от уровня сверху вверх : "+IntegerToString(countUpUp));
    FileWriteString(fileHandle,"\nКоличество отбитий от уровня снизу вниз: "+IntegerToString(countDownDown));
    FileWriteString(fileHandle,"\nКоличество сработавших уровней: "+IntegerToString(countDone));  
    FileWriteString(fileHandle,"\nКоличество НЕ сработавших уровней: "+IntegerToString(countUnDone));  
    // закрываем файл статистики
    FileClose(fileHandle);            
  }