import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/theme_provider.dart';
import 'payment_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    await subscriptionProvider.checkSubscription();
  }

  Future<void> _purchaseSubscription() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaymentScreen()),
    );
    
    if (result == true) {
      // Payment was successful, show success message
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription purchased successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final hasSubscription = subscriptionProvider.hasSubscription;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Premium Subscription',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: subscriptionProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasSubscription) ...[
                      _buildActiveSubscriptionCard(context, subscriptionProvider),
                      const SizedBox(height: 24),
                      _buildSubscriptionFeatures(context, isDark),
                    ] else ...[
                      _buildSubscriptionCard(context, isDark),
                      const SizedBox(height: 24),
                      _buildSubscriptionFeatures(context, isDark),
                      const SizedBox(height: 24),
                      _buildPurchaseButton(context),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActiveSubscriptionCard(BuildContext context, SubscriptionProvider provider) {
    final remainingDays = provider.remainingDays;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified,
                  color: Colors.green,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'Active Subscription',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Premium Financial Advisor Plan',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your subscription is active for $remainingDays more days',
              style: GoogleFonts.poppins(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Expires on: ${provider.subscriptionEndDate?.day}/${provider.subscriptionEndDate?.month}/${provider.subscriptionEndDate?.year}',
                style: GoogleFonts.poppins(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Premium Financial Advisor',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.amber.shade800 : Colors.amber.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Limited Time Offer',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '299',
                  style: GoogleFonts.poppins(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              'per month',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Unlock premium features and get personalized financial advice',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionFeatures(BuildContext context, bool isDark) {
    final features = [
      {
        'icon': Icons.person,
        'title': 'Real Financial Advisor',
        'description': 'Talk to a certified financial advisor for 2 hours daily',
      },
      {
        'icon': Icons.calendar_month,
        'title': '30 Days Access',
        'description': 'Full month of premium support and guidance',
      },
      {
        'icon': Icons.smart_toy,
        'title': 'Advanced AI Assistant',
        'description': 'Get insights from our most advanced AI model',
      },
      {
        'icon': Icons.analytics,
        'title': 'Detailed Portfolio Analysis',
        'description': 'In-depth analysis of your investments',
      },
      {
        'icon': Icons.trending_up,
        'title': 'Custom Investment Strategies',
        'description': 'Personalized strategies based on your goals',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s Included',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...features.map((feature) => _buildFeatureItem(
              context,
              icon: feature['icon'] as IconData,
              title: feature['title'] as String,
              description: feature['description'] as String,
              isDark: isDark,
            )),
      ],
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.amber.shade800.withOpacity(0.2) : Colors.amber.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.amber.shade400 : Colors.amber.shade800,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _purchaseSubscription,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'Subscribe Now',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
