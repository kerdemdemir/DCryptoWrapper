module Client.Client;

public import std.conv;
public import std.uuid;
public import std.datetime ;
public import std.stdio;
public import vibe.data.json;

struct TickData
{
    double bid  = 0.0;
    double ask  = 0.0;
    double last = 0.0;

    string ToString()
    {
    	return " Bid: " ~ to!string(bid) ~ " Ask: " ~ to!string(ask);
    }
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

struct MarketOrderBook
{
	double totalBTCBuyRange = 0.0;
	double totalBTCSellRange = 0.0;
	double totalBTCLongSellRange = 0.0;

    string ToString()
    {
    	return  " Order Book Buy Power : " ~ to!string(totalBTCBuyRange) ~ " Order Book Sell Power : " ~ to!string(totalBTCSellRange);
    }
}


interface IClient
{
	//Private calls 
	bool Buy( string name, string txname, double price, double quantity );
	bool Sell( string name, string txname, double price, double quantity, bool isLimit );
	bool Cancel( UUID uuid );
	bool GetAndCheckBalances();
	bool CheckOpenOrders();
	
	//Public calls 
	bool GetAnalyzeData();
	bool GetMarketHistory( string name, string txname, Duration duration );
	bool GetOrderBook( string name, string txname, double buyTarget, double sellTarget );
	TickData GetTickData( string name, string marketName  );
}

