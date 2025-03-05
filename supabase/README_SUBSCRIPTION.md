# Subscription Feature Setup

This document provides instructions for setting up and configuring the subscription feature in the Finance AI App.

## Overview

The subscription feature allows users to purchase a premium plan that includes:
- Access to a real financial advisor (2 hours daily for 1 month)
- Advanced AI model for financial predictions and assistance
- Detailed portfolio analysis and custom investment strategies

## Database Setup

1. Run the following SQL script in your Supabase SQL Editor to create the necessary tables and policies:

```sql
-- Create or replace the setup_subscription_table.sql script
```

You can find this script in the `supabase/setup_subscription_table.sql` file.

## Demo Payment Setup

The app includes a demo payment screen that simulates the payment process without actually charging users. This is useful for testing and demonstration purposes.

### How the Demo Payment Works

1. When a user clicks "Subscribe Now" on the subscription screen, they are taken to a payment screen.
2. The payment screen displays a form with pre-filled test card details.
3. When the user clicks "Pay", the app simulates a payment process and creates a subscription record in the database.
4. No actual payment is processed, but the user gets full access to premium features.

### Test Card Details (Pre-filled)

- Card Number: 4242 4242 4242 4242
- Expiry Date: 12/25
- CVV: 123
- Cardholder Name: Test User

## Stripe Configuration

1. Create a Stripe account if you don't have one already.
2. Get your Stripe API keys (publishable key and secret key) from the Stripe Dashboard.
3. Add these keys to your `.env` file:

```
STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key
STRIPE_SECRET_KEY=your_stripe_secret_key
```

4. For Android, ensure you have the internet permission in your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

5. For iOS, no additional configuration is needed.

## Testing the Subscription

1. For testing purposes, you can use the demo payment screen which is pre-filled with test card details.
2. Alternatively, if you want to test the actual Stripe integration, you can use Stripe's test cards:
   - Card number: `4242 4242 4242 4242`
   - Expiry date: Any future date
   - CVC: Any 3 digits
   - ZIP: Any 5 digits

3. When testing, the app will use Stripe's test mode, which doesn't process real payments.

## Troubleshooting

### Common Issues

1. **Payment fails to process**:
   - Check that your Stripe API keys are correctly set in the `.env` file.
   - Ensure you're using a valid test card number for testing.
   - Check the logs for any specific error messages from Stripe.

2. **Subscription not showing as active after payment**:
   - Verify that the subscription was properly saved to the Supabase database.
   - Check if there are any errors in the app logs during the payment process.
   - Ensure that the RLS policies are correctly set up in Supabase.

3. **Premium features not accessible after subscription**:
   - Make sure the app is correctly checking the subscription status.
   - Verify that the subscription has not expired.
   - Check if the subscription record in the database has `is_active` set to `true`.

## Production Deployment

Before deploying to production:

1. Replace the test Stripe API keys with your production keys.
2. Thoroughly test the subscription flow in a staging environment.
3. Implement proper error handling and recovery mechanisms for payment failures.
4. Consider adding webhook support for handling Stripe events (payment succeeded, payment failed, etc.).
