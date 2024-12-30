import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Invoicepage.dart';
import '../Provider/invoice provider.dart';
import 'editinvoice.dart';

class InvoiceListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final invoiceProvider = Provider.of<InvoiceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice List'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InvoicePage()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder(
        // Fetch invoices when the page is loaded
        future: invoiceProvider.fetchInvoices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            return const Center(child: CircularProgressIndicator());
          }

          if (invoiceProvider.invoices.isEmpty) {
            return const Center(child: Text('No invoices found.'));
          }

          return ListView.builder(
            itemCount: invoiceProvider.invoices.length,
            itemBuilder: (context, index) {
              final invoice = invoiceProvider.invoices[index];
              return ListTile(
                title: Text('Invoice #${invoice['invoiceNumber']}'),
                subtitle: Text('Customer: ${invoice['customerId']}'),
                trailing: Text('\Rs ${invoice['grandTotal']}'),
                onTap: () {
                  // Navigate to InvoiceEditPage with invoice details
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InvoiceEditPage(
                        invoiceId: invoice['id'],
                        invoiceNumber: invoice['invoiceNumber'],
                        customerId: invoice['customerId'],
                        subtotal: invoice['subtotal'],
                        discount: invoice['discount'],
                        grandTotal: invoice['grandTotal'],
                        paymentType: invoice['paymentType'],
                        paymentMethod: invoice['paymentMethod'],
                        items: List<Map<String, dynamic>>.from(invoice['items']),
                      ),
                    ),
                  );
                },

                onLongPress: () {
                  // Show delete confirmation dialog
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Delete Invoice'),
                        content: const Text('Are you sure you want to delete this invoice?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              invoiceProvider.deleteInvoice(invoice['id']);
                              Navigator.of(context).pop();
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
