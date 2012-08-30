//+------------------------------------------------------------------+
//|                                         BreakthroughEntrance.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
int BreakthroughEntrance()
{
    if (maxPrice > 0) // Если максимум определен
    {
     // Продаем по Bid
     //Alert("максимум найден, ищем вход-пробой вниз" );
     if (Bid < iLow(NULL, Jr_Timeframe, 1) && Bid < iLow(NULL, Jr_Timeframe, 2))     
     {
      if (total < 1) // Нету открытых ордеров -> ищем возможность открытия
        { 
         Opening(OP_SELL);
         return (1);
        }
        else
        {
         OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
         if (OrderType()==OP_BUY) // Открыта короткая позиция SELL
         {
          OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet); // закрываем позицию SELL
          Alert("Закрыли ордер, обнуляем переменные" );
          Opening(OP_SELL);
          return(1);
         }
        }
     }
    }
     
    if (minPrice > 0)
    {
      // Покупаем по Ask
      //Alert("минимум найден, ищем вход-пробой вверх" );
     if (Ask > iHigh(NULL, Jr_Timeframe, 1) && Ask > iHigh(NULL, Jr_Timeframe, 2))
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
          Alert("Закрыли ордер, обнуляем переменные" );
          Opening(OP_BUY);
          return(1);
         }
        }
     }
    }
  return (0);
}