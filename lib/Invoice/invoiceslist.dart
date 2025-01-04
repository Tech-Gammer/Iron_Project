import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Invoicepage.dart';
import '../Provider/invoice provider.dart';
import 'package:intl/intl.dart';

class InvoiceListPage extends StatefulWidget {
  @override
  _InvoiceListPageState createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  TextEditingController _searchController = TextEditingController();
  final TextEditingController _paymentController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  List<Map<String, dynamic>> _filteredInvoices = [];

  @override
  Widget build(BuildContext context) {
    final invoiceProvider = Provider.of<InvoiceProvider>(context);

    _filteredInvoices = invoiceProvider.invoices.where((invoice) {
      final searchQuery = _searchController.text.toLowerCase();
      final invoiceNumber = (invoice['invoiceNumber'] ?? '').toString().toLowerCase();
      final matchesSearch = invoiceNumber.contains(searchQuery);

      if (_selectedDateRange != null) {
        final invoiceDateStr = invoice['createdAt'];
        DateTime? invoiceDate;

        // Parse the date, accounting for different formats
        try {
          invoiceDate = DateTime.tryParse(invoiceDateStr) ?? DateTime.fromMillisecondsSinceEpoch(int.parse(invoiceDateStr));
        } catch (e) {
          print('Error parsing date: $e');
          return false;
        }

        final isInDateRange = (invoiceDate.isAfter(_selectedDateRange!.start) ||
            invoiceDate.isAtSameMomentAs(_selectedDateRange!.start)) &&
            (invoiceDate.isBefore(_selectedDateRange!.end) ||
                invoiceDate.isAtSameMomentAs(_selectedDateRange!.end));

        return matchesSearch && isInDateRange;
      }

      return matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice List'),
        centerTitle: true,
        backgroundColor: Colors.teal,  // AppBar background color
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
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Invoice ID',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear(); // Clear the text in the TextField
                    });
                  },
                )
                    : null, // Only show clear icon when there's text
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {}); // Rebuild to show/hide the clear icon dynamically
              },
            ),
          ),

          // Date Range Picker
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton(
              onPressed: () async {
                DateTimeRange? pickedDateRange = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                  initialDateRange: _selectedDateRange,
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.light().copyWith(
                        primaryColor: Colors.blue,
                        hintColor: Colors.blue,
                        buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
                      ),
                      child: child!,
                    );
                  },
                );

                if (pickedDateRange != null) {
                  setState(() {
                    _selectedDateRange = pickedDateRange;
                  });
                }
              },
              child: Text(
                _selectedDateRange == null
                    ? 'Select Date Range'
                    : 'From: ${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start)} - To: ${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end)}',
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.teal.shade400, // Text color
              ),
            ),
          ),
          // Buttons to remove filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Clear date range filter button
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedDateRange = null;
                    });
                  },
                  child: const Text('Clear Date Range'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.teal.shade400, // Text color
                  ),
                ),
              ],
            ),
          ),
          // Invoice List
          Expanded(
            child: FutureBuilder(
              future: invoiceProvider.fetchInvoices(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_filteredInvoices.isEmpty) {
                  return const Center(child: Text('No invoices found.'));
                }
                return ListView.builder(
                  itemCount: _filteredInvoices.length,
                  itemBuilder: (context, index) {
                    final invoice = Map<String, dynamic>.from(_filteredInvoices[index]);
                    final grandTotal = invoice['grandTotal'] ?? 0.0;
                    final debitAmount = invoice['debitAmount'] ?? 0.0;
                    final remainingAmount = grandTotal - debitAmount;
                    return ListTile(
                      title: Text('Invoice #${invoice['invoiceNumber']}'),
                      subtitle: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text('Customer: ${invoice['customerId']}'),
                          const SizedBox(width: 20,),
                          Text('Date and Time: ${invoice['createdAt']}'),
                          const SizedBox(width: 20,),
                          IconButton(
                            icon: const Icon(Icons.payment),
                            onPressed: () {
                              _showInvoicePaymentDialog(invoice, invoiceProvider);
                            },
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min, // Ensures the row takes only as much space as needed
                        children: [
                          Text('Rs ${invoice['grandTotal']}', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10), // Adds some space between the two texts
                          Text(
                            'Remaining: Rs ${remainingAmount.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 16, color: Colors.red),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InvoicePage(
                              invoice: Map<String, dynamic>.from(_filteredInvoices[index]), // Pass selected invoice
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
                                  onPressed: () async {
                                    // Call deleteInvoice from the InvoiceProvider
                                    await invoiceProvider.deleteInvoice(invoice['id']);
                                    Navigator.of(context).pop(); // Close the dialog
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
          ),
        ],
      ),
    );
  }

  Future<void> _showInvoicePaymentDialog(
      Map<String, dynamic> invoice, InvoiceProvider invoiceProvider) async {
    _paymentController.clear();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pay Invoice'),
          content: TextField(
            controller: _paymentController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Enter Payment Amount',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final amount = double.tryParse(_paymentController.text);
                if (amount != null && amount > 0) {
                  // await invoiceProvider.addDebit(invoice['id'], amount);
                  await invoiceProvider.payInvoice(context, invoice['id'], amount);
                  Navigator.of(context).pop();
                } else {
                  // Handle invalid input
                }
              },
              child: const Text('Pay'),
            ),
          ],
        );
      },
    );
  }
}
