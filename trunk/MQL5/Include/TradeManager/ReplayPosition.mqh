//+------------------------------------------------------------------+
//|                                               ReplayPosition.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include "TradeManagerEnums.mqh"
#include "PositionOnPendingOrders.mqh"
#include "PositionArray.mqh"
#include "TradeManager.mqh"
//+------------------------------------------------------------------+
//| Класс-контейнер для хранения и работы с позициями                |
//+------------------------------------------------------------------+

 class ReplayPosition
  { 
   private:
    CTradeManager ctm;  //торговый класс 
 //   CPositionArray _positionsToReplay; //массив позиций
    ReplayPos _posToReplay[];   //динамический массив для обработки позиций на отыгрыш
   public: 
    void AddToArray (ReplayPos * new_pos); //метод добавляет новую позицию
    void DeletePosition(uint index);      //удаляем позицию по индексу    
    void CustomPosition (int stopLoss,double lot);   //пробагает по массиву и изменяет статусы позиций возвращает индекс позиции    
  };
//+------------------------------------------------------------------+
//| Добавляет позицию в массив на отыгрыш                            |
//+------------------------------------------------------------------+  

void ReplayPosition::AddToArray(ReplayPos *new_pos)
 {
   ArrayResize(_posToReplay,ArraySize(_posToReplay)+1); //изменяем размер массива на единицу
   _posToReplay[ArraySize(_posToReplay)-1].price_close = new_pos.price_close;
   _posToReplay[ArraySize(_posToReplay)-1].price_open  = new_pos.price_open;
   _posToReplay[ArraySize(_posToReplay)-1].status      = new_pos.status;
   _posToReplay[ArraySize(_posToReplay)-1].type        = new_pos.type;   
   _posToReplay[ArraySize(_posToReplay)-1].symbol      = new_pos.symbol; 
   _posToReplay[ArraySize(_posToReplay)-1].profit      = new_pos.profit;

 }
//+------------------------------------------------------------------+
//| Удаляет позицию по индексу                                       |
//+------------------------------------------------------------------+  
 
 void ReplayPosition::DeletePosition(uint index)
  { 
   uint i;
   uint total = ArraySize(_posToReplay); //начальная длина массива
   //смещает  на единицу элементы после удаляемого
   for(i=index+1;i<total;i++)
    {
   _posToReplay[i-1].price_close = _posToReplay[i].price_close ;
   _posToReplay[i-1].price_open  = _posToReplay[i].price_open;
   _posToReplay[i-1].status      = _posToReplay[i].status;
   _posToReplay[i-1].type        = _posToReplay[i].type;   
   _posToReplay[i-1].status      = _posToReplay[i].status;   
   _posToReplay[i-1].profit      = _posToReplay[i].profit;         
    }
   //уменьшаем массив на единицу
   ArrayResize(_posToReplay,total-1);
  }
   
//+------------------------------------------------------------------+
//| пробегает по массиву позиций и проверяет\меняет статусы          |
//+------------------------------------------------------------------+
  void ReplayPosition::CustomPosition(int stopLoss,double lot)
   {

   uint index;
   uint total = ArraySize(_posToReplay);       //текущая длина массива
   double tp; //тейкпрофит
   double sl; //стоп лосс
   double price;
   CPosition *pos;                           //указатель на позицию 

   for (index=0;index<total;index++)         //пробегаем по массиву позиций
    {

    if (_posToReplay[index].status == POSITION_STATUS_MUST_BE_REPLAYED)  //если позиция ожидает перевала за рубеж в Loss
     {
      //если цена перевалила за Loss
      if ((SymbolInfoDouble(_posToReplay[index].symbol,SYMBOL_ASK) - _posToReplay[index].price_close ) <= _posToReplay[index].profit)
       {
         _posToReplay[index].status =  POSITION_STATUS_READY_TO_REPLAY;  //переводим позицию в режим готовности к отыгрушу
       } 
     }
    else if (_posToReplay[index].status == POSITION_STATUS_READY_TO_REPLAY) //если позиция готова к отыгрышу
     {
      if (SymbolInfoDouble(_posToReplay[index].symbol,SYMBOL_BID) >= _posToReplay[index].price_close ) //если цена перевалила за зону цены закрытия позиции
       {
        //  Alert("TYPE = ",GetNameOP(_posToReplay[index].type));
          switch (_posToReplay[index].type) //выбираем тип цены для открытия позиции
           {
             case OP_BUY:
             
             price = SymbolInfoDouble(_posToReplay[index].symbol,SYMBOL_ASK);
             Comment("тип = BUY цена = ",price, 
                     "; цена открытия = ",_posToReplay[index].price_open, 
                     " цена закрытия = ", _posToReplay[index].price_close,
                     " профит позиции = ",_posToReplay[index].profit,
                     " дата и время = ", TimeToString(TimeCurrent())
                     
                     );
             break;
             case OP_SELL:
             price = SymbolInfoDouble(_posToReplay[index].symbol,SYMBOL_BID);
             Comment("тип = SELL цена = ",price, 
                     "; цена открытия = ",_posToReplay[index].price_open, 
                     " цена закрытия = ", _posToReplay[index].price_close,
                     " профит позиции = ",_posToReplay[index].profit,
                     " дата и время = ", TimeToString(TimeCurrent())                     
                     );
             break;
           }
           
    
         tp = NormalizeDouble( MathMax( SymbolInfoInteger( _posToReplay[index].symbol, SYMBOL_TRADE_STOPS_LEVEL )*_Point,
               MathAbs( price-_posToReplay[index].price_open ) / _Point ), SymbolInfoInteger( _posToReplay[index].symbol, SYMBOL_DIGITS));
                     
         ctm.OpenMultiPosition(_posToReplay[index].symbol,_posToReplay[index].type,lot,stopLoss,tp,0,0,0); //открываем позицию
         
        Alert("HELL");
         
         DeletePosition(index); //и удаляем её из массива  
         total = ArraySize(_posToReplay);
       }      
     }
    }    
   }