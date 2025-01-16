import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iron_project_new/Provider/filled%20provider.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../Provider/customerprovider.dart';
import '../Provider/lanprovider.dart';
import 'filledlist.dart'; // Import your customer provider
import 'dart:ui' as ui;


class filledpage extends StatefulWidget {
  final Map<String, dynamic>? filled; // Optional filled data for editing

  filledpage({this.filled});

  @override
  _filledpageState createState() => _filledpageState();
}

class _filledpageState extends State<filledpage> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  String? _selectedCustomerName; // This should hold the name of the selected customer
  String? _selectedCustomerId;
  double _discount = 0.0; // Discount amount or percentage
  String _paymentType = 'instant';
  String? _instantPaymentMethod;
  TextEditingController _discountController = TextEditingController();
  List<Map<String, dynamic>> _filledRows = [];
  String? _filledId; // For editing existing filled
  late bool _isReadOnly;
  bool _isButtonPressed = false;

  String generateFilledNumber() {
    // Generate a timestamp as filled number (in millsiseconds)
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  void _addNewRow() {
    setState(() {
      _filledRows.add({
        'total': 0.0,
        'rate': 0.0,
        'qty': 0.0,
        // 'weight': 0.0,
        'description': '',
        'weightController': TextEditingController(),
        'rateController': TextEditingController(),
        'qtyController': TextEditingController(),
        'descriptionController': TextEditingController(),
      });
    });
  }

  void _updateRow(int index, String field, dynamic value) {
    setState(() {
      _filledRows[index][field] = value;

      // If both Sarya Rate and Sarya Qty are filled, calculate the Total
      if (_filledRows[index]['rate'] != 0.0 && _filledRows[index]['qty'] != 0.0) {
        _filledRows[index]['total'] = _filledRows[index]['rate'] * _filledRows[index]['qty'];
      }
    });
  }

  void _deleteRow(int index) {
    setState(() {
      _filledRows.removeAt(index);
    });
  }

  double _calculateSubtotal() {
    return _filledRows.fold(0.0, (sum, row) => sum + (row['total'] ?? 0.0));
  }

  double _calculateGrandTotal() {
    double subtotal = _calculateSubtotal();
    // Discount is directly subtracted from subtotal
    double discountAmount = _discount;
    return subtotal - discountAmount;
  }

  Future<void> _generateAndPrintPDF(String filledNumber) async {
    final pdf = pw.Document();
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final selectedCustomer = customerProvider.customers.firstWhere((customer) => customer.id == _selectedCustomerId);

    // Get current date and time
    final DateTime now = DateTime.now();
    final String formattedDate = '${now.day}/${now.month}/${now.year}';
    final String formattedTime = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    // Get the remaining balance from the ledger
    double remainingBalance = await _getRemainingBalance(_selectedCustomerId!);

    // Load the image asset for the logo
    final ByteData bytes = await rootBundle.load('assets/images/logo.png');
    final buffer = bytes.buffer.asUint8List();
    final image = pw.MemoryImage(buffer);

    // Load the footer logo if different
    final ByteData footerBytes = await rootBundle.load('assets/images/devlogo.png');
    final footerBuffer = footerBytes.buffer.asUint8List();
    final footerLogo = pw.MemoryImage(footerBuffer);

    // Pre-generate images for all descriptionss
    List<pw.MemoryImage> descriptionImages = [];
    for (var row in _filledRows) {
      final image = await _createTextImage(row['description']);
      descriptionImages.add(image);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 0, vertical: 2),  // Reduced side margins
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Company Logo and Filled Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Image(image, width: 100, height: 100), // Adjust width and height as needed
                    pw.Text(
                      'Filled',
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.Divider(),
                // Customer Information
                pw.Text('Customer Name: ${selectedCustomer.name}', style: const pw.TextStyle(fontSize: 14)),
                pw.Text('Customer Number: ${selectedCustomer.phone}', style: const pw.TextStyle(fontSize: 14)),
                pw.Text('Customer Address ${selectedCustomer.address}', style: const pw.TextStyle(fontSize: 14)),
                pw.Text('Date: $formattedDate', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('Time: $formattedTime', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('Filled Id: $_filledId', style: const pw.TextStyle(fontSize: 14)),

                pw.SizedBox(height: 10),

                // Filled Table with Urdu text converted to image
                pw.Table.fromTextArray(
                  headers: [
                    pw.Text('Description', style: const pw.TextStyle(fontSize: 8)),
                    // pw.Text('Weight', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Qty(Pcs)', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Rate', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Total', style: const pw.TextStyle(fontSize: 10)),
                  ],
                  data: _filledRows.asMap().map((index, row) {
                    return MapEntry(
                      index,
                      [
                        // Use the pre-generated image for the description field
                        pw.Image(descriptionImages[index]),
                        // pw.Text(row['weight']?.toStringAsFixed(2) ?? '0.00', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text(row['qty']?.toStringAsFixed(0) ?? '0', style: const pw.TextStyle(fontSize: 12)),
                        pw.Text(row['rate']?.toStringAsFixed(2) ?? '0.00', style: const pw.TextStyle(fontSize: 12)),
                        pw.Text(row['total']?.toStringAsFixed(2) ?? '0.00', style: const pw.TextStyle(fontSize: 12)),

                      ],
                    );
                  }).values.toList(),
                ),
                pw.SizedBox(height: 10),

                // Totals Section
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Sub Total:'),
                    pw.Text(_calculateSubtotal().toStringAsFixed(2)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount:'),
                    pw.Text((_discount ?? 0.0).toStringAsFixed(2)),

                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Grand Total:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text(_calculateGrandTotal().toStringAsFixed(2), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Footer Section (Remaining Balance)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Previous Balance:', style: const pw.TextStyle(fontSize: 14)),
                    pw.Text(remainingBalance.toStringAsFixed(2), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('......................', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                // Footer Section
                pw.Spacer(), // Push footer to the bottom of the page
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Image(footerLogo, width: 20, height: 20), // Footer logo
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Dev Vally Software House',
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
            ),
          );
        },
      ),
    );

    try {
      await Printing.layoutPdf(
        onLayout: (format) async {
          return pdf.save();
        },
      );
    } catch (e) {
      print("Error printing: $e");
    }
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
      textDirection: TextDirection.ltr,
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


  Future<double> _getRemainingBalance(String customerId) async {
    try {
      final customerLedgerRef = _db.child('filledledger').child(customerId);

      final DatabaseEvent snapshot = await customerLedgerRef.orderByChild('createdAt').limitToLast(1).once();

      if (snapshot.snapshot.exists) {
        final Map<dynamic, dynamic> ledgerEntries = snapshot.snapshot.value as Map<dynamic, dynamic>;

        final lastEntryKey = ledgerEntries.keys.first;
        final lastEntry = ledgerEntries[lastEntryKey];

        if (lastEntry != null && lastEntry is Map) {
          // Safely handle the conversion to double
          final remainingBalanceValue = lastEntry['remainingBalance'];

          // Check if the value is an int or a double and convert accordingly
          double remainingBalance = 0.0;
          if (remainingBalanceValue is int) {
            remainingBalance = remainingBalanceValue.toDouble();
          } else if (remainingBalanceValue is double) {
            remainingBalance = remainingBalanceValue;
          }

          print("Remaining Balance: $remainingBalance"); // Debug print
          return remainingBalance;
        }
      }

      return 0.0; // If no data is found, return 0.0
    } catch (e) {
      print("Error fetching remaining balance: $e"); // Debug error message
      return 0.0; // Return 0 if there's an error
    }
  }

  @override
  void dispose() {
    for (var row in _filledRows) {
      // row['weightController']?.dispose();
      row['rateController']?.dispose();
      row['qtyController']?.dispose();
      row['descriptionController']?.dispose();
    }
    _discountController.dispose(); // Dispose discount controller

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Fetch the customers when the page is initialized
    Provider.of<CustomerProvider>(context, listen: false).fetchCustomers();
    _isReadOnly = widget.filled != null; // Set read-only if filled is passed

    if (widget.filled != null) {
      // Populate fields for editing
      final filled = widget.filled!;
      _discount = widget.filled!['discount'];
      _discountController.text = _discount.toString(); // Initialize controller with discount value
      _filledId = filled['filledNumber']; // Save the filled ID for updates
      _selectedCustomerId = filled['customerId'];
      _discount = filled['discount'];
      _paymentType = filled['paymentType'];
      _instantPaymentMethod = filled['paymentMethod'];
      // _filledRows = List<Map<String, dynamic>>.from(filled['items']); // Populate table rows
      _filledRows = List<Map<String, dynamic>>.from(filled['items']).map((row) {
        return {
          ...row,
          // 'weightController': TextEditingController(text: row['weight'].toString()),
          'rateController': TextEditingController(text: row['rate'].toString()),
          'qtyController': TextEditingController(text: row['qty'].toString()),
          'descriptionController': TextEditingController(text: row['description']),
        };
      }).toList();
      // Update each row's total
      for (int i = 0; i < _filledRows.length; i++) {
        _updateRow(i, 'total', null); // Pass null as value since the function uses row data for calculation
      }
    } else {
      // Default values for a new filled
      _filledRows = [
        {
          'total': 0.0,
          'rate': 0.0,
          'qty': 0.0,
          // 'weight': 0.0,
          'description': '',
          // 'weightController': TextEditingController(),
          'rateController': TextEditingController(),
          'qtyController': TextEditingController(),
          'descriptionController': TextEditingController(),
        },
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final filledProvider = Provider.of<FilledProvider>(context, listen: false);
    final _formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isReadOnly
              ? (languageProvider.isEnglish ? 'Update Filled' : 'فلڈ بنائیں')
              : (languageProvider.isEnglish ? 'Create Filled' : 'انوائس کو اپ ڈیٹ کریں'),
          style: TextStyle(color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal,
        centerTitle: true,
        actions: [
          IconButton(onPressed: (){
            final filledNumber = _filledId ?? generateFilledNumber();
            _generateAndPrintPDF(filledNumber);
          }, icon: Icon(Icons.print, color: Colors.white)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              widget.filled == null
                  ? '${languageProvider.isEnglish ? 'Filled #' : 'فلڈ نمبر#'}${generateFilledNumber()}'
                  : '${languageProvider.isEnglish ? 'Filled #' : 'فلڈ نمبر#'}${widget.filled!['filledNumber']}',
              style: TextStyle(color: Colors.white, fontSize: 14),            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Consumer<CustomerProvider>(
          builder: (context, customerProvider, child) {
            if (customerProvider.customers.isEmpty) {
              return const Center(child: CircularProgressIndicator()); // Show loading indicator if customers are still being fetched
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dropdown to select customer
                  Text(
                    languageProvider.isEnglish ? 'Select Customer:' : 'ایک کسٹمر منتخب کریں',
                    style: TextStyle(color: Colors.teal.shade800, fontSize: 18), // Title text color
                  ),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedCustomerId,
                    hint: Text(languageProvider.isEnglish ? 'Choose a customer' : 'ایک کسٹمر منتخب کریں'),
                    onChanged:_isReadOnly ? null :  (String? newValue) {
                      setState(() {
                        _selectedCustomerId = newValue;
                        _selectedCustomerName = customerProvider.customers
                            .firstWhere((customer) => customer.id == newValue)
                            .name; // Track the customer name
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return languageProvider.isEnglish
                            ? 'Please select a customer'
                            : 'براہ کرم ایک کسٹمر منتخب کریں';
                      }
                      return null;
                    },
                    items: customerProvider.customers.map<DropdownMenuItem<String>>((Customer customer) {
                      return DropdownMenuItem<String>(
                        value: customer.id,
                        child: Text(customer.name), // Display customer's name
                      );
                    }).toList(),
                  ),

                  // Show selected customer name
                  if (_selectedCustomerId != null)
                  // Text('${languageProvider.isEnglish ? 'Selected Customer:' : 'منتخب شدہ کسٹمر:'} ${customerProvider.customers.firstWhere((customer) => customer.id == _selectedCustomerId).name}',
                  //   style: TextStyle(color: Colors.teal.shade600),
                  // ),
                    Text(
                      '${languageProvider.isEnglish ? 'Selected Customer:' : 'منتخب شدہ کسٹمر:'} $_selectedCustomerName',
                      style: TextStyle(color: Colors.teal.shade600),
                    ),

                  // Space between sections
                  const SizedBox(height: 20),

                  // Display columns for the filled details
                  Text(languageProvider.isEnglish ? 'Filled Details:' : 'فلڈ کی تفصیلات:',
                    style: TextStyle(color: Colors.teal.shade800, fontSize: 18),                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width, // Ensures table takes up at least screen width
                      ),
                      child: Table(
                        border: TableBorder.all(),
                        columnWidths: const {
                          0: FlexColumnWidth(3),
                          1: FlexColumnWidth(3),
                          2: FlexColumnWidth(3),
                          3: FlexColumnWidth(3),
                          4: FlexColumnWidth(5),
                          5: FlexColumnWidth(3), // For Delete button column
                        },
                        children: [
                          TableRow(
                            children: [
                              TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(languageProvider.isEnglish ? 'Total' : 'کل', textAlign: TextAlign.center))),
                              TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(languageProvider.isEnglish ? 'FIlled Rate' : 'فلڈ کی قیمت', textAlign: TextAlign.center))),
                              TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(languageProvider.isEnglish ? 'Filled Qty' : 'فلڈ کی مقدار', textAlign: TextAlign.center))),
                              // TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(languageProvider.isEnglish ? 'Filled Weight(Kg)' : 'فلڈ کا وزن(کلوگرام)', textAlign: TextAlign.center))),
                              TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(languageProvider.isEnglish ? 'Description' : 'تفصیل', textAlign: TextAlign.center))),
                              TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(languageProvider.isEnglish ? 'Delete' : 'حذف کریں', textAlign: TextAlign.center))),
                            ],
                          ),
                          // Generate a row for each item in _filledRows
                          for (int i = 0; i < _filledRows.length; i++)
                            TableRow(
                              children: [
                                // Total
                                TableCell(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(_filledRows[i]['total']?.toStringAsFixed(2) ?? '0.00', textAlign: TextAlign.center),
                                  ),
                                ),
                                // Sarya Rate
                                TableCell(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: TextField(
                                      controller: _filledRows[i]['rateController'],
                                      enabled: !_isReadOnly, // Disable in read-only mode

                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),  // This allows only numeric input
                                      ],
                                      onChanged: (value) {
                                        _updateRow(i, 'rate', double.tryParse(value) ?? 0.0);
                                      },
                                      decoration: InputDecoration(hintText: languageProvider.isEnglish ? 'Rate' : 'قیمت',
                                        hintStyle: TextStyle(color: Colors.teal.shade600),
                                      ),
                                    ),
                                  ),
                                ),
                                // Sarya Qty
                                TableCell(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: TextField(
                                      controller: _filledRows[i]['qtyController'],
                                      enabled: !_isReadOnly, // Disable in read-only mode

                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,  // This allows only numeric input
                                      ],
                                      onChanged: (value) {
                                        _updateRow(i, 'qty', double.tryParse(value) ?? 0.0);
                                      },
                                      decoration:  InputDecoration(hintText: languageProvider.isEnglish ? 'Qty' : 'مقدار',
                                        hintStyle: TextStyle(color: Colors.teal.shade600),),
                                    ),
                                  ),
                                ),
                                // Description
                                TableCell(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: TextField(
                                      controller: _filledRows[i]['descriptionController'],
                                      enabled: !_isReadOnly, // Disable in read-only mode

                                      onChanged: (value) {
                                        _updateRow(i, 'description', value);
                                      },
                                      decoration:  InputDecoration(hintText: languageProvider.isEnglish ? 'Description' : 'تفصیل',
                                        hintStyle: TextStyle(color: Colors.teal.shade600),),
                                    ),
                                  ),
                                ),
                                // Delete Button
                                TableCell(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: IconButton(
                                      icon: const Icon(Icons.delete,color: Colors.red,),
                                      onPressed: () {
                                        _deleteRow(i); // Delete the current row
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  // add row button
                  IconButton(onPressed: (){
                    _addNewRow();
                  }, icon: const Icon(Icons.add, color: Colors.teal)),
                  // Subtotal row
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        '${languageProvider.isEnglish ? 'Subtotal:' : 'کل رقم:'} ${_calculateSubtotal().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800, // Subtotal text color
                        ),                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(languageProvider.isEnglish ? 'Discount (Amount):' : 'رعایت (رقم):', style: const TextStyle(fontSize: 18)),
                  TextField(
                    controller: _discountController,
                    enabled: !_isReadOnly, // Disable in read-only mode

                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        double parsedDiscount = double.tryParse(value) ?? 0.0;
                        // Check if the discount is greater than the subtotal
                        if (parsedDiscount > _calculateSubtotal()) {
                          // If it is, you can either reset the value or show a warning
                          _discount = _calculateSubtotal();  // Set discount to subtotal if greater
                          // Optionally, show an error message to the user
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(languageProvider.isEnglish ? 'Discount cannot be greater than subtotal.' : 'رعایت کل رقم سے زیادہ نہیں ہو سکتی۔')),
                          );
                        } else {
                          _discount = parsedDiscount;
                        }
                      });
                    },
                    decoration: InputDecoration(hintText: languageProvider.isEnglish ? 'Enter discount' : 'رعایت درج کریں'),
                  ),
                  // Grand Total row
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        '${languageProvider.isEnglish ? 'Grand Total:' : 'مجموعی کل:'} ${_calculateGrandTotal().toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Payment Type
                  Text(
                    languageProvider.isEnglish ? 'Payment Type:' : 'ادائیگی کی قسم:',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  RadioListTile<String>(
                                    value: 'instant',
                                    groupValue: _paymentType,
                                    title: Text(languageProvider.isEnglish ? 'Instant Payment' : 'فوری ادائیگی'),
                                    onChanged:_isReadOnly ? null : (value) {
                                      setState(() {
                                        _paymentType = value!;
                                        _instantPaymentMethod = null; // Reset instant payment method

                                      });
                                    },
                                  ),
                                  RadioListTile<String>(
                                    value: 'udhaar',
                                    groupValue: _paymentType,
                                    title: Text(languageProvider.isEnglish ? 'Udhaar Payment' : 'ادھار ادائیگی'),
                                    onChanged:_isReadOnly ? null :  (value) {
                                      setState(() {
                                        _paymentType = value!;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            if (_paymentType == 'instant')
                              Expanded(
                                child: Column(
                                  children: [
                                    RadioListTile<String>(
                                      value: 'cash',
                                      groupValue: _instantPaymentMethod,
                                      title: Text(languageProvider.isEnglish ? 'Cash Payment' : 'نقد ادائیگی'),
                                      onChanged: _isReadOnly ? null : (value) {
                                        setState(() {
                                          _instantPaymentMethod = value!;
                                        });
                                      },
                                    ),
                                    RadioListTile<String>(
                                      value: 'online',
                                      groupValue: _instantPaymentMethod,
                                      title: Text(languageProvider.isEnglish ? 'Online Bank Transfer' : 'آن لائن بینک ٹرانسفر'),
                                      onChanged: _isReadOnly ? null : (value) {
                                        setState(() {
                                          _instantPaymentMethod = value!;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        // Add validation messages
                        if (_paymentType == null)
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Text(
                              languageProvider.isEnglish
                                  ? 'Please select a payment type'
                                  : 'براہ کرم ادائیگی کی قسم منتخب کریں',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        if (_paymentType == 'instant' && _instantPaymentMethod == null)
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Text(
                              languageProvider.isEnglish
                                  ? 'Please select an instant payment method'
                                  : 'براہ کرم فوری ادائیگی کا طریقہ منتخب کریں',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!_isReadOnly)
                    ElevatedButton(
                      onPressed: _isButtonPressed
                          ? null
                          : () async {
                        setState(() {
                          _isButtonPressed = true; // Disable the button when pressed
                        });

                        try {
                          // Validate customer selection
                          if (_selectedCustomerId == null || _selectedCustomerName == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  languageProvider.isEnglish
                                      ? 'Please select a customer'
                                      : 'براہ کرم کسٹمر منتخب کریں',
                                ),
                              ),
                            );
                            return;
                          }

                          // Validate payment type
                          if (_paymentType == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  languageProvider.isEnglish
                                      ? 'Please select a payment type'
                                      : 'براہ کرم ادائیگی کی قسم منتخب کریں',
                                ),
                              ),
                            );
                            return;
                          }

                          // Validate instant payment method if "Instant Payment" is selected
                          if (_paymentType == 'instant' && _instantPaymentMethod == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  languageProvider.isEnglish
                                      ? 'Please select an instant payment method'
                                      : 'براہ کرم فوری ادائیگی کا طریقہ منتخب کریں',
                                ),
                              ),
                            );
                            return;
                          }

                          // Validate rate fields
                          for (var row in _filledRows) {
                            if (row['rate'] == null || row['rate'] <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    languageProvider.isEnglish
                                        ? 'Rate cannot be zero or less'
                                        : 'ریٹ صفر یا اس سے کم نہیں ہو سکتا',
                                  ),
                                ),
                              );
                              return;
                            }
                          }

                          // Validate discount amount
                          final subtotal = _calculateSubtotal();
                          if (_discount >= subtotal) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  languageProvider.isEnglish
                                      ? 'Discount amount cannot be greater than or equal to the subtotal'
                                      : 'ڈسکاؤنٹ کی رقم سب ٹوٹل سے زیادہ یا اس کے برابر نہیں ہو سکتی',
                                ),
                              ),
                            );
                            return; // Do not save or print if discount is invalid
                          }

                          final filledNumber = _filledId ?? generateFilledNumber();
                          final grandTotal = _calculateGrandTotal();

                          // Try saving the filled
                          if (_filledId != null) {
                            // Update existing filled
                            await Provider.of<FilledProvider>(context, listen: false).updateFilled(
                              filledId: _filledId!, // Pass the correct ID for updating
                              filledNumber: filledNumber,
                              customerId: _selectedCustomerId!,
                              customerName: _selectedCustomerName!,
                              subtotal: subtotal,
                              discount: _discount,
                              grandTotal: grandTotal,
                              paymentType: _paymentType,
                              paymentMethod: _instantPaymentMethod,
                              items: _filledRows,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  languageProvider.isEnglish
                                      ? 'Filled updated successfully'
                                      : 'فلڈ کامیابی سے تبدیل ہوگئی',
                                ),
                              ),
                            );
                          } else {
                            // Save new filled
                            await Provider.of<FilledProvider>(context, listen: false).saveFilled(
                              filledId: filledNumber, // Pass the filled number (or generated ID)
                              filledNumber: filledNumber,
                              customerId: _selectedCustomerId!,
                              customerName: _selectedCustomerName!,
                              subtotal: subtotal,
                              discount: _discount,
                              grandTotal: grandTotal,
                              paymentType: _paymentType,
                              paymentMethod: _instantPaymentMethod,
                              items: _filledRows,
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  languageProvider.isEnglish
                                      ? 'Filled saved successfully'
                                      : 'فلڈ کامیابی سے محفوظ ہوگئی',
                                ),
                              ),
                            );
                          }

                          // Navigate to the filled list page
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => filledListpage()),
                          );
                        } catch (e) {
                          // Show error message
                          print(e);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                languageProvider.isEnglish
                                    ? 'Failed to save filled'
                                    : 'فلڈ محفوظ کرنے میں ناکام',
                              ),
                            ),
                          );
                        } finally {
                          setState(() {
                            _isButtonPressed = false; // Re-enable button after the operation is complete
                          });
                        }
                      },
                      child: Text(
                        widget.filled == null
                            ? (languageProvider.isEnglish ? 'Save Filled' : 'فلڈ محفوظ کریں')
                            : (languageProvider.isEnglish ? 'Update Filled' : 'فلڈ کو اپ ڈیٹ کریں'),
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade400, // Button background color
                      ),
                    )
                  //   ElevatedButton  (
                  //   onPressed: () async {
                  //     // Validate customer selection
                  //     if (_selectedCustomerId == null || _selectedCustomerName == null) {
                  //       ScaffoldMessenger.of(context).showSnackBar(
                  //         SnackBar(
                  //           content: Text(
                  //             languageProvider.isEnglish
                  //                 ? 'Please select a customer'
                  //                 : 'براہ کرم کسٹمر منتخب کریں',
                  //           ),
                  //         ),
                  //       );
                  //       return;
                  //     }
                  //
                  //     // Validate payment type
                  //     if (_paymentType == null) {
                  //       ScaffoldMessenger.of(context).showSnackBar(
                  //         SnackBar(
                  //           content: Text(
                  //             languageProvider.isEnglish
                  //                 ? 'Please select a payment type'
                  //                 : 'براہ کرم ادائیگی کی قسم منتخب کریں',
                  //           ),
                  //         ),
                  //       );
                  //       return;
                  //     }
                  //
                  //     // Validate instant payment method if "Instant Payment" is selected
                  //     if (_paymentType == 'instant' && _instantPaymentMethod == null) {
                  //       ScaffoldMessenger.of(context).showSnackBar(
                  //         SnackBar(
                  //           content: Text(
                  //             languageProvider.isEnglish
                  //                 ? 'Please select an instant payment method'
                  //                 : 'براہ کرم فوری ادائیگی کا طریقہ منتخب کریں',
                  //           ),
                  //         ),
                  //       );
                  //       return;
                  //     }
                  //
                  //     // Validate weight and rate fields
                  //     for (var row in _filledRows) {
                  //       // if (row['weight'] == null || row['weight'] <= 0) {
                  //       //   ScaffoldMessenger.of(context).showSnackBar(
                  //       //     SnackBar(
                  //       //       content: Text(
                  //       //         languageProvider.isEnglish
                  //       //             ? 'Weight cannot be zero or less'
                  //       //             : 'وزن صفر یا اس سے کم نہیں ہو سکتا',
                  //       //       ),
                  //       //     ),
                  //       //   );
                  //       //   return;
                  //       // }
                  //
                  //       if (row['rate'] == null || row['rate'] <= 0) {
                  //         ScaffoldMessenger.of(context).showSnackBar(
                  //           SnackBar(
                  //             content: Text(
                  //               languageProvider.isEnglish
                  //                   ? 'Rate cannot be zero or less'
                  //                   : 'ریٹ صفر یا اس سے کم نہیں ہو سکتا',
                  //             ),
                  //           ),
                  //         );
                  //         return;
                  //       }
                  //     }
                  //
                  //     // Validate discount amount
                  //     final subtotal = _calculateSubtotal();
                  //     if (_discount >= subtotal) {
                  //       ScaffoldMessenger.of(context).showSnackBar(
                  //         SnackBar(
                  //           content: Text(
                  //             languageProvider.isEnglish
                  //                 ? 'Discount amount cannot be greater than or equal to the subtotal'
                  //                 : 'ڈسکاؤنٹ کی رقم سب ٹوٹل سے زیادہ یا اس کے برابر نہیں ہو سکتی',
                  //           ),
                  //         ),
                  //       );
                  //       return; // Do not save or print if discount is invalid
                  //     }
                  //     final filledNumber = _filledId ?? generateFilledNumber();
                  //     final grandTotal = _calculateGrandTotal();
                  //     // Try saving the filled
                  //     try {
                  //       if (_filledId != null) {
                  //         // Update existing filled
                  //         await Provider.of<FilledProvider>(context, listen: false).updateFilled(
                  //           filledId: _filledId!, // Pass the correct ID for updating
                  //           filledNumber: filledNumber,
                  //           customerId: _selectedCustomerId!,
                  //           customerName: _selectedCustomerName!,
                  //           subtotal: subtotal,
                  //           discount: _discount,
                  //           grandTotal: grandTotal,
                  //           paymentType: _paymentType,
                  //           paymentMethod: _instantPaymentMethod,
                  //           items: _filledRows,
                  //         );
                  //         ScaffoldMessenger.of(context).showSnackBar(
                  //           SnackBar(
                  //             content: Text(
                  //               languageProvider.isEnglish
                  //                   ? 'Filled updated successfully'
                  //                   : 'فلڈ کامیابی سے تبدیل ہوگئی',
                  //             ),
                  //           ),
                  //         );
                  //       }
                  //       else {
                  //         // Save new filled
                  //         await Provider.of<FilledProvider>(context, listen: false).saveFilled(
                  //           filledId: filledNumber, // Pass the filled number (or generated ID)
                  //           filledNumber: filledNumber,
                  //           customerId: _selectedCustomerId!,
                  //           customerName: _selectedCustomerName!,
                  //           subtotal: subtotal,
                  //           discount: _discount,
                  //           grandTotal: grandTotal,
                  //           paymentType: _paymentType,
                  //           paymentMethod: _instantPaymentMethod,
                  //           items: _filledRows,
                  //         );
                  //
                  //         ScaffoldMessenger.of(context).showSnackBar(
                  //           SnackBar(
                  //             content: Text(
                  //               languageProvider.isEnglish
                  //                   ? 'Filled saved successfully'
                  //                   : 'فلڈ کامیابی سے محفوظ ہوگئی',
                  //             ),
                  //           ),
                  //         );
                  //
                  //       }
                  //       // Generate and print the PDF
                  //       // await _generateAndPrintPDF(filledNumber);
                  //
                  //       // Navigate back
                  //       // Navigator.pop(context);
                  //       Navigator.pushReplacement(
                  //         context,
                  //         MaterialPageRoute(builder: (context) => filledListpage()),
                  //       );
                  //     } catch (e) {
                  //       // Show error message
                  //       print(e);
                  //       ScaffoldMessenger.of(context).showSnackBar(
                  //         SnackBar(
                  //           content: Text(
                  //             languageProvider.isEnglish
                  //                 ? 'Failed to save filled'
                  //                 : 'انوائس محفوظ کرنے میں ناکام',
                  //           ),
                  //         ),
                  //       );
                  //     }
                  //   },
                  //   child: Text(
                  //     widget.filled == null
                  //         ? (languageProvider.isEnglish ? 'Save Filled' : 'فلڈ محفوظ کریں')
                  //         : (languageProvider.isEnglish ? 'Update Filled' : 'فلڈ کو اپ ڈیٹ کریں'),
                  //     style: TextStyle(color: Colors.white),
                  //   ),
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Colors.teal.shade400, // Button background color
                  //   ),
                  // )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
