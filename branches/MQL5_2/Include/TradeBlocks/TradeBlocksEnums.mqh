//+------------------------------------------------------------------+
//|                                             TradeBlocksEnums.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| перечисление для выбора торгового блока                          |
//+------------------------------------------------------------------+
 
  enum  TRADE_BLOCKS_TYPE  //тип торгового блока
   {
    TB_CROSSEMA = 0,  //CrossEMA
    TB_RABBIT,        //Follow White Rabbit
    TB_CONDOM         //Гандон
   };
   