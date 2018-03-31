module Currencies.Currency;

public import Utility.DataProxy;


class Currency
{
	string name;
	DataProxy dataProxy; 
	
	this ( string name )
	{
		this.name = name;
	}
	
	bool opEquals(ref const Currency rhs) { 
		return name == rhs.name;
	 }    
}

