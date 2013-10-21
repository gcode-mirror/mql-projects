//+------------------------------------------------------------------+
//|                                                     PosConst.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#define INFOPANEL_SIZE  19
//+------------------------------------------------------------------+
//| ћассив строковых наименований свойств позиций                    |
//+------------------------------------------------------------------+  
string pos_prop_names[INFOPANEL_SIZE]=
  {
   "name_pos_total_deals",
   "name_pos_symbol",
   "name_pos_magic",
   "name_pos_comment",
   "name_pos_swap",
   "name_pos_commission",
   "name_pos_price_first_deal",
   "name_pos_price",
   "name_pos_cprice",
   "name_pos_price_last_deal",
   "name_pos_profit",
   "name_pos_volume",
   "name_pos_initial_volume",
   "name_pos_sl",
   "name_pos_tp",
   "name_pos_time",
   "name_pos_duration",
   "name_pos_id",
   "name_pos_type"
  };
//+------------------------------------------------------------------+
//| ћассив строковых  значений позиций                               |
//+------------------------------------------------------------------+  
string pos_prop_values[INFOPANEL_SIZE]=
  {
   "value_pos_total_deals",
   "value_pos_symbol",
   "value_pos_magic",
   "value_pos_comment",
   "value_pos_swap",
   "value_pos_commission",
   "value_pos_price_first_deal",
   "value_pos_price",
   "value_pos_cprice",
   "value_pos_price_last_deal",
   "value_pos_profit",
   "value_pos_volume",
   "value_pos_initial_volume",
   "value_pos_sl",
   "value_pos_tp",
   "value_pos_time",
   "value_pos_duration",
   "value_pos_id",
   "value_pos_type"
  };
//+------------------------------------------------------------------+
//| ћассив названий свойств позиций                                  |
//+------------------------------------------------------------------+  
string pos_prop_texts[INFOPANEL_SIZE]=
  {
   "Total deals :",
   "Symbol :",
   "Magic Number :",
   "Comment :",
   "Swap :",
   "Commission :",
   "First Deal Price:",
   "Open Price :",
   "Current Price :",
   "Last Deal Price:",
   "Profit :",
   "Volume :",
   "Initial Volume :",
   "Stop Loss :",
   "Take Profit :",
   "Time :",
   "Duration :",
   "Identifier :",
   "Type :"
  }; 
