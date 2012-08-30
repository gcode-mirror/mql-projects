//+------------------------------------------------------------------+
//|                                       DesepticonBreakthrough.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
int DesepticonBreakthrough(int iDirection, string openPlace, int timeframe)
{
    total=OrdersTotal();
    if (iDirection < 0 && trendDirection[frameIndex] < 0)
    {
     // Продаем по Bid
     //Alert("максимум найден, ищем вход-пробой вниз" );
     if (Bid < iLow(NULL, timeframe, 1) && Bid < iLow(NULL, timeframe, 2))     
     {
      if (total < 1) // Нету открытых ордеров -> ищем возможность открытия
      { 
       if (DesepticonOpening(OP_SELL, openPlace, timeframe) > 0)
            return (1);
       else // ошибка открытия
            return(-1);
      }
      else
      {
       OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
       if (OrderMagicNumber() - _MagicNumber == Jr_Timeframe)  
       {
        if (OrderType()==OP_BUY)   // Открыта длинная позиция BUY
        {
         OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet); // закрываем позицию BUY
         Alert("Закрыли ордер, обнуляем переменные" );
         if (DesepticonOpening(OP_SELL, openPlace,  timeframe) > 0)
            return(1);
         else     // ошибка открытия
            return(-1);
        }
       }
      }
     }
    }
     
    if (iDirection > 0 && trendDirection[frameIndex] > 0)
    {
      // Покупаем по Ask
      //Alert("минимум найден, ищем вход-пробой вверх" );
     if (Ask > iHigh(NULL, timeframe, 1) && Ask > iHigh(NULL, timeframe, 2))
     {
      if (total < 1) // Нету открытых ордеров -> ищем возможность открытия
      { 
       if(DesepticonOpening(OP_BUY, openPlace, timeframe) > 0)
            return (1);
       else // ошибка открытия
            return(-1);
      }
      else
      {
       OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
       if (OrderMagicNumber() - _MagicNumber == Jr_Timeframe)  
       {
        if (OrderType()==OP_SELL) // Открыта короткая позиция SELL
        {
         OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet); // закрываем позицию SELL
         Alert("Закрыли ордер, обнуляем переменные" );
         if (DesepticonOpening(OP_BUY, openPlace, timeframe) > 0)
            return(1);
         else // ошибка открытия
            return(-1);
        }
       }
      }
     }
    }
  return (0);
}