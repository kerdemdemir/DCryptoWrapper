module Currencies.CurrencyList;

public import Currencies.Currency;
public import Utility.Config;

struct CurrencyList
{
	Currency[] currencyList;
	
	this ( Currency[] list )
	{
		currencyList ~= list;
	} 
	
	this ( Currency elem )
	{
		currencyList ~= elem; 
	}
	
	void InitCurrency( string name )
	{
		Currency currency = GetWithName( name );
		if ( currency is null )
		{
			currency = new Currency(name);
			currencyList ~= currency;
		}
	}	
	
	Currency GetWithMarketName( string marketName )
	{
		auto txName = marketName.split('-')[0];
		if ( txName != Config.singleton().tradingCurrency )
			return null;
		string currencyName = marketName.split('-')[1];
		return GetWithName(currencyName);
	}
	
	Currency GetWithSymbolName( string symbolName )
	{
		if ( symbolName.length < 3 || symbolName[$-3..$] != Config.singleton().tradingCurrency )
			return null;
		string currencyName = symbolName[0..$-3];
		return GetWithName(currencyName);
	}
	
	Currency GetWithName( string currencyName )
	{
		import std.algorithm : canFind;
		import std.algorithm : find;
		import std.range;
		
		if ( currencyList.canFind(currencyName) )
			return currencyList.find(currencyName).front;
		return null;
	}
}

