import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart'; // For formatting dates
import 'package:provider/provider.dart';
import '../Provider/customerprovider.dart';

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
    // You would need to fetch the data from Firebase (already implemented in your code)
    // After filtering the data, update the state as below
    setState(() {
      // Mock data for demonstration purposes
      _reportData = [
        {
          'customerName': 'John Doe',
          'paymentType': 'instant',
          'paymentMethod': 'online',
          'grandTotal': 500,
          'createdAt': '2025-01-07T10:00:00',
        },
        {
          'customerName': 'Jane Doe',
          'paymentType': 'udhaar',
          'paymentMethod': 'cash',
          'grandTotal': 200,
          'createdAt': '2025-01-07T11:00:00',
        },
      ];
    });
  }

  // Generate PDF and Print
  Future<void> _generateAndPrintPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('Payment Type Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Customer: ${widget.customerName ?? 'N/A'}'),
              pw.Text('Phone: ${widget.customerPhone ?? 'N/A'}'),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                data: [
                  ['Customer', 'Payment Type', 'Payment Method', 'Amount', 'Date'],
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
              pw.Text('Total Amount: Rs ${_calculateTotalAmount().toStringAsFixed(2)}'),
            ],
          );
        },
      ),
    );

    // Print PDF
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // Method to calculate the total amount
  double _calculateTotalAmount() {
    return _reportData.fold(0.0, (sum, invoice) {
      return sum + (invoice['grandTotal'] ?? 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Type Report'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Your existing filter and selection widgets (payment type, customer, date range)

            // Payment method dropdown (only for instant payments)
            if (_selectedPaymentType == 'instant')
              Row(
                children: [
                  // Payment method dropdown (for instant payments)
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
                  width: double.infinity,
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
                      columnSpacing: 25.0,
                      dataRowHeight: 60,
                      columns: [
                        DataColumn(label: Text('Customer', style: TextStyle(color: Colors.teal.shade800))),
                        DataColumn(label: Text('Payment Type', style: TextStyle(color: Colors.teal.shade800))),
                        DataColumn(label: Text('Payment Method', style: TextStyle(color: Colors.teal.shade800))),
                        DataColumn(label: Text('Amount', style: TextStyle(color: Colors.teal.shade800))),
                        DataColumn(label: Text('Date', style: TextStyle(color: Colors.teal.shade800))),
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
                  Text('Total: ${_calculateTotalAmount().toStringAsFixed(2)} rs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
                ],
              ),
            ),
            // Button to generate and print the PDF
            ElevatedButton(
              onPressed: _generateAndPrintPDF,
              child: Text('Generate and Print PDF'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
