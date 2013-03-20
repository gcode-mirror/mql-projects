//+------------------------------------------------------------------+
//|                                          DesepticonVariables.mq4 |
//|                                            Copyright © 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, GIA"
#property link      "http://www.saita.net"

//------- Внешние параметры советника -----------------------------------------+
extern string Desepticon_Parameters = "Desepticon_Parameters";

// Описание глобальных переменных
extern bool useLowTF_EMA_Exit = false; // вкл/выкл выхода по пересечению младших EMA
extern bool useTimeExit = false; // вкл/выкл выхода по времени без прибыли
extern int waitForMove = 6;
extern int minimumProfitLvl = 80;
// Параметры индикаторов
// EMA
extern int jr_EMA1 = 12;
extern int jr_EMA2 = 26;
extern int eld_EMA1 = 12;
extern int eld_EMA2 = 26;
extern int deltaEMAtoEMA = 5;
extern int deltaPriceToEMA = 5;

// MACD
extern double MACD_channel = 0.02;
extern int jrFastMACDPeriod = 12;
extern int jrSlowMACDPeriod = 26;
extern int eldFastMACDPeriod = 12;
extern int eldSlowMACDPeriod = 26;

extern double differenceMACD = 0.0001;

// Глобальные переменные
int startTF = 1, finishTF = 2;

int trendDirection[3][2]; // [][0] - может быть ноль. 0 - значит флэт; [][1] - не может быть 0 - помним предыдущий тренд
double Current_fastEMA, Current_slowEMA;
double CurrentMACD;

///////////////
double minMACD[2][2]; //[0] - значение, [1] - номер бара
double maxMACD[2][2]; //[0] - значение, [1] - номер бара

bool isMinProfit;
int barNumber;
int wantToOpen[3][2];
int buyCondition, sellCondition;
int barsCountToBreak[3][2];
int breakForMACD = 4;
int breakForStochastic = 2;

int frameIndex = 1;
bool MACD_up, MACD_down;

double aTimeframe[3][11]; //

int jr_Timeframe, elder_Timeframe;
double jr_MACD_channel, elder_MACD_channel;

static bool _isTradeAllow = true;

double aDivergence[3][60][5]; // [][0] - резерв
                           // [][1] - знач-е MACD
                           // [][2] - знач-е цены в экстремуме MACD
                           // [][3] - номер бара
                           // [][4] - знак +/-                          