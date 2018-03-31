module Client.BittrexClientHelper;

public import Conf.Conf;

import std.digest.sha;
import std.string;
import std.digest.hmac;
import std.datetime ;


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

bool PrivateMarketCall( string paramUrl, string parameters, ref Json result)
{
	string nonce =  Clock.currTime(UTC()).toUnixTime.to!string;
	string url = "https://bittrex.com/api/v1.1/" ~ paramUrl ~  apikey ~ "&nonce=" ~ nonce ~ parameters;
	
	auto hmac = HMAC!SHA512(secret.representation);
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


	