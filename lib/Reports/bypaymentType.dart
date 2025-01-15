import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // For formatting dates
import 'package:provider/provider.dart';
import '../Provider/customerprovider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../Provider/lanprovider.dart';
class PaymentTypeReportPage extends StatefulWidget {
  final String? customerId;
  final String? customerName;
  final String? customerPhone;

  PaymentTypeReportPage({
    this.customerId,
    this.customerName,
    this.customerPhone,
  });

  @override
  _PaymentTypeReportPageState createState() => _PaymentTypeReportPageState();
}

class _PaymentTypeReportPageState extends State<PaymentTypeReportPage> {
  String? _selectedPaymentType = 'all'; // Filter by payment type: 'udhaar' or 'instant'
  String? _selectedCustomerId; // Filter by customer ID
  String? _selectedCustomerName; // Store selected customer name
  DateTimeRange? _selectedDateRange; // Date range picker
  String? _selectedPaymentMethod = 'all'; // Filter by payment method (online, cash)
  FirebaseDatabase _db = FirebaseDatabase.instance;  // Initialize Firebase Database

  List<Map<String, dynamic>> _reportData = [];
  @override
  void initState() {
    super.initState();
    _fetchTodayReportData(); // Fetch today's report by default
  }

  // Fetch today's report data by default
  Future<void> _fetchTodayReportData() async {
    final DateTime now = DateTime.now();
    final DateTime startOfDay = DateTime(now.year, now.month, now.day); // Midnight of today
    final DateTime endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)); // Last millisecond of today

    // Set the selected date range to today
    _selectedDateRange = DateTimeRange(start: startOfDay, end: endOfDay);

    // Call the function to fetch data based on today's date
    _fetchReportData();
  }

  // Fetch report data based on filters
  Future<void> _fetchReportData() async {
    try {
      DatabaseReference _invoicesRef = _db.ref('invoices'); // Reference to 'invoices' node

      final invoicesSnapshot = await _invoicesRef.get(); // Fetch data

      if (!invoicesSnapshot.exists) {
        throw Exception("No invoices found.");
      }

      List<Map<String, dynamic>> reportData = [];

      // Iterate through all invoices
      for (var invoiceSnapshot in invoicesSnapshot.children) {
        final invoiceId = invoiceSnapshot.key;
        final invoice = Map<String, dynamic>.from(invoiceSnapshot.value as Map);

        // Filter by customer ID if selected
        if (_selectedCustomerId != null && invoice['customerId'] != _selectedCustomerId) {
          continue;
        }

        // Filter by payment type if selected
        if (_selectedPaymentType != 'all' && invoice['paymentType'] != _selectedPaymentType) {
          continue;
        }

        // Filter by date range if selected
        if (_selectedDateRange != null) {
          DateTime invoiceDate = DateTime.parse(invoice['createdAt']);
          if (invoiceDate.isBefore(_selectedDateRange!.start) || invoiceDate.isAfter(_selectedDateRange!.end)) {
            continue;
          }
        }

        // Fetch and process cash payments if the selected payment method includes 'cash'
        if (_selectedPaymentMethod == 'all' || _selectedPaymentMethod == 'cash') {
          final cashPayments = invoice['cashPayments'] != null
              ? Map<String, dynamic>.from(invoice['cashPayments'])
              : {};
          for (var payment in cashPayments.values) {
            reportData.add({
              'invoiceId': invoiceId,
              'customerId': invoice['customerId'],
              'customerName': invoice['customerName'],
              'paymentType': invoice['paymentType'],
              'paymentMethod': 'Cash',
              'amount': payment['amount'],
              'date': payment['date'],
              'createdAt': invoice['createdAt'],
            });
          }
        }

        // Fetch and process online payments if the selected payment method includes 'online'
        if (_selectedPaymentMethod == 'all' || _selectedPaymentMethod == 'online') {
          final onlinePayments = invoice['onlinePayments'] != null
              ? Map<String, dynamic>.from(invoice['onlinePayments'])
              : {};
          for (var payment in onlinePayments.values) {
            reportData.add({
              'invoiceId': invoiceId,
              'customerId': invoice['customerId'],
              'customerName': invoice['customerName'],
              'paymentType': invoice['paymentType'],
              'paymentMethod': 'Online',
              'amount': payment['amount'],
              'date': payment['date'],
              'createdAt': invoice['createdAt'],
            });
          }
        }
      }

      // Update the report data with the fetched information
      setState(() {
        _reportData = reportData;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to fetch report: $e')));
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.teal,
            hintColor: Colors.teal,
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _fetchReportData(); // Refetch data with the selected date range
    }
  }

  // Show customer selection dialog
  Future<void> _selectCustomer(BuildContext context) async {
    // Fetch customers from the provider
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    await customerProvider.fetchCustomers(); // Fetch customers from Firebase

    // Show dialog with the customer list
    final customerId = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a Customer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: customerProvider.customers.map((customer) {
              return ListTile(
                title: Text(customer.name),
                onTap: () => Navigator.pop(context, customer.id),
              );
            }).toList(),
          ),
        );
      },
    );

    if (customerId != null) {
      // Find the customer name based on the selected customerId
      final selectedCustomer = customerProvider.customers.firstWhere((customer) => customer.id == customerId);
      setState(() {
        _selectedCustomerId = customerId;
        _selectedCustomerName = selectedCustomer.name; // Update the selected customer name
      });
      _fetchReportData(); // Refetch data with the selected customer
    }
  }

  // Clear all filters and fetch default report
  void _clearFilters() {
    setState(() {
      _selectedPaymentType = 'all';
      _selectedCustomerId = null;
      _selectedCustomerName = null;
      _selectedDateRange = null;
      _selectedPaymentMethod = 'all';  // Reset payment method
    });
    _fetchReportData(); // Refetch data with the default filters
  }
// Method to calculate the total amount
  double _calculateTotalAmount() {
    return _reportData.fold(0.0, (sum, invoice) {
      return sum + (invoice['amount'] ?? 0.0); // Use 'amount' field for total calculation
    });
  }


  // Future<void> _generateAndPrintPDF() async {
  //   final pdf = pw.Document();
  //   final languageProvider = Provider.of<LanguageProvider>(context,listen: false);
  //
  //   pdf.addPage(
  //     pw.Page(
  //       build: (pw.Context context) {
  //         return pw.Column(
  //           children: [
  //             pw.Text(
  //                 'Payment Type Report For Sarya',
  //                 // languageProvider.isEnglish ? 'Payment Type Report For Sarya' : 'سریا کے لیے ادائیگی کی قسم کی رپورٹ', // Dynamic text based on language
  //
  //                 style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
  //             pw.SizedBox(height: 20),
  //             pw.Text(
  //                 'Customer: ${_selectedCustomerName ?? 'All'}'
  //             ),
  //             // pw.Text('Phone: ${widget.customerPhone ?? 'All'}'),
  //             pw.SizedBox(height: 20),
  //             pw.Table.fromTextArray(
  //               context: context,
  //               data: [
  //                 [
  //                   'Customer',
  //                   // languageProvider.isEnglish ? 'Customer' : 'کسٹمر', // Dynamic text based on language
  //                   'Payment Type',
  //                   // languageProvider.isEnglish ? 'Payment Type' : 'ادائیگی کی قسم', // Dynamic text based on language
  //                   'Payment Method',
  //                   // languageProvider.isEnglish ? 'Payment Method' : 'ادائیگی کی طریقہ', // Dynamic text based on language
  //                   'Amount',
  //                   // languageProvider.isEnglish ? 'Amount' : 'رقم', // Dynamic text based on language
  //                   'Date'
  //                   // languageProvider.isEnglish ? 'Date' : 'تاریخ', // Dynamic text based on language
  //
  //                 ],
  //                 ..._reportData.map((invoice) {
  //                   return [
  //                     invoice['customerName'] ?? 'N/A',
  //                     invoice['paymentType'] ?? 'N/A',
  //                     invoice['paymentMethod'] ?? 'N/A',
  //                     'Rs ${invoice['amount']}',
  //                     DateFormat.yMMMd().format(DateTime.parse(invoice['createdAt'])),
  //                   ];
  //                 }).toList(),
  //               ],
  //             ),
  //             pw.SizedBox(height: 20),
  //             pw.Text(
  //                 'Total Amount: Rs ${_calculateTotalAmount().toStringAsFixed(2)}'
  //               // '${languageProvider.isEnglish ? 'Total Amount: Rs ${_calculateTotalAmount().toStringAsFixed(2)}' : 'کل رقم:${_calculateTotalAmount().toStringAsFixed(2)}روپے' }'
  //
  //             ),
  //           ],
  //         );
  //       },
  //     ),
  //   );
  //
  //   // Print PDF
  //   await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  // }
  Future<void> _generateAndPrintPDF() async {
    final pdf = pw.Document();
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    const int rowsPerPage = 20;

    // Split _reportData into chunks of 20 rows
    for (int i = 0; i < _reportData.length; i += rowsPerPage) {
      final chunk = _reportData.sublist(i, i + rowsPerPage > _reportData.length ? _reportData.length : i + rowsPerPage);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Text(
                  'Payment Type Report For Sarya',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Customer: ${_selectedCustomerName ?? 'All'}',
                ),
                // pw.Text('Phone: ${widget.customerPhone ?? 'All'}'),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  context: context,
                  data: [
                    [
                      'Customer',
                      'Payment Type',
                      'Payment Method',
                      'Amount',
                      'Date',
                    ],
                    // Add data for the current chunk of 20 rows
                    ...chunk.map((invoice) {
                      return [
                        invoice['customerName'] ?? 'N/A',
                        invoice['paymentType'] ?? 'N/A',
                        invoice['paymentMethod'] ?? 'N/A',
                        'Rs ${invoice['amount']}',
                        DateFormat.yMMMd().format(DateTime.parse(invoice['createdAt'])),
                      ];
                    }).toList(),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Total Amount: Rs ${_calculateTotalAmount().toStringAsFixed(2)}',
                ),
              ],
            );
          },
        ),
      );
    }

    // Print PDF
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
         title: Text(
             // 'Payment Type Report'
             languageProvider.isEnglish ? 'Payment Type Report' : 'ادائیگی کی قسم کی رپورٹ', // Dynamic text based on language
             style: const TextStyle(color: Colors.white)
         ),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Row
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     // Payment type dropdown
            //     Container(
            //       decoration: BoxDecoration(
            //         color: Colors.teal.shade50,
            //         borderRadius: BorderRadius.circular(12),
            //         boxShadow: [
            //           BoxShadow(
            //             color: Colors.teal.withOpacity(0.3),
            //             spreadRadius: 2,
            //             blurRadius: 5,
            //           ),
            //         ],
            //       ),
            //       child: DropdownButton<String>(
            //         value: _selectedPaymentType,
            //         onChanged: (value) {
            //           setState(() {
            //             _selectedPaymentType = value;
            //             // Reset payment method when payment type changes
            //             if (value != 'instant') {
            //               _selectedPaymentMethod = 'all';
            //             }
            //           });
            //           _fetchReportData(); // Refetch data based on payment type
            //         },
            //         items: <String>['all', 'udhaar', 'instant']
            //             .map<DropdownMenuItem<String>>((String value) {
            //           return DropdownMenuItem<String>(
            //             value: value,
            //             child: Text(value == 'all'
            //                 ? 'All Payments'
            //                 : value == 'udhaar'
            //                 ? 'Udhaar'
            //                 : 'Instant'),
            //           );
            //         }).toList(),
            //       ),
            //     ),
            //     const SizedBox(width: 15),
            //     // Customer dropdown or filter
            //     ElevatedButton(
            //       onPressed: () => _selectCustomer(context),
            //       style: ElevatedButton.styleFrom(
            //         backgroundColor: Colors.teal.shade400,
            //         shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(12),
            //         ),
            //       ),
            //       child: Text(
            //         _selectedCustomerName == null
            //             ? 'Select Customer'
            //             : 'Selected: $_selectedCustomerName', // Display selected customer name
            //         style: const TextStyle(
            //           color: Colors.white
            //         ),
            //       ),
            //     ),
            //     const SizedBox(width: 15),
            //     // Date range picker
            //     ElevatedButton(
            //       onPressed: () => _selectDateRange(context),
            //       style: ElevatedButton.styleFrom(
            //         backgroundColor: Colors.teal.shade400,
            //         shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(12),
            //         ),
            //       ),
            //       child: Text(
            //           _selectedDateRange == null ? 'Select Date Range' : 'Date Range Selected',
            //         style: const TextStyle(
            //           color: Colors.white
            //         ),
            //       ),
            //     ),
            //     const SizedBox(width: 15),
            //     // Clear filter button
            //     ElevatedButton(
            //       onPressed: _clearFilters,
            //       style: ElevatedButton.styleFrom(
            //         backgroundColor: Colors.red.shade400,
            //         shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(12),
            //         ),
            //       ),
            //       child: Text(
            //           // 'Clear Filters'
            //         languageProvider.isEnglish ? 'Clear Filters' : 'فلٹرز صاف کریں۔', // Dynamic text based on language
            //         style: const TextStyle(color: Colors.white),
            //       ),
            //     ),
            //   ],
            // ),
            // const SizedBox(height: 20),
            // // Payment method dropdown (only for instant payments)
            // if (_selectedPaymentType == 'instant')
            //   Row(
            //     children: [
            //       Container(
            //         decoration: BoxDecoration(
            //           color: Colors.teal.shade50,
            //           borderRadius: BorderRadius.circular(12),
            //           boxShadow: [
            //             BoxShadow(
            //               color: Colors.teal.withOpacity(0.3),
            //               spreadRadius: 2,
            //               blurRadius: 5,
            //             ),
            //           ],
            //         ),
            //         child: DropdownButton<String>(
            //           value: _selectedPaymentMethod,
            //           onChanged: (value) {
            //             setState(() {
            //               _selectedPaymentMethod = value;
            //             });
            //             _fetchReportData(); // Refetch data based on payment method
            //           },
            //           items: <String>['all', 'online', 'cash']
            //               .map<DropdownMenuItem<String>>((String value) {
            //             return DropdownMenuItem<String>(
            //               value: value,
            //               child: Text(value == 'all'
            //                   ? 'All Methods'
            //                   : value == 'online'
            //                   ? 'Online'
            //                   : 'Cash'),
            //             );
            //           }).toList(),
            //         ),
            //       ),
            //       const SizedBox(width: 15),
            //     ],
            //   ),
            // const SizedBox(height: 20),
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      // Payment type dropdown
                      Container(
                        width: MediaQuery.of(context).size.width * 0.45, // Adjust width
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true, // Ensure dropdown adapts to the container width
                          value: _selectedPaymentType,
                          onChanged: (value) {
                            setState(() {
                              _selectedPaymentType = value;
                              if (value != 'instant') {
                                _selectedPaymentMethod = 'all';
                              }
                            });
                            _fetchReportData();
                          },
                          items: <String>['all', 'udhaar', 'instant']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value == 'all'
                                  ? 'All Payments'
                                  : value == 'udhaar'
                                  ? 'Udhaar'
                                  : 'Instant'),
                            );
                          }).toList(),
                        ),
                      ),
                      // Customer dropdown or filter
                      ElevatedButton(
                        onPressed: () => _selectCustomer(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _selectedCustomerName == null
                              ? 'Select Customer'
                              : 'Selected: $_selectedCustomerName',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      // Date range picker
                      ElevatedButton(
                        onPressed: () => _selectDateRange(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _selectedDateRange == null
                              ? 'Select Date Range'
                              : 'Date Range Selected',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      // Clear filter button
                      ElevatedButton(
                        onPressed: _clearFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          languageProvider.isEnglish ? 'Clear Filters' : 'فلٹرز صاف کریں۔',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Payment method dropdown (only for instant payments)
                  // if (_selectedPaymentType == 'instant')
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.45,
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedPaymentMethod,
                            onChanged: (value) {
                              setState(() {
                                _selectedPaymentMethod = value;
                              });
                              _fetchReportData();
                            },
                            items: <String>['all', 'online', 'cash']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value == 'all'
                                    ? 'All Methods'
                                    : value == 'online'
                                    ? 'Online'
                                    : 'Cash'),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Expanded(
            //   child: SingleChildScrollView(
            //     child: Container(
            //       width: double.infinity,  // Make the table take full width
            //       decoration: BoxDecoration(
            //         borderRadius: BorderRadius.circular(12),
            //         boxShadow: [
            //           BoxShadow(
            //             color: Colors.teal.withOpacity(0.3),
            //             spreadRadius: 2,
            //             blurRadius: 5,
            //           ),
            //         ],
            //       ),
            //       child: Card(
            //         color: Colors.teal.shade50,
            //         elevation: 8,
            //         shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(12),
            //         ),
            //         child: DataTable(
            //           columnSpacing: 25.0,  // Increase spacing between columns
            //           dataRowHeight: 60,   // Increase row height
            //           columns: [
            //             DataColumn(label: Text('Customer', style: TextStyle(color: Colors.teal.shade800))),
            //             DataColumn(label: Text('Payment Type', style: TextStyle(color: Colors.teal.shade800))),
            //             DataColumn(label: Text('Invoice ID', style: TextStyle(color: Colors.teal.shade800))),
            //             DataColumn(label: Text('Payment Method', style: TextStyle(color: Colors.teal.shade800))),
            //             DataColumn(label: Text('Amount', style: TextStyle(color: Colors.teal.shade800))),
            //             DataColumn(label: Text('Date', style: TextStyle(color: Colors.teal.shade800))),
            //           ],
            //           rows: _reportData.map((invoice) {
            //             print(invoice);
            //             return DataRow(cells: [
            //               DataCell(Text(invoice['customerName'] ?? 'N/A')),
            //               DataCell(Text(invoice['paymentType'] ?? 'N/A')),
            //               DataCell(Text(invoice['invoiceId'] ?? 'N/A')),
            //               DataCell(Text(invoice['paymentMethod'] ?? 'N/A')),
            //               DataCell(Text(invoice['amount'].toString())),
            //               DataCell(Text(DateFormat.yMMMd().format(DateTime.parse(invoice['date'])))),
            //             ]);
            //           }).toList(),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),

            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity, // Ensure the table takes full width
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Card(
                    color: Colors.teal.shade50,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal, // Enable horizontal scrolling
                      child: DataTable(
                        columnSpacing: 25.0, // Increase spacing between columns
                        dataRowHeight: 60, // Increase row height
                        columns: [
                          DataColumn(label: Text('Customer', style: TextStyle(color: Colors.teal.shade800))),
                          DataColumn(label: Text('Payment Type', style: TextStyle(color: Colors.teal.shade800))),
                          DataColumn(label: Text('Invoice ID', style: TextStyle(color: Colors.teal.shade800))),
                          DataColumn(label: Text('Payment Method', style: TextStyle(color: Colors.teal.shade800))),
                          DataColumn(label: Text('Amount', style: TextStyle(color: Colors.teal.shade800))),
                          DataColumn(label: Text('Date', style: TextStyle(color: Colors.teal.shade800))),
                        ],
                        rows: _reportData.map((invoice) {
                          return DataRow(cells: [
                            DataCell(Text(invoice['customerName'] ?? 'N/A')),
                            DataCell(Text(invoice['paymentType'] ?? 'N/A')),
                            DataCell(Text(invoice['invoiceId'] ?? 'N/A')),
                            DataCell(Text(invoice['paymentMethod'] ?? 'N/A')),
                            DataCell(Text(invoice['amount'].toString())),
                            DataCell(Text(DateFormat.yMMMd().format(DateTime.parse(invoice['date'])))),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    // 'Total: ${_calculateTotalAmount().toStringAsFixed(2)}rs',
                    languageProvider.isEnglish ? 'Total: ${_calculateTotalAmount().toStringAsFixed(2)}rs' : 'کل رقم:${_calculateTotalAmount().toStringAsFixed(2)}روپے', // Dynamic text based on language

                    style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800
                  ),)
                ],
              ),
            ),
            // Button to generate and print the PDF
            ElevatedButton(
              onPressed: _generateAndPrintPDF,
              child: Text(
                  // 'Generate and Print PDF'
                languageProvider.isEnglish ? 'Generate and Print PDF' : 'پی ڈی ایف بنائیں اور پرنٹ کریں۔', // Dynamic text based on language

              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
