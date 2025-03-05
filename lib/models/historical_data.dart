class HistoricalData {
  final String date;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  HistoricalData({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory HistoricalData.fromJson(Map<String, dynamic> json) {
    return HistoricalData(
      date: json['date'] as String,
      open: json['open'] as double,
      high: json['high'] as double,
      low: json['low'] as double,
      close: json['close'] as double,
      volume: json['volume'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
    };
  }
}
