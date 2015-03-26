//+------------------------------------------------------------------+
//|                                            ExtrMACDContainer.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <CompareDoubles.mqh>     // для сравнения вещественных переменных
#include <Constants.mqh>          // подключаем библиотеку констант
#include <CLog.mqh>               // log_file.Write(LOG_DEBUG, StringFormat("%s Не удалось удалить rescue-файл: %s", MakeFunctionPrefix(__FUNCTION__), rescueDataFileName)); 
#include <Arrays/ArrayObj.mqh>
#include <Divergence/CExtremumMACD.mqh>


#define DEPTH_MACD 120                                       // Количество баров на рассматриваемом участке
#define BORDER_DEPTH_MACD 15                                 //
#define REMAINS_MACD (DEPTH_MACD-BORDER_DEPTH_MACD)          //

//+----------------------------------------------------------------------------------------------+
//|            Класс CExtrMACDContainer предназначен для хранения и вычисления экстремумов MACD  |
//                                                          на определенном участке DEPTH_MACD.  |
//+----------------------------------------------------------------------------------------------+
class CExtrMACDContainer
{
private: 
 CArrayObj extremums;                        // массив экстремумов MACD
 double valueMACDbuffer[DEPTH_MACD];         // массив значений MACD на участке DEPTH_MACD
 datetime date_buf[DEPTH_MACD];
 bool _flagFillSucceed;                      // флаг учпешного заполенния контейнера
 int _handle;
 string _symbol;
 ENUM_TIMEFRAMES _period;
 
public: 
 
 CExtrMACDContainer();
 ~CExtrMACDContainer();
 CExtrMACDContainer(string symbol, ENUM_TIMEFRAMES period, int handleMACD, int startIndex);  //Начальная позиция - startIndex, 
                                                               //смещение  - DEPTH, Handle
  
 //---------------Методы для работы с классом-------------------
 int isMACDExtremum(int startIndex);                         // находит есть ли экстремумы на данном бар
 void FilltheExtremums(int startIndex);                      // заполняет контейнер                                    
    //--------------Необходимые методы-----------------------------------------------
 CExtremumMACD *getExtr(int i);                              // возвращает i-ый элемент массива
 bool RecountExtremum(int startIndex, bool fill = false);    // обновиляет массив экстремумов
 CExtremumMACD *maxExtr();                                   // возвращает экстремум MACD с максимальным значением
 CExtremumMACD *minExtr();                                   // возвращает экстремум MACD с минимальным  значением
 int getCount();
 //void maxExtr(int indexStart, int indexFinish, CExtremumMACD &extr);                               //Возвращает максимальный верхний экстремум
 //void minExtr(int indexStart, int indexFinish, CExtremumMACD &extr);                               //Возвращает минимальный нижний экстремум
};  
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CExtrMACDContainer::CExtrMACDContainer(string symbol, ENUM_TIMEFRAMES period, int handle, int startIndex)    //Передается нулевой индекс, слева
{
 _symbol = symbol;
 _period = period;
 _handle = handle;
 FilltheExtremums(startIndex);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CExtrMACDContainer::~CExtrMACDContainer()
{
}
  
//+------------------------------------------------------------------+
//                                                                   |
//            FilltheExtremums заполняет контейнер экстремумами MACD |
//                           начиная с startIndex на глубину _depth. |
//+------------------------------------------------------------------+

void CExtrMACDContainer::FilltheExtremums(int startIndex)
{
 int copiedMACD = 0;
 int copiedDate = 0;
 extremums.Clear();
 Print(__FUNCTION__," was here");
 //----------Копирование значений MACD в буфер valueMACDbuffer-------
 for(int attemps = 0; attemps < 25 && copiedMACD <= 0; attemps++)
 {
  copiedMACD = CopyBuffer(_handle, 0, startIndex , DEPTH_MACD, valueMACDbuffer);
  copiedDate = CopyTime(_symbol, _period, startIndex, DEPTH_MACD, date_buf); 
  Sleep(100);
 }
 
 if(copiedMACD != DEPTH_MACD || copiedDate != DEPTH_MACD)
 {
  int err = GetLastError();
  Print(__FUNCTION__, " Не удалось скопировать буффер полностью. /. Error = ", err);
  _flagFillSucceed = false;
  return;
 }
 //-----------------------Заполнение контейнера---------------------
 int indexForExtremum = startIndex;                       
 int extremRslt = 0;
 int i, j = 2 , ind = DEPTH_MACD - 2;
 for(i = 0; indexForExtremum - startIndex  <= DEPTH_MACD - 4 ; indexForExtremum++) //от 0ого до 126ого
 {
  extremRslt = isMACDExtremum(indexForExtremum);  // проверка на экстремум MACD
  if(extremRslt != 0)                             // если текущий элемент экстремум 
  {
   //Print("value = ",valueMACDbuffer[ind] , " index = ",j, " time = ",date_buf[ind], " i  ",i ,"date_buf", date_buf[0]);
   CExtremumMACD *new_extr = new CExtremumMACD(); // новый экстремум 
   new_extr.direction = extremRslt;               // запомнить направление
   new_extr.index = j;                            // запомнить индекс относитьельно _depth (т.е текущий элемент - [0 + 2])
   new_extr.value = valueMACDbuffer[ind];         // значение экстремума
   new_extr.time = date_buf[ind];
   extremums.Add(new_extr);                       // добавление экстремума в массив 
   i++;
  }
  j++; 
  ind--;
 }
 _flagFillSucceed = true; 
 return;
} 
//+-------------------------------------------------------------------------------+
//                                                                                |
//            RecountExtremum целесообразно вызывать при поступлении нового бара, | 
//                                             а также при заполнении контейнера. |
//                        Таким образом, RecountExtremum работает в двух режимах: |
//                        в зависимости от флага fill может запустить заполнение, |
//        а может пересчитать индексы экстремумов MACD и добавить новый в начало. |
//+-------------------------------------------------------------------------------+

bool CExtrMACDContainer::RecountExtremum(int startIndex, bool fill = false)
{
 if(!_flagFillSucceed || fill)       
 {
  FilltheExtremums(startIndex);
  return (_flagFillSucceed);
 }
 
 CExtremumMACD *new_extr = new CExtremumMACD(0, -1, 0.0, 0);         // временная переменная в которую isMACDExtremum 
                                                                   // запишет текущий экстремум (если он есть)
                                                                   
 //--------Копирование значения предполагаемого экстремума------------
 double buf_Value[1];                                       
 int copiedMACD = 0; 
 int copiedDate = 0; 
 for(int attemps = 0; attemps < 25 && copiedMACD <= 0; attemps++)
 {
  copiedMACD = CopyBuffer(_handle, 0, startIndex + 1, 1, buf_Value);   
  copiedDate = CopyTime(_symbol, _period, startIndex + 1, 1, date_buf); 
  Sleep(100);                   
 }
 if(copiedMACD != 1 || copiedDate != 1)                   
 {
  int err = GetLastError();
  Print(__FUNCTION__, "Не удалось обновить последний элемент. Error = ", err);
  return(false);
 }
 
 //-------------------Обновление индексов--------------------------
 CExtremumMACD *tmp;  
 for(int i = extremums.Total() - 1; i >= 0; i--)
 {
  tmp = extremums.At(i);
  tmp.index++;
  if(tmp.index >= DEPTH_MACD)   
  {
   extremums.Delete(i);
  }
 } 
 //-------Добавление экстремума MACD в начало массива------------
 int is_extr_exist = isMACDExtremum(startIndex); 
 if (is_extr_exist != 0)
 { 
  new_extr.direction = is_extr_exist;
  new_extr.index = 2;    
  new_extr.value = buf_Value[0];
  new_extr.time  = date_buf[0];
  extremums.Insert(new_extr, 0);             
 }   
 return(true);
}            


//+------------------------------------------------------------------+
//|    getCount() - возвращает количесвто экстремумов MACD в массиве |
//+------------------------------------------------------------------+
int CExtrMACDContainer::getCount()
{
 return (extremums.Total());
}

CExtremumMACD *CExtrMACDContainer::getExtr(int i)
{
 return extremums.At(i);
}

//+------------------------------------------------------------------+
//|         maxExtr() - возвращает максимальный экстремум в массиве |
//+------------------------------------------------------------------+
CExtremumMACD *CExtrMACDContainer::maxExtr()   //--- ArrayMaximum(extrems,0,whole_array)
{
 CExtremumMACD *temp_Extr = new CExtremumMACD(0, -1, 0, 0);
 int indexMax = 0;
 if(_flagFillSucceed && extremums.Total() > 0)
 {
  int j = 0; 
  double extrMax = -1;
  for(int i = 0; i < extremums.Total(); i++)
  {
   temp_Extr = extremums.At(i);
   if(temp_Extr.direction == 1)
   {
    if(extrMax < temp_Extr.value)
    {
     extrMax = temp_Extr.value;
     indexMax = i;
    }
   }
  }
  return extremums.At(indexMax);
 }
 return temp_Extr;  
}


//+------------------------------------------------------------------+
//|           minExtr() - возвращает минимальный экстремум в массиве |
//+------------------------------------------------------------------+
CExtremumMACD *CExtrMACDContainer::minExtr()  
{
 CExtremumMACD *temp_Extr = new CExtremumMACD(0, -1, 0, 0);
 int indexMin = 0;
 if(_flagFillSucceed && extremums.Total() > 0)
 {
  int j = 0; 
  double extrMin = 1;
  for(int i = 0; i < extremums.Total(); i++)
  {
   temp_Extr = extremums.At(i);
   if(temp_Extr.direction == -1)
   {
    if(extrMin > temp_Extr.value)
    {
     extrMin = temp_Extr.value;
     indexMin = i;
    }
   }
  }
  return extremums.At(indexMin);
 }
 return temp_Extr;  
}

//+------------------------------------------------------------------+
//             isMACDExtremum - проверяет наличие  экстремума MACD.  | 
//                           Возвращает 1/-1 если эестремум найден   |
//                                            в противном случае 0.  |
//+------------------------------------------------------------------+
int CExtrMACDContainer::isMACDExtremum(int startIndex)
{
 double iMACD_buf[4];
 int copied = 0;
 for(int attemps = 0; attemps < 25 && copied <= 0; attemps++)
 {
  copied = CopyBuffer(_handle, 0, startIndex, 4, iMACD_buf);
  Sleep(100);
 }
 if(copied != 4)
 {
  int err = GetLastError();
  Print(__FUNCTION__, "Не удалось скопировать буффер полностью.", copied, "/4. Error = ", err);
  return(0);
 }

   if ( GreatDoubles(iMACD_buf[2], iMACD_buf[0]) && GreatDoubles(iMACD_buf[2], iMACD_buf[1]) &&
         GreatDoubles(iMACD_buf[2], iMACD_buf[3]) && iMACD_buf[2] > 0)
   {
      return(1);   
   }
   else if ( LessDoubles(iMACD_buf[2], iMACD_buf[0]) && LessDoubles(iMACD_buf[2], iMACD_buf[1]) && 
           LessDoubles(iMACD_buf[2], iMACD_buf[3]) && iMACD_buf[2] < 0) 
   {
      return(-1);     
   }
 return(0);
}
