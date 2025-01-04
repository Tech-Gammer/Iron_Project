import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Invoicepage.dart';
import '../Provider/invoice provider.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:flutter/services.dart'; // For date range picker

class InvoiceListPage extends StatefulWidget {
  @override
  _InvoiceListPageState createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  List<Map<String, dynamic>> _filteredInvoices = [];

  @override
  Widget build(BuildContext context) {
    final invoiceProvider = Provider.of<InvoiceProvider>(context);

    _filteredInvoices = invoiceProvider.invoices.where((invoice) {
      final searchQuery = _searchController.text.toLowerCase();

      // Null check to prevent calling 'toLowerCase()' on null values
      final invoiceNumber = (invoice['invoiceNumber'] ?? '').toString().toLowerCase();

      // Only search by invoice number
      bool matchesSearch = invoiceNumber.contains(searchQuery);

      // Filter by date range if selected
      if (_selectedDateRange != null) {
        // Ensure invoice['date'] is not null and parse it correctly
        final invoiceDateStr = invoice['date']; // Assuming it's a String
        DateTime invoiceDate = DateTime.tryParse(invoiceDateStr ?? '') ?? DateTime.now(); // Use current date if parsing fails

        return matchesSearch &&
            (invoiceDate.isAfter(_selectedDateRange!.start) ||
                invoiceDate.isAtSameMomentAs(_selectedDateRange!.start)) &&
            (invoiceDate.isBefore(_selectedDateRange!.end) ||
                invoiceDate.isAtSameMomentAs(_selectedDateRange!.end));
      }
      return matchesSearch;
    }).toList();

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
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Invoice ID',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear(); // Clear the text in the TextField
                    });
                  },
                )
                    : null, // Only show clear icon when there's text
                border: OutlineInputBorder(),
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
                        buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
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
                  child: Text('Clear Date Range'),
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
                    // final invoice = _filteredInvoices[index];
                    final invoice = Map<String, dynamic>.from(_filteredInvoices[index]);
                    return ListTile(
                      title: Text('Invoice #${invoice['invoiceNumber']}'),
                      subtitle: Text('Customer: ${invoice['customerId']}'),
                        trailing: Text('\Rs ${invoice['grandTotal']}'),
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
                        }

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
}
