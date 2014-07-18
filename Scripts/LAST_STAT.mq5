//+------------------------------------------------------------------+
//|                                                   TALES_STAT.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs 
#include <CompareDoubles.mqh>                                           // для сравнения вещественных чисел
#include <StringUtilities.mqh> 

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+


input datetime  start_time  = 0;   // время начала загрузки истории
input datetime  finish_time = 0;   // время завершения загрузки истории

MqlRates rates_array[];  // динамический массив котировок

int    copiedRates;      

// массив символов
string symbolArray[6] =
 {
  "EURUSD",
  "GBPUSD",
  "USDCHF",
  "USDJPY",
  "USDCAD",
  "AUDUSD"
 };
// массив периодов
ENUM_TIMEFRAMES periodArray[20] =
 {
   PERIOD_M1,
   PERIOD_M2,
   PERIOD_M3,
   PERIOD_M4,
   PERIOD_M5,
   PERIOD_M6,
   PERIOD_M10,
   PERIOD_M12,
   PERIOD_M15,
   PERIOD_M20,
   PERIOD_M30,
   PERIOD_H1,
   PERIOD_H2,
   PERIOD_H3,
   PERIOD_H4,
   PERIOD_H6,
   PERIOD_H8,
   PERIOD_D1,
   PERIOD_W1,
   PERIOD_MN1  
 };
 
void OnStart()
  {
     int i_per;              // счетчик прохода по периодам
     int i_sym;              // счетчик прохода по символам
     int i_spread;           // счетчик прохода по количеству спредов 
     int index;              // счетчик прохода по барам
     int n_stat = 0;         // количество статистик
     int file_handle;        // хэндл файла статистики

     
     double countA      = 0;       // среднее количество убыточных ситуаций 1-го типа
     double countB      = 0;       // среднее количество убыточных ситуаций 2-го типа
     double countWin    = 0;       // среднее количество прибыльных ситуаций
     double averLossSpreads = 0;   // средний размер убытков в спредах
     double averWinSpreads  = 0;   // среднее размер прибыли в спредах
     double spreadsLoss     = 0;   // проигрыш по спредам
     
     double win;                   // суммарная прибыль
     double lose;                  // сумммарный убыток
     double percent;               // отношение прибыли к убыли
     
     int countCount = 0;
     
      // создает файл статистики 
      file_handle = FileOpen("TAKIE_DELA.txt", FILE_WRITE|FILE_COMMON|FILE_ANSI|FILE_TXT, " ");
      if (file_handle == INVALID_HANDLE) //не удалось открыть файл
        {
         Alert("Ошибка открытия файла");
         return;
        }  
         
    for (i_spread = 1; i_spread <= 50; i_spread++)
     {
     n_stat  = 0;
     for (i_sym=0;i_sym<6;i_sym++)
      { 
       for (i_per=0;i_per<20;i_per++)
        {     
          // очищаем массив
          ArrayFree(rates_array);
          
          // загружаем бары         
          copiedRates  = CopyRates(symbolArray[i_sym], periodArray[i_per],start_time, finish_time, rates_array);
  
          spreadsLoss = 0;  // обнуляем количество проигранных спредов
          
          for (index=0;index<copiedRates;index++)
           {
              if (GreatDoubles(rates_array[index].high, rates_array[index].open+i_spread*rates_array[index].spread*_Point) )
               {          
                countA  = countA  + 1;  // увеличиваем количество убыточных 
                spreadsLoss = spreadsLoss + rates_array[index].spread*_Point; // увеличиваем убыток на спред
               }
              else
               {
                if (GreatDoubles(rates_array[index].close, rates_array[index].open) )
                 {
                  countB = countB + 1; // увеличиваем количество убыточных
                  spreadsLoss = spreadsLoss + rates_array[index].spread*_Point;  // увеличиваем убыток в спредах
                  if (rates_array[index].spread > 0)
                   averLossSpreads = averLossSpreads + (rates_array[index].close-rates_array[index].open/*+rates_array[index].spread*_Point*/)/(rates_array[index].spread*_Point);      
                 }
                if (LessDoubles(rates_array[index].close, rates_array[index].open)  )
                 {
                  countWin = countWin + 1;     // увеличиваем количество прибыльных
                  spreadsLoss = spreadsLoss + rates_array[index].spread*_Point;  // увеличиваем убыток в спредах            
                  if (rates_array[index].spread > 0)
                    averWinSpreads = averWinSpreads + (rates_array[index].open/*+rates_array[index].spread*_Point*/ - rates_array[index].close)/(rates_array[index].spread*_Point);                 
                 }
               } 
               
                                  
                          
           }  
           
           
            
           win             = averWinSpreads;  // прибыльная часть сделок
           
           lose            = countA*i_spread + spreadsLoss + averLossSpreads;   // убыточная часть
            
            
           Comment("Соотношение: ",countCount,"/6000");
           countCount++;
           if (lose > 0)
            percent =  win / lose; // получаем соотношение прибыли к убытку
           
if (GreatOrEqualDoubles(averLossSpreads,1.5) )
 {           
  FileWriteString(file_handle,"["+symbolArray[i_sym]+","+PeriodToString(periodArray[i_per])+"]\n");
  FileWriteString(file_handle,"SPREAD = "+i_spread+"\n");       
  FileWriteString(file_handle,"Отношение прибыль к убытку: "+DoubleToString(percent) + "\n\n");   
 }
     // обнуляем счетчики
     countA = 0;
     countB = 0;
     countWin = 0;
     averLossSpreads = 0;
     averWinSpreads  = 0;         
           
           n_stat ++; // увеличиваем количество статистик
         
         }    
    
        }
        
       
      
      }   
   
      FileClose(file_handle);
  }