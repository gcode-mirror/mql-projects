//+------------------------------------------------------------------+
//|                                         DesepticonDivergence.mq4 |
//|                      Copyright © 2011, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
int DesepticonDivergence()
  {
   if( isNewBar() ) 
   { 
    InitDivergenceArray(Jr_Timeframe, frameIndex);
    InitExtremums(frameIndex);
    
    if (waitForMACDMaximum[frameIndex] || waitForMACDMinimum[frameIndex]) // Уже ждем экстремум на MACD
     {
      //Alert ("Ищем расхождение");
      wantToOpen[frameIndex] = isDivergence();
      return (wantToOpen[frameIndex]);
     }
   } // Обновляем массив экстремумов MACD
   
   //total=OrdersTotal();
   //if (total < 1)
   //{ // Нету открытых ордеров -> ищем возможность открытия
    if (wantToOpen[frameIndex] == 0) // Еще не знаем где открываться
    {
     if (!waitForMACDMaximum[frameIndex])
     {
      if (Ask > maxPriceForDiv[frameIndex]) // случился новый экстремум цены
      {
       waitForMACDMaximum[frameIndex] = true;
      }
     } 
     if (!waitForMACDMinimum[frameIndex])
     {
      if (Bid < minPriceForDiv[frameIndex]) // случился новый экстремум цены
      {
       waitForMACDMinimum[frameIndex] = true;
      }
     }  
    } //close Еще не знаем где открываться
    return (wantToOpen[frameIndex]);
   //} 
  }