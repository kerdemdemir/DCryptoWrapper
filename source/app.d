import std.stdio;
import Client.BittrexClient;
import Client.BinanceClientHelper;
import std.datetime;

void main()
{
//	auto bittrexClient = new BittrexClient();
//	
//	//  **************** Gecmis Islemler Cagrisi (History Call) *************** / 
//	// Asagidaki cagri son 30 saniye icinde yapilan hacmi gosteriyor. Ve ekrana sunu yazdiriyor 
//	// "ETH History data:  Total BTC traded : 0.482065 Total Buys BTC: 0.471851 Transacrion count: 10 Buy count: 9"
//	// Bir alis veris iki sekilde olabilir. Elma(Bu ornekte elma ETH'a denk geliyor) satmaya calisan biri 11 liraya(Lira ise BTC'ye) 
//	//satmak ister. Fakat almak isteyenler buna yanasmayip 9 lira vermek isteyebilirler. 
//	// Asagida 0.482 BTC hacmi toplam 9 liraya satanlar ve 11 Liraya alanlari iceriyor. 0.471 ise sadece 11 Liraya alanlari iceriyor.
//	// Satis fiyatindan islem gorulmesi bu marketin yukselicegi manasina gelebilir. Bunun yani sira 10 islem olduğu ve bunlarin 9'unun 
//	// satis fiyatindan islem gordugu belirtiliyor. 
//	
//	// This call prints that:  
//	// "ETH History data:  Total BTC traded : 0.482065 Total Buys BTC: 0.471851 Transacrion count: 10 Buy count: 9"
//	// which means in last 30 seconds 0.482 BTC traded. 0.471 BTC was bought in ask price ,
//	// You can think sellers of apple wants to sell apples(apples are ETH in this case) for 11 Liras(Liras are BTC in theses case) and buyers want to buy for 9 liras 
//	// 0.482 below is the total trade which include both apples sold for 11 Liras and 9 Liras. 0.471 is the apples bought for 11 Liras. The ratio of buyers might indicate a bullish market. 
//	bittrexClient.GetMarketHistory( "ETH", "BTC", 30.seconds );  
//	// "ETH History data:  Total BTC traded : 0.482065 Total Buys BTC: 0.471851 Transacrion count: 10 Buy count: 9"
//	//  **************** Yorum sonu (End of comment ) *************** / 
	
	//SocketCall();

}
