module Currencies.CurrencyList;

import Currencies.Currency;
import Currencies.CurrencyImpl;

import std.algorithm;

class CurrencyList
{
	ICurrency[string] currencyList;
	SysTime lastLogTime;
	
	this ( ICurrency[] list )
	{
		foreach ( currency; list )
			currencyList[ currency.GetName() ] = currency; 	 
	} 
	
	this ( ICurrency elem )
	{
		currencyList[ elem.GetName() ] = elem; 
	}
	
	this()
	{
		
	}
		
	void InitBittrexCurrency( Json currencyData  )
	{
		string name = currencyData["MarketCurrency"].get!string;
		string longName =	currencyData["MarketCurrencyLong"].get!string;
		ICurrency *p = (name in currencyList);
		auto list = [ RuleEnum.FastRiseCheck, RuleEnum.BidAskRatio, RuleEnum.RiseTime ] ;
		if (p !is null)
		{
			p.SetCurrency( name, longName, list);
		}
		else 
		{
			ICurrency currency = new Currency();
			currency.SetCurrency( name, longName, list);
			currencyList[name] = currency;
		}
	}
	
	void InitHitBTCCurrency( Json currencyData  )
	{
		string id = currencyData["id"].get!string;
		string fullName =	currencyData["fullName"].get!string;
		ICurrency *p = ( id in currencyList );
		auto list = [ RuleEnum.BuyVsSellWall, RuleEnum.TotalVsSellWall, RuleEnum.TotalVsLongSellWall, RuleEnum.TransactionCount, RuleEnum.TotalLimit, RuleEnum.BuyWallLimit,
		  RuleEnum.TransactionCountBuyRatio, RuleEnum.DropTrendCheck, RuleEnum.FakeRiseCheck, RuleEnum.BuyWallLimitForSelling, RuleEnum.TradeAndOrderBadForSelling, 
		  RuleEnum.BuyWallWithBuyRatioForSelling, RuleEnum.TotalVsBuyRatio ] ;
		if (p !is null)
		{
			p.SetCurrency( id, fullName, list);
		}
		else 
		{
			ICurrency currency = new Currency();
			currency.SetCurrency( id, fullName, list);
			currencyList[id] = currency;
		}
	}
	
	void InitBinanceCurrency( string id  )
	{
		auto list = [ RuleEnum.BuyVsSellWall, RuleEnum.TotalVsSellWall, RuleEnum.TotalVsLongSellWall, RuleEnum.TransactionCount, RuleEnum.TotalLimit, RuleEnum.BuyWallLimit,
		  RuleEnum.TransactionCountBuyRatio, RuleEnum.DropTrendCheck, RuleEnum.FakeRiseCheck, RuleEnum.BuyWallLimitForSelling, RuleEnum.TradeAndOrderBadForSelling, 
		  RuleEnum.BuyWallWithBuyRatioForSelling, RuleEnum.TotalVsBuyRatio ] ;
		ICurrency *p = ( id in currencyList );
		if (p !is null)
		{
			p.SetCurrency( id, id, list);
		}
		else 
		{
			ICurrency currency = new Currency();
			currency.SetCurrency( id, id, list );
			currencyList[id] = currency;
		}
	}
	
	ICurrency[] GetWithPriority( PriorityEnum priority )
	{
		return currencyList.values.filter!( a => a.GetPriority() == priority).array();
	}
	
	ICurrency GetWithMarketName( string marketName )
	{
		auto txName = marketName.split('-')[0];
		if ( txName != Config.singleton().tradingCurrency )
			return null;
		string currencyName = marketName.split('-')[1];
		return GetWithName(currencyName);
	}
	
	ICurrency GetWithSymbolName( string symbolName )
	{
		if ( symbolName.length < 3 || symbolName[$-3..$] != Config.singleton().tradingCurrency )
			return null;
		string currencyName = symbolName[0..$-3];
		return GetWithName(currencyName);
	}
	
	ICurrency GetWithName( string currencyName )
	{
		if ( currencyName in currencyList )
			return currencyList[currencyName];
		return null;
	}



	void Update()
	{
		auto curTime =  Config.singleton().loopStartTime;
		if ( (curTime - lastLogTime ) > 10.seconds )
		{
			lastLogTime = curTime;
			ICurrency[] list = currencyList.values.filter!(a => a.GetQuantityData().IsOwnedExists() ).array();
			char[] ownedStr;
			foreach( currency; list)
			{
				if ( Config.singleton().IsInBlackList(currency.GetName())	)
					continue;
				string namePlusVal = " " ~ currency.GetName() ~ " " ~  currency.GetQuantityData().ToString();
				ownedStr ~= namePlusVal;
			}
			writeln("TimeStamp: ", lastLogTime.toString(), ownedStr ); 
		}
	}
}

