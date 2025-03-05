import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/currency_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildThemeSection(context),
          _buildPreferencesSection(context),
        ],
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(
                    'Dark Mode',
                    style: GoogleFonts.poppins(),
                  ),
                  value: themeProvider.isDarkMode,
                  onChanged: (_) => themeProvider.toggleTheme(),
                  secondary: Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preferences',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Currency'),
              leading: const Icon(Icons.currency_exchange),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(currencyProvider.selectedCurrency),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              onTap: () => _showCurrencyPicker(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Currency',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: currencyProvider.currencySymbols.length,
                itemBuilder: (context, index) {
                  final currency = currencyProvider.currencySymbols.keys.elementAt(index);
                  final symbol = currencyProvider.currencySymbols[currency];
                  
                  return ListTile(
                    leading: Text(
                      symbol!,
                      style: const TextStyle(fontSize: 20),
                    ),
                    title: Text(currency),
                    trailing: currency == currencyProvider.selectedCurrency
                        ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () {
                      currencyProvider.changeCurrency(currency);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
