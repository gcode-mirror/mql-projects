//+------------------------------------------------------------------+
//|                                                    megathron.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

//подключение необходимых библиотек


#include <SystemLib/IndicatorManager.mqh>   // библиотека по работе с индикаторами
#include <MoveContainer/CMoveContainer.mqh> // нужный(новый) контейнер движений
#include <CTrendChannel.mqh>                // старый(на удаление) трендовый контейнер
#include <Rabbit/RabbitsBrain.mqh>
#include <Hvost/HvostBrain.mqh>
#include <Chicken/ChickensBrain.mqh>
#include <RobotEvgeny/EvgenysBrain.mqh>
//#include <CExtrContainer.mgh>

//константы
#define SPREAD 30       // размер спреда 

// ---------переменные робота------------------
CExtrContainer *extr_container;
CContainerBuffers *conbuf; // буфер контейнеров на различных Тф, заполняемый на OnTick()
                           // highPrice[], lowPrice[], closePrice[] и т.д; 
                           
CRabbitsBrain  *rabbit;
CChickensBrain *chickenM5, *chickenM15, *chickenH1;
CHvostBrain    *hvostBrain;
CEvgenysBrain  *evgeny;

CTradeManager *ctm;        // торговый класс 
     
datetime history_start;    // время для получения торговой истории
int robot_signal;
int handleDE; 
int moveSELL;
int moveBUY;  
double value;  // объем позиции                        

ENUM_TM_POSITION_TYPE opBuy, opSell; // заполнить
ENUM_TIMEFRAMES TFs[7]    = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_H1};//, PERIOD_H4, PERIOD_D1, PERIOD_W1};
ENUM_TIMEFRAMES JrTFs[3]  = {PERIOD_M1, PERIOD_M5, PERIOD_M15};
ENUM_TIMEFRAMES MedTFs[2] = {PERIOD_H1, PERIOD_H4};
ENUM_TIMEFRAMES EldTFs[2] = {PERIOD_D1, PERIOD_W1};

//---------параметры позиции и трейлинга------------
SPositionInfo pos_info;
/*//---------Массивы информации о торговых движениях на каждом роботе конкретного ВИ------
SPositionInfo mass_pos_info_Old[];
SPositionInfo mass_pos_info_Mid[];
SPositionInfo mass_pos_info_Jun[]; // Если можно ставить статус позиции 0, можно избежать массив роботов на каждом ТФ*/
STrailing     trailing;
//--------------массив роботов----------------------
CArrayObj *robots_OLD;
CArrayObj *robots_MID;
CArrayObj *robots_JUN;

CBrain *robot;


// направление открытия позиции??
long magicAll[6] = {1111, 1112, 1113, 1114, 1115, 1116};


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
 Print("Инициализация началась");
 ctm = new CTradeManager();
 history_start = TimeCurrent(); // запомним время запуска эксперта для получения торговой истории

 //---------- Загружаем контейнер всех данных по цене----------------
 conbuf = new CContainerBuffers(TFs);
 for (int attempts = 0; attempts < 25; attempts++)
 {
  conbuf.Update();
  Sleep(100);
  if(conbuf.isFullAvailable())
  {
   PrintFormat("Наконец-то загрузился! attempts = %d", attempts);
   break;
  }
 }
  if(!conbuf.isFullAvailable())
   return (INIT_FAILED);
 //---------- Загружаем контейнер экстремумов для Евгения на Н4----------------
 handleDE = DoesIndicatorExist(_Symbol, PERIOD_H4, "DrawExtremums");
 if (handleDE == INVALID_HANDLE)
 {
  handleDE = iCustom(_Symbol, PERIOD_H4, "DrawExtremums");
  if (handleDE == INVALID_HANDLE)
  {
   Print("Не удалось создать хэндл индикатора DrawExtremums");
   return (INIT_FAILED);
  }
 }   
 extr_container = new CExtrContainer(handleDE,_Symbol,PERIOD_H4,1000);
 if(!extr_container.Upload()) // Если не загрузился прервем работу
  return (INIT_FAILED);
 

 //-----------Заполним массив роботов на старшем ВИ----------------
 robots_OLD = new CArrayObj();
              robots_OLD.Add(new  CEvgenysBrain(_Symbol,PERIOD_H4, extr_container, conbuf));
 //-----------Заполним массив роботов на среднем ВИ----------------
 robots_MID = new CArrayObj();
              //robots_MID.Add(new CChickensBrain(_Symbol,PERIOD_H1, conbuf));
 //-----------Заполним массив роботов на младшем ВИ----------------
 robots_JUN = new CArrayObj();
              //robots_JUN.Add(new CChickensBrain(_Symbol,PERIOD_M5, conbuf));
              //robots_JUN.Add(new CChickensBrain(_Symbol,PERIOD_M15, conbuf));
              //robots_JUN.Add(new  CRabbitsBrain(_Symbol, conbuf));
              
 pos_info.volume = 1;
 trailing.trailingType = TRAILING_TYPE_NONE;
 trailing.trailingStop = 0;
 trailing.trailingStep = 0;
 trailing.handleForTrailing = 0;
  
 moveSELL = 0;
 moveBUY = 0;
 Print("Инициализация успешно завершена");
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 delete rabbit;
 delete chickenM5;
 delete chickenM15;
 delete chickenH1;
 delete evgeny;
 
 delete conbuf;
 delete ctm;
 delete extr_container;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
 conbuf.Update();
 ctm.OnTick();   
       
 MoveDown(robots_OLD);
 MoveUp(robots_JUN);
 //PrintFormat("moveSELL = %d moveBUY %d", moveSELL, moveBUY);
 
   //Получить сигналы на старших ТФ, записать состояние в соответствующие переменные
    //
   //В соответствии со старшими сигналами, получить сигнал от роботов средних ТФ; заполнить переменные состояний
    //Будет вестись одна общая позиция или для каждого робота своя?
    //Если отдельные позиции - как разделять для кого открылась позиция на нижнем ТФ?
   //Получить сигналы на младших ТФ
   
   //Проверить тенденции на слом, начиная со старших ТФ; закрыть позиции в случае слома тенденции
   //По оставшимся позициям проверить возможность передачи на верхние ТФ
   //
   
}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
//---
   
}
//+------------------------------------------------------------------+

void MoveDown (CArrayObj *robots) // привести в соответствие направление позиции и торговые сигналы SELL и OP_SELL
{
 FillTradeInfo(robots); // заполнить информацию о торговле для ВИ
 
 // если на верхнем ВИ есть торговые сигналы
 if(moveBUY != 0||moveSELL != 0)
 {
  pos_info.volume = value;
  // для каждого робота на этом ВИ
  for(int i = 0; i < robots.Total(); i++)
  {
   robot = robots.At(i);
   // Вычислим торговый сигнал по алгоритму робота
   robot_signal = robot.GetSignal();
   // Если пришел сигнал на открытие позиции
   if(robot_signal == SELL || robot_signal == BUY)
   {
    // открыть позицию, с мэджиком этого робота по направлению SELL
     if(robot_signal == SELL && moveSELL == SELL) // если есть разрешение с верхнего ВИ на торговлю в этом направлении
      pos_info.type = OP_SELL;
     else if(robot_signal == BUY && moveBUY == BUY)
      pos_info.type = OP_BUY;
     else
      continue;
    // Если у этого робота нет открытых позиций
    if(ctm.GetPositionCount(robot.GetMagic()) <= 0)
    {
     // текущее направление робота изменится автоматически еще при getSignal()
     ctm.OpenMultiPosition(_Symbol,robot.GetPeriod(),pos_info,trailing);
    }
    // По-другому: смотри в алгоритм. Там мы оставляем позицию противоположного направления не смотря на противоречие в getSignal на ЭТОМ же роботе
    
    // Если существует открытая позиция с magicом этого робота 
    // закрываем ее ПОЛНОСТЬЮ в любом случае и открываем новую
    else 
    {
     // if (ctm.GetPositionType(_Symbol,robot.GetMagic()) != robot_signal)//но ее направление противоречит вычисленному сигналу
     // ctm.ClosePosition(robot.GetMagic());
     // ctm.OpenMultiPosition(_Symbol,robot.GetPeriod(),pos_info, trailing); + magic 
     // закрыть позицию по противоположному сигналу в стм и открыть по вычисленному, 
     // если на старшем есть разрешение на торговлю по противоположному сигналу
     // ИЛИ просто сделать ОпенЮникПозишн для робота, и стм сам будет удалять позицию если открылась новая (независимо от направления)
    }
   }
   else if (robot_signal == DISCORD)
   {
    // закрыть позицию с мэджиком этого робота
    // ctm.ClosePosition(robot.GetMagic());
   }
  }
 }
 if(robots != robots_JUN)
  MoveDown(GetNextTI(robots,true));
}

void MoveUp (CArrayObj *robots)
{
 for(int i = 0; i < robots.Total(); i++) 
 {
  robot = robots.At(i); // для каждого робота на ВИ
  // если его позиция существует и активна
  if(ctm.GetPositionCount(robot.GetMagic()) <= 0) 
  {
  }
  else
  {
   // получить направление , SL и TP позиции
   double curPrice;
   if(ctm.GetPositionType(_Symbol, robot.GetMagic()) == OP_SELL)
   {
    curPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    if(curPrice <= ctm.GetPositionTakeProfit(_Symbol, robot.GetMagic()))
    {
     // закрываем часть позиции
     // ctm.ClosePosition(robot.GetMagic(), value);
     // value = ? 
     // и добавляем оставшийся объем к роботу верхнего ТФ
     // ctm.AddPositionValue(ChooseTheBrain(OP_SELL, GetNextTI(robots, false)) value);//up
     // если никакой робот не принимает позиции по направлению и невозможно добавить объем
     // то позиция "отвисает" ее мэджик = 0;
    }
    // если позиция коснулась SL закрываем позицию полностью
    if(curPrice >= ctm.GetPositionStopLoss(_Symbol, robot.GetMagic()))
    {
     //ctm.ClosePosition(magic);
    }    
   }
   
   if(ctm.GetPositionType(_Symbol,robot.GetMagic()) == OP_BUY)
   {
    curPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    if(curPrice >= ctm.GetPositionTakeProfit(_Symbol, robot.GetMagic()))
    {
     // закрываем часть позиции
     // ctm.ClosePosition(robot.GetMagic(), value);
     // value = ? 
     // и добавляем оставшийся объем к роботу верхнего ТФ
     // ctm.AddPositionValue(ChooseTheBrain(OP_SELL, GetNextTI(robots, false)) value);//up
    }
    // если позиция коснулась SL закрываем позицию полностью
    if(curPrice <= ctm.GetPositionStopLoss(_Symbol, robot.GetMagic()))
    {
     //ctm.ClosePosition(magic);
    }    
   }
  }
 }
 if(robots!=robots_OLD)
  MoveUp(GetNextTI(robots,false));
}


CArrayObj *GetNextTI(CArrayObj *robots, bool down)
{
 CBrain *robot = robots.At(0); 
 ENUM_TIMEFRAMES period = robot.GetPeriod();

 if(period >= PERIOD_H4)
  return down ? robots_MID  :  robots_OLD;
 if(period > PERIOD_M15 && period < PERIOD_H4)
  return down ? robots_JUN  :  robots_OLD;
 if(period <= PERIOD_M15)
  return down ? robots_JUN  :  robots_MID;
  
 return robots_JUN;  
}


void FillTradeInfo(CArrayObj *robots)
{ 
 moveSELL = 0;
 moveBUY = 0;
 CBrain *robot = robots.At(0);
 if(robot.GetPeriod() > PERIOD_M15)
  value = 0.0;
 else
  value = 1.0;
 for(int i = 0; i < robots.Total(); i++)
 {
  robot = robots.At(i);
  //moveSELL = robot.GetDirection();
  if(robot.GetDirection() == 1)
   moveBUY = 1;
  else if(robot.GetDirection() == -1)
   moveSELL = -1;
 }
 return;
}

int ChooseTheBrain(int pos_type, CArrayObj *robots)
{
 double volume = 0;
 int magic = 0;   // на стм - если мэджик позиции отрицательный, удалить ее, не считать и прочее
 for(int i = 0; i < robots.Total(); i++)
 {
  robot = robots.At(i);
  magic = robot.GetMagic();
  if(ctm.GetPositionCount(magic))
  {
   if(ctm.GetPositionType(magic) == pos_type)
   {
    if(ctm.GetPositionVolume(magic) >= volume)
    {
     magic = robot.GetMagic();
     volume = ctm.GetPositionVolume(magic);
    }
   }
  }
 }
 return magic;
}

// Сравнить направление позиции с сигналом 

// Переделать таким образом, чтобы по открытой с мэджиком этого робота позиции понимать какое направление
/*
void FillTradeMoveTI(CArrayObj *robots)
{ 
 moveSELL = 0;
 moveBUY = 0;
 CBrain *robot;
 for(int i = 0; i < robots.Total(); i++)
 {
  robot = robots.At(i);
  //moveSELL = robot.GetDirection();
  if(robot.GetDirection() == 1)
   moveBUY = 1;
  else if(robot.GetDirection() == -1)
   moveSELL = -1;
 }
 return;
}*/

//ctm.ShareWithDaddy()