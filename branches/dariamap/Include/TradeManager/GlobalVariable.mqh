//+------------------------------------------------------------------+
//|                                               GlobalVariable.mqh |
//|                                     Copyright Paul Hampton-Smith |
//|                            http://paulsfxrandomwalk.blogspot.com |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
/// Simple wrapper for MT5 Global Variable functions.
//+------------------------------------------------------------------+
class CGlobalVariable
  {
private:
   string            m_strName;

public:
   long Decrement(){return(LongValue(LongValue()-1));}
   bool Delete(){ return(GlobalVariableDel(m_strName));}
   double DoubleValue() {return(GlobalVariableGet(m_strName));}
   double DoubleValue(double dbl) { GlobalVariableSet(m_strName,dbl); return(dbl);}
   int IntValue() {return((int)MathRound(GlobalVariableGet(m_strName)));}
   int IntValue(int i) {GlobalVariableSet(m_strName,(double)i); return(i);}
   long LongValue() {return((long)MathRound(GlobalVariableGet(m_strName)));}
   long LongValue(long l) {GlobalVariableSet(m_strName,(double)l); return(l);}
   ulong ULongValue() {return((ulong)MathRound(GlobalVariableGet(m_strName)));}
   ulong ULongValue(ulong ul) {GlobalVariableSet(m_strName,(double)ul); return(ul);}
   long Increment(){return(LongValue(LongValue()+1));}
   string Name(){ return(m_strName);}
   string Name(string strName){return(m_strName=strName);}
  };
//+------------------------------------------------------------------+
