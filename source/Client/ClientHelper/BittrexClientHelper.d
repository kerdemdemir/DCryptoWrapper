module Client.BittrexClientHelper;

import std.digest.sha;
import std.string;
import std.digest.hmac;
import std.datetime ;
import std.stdio ;
import std.algorithm;
import std.array;
import std.conv;
import std.uuid;
import vibe.core.log;
import vibe.http.client;
import vibe.stream.operations;
import vibe.data.json;
import vibe.crypto.cryptorand;
import std.digest.digest;

string apikey=" write your api key ";
string apisecret="write your api secret ";

bool PublicMarketCall( string url,  ref Json result )
{
	string fullUrl = "https://bittrex.com/api/v1.1/public/" ~ url;
	Json data;
	try
	{
		requestHTTP(fullUrl,
			(scope req) {
				req.method = HTTPMethod.GET;
			},
			(scope res) {
				data = parseJsonString(res.bodyReader.readAllUTF8());	
			}
		);
	}
	catch ( std.json.JSONException e )
	{
		writeln("Exception was caught while making the public call: ", fullUrl);
		return false;
	}
		
	foreach (key, value; data.byKeyValue)
	{		
		if ( key == "success" ) 
		{
			bool resultBool = value.get!bool;
			if (!resultBool) 
			{
				writeln("Failed: ", data["message"].get!string);
				return false;
			}
		}
		
		if ( key == "result" ) 
		{
			result = value;
			return true;
		}
	}
	scope(failure)
		writeln("Exception was caught while public data: ", url);
	return false;
}

bool PublicMarketCallV2( string url,  ref Json result )
{
	string fullUrl = "https://bittrex.com/api/v2.0/pub/" ~ url;
	Json data;
	try
	{
		requestHTTP(fullUrl,
			(scope req) {
				req.method = HTTPMethod.GET;
			},
			(scope res) {
				data = parseJsonString(res.bodyReader.readAllUTF8());	
			}
		);
	}
	catch ( std.json.JSONException e )
	{
		writeln("Exception was caught while making the public call: ", fullUrl);
		return false;
	}
		
	foreach (key, value; data.byKeyValue)
	{		
		if ( key == "success" ) 
		{
			bool resultBool = value.get!bool;
			if (!resultBool) 
			{
				writeln("Failed: ", data["message"].get!string);
				return false;
			}
		}
		
		if ( key == "result" ) 
		{
			result = value;
			return true;
		}
	}
	scope(failure)
		writeln("Exception was caught while public data: ", url);
	return false;
}

bool PrivateMarketCall( string paramUrl, string parameters, ref Json result, bool writeUrl = true)
{
	string nonce =  Clock.currTime(UTC()).toUnixTime.to!string;
	string url = "https://bittrex.com/api/v1.1/" ~ paramUrl ~  apikey ~ "&nonce=" ~ nonce ~ parameters;
	if (writeUrl)
		writeln(url);
	auto hmac = HMAC!SHA512(apisecret.representation);
	hmac.put(url.representation);
	auto generatedHmac = hmac.finish();
	string generatedHmacStr = std.digest.digest.toHexString(generatedHmac);
	//writeln(generatedHmacStr);
	Json data;	
	try
	{
		requestHTTP(url.dup,
			(scope req) {
				req.method = HTTPMethod.GET;
				req.headers["apisign"] = generatedHmacStr;
			},
			(scope res) {
				data = parseJsonString(res.bodyReader.readAllUTF8());
				//writeln(data);
			}
		);
	}
	catch ( std.json.JSONException e )
	{
		writeln("Exception was caught while making the private call: ", url);
		return false;
	}
	
	foreach (key, value; data.byKeyValue)
	{		
		if ( key == "success" ) 
		{
			bool resultBool = value.get!bool;
			if (!resultBool) 
			{
				writeln("Failed: ", data["message"].get!string);
				return false;
			}
		}
		
		if ( key == "result" ) 
		{
			result = value;
			return true;
		}
	}	
	scope(failure)
		writeln("Exception was caught while public data: ", url);
	return false;
}

//https://bittrex.com/Api/v2.0/key/market/TradeBuy?marketName=BTC-LTC&orderType=LIMIT&quantity=5000&rate=.00000012&timeInEffect=GOOD_TIL_CANCELLED&conditionType=NONE&target=0
//https://bittrex.com/api/v2.0/key/market/tradesell?marketname=BTC-LTC&ordertype=XXXX&quantity=1&rate=.00000012&timeInEffect=IOC&conditiontype=xxx&target=xxxx
bool PrivateMarketCallV2( string paramUrl, string parameters, ref Json result, bool writeUrl = true)
{
	string nonce =  Clock.currTime(UTC()).toUnixTime.to!string;
	string url = "https://bittrex.com/Api/v2.0/key/" ~ paramUrl ~  apikey ~ "&nonce=" ~ nonce ~ parameters;
	if (writeUrl)
		writeln(url);
	auto hmac = HMAC!SHA512(apisecret.representation);
	hmac.put(url.representation);
	auto generatedHmac = hmac.finish();
	string generatedHmacStr = std.digest.digest.toHexString(generatedHmac);
	//writeln(generatedHmacStr);
	Json data;	
	try
	{
		requestHTTP(url.dup,
			(scope req) {
				req.method = HTTPMethod.GET;
				req.headers["apisign"] = generatedHmacStr;
			},
			(scope res) {
				writeln(data);
				data = parseJsonString(res.bodyReader.readAllUTF8());
				//writeln(data);
			}
		);
	}
	catch ( std.json.JSONException e )
	{
		writeln("Exception was caught while making the private call: ", url);
		return false;
	}
	
	foreach (key, value; data.byKeyValue)
	{		
		if ( key == "success" ) 
		{
			bool resultBool = value.get!bool;
			if (!resultBool) 
			{
				writeln("Failed: ", data["message"].get!string);
				return false;
			}
		}
		
		if ( key == "result" ) 
		{
			result = value;
			return true;
		}
	}	
	scope(failure)
		writeln("Exception was caught while public data: ", url);
	return false;
}

	