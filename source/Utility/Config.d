module Utility.Conf;
 
public import Utility.Enums; 
 
bool IsDoubleSane( double val )
{
	return val < double.infinity && val != double.nan && val > 0.0;
}


class Config 
{
public:
	static Config singleton()
	{
		static Config instance;
		if ( !instance )
		{
			
			instance = new Config();
			instance.Init();
		}
 		return instance;
	}
	
	void Init()
	{
		tradingCurrency = "BTC";
	}
	
	void AddBlackListCurrencies(T)( T currencies )
	{
		blackListCurrencies =~ currencies;
	}
	
	void SetBlackListCurrencies(T)( T currencies )
	{
		blackListCurrencies = currencies;
	}	
	
	bool IsInBlackList( string name )
	{
		import std.algorithm : any;
		return blackListCurrencies.any!( a => a == name );
	}
	
	bool IsInBlackListOrMain( string name )
	{
		import std.algorithm : any;
		if ( name == tradingCurrency)
			return true;
		return blackListCurrencies.any!( a => a == name );
	}
	
	bool IsBinance ()
	{
		return  marketType == MarketType.BINANCE;
	}
	
	bool IsBittrex ()
	{
		return  marketType == MarketType.BITTREX;
	}
	
	string   apiSecret;
	string   apiKey;
	SysTime  loopStartTime;	
private:	

	string[] blackListCurrencies;
	string   tradingCurrency;
	MarketType marketType;
} 
