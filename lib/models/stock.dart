class Stock {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final double changePercent;
  final double open;
  final double high;
  final double low;
  final int volume;

  Stock({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
  });

  // Create a copy of this stock with updated values
  Stock copyWith({
    String? symbol,
    String? name,
    double? price,
    double? change,
    double? changePercent,
    double? open,
    double? high,
    double? low,
    int? volume,
  }) {
    return Stock(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      price: price ?? this.price,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      open: open ?? this.open,
      high: high ?? this.high,
      low: low ?? this.low,
      volume: volume ?? this.volume,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'price': price,
      'change': change,
      'changePercent': changePercent,
      'open': open,
      'high': high,
      'low': low,
      'volume': volume,
    };
  }

  // Create from JSON for retrieval
  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      price: json['price'] as double,
      change: json['change'] as double,
      changePercent: json['changePercent'] as double,
      open: json['open'] as double,
      high: json['high'] as double,
      low: json['low'] as double,
      volume: json['volume'] as int,
    );
  }
}
