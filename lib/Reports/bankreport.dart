import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Provider/invoice provider.dart';

class OnlineBankTransferReportPage extends StatelessWidget {
  final String customerName;
  final String customerPhone;
  final String paymentMethod;

  OnlineBankTransferReportPage({
    required this.customerName,
    required this.customerPhone,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    // Fetch invoices filtered by payment method (Online Bank Transfer)
    final invoiceProvider = Provider.of<InvoiceProvider>(context);
    final onlineBankInvoices = invoiceProvider.getInvoicesByPaymentMethod('online');

    print('Invoices for Online Bank Transfer: $onlineBankInvoices'); // Debugging line

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
            SizedBox(height: 16),
            onlineBankInvoices.isEmpty
                ? Expanded(
              child: Center(
                child: Text(
                  'No invoices found for $paymentMethod.',
                  style: TextStyle(color: Colors.teal.shade600),
                ),
              ),
            )
                : Expanded(
              child: ListView.builder(
                itemCount: onlineBankInvoices.length,
                itemBuilder: (context, index) {
                  final invoice = onlineBankInvoices[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        'Invoice #${invoice['invoiceNumber']}',
                        style: TextStyle(
                            color: Colors.teal.shade800, fontSize: 16),
                      ),
                      subtitle: Text(
                        'Total: ${invoice['grandTotal']}',
                        style: TextStyle(
                            color: Colors.teal.shade600, fontSize: 14),
                      ),
                      onTap: () {
                        // Navigate to invoice details page if needed
                        // Example: Navigator.push(...)
                      },
                    ),
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
