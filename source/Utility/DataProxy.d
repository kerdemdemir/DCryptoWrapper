module Utility.DataProxy;

public import Utility.Data;

 
struct DataProxy
{
	TickData tick;
	TickData prevTick;
	HistoryData historyData;
	OrderBook orderData;
	TradeData tradeData;
	QuantityData quantityData;
	
	void UpdateTick( ref const TickData data)
	{
		analyzeData.prevTickData =  analyzeData.tickData;
		analyzeData.tickData = data;		
	}
	
    string ToString()
    {
    	return " Tick: " ~ ToString(tick) ~ " Prev Tick: " ~ to!string(prevTick) ~ 
		       " HistoryData: " ~ ToString(historyData) ~ " OrderBook: " ~ to!string(orderData) ~
		       " TradeData: " ~ ToString(tradeData) ~ " QuantityData: " ~ to!string(quantityData);
    }
}

