module Client.ClientWrapper.BinanceWrapper;

import Client.ClientHelper.BinanceHelper;
import Client.ClientWrapper.ClientWrapper;

public import std.uuid;
import std.stdio;
import std.datetime;
		
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
			long startDate;
			for ( int i = 0; i < resultJson.length; i++ )
			{
				long date = resultJson[i]["T"].to!long / 1000 ;
				if ( i == 0)
					startDate = date;
				Duration tempDuration = (date - startDate).seconds;
				if ( tempDuration > duration  )
					break;	
				
				data.transactionCount += 1;
				double quantity = resultJson[i]["q"].to!double;
				double price = resultJson[i]["p"].to!double;
				double curPower = quantity*price;
				data.total += curPower;
				if ( !resultJson[i]["m"].to!bool ) 
				{
					data.buyCount++;
					data.totalBuy += curPower;
				}			
  			}

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
					else 
						break;	
				}
				return returnVal;
			}		
			
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
	
	BinanceHelper helper;
}

unittest 
{
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
	writeln(orderOutput.ToString());
	assert(isSuccess && orderOutput.bookLongSellRange > orderOutput.bookSellRange ); 
	
	// I don't know how to model private calls since I don't want give my keys. 
	
}

	