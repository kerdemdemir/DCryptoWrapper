module Utility.Config;
 
public import Utility.Enums; 
public import std.datetime : SysTime;
 
bool IsDoubleSane( double val )
{
	return val < double.infinity && val != double.nan && val > 0.0;
}

struct PreciseDouble
{
	enum PRICE_EPSILON = 0.00000001;
	
    double val;
    size_t toHash() const
    {
		return cast(size_t)(this.val*(1.0/PRICE_EPSILON));
    }

    bool opEquals(ref const PreciseDouble rhs) const
    {
        return (rhs.val - this.val) < PRICE_EPSILON;
    }
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
	string[] blackListCurrencies;
	string   tradingCurrency;
	MarketType marketType;
} 
