import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../Provider/customerprovider.dart';
import '../Provider/invoice provider.dart';
import '../Provider/lanprovider.dart'; // Import your customer provider

class InvoicePage extends StatefulWidget {
  final Map<String, dynamic>? invoice; // Optional invoice data for editing

  InvoicePage({this.invoice});

  @override
  _InvoicePageState createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  String? _selectedCustomerName; // This should hold the name of the selected customer
  String? _selectedCustomerId;
  double _discount = 0.0; // Discount amount or percentage
  String _paymentType = 'instant';
  String? _instantPaymentMethod;
  TextEditingController _discountController = TextEditingController();
  List<Map<String, dynamic>> _invoiceRows = [];
  String? _invoiceId; // For editing existing invoices
  late bool _isReadOnly;

  String generateInvoiceNumber() {
    // Generate a timestamp as invoice number (in milliseconds)
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  void _addNewRow() {
    setState(() {
      _invoiceRows.add({
        'total': 0.0,
        'rate': 0.0,
        'qty': 0.0,
        'weight': 0.0,
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
      _invoiceRows[index][field] = value;

      // If both Sarya Rate and Sarya Qty are filled, calculate the Total
      if (_invoiceRows[index]['rate'] != 0.0 && _invoiceRows[index]['qty'] != 0.0) {
        _invoiceRows[index]['total'] = _invoiceRows[index]['rate'] * _invoiceRows[index]['weight'];
      }
    });
  }

  void _deleteRow(int index) {
    setState(() {
      _invoiceRows.removeAt(index);
    });
  }

  double _calculateSubtotal() {
     // return _invoiceRows.fold(0.0, (sum, row) => sum + row['total']);
       return _invoiceRows.fold(0.0, (sum, row) => sum + (row['total'] ?? 0.0));
  }

  double _calculateGrandTotal() {
    double subtotal = _calculateSubtotal();
    // Discount is directly subtracted from subtotal
    double discountAmount = _discount;
    return subtotal - discountAmount;
  }

  Future<void> _generateAndPrintPDF(String invoiceNumber) async {
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


    // Load the image from assets
    final ByteData bytes = await rootBundle.load('images/logo.png');
    final Uint8List imageBytes = bytes.buffer.asUint8List();
    final pw.MemoryImage logoImage = pw.MemoryImage(imageBytes);
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 0, vertical: 2),  // Reduced side margins
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Company Logo and Invoice Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Image(logoImage, width: 70, height: 70), // Adjust width and height as needed
                    pw.Text(
                      languageProvider.isEnglish ? 'Invoice' : 'انوائس',
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.Divider(),
                // Customer Information
                pw.Text(
                  '${languageProvider.isEnglish ? 'Customer Name:' : 'کسٹمر کا نام:'} ${selectedCustomer.name}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  '${languageProvider.isEnglish ? 'Customer Number:' : 'کسٹمر نمبر:'} ${selectedCustomer.phone}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  '${languageProvider.isEnglish ? 'Customer Address:' : 'کسٹمر پتہ:'} ${selectedCustomer.address ?? ''}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  '${languageProvider.isEnglish ? 'Date:' : 'تاریخ:'} $formattedDate',
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.Text(
                  '${languageProvider.isEnglish ? 'Time:' : 'وقت:'} $formattedTime',
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.SizedBox(height: 10),
                // Invoice Table
                pw.Table.fromTextArray(
                  headers: [
                    pw.Text(
                      languageProvider.isEnglish ? 'Description' : 'تفصیل',
                      style: const pw.TextStyle(fontSize: 8),  // Reduced font size
                    ),
                    pw.Text(
                      languageProvider.isEnglish ? 'Sarya Weight' : 'سرئے کا وزن',
                      style: const pw.TextStyle(fontSize: 10),  // Reduced font size
                    ),
                    pw.Text(
                      languageProvider.isEnglish ? 'Sarya Qty' : 'سرئے کی مقدار',
                      style: const pw.TextStyle(fontSize: 10),  // Reduced font size
                    ),
                    pw.Text(
                      languageProvider.isEnglish ? 'Sarya Rate' : 'سرئے کی قیمت',
                      style: const pw.TextStyle(fontSize: 10),  // Reduced font size
                    ),
                    pw.Text(
                      languageProvider.isEnglish ? 'Total' : 'کل',
                      style: const pw.TextStyle(fontSize: 10),  // Reduced font size
                    ),
                  ],
                  data: _invoiceRows.map((row) {
                    return [
                      pw.Text(row['description'], style: const pw.TextStyle(fontSize: 8)),  // Reduced font size for data
                      pw.Text(row['weight'].toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8)),  // Reduced font size for data
                      pw.Text(row['qty'].toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8)),  // Reduced font size for data
                      pw.Text(row['rate'].toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8)),  // Reduced font size for data
                      pw.Text(row['total'].toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8)),  // Reduced font size for data
                    ];
                  }).toList(),
                ),
                pw.SizedBox(height: 10),
                // Totals Section
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('${languageProvider.isEnglish ? 'Sub Total:' : 'کل رقم:'}'),
                    pw.Text(_calculateSubtotal().toStringAsFixed(2)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('${languageProvider.isEnglish ? 'Discount:' : 'رعایت:'}'),
                    pw.Text(_discount.toStringAsFixed(2)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${languageProvider.isEnglish ? 'Grand Total:' : 'مجموعی کل:'}',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      _calculateGrandTotal().toStringAsFixed(2),
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                // Footer
                // Previous Balance Section (Remaining Balance)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      languageProvider.isEnglish ? 'Previous Balance:' : 'پچھلا بیلنس:',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                    pw.Text(
                      remainingBalance.toStringAsFixed(2),
                      style:  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(
                      '......................',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    // Print or preview the PDF
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  Future<double> _getRemainingBalance(String customerId) async {
    try {
      // Reference to the customer's ledger in Firebase
      final customerLedgerRef = _db.child('ledger').child(customerId);

      // Get the most recent entry based on the 'createdAt' field
      final DatabaseEvent snapshot = await customerLedgerRef.orderByChild('createdAt').limitToLast(1).once();

      if (snapshot.snapshot.exists) {
        // The snapshot will contain the data in a Map form
        final Map<dynamic, dynamic> ledgerEntries = snapshot.snapshot.value as Map<dynamic, dynamic>;

        // Get the last entry (since we ordered by 'createdAt' and limited to last 1)
        final lastEntryKey = ledgerEntries.keys.first; // Get the key of the first (and only) entry
        final lastEntry = ledgerEntries[lastEntryKey];

        if (lastEntry != null && lastEntry is Map) {
          // Get the remaining balance from the last entry
          final double remainingBalance = lastEntry['remainingBalance'] ?? 0.0;
          return remainingBalance;
        }
      }

      // If no ledger entry exists, return 0 as default
      return 0.0;
    } catch (e) {
      print("Error fetching remaining balance: $e");
      return 0.0; // Return 0 if there's an error
    }
  }



  @override
  void dispose() {
    for (var row in _invoiceRows) {
      row['weightController']?.dispose();
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
    _isReadOnly = widget.invoice != null; // Set read-only if invoice is passed

    if (widget.invoice != null) {
      // Populate fields for editing
      final invoice = widget.invoice!;
      _discount = widget.invoice!['discount'];
      _discountController.text = _discount.toString(); // Initialize controller with discount value
      _invoiceId = invoice['invoiceNumber']; // Save the invoice ID for updates
      _selectedCustomerId = invoice['customerId'];
      _discount = invoice['discount'];
      _paymentType = invoice['paymentType'];
      _instantPaymentMethod = invoice['paymentMethod'];
      // _invoiceRows = List<Map<String, dynamic>>.from(invoice['items']); // Populate table rows
      _invoiceRows = List<Map<String, dynamic>>.from(invoice['items']).map((row) {
        return {
          ...row,
          'weightController': TextEditingController(text: row['weight'].toString()),
          'rateController': TextEditingController(text: row['rate'].toString()),
          'qtyController': TextEditingController(text: row['qty'].toString()),
          'descriptionController': TextEditingController(text: row['description']),
        };
      }).toList();
      // Update each row's total
      for (int i = 0; i < _invoiceRows.length; i++) {
        _updateRow(i, 'total', null); // Pass null as value since the function uses row data for calculation
      }
    } else {
      // Default values for a new invoice
      _invoiceRows = [
        {
          'total': 0.0,
          'rate': 0.0,
          'qty': 0.0,
          'weight': 0.0,
          'description': '',
          'weightController': TextEditingController(),
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
    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
    final _formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          // widget.invoice == null
          _isReadOnly
              ? (languageProvider.isEnglish ? 'Create Invoice' : 'انوائس بنائیں')
              : (languageProvider.isEnglish ? 'Update Invoice' : 'انوائس کو اپ ڈیٹ کریں'),
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        centerTitle: true,
        actions: [
          IconButton(onPressed: (){
            final invoiceNumber = _invoiceId ?? generateInvoiceNumber();
            _generateAndPrintPDF(invoiceNumber);
          }, icon: Icon(Icons.print, color: Colors.white)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              widget.invoice == null
                  ? '${languageProvider.isEnglish ? 'Invoice #' : 'انوائس نمبر#'}${generateInvoiceNumber()}'
                  : '${languageProvider.isEnglish ? 'Invoice #' : 'انوائس نمبر#'}${widget.invoice!['invoiceNumber']}',
              style: TextStyle(color: Colors.white, fontSize: 16),            ),
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
                    // onChanged: (String? newValue) {
                    onChanged: _isReadOnly ? null : (String? newValue) {
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

                  // Display columns for the invoice details
                  Text(languageProvider.isEnglish ? 'Invoice Details:' : 'انوائس کی تفصیلات:',
                    style: TextStyle(color: Colors.teal.shade800, fontSize: 18),                  ),
                  Table(
                    border: TableBorder.all(),
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(2),
                      3: FlexColumnWidth(2),
                      4: FlexColumnWidth(3),
                      5: FlexColumnWidth(1), // For Delete button column
                    },
                    children: [
                      TableRow(
                        children: [
                           TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(languageProvider.isEnglish ? 'Total' : 'کل', textAlign: TextAlign.center))),
                           TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(languageProvider.isEnglish ? 'Sarya Rate' : 'سرئے کی قیمت', textAlign: TextAlign.center))),
                           TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(languageProvider.isEnglish ? 'Sarya Qty' : 'سرئے کی مقدار', textAlign: TextAlign.center))),
                           TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(languageProvider.isEnglish ? 'Sarya Weight(Kg)' : 'سرئے کا وزن(کلوگرام)', textAlign: TextAlign.center))),
                           TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(languageProvider.isEnglish ? 'Description' : 'تفصیل', textAlign: TextAlign.center))),
                           TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(languageProvider.isEnglish ? 'Delete' : 'حذف کریں', textAlign: TextAlign.center))),
                        ],
                      ),
                      // Generate a row for each item in _invoiceRows
                      for (int i = 0; i < _invoiceRows.length; i++)
                        TableRow(
                          children: [
                            // Total
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(_invoiceRows[i]['total']?.toStringAsFixed(2) ?? '0.00', textAlign: TextAlign.center),
                              ),
                            ),
                            // Sarya Rate
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  // controller: TextEditingController(text: _invoiceRows[i]['rate'].toString()),
                                  controller: _invoiceRows[i]['rateController'],
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
                                  // controller: TextEditingController(text: _invoiceRows[i]['qty'].toString()),
                                  controller: _invoiceRows[i]['qtyController'],
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
                            // Sarya Weight
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  // controller: TextEditingController(text: _invoiceRows[i]['weight'].toString()),
                                  controller: _invoiceRows[i]['weightController'],
                                  enabled: !_isReadOnly, // Disable in read-only mode

                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),  // This allows only numeric input
                                  ],
                                  onChanged: (value) {
                                    _updateRow(i, 'weight', double.tryParse(value) ?? 0.0);
                                  },
                                  decoration:  InputDecoration(hintText: languageProvider.isEnglish ? 'Weight' : 'وزن',
                                    hintStyle: TextStyle(color: Colors.teal.shade600),),
                                ),
                              ),
                            ),
                            // Description
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  // controller: TextEditingController(text: _invoiceRows[i]['description']),
                                  controller: _invoiceRows[i]['descriptionController'],
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
                                    onChanged: _isReadOnly ? null : (value) {
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
                                    onChanged: _isReadOnly ? null : (value) {
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
                  ElevatedButton  (
                    onPressed: () async {
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

                      // Validate weight and rate fields
                      for (var row in _invoiceRows) {
                        if (row['weight'] == null || row['weight'] <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                languageProvider.isEnglish
                                    ? 'Weight cannot be zero or less'
                                    : 'وزن صفر یا اس سے کم نہیں ہو سکتا',
                              ),
                            ),
                          );
                          return;
                        }

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
                      final invoiceNumber = _invoiceId ?? generateInvoiceNumber();
                      final grandTotal = _calculateGrandTotal();
                      // Try saving the invoice
                      try {
                        if (_invoiceId != null) {
                          // Update existing invoice
                          await Provider.of<InvoiceProvider>(context, listen: false).updateInvoice(
                            invoiceId: _invoiceId!, // Pass the correct ID for updating
                            invoiceNumber: invoiceNumber,
                            customerId: _selectedCustomerId!,
                            customerName: _selectedCustomerName!,
                            subtotal: subtotal,
                            discount: _discount,
                            grandTotal: grandTotal,
                            paymentType: _paymentType,
                            paymentMethod: _instantPaymentMethod,
                            items: _invoiceRows,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                languageProvider.isEnglish
                                    ? 'Invoice updated successfully'
                                    : 'انوائس کامیابی سے تبدیل ہوگئی',
                              ),
                            ),
                          );
                        }
                        else {
                          // Save new invoice
                          await Provider.of<InvoiceProvider>(context, listen: false).saveInvoice(
                            invoiceId: invoiceNumber, // Pass the invoice number (or generated ID)
                            invoiceNumber: invoiceNumber,
                            customerId: _selectedCustomerId!,
                            customerName: _selectedCustomerName!,
                            subtotal: subtotal,
                            discount: _discount,
                            grandTotal: grandTotal,
                            paymentType: _paymentType,
                            paymentMethod: _instantPaymentMethod,
                            items: _invoiceRows,
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                languageProvider.isEnglish
                                    ? 'Invoice saved successfully'
                                    : 'انوائس کامیابی سے محفوظ ہوگئی',
                              ),
                            ),
                          );

                        }
                        // Generate and print the PDF
                        await _generateAndPrintPDF(invoiceNumber);

                        // Navigate back
                        Navigator.pop(context);
                      } catch (e) {
                        // Show error message
                        print(e);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              languageProvider.isEnglish
                                  ? 'Failed to save invoice'
                                  : 'انوائس محفوظ کرنے میں ناکام',
                            ),
                          ),
                        );
                      }
                    },
                    // child: Text(
                    //   languageProvider.isEnglish ? 'Save Invoice' : 'انوائس محفوظ کریں',
                    // ),
                    child: Text(
                      widget.invoice == null
                          ? (languageProvider.isEnglish ? 'Save Invoice' : 'انوائس محفوظ کریں')
                          : (languageProvider.isEnglish ? 'Update Invoice' : 'انوائس کو اپ ڈیٹ کریں'),
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade400, // Button background color
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
