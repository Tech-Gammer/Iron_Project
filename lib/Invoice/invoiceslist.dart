import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Provider/lanprovider.dart';
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
    // final languageProvider = Provider.of<LanguageProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

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
        title: Text(languageProvider.isEnglish ? 'Invoice List:' : 'انوائس لسٹ',),
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
                labelText: languageProvider.isEnglish ? 'Search By Invoice ID' : 'انوائس آئی ڈی سے تالاش کریں',
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
                    ? languageProvider.isEnglish ? 'Select Date:' : 'ڈیٹ منتخب کریں'
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
                  child: Text(languageProvider.isEnglish ? 'Clear Date Filter:' : 'انوائس لسٹ کا فلٹر ختم کریں',),
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
                  return Center(child: Text(languageProvider.isEnglish ? 'No Invoice Found:' : 'کوئی انوائس موجود نہیں',));
                }
                return ListView.builder(
                  itemCount: _filteredInvoices.length,
                  itemBuilder: (context, index) {
                    final invoice = Map<String, dynamic>.from(_filteredInvoices[index]);
                    final grandTotal = invoice['grandTotal'] ?? 0.0;
                    final debitAmount = invoice['debitAmount'] ?? 0.0;
                    final remainingAmount = grandTotal - debitAmount;
                    return ListTile(
                      // title: Text('Invoice #${invoice['invoiceNumber']}'),
                      title: Text(
                        // languageProvider.isEnglish ? 'Invoice #' : 'انوائس نمبر' '${invoice['invoiceNumber']}',
                        '${languageProvider.isEnglish ? 'Invoice #' : 'انوائس نمبر'} ${invoice['invoiceNumber']}',

                      ),
                      subtitle: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Text('Customer: ${invoice['customerName']?? 'Unknown'}'),
                          Text(
                              '${languageProvider.isEnglish ? 'Customer' : 'کسٹمر کا نام'} ${invoice['customerName']}',
                            ),
                          const SizedBox(width: 20,),
                          // Text('Date and Time: ${invoice['createdAt']}'),
                          Text(
                            '${languageProvider.isEnglish ? 'Date and Time' : 'ڈیٹ & ٹائم'} ${invoice['createdAt']}',
                          ),
                          const SizedBox(width: 20,),
                          IconButton(
                            icon: const Icon(Icons.payment),
                            onPressed: () {
                              _showInvoicePaymentDialog(invoice, invoiceProvider, languageProvider);
                            },
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min, // Ensures the row takes only as much space as needed
                        children: [
                          Text('Rs ${invoice['grandTotal']}',
                              style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10), // Adds some space between the two texts
                          Text(
                            // 'Remaining: Rs ${remainingAmount.toStringAsFixed(2)}',
                            '${languageProvider.isEnglish ? 'remainingAmount' : 'بقایا رقم'} ${remainingAmount.toStringAsFixed(2)}',

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
                              // title: const Text('Delete Invoice'),
                              title: Text(languageProvider.isEnglish ? 'Delete Invoice' : 'انوائس ڈلیٹ کریں'),

                              // content: const Text('Are you sure you want to delete this invoice?'),
                              content: Text(languageProvider.isEnglish ? 'Are you sure you want to delete this invoice?' : 'کیاآپ واقعی اس انوائس کو ڈیلیٹ کرنا چاہتے ہیں'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  // child: const Text('Cancel'),
                                  child: Text(languageProvider.isEnglish ? 'Cancel' : 'ردکریں'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    // Call deleteInvoice from the InvoiceProvider
                                    await invoiceProvider.deleteInvoice(invoice['id']);
                                    Navigator.of(context).pop(); // Close the dialog
                                  },
                                  // child: const Text('Delete'),
                                  child: Text(languageProvider.isEnglish ? 'Delete' : 'ڈیلیٹ کریں'),

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

      Map<String, dynamic> invoice, InvoiceProvider invoiceProvider, LanguageProvider languageprovider) async {
    // final languageProvider = Provider.of<LanguageProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    _paymentController.clear();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // title: const Text('Pay Invoice'),
          title: Text(languageProvider.isEnglish ? 'Pay Invoice' : 'انوائس کی رقم ادا کریں'),
          content: TextField(
            controller: _paymentController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              // labelText: 'Enter Payment Amount',
              labelText: languageProvider.isEnglish ? 'Enter Payment Amount' : 'رقم لکھیں'
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
