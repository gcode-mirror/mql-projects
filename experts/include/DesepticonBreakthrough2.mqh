//+------------------------------------------------------------------+
//|                                      DesepticonBreakthrough2.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
int DesepticonBreakthrough2(int iDirection, int timeframe)
{
 int i;
 total=OrdersTotal();
 
 if (iDirection < 0)
 {
  // Продаем по Bid
  if (!ExistPositions("", -1, _MagicNumber)) // Нету открытых ордеров -> ищем возможность открытия
  {
   //if (Ask > iMA(NULL, Elder_Timeframe, eld_EMA2, 0, 1, 0, 0))
   if (OpenPosition(NULL, OP_SELL, openPlace, timeframe, 0, 0, _MagicNumber) > 0)
   {
    return (1);
   }  
   else // ошибка открытия
    return(-1);
  }
  else
  {
   for (i=0; i<total; i++)
   {
    if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
    {
     if (OrderMagicNumber() == _MagicNumber)  
     {
      if (OrderType()==OP_BUY)   // Открыта длинная позиция BUY
      {
       ClosePosBySelect(Bid); // закрываем позицию BUY
       Alert("DesepticonBreakthrough2: Закрыли ордер BUY" );
       if (OpenPosition(NULL, OP_SELL, openPlace, timeframe, 0, 0, _MagicNumber) > 0)
       {
        return (1);
       }  
       else // ошибка открытия
        return(-1);
      }
     }
    } 
   } 
  }
 }
      
 if (iDirection > 0)
 {
  // Покупаем по Ask
  if (!ExistPositions("", -1, _MagicNumber)) // Нету открытых ордеров -> ищем возможность открытия
  { 
   //if (Bid < iMA(NULL, Elder_Timeframe, eld_EMA2, 0, 1, 0, 0))
    if (OpenPosition(NULL, OP_BUY, openPlace, timeframe, 0, 0, _MagicNumber) > 0)
    {
     return (1);
    }
    else // ошибка открытия
     return(-1);
  }
  else
  {
   for (i=0; i<total; i++)
   {
    if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
    {
     if (OrderMagicNumber() == _MagicNumber)  
     {
      if (OrderType()==OP_SELL) // Открыта короткая позиция SELL
      {
       ClosePosBySelect(Ask); // закрываем позицию SELL
       Alert("DesepticonBreakthrough2: Закрыли ордер SELL" );
        if (OpenPosition(NULL, OP_BUY, openPlace, timeframe, 0, 0, _MagicNumber) > 0)
        {
         return (1);
        }
        else // ошибка открытия
         return(-1);
      }
     }
    }
   }  
  }
 }
 return (0);
}

////

/////


int DesepticonBreakthroughTest(int iDirection, int timeframe)
{
 int i;
 total=OrdersTotal();
 
 if (iDirection < 0)
 {
  // Продаем по Bid
  if (!ExistPositions("", -1, _MagicNumber)) // Нету открытых ордеров -> ищем возможность открытия
  {
   //if (Ask > iMA(NULL, Elder_Timeframe, eld_EMA2, 0, 1, 0, 0))
   if (OpenPositionTest(NULL, OP_SELL, openPlace, timeframe, 0, 0, _MagicNumber) > 0)
   {
    return (1);
   }  
   else // ошибка открытия
    return(-1);
  }
  else
  {
   for (i=0; i<total; i++)
   {
    if(OrderSelect(0,SELECT_BY_POS,MODE_TRADES))
    {
     if (OrderMagicNumber() == _MagicNumber)  
     {
      if (OrderType()==OP_BUY)   // Открыта длинная позиция BUY
      {
       OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet); // закрываем позицию BUY
       Alert("DesepticonBreakthrough2: Закрыли ордер BUY" );
       //if (Ask > iMA(NULL, Elder_Timeframe, eld_EMA2, 0, 1, 0, 0))
       if (OpenPositionTest(NULL, OP_SELL, openPlace, timeframe, 0, 0, _MagicNumber) > 0)
       {
        return (1);
       }  
       else // ошибка открытия
        return(-1);
      }
     }
    } 
   } 
  }
 }
      
 if (iDirection > 0)
 {
  // Покупаем по Ask
  if (!ExistPositions("", -1, _MagicNumber)) // Нету открытых ордеров -> ищем возможность открытия
  { 
   //if (Bid < iMA(NULL, Elder_Timeframe, eld_EMA2, 0, 1, 0, 0))
    if (OpenPosition(NULL, OP_BUY, openPlace, timeframe, 0, 0, _MagicNumber) > 0)
    {
     return (1);
    }
    else // ошибка открытия
     return(-1);
  }
  else
  {
   for (i=0; i<total; i++)
   {
    if(OrderSelect(0,SELECT_BY_POS,MODE_TRADES))
    {
     if (OrderMagicNumber() == _MagicNumber)  
     {
      if (OrderType()==OP_SELL) // Открыта короткая позиция SELL
      {
       OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet); // закрываем позицию SELL
       Alert("DesepticonBreakthrough2: Закрыли ордер SELL" );
       //if (Bid < iMA(NULL, Elder_Timeframe, eld_EMA2, 0, 1, 0, 0))
        if (OpenPosition(NULL, OP_BUY, openPlace, timeframe, 0, 0, _MagicNumber) > 0)
        {
         return (1);
        }
        else // ошибка открытия
         return(-1);
      }
     }
    }
   }  
  }
 }
 return (0);
}