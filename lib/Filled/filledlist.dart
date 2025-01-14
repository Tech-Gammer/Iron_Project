import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../Provider/filled provider.dart';
import '../Provider/lanprovider.dart';
import 'filledpage.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class filledListpage extends StatefulWidget {
  @override
  _filledListpageState createState() => _filledListpageState();
}

class _filledListpageState extends State<filledListpage> {
  TextEditingController _searchController = TextEditingController();
  final TextEditingController _paymentController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  List<Map<String, dynamic>> _filteredFilled = [];

  @override
  Widget build(BuildContext context) {
    final filledProvider = Provider.of<FilledProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    _filteredFilled = filledProvider.filled.where((filled) {
      final searchQuery = _searchController.text.toLowerCase();
      final filledNumber = (filled['filledNumber'] ?? '').toString().toLowerCase();
      final matchesSearch = filledNumber.contains(searchQuery);

      if (_selectedDateRange != null) {
        final filledDateStr = filled['createdAt'];
        DateTime? filledDate;

        // Parse the date, accounting for different formats
        try {
          filledDate = DateTime.tryParse(filledDateStr) ?? DateTime.fromMillisecondsSinceEpoch(int.parse( filledDateStr));
        } catch (e) {
          print('Error parsing date: $e');
          return false;
        }

        final isInDateRange = (filledDate.isAfter(_selectedDateRange!.start) ||
            filledDate.isAtSameMomentAs(_selectedDateRange!.start)) &&
            (filledDate.isBefore(_selectedDateRange!.end) ||
                filledDate.isAtSameMomentAs(_selectedDateRange!.end));

        return matchesSearch && isInDateRange;
      }

      return matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.isEnglish ? 'Filled List:' : 'فلڈ لسٹ',style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Colors.teal,  // AppBar background color
        actions: [
          IconButton(
            icon: const Icon(Icons.add,color: Colors.white,),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => filledpage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
              onPressed: () {
                _printFilled(); // Trigger the print function
          },
           )
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
                labelText: languageProvider.isEnglish ? 'Search By Filled ID' : 'فلڈ آئی ڈی سے تالاش کریں',
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
            child: ElevatedButton.icon(
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
              icon: const Icon(Icons.date_range,color: Colors.white,),
              label:  Text(
                _selectedDateRange == null
                    ? languageProvider.isEnglish ? 'Select Date' : 'ڈیٹ منتخب کریں'
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
                  child: Text(languageProvider.isEnglish ? 'Clear Date Filter' : 'انوائس لسٹ کا فلٹر ختم کریں',),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.teal.shade400, // Text color
                  ),
                ),
              ],
            ),
          ),
          // Filled List
          Expanded(
            child: FutureBuilder(
              future:  filledProvider.fetchFilled(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_filteredFilled.isEmpty) {
                  return Center(child: Text(languageProvider.isEnglish ? 'No Filled Found:' : 'کوئی فلڈ موجود نہیں',));
                }
                return ListView.builder(
                  itemCount: _filteredFilled.length,
                  itemBuilder: (context, index) {
                    final  filled = Map<String, dynamic>.from(_filteredFilled[index]);
                    final grandTotal = filled['grandTotal'] ?? 0.0;
                    final debitAmount = filled['debitAmount'] ?? 0.0;
                    final remainingAmount = grandTotal - debitAmount;
                    return ListTile(
                      // title: Text('Filled #${filled['filledNumber']}'),
                      title: Text(
                        '${languageProvider.isEnglish ? 'Filled #' : 'فلڈ نمبر'} ${filled['filledNumber']}',

                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${languageProvider.isEnglish ? 'Customer' : 'کسٹمر کا نام'} ${filled['customerName']}',
                          ),                          const SizedBox(width: 20,),
                          // Text(
                          //   '${languageProvider.isEnglish ? 'Date and Time' : 'ڈیٹ & ٹائم'} ${filled['createdAt']}',
                          // ),
                          //
                          Text(
                            '${languageProvider.isEnglish ? 'Date and Time' : 'ڈیٹ & ٹائم'}',
                          ),
                          Text(
                              '${filled['createdAt']}',style: TextStyle(fontSize: 12)
                          ),
                          const SizedBox(width: 20,),
                          IconButton(
                            icon: const Icon(Icons.payment),
                            onPressed: () {
                              _showInvoicePaymentDialog(filled, filledProvider, languageProvider);
                            },
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min, // Ensures the row takes only as much space as needed
                        crossAxisAlignment: CrossAxisAlignment.end,                        children: [
                          Text(
                              // 'Rs ${filled['grandTotal']}',
                              '${languageProvider.isEnglish ? 'Rs' : 'روپے'} ${filled['grandTotal']}',

                              style: TextStyle(fontSize: 16)
                          ),
                          const SizedBox(width: 10), // Adds some space between the two texts
                          // Text(
                          //   'Remaining: Rs ${remainingAmount.toStringAsFixed(2)}',
                          //   style: TextStyle(fontSize: 16, color: Colors.red),
                          // ),
                          Text(
                            // 'Remaining: Rs ${remainingAmount.toStringAsFixed(2)}',
                            '${languageProvider.isEnglish ? 'Remaining Amount' : 'بقایا رقم'} ${remainingAmount.toStringAsFixed(2)}',

                            style: TextStyle(fontSize: 16, color: Colors.red),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => filledpage(
                              filled: Map<String, dynamic>.from(_filteredFilled[index]), // Pass selected filled
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
                              title: Text(languageProvider.isEnglish ? 'Delete Filled' : 'فلڈ ڈلیٹ کریں'),
                              // title: const Text('Delete Filled'),
                              // content: const Text('Are you sure you want to delete this filled?'),
                              content: Text(languageProvider.isEnglish ? 'Are you sure you want to delete this filled?' : 'کیاآپ واقعی اس فلڈ کو ڈیلیٹ کرنا چاہتے ہیں'),

                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(languageProvider.isEnglish ? 'Cancel' : 'ردکریں'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    // Call deletefilled from the filledProvider
                                    await filledProvider.deleteFilled(filled['id']);
                                    Navigator.of(context).pop(); // Close the dialog
                                  },
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

  // Future<void> _showFilledPaymentDialog(
  //     Map<String, dynamic> filled, FilledProvider filledProvider, LanguageProvider languageprovider) async {
  //
  //   final languageProvider = context.read<LanguageProvider>();
  //
  //   _paymentController.clear();
  //   await showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         // title: const Text('Pay Filled'),
  //         title: Text(languageProvider.isEnglish ? 'Pay Filled' : 'فلڈ کی رقم ادا کریں'),
  //
  //         content: TextField(
  //           controller: _paymentController,
  //           keyboardType: TextInputType.number,
  //           decoration: InputDecoration(
  //             // labelText: 'Enter Payment Amount',
  //               labelText: languageProvider.isEnglish ? 'Enter Payment Amount' : 'رقم لکھیں'
  //
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text('Cancel'),
  //           ),
  //           TextButton(
  //             onPressed: () async {
  //               final amount = double.tryParse(_paymentController.text);
  //               if (amount != null && amount > 0) {
  //                 // awaitfilledProvider.addDebit(filled['id'], amount);
  //                 await filledProvider.payFilled(context, filled['id'], amount);
  //                 Navigator.of(context).pop();
  //               } else {
  //                 // Handle invalid input
  //               }
  //             },
  //             child: const Text('Pay'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  Future<void> _printFilled() async {
    final pdf = pw.Document();

    // Header for the table
    final headers = ['Filled Number', 'Customer Name', 'Date', 'Grand Total', 'Remaining Amount'];

    // Prepare data for the table
    final data = _filteredFilled.map((filled) {
      return [
        filled['filledNumber'] ?? 'N/A',
        filled['customerName'] ?? 'N/A',
        filled['createdAt'] ?? 'N/A',
        'Rs ${filled['grandTotal']}',
        'Rs ${(filled['grandTotal'] - filled['debitAmount']).toStringAsFixed(2)}',
      ];
    }).toList();

    // Add page with a table
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Filled List',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: headers,
                data: data,
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: pw.EdgeInsets.all(8),
              ),
            ],
          );
        },
      ),
    );

    // Send the PDF document to the printer
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> _showInvoicePaymentDialog(
      Map<String, dynamic> invoice,
      FilledProvider invoiceProvider,
      LanguageProvider languageProvider) async {
    String? selectedPaymentMethod; // To hold the selected payment method
    _paymentController.clear();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                languageProvider.isEnglish ? 'Pay Filled' : 'انوائس کی رقم ادا کریں',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedPaymentMethod,
                    items: [
                      DropdownMenuItem(
                        value: 'Cash',
                        child: Text(languageProvider.isEnglish ? 'Cash' : 'نقدی'),
                      ),
                      DropdownMenuItem(
                        value: 'Online',
                        child: Text(languageProvider.isEnglish ? 'Online' : 'آن لائن'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedPaymentMethod = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: languageProvider.isEnglish ? 'Select Payment Method' : 'ادائیگی کا طریقہ منتخب کریں',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _paymentController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: languageProvider.isEnglish ? 'Enter Payment Amount' : 'رقم لکھیں',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(languageProvider.isEnglish ? 'Cancel' : 'انکار'),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedPaymentMethod == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(languageProvider.isEnglish
                              ? 'Please select a payment method.'
                              : 'براہ کرم ادائیگی کا طریقہ منتخب کریں۔'),
                        ),
                      );
                      return;
                    }

                    final amount = double.tryParse(_paymentController.text);
                    if (amount != null && amount > 0) {
                      await invoiceProvider.payFilledWithSeparateMethod(
                        context,
                        invoice['id'],
                        amount,
                        selectedPaymentMethod!,
                      );
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(languageProvider.isEnglish
                              ? 'Please enter a valid payment amount.'
                              : 'براہ کرم ایک درست رقم درج کریں۔'),
                        ),
                      );
                    }
                  },
                  child: Text(languageProvider.isEnglish ? 'Pay' : 'رقم ادا کریں'),
                ),
              ],
            );
          },
        );
      },
    );
  }

}
