//+------------------------------------------------------------------+
//|                                                      CTihiro.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include "Extrem.mqh" 

//+------------------------------------------------------------------+
//| ����� ��� �������� TIHIRO                                        |
//+------------------------------------------------------------------+

class CTihiro 
 {
    //��������� ���� ������
   private:
    //������ 
    double   _price_high[];      // ������ ������� ���  
    double   _price_low[];       // ������ ������ ���  
    datetime _price_time[];      // ������ ������� 
    //������
    string  _symbol;
    //���������
    ENUM_TIMEFRAMES _timeFrame;
    //����� ��������� �����
    TIHIRO_MODE _mode;
    //���������� ����� �������
    uint    _bars;  
    //������� ����� ������
    double  _tg;
    //���������� �� ����� ������ �� ���������� ����������
    double  _range;
    //����, �� ������� ���� ������� �������
    double  _open_price;
    //��������� ����������
    Extrem  _extr_up_past,_extr_down_past;
    //��������� �����������
    Extrem  _extr_up_present,_extr_down_present;
    //����� ���������� �����������
    short   _flag_up,_flag_down;
    //��� ��������
    short   _trend_type;
    //��������� ������ ������
   private:
    //�������� �������� �������� ���� ������� ����� ������   
    void    GetTan();  
    //���������� ���������� �� ���������� �� ����� ������
    void    GetRange();
    //���� TD ����� ��� ����� �����
    void    GetTDPoints();
    //���������� ��������
    void    RecognizeSituation();
    //���������, ���� ��� ���� ����� ������ ��������� ������� �����
    short   TestPointLocate(datetime cur_time,double cur_price);
    //���������, ��� ���� ����� �� ����� ������
    short   TestCrossTrendLine();
    //���������, ��� ���� ����� �� ���� range
    short   TestReachRange();
   public:
   //����������� ������ 
   CTihiro(string symbol,ENUM_TIMEFRAMES timeFrame,uint bars):
     _symbol(symbol),
     _timeFrame(timeFrame),
     _mode(TM_WAIT_FOR_CROSS),
     _bars(bars)
    { 
     //������� ��� � ���������
     ArraySetAsSeries(_price_high,true);
     ArraySetAsSeries(_price_low, true);   
     ArraySetAsSeries(_price_time,true);        
    }; 
   //���������� ������
   ~CTihiro()
    {
     //������� ������� �� ������������ ������
     ArrayFree(_price_high);
     ArrayFree(_price_low);
     ArrayFree(_price_time);
    };
   // -----------------------------------------------------------------------------
   //�������� �� �������� ��������� �� ������� ������������ � ����������� ��� �����
   //� ��������� ��� ����������� �������� �� ���
   //� ������ - ����������, ������� ��������� �����, ���������� �� ����� ������ �� ���������� ���������� 
   void   OnNewBar();
   //�� ������ ���� ���������, ������� �� ���� �� ����� �����  
   //���������� �������� ������ 
   //0 - UNKNOWN, 1 - BUY, 2 - SELL
   short  OnTick();
 };

//+------------------------------------------------------------------+
//| �������� ��������� �������                                       |
//+------------------------------------------------------------------+

void CTihiro::GetTan() 
//�������� �������� �������� ���� ������� ����� ������
 {
  if (_trend_type == TREND_DOWN)
   {  
    _tg =  (_extr_down_present.price-_extr_down_past.price)/(_extr_down_present.time - _extr_down_past.time);
   }
  if (_trend_type == TREND_UP)
   {  
    _tg =  (_extr_up_present.price-_extr_up_past.price)/(_extr_up_present.time - _extr_up_past.time);
   }   
 }
 
void CTihiro::GetRange()
//��������� ���������� �� ���������� �� ����� ������
 {
  datetime L;
  double H;
  if (_trend_type == TREND_DOWN)
   {
    L=_extr_up_present.time-_extr_down_past.time;  
    H=_extr_up_present.price-_extr_down_past.price;
   }
  if (_trend_type == TREND_UP)
   {
    L=_extr_down_present.time-_extr_up_past.time;  
    H=_extr_down_present.price-_extr_up_past.price;
   }   
  _range=H-_tg*L;
 }
 
void CTihiro::GetTDPoints()
//���� TD ����� ��� ����� �����
 {
   short i; 
   _flag_down = 0;
   _flag_up   = 0;
   //�������� �� ����� � ��������� ����������
   for(i = 1; i < (_bars-1) && (_flag_down<2||_flag_up<2); i++)
    {
     //���� ������� high ���� ������ high ��� ����������� � ����������
     if (_price_high[i] > _price_high[i-1] && _price_high[i] > _price_high[i+1] && _flag_down < 2)
      {
       if (_flag_down == 0)
        {
         //��������� ������ ���������
         _extr_down_present.SetExtrem(_price_time[i],_price_high[i]);
         _flag_down = 1; 
        }
       else 
        {
         if(_price_high[i] > _extr_down_present.price)
          {
          //��������� ����� ���������
          _extr_down_past.SetExtrem(_price_time[i],_price_high[i]);               
          _flag_down = 2;
          }
        }            
      }  //���������� �����
//���� ������� low ���� ������ low ��� ����������� � ����������
     if (_price_low[i] < _price_low[i-1] && _price_low[i] < _price_low[i+1] && _flag_up < 2 )
      {
       if (_flag_up == 0)
        {
         //��������� ������ ���������
         _extr_up_present.SetExtrem(_price_time[i],_price_low[i]);
         _flag_up = 1; 
        }
       else 
        {
         if(_price_low[i] < _extr_up_present.price)
          {
          //��������� ����� ���������
          _extr_up_past.SetExtrem(_price_time[i],_price_low[i]);        
          _flag_up = 2;
          }
        }            
      }  //���������� �����               
     }
 } 
 
void  CTihiro::RecognizeSituation(void)
//���������� �������� 
 {
   _trend_type = NOTREND; //��� ������
   if (_flag_down == 2) //���� ���������� ����� ������
    {
     if (_flag_up > 0) //���� ���� ���� ��������� ������
      {
       if (_extr_up_present.time > _extr_down_present.time)  //���� ������ ��������� ������� ����� ������
        {
         _trend_type = TREND_DOWN; //�� ������, ��� ����� ����������
        } 
      }
    }
   if (_flag_up == 2) //���� ���������� ����� ������
    {
     if (_flag_down > 0) //���� ���� ���� ��������� ������
      {
       if (_extr_down_present.time > _extr_up_present.time)  //���� ������� ��������� ������� ����� ������
        {
         _trend_type = TREND_UP; //�� ������, ��� ����� ����������
        } 
      }
    }      
 }
 
short CTihiro::TestPointLocate(datetime cur_time,double cur_price)
//���������, ���� ��� ���� ����� ������ ��������� ������� �����
 {
   datetime time;
   double price;
   double line_level;
   if (_trend_type == TREND_DOWN)
    {
     line_level = _extr_down_past.price+(cur_time-_extr_down_past.time)*_tg;  //��������  ����� ������ � ������ ����� 
    }
   if (_trend_type == TREND_UP)
    {
     line_level = _extr_up_past.price+(cur_time-_extr_up_past.time)*_tg;  //��������  ����� ������ � ������ ����� 
    }    
   if (cur_price>line_level)
    return 1;  //����� ��������� ���� ����� ������
   if (cur_price<line_level)
    return -1; //����� ��������� ���� ����� ������
   return 0;   //����� ��������� �� ����� ������
 }
 
short CTihiro::TestCrossTrendLine()
//���������, ��� ���� ����� �� ����� ������ 
 {
 datetime time;   //������� �����
 double   price;  //������� ����
  //���� ����� ���������� 
 if (_trend_type == TREND_UP) 
   {
    //��������� ������� �����
    time = TimeCurrent();
    //��������� ���� BID, ��� ������
    price = SymbolInfoDouble(_symbol,SYMBOL_BID);
    //���� ���� ���������� �� ����� ������
    if (TestPointLocate(time,price)<=0)
     {
      //��������� � ����� �������� ���������� ������ range
      _mode = TM_REACH_THE_RANGE;
      return SELL;
     }
   }
  //���� ����� ����������
  if (_trend_type == TREND_DOWN) 
   {
    //��������� ������� �����
    time = TimeCurrent();   
    //��������� ���� ASK, ��� �������
    price = SymbolInfoDouble(_symbol,SYMBOL_ASK);
    //���� ���� ���������� �� ����� ������
    if (TestPointLocate(time,price)>=0)
     {
      //��������� � ����� �������� ���������� ������ range
      _mode = TM_REACH_THE_RANGE;     
      return BUY;
     }    
   }  
  return UNKNOWN;  
 }
  
short CTihiro::TestReachRange()
//���������, ��� ���� ����� �� ���� range
 {
  double cur_price;
  double abs;
  //���� ����� ����������
  if (_trend_type == TREND_UP)
   {
     cur_price = SymbolInfoDouble(_symbol,SYMBOL_BID);
     abs=_open_price-cur_price;
     if (abs>_range) 
      {
       //��������� � ����� �������� ����������� � ������ ������
       _mode = TM_WAIT_FOR_CROSS;      
       return BUY;
      }
   }
  //���� ����� ����������
  if (_trend_type == TREND_DOWN)
   {
     cur_price = SymbolInfoDouble(_symbol,SYMBOL_ASK);   
     abs=cur_price-_open_price;
     if (abs>_range) 
      {
       //��������� � ����� �������� ����������� � ������ ������
       _mode = TM_WAIT_FOR_CROSS;            
       return SELL;
      }
   }  
  return UNKNOWN;
 }
 
//+------------------------------------------------------------------+
//| �������� ��������� �������                                       |
//+------------------------------------------------------------------+ 

void CTihiro::OnNewBar()
//��������� ��� ����������� �������� �� �������� ������������ � ����������� ��� �����
 {
   //��������� ������ 
   if(CopyHigh(_symbol, _timeFrame, 1, _bars, _price_high) <= 0 ||
      CopyLow (_symbol, _timeFrame, 1, _bars, _price_low)  <= 0 ||
      CopyTime(_symbol, _timeFrame, 1, _bars, _price_time) <= 0  ) 
       {
        Print("�� ������� ��������� ���� �� �������");
        return;
       }
  //���� ����� �������� ����������� ���� � ������ ������
  if (_mode==TM_WAIT_FOR_CROSS)
  {
   // ��������� ���������� (TD-����� ����� ������)
   GetTDPoints();
   // ��������� ��� ������ (��������)
   RecognizeSituation();
   // ��������� ������� ����� �����
   GetTan();
   // ��������� ���������� �� ���������� �� ����� ������
   GetRange();
  }
 }
 
short CTihiro::OnTick()
//�� ������ ���� ���������, ������� �� ���� �� ����� �����  
{
  //����� ��������� �����
 switch (_mode)
 {
 //�������� ����������� ����� ������
 case TM_WAIT_FOR_CROSS:   
  return TestCrossTrendLine(); 
 break;
 //����� �������� ���������� ������ range
 case TM_REACH_THE_RANGE:
  return TestReachRange();
 break; 
 } //switch
 return UNKNOWN;
}