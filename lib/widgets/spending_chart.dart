import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/finance_provider.dart';

class SpendingChart extends StatefulWidget {
  const SpendingChart({super.key});

  @override
  _SpendingChartState createState() => _SpendingChartState();
}

class _SpendingChartState extends State<SpendingChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (ctx, financeData, _) {
        final categorySpending = financeData.getCategoryTotals();
        
        if (categorySpending.isEmpty) {
          return _buildEmptyChart();
        }

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spending by Category',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    touchedIndex = -1;
                                    return;
                                  }
                                  touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: _getSections(categorySpending),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildLegend(categorySpending),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending by Category',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pie_chart,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No spending data yet',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add transactions to see your spending chart',
                      style: TextStyle(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _getSections(Map<String, double> categorySpending) {
    final List<PieChartSectionData> sections = [];
    final List<Color> colors = [
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.red,
      Colors.pink,
      Colors.green,
      Colors.indigo,
      Colors.grey,
    ];

    int i = 0;
    categorySpending.forEach((category, amount) {
      final isTouched = i == touchedIndex;
      final double fontSize = isTouched ? 20 : 16;
      final double radius = isTouched ? 60 : 50;
      final Color color = colors[i % colors.length];

      sections.add(
        PieChartSectionData(
          color: color,
          value: amount,
          title: '',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      i++;
    });

    return sections;
  }

  List<Widget> _buildLegend(Map<String, double> categorySpending) {
    final List<Widget> legendItems = [];
    final List<Color> colors = [
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.red,
      Colors.pink,
      Colors.green,
      Colors.indigo,
      Colors.grey,
    ];

    int i = 0;
    final totalSpending = categorySpending.values.fold(0.0, (sum, amount) => sum + amount);

    categorySpending.forEach((category, amount) {
      final percentage = totalSpending > 0 ? (amount / totalSpending * 100).toStringAsFixed(1) : '0.0';
      final Color color = colors[i % colors.length];

      legendItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$category ($percentage%)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
      i++;
    });

    return legendItems;
  }
}
