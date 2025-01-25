import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../Provider/lanprovider.dart';
import 'Invoicepage.dart';
import '../Provider/invoice provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:ui' as ui;

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
    final languageProvider = Provider.of<LanguageProvider>(context);

    _filteredInvoices = invoiceProvider.invoices.where((invoice) {
      final searchQuery = _searchController.text.toLowerCase();
      final invoiceNumber = (invoice['invoiceNumber'] ?? '').toString().toLowerCase();
      final customerName = (invoice['customerName'] ?? '').toString().toLowerCase();

      final matchesSearch = invoiceNumber.contains(searchQuery) || customerName.contains(searchQuery);

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

// Sort invoices by createdAt in descending order
    _filteredInvoices.sort((a, b) {
      final dateA = DateTime.tryParse(a['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(int.parse(a['createdAt']));
      final dateB = DateTime.tryParse(b['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(int.parse(b['createdAt']));
      return dateB.compareTo(dateA); // Newest first
    });


    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.isEnglish ? 'Invoice List' : 'انوائس لسٹ',style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Colors.teal,  // AppBar background color
        actions: [
          IconButton(
            icon: const Icon(Icons.add,color: Colors.white,),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InvoicePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            onPressed: () {
              _printInvoices(); // Trigger the print functions
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
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.teal.shade400, // Text color
              ),
              icon: const Icon(Icons.date_range,color: Colors.white,),
              label:  Text(
              _selectedDateRange == null
                  ? languageProvider.isEnglish ? 'Select Date' : 'ڈیٹ منتخب کریں'
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
                  child: Text(languageProvider.isEnglish ? 'Clear Date Filter' : 'انوائس لسٹ کا فلٹر ختم کریں',),
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

                    // final grandTotal = invoice['grandTotal'] ?? 0.0;
                    final grandTotal = (invoice['grandTotal'] ?? 0.0).toDouble();

                    // final debitAmount = invoice['debitAmount'] ?? 0.0;
                    final debitAmount = (invoice['debitAmount'] ?? 0.0).toDouble();

                    // final remainingAmount = grandTotal - debitAmount;
                    final remainingAmount = (grandTotal - debitAmount).toDouble();

                    return ListTile(
                      // title: Text('Invoice #${invoice['invoiceNumber']}'),
                      title: Text(
                        // languageProvider.isEnglish ? 'Invoice #' : 'انوائس نمبر' '${invoice['invoiceNumber']}',
                        '${languageProvider.isEnglish ? 'Invoice #' : 'انوائس نمبر'} ${invoice['invoiceNumber']}',

                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text('Customer: ${invoice['customerName']?? 'Unknown'}'),
                          Text(
                              '${languageProvider.isEnglish ? 'Customer' : 'کسٹمر کا نام'} ${invoice['customerName']}',
                            ),
                          // Text('Date and Time: ${invoice['createdAt']}'),
                          Text(
                            '${languageProvider.isEnglish ? 'Date and Time' : 'ڈیٹ & ٹائم'}',
                          ),
                          Text(
                              '${invoice['createdAt']}',style: TextStyle(fontSize: 12)
                          ),
                          IconButton(
                            icon: const Icon(Icons.payment),
                            onPressed: () {
                              _showInvoicePaymentDialog(invoice, invoiceProvider, languageProvider);
                            },
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min, // Ensures the row takes only as much space as needed
                        crossAxisAlignment: CrossAxisAlignment.end,

                        children: [
                          Text(
                              '${languageProvider.isEnglish ? 'Rs ${invoice['grandTotal'].toStringAsFixed(2)}' : '${invoice['grandTotal'].toStringAsFixed(2)} روپے'}',
                              style: TextStyle(fontSize: 16)),
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




  Future<pw.MemoryImage> _createTextImage(String text) async {
    // Scale factor to increase resolution
    const double scaleFactor = 1.5;

    // Create a custom painter with the Urdu text
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromPoints(
        Offset(0, 0),
        Offset(500 * scaleFactor, 50 * scaleFactor),
      ),
    );

    // Paint settings
    final paint = Paint()..color = Colors.black;

    // Define text style with scaling
    final textStyle = TextStyle(
      fontSize: 13 * scaleFactor,
      fontFamily: 'JameelNoori',
      color: Colors.black,
      fontWeight: FontWeight.bold,
    );

    // Create the text span and text painter
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.left,
      textDirection: ui.TextDirection.ltr,
    );

    // Layout and paint the text
    textPainter.layout();
    textPainter.paint(canvas, Offset(0, 0));

    // Create an image from the canvas
    final picture = recorder.endRecording();
    final img = await picture.toImage(
      (textPainter.width * scaleFactor).toInt(),
      (textPainter.height * scaleFactor).toInt(),
    );

    // Convert the image to PNG
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    // Return the image as a MemoryImage
    return pw.MemoryImage(buffer);
  }



  Future<void> _printInvoices() async {
    final pdf = pw.Document();
    // Header for the table
    final headers = ['Invoice Number', 'Customer Name', 'Date', 'Grand Total', 'Remaining Amount'];

    // Prepare data for the table
    final List<List<dynamic>> tableData = [];

    // Pre-process customer name images before building the table
    for (var invoice in _filteredInvoices) {
      final customerName = invoice['customerName'] ?? 'N/A';
      final customerNameImage = await _createTextImage(customerName);

      tableData.add([
        invoice['invoiceNumber'] ?? 'N/A',
        pw.Image(customerNameImage),
        invoice['createdAt'] ?? 'N/A',
        'Rs ${invoice['grandTotal']}',
        'Rs ${(invoice['grandTotal'] - invoice['debitAmount']).toStringAsFixed(2)}',
      ]);
    }

    // Split the data into chunks that fit on a single page
    const int rowsPerPage = 11; // Adjust the number of rows per page as needed
    final pageCount = (tableData.length / rowsPerPage).ceil();

    for (int pageIndex = 0; pageIndex < pageCount; pageIndex++) {
      // Get a subset of the data for the current page
      final startIndex = pageIndex * rowsPerPage;
      final endIndex = (startIndex + rowsPerPage) < tableData.length ? startIndex + rowsPerPage : tableData.length;
      final pageData = tableData.sublist(startIndex, endIndex);
      // Load the footer logo if different
      final ByteData footerBytes = await rootBundle.load('images/devlogo.png');
      final footerBuffer = footerBytes.buffer.asUint8List();
      final footerLogo = pw.MemoryImage(footerBuffer);
      // Add page with a table
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Invoice List',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  headers: headers,
                  data: pageData,
                  border: pw.TableBorder.all(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellPadding: pw.EdgeInsets.all(8),
                ),
                // Footer Section
                pw.Spacer(), // Push footer to the bottom of the page
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Image(footerLogo, width: 30, height: 30), // Footer logo
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Dev Valley Software House',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            'Contact: 0303-4889663',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                          ),
                        ]
                    )
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    // Send the PDF document to the printer
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }





  Future<void> _showInvoicePaymentDialog(
      Map<String, dynamic> invoice,
      InvoiceProvider invoiceProvider,
      LanguageProvider languageProvider) async {
    String? selectedPaymentMethod; // To hold the selected payment method
    _paymentController.clear();
    bool _isPaymentButtonPressed = false; // Flag to prevent multiple presses

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                languageProvider.isEnglish ? 'Pay Invoice' : 'انوائس کی رقم ادا کریں',
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
                  onPressed: _isPaymentButtonPressed
                      ? null // Disable the button if it's already pressed
                      : () async {
                    setState(() {
                      _isPaymentButtonPressed = true; // Disable the button when pressed
                    });

                    if (selectedPaymentMethod == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(languageProvider.isEnglish
                              ? 'Please select a payment method.'
                              : 'براہ کرم ادائیگی کا طریقہ منتخب کریں۔'),
                        ),
                      );
                      setState(() {
                        _isPaymentButtonPressed = false; // Re-enable the button on failure
                      });
                      return;
                    }

                    final amount = double.tryParse(_paymentController.text);
                    if (amount != null && amount > 0) {
                      await invoiceProvider.payInvoiceWithSeparateMethod(
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

                    setState(() {
                      _isPaymentButtonPressed = false; // Re-enable the button after payment is processed
                    });
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

