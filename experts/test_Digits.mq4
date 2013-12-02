//+------------------------------------------------------------------+
//|                                                  test_Digits.mq4 |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

extern int test_extern = 200;
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----
   string symb = Symbol();
   int dg=MarketInfo(symb, MODE_DIGITS);
   double vol=MathPow(10.0,dg);
   double price=0.0003*vol;
   Alert(dg,"-значка ", "price=", price); 
   datetime expirationTime = TimeCurrent() + PERIOD_M15;
   Alert(" Now = ", TimeCurrent(), " expirationTime = ", expirationTime); 
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+