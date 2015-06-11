//+------------------------------------------------------------------+
//|                                                 EvgenysBrain.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <Lib CisNewBarDD.mqh>                // для проверки формирования нового бара
#include <CompareDoubles.mqh>                 // для сравнения вещественных чисел
#include <ChartObjects/ChartObjectsLines.mqh> // для рисования линий тренда
#include <DrawExtremums/CExtrContainer.mqh>   // контейнер экстремумов (попробовать удалить после появления контейнера трендов)
#include <ContainerBuffers.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input double percent = 0.1; // для контейнера движений (скорее всего станет константой)


// перечисление для сигналов торговли
enum ENUM_SIGNAL_FOR_TRADE
{
 SELL = -1,     // открытие позиции на продажу
 BUY  = 1,      // открытие позиции на покупку
 NO_SIGNAL = 0, // для действий, когда сигнала на открытие позиции не было
 DISCORD = 2,   // сигнал противоречия, "разрыв шаблона"
};

 
class CEvgenysBrain
{
private:
 CisNewBar *_isNewBar;
 CContainerBuffers *_conbuf;
 CExtrContainer *_extremums; // контейнер экстремумов
 CExtremum *extr1; //Для вычисления коридоров (нахождения разности и пр.)
 CExtremum *extr2;
 CExtremum *extr3; 
 CExtremum *extr4;
 ENUM_TIMEFRAMES _period;
 ENUM_SIGNAL_FOR_TRADE signalForTrade;
 string _symbol;
 int _countTotal;  // всего экстремумов
 int _trend;       // текущий тренд 1-й типа
 int _prevTrend;   // предыдущий тренд
 double curBid;   // текущая цена bid
 double curAsk;   // текущая цена Ask
 double prevBid;  // предыдущая цена bid
 double priceTrendUp; // цена верхней линии тренда
 double priceTrendDown; // цена нижней линии тренда
 double H1,H2; // расстояния между экстремумами
 double channelH; // ширина канала
 double horPrice;
 double pbiMove; // значение движение на PBI в текущий момент
 // массивы и буфера
 MqlRates rates[]; // буфер котировок
 CChartObjectTrend  trendLine; // объект класса трендовой линии
 CChartObjectHLine  horLine; // объект класса горизонтальной линии

public:
                     CEvgenysBrain(string symbol,ENUM_TIMEFRAMES period, CExtrContainer *extremums, CContainerBuffers *conbuf);
                    ~CEvgenysBrain();
                    int GetSignal();
                    int CountStopLossForTrendLines();
                    int IsTrendNow();
                    void UploadOnEvent();
                    bool CheckClose();
                    bool UploadExtremums();
                    void DrawLines();
                    void DeleteLines();
                    
                    
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CEvgenysBrain::CEvgenysBrain(string symbol,ENUM_TIMEFRAMES period, CExtrContainer *extremums, CContainerBuffers *conbuf) // удалть хэндл  и передать CExtrContainer
{
 _countTotal = 0;  // всего экстремумов
 _trend = 0;       // текущий тренд 1-й типа
 _prevTrend = 0;   // предыдущий тренд
 _symbol = symbol;
 _period = period;
 _isNewBar = new CisNewBar(_symbol, _period);
 _isNewBar.isNewBar();
 _extremums = extremums;
 _conbuf = conbuf;
 _trend = IsTrendNow();
  if (_trend)
  {
   // строим линии 
   DrawLines ();    
  }
  
 // сохраняем цены  
 curBid = SymbolInfoDouble(_symbol,SYMBOL_BID);   // стоит ли использовать конбуф, ведь таким образом данные будут точнее
 curAsk = SymbolInfoDouble(_symbol,SYMBOL_ASK);
 prevBid = curBid;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CEvgenysBrain::~CEvgenysBrain()
{
 DeleteLines ();
 delete _isNewBar;
}
//+------------------------------------------------------------------+

int CEvgenysBrain::GetSignal()
{
 curBid = SymbolInfoDouble(_symbol,SYMBOL_BID); 
 curAsk = SymbolInfoDouble(_symbol,SYMBOL_ASK);
 signalForTrade =  NO_SIGNAL;
  // если текущее движение - тренд 1-й типа вверх
 if (_trend == 1)
 {
  // если сформировался новый бар
  if (_isNewBar.isNewBar() > 0)
  {
   priceTrendUp = ObjectGetValueByTime(0,"trendUp",TimeCurrent());
   priceTrendDown = ObjectGetValueByTime(0,"trendDown",TimeCurrent());   
   channelH = priceTrendUp - priceTrendDown;   // вычисляю ширину канала   
   // если цена закрытия на последнем баре выше цены открытия (в нашу сторону), а на предыдущем баре - обратная ситуевина
   if ( GreatDoubles(_conbuf.GetClose(_period).buffer[2], _conbuf.GetOpen(_period).buffer[2]) && LessDoubles(_conbuf.GetClose(_period).buffer[1],_conbuf.GetOpen(_period).buffer[1]) &&  // если последний бар закрылся в нашу сторону, а прошлый - в противоположную
        LessOrEqualDoubles(MathAbs(curBid-priceTrendDown),channelH*0.2)                             // если текущая цена находится возле нижней границы канала тренда 
      )
   {
    signalForTrade = BUY;
   }
  }
 }
 // если текущее движение - тренд 1-й типа вниз
 if (_trend == -1)
 {
  // если сформировался новый бар
  if (_isNewBar.isNewBar() > 0)
  {
   priceTrendUp = ObjectGetValueByTime(0,"trendUp", TimeCurrent());
   priceTrendDown = ObjectGetValueByTime(0,"trendDown", TimeCurrent());   
   channelH = priceTrendUp - priceTrendDown;   // вычисляю ширину канала   
   // если цена закрытия на последнем баре ниже цены открытия (в нашу сторону), а на предыдущем баре - обратная ситуевина
   if ( LessDoubles(_conbuf.GetClose(_period).buffer[2], _conbuf.GetOpen(_period).buffer[2]) && GreatDoubles(_conbuf.GetClose(_period).buffer[1],_conbuf.GetOpen(_period).buffer[1]) &&  // если последний бар закрылся в нашу сторону, а прошлый - в противоположную
        LessOrEqualDoubles(MathAbs(curBid-priceTrendUp),channelH * 0.2)                             // если текущая цена находится возле нижней границы канала тренда 
      )
   {
    signalForTrade =  SELL;
   }
  }
 }    
 prevBid = curBid;
 if (_trend != 0)
  _prevTrend = _trend; 
 return signalForTrade;
}

bool CEvgenysBrain::CheckClose()
{
 if (_prevTrend == -_trend)
  return true;
 else
  return false;
}


// вернет true, если тренд валиден
int  CEvgenysBrain::IsTrendNow ()
{
 double h1,h2;
 extr1 = _extremums.GetFormedExtrByIndex(0, EXTR_BOTH);
 extr2 = _extremums.GetFormedExtrByIndex(1, EXTR_BOTH);
 extr3 = _extremums.GetFormedExtrByIndex(2, EXTR_BOTH);
 extr4 = _extremums.GetFormedExtrByIndex(3, EXTR_BOTH);
 // вычисляем расстояния h1, h2
 h1 = MathAbs(extr1.price - extr3.price);
 h2 = MathAbs(extr2.price - extr4.price);
 // если тренд вверх 
 if (GreatDoubles(extr1.price,extr3.price) && GreatDoubles(extr2.price,extr4.price)) // можно переписать покороче (через ИЛИ - ретёрн -дирекшн)
 {
  // если последний экстремум - вниз
  if (extr1.direction == -1) 
  {
   H1 = extr2.price - extr3.price;
   H2 = extr4.price - extr1.price;
   // если наша трендовая линия нас удовлетворяет
   if (GreatDoubles(h1, H1*percent) && GreatDoubles(h2, H2*percent) )
    return (1);
  }
 }
 // если тренд вниз
 if (LessDoubles(extr1.price,extr3.price) && LessDoubles(extr2.price,extr4.price))
 {
  // если  последний экстремум - вверх
  if (extr1.direction == 1)
  {
   H1 = extr2.price - extr3.price;
   H2 = extr4.price - extr1.price;
   // если наша трендования линия нас удовлетворяет
   if (GreatDoubles(h1, H1 * percent) && GreatDoubles(h2, H2 * percent))    
    return (-1);
  }
 }   
 return (0);   
}

// функция отрисовывает линии по экстремумам  
void CEvgenysBrain::DrawLines()
{
 // то создаем линии по точкам
 if (extr1.direction == 1)
 {
  trendLine.Create(0,"trendUp",0,extr3.time,extr3.price,extr1.time, extr1.price);   // верхняя  линия
  ObjectSetInteger(0,"trendUp",OBJPROP_RAY_RIGHT,1);
  trendLine.Create(0,"trendDown",0,extr4.time,extr4.price,extr2.time,extr2.price); // нижняя  линия
  ObjectSetInteger(0,"trendDown",OBJPROP_RAY_RIGHT,1);   
  if (_trend == 1)
  {
   horLine.Create(0,"horLine",0,extr1.price); // горизонтальная линия    
   horPrice = extr1.price;    
  } 
  if (_trend == -1)
  {
   horLine.Create(0,"horLine",0,extr2.price); // горизонтальная линия       
   horPrice = extr1.price;         
  }        
 }
 // то создаем линии по точкам
 if (extr1.direction == -1)
 {
  trendLine.Create(0,"trendDown", 0, extr3.time, extr3.price, extr1.time, extr1.price); // нижняя  линия
  ObjectSetInteger(0,"trendDown", OBJPROP_RAY_RIGHT, 1);
  trendLine.Create(0,"trendUp", 0, extr4.time, extr4.price, extr2.time, extr2.price); // верхняя  линия
  ObjectSetInteger(0,"trendUp", OBJPROP_RAY_RIGHT, 1);   
  if (_trend == 1)
  {
   horLine.Create(0,"horLine", 0, extr2.price); // горизонтальная линия     
   horPrice = extr2.price;           
  } 
  if (_trend == -1)
  {
   horLine.Create(0,"horLine", 0, extr1.price); // горизонтальная линия      
   horPrice = extr1.price;          
  }          
 }   
} 

// функция удаляет линии с графика
void CEvgenysBrain::DeleteLines ()
{
 ObjectDelete(0,"trendUp");
 ObjectDelete(0,"trendDown");
 ObjectDelete(0,"horLine");
}

// функция вычисляет стоп лосс для трендовых линий
int CEvgenysBrain::CountStopLossForTrendLines ()
 {
  // если тренд вверх
  if (_trend == 1)
   {
    return (int((MathAbs(curBid-extr1.price) + H1*percent)/_Point));
   }
  // если тренд вниз
  if (_trend == -1)
   {
    return (int((MathAbs(curAsk-extr1.price) - H1*percent)/_Point));
   }   
  return (0);
 }
//---------------------------------------------------------------------------+
//         Функция UploadOnEvent()                                           |
//       включить в функцию OnChartEvent() при появлении событий             | 
//       о сформированном экстремуме (верхнем или нижнем)                    |
//---------------------------------------------------------------------------+
void CEvgenysBrain::UploadOnEvent(void)
{
   // удаляем линии с графика
  DeleteLines();
  _trend = IsTrendNow();
  if (_trend)
  {  
   // перерисовываем линии
   DrawLines();     
  }   
}