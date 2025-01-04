import 'package:flutter/material.dart';

class UdhaarPaymentReportPage extends StatelessWidget {
  final String customerName;
  final String customerPhone;
  final String paymentMethod;

  UdhaarPaymentReportPage({
    required this.customerName,
    required this.customerPhone,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Report - $paymentMethod'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Name: $customerName',
              style: TextStyle(fontSize: 18, color: Colors.teal.shade800),
            ),
            SizedBox(height: 8),
            Text(
              'Customer Phone: $customerPhone',
              style: TextStyle(fontSize: 16, color: Colors.teal.shade600),
            ),
            SizedBox(height: 16),
            Text(
              'Payment Method: $paymentMethod',
              style: TextStyle(fontSize: 16, color: Colors.teal.shade800),
            ),
            // Additional content specific to Udhaar (Credit) payment type can be added here.
            Expanded(
              child: Center(
                child: Text(
                  'Details of the Udhaar payment report...',
                  style: TextStyle(color: Colors.teal.shade600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
