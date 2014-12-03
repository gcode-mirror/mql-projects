//+------------------------------------------------------------------+
//|                                                      Volumes.mq5 |
//|                        Copyright 2009, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2009, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//---- indicator settings
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  Green,Red
#property indicator_style1  0
#property indicator_width1  1
#property indicator_minimum 0.0

//---- indicator buffers
double                    ExtVolumesBuffer[];
double                    ExtColorsBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {   
   SetIndexBuffer(0,ExtVolumesBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtColorsBuffer,INDICATOR_COLOR_INDEX);

   IndicatorSetString(INDICATOR_SHORTNAME,"Volumes");

   IndicatorSetInteger(INDICATOR_DIGITS,0);
   
   //Добавим окно с символом и периодом индюка если его нет
   bool chart = true;
   long z = ChartFirst();
   while (chart && z>=0)
   {
   if (ChartSymbol(z)== _Symbol && ChartPeriod(z)==_Period)  // если найден график с текущим символом и периодом 
      {
       // если на этом графике нашли индикатор IsNewBar
       if (ChartIndicatorGet(z,0,"IsNewBar") != INVALID_HANDLE)
        {
         chart=false;
         break;
        }
      }
   z = ChartNext(z);
   }
   // если ни на одном графике данного символа и ТФ не найден IsNewBar, то создаем его на новом графике
   if (chart) 
    {
     z = ChartOpen(_Symbol, _Period);
     if (z>0)
      {
       int handleIsNewBar = iCustom(_Symbol,_Period,"IsNewBar");
       // если удалось создать хэндл
       if (handleIsNewBar != INVALID_HANDLE)         
        ChartIndicatorAdd(z,0,handleIsNewBar);
      }
    }
   
  }
//+------------------------------------------------------------------+
//|  Volumes                                                         |
//+------------------------------------------------------------------+
bool couldCalc = true; // флаг разрешения пересчета индикатора
int count=0;
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
  // если разрешено делать пересчет индикатора
  if (couldCalc)
   {
    //---check for rates total
    if(rates_total<3)
     return(0);
    
    //--- starting work
    int start=prev_calculated-1;
    //--- correct position
    if(start<2) start = 2;
     CalculateVolume(start,rates_total,tick_volume);
   }
  couldCalc = false;
  return(rates_total);
 }
 
 int countEvent = 0;
  
void OnChartEvent(const int id,         // идентификатор события  
                  const long& lparam,   // параметр события типа long
                  const double& dparam, // параметр события типа double
                  const string& sparam  // параметр события типа string
  )
   {
    
    // если получили события о том, что пришел новый бар на заданном таймфрейме
    if (id==CHARTEVENT_CUSTOM+1)
     {
     Comment("количество событий = ",countEvent++);
      couldCalc = true; // включаем флаг возможности пересчета индикатора
     }
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateVolume(const int nPosition,
                     const int nRatesCount,
                     const long &SrcBuffer[])
  {
   ExtVolumesBuffer[0]=(double)SrcBuffer[0];
   ExtColorsBuffer[0]=0.0;
   
   for(int i=nPosition;i<nRatesCount && !IsStopped();i++)
     {
      double dCurrVolume=(double)SrcBuffer[i];
      double dPrevVolume=(double)SrcBuffer[i-1];
      double dPrePreVolume=(double)SrcBuffer[i-2];
      ExtVolumesBuffer[i-1]=dPrevVolume;
      if(dPrevVolume>dPrePreVolume)
         ExtColorsBuffer[i-1]=0.0;
      else
         ExtColorsBuffer[i-1]=1.0;
     }
  }