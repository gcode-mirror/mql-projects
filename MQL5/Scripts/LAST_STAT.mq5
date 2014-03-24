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


input datetime  start_time = 0;    // время начала загрузки истории
input datetime  finish_time = 0;   // время завершения загрузки истории

MqlRates rates_array[];  // динамический массив котировок

long   countBars;        // количество баров
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

     
     double averCountA      = 0;   // среднее количество прибыльных ситуаций 1-го типа
     double averCountB      = 0;   // среднее количество прибльынх ситуаций 2-го типа
     double averCountLoss   = 0;   // среднее количество убыточных ситуаций
     double averWinSpreads  = 0;   // среднее количество выйгрышей в спредах
     double averLossSpreads = 0;   // среднее количество убытков в спредах
         
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
          // сохраняем количество баров
          countBars = Bars(symbolArray[i_sym],periodArray[i_per],start_time,finish_time);  
         /// Alert("КОЛИЧЕСТВО БАРОВ = ",countBars);       
          // очищаем массив
          ArrayFree(rates_array);
          // загружаем бары     
          copiedRates  = CopyRates(symbolArray[i_sym], periodArray[i_per],start_time, finish_time, rates_array);
          if ( copiedRates < countBars)
           { // если не удалось прогрузить все бары истории
            Alert("Не удалось прогрузить все бары истории");
            return;
           }   
           
          
          for (index=0;index<countBars;index++)
           {
              
             // Comment("ЦЕНА = ",rates_array[index].open+i_spread*rates_array[index].spread*_Point);
              if (GreatDoubles(rates_array[index].high, rates_array[index].open+i_spread*rates_array[index].spread*_Point) )
               {
                averCountA = averCountA + 1;  // увеличиваем количество прибыльных     
               }
              else
               {
                if (GreatDoubles(rates_array[index].close, rates_array[index].open+rates_array[index].spread*_Point) )
                 {
                  averCountB = averCountB + 1; // увеличиваем количество прибыльных
                  if (rates_array[index].spread > 0)
                   averWinSpreads = averWinSpreads + (rates_array[index].close-rates_array[index].open+rates_array[index].spread*_Point)/(rates_array[index].spread*_Point);
                 
                 }
                if (LessDoubles(rates_array[index].close, rates_array[index].open+rates_array[index].spread*_Point)  )
                 {
                  averCountLoss = averCountLoss + 1;     // увеличиваем количество убыточных
                  if (rates_array[index].spread > 0)
                    averLossSpreads = averLossSpreads + (rates_array[index].open+rates_array[index].spread*_Point - rates_array[index].close)/(rates_array[index].spread*_Point);                 
                 }
               } 
               
                                  
                          
           }  
           
           averCountA = averCountA*i_spread;  // получаем количество выиграных спредов
           averCountB = averCountA + averWinSpreads; // прибыль суммарная
           if (averLossSpreads > 0)
            averLossSpreads =  averLossSpreads / averCountB; // получаем соотношение прибыли к убытку
           
if (GreatOrEqualDoubles(averLossSpreads,1.5) )
 {           
  FileWriteString(file_handle,"["+symbolArray[i_sym]+","+PeriodToString(periodArray[i_per])+"]\n");
  FileWriteString(file_handle,"SPREAD = "+i_spread+"\n");       
  FileWriteString(file_handle,"Отношение прибыль к убытку: "+DoubleToString(averLossSpreads) + "\n\n");   
 }
     averCountA = 0;
     averCountB = 0;
     averCountLoss = 0;
     averLossSpreads = 0;
     averWinSpreads  = 0;         
           
           n_stat ++; // увеличиваем количество статистик
         
         }    
    
        }
        
        /*
         if (n_stat > 0)
           {
            averCountA = 1.0*averCountA / n_stat;
            
           }
         else
           averCountA = 0;
         if (n_stat > 0)
           {
            averCountB = 1.0*averCountB / n_stat;
            if (averCountB > 0)
             averWinSpreads = averWinSpreads / averCountB;
           }
         else
           averCountB = 0;
         if (n_stat > 0)
           {
            averCountLoss = averCountLoss / n_stat;
             if (averCountLoss > 0)
              averLossSpreads = averLossSpreads / averCountLoss;
           }
         else
           averCountLoss = 0;      
                         

        FileWriteString(file_handle,"Спред = "+IntegerToString(i_spread)+"\n");
        FileWriteString(file_handle,"Cреднее количество выйгрышей A: "+DoubleToString(averCountA,0)+"\n");
        FileWriteString(file_handle,"Cреднее количество выйгрышей B: "+DoubleToString(averCountB,0)+"\n");
        FileWriteString(file_handle,"Cреднее количество убытков: "+DoubleToString(averCountLoss,0)+"\n");
        FileWriteString(file_handle,"Среднее кол-во спредов прибыли: "+DoubleToString(averWinSpreads,0)+"\n");
        FileWriteString(file_handle,"Среднее кол-во спредов убытка: "+DoubleToString(averLossSpreads,0)+"\n");  
        FileWriteString(file_handle,"Средняя прибыль в спредах A: "+DoubleToString(averCountA*i_spread,0)+"\n");
        FileWriteString(file_handle,"Средняя прибыль в спредах B: "+DoubleToString(averCountB*averWinSpreads,0)+"\n");
        FileWriteString(file_handle,"Средний убыток в спредах: "+DoubleToString(averCountLoss*averLossSpreads,0)+"\n");
        FileWriteString(file_handle,"Отношение прибыль к убытку: "+DoubleToString( (averCountA*i_spread+averCountB*averWinSpreads)/(averCountLoss*averLossSpreads)) + "\n\n");              
             
   */
      
      }   
   
      FileClose(file_handle);
  }