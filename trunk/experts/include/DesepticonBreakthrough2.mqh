//+------------------------------------------------------------------+
//|                                      DesepticonBreakthrough2.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
int DesepticonBreakthrough2(int iDirection, int timeframe)
{
    if (iDirection < 0
    // && trendDirection[frameIndex][1] < 0
    )
    {
     // Продаем по Bid
     //Alert("ст. тренд вниз, мл. тренд вверх" );
     //if (Bid < iLow(NULL, timeframe, 1) && Bid < iLow(NULL, timeframe, 2))     
     //{
      if (total < 1) // Нету открытых ордеров -> ищем возможность открытия
      {
       //if (Ask > iMA(NULL, Elder_Timeframe, eld_EMA2, 0, 1, 0, 0))
        if (DesepticonOpening(OP_SELL, openPlace, timeframe) > 0)
        {
         return (1);
        }  
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
         Alert("DesepticonBreakthrough2: Закрыли ордер BUY" );
         //if (Ask > iMA(NULL, Elder_Timeframe, eld_EMA2, 0, 1, 0, 0))
          if (DesepticonOpening(OP_SELL, openPlace, timeframe) > 0)
          {
           return (1);
          }  
          else // ошибка открытия
           return(-1);
        }
       }
      }
     //}
    }
     
    if (iDirection > 0
     //&& trendDirection[frameIndex][1] > 0
     )
    {
     // Покупаем по Ask
     //Alert("ст. тренд вверх, мл. тренд вниз" );
     //if (Ask > iHigh(NULL, timeframe, 1) && Ask > iHigh(NULL, timeframe, 2))
     //{
      if (total < 1) // Нету открытых ордеров -> ищем возможность открытия
      { 
       //if (Bid < iMA(NULL, Elder_Timeframe, eld_EMA2, 0, 1, 0, 0))
        if (DesepticonOpening(OP_BUY, openPlace, timeframe) > 0)
        {
         return (1);
        }
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
         Alert("DesepticonBreakthrough2: Закрыли ордер SELL" );
         //if (Bid < iMA(NULL, Elder_Timeframe, eld_EMA2, 0, 1, 0, 0))
          if (DesepticonOpening(OP_BUY, openPlace, timeframe) > 0)
          {
           return (1);
          }
          else // ошибка открытия
           return(-1);
        }
       }
      }
     //}
    }
  return (0);
}