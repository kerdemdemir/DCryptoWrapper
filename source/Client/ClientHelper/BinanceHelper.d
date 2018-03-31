module Client.BinanceClientHelper;

public import Utility.Config;

import std.digest.hmac;
import std.datetime ;
import std.digest.sha;
import vibe.http.client;

bool PublicMarketCall( string url,  ref Json result )
{
	string fullUrl = "https://api.binance.com/api/v1/" ~ url;
	try
	{
		requestHTTP(fullUrl,
			(scope req) {
				req.method = HTTPMethod.GET;
			},
			(scope res) {
				result = parseJsonString(res.bodyReader.readAllUTF8());	
			}
		);
	}
	catch ( std.json.JSONException e )
	{
		writeln("Exception was caught while making the public binance call: ", fullUrl);
		return false;
	}
	
	scope(failure)
	{
		writeln("Exception was caught while public data: ", url);
		return false;
	}
	return true;
}

bool PrivateMarketCall( string paramUrl, string quaryStr, ref Json result, HTTPMethod method)
{
    auto systime = Clock.currTime(UTC());
    string time = systime.toUnixTime.to!string ~ systime.fracSec.msecs.to!string;
	string url = "https://api.binance.com/api/v3/" ~ paramUrl ~ "?";
	
	try
	{
		char[] quary = quaryStr.dup;
		quary ~=  ("&timestamp=" ~ time ~ "&recvWindow=10000").dup  ;		
		auto hmac = HMAC!SHA256(secret.representation);
		hmac.put(quary.representation);
		auto generatedHmac = hmac.finish();
		string generatedHmacStr = std.digest.digest.toHexString(generatedHmac);
		
		quary ~= "&signature=";
		quary ~= generatedHmacStr.dup;
		
		url ~=  quary;
		if ( writeUrl )
			writeln(url);
		requestHTTP(url.dup,
			(scope req) {
				req.method = method; 
				req.headers["X-MBX-APIKEY"] = key;
			},
			(scope res) {
				result = parseJsonString(res.bodyReader.readAllUTF8());	
			}
		);
	}
	catch ( std.json.JSONException e )
	{
		writeln("Exception was caught while making the binance private call: ", url);
		return false;
	}
	
	scope(failure)
	{
		writeln("Exception was caught while binance private data: ", url);
		return false;
	}
	return true;
}

unittest
{
	Json resultJson;
	string[string] params;
	params["symbol"] = "LTCBTC";
	params["side"] = "BUY";
	params["type"] = "LIMIT";
	params["timeInForce"] = "GTC";
	params["quantity"] = "1";
	params["price"] = "0.1";
	
	//bool PrivateMarketCallTemp( string paramUrl, string quaryStr, ref Json result, HTTPMethod method, bool writeUrl = true)
	UUID curUUID = randomUUID();
	double quantityVal = 2;
	auto quantityStr = format("%0.2f",quantityVal);
		//params["newClientOrderId"] = curUUID.toString();
	//auto stringParam = "symbol=NEOBTC&side=BUY&type=MARKET&quantity=" ~ quantityStr ~ "&newClientOrderId=" ~  curUUID.toString();
	auto stringParam = "symbol=NEOBTC&side=BUY&type=LIMIT&price=0.011&timeInForce=GTC&quantity=" ~ quantityStr ~ "&newClientOrderId=" ~  curUUID.toString();

    //bool isSuccess = PrivateMarketCall( "order", stringParam,  resultJson, HTTPMethod.POST );
    bool isSuccess = PrivateMarketCall( "order/test", stringParam,  resultJson, HTTPMethod.POST );
    writeln(resultJson);
    auto result = PrivateMarketGetCall("openOrders?", resultJson);
    
	string parameters =  "symbol=NEOBTC" ~  "&origClientOrderId=" ~ UUID(resultJson[0]["clientOrderId"].to!string).toString();	
    isSuccess = PrivateMarketCall("order", parameters, resultJson, HTTPMethod.DELETE);	
    writeln(resultJson);
	//&symbol=NEOBTC&side=BUY&type=MARKET&timeInForce=IOC&quantity=0.128053&timestamp=151596108512&recvWindow=10000
	//[linux]$ echo -n "symbol=" | openssl dgst -sha256 -hmac "NhqPtmdSJYdKjVHjA7PZj4Mge3R5YNiP1e3UZjInClVN65XAbvqqM6A7H5fATj0j"
	//(stdin)= c8db56825ae71d6d79447849e617115f4a920fa2acdcab2b053c4b2838bd6b71

	//(HMAC SHA256)
	//[linux]$ curl -H "X-MBX-APIKEY: vmPUZE6mv9SD5VNHk4HlWFsOr6aKE2zvsw0MuIgwCIPy6utIco14y7Ju91duEh8A" -X POST 'https://api.binance.com/api/v3/order?symbol=LTCBTC&side=BUY&type=LIMIT&timeInForce=GTC&quantity=1&price=0.1&recvWindow=5000&timestamp=1499827319559&signature=c8db56825ae71d6d79447849e617115f4a920fa2acdcab2b053c4b2838bd6b71'

}

	