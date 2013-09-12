//+------------------------------------------------------------------+
//|                                                 ForTerminals.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <TradeManager/TradeManager.mqh> //библиотека совершени€ сделок

long   deal_type=0;  //тип сделки
double deal_volue=0; //объем сделки
double deal_price=0; //цена сделки
   
long date_last_pos;  //дата последней позиции
long first_time;     //сама€ перва€ дата при загрузке эксперта
CTradeManager new_trade; //класс торговли

void CurrentPositionLastDealPrice() //возвращает параметры последней сделки
  {
   int    total       =0;   // ¬сего сделок в списке выбранной истории
   string deal_symbol ="";  // —имвол сделки 
//--- ≈сли истори€ позиции получена
   if(HistorySelect(first_time,TimeCurrent()))
     {
      //--- ѕолучим количество сделок в полученном списке
      total=HistoryDealsTotal();
     
      //--- ѕройдем по всем сделкам в полученном списке от последней сделки в списке к первой

      for(int i=total-1; i>=0; i--)
        {
         //--- ѕолучим цену сделки
         deal_type=HistoryDealGetInteger(HistoryDealGetTicket(i),DEAL_TYPE);
         deal_volue=HistoryDealGetDouble(HistoryDealGetTicket(i),DEAL_VOLUME);
         deal_price=HistoryDealGetDouble(HistoryDealGetTicket(i),DEAL_PRICE);     
                           
         //--- ѕолучим символ сделки
         deal_symbol=HistoryDealGetString(HistoryDealGetTicket(i),DEAL_SYMBOL);
         //--- ≈сли символ сделки и текущий символ равны, остановим цикл
         if(deal_symbol==_Symbol)
            break;
        }
        
        
     }

  }

void SavePositionToFile(string file_url)  //сохран€ет позицию в файл 
{
 long tmp_time = TimeCurrent();  //сохран€ем текущее врем€
 int total;
 int file_handle = FileOpen(file_url, FILE_WRITE|FILE_COMMON, ";");
 if(file_handle == INVALID_HANDLE)
 {
  return;
 }
   FileWrite(file_handle,tmp_time); //сохран€ем текущее врем€

   CurrentPositionLastDealPrice(); //сохран€ет параметры последней сделки
   
   FileWrite(file_handle, deal_type ); //сохран€ем тип сделки    
   FileWrite(file_handle, deal_volue ); //сохран€ем объем сделки
   FileWrite(file_handle, deal_price ); //сохран€ем цену сделки   
     
      
     date_last_pos = tmp_time;  //сохран€ем врем€ сделки
      
 FileClose(file_handle); //закрываем файл
}

bool ReadPositionFromFile (string file_url) //открывает файл дл€ открыти€ позиции
 {
 int file_handle = FileOpen(file_url, FILE_READ|FILE_COMMON, ";");
 long tmp_time;
 if(file_handle == INVALID_HANDLE)
 {
  return false;
 }

 //сохран€ем позицию 
 
 tmp_time = FileReadLong(file_handle); //загружаем врем€ из файла 
 
 if (tmp_time > date_last_pos) //если врем€ в файле больше, чем последнее сохраненное врем€
  {
   deal_type  =  FileReadLong(file_handle); //загружаем тип сделки
   deal_volue =  FileReadDouble(file_handle); //загружаем объем сделки
   deal_price =  FileReadDouble(file_handle); //загружаем цену сделки
   return true;
  } 
 FileClose(file_handle);
 return  false;
 }

int OnInit()
  {
   //загружаем текущее врем€ сервера
   date_last_pos = TimeCurrent();
   first_time    = date_last_pos;
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

  }

void OnTick()
  {
    //провер€ем каждый раз, есть ли 
    if (ReadPositionFromFile("my_file.txt") ) //если была нова€ сделка
      {
       if (deal_type == DEAL_TYPE_BUY)
       new_trade.OpenPosition(_Symbol,OP_BUY,deal_volue,0,0,0,0,0);
       if (deal_type == DEAL_TYPE_SELL)
       new_trade.OpenPosition(_Symbol,OP_SELL,deal_volue,0,0,0,0,0);       
      } 
  }

void OnTrade()  
  {
      //сохран€ем в файл
      SavePositionToFile("my_file.txt");     
  }
