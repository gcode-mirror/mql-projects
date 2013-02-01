//+------------------------------------------------------------------+
//|                                                   VOM_manual.mqh |
//|                                     Copyright Paul Hampton-Smith |
//|                            http://paulsfxrandomwalk.blogspot.com |
//+------------------------------------------------------------------+

/** \mainpage Virtual Order Manager guide

<b> 1. Introduction </b> \n
Arguably the biggest change in the transition from MetaTrader 4 to MetaTrader 5 is the management of 
open trades as \e positions. At any one time there can be one position only open for each currency pair, 
and the size of this position adjusts up and down each time orders are processed by the broker. 
Apart from anything else, this aligns with the NFA 2-43(b) FIFO rule introduced in the US which 
effectively outlaws hedging.\n

The most startling example of the difference would be when two EAs running against the same pair issue 
orders in opposite directions.  This can be a common situation with two EAs working in different 
timeframes, such as a scalper and a trend-follower.  In MT4, the open trade list would show buy and 
sell orders with zero margin used. In MT5, no position would be open at all.\n

So the MetaTrader 5 position-centric environment presents unfamiliar challenges for the MQL5 programmer
used to the order processing approach used in MetaTrader 4, and the Virtual Order Manager is one way that 
this situation can be managed effectively.\n\n

<b> 2. Installing the Virtual Order Manager </b> \n
The VOM comes as a number of .mqh files which should be installed in Experts\\Virtual Order Manager,
listed as follows:
- ChartObjectsTradeLines.mqh - CEntryPriceLine, CStopLossLine, CTakeProfitLine
- StringUtilities.mqh - global enum descriptors such as ErrorDescription()
- Log.mqh - CLog
- SimpleChartObject.mqh - CButton, CLabel and CEdit
- VirtualOrder.mqh - CVirtualOrder
- GlobalVariable.mqh - CGlobalVariable
- VirtualOrderArray.mqh - CVirtualOrderArray
- VirtualOrderManager.mqh - CVirtualOrderManager
- VirtualOrderManagerConfig.mqh - CConfig
- VirtualOrderManagerEnums.mqh - the various enums defined for the VOM
- VOM_manual.mqh - this page of the manual

Four EA mq5 files are also included under Experts\\Virtual Order Manager\\VOM EAs:
- VOM_template_EA.mq5 - clone this to make your own EAs, and store them in Experts\\Virtual Order Manager
- VirtualOrderManagerTester.mq5
- Support_Resistance_EA_VOM.mq5
- FrAMA_Cross_EA_VOM.mq5

This manual
- VOM help.chm

<b> 3. Using the Virtual Order Manager in an Expert Advisor </b>\n
The VOM is an MQL5 class with a number of MQL4-like member functions to enable virtual trades to be issued 
and monitored by an Expert Advisor.\n
Several different EAs can each use the VOM, as shown in figure 1.
\image html Slide1.bmp "Figure 1: multiple use of the Virtual Order Manager"
\n
The linkage from each EA to the VOM is shown in figure 2.
\image html Slide2.bmp "Figure 2: EA linkage to the Virtual Order Manager"
\n
<b> Items in figure 2 explained </b>\n\n
- \code #include "VirtualOrderManager.mqh" \endcode \n
This provides the EA with access to the VOM functions and declares the global object 
CVirtualOrderManager VOM;\n\n
- OnInit()\n
Each EA uses this function to perform initilisation during EA load. 
The following code needs to be added to each EA's OnInit() to ensure that the VOM is also initialised.
\code
// EA code
void OnInit()\n
{
	// The System ID or Magic Number is calculated from the EA name
	VOM.Initialise();
	//
	// continue with other initialisation of this EA
	// ....
}
\endcode \n\n

- OnTick()\n
This is the MQL5 equivalent of start() in MQL4.
The following code needs to be added to each EA's OnTick() to let the VOM
know that a new tick has been received.
\code
// EA code
void OnTick()
{
	// action virtual stoplosses, takeprofits and pending orders
	VOM.OnTick();
	// Display virtual order status
   Comment(VOM.m_OpenOrders.SummaryList());
	//
	// continue with other tick event handling in this EA
	// ....
}
\endcode \n\n
- <b>Virtual trade functions </b> \n
These functions have many similarities with the trade functions in MQL4.\n
Where in MQL4 an order send might look like this
\code OrderSend(symbol,type,volume,price,slippage,sl,tp,"comment",0); \endcode
Using the VOM an order send looks like this
\code VOM.OrderSend(symbol,type,volume,price,slippage,sl,tp,"comment",0); \endcode \n
Follow the CVirtualOrderManager link to view the class reference for all member functions.\n\n

<b> 4. Virtual Order Manager structure </b> \n
Shown in figure 3 are the most important elements surrounding the VOM.
\image html Slide3.bmp "Figure 3: VOM environment"
- \b Configuration - the VOM uses CConfig to store all the main configuration items in one place in a global 
object Config. To make access simple the member variables are public and no get/set 
functions are provided.\n
- <b> Global variables </b> - these are the variables accessed in MQL5 by functions such as GlobalVariableGet(). 
The VOM uses the global variable functionality in CGlobalVariable to record and increment the last Virtual Order Ticket number.
- <b> Open trades and history files </b> - these are the permanent disk files for CVirtualOrderArrays used to ensure that 
order status can be re-established on restart.  A pair of these files is created and stored in Files\\VOM for each EA that 
uses the VOM.  A CVirtualOrder starts life in the VOM.m_OpenOrders array, and is transferred to the VOM.m_OrderHistory 
array when closed or deleted.\n
- <b> Activity and debug log </b> - most code of any complexity needs the ability to log activity, and this function is encapsulated by the 
CLog class. This enables logging to occur at four different levels of importance, and includes 
automatic cleanup of old log files to ensure that diskspace is managed.\n\n

<b> 5. Testing the Virtual Order Manager </b> \n
A project of this size takes time to test thoroughly, so I wrote the EA VirtualOrderManagerTester.mq5 to 
enable virtual orders to be created, modifed, deleted and closed easily with command buttons on the chart.
Figure 4 shows a virtual buy order at 0.1 lot and a virtual sell order of 0.3 lot open against EURUSD 
(see comment line), with the server status correctly showing one position at 0.2 lots sold. Because 
the overall position is short, the server stoploss is determined from the tightest virtual sell order 
stoploss plus a configurable margin above of 50.0 pips. This server stop is intended as a disaster stop 
in the event of PC or internet link failure and under normal conditions the tighter virtual stop will cause 
the trade to exit.\n
\image html VOM1.GIF "Figure 4: VOM testing"

<b> 6. Running real EAs on the Virtual Order Manager </b> \n
The real purpose if the VOM is to run a number of EAs at once on the one account, and as an example
I have re-written the following two EAs to use the VOM:\n
- A swing trader EA, which enters on reversal of price at support and resistance lines.\n
- A Fractal Adaptive Moving Average (FrAMA) Cross EA on daily charts.\n

<b> 7. Further improvements to the VOM </b> \n
At the time of writing this article, the VOM code is in Beta, just like MetaTrader 5 itself, and 
time will tell if the VOM concept becomes popular or ends up being regarded as just an interesting 
piece of MQL5 programming.\n
A number of changes may be needed or desirable over time, and will certainly be implemented if 
the MQL5 community shows an interest:\n
- As with any software development in its early stages of development, it is likely that there are bugs in the code. 
- Robustness will need attention to properly handle unusual events such as shutting down MetaTrader 5
before a trade has managed to complete, or trading during the extreme volatility of a major forex 
news event.\n
- With each MetaTrader 5 Beta build release there may be required VOM changes to maintain compatibility.\n
- The documentation is not yet very comprehensive and could be expanded. \n 
- The following could be added to the VOM at some stage:\n
	- GetLastError() and ErrorDescription() functions
	- Display of open orders and order history using an indicator
	- Ability to read configuration from a file
	- Trailing stops of various types
	- Compatibility with the MetaTrader 5 Strategy Tester when it is released
	
\n\n\n
<b> Change list </b> \n
- V0.1 Initial release
- V0.2 Added Section 2 to the manual. Added VOM_template_EA.mq5 to the distribution
- V0.3 7/2/10
	- Each VOM instance now stores an individual pair of open and closed order files under Files\\VOM
	- Monitoring handles to determine if the open and closed order files can be accessed
	- Added simple trade functions CVirtualOrderManager::Buy, CVirtualOrderManager::Sell 
	  and CVirtualOrderManager::NewBar()
- V0.4 9/2/10
	- Included symbol name and period in the open and closed order filenames
	- Updated Magic Number generator
	- Fixed error in CLog which posted CLog::Log as the originating function
	- Included up to 10 optional string inputs to CLog::Log
- V0.5 14/2/10
	- fixed order errors caused by conversion of ulong magic to int
	- general audit of type integrity through function calls
- V0.6 29/3/10
   - fixed error in reading virtual order open time from file
   - extended file record of orders to include close price and time
- V2.0 13/1/12
   - a significant number of bugfixes and some additional utility functions
	

















*/