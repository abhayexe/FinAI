import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class StockChart extends StatefulWidget {
  final List<Map<String, dynamic>> historicalData;
  final String symbol;
  final Color lineColor;
  
  const StockChart({
    super.key,
    required this.historicalData,
    required this.symbol,
    this.lineColor = Colors.blue,
  });

  @override
  _StockChartState createState() => _StockChartState();
}

class _StockChartState extends State<StockChart> {
  int _selectedTimeRange = 30; // Default to 30 days
  late List<Map<String, dynamic>> _filteredData;
  
  @override
  void initState() {
    super.initState();
    _filterData();
  }
  
  @override
  void didUpdateWidget(StockChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.historicalData != widget.historicalData) {
      _filterData();
    }
  }
  
  void _filterData() {
    if (widget.historicalData.isEmpty) {
      _filteredData = [];
      return;
    }
    
    // Sort by date (oldest first for the chart)
    final sortedData = List<Map<String, dynamic>>.from(widget.historicalData)
      ..sort((a, b) => a['date'].compareTo(b['date']));
    
    // Take only the last X days based on selected range
    if (sortedData.length > _selectedTimeRange) {
      _filteredData = sortedData.sublist(sortedData.length - _selectedTimeRange);
    } else {
      _filteredData = sortedData;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_filteredData.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No chart data available',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Ensure we have enough data points for the chart
    if (_filteredData.length < 2) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Not enough data points for chart',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    try {
      final minY = _filteredData.map((e) => e['low'] as double).reduce((a, b) => a < b ? a : b) * 0.98;
      final maxY = _filteredData.map((e) => e['high'] as double).reduce((a, b) => a > b ? a : b) * 1.02;
      
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.symbol,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildTimeRangeSelector(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${_filteredData.last['close'].toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getChangeColor(),
                  ),
                ),
                _buildChangeIndicator(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0, left: 8.0),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY - minY) / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: _getDateInterval(),
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < 0 || value.toInt() >= _filteredData.length) {
                            return const SizedBox();
                          }
                          
                          final date = DateTime.parse(_filteredData[value.toInt()]['date']);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('MM/dd').format(date),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (maxY - minY) / 5,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              '\$${value.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  minX: 0,
                  maxX: _filteredData.length.toDouble() - 1,
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getSpots(),
                      isCurved: true,
                      color: widget.lineColor,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(
                        show: false,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: widget.lineColor.withOpacity(0.2),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.black.withOpacity(0.8),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((touchedSpot) {
                          final index = touchedSpot.x.toInt();
                          final data = _filteredData[index];
                          final date = DateTime.parse(data['date']);
                          
                          return LineTooltipItem(
                            '${DateFormat('MMM dd, yyyy').format(date)}\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: 'Open: \$${data['open'].toStringAsFixed(2)}\n',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              TextSpan(
                                text: 'Close: \$${data['close'].toStringAsFixed(2)}\n',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              TextSpan(
                                text: 'High: \$${data['high'].toStringAsFixed(2)}\n',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              TextSpan(
                                text: 'Low: \$${data['low'].toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } catch (e) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading chart data',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
  
  List<FlSpot> _getSpots() {
    final spots = <FlSpot>[];
    
    for (int i = 0; i < _filteredData.length; i++) {
      spots.add(FlSpot(i.toDouble(), _filteredData[i]['close']));
    }
    
    return spots;
  }
  
  double _getDateInterval() {
    if (_filteredData.length <= 7) {
      return 1;
    } else if (_filteredData.length <= 30) {
      return 5;
    } else {
      return 7;
    }
  }
  
  Color _getChangeColor() {
    if (_filteredData.length < 2) return Colors.grey;
    
    final firstClose = _filteredData.first['close'] as double;
    final lastClose = _filteredData.last['close'] as double;
    
    return lastClose >= firstClose ? Colors.green : Colors.red;
  }
  
  Widget _buildChangeIndicator() {
    if (_filteredData.length < 2) return const SizedBox();
    
    final firstClose = _filteredData.first['close'] as double;
    final lastClose = _filteredData.last['close'] as double;
    
    final change = lastClose - firstClose;
    final changePercent = (change / firstClose) * 100;
    
    final isPositive = change >= 0;
    
    return Row(
      children: [
        Icon(
          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
          color: isPositive ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          '${isPositive ? '+' : ''}${change.toStringAsFixed(2)} (${changePercent.toStringAsFixed(2)}%)',
          style: TextStyle(
            color: isPositive ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildTimeRangeSelector() {
    return Row(
      children: [
        _timeRangeButton(7, '1W'),
        _timeRangeButton(30, '1M'),
        _timeRangeButton(90, '3M'),
        _timeRangeButton(180, '6M'),
        _timeRangeButton(365, '1Y'),
      ],
    );
  }
  
  Widget _timeRangeButton(int days, String label) {
    final isSelected = _selectedTimeRange == days;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeRange = days;
          _filterData();
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? widget.lineColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? widget.lineColor : Colors.grey,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
