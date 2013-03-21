//+------------------------------------------------------------------+
//|                                               BasicVariables.mq4 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
//------- Внешние параметры советника -----------------------------------------+
extern string Basic_Parameters = "Basic_Parameters";
extern int _MagicNumber = 1122;
extern int timeframe = 60;

extern double stopLoss = 400;
extern double takeProfit = 1600;

extern bool useTrailing = true;

extern double minProfit = 300; // когда профит достигает указанное количество пунктов, трейлинг начинает работу
extern double trailingStop = 300; // Величина трала
extern double trailingStep = 100; // Величина шага

// --- Параметры управления капиталом ---
extern bool uplot = true; // вкл/выкл изменение величины лота
extern int lastprofit = -1; // принимает значения -1/1. 
// -1 - увеличение лота после минусовой сделки до первой плюсовой
//  1 - увеличение лота после плюсовой сделки до первой минусовой
extern double lotmin = 0.1; // начальное значение 
//extern double lotmax = 0.5; // потолок
//extern double lotstep = 0.1; // приращение лота

// --- Параметры использования отложенных ордеров ---
extern bool useLimitOrders = false;
extern int limitPriceDifference = 20;

extern bool useStopOrders = false;
extern int stopPriceDifference = 20;

//------- Глобальные переменные советника -------------------------------------+
string _symbol = "";

bool   gbDisabled    = False;          // Флаг блокировки советника
color  clOpenBuy = Red;                // Цвет значка открытия покупки
color  clOpenSell = Green;             // Цвет значка открытия продажи
color  clCloseBuy    = Blue;           // Цвет значка закрытия покупки
color  clCloseSell   = Blue;           // Цвет значка закрытия продажи
color  clDelete      = Black;          // Цвет значка отмены отложенного ордера
int    Slippage      = 3;              // Проскальзывание цены
int    NumberOfTry   = 5;              // Количество торговых попыток
bool   UseSound      = True;           // Использовать звуковой сигнал
string NameFileSound = "expert.wav";   // Наименование звукового файла
bool Debug = false;

int total = 0;
int ticket = -1;
int _GetLastError = 0;
double lots = 0;
string openPlace;

