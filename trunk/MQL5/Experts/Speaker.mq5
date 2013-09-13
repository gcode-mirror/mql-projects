//+------------------------------------------------------------------+
//|                                                      Speaker.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Эксперт, сохраняющие в файл последнюю сделку и свойства позиции  |
//+------------------------------------------------------------------+
long   deal_type=0;  //тип сделки
double deal_volume=0; //объем сделки
double deal_price=0; //цена сделки
long   first_time;     //самая первая дата при загрузке эксперта



bool CurrentPositionLastDealPrice() //возвращает параметры последней сделки
  {
   int    total       =0;   // Всего сделок в списке выбранной истории
   string deal_symbol ="";  // Символ сделки 
//--- Если история позиции получена
   if(HistorySelect(first_time,TimeCurrent()))
     {
      //--- Получим количество сделок в полученном списке
      total=HistoryDealsTotal();     
      //--- Пройдем по всем сделкам в полученном списке от последней сделки в списке к первой
      for(int i=total-1; i>=0; i--)
        {
         deal_symbol=HistoryDealGetString(HistoryDealGetTicket(i),DEAL_SYMBOL);
         //--- Если символ сделки и текущий символ равны, остановим цикл
         if(deal_symbol==_Symbol)
           {
            deal_type=HistoryDealGetInteger(HistoryDealGetTicket(i),DEAL_TYPE);
            deal_volume=HistoryDealGetDouble(HistoryDealGetTicket(i),DEAL_VOLUME);
            deal_price=HistoryDealGetDouble(HistoryDealGetTicket(i),DEAL_PRICE);              
            first_time = TimeCurrent();
            return true; 
            
           }
        }
     }
     return false;
  }

bool SavePositionToFile(string file_url)  //сохраняет позицию в файл 
{
 long tmp_time = TimeCurrent();  //сохраняем текущее время
 int file_handle = FileOpen(file_url, FILE_WRITE|FILE_COMMON|FILE_ANSI, "");
 if(file_handle == INVALID_HANDLE)
 {
  Alert("Не удалось открыть файл для записи сделки");
  return false;
 }

   FileWrite(file_handle,tmp_time); //сохраняем текущее время
   FileWrite(file_handle, deal_type ); //сохраняем тип сделки    
   FileWrite(file_handle, deal_volume ); //сохраняем объем сделки
   FileWrite(file_handle, deal_price ); //сохраняем цену сделки   
     
   FileClose(file_handle); //закрываем файл
   return true;
}

int OnInit()
  {
   first_time = TimeCurrent();


   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

   
  }

void OnTick()
  {

   
  }

void OnTrade()
  {
   if (CurrentPositionLastDealPrice() )      
   {
    if (FileDelete("mask.txt",FILE_COMMON))  //удаляем файл маску
    {
     Print ("Удалили файл-маску");
    }
    else
    {
     Print ("Не удалось удалить файл-маску");
    }
    
    if (SavePositionToFile("speaker.txt")) //сохраняем последнюю сделку в файл
    {
     Print ("Записали позицию в файл");
    }
    else
    {
     Print ("Не удалось сохранить позицию в файл");
    }
    
    int handle;
    if ((handle = FileOpen("mask.txt", FILE_WRITE|FILE_COMMON,"")) == INVALID_HANDLE) //создаем файл маску
    {
     Print ("Не удалось создать файл-маску обратно");
    }
    else
    {
     Print ("Удалось создать файл-маску обратно, закрываем файл");
     FileClose(handle);
    }
   }
  }
