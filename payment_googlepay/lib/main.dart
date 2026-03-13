import 'package:flutter/material.dart';
import 'package:pay/pay.dart'; // Import the pay plugin

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Pay Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const GooglePayScreen(),
    );
  }
}

class GooglePayScreen extends StatefulWidget {
  const GooglePayScreen({super.key});

  @override
  State<GooglePayScreen> createState() => _GooglePayScreenState();
}

class _GooglePayScreenState extends State<GooglePayScreen> {
  String _paymentStatus = 'No payment initiated.';

  // 1. Define your payment configuration
  // This JSON specifies payment methods, gateway, currency, etc.
  // IMPORTANT: For production, you'll replace "example" gateway with your actual gateway (e.g., "stripe", "braintree").
  // The "gatewayMerchantId" would be your actual merchant ID/publishable key.
  static const String _googlePayConfig = '''{
    "provider": "google_pay",
    "data": {
      "apiVersion": 2,
      "apiVersionMinor": 0,
      "allowedPaymentMethods": [
        {
          "type": "CARD",
          "parameters": {
            "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
            "allowedCardNetworks": ["AMEX", "VISA", "MASTERCARD", "DISCOVER", "JCB", "INTERAC", "MIR"]
          },
          "tokenizationSpecification": {
            "type": "PAYMENT_GATEWAY",
            "parameters": {
              "gateway": "example",
              "gatewayMerchantId": "exampleGatewayMerchantId"
            }
          }
        }
      ],
      "merchantInfo": {
        "merchantName": "My Awesome App",
        "merchantId": "01234567890123456789"
      },
      "transactionInfo": {
        "countryCode": "US",
        "currencyCode": "USD",
        "totalPriceStatus": "FINAL",
        "totalPrice": "10.00"
      },
      "shippingAddressRequired": false,
      "emailRequired": false
    }
  }''';

  // 2. Define the items for the payment sheet
  final List<PaymentItem> _paymentItems = [
    const PaymentItem(
      label: 'Total',
      amount: '10.00',
      status: PaymentItemStatus.final_price,
    ),
  ];

  // 3. Callback for payment result
  Future<void> onGooglePayResult(Map<String, dynamic> result) async {
    // This method is called when the Google Pay sheet closes.
    // The `result` map contains the payment token or error information.
    debugPrint('Google Pay Result: $result');

    if (result['paymentMethodData'] != null) {
      final token = result['paymentMethodData']['tokenizationData']['token'];
      debugPrint('Payment Token: $token');

      // IMPORTANT:
      // 1. Send this `token` to your secure backend server.
      // 2. Your backend server then uses a payment gateway (e.g., Stripe, Braintree)
      //    to charge the customer using this token.
      // 3. Your backend will then respond with the actual payment status.
      // 4. Update the UI based on the backend's response.

      setState(() {
        _paymentStatus = 'Payment token received! Sending to backend...';
      });

      // Simulate sending to a backend and getting a success response
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _paymentStatus = 'Payment successful! (Simulated)';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment successful!')));
    } else if (result['error'] != null) {
      setState(() {
        _paymentStatus = 'Payment failed: ${result['error']['message']}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${result['error']['message']}'),
        ),
      );
    } else {
      setState(() {
        _paymentStatus = 'Payment cancelled or unknown error.';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment cancelled.')));
    }
  }

  // 4. Check if Google Pay is available
  late final Future<PaymentConfiguration> _googlePayConfigFuture;

  @override
  void initState() {
    super.initState();
    _googlePayConfigFuture = Future.value(
      PaymentConfiguration.fromJsonString(_googlePayConfig),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Pay Integration')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FutureBuilder<PaymentConfiguration>(
              future: _googlePayConfigFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  return GooglePayButton(
                    paymentConfiguration: snapshot.data!,
                    paymentItems: _paymentItems,
                    onPaymentResult: onGooglePayResult,
                    // You can customize the button appearance
                    type: GooglePayButtonType.pay,
                    margin: const EdgeInsets.only(top: 15.0),
                    onPressed: () {
                      // Optional: Add custom logic before the payment sheet appears
                      debugPrint('Google Pay button pressed!');
                    },
                    childOnError: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Google Pay is not available on this device/region. This app requires Android with Google Play Services.',
                            ),
                          ),
                        );
                      },
                      child: const Text('Pay with Google Pay (Not Available)'),
                    ),
                    loadingIndicator: const CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error loading Google Pay config: ${snapshot.error}',
                          ),
                        ),
                      );
                    },
                    child: const Text('Error: Tap for details'),
                  );
                }
                return const CircularProgressIndicator();
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test button pressed! Google Pay may not be available on this platform.'),
                  ),
                );
              },
              child: const Text('Test Button (Always Visible)'),
            ),
            const SizedBox(height: 20),
            Text(
              _paymentStatus,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
