//+------------------------------------------------------------------+
//|                                        EntranceExtremumPrice.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
int EntranceExtremumPrice()
{
     if (maxPrice > 0) // Если максимум определен Продаем по Bid
      {
       if (maxPrice <= (Bid + deltaPrice*Point)) // Текущая цена превысила максимум
       {
        if (total < 1) // Нету открытых ордеров -> ищем возможность открытия
        { 
         Opening(OP_SELL);
         return (1);
        }
        else
        {
         OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
         if (OrderType()==OP_BUY) // Открыта длинная позиция BUY
         {
          OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet); // закрываем позицию BUY
          Opening(OP_SELL);
          return (1);
         }
        }
       }
      }
     
    if (minPrice > 0) // Покупаем по Ask
      {
       if (minPrice >= (Ask - deltaPrice*Point)) // Текущая цена пробила минимум
       {
        if (total < 1) // Нету открытых ордеров -> ищем возможность открытия
        { 
         Opening(OP_BUY);
         return (1);
        }
        else
        {
         OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
         if (OrderType()==OP_SELL) // Открыта короткая позиция SELL
         {
          OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet); // закрываем позицию SELL
          Opening(OP_BUY);
          return (1);
         }
        }
       }
      }
  return (0);
}