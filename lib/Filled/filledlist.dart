import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../Provider/filled provider.dart';
import '../Provider/lanprovider.dart';
import 'filledpage.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:ui' as ui;

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
          filledDate = DateTime.tryParse(filledDateStr) ?? DateTime.fromMillisecondsSinceEpoch(int.parse(filledDateStr));
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

// Sort the filtered list by createdAt in descending orders
    _filteredFilled.sort((a, b) {
      final dateA = DateTime.tryParse(a['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(int.parse(a['createdAt']));
      final dateB = DateTime.tryParse(b['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(int.parse(b['createdAt']));
      return dateB.compareTo(dateA); // Newest first
    });


    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.isEnglish ? 'Filled List' : 'فلڈ لسٹ',style: TextStyle(color: Colors.white),),
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
                              '${languageProvider.isEnglish ? 'Rs' : 'روپے'} ${filled['grandTotal'].toStringAsFixed(2)}',

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

                            style: TextStyle(fontSize: 15, color: Colors.red),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => filledpage(
                              filled: Map<String, dynamic>.from(_filteredFilled[index]), // Passs selected filled
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

  Future<pw.MemoryImage> _createTextImage(String text) async {
    // Create a custom painter with the Urdu text
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromPoints(Offset(0, 0), Offset(500, 50)));
    final paint = Paint()..color = Colors.black;

    final textStyle = TextStyle(fontSize: 13, fontFamily: 'JameelNoori',color: Colors.black,fontWeight: FontWeight.bold);  // Set custom font here if necessary
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.left,
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset(0, 0));

    // Create image from the canvas
    final picture = recorder.endRecording();
    final img = await picture.toImage(textPainter.width.toInt(), textPainter.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    return pw.MemoryImage(buffer);  // Return the image as MemoryImage
  }


  Future<void> _printFilled() async {
    final pdf = pw.Document();

    // Header for the table
    final headers = ['Filled Number', 'Customer Name', 'Date', 'Grand Total', 'Remaining Amount'];

    // Prepare data for the table with customer name images
    final List<List<dynamic>> data = [];

    for (var filled in _filteredFilled) {
      final customerName = filled['customerName'] ?? 'N/A';
      final customerNameImage = await _createTextImage(customerName);  // Generate image for customer name

      data.add([
        filled['filledNumber'] ?? 'N/A',
        pw.Image(customerNameImage),  // Add customer name image to the table
        filled['createdAt'] ?? 'N/A',
        'Rs ${filled['grandTotal']}',
        'Rs ${(filled['grandTotal'] - filled['debitAmount']).toStringAsFixed(2)}',
      ]);
    }

    // Define the number of rows per page based on the page size
    const int rowsPerPage = 20;  // Adjust this value as necessary

    // Split data into chunks for pagination
    final pageCount = (data.length / rowsPerPage).ceil();

    for (int pageIndex = 0; pageIndex < pageCount; pageIndex++) {
      final startIndex = pageIndex * rowsPerPage;
      final endIndex = (startIndex + rowsPerPage) < data.length ? startIndex + rowsPerPage : data.length;
      final pageData = data.sublist(startIndex, endIndex);
      // Load the footer logo if different
      final ByteData footerBytes = await rootBundle.load('assets/images/devlogo.png');
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
                  'Filled List',
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
      FilledProvider invoiceProvider,
      LanguageProvider languageProvider) async {
    String? selectedPaymentMethod; // To hold the selected payment smethod
    _paymentController.clear();
    bool _isPaymentButtonPressed = false; // Flag to prevent multiple presses

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
