//+------------------------------------------------------------------+
//|                                                       Condom.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <CompareDoubles.mqh>
#include <TradeManager/TradeManagerEnums.mqh> 
//#include <TradeManager/TradeManager.mqh> 
#include <Lib CisNewBar.mqh>
#include <ColoredTrend\ColoredTrendUtilities.mqh> //загружаем бибилиотеку цветов


//+------------------------------------------------------------------+
//| Торговый класс Condom                                            |
//+------------------------------------------------------------------+

 class Condom //торговый класс Condom
  {
    private:
     //системные параметры
     bool _waitForSell;                       //флаг ожидания продажи
     bool _waitForBuy;                        //флаг ожидаения торговли
     bool _tradeOnTrend;                      //флаг торговли на тренде
     double _globalMax;                       //максимум
     double _globalMin;                       //минимум
     int _historyDepth;                       //глубина истории
     string _sym;                             //переменная для хранения символа
     ENUM_TIMEFRAMES _timeFrame;              //таймфрейм
     MqlTick _tick;                           //тик
     //параметры Price Based Indicator 
     int _handle_PBI;                         //хэндл Price Based Indicator
     double PBI_buf[1],                       //буфер Price Based Indicator
            high_buf[],                       //буфер высоких цен
            low_buf[],                        //буфер низких цен
            close_buf[2];                     //буфер цен закрытия      
     double _takeProfit;     
    public:
     double GetTakeProfit() { return (_takeProfit); }; //получает значение тейк профита
     int InitTradeBlock(string sym,
                        ENUM_TIMEFRAMES timeFrame,
                        bool   tradeOnTrend,                        
                        int historyDepth);       //метод инициализации торгового блока
     int DeinitTradeBlock();                             //метод деинициализации торгового блока
     bool UploadBuffers();                               //загружает буферы 
     short GetSignal (bool ontick);      //получает торговый сигнал     
       
  };
  
    int Condom::InitTradeBlock             (string sym,   //конструктор класса
                        ENUM_TIMEFRAMES timeFrame,
                        bool   tradeOnTrend,                  
                        int historyDepth)
   {
    _sym          = sym;
    _timeFrame    = timeFrame;
    
    _tradeOnTrend = tradeOnTrend;   
    _historyDepth = historyDepth; 

    if (_tradeOnTrend)
    {
     _handle_PBI = iCustom(_sym,_timeFrame,"PriceBasedIndicator",4,_historyDepth,false);  //подключаем индикатор и получаем его хендл
     if(_handle_PBI == INVALID_HANDLE)                                  //проверяем наличие хендла индикатора
      {
       Print("Не удалось получить хендл Price Based Indicator");               //если хендл не получен, то выводим сообщение в лог об ошибке                                                //завершаем работу с ошибкой
      }      
     } 

   ArraySetAsSeries(low_buf, false);
   ArraySetAsSeries(high_buf, false);

   _globalMax = 0;
   _globalMin = 0;
   _waitForSell = false;
   _waitForBuy = false;
   return(INIT_SUCCEEDED);
    }
    
  int  Condom::DeinitTradeBlock(void)  //деинициализация торгового блока Condom
    {
     //высвобождаем массивы
     ArrayFree(low_buf);
     ArrayFree(high_buf);
     return 1;
    } 
    
  bool Condom::UploadBuffers(void)     //загружает буферы 
   {
   int errLow = 0;                                                   
   int errHigh = 0;                                                   
   int errClose = 0;
   int errPBI = 0;
   if (_tradeOnTrend)
    {
     //копируем данные из индикаторного массива в динамический массив MACD_buf для дальнейшей работы с ними
     errPBI = CopyBuffer(_handle_PBI, 4, 1, 1, PBI_buf);
     if(errPBI < 0)
     {
      Alert("Не удалось скопировать данные из индикаторного буфера"); 
      return false; 
     }
    } 
    //копируем данные ценового графика в динамические массивы для дальнейшей работы с ними
    errLow=CopyLow(_sym, _timeFrame, 2, _historyDepth, low_buf); // (0 - тек. бар, 1 - посл. сформ. 2 - начинаем копир.)
    errHigh=CopyHigh(_sym, _timeFrame, 2, _historyDepth, high_buf); // (0 - тек. бар, 1 - посл. сформ. 2 - начинаем копир.)
    errClose=CopyClose(_sym, _timeFrame, 1, 2, close_buf); // (0 - тек. бар, копируем 2 сформ. бара)
             
    if(errLow < 0 || errHigh < 0 || errClose < 0)                         //если есть ошибки
    {
     Alert("Не удалось скопировать данные из буфера ценового графика");  //то выводим сообщение в лог об ошибке
     return false;                                                                  //и выходим из функции
    }  
    return true;
   }
    
  short Condom::GetSignal(bool ontick)  //получает торговый сигнал
   {
   CisNewBar isNewBar(_sym, _timeFrame);
    ENUM_TM_POSITION_TYPE order_type = OP_UNKNOWN;
     if(isNewBar.isNewBar() > 0)
       {       
       if (!UploadBuffers()) //если буферы не удалось скопировать
        return 0; //неизвестный сигнал
       
        _globalMax = high_buf[ArrayMaximum(high_buf)];
        _globalMin = low_buf[ArrayMinimum(low_buf)];
    
        if(LessDoubles(close_buf[1], _globalMin)) // Последний Close(0 - старше, 1 - моложе, т.е НЕ как в таймсерии) ниже глобального минимума
         {
          _waitForSell = false;
          _waitForBuy = true;
         }
        if(GreatDoubles(close_buf[1], _globalMax)) // Последний Close(0 - старше, 1 - моложе, т.е НЕ как в таймсерии) выше глобального максимума
         {
          _waitForBuy = false;
          _waitForSell = true;
         } 
      }
        if(_tradeOnTrend)
          {
            if (PBI_buf[0]==MOVE_TYPE_TREND_DOWN || 
                PBI_buf[0]==MOVE_TYPE_TREND_UP)
             {
              return 0; //неизвестный сигнал
             }
          } 
         if(!SymbolInfoTick(_sym,_tick))
   {
    Alert("SymbolInfoTick() failed, error = ",GetLastError());
    return 0; //неизвестный сигнал
   }
      
   if (_waitForBuy)
   { 
    if (GreatDoubles(_tick.ask, close_buf[0]) && GreatDoubles(_tick.ask, close_buf[1]))
    {
      _waitForBuy  = false;
      _waitForSell = false;
       order_type  = 1;  //BUY
    }
   } 

   if (_waitForSell)
   { 
    if (LessDoubles(_tick.bid, close_buf[0]) && LessDoubles(_tick.bid, close_buf[1]))
    {
      _waitForBuy  = false;
      _waitForSell = false;   
       order_type  = 2;   //SELL
    }
   }  
      
      return order_type;
   }