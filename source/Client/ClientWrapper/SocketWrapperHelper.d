module Client.ClientWrapper.SocketWrapperHelper;

public import Utility.DataProxy;
import std.datetime;
import vibe.data.json;
import std.container.dlist;


HistoryData CalculateHistoryDataFromJson( Json inData, Duration duration )
{
	HistoryData data;
	long startDate;
	for ( int i = 0; i < inData.length; i++ )
	{
		long date = inData[i]["T"].to!long / 1000 ;
		if ( i == 0)
			startDate = date;
		Duration tempDuration = (startDate - date ).seconds;
		if ( tempDuration > duration  )
			break;	
		
		data.transactionCount += 1;
		double quantity = inData[i]["q"].to!double;
		double price = inData[i]["p"].to!double;
		double curPower = quantity*price;
		data.total += curPower;
		if ( !inData[i]["m"].to!bool ) 
		{
			data.buyCount++;
			data.totalBuy += curPower;
		}			
  	}
	return data;	
}

HistoryData CalculateHistoryDataFromJson( DList!(Json)* inData, Duration duration )
{
	HistoryData data;
	long startDate;
	auto range = (*inData)[];
	int i = 0;
	foreach ( jsonData; range )
	{
		long date = jsonData["T"].to!long / 1000 ;
		if ( i++ == 0)
			startDate = date;
		Duration tempDuration = (startDate - date).seconds;
		if ( tempDuration > duration  )
			break;	
		
		data.transactionCount += 1;
		double quantity = jsonData["q"].to!double;
		double price = jsonData["p"].to!double;
		double curPower = quantity*price;
		data.total += curPower;
		if ( !jsonData["m"].to!bool ) 
		{
			data.buyCount++;
			data.totalBuy += curPower;
		}			
  	}
	return data;	
}

class OrderBookSocketHelper
{
public:
	
	void Process( Json data )
    {
    	Json bids = data["b"];
    	Json asks = data["a"];
    	
    	ApplyToMap( orderBookBid, bids );
    	ApplyToMap( orderBookAsks, asks );

    }
    
    double CalculatePower( double ratioFromFirst, bool isBid )
    {
    	import std.algorithm;
    	import std.array;
    	double[PreciseDouble] bidOrAskMap = isBid ? orderBookBid : orderBookAsks;
    	auto keys = bidOrAskMap.keys().sort!( (a,b) => isBid ?  a.val > b.val : a.val < b.val );
    	double firstVal = keys.front().val;
    	double stopVal = firstVal * ratioFromFirst;
    	auto doubleRange = keys.filter!( a=> isBid ? a.val > stopVal
    		                                       : a.val < stopVal).map!( a=> a.val);
    	double result = doubleRange.fold!( (a,b) => a + CalculatePowerForKey(b, bidOrAskMap) )(0.0);  
	    return result;
    }
    
    void CalculateWithRawJson( ref Json data )
    {
 		auto askJson = data["asks"];
 		auto bidJson = data["bids"];
	 		 	
 		InsertRawJson( orderBookAsks, askJson);
 		InsertRawJson( orderBookBid, bidJson);
    }
    
private:

	void InsertRawJson( ref double[PreciseDouble] mapParam, ref Json json)
	{
		import std.stdio : writeln;
			
		if ( json.type() != Json.Type.array )
		{
			writeln(" Initing array is not possible with this json which is not array " );
			return;
		}
		for ( int i = 0; i < json.length; i++ )
		{
			double rate= json[i][0].to!double;
			double quantity  = json[i][1].to!double;
			PreciseDouble key = PreciseDouble(rate);
			mapParam[key] = quantity;
		}		
	}

	double CalculatePowerForKey( double keyVal, ref double[PreciseDouble] mapParam)
	{
		PreciseDouble key = PreciseDouble(keyVal);
		double* result =  key in mapParam;
		if ( !result )
		{
			return 0.0;
		}
		return (*result)*keyVal;
	}
    
    void ApplyToMap( ref double[PreciseDouble] map, Json data )
    {
    	import std.math : approxEqual;
    	
  		for ( int i = 0; i < data.length; i++ )
		{
			double price = data[i][0].to!double();
			double quantity = data[i][1].to!double();
			PreciseDouble curVal = PreciseDouble(price);
			if ( approxEqual(quantity, 0.0) )
			{
				map.remove(curVal);
			}
			else 
			{
				map[curVal]	 = quantity;		
			}
		}		  	
    }
    
	double[PreciseDouble] orderBookAsks;
	double[PreciseDouble] orderBookBid;
}

