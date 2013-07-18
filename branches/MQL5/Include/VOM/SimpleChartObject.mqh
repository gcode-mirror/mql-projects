//+------------------------------------------------------------------+
//|                                            SimpleChartObject.mqh |
//|                                     Copyright Paul Hampton-Smith |
//|                            http://paulsfxrandomwalk.blogspot.com |
//+------------------------------------------------------------------+
#property copyright "Paul Hampton-Smith"
#property link      "http://paulsfxrandomwalk.blogspot.com"

#include <Object.mqh>
//+------------------------------------------------------------------+
/** Base class for creating chart objects.
<b> Change history </b>
	- V0.1 first release 10/1/2010
	- V0.2 derived from CObject

*/
//+------------------------------------------------------------------+
class CSimpleChartObject : public CObject
  {
public:
                     CSimpleChartObject() { m_strName="";}
                    ~CSimpleChartObject() { if(ObjectFind(0,m_strName)>=0) ObjectDelete(0,m_strName);}

   string Name(){return(m_strName);}
   string Text(){return ObjectGetString(0,m_strName,OBJPROP_TEXT);}
   bool              Create(ENUM_OBJECT enumObjectType,string strName,int nLeftPos,int nTopPos,int nXsize,int nYsize,color BackgroundColor,string strText,color TextColor,string strFont,int nFontSize);
   // Set horizontal and vertical justification.
   void Align(ENUM_ANCHOR_POINT enumAnchor)
     {
      ObjectSetInteger(0,Name(),OBJPROP_ANCHOR,enumAnchor);
     }

protected:
   string            m_strName;
  };
//+------------------------------------------------------------------+
/// Main creation function to set up common attributes.
//+------------------------------------------------------------------+
bool CSimpleChartObject::Create(ENUM_OBJECT enumObjectType,string strName,int nLeftPos,int nTopPos,int nXsize,int nYsize,color BackgroundColor,string strText,color TextColor,string strFont,int nFontSize)
  {
   if(ObjectFind(0,strName)<0)
     {
      if(!ObjectCreate(0,strName,enumObjectType,0,0,0,0,0)) return(false);
     }
   m_strName=strName;
   ObjectSetInteger(0,strName,OBJPROP_XDISTANCE,nLeftPos);
   ObjectSetInteger(0,strName,OBJPROP_YDISTANCE,nTopPos);
   ObjectSetInteger(0,strName,OBJPROP_XSIZE,nXsize);
   ObjectSetInteger(0,strName,OBJPROP_YSIZE,nYsize);
   ObjectSetInteger(0,strName,OBJPROP_BGCOLOR,BackgroundColor);
   ObjectSetString(0,strName,OBJPROP_TEXT,strText);
   ObjectSetInteger(0,strName,OBJPROP_COLOR,TextColor);
   ObjectSetString(0,strName,OBJPROP_FONT,strFont);
   ObjectSetInteger(0,strName,OBJPROP_FONTSIZE,nFontSize);
   ObjectSetInteger(0,strName,OBJPROP_SELECTABLE,false);
   ChartRedraw(0);
   return(true);
  }
//+------------------------------------------------------------------+
/// Simple command button chart object
//+------------------------------------------------------------------+
class CButton : public CSimpleChartObject
  {
public:
   bool Create(string strName,int nLeftPos,int nTopPos,int nXsize,int nYsize,color BackgroundColor,string strText,color TextColor,string strFont,int nFontSize)
     { return(CSimpleChartObject::Create(OBJ_BUTTON,strName,nLeftPos,nTopPos,nXsize,nYsize,BackgroundColor,strText,TextColor,strFont,nFontSize));}
  };
//+------------------------------------------------------------------+
/// Simple edit chart object
//+------------------------------------------------------------------+
class CEdit : public CSimpleChartObject
  {
public:
   bool Create(string strName,int nLeftPos,int nTopPos,int nXsize,int nYsize,color BackgroundColor,string strText,color TextColor,string strFont,int nFontSize)
     { return(CSimpleChartObject::Create(OBJ_EDIT,strName,nLeftPos,nTopPos,nXsize,nYsize,BackgroundColor,strText,TextColor,strFont,nFontSize));}
   /// Return contents converted to double
   double DoubleValue(){return(StringToDouble(CSimpleChartObject::Text()));}
   /// Return contents converted to long
   long IntegerValue(){return(StringToInteger(CSimpleChartObject::Text()));}
  };
//+------------------------------------------------------------------+
/// Simple label chart object
//+------------------------------------------------------------------+
class CLabel : public CSimpleChartObject
  {
public:
   bool Create(string strName,int nLeftPos,int nTopPos,int nXsize,int nYsize,color BackgroundColor,string strText,color TextColor,string strFont,int nFontSize)
     { return(CSimpleChartObject::Create(OBJ_LABEL,strName,nLeftPos,nTopPos,nXsize,nYsize,BackgroundColor,strText,TextColor,strFont,nFontSize));}
  };

#include <Arrays/ArrayObj.mqh>  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CTable
  {
protected:
   CLabel            m_Header;
   CArrayObj         m_Contents;
   int               m_nLeftPos;
   int               m_nTopPos;
   int               m_nRowPos;
   int               m_nFontSize;
   color             m_TextColor;

public:
	void					ClearContents(){m_Contents.Clear();m_nRowPos=m_nTopPos+20;}
   void              Create(int nLeftPos,int nTopPos,string strHeader,color HeaderColor,color TextColor,int nFontSize);

   void              AddRow(string strRow);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTable::Create(int nLeftPos,int nTopPos,string strHeader,color HeaderColor,color TextColor,int nFontSize)
  {
   m_Header.Create("Header",nLeftPos,nTopPos,100,100,Black,strHeader,HeaderColor,"Courier New Bold",nFontSize);
   m_nLeftPos= nLeftPos;
   m_nTopPos = nTopPos;
   m_nRowPos = nTopPos+20;
   m_nFontSize = nFontSize;
   m_TextColor = TextColor;
   m_Contents.Clear();
  }
//+------------------------------------------------------------------+
/** Table consisting of header plus row array
<b> Change history </b>
	- V0.1 first release 12/1/2010
	- V0.2 TODO: CLabels apepar to have a limited length.  Will have to develop a table of individual cells

*/
//+------------------------------------------------------------------+
void CTable::AddRow(string strRow)
  {
   CLabel *row=new CLabel;
   row.Create("row"+(string)m_Contents.Total(),m_nLeftPos,m_nRowPos,100,100,Black,strRow,m_TextColor,"Courier New",m_nFontSize);
   m_Contents.Add(row);
   m_nRowPos+=20;
  }



//+------------------------------------------------------------------+
