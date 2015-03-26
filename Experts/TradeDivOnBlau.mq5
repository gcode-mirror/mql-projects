//+------------------------------------------------------------------+
//|                                                      ONODERA.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
// подсключение библиотек 
#include <TradeManager\TradeManager.mqh>        // подключение торговой библиотеки
#include <Lib CisNewBar.mqh>                    // для проверки формирования нового бара
#include <CompareDoubles.mqh>                   // для проверки соотношения  цен
#include <Constants.mqh>                        // библиотека констант
#define ADD_TO_STOPPLOSS 50
// константы сигналов
#define BUY   1    
#define SELL -1

//+------------------------------------------------------------------+
//| Эксперт, основанный на расхождении Blau                          |
//+------------------------------------------------------------------+                                                                 
   
// входные параметры
sinput string base_param                           = "";                 // БАЗОВЫЕ ПАРАМЕТРЫ ЭКСПЕРТА
input  int    risk                                 = 1;                  // размер риска в процентах   
input  int    top_level                            = 75;                 // Top Level
input  int    bottom_level                         = 25;                 // Bottom Level
input  ENUM_MA_METHOD      ma_method               = MODE_EMA;           // тип сглаживания
input  ENUM_STO_PRICE      price_field             = STO_LOWHIGH;        // способ расчета стохастика   
input  int    q                                    = 2;                  // q - период, по которому вычисляется моментум
input  int    r                                    = 20;                 // r - период 1-й EMA, применительно к моментуму
input  int    s                                    = 1;                  // s - период 2-й EMA, применительно к результату первого сглаживания
input  int    u                                    = 1;                  // u - период 3-й EMA, применительно к результату второго сглаживания
// объекты
CTradeManager    *ctm;                                                   // указатель на объект торговой библиотеки
static CisNewBar *isNewBar;                                              // для проверки формирования нового бара
// хэндлы индикаторов 
int handleSmydBlau;                                                      // хэндл индикатора smydBlau
int handleStoc;                                                          // хэндл Стохастика
int handle19Lines;                                                       // хэндл NineTeenLines
// параметры позиции
SPositionInfo pos_info;                                                  // информация о позиции
STrailing     trailing;                                                  // информация о трейлинге
// переменные эксперта 
double lastRightExtr=0;                                                  // значение последней даты правого экстремума расхождения
double riskSize;                                                         // размер риска
// буферы 
double signalBuffer[];                                                   // буфер для получения сигнала из индикатора smydBlau
double dateRightExtr[];                                                  // буфер для получения времени прихода правого экстремума расхождения
double stoc[];                                                           // буфер Стохастика
double levelPrices[10];                                                  // буфер цен уровней
int OnInit()
{
 // выделяем память под объект тороговой библиотеки
 isNewBar = new CisNewBar(_Symbol, _Period);
 ctm = new CTradeManager(); 
  
 // создаем хэндл индикатора smyBlau
 handleSmydBlau = iCustom (_Symbol,_Period,"smydBLAU","",q,r,s,u);   
 if ( handleSmydBlau == INVALID_HANDLE )
 {
  Print("Ошибка при инициализации эксперта TradeDivOnBlau. Не удалось создать хэндл smydBlau");
  return(INIT_FAILED);
 }     
 // создаем хэндл индикатора Стохастика
 handleStoc = iStochastic(_Symbol,_Period,5,3,3,ma_method,price_field);
 if ( handleStoc == INVALID_HANDLE)
 {
  Print("Ошибка при инициализации эксперта TradeDivOnBlau. Не удалось создать хэндл Стохастика"); 
  return(INIT_FAILED);
 }
 // создаем хэндл идникатора NineTeenLines
 handle19Lines = iCustom(_Symbol,_Period,"NineteenLines");       
 if (handle19Lines == INVALID_HANDLE)
  {
   Print("Не удалось получить хэндл NineteenLines");
   return(INIT_FAILED);    
  }
 pos_info.tp = 0;
 //pos_info.volume = lot;
 pos_info.expiration = 0;
 pos_info.priceDifference = 0; 
 pos_info.sl = 0;
 pos_info.tp = 0; 
 
 trailing.trailingType = TRAILING_TYPE_NONE;
 trailing.trailingStop = 0;
 trailing.trailingStep = 0;
 trailing.handleForTrailing = 0;
 
 // вычисляем значение риска
 riskSize = risk/100.0;
 
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 // удаляем объект класса TradeManager
 delete isNewBar;
 delete ctm;
 // удаляем индикатор 
 IndicatorRelease(handleSmydBlau);
}

void OnTick()
{
 ctm.OnTick();
 // если сформирован новый бар
   if (CopyBuffer(handleSmydBlau,1,0,1,signalBuffer) < 1 || CopyBuffer(handleSmydBlau,3,0,1,dateRightExtr) < 1 || CopyBuffer(handleStoc,0,0,1,stoc) < 1 )
    {
     PrintFormat("Не удалось прогрузить все буферы Error=%d",GetLastError());
     return;
    }   
  
   if ( signalBuffer[0] == BUY)  // получили расхождение на покупку
     { 
      // если последний полученный сигнал не равен предыдущему
      if ( !EqualDoubles( lastRightExtr,dateRightExtr[0]) && stoc[0] < bottom_level ) 
       {     
          // то открываем позицию на BUY
          pos_info.type = OP_BUY;
          // задаем стоп лосс
          pos_info.sl  =  CountStopLoss(1,SymbolInfoDouble(_Symbol,SYMBOL_BID));
          // вычисляем размер лота
          pos_info.volume = CountLotByStopLoss(SymbolInfoDouble(_Symbol,SYMBOL_BID),pos_info.sl);
          if (pos_info.volume!=0)
           ctm.OpenUniquePosition(_Symbol,_Period, pos_info, trailing);                  
        }
       // сохраняем последний сигнал
       lastRightExtr = dateRightExtr[0];
     }
   if ( signalBuffer[0] == SELL) // получили расхождение на продажу
     { 
      // если последний полученный сигнал не равен предыдущему
      if ( !EqualDoubles( lastRightExtr,dateRightExtr[0]) && stoc[0] > top_level )
       {
          // то открываем позицию на SELL
          pos_info.type = OP_SELL;
          // задаем стоп лосс
          pos_info.sl = CountStopLoss(-1,SymbolInfoDouble(_Symbol,SYMBOL_ASK));
          // вычисляем размер лота
          pos_info.volume = CountLotByStopLoss(SymbolInfoDouble(_Symbol,SYMBOL_ASK),pos_info.sl);
          if (pos_info.volume!=0)
           ctm.OpenUniquePosition(_Symbol,_Period, pos_info, trailing);                   
       }
      //сохраняем последний правый экстремум расхождения
      lastRightExtr = dateRightExtr[0]; 
     }
}

// получает последние значения уровней
bool UploadBuffers ()   
 {
  int copiedPrice;
  int indexPer;
  int indexBuff;
  int indexLines = 0;
  double tmpLevelBuff[];
  for (indexPer=0;indexPer<5;indexPer++)
   {
    for (indexBuff=0;indexBuff<2;indexBuff++)
     {
      copiedPrice = CopyBuffer(handle19Lines,indexPer*8+indexBuff*2+4,  0,1, tmpLevelBuff);
      if (copiedPrice < 1)
       {
        Print("Не удалось прогрузить буферы индикатора NineTeenLines");
        return (false);
       }
      levelPrices[indexLines] = tmpLevelBuff[0];
      indexLines++;
     }
   }
  return(true);     
 }

// возвращает стоп лосс по уровням NineTeenLines
int   CountStopLoss (int dealType, double currentPrice)
 {
  double closestLevel=0;  // цена ближайшего уровня
  int ind;                // для прохода по циклам
  int stopLoss;           // стоп лосс в пунктах
  // загружаем буферы уровней
  if (!UploadBuffers())
   return (0);
    // проходим по циклу и вычисляем ближайшую цену уровня снизу
    for (ind=0;ind < 10; ind++)
     {
      // если позиция открыта на Buy, цена уровня ниже цены открытия позиции , но она ближе к цене позиции
      if (dealType == 1 && LessDoubles(levelPrices[ind],currentPrice) && GreatDoubles(levelPrices[ind],closestLevel)  )
       {
        // то сохраняем цену ближайшего уровня
        closestLevel = levelPrices[ind]; 
       }
      // если позиция открыта на Sell, цена уровня выше цены открытия позиции , но она ближе к цене позиции
      if (dealType == -1 && GreatDoubles(levelPrices[ind],currentPrice) && (LessDoubles(levelPrices[ind],closestLevel)||closestLevel==0) )
       {   
        // то сохраняем цену ближайшего уровня
        closestLevel = levelPrices[ind];
       }       
     } 
  // вычисляем размер стопа
  stopLoss = int( MathAbs(currentPrice-closestLevel)/_Point );
  // если stopLoss оказался меньше 100 пунктов, то выставляем его в размере 100 пунктов
  if (stopLoss < 100)
   stopLoss = 100; 
  // возвращаем стоп лосс в пунктах
  return (stopLoss);
 }
 
// функция вычисляет размер лота в зависимоти от стоп лосса 
double  CountLotByStopLoss (double posOpenPrice,int stopLoss)
 {
  double balancePart;
  double Sp;
  double percentLot;
  // вычисляем процент риска от текущего баланса, которым мы можем потерять
  balancePart = AccountInfoDouble(ACCOUNT_BALANCE)*riskSize;
  Sp = stopLoss*SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE_PROFIT);
  //SymbolInfoInteger(_Symbol,
  percentLot = NormalizeDouble(balancePart / Sp, 2);
 // PrintFormat("Размер лота = %.02f, процент баланса = %.05f, стоимость стопа = %.05f, стоимость тика = %.05f ",percentLot, balancePart , Sp, SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE_PROFIT)  );
  //Comment("Текущий счёт = ",DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE) ) );  
  return (percentLot);
 }