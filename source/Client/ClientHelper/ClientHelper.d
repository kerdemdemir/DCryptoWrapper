module Client.ClientHelper;

public import vibe.data.json;
public import vibe.http.common : HTTPMethod;

class ClientHelper
{
	string key;
	string secret;
	
	this( string apikey, string apisecret )
	{
		this.key    = apikey;
		this.secret = apisecret;
	}
	
	this()
	{
		
	}
	
	bool PublicCall( string url,  ref Json result );
	bool PrivateMarketCall( string url, string quary, ref Json result, HTTPMethod method );

}	