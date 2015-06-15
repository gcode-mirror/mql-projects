//+------------------------------------------------------------------+
//|                                                CTrendChannel.mqh |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| ����� ��������� ����� � �������                                  |
//+------------------------------------------------------------------+
// ����������� ����������� ���������
#include <ChartObjects/ChartObjectsLines.mqh> // ��� ��������� ����� ������
#include <DrawExtremums/CExtremum.mqh> // ����� �����������
#include <DrawExtremums/CExtrContainer.mqh> // ��������� �����������
#include <CompareDoubles.mqh> // ��� ��������� ������������ �����
#include <Arrays\ArrayObj.mqh> // ����� ������������ ��������
#include <StringUtilities.mqh> // ��������� �������
#include "CMove.mqh" // ����� ��������

class CMoveContainer: public CObject
 {
  private:
   int    _handleDE; // ����� ���������� DrawExtremums
   int    _chartID;  // ID �������
   int    _countMoves; // ������� ��������
   string _symbol;   // ������
   string _eventExtrUp;   // ��� ������� ������� �������� ����������
   string _eventExtrDown; // ��� ������� ������� ������� ����������
   double _percent; // ������� �������� ������
   ENUM_TIMEFRAMES _period; // ������
   int    _trendNow; // ���� ����, ��� � ������ ������ ���� ��� ��� ������
   bool   _isHistoryUploaded; // ���� ����, ��� ������� ���� ���������� �������
   CExtrContainer *_container; // ��������� �����������
   CArrayObj _bufferMove;// ����� ��� �������� ��������
   CMove *_prevTrend; // ��������� �� ���������� �����
   CMove *_curTrend; // ������� �����
   // ��������� ������ ������
   string GenEventName (string eventName) { return(eventName +"_"+ _symbol +"_"+ PeriodToString(_period) ); };
  public:
   // ��������� ������ ������
   CMoveContainer(int chartID,string symbol,ENUM_TIMEFRAMES period,int handleDE,double percent); // ����������� ������
   ~CMoveContainer(); // ���������� ������
   // ������ ������
   CMove *GetMoveByIndex (int index); // ���������� ��������� �� �������� �� �������
   CMove *GetTrendByIndex (int index); // ���������� ����� �� �������
   CMove *GetLastTrend(void); // ���������� �������� ���������� ������  
   bool IsTrendNow () { return (_trendNow); }; // ���������� true, ���� � ������� ������ - �����, false - ���� � ������� ������ - ��� �����
   int  GetTotal () { return (_bufferMove.Total() ); }; // ���������� ���������� �������� �� ������� ������ � ������
   void RemoveAll (); // ������� ����� ��������
   void UploadOnEvent (string sparam,double dparam,long lparam); // ����� ��������� ���������� �� �������� 
   bool UploadOnHistory (); // ����� ��������� ������ � ����� �� ������� 
 };

// ����������� ������� ������ CTrendChannel
CMoveContainer::CMoveContainer(int chartID, string symbol,ENUM_TIMEFRAMES period,int handleDE,double percent)
 {
  _chartID = chartID;
  _handleDE = handleDE;
  _symbol = symbol;
  _period = period;
  _percent = percent;
  _countMoves = 0;
  _container = new CExtrContainer(handleDE,symbol,period);
  // ��������� ���������� ����� �������
  _eventExtrDown = GenEventName("EXTR_DOWN_FORMED");
  _eventExtrUp = GenEventName("EXTR_UP_FORMED");
  _isHistoryUploaded = false;
 } 
  
// ���������� ������
CMoveContainer::~CMoveContainer()
 {
  _bufferMove.Clear();
  delete _container;
 }
 
// ���������� ��������� �� ����� �� �������
CMove * CMoveContainer::GetMoveByIndex(int index)
 {
  CMove *curTrend = _bufferMove.At(_bufferMove.Total()-1-index);
  if (curTrend == NULL)
   PrintFormat("%s �� ������� ������ i=%d, total=%d", MakeFunctionPrefix(__FUNCTION__), index, _bufferMove.Total());
  return (curTrend);
 }
 
// ���������� ����� �� �������
CMove * CMoveContainer::GetTrendByIndex(int index)
 {
  if (index == 0) // ���� ���� ������� ��������� �� ��������� �����
   {
    return (_curTrend);
   }
  if (index == 1) // ���� ���� ������� ��������� �� ���������� �����
   {
    return (_prevTrend); 
   }
  return NULL;
 }

// ���������� ��������� �� ��������� �����
CMove * CMoveContainer::GetLastTrend(void)
 {
  int total = _bufferMove.Total();
  CMove *tempMove;
  for (int i=0;i<total;i++)
   {
    tempMove = _bufferMove.At(i);
    if (tempMove.GetMoveType() == MOVE_TREND_DOWN || tempMove.GetMoveType() == MOVE_TREND_UP)
     {             
      return (tempMove); 
     }
   }
  return (NULL);
 } 
 
// ����� ������� ����� ��������
void CMoveContainer::RemoveAll(void)
 {
  int countTrend=0; // ���������� ��������� �������  
  int last_index; // ������ ������� ������
  CMove *move;
  // �������� �� ����� ������ �������� � ������� �� �� ����������� ������
  for(int i=0;i<_bufferMove.Total();i++)
   {
    move = _bufferMove.At(i);
    // ���� ����� �����
    if (move.GetMoveType() == MOVE_TREND_UP || move.GetMoveType() == MOVE_TREND_DOWN)
     countTrend++;
    // ���� ����� ������ �����
    if (countTrend == 2)
     {
      last_index = i-1;
      break;
     }
   }
  // Comment("���������� ��������� �������� = ",last_index);
  // ������� ����� �������� �� ������� ������
  _bufferMove.DeleteRange(0,last_index);
 }
 
// ����� ��������� ��������� � �����
void CMoveContainer::UploadOnEvent(string sparam,double dparam,long lparam)
 {
  CMove *temparyMove;
  CMove *temparyTrend;
  // ��������� ����������
  _container.UploadOnEvent(sparam,dparam,lparam);
  // ���� ��������� ��������� - ������
  if (sparam == _eventExtrDown)
   {
     // �������� �������� �������� ��������
     temparyMove = new CMove("move"+_countMoves++,_chartID, _symbol, _period,_container.GetFormedExtrByIndex(0,EXTR_HIGH),_container.GetFormedExtrByIndex(1,EXTR_HIGH),_container.GetFormedExtrByIndex(0,EXTR_LOW),_container.GetFormedExtrByIndex(1,EXTR_LOW),_percent );
     // ���� ������� �������� ������� ��������
     if (temparyMove != NULL)
        {
         // ���� ������� �����
         if (temparyMove.GetMoveType() == MOVE_TREND_UP || temparyMove.GetMoveType() == MOVE_TREND_DOWN)
          {
           
           // ��������� ������� �����
           _trendNow = temparyMove.GetMoveType();
           // �� ������� �����
           RemoveAll();
           // � ��������� ����� � �����
           _bufferMove.Add(temparyMove);
          }
         // ����� ����  ��� ����
         else if (temparyMove.GetMoveType() == MOVE_FLAT_A ||
                  temparyMove.GetMoveType() == MOVE_FLAT_B ||
                  temparyMove.GetMoveType() == MOVE_FLAT_C ||
                  temparyMove.GetMoveType() == MOVE_FLAT_D ||
                  temparyMove.GetMoveType() == MOVE_FLAT_E ||
                  temparyMove.GetMoveType() == MOVE_FLAT_F ||
                  temparyMove.GetMoveType() == MOVE_FLAT_G 
                 )
          {
           temparyTrend = new CMove("move"+_countMoves++,_chartID, _symbol, _period,_container.GetFormedExtrByIndex(0,EXTR_HIGH),
                                                               _container.GetFormedExtrByIndex(1,EXTR_HIGH),
                                                               _container.GetFormedExtrByIndex(1,EXTR_LOW),
                                                               _container.GetFormedExtrByIndex(2,EXTR_LOW),_percent );
           if (temparyTrend != NULL)
            {
             if (temparyTrend.GetMoveType() != MOVE_TREND_UP && temparyTrend.GetMoveType() != MOVE_TREND_DOWN)
              {
               // �� ��������� ��� � �����
               _bufferMove.Add(temparyMove);
               delete temparyTrend;
              }
             else
              {
               delete temparyMove;
              }
            }
           else
            {
             _bufferMove.Add(temparyMove);
            }
          }
        }     
   }
  // ���� ��������� ��������� - �������
  if (sparam == _eventExtrUp)
   {
     temparyMove = new CMove("move"+_countMoves++,_chartID, _symbol, _period,_container.GetFormedExtrByIndex(0,EXTR_HIGH),_container.GetFormedExtrByIndex(1,EXTR_HIGH),_container.GetFormedExtrByIndex(0,EXTR_LOW),_container.GetFormedExtrByIndex(1,EXTR_LOW),_percent );
     if (temparyMove != NULL)
        {
         // ���� ������� �����
         if (temparyMove.GetMoveType() == MOVE_TREND_UP || temparyMove.GetMoveType() == MOVE_TREND_DOWN)
          {
           // �� ������� �����
           RemoveAll();          
           // � ��������� ����� � �����
           _bufferMove.Add(temparyMove);
          }
         // ����� ����  ��� ����
         else if (temparyMove.GetMoveType() == MOVE_FLAT_A || 
                  temparyMove.GetMoveType() == MOVE_FLAT_B || 
                  temparyMove.GetMoveType() == MOVE_FLAT_C || 
                  temparyMove.GetMoveType() == MOVE_FLAT_D || 
                  temparyMove.GetMoveType() == MOVE_FLAT_E || 
                  temparyMove.GetMoveType() == MOVE_FLAT_F || 
                  temparyMove.GetMoveType() == MOVE_FLAT_G 
                  )
          {
           temparyTrend = new CMove("move"+_countMoves++,_chartID, _symbol, _period,_container.GetFormedExtrByIndex(1,EXTR_HIGH),
                                                               _container.GetFormedExtrByIndex(2,EXTR_HIGH),
                                                               _container.GetFormedExtrByIndex(0,EXTR_LOW),
                                                               _container.GetFormedExtrByIndex(1,EXTR_LOW),_percent );          
           if (temparyTrend != NULL)
            {         
             // ���� �� ���� ��������� ������ �� ��������� � ������������ �����
             if (temparyTrend.GetMoveType() != MOVE_TREND_UP && temparyTrend.GetMoveType() != MOVE_TREND_DOWN)
              {
               // �� ��������� ��� � �����
               _bufferMove.Add(temparyMove);
               delete temparyTrend;
              }
             else
              {
               delete temparyMove;
              }
            }
           else
            {
             // �� ��������� ��� � �����
             _bufferMove.Add(temparyMove);
            }
            
          }
        }   
   }
  /*
  // ���� ��������� ������� - �����
  temparyMove = _bufferMove.At(_bufferMove.Total()-1);
  if (temparyMove.GetMoveType() == MOVE_TREND_UP || temparyMove.GetMoveType() == MOVE_TREND_DOWN)
   {
    _lastTrendLineDown = temparyMove.GetLineDownName();
    _lastTrendLineUp = temparyMove.GetLineUpName();
   }
  */
 }
 
// ����� ��������� ������ �� �������
bool CMoveContainer::UploadOnHistory(void)
 { 
  if(!_isHistoryUploaded || _bufferMove.Total()<=0)
  {
   int i;
   int extrTotal;
   int dirLastExtr;
   int highIndex=0;
   int lowIndex=0;
   int countTrend=0; // ������� ������� 
   bool jumper=true;
   CMove *temparyMove; 
   CMove *moveForPrevTrend = NULL; // ��������� ��� �������� ����������� ��������
   CMove *tempPrevTrend; // ��������� �� ���������� �����
   // ��������� ������ 
   for (int attempts=0;attempts<25;attempts++)
   {
    _container.Upload(0);
    Sleep(100);
   }
   // ���� ������� ���������� ��� ���������� �� �������
   if (_container.isUploaded())
   {
    extrTotal = _container.GetCountFormedExtr(); // �������� ���������� �����������
    dirLastExtr = _container.GetLastFormedExtr(EXTR_BOTH).direction; // �������� ��������� �������� ����������
    // �������� �� ����������� � ��������� ����� ��������
    for (i=0; i < extrTotal-4; i++)
    {
     // ������� ������ ��������
     temparyMove = new CMove("move"+_countMoves++,_chartID,_symbol,_period,_container.GetFormedExtrByIndex(highIndex,EXTR_HIGH),
                                                      _container.GetFormedExtrByIndex(highIndex+1,EXTR_HIGH),
                                                      _container.GetFormedExtrByIndex(lowIndex,EXTR_LOW),
                                                      _container.GetFormedExtrByIndex(lowIndex+1,EXTR_LOW),_percent );
     if (temparyMove != NULL)
     {
      // ���� ���������� �����
      if (temparyMove.GetMoveType() == MOVE_TREND_UP || temparyMove.GetMoveType() == MOVE_TREND_DOWN)
      {
      // temparyMove = new CMove("move"+_countMoves++,_chartID,_symbol,_period,_container.GetFormedExtrByIndex(highIn
       // ��������� ����� � �����
       _bufferMove.Add(temparyMove);
      
       countTrend ++;
       // ���� ���������� ������� - 1
       if (countTrend == 1)
       {
        _prevTrend = temparyMove;
       }
       // ���� ���������� ������� - 2
       if (countTrend == 2)
       {
        _curTrend = temparyMove;
        _isHistoryUploaded = true;
        return (true);
       }
      }
      // ���� ��� ����
      else if (temparyMove.GetMoveType() == MOVE_FLAT_A ||
               temparyMove.GetMoveType() == MOVE_FLAT_B ||
               temparyMove.GetMoveType() == MOVE_FLAT_C ||
               temparyMove.GetMoveType() == MOVE_FLAT_D ||
               temparyMove.GetMoveType() == MOVE_FLAT_E ||
               temparyMove.GetMoveType() == MOVE_FLAT_F ||
               temparyMove.GetMoveType() == MOVE_FLAT_G 
              )
      {
       if (moveForPrevTrend == NULL)
       {
        // �� ������ ��������� ��� � ����� ��������
        _bufferMove.Add(temparyMove);
       }
       else
       {
        if (moveForPrevTrend.GetMoveType() != MOVE_TREND_UP && moveForPrevTrend.GetMoveType() != MOVE_TREND_DOWN)
        {
         // �� ������ ��������� ��� � ����� ��������
         _bufferMove.Add(temparyMove);                   
        }
       }
      }
     }                                                         
                                                         
    // ���� ��������� ��������� �������
    if (dirLastExtr == 1)
    {
     // ���� jumper == true, �� ����������� ������ 
     if (jumper)
     {
      highIndex++;
     }
     else
     {
      lowIndex++;
     }
     jumper = !jumper;
    }
    // ���� ��������� ��������� ������
    if (dirLastExtr == -1)
    {
     // ���� jumper == true, �� ����������� ������ 
     if (jumper)
     {
      lowIndex++;
     }
     else
     {
      highIndex++;
     }
     jumper = !jumper;
    }        
    moveForPrevTrend = temparyMove; // ��������� ���������� ��������
   }
  }
 }
 _isHistoryUploaded = false;
 return (false);  
}