//+------------------------------------------------------------------+
//|                                                   TALES_STAT.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <CompareDoubles.mqh>                                           // для сравнения вещественных чисел

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+

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
     int countTales;         // счетчик баров с хвостами
     int n_stat = 0;         // количество статистик
     double percent = 0;     // средний процент для всех статистик
     int file_handle;        // хэндл файла статистики
     double aver_spread = 0; // средний размер спреда
     
     int countProfitA = 0;       // количество прибыльных ситуаций 1-го типа
     int countProfitB = 0;       // количество прибыльных ситуаций 2-го типа
     int countLoss    = 0;          // количество убыточных ситуаций  
     
     bool  openedPosition = false;   // флаг, имитирующий открытие\закрытие позиции
     
     
      // создает файл статистики 
      file_handle = FileOpen("OGON.txt", FILE_WRITE|FILE_COMMON|FILE_ANSI|FILE_TXT, " ");
      if (file_handle == INVALID_HANDLE) //не удалось открыть файл
        {
         Alert("Ошибка открытия файла");
         return;
        }  
   
    for (i_spread = 1; i_spread <= 1000; i_spread+=10)
     {
     percent = 0;
     n_stat  = 0;
     aver_spread = 0;
     countTales = 0;

     for (i_sym=0;i_sym<6;i_sym++)
      { 
       for (i_per=0;i_per<20;i_per++)
        {
          // сохраняем количество баров
          countBars = Bars(symbolArray[i_sym],periodArray[i_per]);         
          // очищаем массив
          ArrayFree(rates_array);
          // загружаем бары     
          copiedRates  = CopyRates(symbolArray[i_sym], periodArray[i_per],0, countBars, rates_array);
          if ( copiedRates < countBars)
           { // если не удалось прогрузить все бары истории
            Alert("Не удалось прогрузить все бары истории");
            return;
           }   
          
          openedPosition = false;  // выставляем позицию, как не открытую 
          
          for (index=0;index<countBars;index++)
           {
  
              if (  GreatDoubles(rates_array[index].high, i_spread*rates_array[index].spread*_Point+rates_array[index].open) == true  )
               {
                countProfitA ++;  // увеличиваем количество прибыль           
               }
              

           }  
         
         }    
    
        }
   
           if (countTales > 0)
            {
             FileWriteString(file_handle,"Спред = ",IntegerToString(i_spread)+"\n");
             FileWriteString(file_handle,""+DoubleToString(aver_spread/countTales)+"\n\n");
            }
             
   
      
      }   
   
      FileClose(file_handle);
  }