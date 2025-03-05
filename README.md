# Finance AI App

A comprehensive finance management application built with Flutter, featuring AI-powered insights, transaction tracking, and stock market monitoring.

## Features

### Core Features
- **Transaction Management**: Track income and expenses with categorization
- **Budget Planning**: Set and monitor budgets for different expense categories
- **Recurring Expenses**: Manage subscription and recurring payments
- **AI-Powered Financial Advice**: Get personalized financial recommendations
- **AI Predictions**: Forecast future expenses and savings
- **Bank Connection**: Connect to your bank accounts (simulated)
- **Loan Calculator**: Calculate loan payments and interest

### Stock Market Features
- **Stock Watchlist**: Add and track your favorite stocks
- **Real-Time Stock Data**: View current stock prices, changes, and key metrics
- **Market News**: Stay updated with the latest financial news
- **Stock Search**: Search for stocks by symbol or company name

## APIs Used
- **Alpha Vantage API**: For stock market data and financial news
- **Google Gemini API**: For AI-powered financial advice and predictions
- **Supabase**: For user authentication and data storage
- **Razorpay**: For payment processing (simulated)

## Getting Started

### Prerequisites
- Flutter SDK
- Dart SDK
- API Keys for:
  - Alpha Vantage
  - Google Gemini
  - Supabase
  - Razorpay

### Setup
1. Clone the repository
2. Create a `.env` file in the root directory with the following:
   ```
   GEMINI_API_KEY=your_gemini_api_key
   STOCK_API_KEY=your_alpha_vantage_api_key
   RAZORPAY_KEY_ID=your_razorpay_key_id
   RAZORPAY_KEY_SECRET=your_razorpay_key_secret
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the application

## Architecture
- **Provider**: For state management
- **Models**: For data structure
- **Services**: For API interactions
- **Screens**: For UI components
- **Widgets**: For reusable UI elements
