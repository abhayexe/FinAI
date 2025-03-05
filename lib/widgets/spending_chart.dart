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
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: Center(
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
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16.0,
                  runSpacing: 8.0,
                  children: _buildLegend(categorySpending),
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
                color: Theme.of(context).textTheme.titleLarge?.color,
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
                      color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[400] 
                        : Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No spending data yet',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add transactions to see your spending chart',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
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
      Colors.orange.shade400,
      Colors.blue.shade400,
      Colors.purple.shade400,
      Colors.red.shade400,
      Colors.pink.shade400,
      Colors.green.shade400,
      Colors.indigo.shade400,
      Colors.grey.shade400,
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
      Colors.orange.shade400,
      Colors.blue.shade400,
      Colors.purple.shade400,
      Colors.red.shade400,
      Colors.pink.shade400,
      Colors.green.shade400,
      Colors.indigo.shade400,
      Colors.grey.shade400,
    ];

    int i = 0;
    final totalSpending = categorySpending.values.fold(0.0, (sum, amount) => sum + amount);

    categorySpending.forEach((category, amount) {
      final percentage = totalSpending > 0 ? (amount / totalSpending * 100).toStringAsFixed(1) : '0.0';
      final Color color = colors[i % colors.length];

      legendItems.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey[800] 
              : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$category',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(0.9),
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
