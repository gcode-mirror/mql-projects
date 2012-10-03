//+------------------------------------------------------------------+
//|                                             CheckBeforeStart.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
bool CheckBeforeStart()                           // Пользовательская функция
{
   if(Bars<200) // количество баров на графике
    {
     Print("bars less than 200");
     return(false);  
    }
   if(TakeProfit<10)
    {
     Print("Ошибка! TakeProfit меньше 10");
     return(false);  
    }
 /*  
   if(StopLoss<10)
    {
     Print("Ошибка! StopLoss меньше 10");
     return(false);  
    }
 */  
   if(AccountFreeMargin()<(1000*lotmin))
    {
     Print("We have no money. Free Margin = ", AccountFreeMargin(), "Lots = ", 1000*lotmin);
     return(false);  
    }
   
     
   if (TrailingStop_1D_min > TrailingStop_1D_max || TrailingStop_1H_min > TrailingStop_1H_max || TrailingStop_5M_min > TrailingStop_5M_max)
    {
     Print("Максимальная граница трейлинг-стопа должна быть выше минимальной");
     return(false);
    }
    
   if (StopLoss_1D_min > StopLoss_1D_max || StopLoss_1H_min > StopLoss_1H_max || StopLoss_5M_min > StopLoss_5M_max)
    {
     Print("Максимальная граница стоп-лосса должна быть выше минимальной");
     return(false);
    }
     
   /*
   if (frameIndex < 0 || frameIndex > 2)
    {
     Print("Ошибка! Неверный таймфрейм");
     return(false);
    }
   */
   
   switch (Elder_Timeframe){
    case 1: break; //Print("Elder_Timeframe is 1 minute"); break;
    case 5: break; // Print("Elder_Timeframe is 5 minutes"); break;
    case 15: break; // Print("Elder_Timeframe is 15 minutes"); break;
    case 30: break; // Print("Elder_Timeframe is 30 minutes"); break;
    case 60: break; //Print("Elder_Timeframe is 1 hour"); break;
    case 240: break; //Print("Elder_Timeframe is 4 hours"); break;
    case 1440: break; //Print("Elder_Timeframe is 1 day"); break;
    case 10080: break; //Print("Elder_Timeframe is 1 week"); break;
    case 43200: break; //Print("Elder_Timeframe is 1 month"); break;
    case 0: break; //Print("Elder_Timeframe is current timeframe"); break;
    default: Print ("Incorrect Elder timeframe"); return(false);
   }
   
   switch (Jr_Timeframe){
    case 1: break; //Print("Junior Timeframe is 1 minute"); break;
    case 5: break;  //Print("Junior Timeframe is 5 minutes"); break;
    case 15: break; // Print("Junior Timeframe is 15 minutes"); break;
    case 30: break; //Print("Junior Timeframe is 30 minutes"); break;
    case 60: break; // Print("Junior Timeframe is 1 hour"); break;
    case 240: break; //Print("Junior Timeframe is 4 hours"); break;
    case 1440: break; //Print("Junior Timeframe is 1 day"); break;
    case 10080: break; //Print("Junior Timeframe is 1 week"); break;
    case 43200: break; //Print("Junior Timeframe is 1 month"); break;
    case 0: break; //Print("Junior Timeframe is current timeframe"); break;
    default: Print ("Incorrect Junior timeframe"); return(false);
   }
    
   return(true);
 }