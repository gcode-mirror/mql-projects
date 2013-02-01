//+------------------------------------------------------------------+
//|                                               CompareDoubles.mqh |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| EqualDoubles                                                   |
//+------------------------------------------------------------------+
bool EqualDoubles(double number1,double number2)
 {
  if(NormalizeDouble(number1-number2,8)==0) return(true);
  else return(false);
 }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| GreatDoubles                                                   |
//+------------------------------------------------------------------+
bool GreatDoubles(double number1,double number2)
 {
  if(NormalizeDouble(number1-number2,8)>0) return(true);
  else return(false);
 }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| LessDoubles                                                   |
//+------------------------------------------------------------------+
bool LessDoubles(double number1,double number2)
 {
  if(NormalizeDouble(number1-number2,8)<0) return(true);
  else return(false);
 }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| GreatOrEqualDoubles                                                   |
//+------------------------------------------------------------------+
bool GreatOrEqualDoubles(double number1,double number2)
 {
  if(NormalizeDouble(number1-number2,8)==0 || NormalizeDouble(number1-number2,8)>0) return(true);
  else return(false);
 }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| LessOrEqualDoubles                                                   |
//+------------------------------------------------------------------+
bool LessOrEqualDoubles(double number1,double number2)
 {
  if(NormalizeDouble(number1-number2,8)==0 || NormalizeDouble(number1-number2,8)>0) return(true);
  else return(false);
 }
//+------------------------------------------------------------------+