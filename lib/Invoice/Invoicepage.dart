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
  @override
  _InvoicePageState createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  String? _selectedCustomerId;
  double _discount = 0.0; // Discount amount or percentage
  String _paymentType = 'instant';
  String? _instantPaymentMethod;
  List<Map<String, dynamic>> _invoiceRows = [
    {
      'total': 0.0,
      'rate': 0.0,
      'qty': 0.0,
      'weight': 0.0,
      'description': '',
    },
  ];

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
    return _invoiceRows.fold(0.0, (sum, row) => sum + row['total']);
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
                pw.Text(
                  languageProvider.isEnglish ? 'Previous Balance: [Placeholder]' : 'پچھلا بیلنس: [Placeholder]',
                  style: const pw.TextStyle(fontSize: 14),
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

  @override
  void initState() {
    super.initState();
    // Fetch the customers when the page is initialized
    Provider.of<CustomerProvider>(context, listen: false).fetchCustomers();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
    final _formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.isEnglish ? 'Create Invoice' : 'انوائس بنائیں'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '${languageProvider.isEnglish ? 'Invoice #' : 'انوائس نمبر#'}${generateInvoiceNumber()}',
              style: const TextStyle(fontSize: 16),
            ),
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
                  const Text('Select Customer:', style: TextStyle(fontSize: 18)),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedCustomerId,
                    hint: Text(languageProvider.isEnglish ? 'Choose a customer' : 'ایک کسٹمر منتخب کریں'),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCustomerId = newValue;
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
                    Text('${languageProvider.isEnglish ? 'Selected Customer:' : 'منتخب شدہ کسٹمر:'} ${customerProvider.customers.firstWhere((customer) => customer.id == _selectedCustomerId).name}'),

                  // Space between sections
                  const SizedBox(height: 20),

                  // Display columns for the invoice details
                  Text(languageProvider.isEnglish ? 'Invoice Details:' : 'انوائس کی تفصیلات:', style: const TextStyle(fontSize: 18)),
                  Table(
                    border: TableBorder.all(),
                    columnWidths: {
                      0: const FlexColumnWidth(2),
                      1: const FlexColumnWidth(2),
                      2: const FlexColumnWidth(2),
                      3: const FlexColumnWidth(2),
                      4: const FlexColumnWidth(3),
                      5: const FlexColumnWidth(1), // For Delete button column
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
                                child: Text(_invoiceRows[i]['total'].toStringAsFixed(2), textAlign: TextAlign.center),
                              ),
                            ),
                            // Sarya Rate
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),  // This allows only numeric input
                                  ],
                                  onChanged: (value) {
                                    _updateRow(i, 'rate', double.tryParse(value) ?? 0.0);
                                  },
                                  decoration: InputDecoration(hintText: languageProvider.isEnglish ? 'Rate' : 'قیمت'),
                                ),
                              ),
                            ),
                            // Sarya Qty
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,  // This allows only numeric input
                                  ],
                                  onChanged: (value) {
                                    _updateRow(i, 'qty', double.tryParse(value) ?? 0.0);
                                  },
                                  decoration:  InputDecoration(hintText: languageProvider.isEnglish ? 'Qty' : 'مقدار'),
                                ),
                              ),
                            ),
                            // Sarya Weight
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),  // This allows only numeric input
                                  ],
                                  onChanged: (value) {
                                    _updateRow(i, 'weight', double.tryParse(value) ?? 0.0);
                                  },
                                  decoration:  InputDecoration(hintText: languageProvider.isEnglish ? 'Weight' : 'وزن'),
                                ),
                              ),
                            ),
                            // Description
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  onChanged: (value) {
                                    _updateRow(i, 'description', value);
                                  },
                                  decoration:  InputDecoration(hintText: languageProvider.isEnglish ? 'Description' : 'تفصیل'),
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
                  }, icon: const Icon(Icons.add)),
                  // Subtotal row
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        '${languageProvider.isEnglish ? 'Subtotal:' : 'کل رقم:'} ${_calculateSubtotal().toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(languageProvider.isEnglish ? 'Discount (Amount):' : 'رعایت (رقم):', style: const TextStyle(fontSize: 18)),
                  TextField(
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
                                    onChanged: (value) {
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
                                    onChanged: (value) {
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
                                      onChanged: (value) {
                                        setState(() {
                                          _instantPaymentMethod = value!;
                                        });
                                      },
                                    ),
                                    RadioListTile<String>(
                                      value: 'online',
                                      groupValue: _instantPaymentMethod,
                                      title: Text(languageProvider.isEnglish ? 'Online Bank Transfer' : 'آن لائن بینک ٹرانسفر'),
                                      onChanged: (value) {
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

                  ElevatedButton(
                    onPressed: () async {
                      // Validate customer selection
                      if (_selectedCustomerId == null) {
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

                      // Generate invoice details
                      final invoiceNumber = generateInvoiceNumber();
                      final grandTotal = _calculateGrandTotal();

                      // Try saving the invoice
                      try {
                        await invoiceProvider.saveInvoice(
                          invoiceNumber: invoiceNumber,
                          customerId: _selectedCustomerId!,
                          subtotal: subtotal,
                          discount: _discount,
                          grandTotal: grandTotal,
                          paymentType: _paymentType,
                          paymentMethod: _instantPaymentMethod,
                          items: _invoiceRows,
                        );

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              languageProvider.isEnglish
                                  ? 'Invoice saved successfully'
                                  : 'انوائس کامیابی سے محفوظ ہوگئی',
                            ),
                          ),
                        );

                        // Generate and print the PDF
                        await _generateAndPrintPDF(invoiceNumber);

                        // Navigate back
                        Navigator.pop(context);
                      } catch (e) {
                        // Show error message
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
                    child: Text(
                      languageProvider.isEnglish ? 'Save Invoice' : 'انوائس محفوظ کریں',
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
