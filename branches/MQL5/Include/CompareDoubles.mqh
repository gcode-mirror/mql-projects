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
bool EqualDoubles(double number1,double number2, int precision = 8)
 {
  return(NormalizeDouble(number1-number2, precision) == 0);
 }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| GreatDoubles                                                   |
//+------------------------------------------------------------------+
bool GreatDoubles(double number1,double number2, int precision = 8)
 {
  return(NormalizeDouble(number1-number2,precision)>0);
 }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| LessDoubles                                                   |
//+------------------------------------------------------------------+
bool LessDoubles(double number1,double number2, int precision = 8)
 {
  return(NormalizeDouble(number1-number2,precision) < 0);
 }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| GreatOrEqualDoubles                                                   |
//+------------------------------------------------------------------+
bool GreatOrEqualDoubles(double number1,double number2, int precision = 8)
 {
  return(NormalizeDouble(number1-number2,precision)>=0);
 }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| LessOrEqualDoubles                                                   |
//+------------------------------------------------------------------+
bool LessOrEqualDoubles(double number1,double number2, int precision = 8)
 {
  return(NormalizeDouble(number1-number2,precision)<=0);
 }
//+------------------------------------------------------------------+