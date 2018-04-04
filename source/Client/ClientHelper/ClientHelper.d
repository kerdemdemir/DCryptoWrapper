module Client.ClientHelper.ClientHelper;

public import vibe.data.json;
public import vibe.http.common : HTTPMethod;
public import std.string;

struct KeySecretStruct
{
	string key;
	string secret;
	
	this( string apikey, string apisecret )
	{
		SetKeyAndSecret( apikey, apisecret );
	}
	
	void SetKeyAndSecret( string apikey, string apisecret )
	{
		this.key    = apikey;
		this.secret = apisecret;
	}

}	