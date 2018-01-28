module Client.BittrexClient;

import Client.Client;
import Client.BittrexClientHelper;


import std.algorithm;
import std.array;
import vibe.core.log;
import vibe.http.client;
import vibe.stream.operations;
import std.typecons;
import vibe.core.sync;
import vibe.core.concurrency;
import vibe.core.core;

class BittrexClient : IClient
{
	QuantityData ownedBtc; 
	
	//https://bittrex.com/api/v1.1/public/getmarketsummaries    
	bool GetAnalyzeData( )
	{	
		Json resultJson;
		try 
		{
			
			bool isSuccess = PublicMarketCall("getmarketsummaries", resultJson);	
			if ( !isSuccess )
				return false;
			

			for ( int i = 0; i < resultJson.length; i++ )
			{
				string marketName =  resultJson[i]["MarketName"].to!string;
				TickData data;
				data.bid = resultJson[i]["Bid"].to!double;
			    data.ask = resultJson[i]["Ask"].to!double;
			    data.last = resultJson[i]["Last"].to!double;
			    // Here I only print the results I suggest you keep this TickData in your data structures
			    writeln( marketName, " Tick data: ",  data.ToString() );
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
	
	//https://bittrex.com/api/v1.1/public/getmarkethistory?market=BTC-DOGE    
	bool GetMarketHistory( string name, string txname, Duration duration )
	{
		Json resultJson;
		string urlName = "getmarkethistory?market=" ~ txname ~ "-" ~ name;
		bool isSuccess = PublicMarketCall(urlName, resultJson);	
		if ( !isSuccess )
			return false;
						
		try 
		{
			MarketHistoryData setVal;
			SysTime startDate;
			for ( int i = 0; i < resultJson.length; i++ )
			{
				SysTime date =  SysTime(DateTime.fromISOExtString(resultJson[i]["TimeStamp"].to!string.split('.')[0])) ;
				if ( i == 0)
					startDate = date;
				Duration tempDuration = startDate - date;
				if ( tempDuration > duration  )
					break;	
				
				setVal.transactionCount += 1;
				double curBuyPower = resultJson[i]["Total"].to!double;
				setVal.totalBTC += curBuyPower;
				if (resultJson[i]["OrderType"].to!string == "BUY") 
				{
					setVal.buyCount++;
					setVal.totalBuyInBTC += curBuyPower;
				}			
  			}
		    // Here I only print the results I suggest you keep this MarketHistoryData in your data structures
		    writeln( name, " History data: ",  setVal.ToString() );
		}
		catch(std.json.JSONException e)
		{
			writeln(e);
			return false;
		}
		return true;			
	}
	
	// https://bittrex.com/api/v1.1/public/getorderbook?market=BTC-LTC&type=both    
	bool GetOrderBook( string name, string txname, double buyTarget, double sellTarget )
	{
		Json resultJson;
		// If desired v2 call can be called 
		// string urlName = "Market/GetMarketOrderBook?marketName=" ~ txname ~ "-" ~ name ~ "&type=both" ;
		// bool isSuccess = PublicMarketCallV2(urlName, resultJson);	

		string urlName = "getorderbook?market=" ~ txname ~ "-" ~ name ~ "&type=both" ;
		bool isSuccess = PublicMarketCall(urlName, resultJson);	
		if ( !isSuccess )
			return false;
			
		try 
		{
			double quantityCount( ref Json json, bool delegate(double, double) stopControl )
			{
				double returnVal = 0.0;
				double firstRate = 0.0;
				if ( json == Json.emptyObject)
					return 0.0; 
				for ( int i = 0; i < json.length; i++ )
				{
					double quantity = json[i]["Quantity"].to!double;
					double rate = json[i]["Rate"].to!double;
					
					if ( i == 0 )
						firstRate = rate;
					double curValue = quantity*rate;
					if ( stopControl(rate, firstRate) ) 
						returnVal += curValue;
				}
				return returnVal;
			}		
			MarketOrderBook orderBook;
			
			// I am only interested with the small parts of the orderbook data you can adjust it for yourself. 
			orderBook.totalBTCSellRange =  quantityCount(resultJson["sell"], (a,b) => ( a < b*1.005 ) );
			orderBook.totalBTCLongSellRange =  quantityCount(resultJson["sell"], (a,b) => ( a < b*1.01 ) );
			orderBook.totalBTCBuyRange =  quantityCount(resultJson["buy"], (a,b) => ( a > b*0.995 && a>buyTarget) );
			
		    // Here I only print the results I suggest you keep this orderbook data in your data structures
		    writeln( name, " Order book data: ",  orderBook.ToString() );	
		}
		catch(std.json.JSONException e)
		{
			writeln(e);
			return false;
		}
		return true;			
	}
	
	//https://bittrex.com/api/v1.1/public/getticker    
	TickData GetTickData( string name, string txname )
    {
	  	TickData resultData;
		string url = "getticker?market=" ~ txname ~ "-" ~ name;
		Json resultJson;
		bool success = PublicMarketCall(url, resultJson);
		if ( !success )
			return resultData;
			
		try 
		{
			resultData.bid = resultJson["Bid"].to!double;
		    resultData.ask = resultJson["Ask"].to!double;
		    resultData.last = resultJson["Last"].to!double;
		}
		catch(std.json.JSONException e)
		{
			return resultData;
		}	
		return resultData;  	
    }  
			

	//https://bittrex.com/api/v1.1/account/getbalances?apikey=API_KEY    
	bool GetAndCheckBalances( )
	{
		Json resultJson;
		bool isSuccess = PrivateMarketCall("account/getbalances?apikey=", "", resultJson, false);	
		if ( !isSuccess )
			return false;
			
		try 
		{
			for ( int i = 0; i < resultJson.length; i++ )
			{
				QuantityData quantityData;
				
				string currencyName =  resultJson[i]["Currency"].to!string;
				quantityData.quantityAvaliable = resultJson[i]["Available"].to!double;
			    quantityData.quantityOwned = resultJson[i]["Balance"].to!double;
			    
			    // I am taking BTC is being used normally in an app I would get this from Configuration and made it adjustable
			    auto tickData = GetTickData(currencyName, "BTC");
			    quantityData.quantityAvaliableInBTC = quantityData.quantityAvaliable * tickData.last;
			    quantityData.quantityOwnedInBTC = quantityData.quantityOwned * tickData.last;
			    
				if ( currencyName == "BTC" )
				{
					ownedBtc.quantityAvaliableInBTC = quantityData.quantityAvaliable;
					ownedBtc.quantityOwnedInBTC = quantityData.quantityOwned;
				}
				
			    // Here I only print the results I suggest you keep this orderbook data in your data structures
				 writeln( currencyName, " Account Data: ",  quantityData.ToString() );	
  			}

		}
		catch(std.json.JSONException e)
		{
			return false;
		}
		return true;			
	}

	//https://bittrex.com/api/v1.1/market/getopenorders?apikey=API_KEY 
	bool CheckOpenOrders( )
	{
		bool returnVal = true;
		Json resultJson;
		auto result = PrivateMarketCall("market/getopenorders?apikey=", "", resultJson, false);
		if ( !result )
			return false;
			
		try 
		{
			for ( int i = 0; i < resultJson.length; i++ )
			{
				string uuid =  resultJson[i]["OrderUuid"].to!string;
				string orderType =  resultJson[i]["OrderType"].to!string;
				string exchange =  resultJson[i]["Exchange"].to!string.split("-")[1];
				 
				if ( orderType == "LIMIT_BUY" )
				{
				    // Here I only print the results I suggest you keep this orderbook data in your data structures
					 writeln( exchange, " Open Buy Order UUID: ",  uuid );	
				}
				else if ( orderType == "LIMIT_SELL" )
				{
				    // Here I only print the results I suggest you keep this orderbook data in your data structures
					 writeln( exchange, " Open Sell Order UUID: ",  uuid );	
				}
  			}

		}
		catch(std.json.JSONException e)
		{
			return false;
		}		
		scope(failure)
			writeln("Exception was caught while public checking open orders ");
		return returnVal;		
	}

	//https://bittrex.com/api/v1.1/market/buylimit?apikey=API_KEY&market=BTC-LTC&quantity=1.2&rate=1.3    
	bool Buy( string name, string txname, double price, double quantity )
	{
		Json resultJson;
		string parameters = "&market=" ~   txname ~ "-" ~ name ~ "&quantity=" ~ 
		                     to!string(quantity)   ~ "&rate=" ~ to!string(price);
	    bool isSuccess = PrivateMarketCall("market/buylimit?apikey=", parameters, resultJson);	
		if (isSuccess)  
		{
			try 
			{
				QuantityData quantityData;
				quantityData.buyOrderID = UUID(resultJson["uuid"].get!string);
				quantityData.buyOrderTime = Clock.currTime();
				
			    // Here I only print the results I suggest you keep this orderbook data in your data structures
				 writeln( name, " After buy UUID: ",  quantityData.ToString() );	
 
			}
			catch ( std.json.JSONException e )
			{
				writeln("Exception was caught while getting uuid");
				return false;
			}
		}
		return isSuccess;
	}

	//https://bittrex.com/api/v1.1/market/cancel?apikey=API_KEY&uuid=ORDER_UUID    
	bool Cancel( UUID uuid )
	{			
		Json resultJson;
		string parameters = "&uuid=" ~  uuid.toString(); 
	    bool isSuccess = PrivateMarketCall("market/cancel?apikey=", parameters, resultJson);	
		return isSuccess;
	}

	//https://bittrex.com/api/v1.1/market/selllimit?apikey=API_KEY&market=BTC-LTC&quantity=1.2&rate=1.3    
	bool Sell(  string name, string txname, double price, double quantity, bool isLimit  )
	{		
		Json resultJson;
		string parameters = "&market=" ~   txname ~ "-" ~ name ~ "&quantity=" ~ 
		                     to!string(quantity)   ~ "&rate=" ~ to!string(price);
		bool isSuccess = PrivateMarketCall("market/selllimit?apikey=", parameters, resultJson);
		if (isSuccess)  
		{
			try 
			{
				QuantityData quantityData;
				quantityData.sellOrderID = UUID(resultJson["uuid"].get!string);
				quantityData.sellOrderTime = Clock.currTime();
			    // Here I only print the results I suggest you keep this orderbook data in your data structures
				 writeln( name, " After sell UUID: ",  quantityData.ToString() );	
			}
			catch ( std.json.JSONException e )
			{
				writeln("Exception was caught while getting uuid");
				return false;
			}
		}
		return 	isSuccess;	
	}  
}
