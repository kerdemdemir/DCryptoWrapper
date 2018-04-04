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
		prevTick = tick;
		tick = data;		
	}
	
    string ToString()
    {
    	return " Tick: " ~ tick.ToString() ~ " Prev Tick: " ~ prevTick.ToString() ~ 
		       " HistoryData: " ~ historyData.ToString() ~ " OrderBook: " ~ orderData.ToString() ~
		       " TradeData: " ~ tradeData.ToString() ~ " QuantityData: " ~ quantityData.ToString();
    }
}

