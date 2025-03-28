# Finance AI App

A comprehensive finance management application built with Flutter, featuring AI-powered insights, transaction tracking, and stock market monitoring.

## Screenshots

Below are some screenshots of the Finance AI (FinAI) application showcasing its features:

<table>
  <tr>
    <td><img src="screenshots/ss1.jpeg" alt="Screenshot 1" width="200"></td>
    <td><img src="screenshots/ss2.jpeg" alt="Screenshot 2" width="200"></td>
    <td><img src="screenshots/ss3.jpeg" alt="Screenshot 3" width="200"></td>
    <td><img src="screenshots/ss4.jpeg" alt="Screenshot 4" width="200"></td>
  </tr>
  <tr>
    <td><img src="screenshots/ss5.jpeg" alt="Screenshot 5" width="200"></td>
    <td><img src="screenshots/ss6.jpeg" alt="Screenshot 6" width="200"></td>
    <td><img src="screenshots/ss7.jpeg" alt="Screenshot 7" width="200"></td>
    <td><img src="screenshots/ss8.jpeg" alt="Screenshot 8" width="200"></td>
  </tr>
  <tr>
    <td><img src="screenshots/ss9.jpeg" alt="Screenshot 9" width="200"></td>
    <td><img src="screenshots/ss10.jpeg" alt="Screenshot 10" width="200"></td>
    <td><img src="screenshots/ss11.jpeg" alt="Screenshot 11" width="200"></td>
    <td><img src="screenshots/ss12.jpeg" alt="Screenshot 12" width="200"></td>
  </tr>
  <tr>
    <td><img src="screenshots/ss13.jpeg" alt="Screenshot 13" width="200"></td>
    <td><img src="screenshots/ss14.jpeg" alt="Screenshot 14" width="200"></td>
    <td><img src="screenshots/ss15.jpeg" alt="Screenshot 15" width="200"></td>
    <td><img src="screenshots/ss16.jpeg" alt="Screenshot 16" width="200"></td>
  </tr>
  <tr>
    <td><img src="screenshots/ss17.jpeg" alt="Screenshot 17" width="200"></td>
    <td><img src="screenshots/ss18.jpeg" alt="Screenshot 18" width="200"></td>
    <td><img src="screenshots/ss19.jpeg" alt="Screenshot 19" width="200"></td>
    <td><img src="screenshots/ss20.jpeg" alt="Screenshot 20" width="200"></td>
  </tr>
</table>

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
