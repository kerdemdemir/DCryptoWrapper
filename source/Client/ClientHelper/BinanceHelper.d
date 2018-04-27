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
import vibe.core.core : sleep;

class SocketData
{
	this (WebSocket socket)
	{
		this.socket = socket;
	}
	
	int maxTime = 20;
	int curTime = 20;
	WebSocket socket;
}

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
	
	bool KeepSocketAlive( string name, string txName, string streamName )
	{
		string uniqStreamName = name ~ txName ~ "@" ~ streamName;
		auto socketPair = (uniqStreamName in sockets);
		if ( socketPair )
		{
			socketPair.curTime = socketPair.maxTime;
			return true; 
		}
		else 
		{
			writeln(" Keeping socket: ", uniqStreamName, " failed because socket didn't existed ");
			return false;
		}		
	}
	
	bool LaunchSocket(CallBack)( string name, string txName, string streamName, CallBack callBackfunction )
	{
		import vibe.core.sync;
		import vibe.core.concurrency;
		
		string uniqStreamName = name ~ txName ~ "@" ~ streamName;
		auto socketPair = (uniqStreamName in sockets);
		if ( socketPair )
		{
			writeln(" Launching socket: ", uniqStreamName, " failed because socket already existed ");
			return false; 
		}
		
		auto socketData = InitSocket( name, txName, streamName );
		if ( socketData )
		{
			auto result = vibe.core.concurrency.async( &CallBackLoop!(CallBack), name, txName, streamName, callBackfunction ); 
			while ( socketData.curTime-- )
			{
				sleep(1.seconds);
				if ( result.ready() )
				{
					CloseSocket( name, txName, streamName);
					return false;
				}
			} 
		}
		CloseSocket( name, txName, streamName);
		return true;
	}	
		
	bool CloseSocket( string name, string txName, string streamName )
	{
		string uniqStreamName = name ~ txName ~ "@" ~ streamName;
		auto socket = GetSocket( name, txName, streamName);
		if ( !socket )
		{
			writeln( " Socket which is to be removed does not exists ");
			return false;
		}
		auto returnVal = sockets.remove(uniqStreamName);
		socket.close();
		return returnVal;
	}
	
	WebSocket GetSocket( string name, string txName, string streamName )
	{
		string uniqStreamName = name ~ txName ~ "@" ~ streamName;
		return GetSocket(uniqStreamName);
	}
	
	WebSocket GetSocket( string uniqueName )
	{
		SocketData* socketPair = (uniqueName in sockets);
		if ( socketPair )
			return socketPair.socket;
		return null;
	}
	
private:
	
	SocketData InitSocket( string name, string txName, string streamName )
	{
		import std.uni : toLower;
		string uniqStreamName = name ~ txName ~ "@" ~ streamName;
		
		if ( uniqStreamName in sockets ) 
		{
			writeln( "Socket with unique name: ", uniqStreamName, " was already existed will return"  );
			return null;
		}
		
		auto ws_url = URL("wss://stream.binance.com:9443/ws/" ~ uniqStreamName);
		auto ws = connectWebSocket(ws_url);
		if ( !ws.connected )
			return null;
		SocketData socketData = new SocketData(ws);
		sockets[uniqStreamName] = socketData;
		return socketData;
	}
	
	short CallBackLoop(CallBack)( string name, string txName, string streamName, CallBack callBackfunction )
	{
		string uniqStreamName = name ~ txName ~ "@" ~ streamName;
		auto socket = GetSocket(name, txName, streamName);
		if ( !socket ) 
		{
			writeln(" Please be sure socket is initiliazed" );
			return -1;
		}		
		while (socket && socket.waitForData())
		{
			try
			{
				Json result = parseJsonString(socket.receiveText);
				callBackfunction(result);
			}
			catch ( std.json.JSONException e )
			{
				writeln("Exception was caught while making the binance socket call: ", e);
				continue;
			}
		}
		CloseSocket(name, txName, streamName);
		writeln( "Socket will be closed reason was: ", socket.closeReason );
		return socket.closeCode;		
	}
	
	SocketData[string] sockets;
}

unittest 
{
	import vibe.core.sync;
	import vibe.core.concurrency;

	
	writeln( "***** BinanceHelper Tests  *****" );
	auto helper = new BinanceHelper();	
	void testFoo( Json json )
	{
		//writeln(json);
	}
	
	// This is a basic test for blocking call for LaunchSocket
	// assert (helper.LaunchSocket!((typeof(&testFoo)))("iota", "btc", "aggTrade", &testFoo )); 
	
	// I expect LaunchSocket to be called with async normally 
	// auto result = vibe.core.concurrency.async( &helper.LaunchSocket!((typeof(&testFoo))),"iota", "btc", "aggTrade", &testFoo ); 
	// sleep(2.seconds);
	// helper.CloseSocket("iota", "btc", "aggTrade");
	//Premature close result should be close 
	// assert( !result.ready() );
}


	