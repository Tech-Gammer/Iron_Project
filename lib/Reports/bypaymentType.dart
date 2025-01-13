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
    final DateTime endOfDay = startOfDay.add(Duration(days: 1)).subtract(Duration(milliseconds: 1)); // Last millisecond of today

    // Set the selected date range to today
    _selectedDateRange = DateTimeRange(start: startOfDay, end: endOfDay);

    // Call the function to fetch data based on today's date
    _fetchReportData();
  }

  // Fetching report data based on filters
  Future<void> _fetchReportData() async {
    final DatabaseReference invoiceRef = FirebaseDatabase.instance.ref().child('invoices');
    Query query = invoiceRef;

    // Filter by paymentType if selected
    if (_selectedPaymentType != 'all') {
      query = query.orderByChild('paymentType').equalTo(_selectedPaymentType);
    }

    // Fetch the data from Firebase based on the paymentType filter
    final snapshot = await query.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;

      // Now, filter the data by paymentMethod, customerId, and date range in the code
      List<Map<String, dynamic>> filteredData = data.values
          .where((invoice) {
        bool matchesCustomer = _selectedCustomerId == null || invoice['customerId'] == _selectedCustomerId;
        bool matchesDateRange = _selectedDateRange == null ||
            (DateTime.parse(invoice['createdAt']).isAfter(_selectedDateRange!.start) &&
                DateTime.parse(invoice['createdAt']).isBefore(_selectedDateRange!.end));

        // Apply paymentMethod filter only if the paymentType is 'instant'
        bool matchesPaymentMethod = (_selectedPaymentType != 'instant' ||
            (_selectedPaymentMethod == 'all' || invoice['paymentMethod'] == _selectedPaymentMethod));

        return matchesCustomer && matchesDateRange && matchesPaymentMethod;
      })
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();

      setState(() {
        _reportData = filteredData;
      });
    } else {
      setState(() {
        _reportData = [];
      });
    }
  }

  // Show date range picker
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
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
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
          title: Text('Select a Customer'),
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
      return sum + (invoice['grandTotal'] ?? 0.0);
    });
  }

  Future<void> _generateAndPrintPDF() async {
    final pdf = pw.Document();
    final languageProvider = Provider.of<LanguageProvider>(context,listen: false);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text(
                  'Payment Type Report For Sarya',
                  // languageProvider.isEnglish ? 'Payment Type Report For Sarya' : 'سریا کے لیے ادائیگی کی قسم کی رپورٹ', // Dynamic text based on language

                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text(
                  'Customer: ${_selectedCustomerName ?? 'All'}'
              ),
              // pw.Text('Phone: ${widget.customerPhone ?? 'All'}'),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                data: [
                  [
                    'Customer',
                    // languageProvider.isEnglish ? 'Customer' : 'کسٹمر', // Dynamic text based on language
                    'Payment Type',
                    // languageProvider.isEnglish ? 'Payment Type' : 'ادائیگی کی قسم', // Dynamic text based on language
                    'Payment Method',
                    // languageProvider.isEnglish ? 'Payment Method' : 'ادائیگی کی طریقہ', // Dynamic text based on language
                    'Amount',
                    // languageProvider.isEnglish ? 'Amount' : 'رقم', // Dynamic text based on language
                    'Date'
                    // languageProvider.isEnglish ? 'Date' : 'تاریخ', // Dynamic text based on language

                  ],
                  ..._reportData.map((invoice) {
                    return [
                      invoice['customerName'] ?? 'N/A',
                      invoice['paymentType'] ?? 'N/A',
                      invoice['paymentMethod'] ?? 'N/A',
                      'Rs ${invoice['grandTotal']}',
                      DateFormat.yMMMd().format(DateTime.parse(invoice['createdAt'])),
                    ];
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                  'Total Amount: Rs ${_calculateTotalAmount().toStringAsFixed(2)}'
                // '${languageProvider.isEnglish ? 'Total Amount: Rs ${_calculateTotalAmount().toStringAsFixed(2)}' : 'کل رقم:${_calculateTotalAmount().toStringAsFixed(2)}روپے' }'

              ),
            ],
          );
        },
      ),
    );

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
             style: TextStyle(color: Colors.white)
         ),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Payment type dropdown
                Container(
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
                    value: _selectedPaymentType,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentType = value;
                        // Reset payment method when payment type changes
                        if (value != 'instant') {
                          _selectedPaymentMethod = 'all';
                        }
                      });
                      _fetchReportData(); // Refetch data based on payment type
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
                SizedBox(width: 15),
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
                        : 'Selected: $_selectedCustomerName', // Display selected customer name
                    style: TextStyle(
                      color: Colors.white
                    ),
                  ),
                ),
                SizedBox(width: 15),
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
                      _selectedDateRange == null ? 'Select Date Range' : 'Date Range Selected',
                    style: TextStyle(
                      color: Colors.white
                    ),
                  ),
                ),
                SizedBox(width: 15),
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
                      // 'Clear Filters'
                    languageProvider.isEnglish ? 'Clear Filters' : 'فلٹرز صاف کریں۔', // Dynamic text based on language
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Payment method dropdown (only for instant payments)
            if (_selectedPaymentType == 'instant')
              Row(
                children: [
                  Container(
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
                      value: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value;
                        });
                        _fetchReportData(); // Refetch data based on payment method
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
                  SizedBox(width: 15),
                ],
              ),
            SizedBox(height: 20),
            // Table for showing report data
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,  // Make the table take full width
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
                    child: DataTable(
                      columnSpacing: 25.0,  // Increase spacing between columns
                      dataRowHeight: 60,   // Increase row height
                      columns: [
                        DataColumn(label: Text(
                            // 'Customer',
                            languageProvider.isEnglish ? 'Customer' : 'کسٹمر', // Dynamic text based on language

                            style: TextStyle(color: Colors.teal.shade800))),
                        DataColumn(label: Text(
                            // 'Payment Type',
                            languageProvider.isEnglish ? 'Payment Type' : 'ادائیگی کی قسم', // Dynamic text based on language

                            style: TextStyle(color: Colors.teal.shade800))),
                        DataColumn(label: Text(
                            // 'Payment Method',
                            languageProvider.isEnglish ? 'Payment Method' : 'ادائیگی کی طریقہ', // Dynamic text based on language

                            style: TextStyle(color: Colors.teal.shade800))),
                        DataColumn(label: Text(
                            // 'Amount',
                            languageProvider.isEnglish ? 'Amount' : 'رقم', // Dynamic text based on language

                            style: TextStyle(color: Colors.teal.shade800))),
                        DataColumn(label: Text(
                            // 'Date',
                            languageProvider.isEnglish ? 'Date' : 'تاریخ', // Dynamic text based on language

                            style: TextStyle(color: Colors.teal.shade800))),
                      ],
                      rows: _reportData.isNotEmpty
                          ? _reportData.map((invoice) {
                        return DataRow(cells: [
                          DataCell(Text(invoice['customerName'] ?? 'N/A')),
                          DataCell(Text(invoice['paymentType'] ?? 'N/A')),
                          DataCell(Text(invoice['paymentMethod'] ?? 'N/A')),
                          DataCell(Text(invoice['grandTotal'].toString())),
                          DataCell(Text(DateFormat.yMMMd().format(DateTime.parse(invoice['createdAt'])))),
                        ]);
                      }).toList()
                          : [],
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
