import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                context,
                'Getting Started',
                [
                  'Set your monthly income and budget in the Budget Summary section',
                  'Add your first transaction using the + button',
                  'Track your spending with the intuitive dashboard',
                ],
              ),
              _buildSection(
                context,
                'Managing Transactions',
                [
                  'Add regular expenses or income with the + button',
                  'Set up recurring payments for bills and subscriptions',
                  'View transaction history with detailed breakdowns',
                  'Edit or delete transactions by tapping on them',
                  'Categorize transactions for better tracking',
                ],
              ),
              _buildSection(
                context,
                'Budget Management',
                [
                  'View your budget overview in the Budget Summary card',
                  'Track remaining budget and total expenses',
                  'Get warnings when approaching budget limits',
                  'Update your budget anytime by tapping the Budget Summary',
                  'Monitor recurring expenses impact on your budget',
                ],
              ),
              _buildSection(
                context,
                'Spending Analytics',
                [
                  'View spending breakdown by category in the pie chart',
                  'Track your top spending categories',
                  'Monitor monthly spending trends',
                  'Get insights on your financial habits',
                ],
              ),
              _buildSection(
                context,
                'AI Financial Advisor',
                [
                  'Get personalized financial advice based on your spending',
                  'Receive predictions about future expenses',
                  'Get suggestions for budget optimization',
                  'Ask specific questions about your finances',
                ],
              ),
              _buildSection(
                context,
                'Currency Management',
                [
                  'Change your preferred currency',
                  'Automatic currency conversion for transactions',
                  'View amounts in multiple currencies',
                ],
              ),
              _buildSection(
                context,
                'Bank Integration',
                [
                  'Connect your bank account securely',
                  'Process payments using RazorPay',
                  'View connected bank account details',
                ],
              ),
              _buildSection(
                context,
                'App Settings',
                [
                  'Toggle between light and dark mode',
                  'Update your profile information',
                  'Manage notification preferences',
                  'Sign out from your account',
                ],
              ),
              _buildSection(
                context,
                'Need More Help?',
                [
                  'Contact our support team using the Feedback button',
                  'Visit our documentation for detailed guides',
                  'Join our community forum for tips and discussions',
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 8),
      ],
    );
  }
}
