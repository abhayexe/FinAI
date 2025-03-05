import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/finance_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/currency_provider.dart';
import 'providers/stock_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/subscription_provider.dart';
import 'services/gemini_service.dart';
import 'services/supabase_service.dart';
import 'services/stripe_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  // Initialize Stripe
  try {
    await StripeService.initialize();
  } catch (e) {
    debugPrint('Error initializing Stripe: $e');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) => FinanceProvider(GeminiService()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => CurrencyProvider(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => StockProvider(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => ChatProvider(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => SubscriptionProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Finance AI',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.theme,
            home: SupabaseService.isAuthenticated ? HomeScreen() : AuthScreen(),
          );
        },
      ),
    );
  }
}
