module Currencies.Currency;

public import Values.Values;
public import Rules.Rules;
public import vibe.data.json;	
public import std.math;
public import std.datetime ;
public import std.conv ;
public import std.uuid;
public import Conf.Conf;
public import std.string;
public import std.stdio ;
public import std.array;


struct TickData
{
    double bid  = 0.0;
    double ask  = 0.0;
    double last = 0.0;
    
    bool IsValid()
    {
    	return IsDoubleSane(bid) && IsDoubleSane(ask);
    }
    
    string ToString()
    {
    	return " Bid: " ~ to!string(bid) ~ " Ask: " ~ to!string(ask);
    }
}

enum PriorityEnum : string
{
	NO_PRIORITY = "No priority",
	MAYBE_PRIORITY = "Maybe priority",
	BUY_PRIORITY = "Buy priority",
}

struct MarketHistoryData
{
	double totalBTC = 0.0;
	double transactionCount = 0.0;
	double buyCount = 0.0;
	double totalBuyInBTC = 0.0;
	
    string ToString()
    {
    	return  " Total BTC traded : " ~ to!string(totalBTC) ~ " Total Buys BTC: " ~ to!string(totalBuyInBTC) ~ " Transacrion count: " ~  to!string(transactionCount) ~ " Buy count: " ~ to!string(buyCount) ;
    }
}

struct MarketOrderBook
{
	double totalBTCBuyRange = 0.0;
	double totalBTCSellRange = 0.0;
	double totalBTCLongSellRange = 0.0;
//	double smallTotalBTCBuyRange = 0.0;
//	double smallTotalBTCSellRange = 0.0;
//	
//	double midTotalBTCBuyRange = 0.0;
//	double midTotalBTCSellRange = 0.0;
	
	string ToCSV()
	{
		return  to!string(totalBTCBuyRange) ~ "," ~ to!string(totalBTCSellRange);
	}
	
    string ToString()
    {
    	return  " Order Book Buy Power : " ~ to!string(totalBTCBuyRange) ~ " Order Book Sell Power : " ~ to!string(totalBTCSellRange);
//    	~ 
//    	        " Small Order Book Buy Power : " ~ to!string(smallTotalBTCBuyRange) ~ " Small Order Book Sell Power : " ~ to!string(smallTotalBTCSellRange) ~ 
//    	        " Mid Book Buy Power : " ~ to!string(midTotalBTCBuyRange) ~ " Mid Book Sell Power : " ~ to!string(midTotalBTCSellRange);
    }
}

struct TimeData
{
	SysTime buyStartTime;
	SysTime buyOrderTime;
	SysTime buyMaybeTime;

    string ToString()
    {
    	return  " Time Dif: " ~  (buyOrderTime - buyStartTime).toString() ~ " Time Dif Maybe: "~ (buyOrderTime - buyMaybeTime).toString();
    }	
}

struct AnalyzeData
{
	string recieverName;
	string txName;
	TickData tickData;	
	TickData prevTickData;
	double count = 0.0; 
	double minBid  = 0.0;
	double minGlobalBid = double.max;
	ulong     riseTimeInSeconds = 0;
	double maxBid  = 0.0;
	double prevMaxBid  = 0.0;
	double volume = 0.0;
	MarketHistoryData historyData;
	MarketOrderBook   orderBookData;
	
	void SetMaxBid( double newVal )
	{
		newVal < 0.00000001  ? prevMaxBid = 0 : prevMaxBid = maxBid;
		maxBid = newVal;
	}
	
	string GetMarketName()
	{
		return txName ~ "-" ~ recieverName;
	}
	
	string GetSymbolName()
	{
		return recieverName~txName;
	}
	
	
    string ToString()
    {
    	return " " ~ tickData.ToString() ~ " Streght: " ~ to!string(count) ~ " MaxBid: " ~  to!string(maxBid) 
    	       ~ " \n History Data: " ~ historyData.ToString() ~ " \n Order Book " ~ orderBookData.ToString();
    }
}

struct FinalizeData
{
	bool isBuying = false;
	bool isSelling = false;
	double buyPrice = 0.0;
	double sellPrice = 0.0;
	double factor = 0.0;
	double    sellCountDown = 5.0;
	
	string ToString()
    {
    	return " IsBuying: " ~ to!string(isBuying) ~ " IsSelling: " ~ to!string(isSelling) ~ " BuyPrice: " ~ to!string(buyPrice) ~ " SellCountDown: " ~ to!string(sellCountDown) ;
    }
}

struct QuantityData
{
	double quantityOwned     = 0.0;
	double quantityAvaliable     = 0.0;
	double quantityAvaliableInBTC     = 0.0;
	double quantityOwnedInBTC     = 0.0;

	UUID   sellOrderID;
	UUID   buyOrderID;
	SysTime buyOrderTime;
	SysTime sellOrderTime;
	
	bool IsExists()
	{
		return quantityAvaliableInBTC > 0.00091;
	}
	
	bool IsOwnedExists()
	{
		return quantityOwnedInBTC > 0.00091;
	}
	
	string ToString()
    {
    	return " Owned " ~ to!string(quantityOwned) ~ "Avaliable: " ~ to!string(quantityAvaliable);	
	}
}


interface ICurrency
{
	AnalyzeData*  GetAnalyzeData( );
	FinalizeData* GetFinalizeData( );
	QuantityData* GetQuantityData( );
	TimeData*     GetTimeData();
	IRules*       GetRules();
	ref PriorityEnum  GetPriority();

	string        GetName() const;
	void		  UpdateTick( ref const TickData data);
	string        ToString();
	string        GetLog();
	string        GetLastLog();
	void          SetBuyData();
	ref Json          GetBuyData();
	ref Json          GetLastData();
	ref Json          GetMaxData();
	ref Json          GetMinData();
	void SetCurrency(  string nameParam, string longNameParam, RuleEnum[] ruleList  );

	final int opCmp(ref const ICurrency c2) const  {
	     if(GetName() < c2.GetName())
	       return -1;
	     if(GetName() > c2.GetName())
	       return 1;
	     return 0;
    }


	final bool opEquals(ref const ICurrency c2) { 
		return GetName() == c2.GetName();
	 }    
}

