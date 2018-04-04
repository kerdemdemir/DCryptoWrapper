module Client.ClientHelper.BinanceHelper;

public import Utility.Config;
public import Client.ClientHelper.ClientHelper;
public import std.container : DList;

import std.digest.hmac;
import std.datetime ;
import std.digest.sha;
import vibe.http.client;
import std.stdio;
import vibe.stream.operations : readAllUTF8;
import vibe.http.websockets;

class BinanceHelper
{
	KeySecretStruct keySecret;
	
	bool PublicCall( string url,  ref Json result )
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
	
	bool PrivateCall( string paramUrl, string quaryStr, ref Json result, HTTPMethod method)
	{
		import std.conv : to;
		
	    auto systime = Clock.currTime(UTC());
	    string time = systime.toUnixTime.to!string ~ systime.fracSec.msecs.to!string;
		string url = "https://api.binance.com/api/v3/" ~ paramUrl ~ "?";
		
		try
		{
			char[] quary = quaryStr.dup;
			quary ~=  ("&timestamp=" ~ time ~ "&recvWindow=10000").dup  ;		
			auto hmac = HMAC!SHA256(keySecret.secret.representation);
			hmac.put(quary.representation);
			auto generatedHmac = hmac.finish();
			string generatedHmacStr = std.digest.digest.toHexString(generatedHmac);
			
			quary ~= "&signature=";
			quary ~= generatedHmacStr.dup;
			
			url ~=  quary;
			requestHTTP(url.dup,
				(scope req) {
					req.method = method; 
					req.headers["X-MBX-APIKEY"] = keySecret.key;
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
	
	
	short InitSocket(CallBack)( string name, string txName, string streamName, CallBack  )
	{
		import std.uni : toLower;
		string uniqStreamName = name.toLower() ~ txName.toLower() ~ "@" ~ streamName;
		
		if ( uniqStreamName in sockets ) 
		{
			writeln( "Socket with unique name: ", uniqStreamName, " was already existed will return"  );
			return -1;
		}
		auto ws_url = URL("wss://stream.binance.com:9443/ws/" ~ uniqStreamName);
		auto ws = connectWebSocket(ws_url);
		if ( !ws.connected )
			return -1;
		sockets[uniqStreamName] = ws;
		
		while (ws.waitForData())
		{
			try
			{
				Json result = parseJsonString(ws.receiveText);
				callBackfunction(result);
			}
			catch ( std.json.JSONException e )
			{
				writeln("Exception was caught while making the binance socket call: ", e);
				continue;
			}
		}
		CloseSocket(name.toLower(), txName.toLower(), streamName);
		writeln( "Socket will be closed reason was: ", ws.closeReason );
		return ws.closeCode;		
	}
	
	bool CloseSocket( string name, string txName, string streamName )
	{
		string uniqStreamName = name ~ txName ~ "@" ~ streamName;
		return sockets.remove(uniqStreamName);
	}
	
private:
	WebSocket[string] sockets;
}

unittest 
{
	import vibe.core.sync;
	import vibe.core.concurrency;
	import vibe.core.core;

	writeln( "***** BinanceHelper Tests  *****" );

	auto helper = new BinanceHelper();
	
	void testFoo( Json json )
	{
		writeln(json);
	}
	
	vibe.core.concurrency.async(  helper.InitSocket, "iota", "btc", "aggTrade", &testFoo ); 
	
	//helper.CloseSocket( "eth", "btc", "aggTrade");
}


	