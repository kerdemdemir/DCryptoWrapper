module Client.ClientWrapper.ClientWrapper;

public import Utility.DataProxy;
public import std.datetime : Duration;
public import std.uuid;

interface ClientWrapper
{
	bool Buy( string name, string txname, double price, double quantity, out TradeData quantityData  );
	bool Sell(  string name, string txname, double price, double quantity, bool isLimit, out TradeData quantityData );
	bool Cancel(  string name, string txname, UUID uuid  );
	
	bool GetPrices( out TickData[string] output );
	bool GetOpenOrders( out TradeData[string] dataList );
	bool GetBalances( out QuantityData[string] quantityDataList );
	bool GetMarketHistory( string name, string txName, Duration duration, out HistoryData data  );
	bool GetOrderBook( string name, string txName, double level, out OrderBook orderBook );
}

