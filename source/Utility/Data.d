module Utility.Data;

public import Utility.Config;
public import Utility.Enums;
public import std.conv : to;
public import std.string;



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

struct HistoryData
{
	double total = 0.0;
	double totalBuy = 0.0;
	double transactionCount = 0.0;
	double buyCount = 0.0;

    string ToString()
    {
    	return  " Total traded: " ~ to!string(total) ~ " Total Buys: " ~ to!string(totalBuy) ~ " Transacrion count: " ~  to!string(transactionCount) ~ " Buy count: " ~ to!string(buyCount) ;
    }
}

struct OrderBook
{
	double bookBuyRange = 0.0;
	double bookSellRange = 0.0;
	double bookLongSellRange = 0.0;
		
    string ToString()
    {
    	return  " Order Book Buy Power : " ~ to!string(bookBuyRange) ~ " Order Book Sell Power : " 
		    	~ to!string(bookSellRange) ~ " Long Sell Power: " ~ to!string(bookLongSellRange);
    }
}

struct TradeData
{
	import std.uuid : UUID;
	import std.datetime : DateTime;

	UUID   sellOrderID;
	UUID   buyOrderID;
	DateTime buyOrderTime;
	DateTime sellOrderTime;	
	
	string ToString()
    {
    	return " BuyID: " ~ sellOrderID.toString() ~ " SellID: " ~ sellOrderID.toString() ~ 
		       " BuyTime: " ~ buyOrderTime.toSimpleString() ~ " Sell Time: " ~ sellOrderTime.toSimpleString();	
	}
}

struct QuantityData
{
	double owned                  = 0.0;
	double avaliable     	      = 0.0;
	double avaliableTx            = 0.0;
	double ownedTx                = 0.0;
	double minunumVal             = 0.00091; 
	
	bool IsExists()
	{
		return avaliableTx > minunumVal;
	}
	
	bool IsOwnedExists()
	{
		return ownedTx > minunumVal;
	}
	
	string ToString()
    {
    	return " Owned " ~ to!string(owned) ~ "Avaliable: " ~ to!string(avaliable);	
	}
}

