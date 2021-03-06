module Client.ClientWrapper.BinanceWrapper;

import Client.ClientHelper.BinanceHelper;
import Client.ClientWrapper.ClientWrapper;
import Client.ClientWrapper.SocketWrapperHelper;

public import std.uuid;
import std.stdio;
import std.datetime;
import std.container.dlist;

enum SocketListSize = 1000;
		
class BinanceWrapper : ClientWrapper
{
	bool GetPrices( out TickData[string] output )
	{
		Json resultJson;
		bool isSuccess = helper.PublicCall("ticker/allBookTickers", resultJson);	
		if ( !isSuccess )
			return false;	
		try 
		{
			for ( int i = 0; i < resultJson.length; i++ )
			{
				string marketName =  resultJson[i]["symbol"].to!string;
	
				TickData data;
				data.bid = resultJson[i]["bidPrice"].to!double;
			    data.ask = resultJson[i]["askPrice"].to!double;
			    data.last = (data.bid + data.ask)/2;
			    
			    output[marketName] = data;
  			}
		}
		catch(std.json.JSONException e)
		{
			writeln(e);
			return false;
		}
		catch(Exception e)
		{
			writeln(e);
			return false;			
		}

		scope(failure)
		{
			writeln("Exception was caught while client analyze data");
			return false;
		}	
		return true;				
	}
	
	bool GetMarketHistory( string name, string txName, Duration duration, out HistoryData data )
	{		
		Json resultJson;
		string urlName = "aggTrades?symbol="  ~ name ~ txName;
		bool isSuccess = helper.PublicCall(urlName, resultJson);	
		if ( !isSuccess )
			return false;
		try 
		{
			data = CalculateHistoryDataFromJson( resultJson, duration );
		}
		catch(std.json.JSONException e)
		{
			writeln(e);
			return false;
		}
		return true;			
	}	
	
	bool GetMarketHistorySocket( string name, string txName, Duration duration, out HistoryData data  )
	{
		import vibe.core.sync;
		import vibe.core.concurrency;
		import vibe.core.core : sleep;
		
		void CallBackFoo( Json data )
		{
			InsertSocketDataToList(name, txName, data);	
		}	
		 
		try 
		{
		    if ( !GetListData( name, txName ) )
		    {
				Json resultJson;
				string urlName = "aggTrades?symbol="  ~ name.toUpper() ~ txName.toUpper();
				bool isSuccess = helper.PublicCall(urlName, resultJson);	
				if ( !isSuccess )
					return false;
				InsertSocketDataToList(name, txName, resultJson);
				
				vibe.core.concurrency.async( 
						{ return this.helper.LaunchSocket(name, txName, "aggTrade", &CallBackFoo );}
				);  	
		    }
		    else 
		    {
		    	this.helper.KeepSocketAlive(name, txName, "aggTrade");
		    }
		    
		    auto listData = GetListData( name, txName );
		    if ( !listData )
			    return false;
			data = CalculateHistoryDataFromJson( listData, duration );			
		} 
		catch(std.json.JSONException e)
		{
			writeln(e);
			return false;
		}
		return true;					
	}
	
	bool GetOrderBook( string name, string txName, double level, out OrderBook orderBook )
	{
		Json resultJson;
		string urlName = "depth?symbol="  ~ name ~ txName ~ "&limit=1000";
		if ( !helper.PublicCall(urlName, resultJson) )
			return false;
			
		try 
		{
			orderBook.bookSellRange =  quantityCount(resultJson["asks"], (a,b) => ( a < b*(1 + level)));
			orderBook.bookLongSellRange =  quantityCount(resultJson["asks"], (a,b) => ( a < b*(1 + level*2)));
			orderBook.bookBuyRange =  quantityCount(resultJson["bids"], (a,b) => ( a > b*(1 - level)));						
		}
		catch(std.json.JSONException e)
		{
			writeln(e);
			return false;
		}
		return true;			
	}
	
	bool GetOrderBookSocket( string name, string txName, double level, out OrderBook orderBook )
	{
		import vibe.core.sync;
		import vibe.core.concurrency;
		import vibe.core.core : sleep;
		
		ulong lastUpdateID = 0; 
		
		void CallBackFoo( Json data )
		{
			ulong updateID = data["u"].to!ulong;
			if ( lastUpdateID > updateID )
				return;
			string symbol = data["s"].to!string.toLower();
			auto helper = (symbol in socketOrderBookHelperMap);
			if ( helper )
			{
				helper.Process(data);
			}
		}	
		
		try 
		{
			string symbol = name ~  txName;
		    if ( !GetOrderBookSocketData(symbol) )
		    {
				Json resultJson;
				string urlName = "depth?symbol="  ~ symbol.toUpper() ~ "&limit=1000";
				bool isSuccess = helper.PublicCall(urlName, resultJson);	
				if ( !isSuccess )
					return false;
				lastUpdateID = resultJson["lastUpdateId"].to!ulong;
				
				OrderBookSocketHelper tempHelper = new OrderBookSocketHelper;
				tempHelper.CalculateWithRawJson(resultJson);	
				socketOrderBookHelperMap[symbol] = tempHelper;
				
				vibe.core.concurrency.async( 
						{ return this.helper.LaunchSocket(name, txName, "depth", &CallBackFoo );}
				);  	
		    }
		    else 
		    {
		    	this.helper.KeepSocketAlive(name, txName, "depth");
		    }
		    
		    auto listData = GetOrderBookSocketData(symbol);
		    if ( !listData )
			    return false;
			orderBook.bookSellRange =  listData.CalculatePower( 1+level, false );
			orderBook.bookLongSellRange =  listData.CalculatePower( 1+level*2, false );
			orderBook.bookBuyRange = listData.CalculatePower( 1-level, true );		
		}
		catch(std.json.JSONException e)
		{
			writeln(e);
			return false;
		}
		    	
		return true;				
	}
	
	bool GetBalances( out QuantityData[string] quantityDataList )
	{
		Json resultJson;
		
		if ( !helper.PrivateCall("account?", "", resultJson, HTTPMethod.GET) )
			return false;
			
		try 
		{
			Json balanceJson = resultJson["balances"];
			for ( int i = 0; i < balanceJson.length; i++ )
			{
				QuantityData quantityData;
				string currencyName =  balanceJson[i]["asset"].to!string;

				quantityData.avaliable = balanceJson[i]["free"].to!double;
			    quantityData.owned = balanceJson[i]["locked"].to!double + quantityData.avaliable;
			    quantityDataList[currencyName] = quantityData;
  			}

		}
		catch(std.json.JSONException e)
		{
			return false;
		}
		
		return true;	
	}
	
	bool GetOpenOrders( out TradeData[string] dataList )
	{
		Json resultJson;
		if ( !helper.PrivateCall("openOrders?", "", resultJson, HTTPMethod.GET) )
			return false;
		
		try 
		{
			for ( int i = 0; i < resultJson.length; i++ )
			{
				TradeData data;
				string uuid =  resultJson[i]["clientOrderId"].to!string;
				string orderType =  resultJson[i]["side"].to!string;
				string marketName =  resultJson[i]["symbol"].to!string;
				if ( orderType == "BUY" )
				{
					data.buyOrderID = UUID(uuid);
				}
				else if ( orderType == "SELL" )
				{
					data.sellOrderID = UUID(uuid);
				}
				dataList[marketName] = data;
  			}

		}
		catch(std.json.JSONException e)
		{
			return false;
		}		
		scope(failure)
			writeln("Exception was caught while public checking open orders ");
			
		return true;	
	}	

	bool Buy( string name, string txname, double price, double quantity, out TradeData tradeData )
	{
		Json resultJson;
		UUID curUUID = randomUUID();
		string parameters = "symbol=" ~  name ~ txname ~ 
							"&side=BUY&type=MARKET&quantity=" ~ to!string(quantity) 
							~ "&newClientOrderId=" ~  curUUID.toString();
		        
		if (helper.PrivateCall( "order", parameters, resultJson, HTTPMethod.POST))  
		{
			try 
			{
				tradeData.buyOrderID = curUUID;
				tradeData.buyOrderTime = to!DateTime(Clock.currTime());
			}
			catch ( std.json.JSONException e )
			{
				writeln("Exception was caught while getting uuid");
				return false;
			}
		}
		return true;				
	}
	
	bool Sell( string name, string txname, double price, 
			   double quantity, bool isLimit, out TradeData tradeData  )
	{
		Json resultJson;
		UUID curUUID = randomUUID();
		
		auto quantityStr =  to!string(quantity);
		char[] parameters;
		if ( isLimit )
		{
			parameters = ("symbol=" ~ name ~ txname ~ 
									"&side=SELL&type=LIMIT&quantity=" ~ quantityStr ~ 
									"&price=" ~  to!string(price) ~ 
									"&timeInForce=GTC" ~  
									"&newClientOrderId=" ~ curUUID.toString()).dup;		
			
		} 
		else 
		{
			parameters = ("symbol=" ~ name ~ txname ~ 
									"&side=SELL&type=MARKET&quantity=" ~ quantityStr ~ 
									"&newClientOrderId=" ~ curUUID.toString()).dup;	
		}
		
		if (helper.PrivateCall( "order", parameters.idup, resultJson, HTTPMethod.POST ))  
		{
			try 
			{
				tradeData.sellOrderID = curUUID;
				tradeData.sellOrderTime = to!DateTime(Clock.currTime()); 
			}
			catch ( std.json.JSONException e )
			{
				writeln("Exception was caught while getting uuid");
				return false;
			}
		}
		return true;		
	}
	
	bool Cancel( string name, string txname, UUID uuid )
	{
		Json resultJson;
		string parameters =  "symbol=" ~ name ~ txname ~ "&origClientOrderId=" ~ uuid.toString();	
	    return helper.PrivateCall("order", parameters, resultJson, HTTPMethod.DELETE);			
	}
	
	this( string apikey, string apisecret )
	{
		helper  = new BinanceHelper();
		helper.keySecret.SetKeyAndSecret(apikey, apisecret);
	}
	
	this()
	{
		helper  = new BinanceHelper();
	}
	
	void SetKeyAndSecret( string apikey, string apisecret )
	{
		helper.keySecret.SetKeyAndSecret(apikey, apisecret);
	}
	
private:
	
	void InsertSocketDataToList( string name, string txName, Json data )
	{
		import std.range : walkLength;
		
		auto socketData = GetListData( name, txName);
		if ( !socketData ) 
		{
			string uniqStreamName = name ~ txName;
			socketData = new DList!Json;
			socketDataList[uniqStreamName] = *socketData;
			InsertSocketDataToList(name, txName, data);
		}
		
		try 
		{
			
			auto curSize = (*socketData)[].walkLength();
			if ( data.type() == Json.Type.array )
			{
				for ( int i = 0; i < data.length; i++ )
				{
					socketData.insertFront(data[i]);
					if ( ++curSize > SocketListSize )
						socketData.removeBack();					
				}			
			}
			else
			{
				socketData.insertFront(data);
				if ( ++curSize > SocketListSize )
					socketData.removeBack();
			}
								
		}
		catch(std.json.JSONException e)
		{
			writeln(e);
		}						
	}
	
	DList!(Json)* GetListData(  string name, string txName )
	{
		import std.range : popFrontN;
		
		string uniqStreamName = name ~ txName;
		auto socketData = (uniqStreamName in socketDataList);
		return socketData;
	}
	
	OrderBookSocketHelper* GetOrderBookSocketData( string name )
	{
		auto socketData = (name in socketOrderBookHelperMap);
		return socketData;		
	}
	
	DList!Json[string] socketDataList;
	OrderBookSocketHelper[string] socketOrderBookHelperMap;
	BinanceHelper helper;
}

double quantityCount(T)( ref T json, bool delegate(double, double) stopControl )
{
	double returnVal = 0.0;
	double firstRate = 0.0;
	for ( int i = 0; i < json.length; i++ )
	{
		double rate= json[i][0].to!double;
		double quantity  = json[i][1].to!double;
		
		if ( i == 0 )
			firstRate = rate;
		double curValue = quantity*rate;
		if ( stopControl(rate, firstRate) ) 
			returnVal += curValue;
		else 
			break;	
	}
	return returnVal;
}		
				

unittest 
{
	import vibe.core.core : sleep;
	
	auto wrapper = new BinanceWrapper();
	bool isSuccess = false;
	writeln( "***** BinanceWrapper Tests  *****" );
	
	TickData[string] output;
	isSuccess = wrapper.GetPrices( output );
	assert(isSuccess && output.length > 0 );
	
	HistoryData historyOutput;
	isSuccess = wrapper.GetMarketHistory( "ETH", "BTC", 30.seconds, historyOutput );
	// Assume big currencies like BTC and ETC will always be traded 
	assert(isSuccess && historyOutput.total > 0 );

	OrderBook orderOutput;
	isSuccess = wrapper.GetOrderBook( "ETH", "BTC", 0.05, orderOutput );
	//writeln(orderOutput.ToString());
	assert(isSuccess && orderOutput.bookLongSellRange > orderOutput.bookSellRange ); 
	
//	for ( int i = 0; i < 10; i++ )
//	{
//		HistoryData historyOutputSocket;
//		isSuccess = wrapper.GetMarketHistorySocket("eth", "btc", 60.seconds, historyOutputSocket );
//		writeln(historyOutputSocket);
//		sleep(1.seconds);		
//		
//		HistoryData historyOutputSocket2;
//		isSuccess = wrapper.GetMarketHistorySocket("iota", "btc", 60.seconds, historyOutputSocket2 );
//		writeln(historyOutputSocket2);
//		sleep(1.seconds);		
//	}	
	
	
	for ( int i = 0; i < 20; i++ )
	{
		OrderBook orderBookSocket;
		isSuccess = wrapper.GetOrderBookSocket("eth", "btc", 0.005, orderBookSocket );
		writeln(orderBookSocket.ToString());
		sleep(2.seconds);			
	}

	// I don't know how to model private calls since I don't want give my keys. 
	
}

	