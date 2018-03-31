module Client.Client;

public import std.uuid : UUID;
public import std.datetime : Duration;


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

