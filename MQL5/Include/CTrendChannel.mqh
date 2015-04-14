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
   // приватные методы класса
   void GenUniqName (); // генерирует уникальное имя трендового канала
   bool IsItTrend (); // метод проверяет, является ли создаваемый объект трендом. 
  public:
   CTrend(CExtremum *extrUp0,CExtremum *extrUp1,CExtremum *extrDown0,CExtremum *extrDown1); // конструктор класса по экстр
  ~CTrend(); // деструктор класса
   // методы класса
   int  GetDirection () { return (_direction); }; // возвращает направление тренда 
   void ShowTrend (); // показывает тренд на графике
   void HideTrend (); // скрывает отображение тренда
   
 };

 
// кодирование методов класса трендовых каналов

/////////приватные методы класса

void CTrend::GenUniqName(void) // генерирует уникальное имя трендового канала
 {
  
 }
 
bool CTrend::IsItTrend(void) // проверяет, является ли данный канал трендовым
 {
  return (true);
 }

CTrend::CTrend(CExtremum *extrUp0,CExtremum *extrUp1,CExtremum *extrDown0,CExtremum *extrDown1)
 {
  // создаем объекты экстремумов для трендовых линий
  _extrUp0 = new CExtremum(extrUp0.direction,extrUp0.price,extrUp0.time,extrUp0.state);
  _extrUp1 = new CExtremum(extrUp1.direction,extrUp1.price,extrUp1.time,extrUp1.state);
  _extrDown0 = new CExtremum(extrDown0.direction,extrDown0.price,extrDown0.time,extrDown0.state);
  _extrDown1 = new CExtremum(extrDown1.direction,extrDown1.price,extrDown1.time,extrDown1.state);      
 }

void CTrend::ShowTrend(void) // отображает тренд на графике
 {
  //_trendLine.Create(0,"trendUp_"+_uniqName,0,extrs[2].time,extrs[2].price,extr[0].time,extrs[0].price); // верхняя  линия
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
   ENUM_TIMEFRAMES _period; // период
   CExtrContainer *_container; // контейнер экстремумов
   CArrayObj _bufferTrend;// буфер для хранения трендовых линий  
  public:
   CTrendChannel(string symbol,ENUM_TIMEFRAMES period,int handleDE); // конструктор класса
  ~CTrendChannel(); // деструктор класса
  // методы класса
  CTrend * GetTrendByIndex (int index); // возвращает указатель на тренд по индексу
 };
 
// кодирование методов класса CTrendChannel
CTrendChannel::CTrendChannel(string symbol,ENUM_TIMEFRAMES period,int handleDE)
 {
  int i;
  int extrTotal; 
  int dirLastExtr;
  _handleDE = handleDE;
  _symbol = symbol;
  _period = period;
  _container = new CExtrContainer(handleDE,symbol,period);
  // если удалось создать объект контейнера
  if (_container != NULL)
   {
    _container.Upload(0);
    // если удалось прогрузить все экстремумы на истории 
    if (_container.isUploaded())
     {    
      extrTotal = _container.GetCountFormedExtr(); // получаем количество экстремумов
      dirLastExtr = _container.GetLastFormedExtr(EXTR_BOTH).direction;
      // проходим по экстремумам и заполняем буфер трендов
      for (i=0;i<extrTotal-4;i++)
       {
      //  _bufferTrend.Add(new CTrend(_container.GetExtrByIndex(i)
       }
     }
   }
 }