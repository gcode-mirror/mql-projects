//+------------------------------------------------------------------+
//|                                                CTrendChannel.mqh |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| Класс трендовых линий и каналов                                  |
//+------------------------------------------------------------------+
// подключение необходимых библиотек
#include <ChartObjects/ChartObjectsLines.mqh> // для рисования линий тренда
#include <DrawExtremums/CExtremum.mqh> // класс экстремумов
#include <DrawExtremums/CExtrContainer.mqh> // контейнер экстремумов
#include <CompareDoubles.mqh> // для сравнения вещественных чисел
#include <Arrays\ArrayObj.mqh> // класс динамических массивов
#include <StringUtilities.mqh> // строковые утилиты

// класс трендовых каналов
class CTrend : public CObject
 {
  private:
   CExtremum *_extrUp0,*_extrUp1; // экстремумы верхней линии
   CExtremum *_extrDown0,*_extrDown1; // экстремумы нижней линии
   CChartObjectTrend _trendLine; // объект класса трендовой линии
   int _direction; // направление тренда 
   long _chartID;  // ID графика  
   string _symbol; // символ
   ENUM_TIMEFRAMES _period; // период
   string _trendUpName; // уникальное имя трендовой верхней линии
   string _trendDownName; // уникальное имя трендовой нижней линии
   double _percent; // процент рассчета тренда
   // приватные методы класса
   void GenUniqName (); // генерирует уникальное имя трендового канала
   int  IsItTrend (); // метод проверяет, является ли создаваемый объект трендом. 
  public:
   CTrend(int chartID, string symbol, ENUM_TIMEFRAMES period,CExtremum *extrUp0,CExtremum *extrUp1,CExtremum *extrDown0,CExtremum *extrDown1,double percent); // конструктор класса по экстр
  ~CTrend(); // деструктор класса
   // методы класса
   int  GetDirection () { return (_direction); }; // возвращает направление тренда 
   double GetPriceExtrUp() { return (_extrUp0.price); };
   void ShowTrend (); // показывает тренд на графике
   void HideTrend (); // скрывает отображение тренда
 };
 
// кодирование методов класса трендовых каналов

/////////приватные методы класса

void CTrend::GenUniqName(void) // генерирует уникальное имя трендового канала
 {
  // генерит уникальные имена трендовых линий исходя из символа, периода и времени первого экстремума
  _trendUpName = "trendUp."+_symbol+"."+PeriodToString(_period)+"."+TimeToString(_extrUp0.time);
  _trendDownName = "trendDown."+_symbol+"."+PeriodToString(_period)+"."+TimeToString(_extrDown0.time);
  //Print("trendUp (",DoubleToString(_extrUp0.price),";",TimeToString(_extrUp0.time),") (",DoubleToString(_extrUp1.price),";",TimeToString(_extrUp1.time),")");  
  //Print("trendDown (",DoubleToString(_extrDown0.price),";",TimeToString(_extrDown0.time),") (",DoubleToString(_extrDown1.price),";",TimeToString(_extrDown1.time),")");    
 }
 
int CTrend::IsItTrend(void) // проверяет, является ли данный канал трендовым
 {
  
  double h1,h2;
  double H1,H2;
  // если тренд вверх 
  if (GreatDoubles(_extrUp0.price,_extrUp1.price) && GreatDoubles(_extrDown0.price,_extrDown1.price))
   {
    // если последний экстремум - вниз
    if (_extrDown0.time > _extrUp0.time)
     {
      H1 = _extrUp0.price - _extrDown1.price;
      H2 = _extrUp1.price - _extrDown1.price;
      h1 = MathAbs(_extrDown0.price - _extrDown1.price);
      h2 = MathAbs(_extrUp0.price - _extrUp1.price);
      // если наша трендовая линия нас удовлетворяет
      if (GreatDoubles(h1,H1*_percent) && GreatDoubles(h2,H2*_percent) )
       return (1);
     }
   
   }
  // если тренд вниз
  if (LessDoubles(_extrUp0.price,_extrUp1.price) && LessDoubles(_extrDown0.price,_extrDown1.price))
   {
    
    // если  последний экстремум - вверх
    if (_extrUp0.time > _extrDown0.time)
     {
      H1 = _extrDown0.price - _extrUp1.price;    
      H2 = _extrDown1.price - _extrUp1.price;
      h1 = MathAbs(_extrUp0.price - _extrUp1.price);
      h2 = MathAbs(_extrDown0.price - _extrDown1.price);
      // если наша трендования линия нас удовлетворяет
      if (GreatDoubles(h1,H1*_percent) && GreatDoubles(h2,H2*_percent) )    
       return (-1);
     }

   }   
   
  return (0);
 }

CTrend::CTrend(int chartID,string symbol,ENUM_TIMEFRAMES period,CExtremum *extrUp0,CExtremum *extrUp1,CExtremum *extrDown0,CExtremum *extrDown1,double percent)
 {
  // сохраняем поля класса
  _chartID = chartID;
  _symbol = symbol;
  _period = period;
  _percent = percent;
  // создаем объекты экстремумов для трендовых линий
  _extrUp0   = new CExtremum(extrUp0.direction,extrUp0.price,extrUp0.time,extrUp0.state);
  _extrUp1   = new CExtremum(extrUp1.direction,extrUp1.price,extrUp1.time,extrUp1.state);
  _extrDown0 = new CExtremum(extrDown0.direction,extrDown0.price,extrDown0.time,extrDown0.state);
  _extrDown1 = new CExtremum(extrDown1.direction,extrDown1.price,extrDown1.time,extrDown1.state);
  // генерируем уникальные имена трендовых линий
  GenUniqName();   
  // получаем тип движения
  _direction = IsItTrend ();
  if (_direction != 0)
   {
    // отображаем трендовые линии
    ShowTrend();
   }
 }
 
// деструктор класса
CTrend::~CTrend()
 {
 
 }

void CTrend::ShowTrend(void) // отображает тренд на графике
 {
  _trendLine.Create(_chartID,_trendUpName,0,_extrUp0.time,_extrUp0.price,_extrUp1.time,_extrUp1.price); // верхняя линия
  _trendLine.Create(_chartID,_trendDownName,0,_extrDown0.time,_extrDown0.price,_extrDown1.time,_extrDown1.price); // верхняя линия  
 }

void CTrend::HideTrend(void) // скрывает тренд с графика
 {
  ObjectDelete(_chartID,_trendUpName);
  ObjectDelete(_chartID,_trendDownName);
 }

class CTrendChannel 
 {
  private:
   int _handleDE; // хэндл индикатора DrawExtremums
   int _chartID; //ID графика
   string _symbol; // символ
   string _eventExtrUp; // имя события прихода верхнего экстремума
   string _eventExtrDown; // имя события прихода нижнего экстремума 
   double _percent; // процент рассчета тренда
   ENUM_TIMEFRAMES _period; // период
   bool _trendNow; // флаг того, что в данный момент есть или нет тренда
   CExtrContainer *_container; // контейнер экстремумов
   CArrayObj _bufferTrend;// буфер для хранения трендовых линий  
   // приватные методы класса
   string GenEventName (string eventName) { return(eventName +"_"+ _symbol +"_"+ PeriodToString(_period) ); };
  public:
   // публичные методы класса
   CTrendChannel(int chartID,string symbol,ENUM_TIMEFRAMES period,int handleDE,double percent); // конструктор класса
  ~CTrendChannel(); // деструктор класса
   // методы класса
   CTrend * GetTrendByIndex (int index); // возвращает указатель на тренд по индексу
   bool IsTrendNow () { return (_trendNow); }; // возвращает true, если в текущий момент - тренд, false - если в текущий момент - нет тренд
   void UploadOnEvent (string sparam,double dparam,long lparam); // метод догружает экстремумы по событиям 
   bool UploadOnHistory (); // метод загружает тренды в буфер на истории
   
 };
 
// кодирование методов класса CTrendChannel
CTrendChannel::CTrendChannel(int chartID, string symbol,ENUM_TIMEFRAMES period,int handleDE,double percent)
 {

  _chartID = chartID;
  _handleDE = handleDE;
  _symbol = symbol;
  _period = period;
  _percent = percent;
  _container = new CExtrContainer(handleDE,symbol,period);
  // формируем уникальные имена событий
  _eventExtrDown = GenEventName("EXTR_DOWN_FORMED");
  _eventExtrUp = GenEventName("EXTR_UP_FORMED");
  // если удалось создать объект контейнера
  // if (_container != NULL)
  // {

  // }
 }
 
// деструктор класса
CTrendChannel::~CTrendChannel()
 {
  _bufferTrend.Clear();
 }
 
// возвращает указатель на тренд по индексу
CTrend * CTrendChannel::GetTrendByIndex(int index)
 {
  CTrend *curTrend = _bufferTrend.At(_bufferTrend.Total()-1-index);
  if (curTrend == NULL)
   Print("не нулевой индекс ",index);
  return (curTrend);
 }
 
// метод обновляет экстремум и тренд
void CTrendChannel::UploadOnEvent(string sparam,double dparam,long lparam)
 {
  CTrend *temparyTrend; 
  // догружаем экстремумы
  _container.UploadOnEvent(sparam,dparam,lparam);
  
  // если последний экстремум - нижний
  if (sparam == _eventExtrDown)
   {
     _trendNow = false;
     temparyTrend = new CTrend(_chartID, _symbol, _period,_container.GetExtrByIndex(2),_container.GetExtrByIndex(4),_container.GetExtrByIndex(1),_container.GetExtrByIndex(3),_percent );         
     if (temparyTrend != NULL)
        {
         if (temparyTrend.GetDirection() != 0)
           {
            _trendNow = true;
            _bufferTrend.Add(temparyTrend);
           }
        }     
   }
  // если последний экстремум - верхний
  if (sparam == _eventExtrUp)
   {
     _trendNow = false;
     temparyTrend = new CTrend(_chartID, _symbol, _period,_container.GetExtrByIndex(1),_container.GetExtrByIndex(3),_container.GetExtrByIndex(2),_container.GetExtrByIndex(4),_percent );
     if (temparyTrend != NULL)
        {
         if (temparyTrend.GetDirection() != 0)
           {
            _trendNow = true;
            _bufferTrend.Add(temparyTrend);
           }
        }   
   }
 }
 
// метод загружает тренды на истории
bool CTrendChannel::UploadOnHistory(void)
 { 
   int i;
   int extrTotal;
   int dirLastExtr;
   CTrend *temparyTrend; 
    // загружаем тренды 
    _container.Upload(0);
    // если удалось прогрузить все экстремумы на истории
    if (_container.isUploaded())
     {    
      extrTotal = _container.GetCountFormedExtr(); // получаем количество экстремумов
      dirLastExtr = _container.GetLastFormedExtr(EXTR_BOTH).direction; // получаем последнее значение экстремума
      // проходим по экстремумам и заполняем буфер трендов
      for (i=0;i<extrTotal-4;i++)
       {
        // если последнее направление экстремума - вверх
        if (dirLastExtr == 1)
         {
           temparyTrend = new CTrend(_chartID, _symbol, _period,_container.GetExtrByIndex(i),_container.GetExtrByIndex(i+2),_container.GetExtrByIndex(i+1),_container.GetExtrByIndex(i+3),_percent );
           if (temparyTrend != NULL)
            {
             if (temparyTrend.GetDirection() != 0)
                _bufferTrend.Add(temparyTrend);
            }
         }
        // если последнее направление экстремума - вниз
        if (dirLastExtr == -1)
         {
           temparyTrend = new CTrend(_chartID, _symbol, _period,_container.GetExtrByIndex(i+1),_container.GetExtrByIndex(i+3),_container.GetExtrByIndex(i),_container.GetExtrByIndex(i+2),_percent );         
           if (temparyTrend != NULL)
            {
             if (temparyTrend.GetDirection() != 0)
                _bufferTrend.Add(temparyTrend);
            }
         }
        dirLastExtr = -dirLastExtr; 
       }
      return (true);
     }
   return (false);
 }