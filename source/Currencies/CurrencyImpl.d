module Currencies.CurrencyImpl;

import Currencies.Currency;

import vibe.core.log;
import vibe.http.client;
import vibe.stream.operations;
import std.algorithm;
import std.container : DList;
import std.range;


class Currency : ICurrency
{
	string name;
	string longName;
	AnalyzeData analyzeData;
	TimeData     timeData;
    FinalizeData finalizeData;
    QuantityData quantityData;   
    IRules     ruleList;
	PriorityEnum priority = PriorityEnum.NO_PRIORITY;
    DList!Json  logMessages;
    Json      lastLogInJson;
	Json      maxLogJson;
	Json      minLogJson;
	
	this()
	{
		ruleList = new RuleList();
	}

	string ToString()
	{
		return " Time: " ~ Config.singleton().loopStartTime.toString() ~ " " ~ analyzeData.ToString()  ~ 
				" " ~ finalizeData.ToString() ~ "\n";
	}

	Json ToJson()
	{
		auto json = analyzeData.serializeToJson();
		json["finalizeData"] = finalizeData.serializeToJson();
		json["time"] = Config.singleton().loopStartTime.toString();
		return json;
	}

 	string GetLog()
 	{
 		Json jsonArray = Json.emptyArray();
 		foreach( json ; logMessages)
	 		jsonArray ~= json;
	 	return jsonArray.toPrettyString();	   
 	}

	string        GetLastLog()
	{
		return logMessages.back.toPrettyString();	 
	}

	void          SetBuyData()
	{
		lastLogInJson = logMessages.back();
	}

	
	ref Json          GetBuyData()
	{
		return lastLogInJson;
	}

	ref Json          GetLastData()
	{
		return logMessages.back;
	}
	
	ref PriorityEnum  GetPriority()
	{
		return priority;
	}

	TimeData*     GetTimeData()
	{
		return &timeData;
	}

	AnalyzeData* GetAnalyzeData()
	{
		return &analyzeData; 
	}
	
	void	UpdateTick(ref const TickData data)
	{	
		analyzeData.prevTickData =  analyzeData.tickData;
		analyzeData.tickData = data;
		if ( analyzeData.tickData.IsValid() )
		{
			analyzeData.recieverName = name;
			analyzeData.txName = Config.singleton().tradingCurrency;
		}
		auto json = ToJson();
		if ( analyzeData.tickData.ask >= analyzeData.maxBid && analyzeData.maxBid > 0.0 )
			maxLogJson = json;
			
		if ( analyzeData.tickData.ask <= analyzeData.minGlobalBid )
		{
			analyzeData.minGlobalBid = analyzeData.tickData.ask;
			timeData.buyStartTime = Config.singleton().loopStartTime;
			minLogJson = json;	
		}
		else
		{
			auto seconds =  (Config.singleton().loopStartTime - GetTimeData().buyStartTime).total!"seconds";
			if ( seconds > 300 )
				analyzeData.minGlobalBid = double.max; 
		}
					
			
		ruleList.Update(json);
		logMessages.insert(json);
		if ( walkLength(logMessages[]) > 300 )
			logMessages.removeFront();
		
		
			
	}
	
	ref Json  GetMaxData()
	{
		return maxLogJson;
	}

	ref Json   GetMinData()
	{
		return minLogJson;
	}
	
	FinalizeData* GetFinalizeData( )
	{
		return &finalizeData;
	}
	
	QuantityData* GetQuantityData( )
	{
		return &quantityData;
	}
	
	string        GetName() const
	{
		return name;
	}

	void SetCurrency( string nameParam, string longNameParam, RuleEnum[] rules )
	{
		if ( name.empty() )
		{
			name = nameParam;         
			longName = longNameParam;
			ruleList.Register( rules, name );
		}
	}
	
	IRules*       GetRules()
	{
		return &ruleList;
	}
}

