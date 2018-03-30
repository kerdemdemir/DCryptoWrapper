module Client.BinanceClient;

public import Client.BinanceClientHelper;

import Client.Client;


class BinanceClient : IClient
{
	QuantityData ownedBtc;

	//https://api.binance.com/api/v1/ticker/allBookTickers 
	bool GetAnalyzeData()
	{	
		Json resultJson;
		bool isSuccess = PublicMarketCall("ticker/allBookTickers", resultJson);	
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
	
	//https://api.binance.com/api/v1/aggTrades?symbol=ETHBTC
	bool GetMarketHistory(  string name, string txname, Duration duration  )
	{
		Json resultJson;
		string urlName = "aggTrades?symbol="  ~ name ~ txname;
		bool isSuccess = PublicMarketCall(urlName, resultJson);	
		if ( !isSuccess )
			return false;
						
		try 
		{
			MarketHistoryData setVal;
			long startDate;
			int counter = 0;
			foreach_reverse (cur; resultJson) 
			{
				long date = cur["T"].to!long / 1000 ;
				if ( counter++ == 0)
					startDate = date;
				Duration tempDuration = (startDate - date).seconds;
				if ( tempDuration > duration  )
					break;	
				
				setVal.transactionCount += 1;
				double quantity = cur["q"].to!double;
				double price = cur["p"].to!double;
				double curPower = quantity*price;
				setVal.totalBTC += curPower;
				if ( !cur["m"].to!bool ) 
				{
					setVal.buyCount++;
					setVal.totalBuyInBTC += curPower;
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
	
	//https://api.binance.com/api/v1/depth?symbol=ETHBTC  
	bool GetOrderBook( string name, string txname, double buyTarget, double sellTarget )
	{
		Json resultJson;
		string urlName = "depth?symbol="  ~ name ~ txname;
		bool isSuccess = PublicMarketCall(urlName, resultJson);	
		if ( !isSuccess )
			return false;
			
		try 
		{
			double quantityCount( Json json, bool delegate(double, double) stopControl )
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
				}
				return returnVal;
			}		
			MarketOrderBook orderBook;
			orderBook.totalBTCSellRange =  quantityCount(resultJson["asks"], (a,b) => ( a < b*1.005 ) );
			orderBook.totalBTCLongSellRange =  quantityCount(resultJson["asks"], (a,b) => ( a < b*1.01 ) );
			orderBook.totalBTCBuyRange =  quantityCount(resultJson["bids"], (a,b) => ( a > b*0.997 && a>buyTarget) );
			
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
	
	//https://api.binance.com/api/v1/ticker/24hr?symbol=ETHBTC  
	TickData GetTickData( string name, string txname )
    {
	  	TickData resultData;
		string url = "ticker/24hr" ~ name ~ txname;
		Json resultJson;
		bool success = PublicMarketCall(url, resultJson);
		if ( !success )
			return resultData;
			
		try 
		{
			resultData.bid = resultJson["bidPrice"].to!double;
		    resultData.ask = resultJson["askPrice"].to!double;
		    resultData.last = resultJson["lastPrice"].to!double;
		}
		catch(std.json.JSONException e)
		{
			return resultData;
		}	
		return resultData;  	
    }
    
	bool CheckOpenOrders()
	{
		bool returnVal = true;
		Json resultJson;
		auto result = PrivateMarketGetCall("openOrders?", resultJson, false);
		if ( !result )
			return false;
		
		try 
		{
			for ( int i = 0; i < resultJson.length; i++ )
			{
				string uuid =  resultJson[i]["clientOrderId"].to!string;
				string orderType =  resultJson[i]["side"].to!string;
				string marketName =  resultJson[i]["symbol"].to!string;
				if ( orderType == "BUY" )
				{
					writeln( UUID(uuid) );
				}
				else if ( orderType == "SELL" )
				{
					writeln( UUID(uuid) );
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
    
	bool GetAndCheckBalances( )
	{
		Json resultJson;
		string[string] params;
		bool isSuccess = PrivateMarketGetCall("account?", resultJson, false);	
		
		if ( !isSuccess )
			return false;
			
		try 
		{
			Json balanceJson = resultJson["balances"];
			for ( int i = 0; i < balanceJson.length; i++ )
			{
				QuantityData quantityData;
				string currencyName =  balanceJson[i]["asset"].to!string;

				quantityData.quantityAvaliable = balanceJson[i]["free"].to!double;
			    quantityData.quantityOwned = balanceJson[i]["locked"].to!double + quantityData.quantityAvaliable;
			    
			    auto tickData = GetTickData(currencyName, "BTC");
			    quantityData.quantityAvaliableInBTC = quantityData.quantityAvaliable * tickData.last;
			    quantityData.quantityOwnedInBTC = quantityData.quantityOwned * tickData.last;
  			}
		    // Here I only print the results I suggest you keep this orderbook data in your data structures
			// writeln( currencyName, " Account Data: ",  quantityData.ToString() );	

		}
		catch(std.json.JSONException e)
		{
			return false;
		}
		
		return true;			
	}
	
  
    //https://api.binance.com/api/v3/symbol=LTCBTC&side=BUY&type=LIMIT&timeInForce=GTC&quantity=1&price=0.1&recvWindow=5000&timestamp=1499827319559
 	bool Buy(  string name, string txname, double price, double quantity  )
	{
		import std.format : format;
		import std.math : floor;
		import vibe.http.client : HTTPMethod;
		
		if ( !ownedBtc.IsExists() )
		{
			writeln( " Dont have enough BTC can't buy" );
			return false;
		} 

		Json resultJson;
		UUID curUUID = randomUUID();
		auto quantityStr = quantity < 1.0 ? format("%0.2f",quantity) : to!string(floor(quantity));
		string parameters = "symbol=" ~  name ~ txname ~ 
							"&side=BUY&type=MARKET&quantity=" ~ quantityStr ~ "&newClientOrderId=" ~  curUUID.toString();
		        
	    bool isSuccess = PrivateMarketCall( "order", parameters, resultJson, HTTPMethod.POST);
		if (isSuccess)  
		{
			try 
			{
				QuantityData quantityData;
				quantityData.buyOrderID = curUUID;
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
		import vibe.http.client : HTTPMethod;
					
		Json resultJson;
		string parameters =  "symbol=" ~ "&origClientOrderId=" ~ uuid.toString();	
	    return PrivateMarketCall("order", parameters, resultJson, HTTPMethod.DELETE);	
	}
	
	//https://bittrex.com/api/v1.1/market/selllimit?apikey=API_KEY&market=BTC-LTC&quantity=1.2&rate=1.3    
	bool Sell( string name, string txname, double price, double quantity, bool isLimit )
	{
		import std.format : format;
		import std.math : floor;
		import vibe.http.client : HTTPMethod;
				
		Json resultJson;
		UUID curUUID = randomUUID();
		
		auto quantityStr = quantity < 1.0 ? format("%0.2f",quantity) : to!string(floor(quantity));
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
		bool isSuccess = PrivateMarketCall( "order", parameters.idup, resultJson, HTTPMethod.POST );
		if (isSuccess)  
		{
			try 
			{
				QuantityData quantityData;
				quantityData.sellOrderID = curUUID; 
			}
			catch ( std.json.JSONException e )
			{
				writeln("Exception was caught while getting uuid");
				return false;
			}
		}
		return isSuccess;
	}  	

	

}
