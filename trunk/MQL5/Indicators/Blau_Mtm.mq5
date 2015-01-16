//+------------------------------------------------------------------+
//|                                                     Blau_Mtm.mq5 |
//|                        Copyright 2011, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2011, MetaQuotes Software Corp." // название компании-производителя
#property link      "http://www.mql5.com"                       // ссылка на сайт компании-производителя
#property description "q-period Momentum (William Blau)"        // краткое описание mql5-программы
#include <WilliamBlau.mqh>              // включаемый файл (поиск в стандартном каталоге)
//--- настройки индикатора
#property indicator_separate_window     // выводить индикатор в отдельное окно
#property indicator_buffers 5           // количество буферов для расчёта индикатора
#property indicator_plots   1           // количество графических построений в индикаторе
//--- графическое построение #0 (Main)
#property indicator_label1  "Mtm"       // метка для графического построения #0
#property indicator_type1   DRAW_LINE   // способ отображения: DRAW_LINE - линия
#property indicator_color1  Blue        // цвет для вывода линии: Blue - синий
#property indicator_style1  STYLE_SOLID // стиль линии: STYLE_SOLID - сплошная линия
#property indicator_width1  1           // толщина линии
//--- входные параметры
input int    q=2;  // q - период, по которому вычисляется моментум
input int    r=20; // r - период 1-й EMA, применительно к моментуму
input int    s=5;  // s - период 2-й EMA, применительно к результату первого сглаживания
input int    u=3;  // u - период 3-й EMA, применительно к результату второго сглаживания
input ENUM_APPLIED_PRICE AppliedPrice=PRICE_CLOSE; // AppliedPrice - тип цены
//--- динамические массивы для расчёта индикатора
double MainBuffer[];     // u-периодная 3-я EMA (для графического построения #0)
double PriceBuffer[];    // массив цен
double MtmBuffer[];      // q-периодный моментум
double EMA_MtmBuffer[];  // r-периодная 1-я EMA
double DEMA_MtmBuffer[]; // s-периодная 2-я EMA
//--- глобальные переменные
int    begin1, begin2, begin3, begin4; // индекс таймсерии, с которой начинаются значимые данные
int    rates_total_min; // минимальный размер входных таймсерий индикатора
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- связь индикаторных буферов с соответствующими динамическими массивами 
   // значения рассчитанного индикатора; предназначены для отрисовки графических построений
   // графическое построение #0
   SetIndexBuffer(0,MainBuffer,INDICATOR_DATA);             // u-периодная 3-я EMA
   // буферы для промежуточных расчётов индикатора; не предназначены для отрисовки
   SetIndexBuffer(1,PriceBuffer,INDICATOR_CALCULATIONS);    // массив цен
   SetIndexBuffer(2,MtmBuffer,INDICATOR_CALCULATIONS);      // q-периодный моментум
   SetIndexBuffer(3,EMA_MtmBuffer,INDICATOR_CALCULATIONS);  // r-периодная 1-я EMA
   SetIndexBuffer(4,DEMA_MtmBuffer,INDICATOR_CALCULATIONS); // s-периодная 2-я EMA
/*
//--- графическое построение #0 (Main)
   PlotIndexSetString(0,PLOT_LABEL,"Mtm");             // метка для графического построения #0
   PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_LINE);    // способ отображения: DRAW_LINE - линия
   PlotIndexSetInteger(0,PLOT_LINE_COLOR,Blue);        // цвет для вывода линии: Blue - синий
   PlotIndexSetInteger(0,PLOT_LINE_STYLE,STYLE_SOLID); // стиль линии: STYLE_SOLID - сплошная линия
   PlotIndexSetInteger(0,PLOT_LINE_WIDTH,1);           // толщина линии
*/
//--- точность отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---
   begin1=q-1;        //                             - значимые данные: MtmBuffer[]
   begin2=begin1+r-1; // or =(q-1)+(r-1)             - значимые данные: EMA_MtmBuffer[]
   begin3=begin2+s-1; // or =(q-1)+(r-1)+(s-1)       - значимые данные: DEMA_MtmBuffer[]
   begin4=begin3+u-1; // or =(q-1)+(r-1)+(s-1)+(u-1) - значимые данные: MainBuffer[]
   //
   rates_total_min=begin4+1; // минимальный размер входных таймсерий индикатора
//--- количество начальных баров без отрисовки графического построения #0
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,begin4);
//--- краткое имя индикатора
   string shortname=PriceName(AppliedPrice)+","+string(q)+","+string(r)+","+string(s)+","+string(u);
   IndicatorSetString(INDICATOR_SHORTNAME,"Blau_Mtm("+shortname+")");
//--- OnInit done
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(
                const int rates_total,     // размер входных таймсерий
                const int prev_calculated, // обработано баров на предыдущем вызове
                const datetime &Time[],    // Time
                const double &Open[],      // Open
                const double &High[],      // High
                const double &Low[],       // Low
                const double &Close[],     // Close
                const long &TickVolume[],  // Tick Volume
                const long &Volume[],      // Real Volume
                const int &Spread[]        // Spread
               )
  {
   int i,pos;
//--- достаточно ли данных для расчёта индикатора
   if(rates_total<rates_total_min) return(0);
//--- расчёт массива цен PriceBuffer[]
   CalculatePriceBuffer(
                        AppliedPrice,        // тип цены
                        rates_total,         // размер входных таймсерий
                        prev_calculated,     // обработано баров на предыдущем вызове
                        Open,High,Low,Close, // массивы Open[], High[], Low[], Close[]
                        PriceBuffer          // рассчитываемый массив цен
                       );
//--- расчёт q-периодного моментума
   // определение индекса (pos), с которого начать/продолжить расчёт q-периодного моментума
   // обнуление незначимых элементов массива MtmBuffer[]
   if(prev_calculated==0)      // если первый вызов
     {
      pos=begin1;              // то расcчитывать все значения, начиная со значимого индекса
      for(i=0;i<pos;i++)       // до значимого индекса
         MtmBuffer[i]=0.0;     // значения обнулить
     }
   else pos=prev_calculated-1; // иначе рассчитывать только последнее значение
   // расчёт значимых элементов массива MtmBuffer[]
   for(i=pos;i<rates_total;i++)
      MtmBuffer[i]=PriceBuffer[i]-PriceBuffer[i-(q-1)];
//--- сглаживание методом EMA
   // r-периодная 1-я EMA
   ExponentialMAOnBufferWB(
                           rates_total,     // размер входных таймсерий
                           prev_calculated, // обработано баров на предыдущем вызове
                           begin1,          // с какого индекса начинаются значимые данные во входном массиве
                           r,               // период сглаживания
                           MtmBuffer,       // входной массив
                           EMA_MtmBuffer    // выходной массив
                          );
   // s-периодная 2-я EMA
   ExponentialMAOnBufferWB(rates_total,prev_calculated,begin2,s,EMA_MtmBuffer,DEMA_MtmBuffer);
   // u-периодная 3-я EMA (для графического построения #0)
   ExponentialMAOnBufferWB(rates_total,prev_calculated,begin3,u,DEMA_MtmBuffer,MainBuffer);
//--- OnCalculate done. Return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+