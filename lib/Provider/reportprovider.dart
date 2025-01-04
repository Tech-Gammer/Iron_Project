import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

class CustomerReportProvider with ChangeNotifier {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  bool isLoading = false;
  String error = '';
  List<Map<String, dynamic>> transactions = [];
  Map<String, dynamic> report = {};
  // Future<void> fetchCustomerReport(String customerId) async {
  //   isLoading = true;
  //   error = '';
  //   notifyListeners();
  //
  //   try {
  //     // Fetch invoices from Firebase where customerId matches
  //     final snapshot = await _db
  //         .child('invoices')
  //         .orderByChild('customerId')
  //         .equalTo(customerId)
  //         .get();
  //
  //     if (snapshot.exists && snapshot.value != null) {
  //       // Parse Firebase snapshot data
  //       final data = Map<String, dynamic>.from(snapshot.value as Map);
  //
  //       // Convert invoice map values into a list of transactions
  //       transactions = data.values.map((entry) {
  //         return Map<String, dynamic>.from(entry as Map);
  //       }).toList();
  //
  //       calculateReport();
  //     } else {
  //       // No data found, reset report and transactions
  //       transactions = [];
  //       report = {'debit': 0.0, 'credit': 0.0, 'balance': 0.0};
  //     }
  //   } catch (e) {
  //     // Handle parsing or network errors
  //     error = 'Failed to fetch data: $e';
  //   } finally {
  //     isLoading = false;
  //     notifyListeners();
  //   }
  // }

  // void calculateReport() {
  //   double debit = 0.0;
  //   double credit = 0.0;
  //
  //   for (var transaction in transactions) {
  //     final paymentType = transaction['paymentType'] ?? '';
  //     final amount = (transaction['grandTotal'] as num?)?.toDouble() ?? 0.0;
  //
  //     if (paymentType == 'instant') {
  //       debit += amount;
  //     } else if (paymentType == 'udhaar') {
  //       credit += amount;
  //     }
  //   }
  //
  //   report = {
  //     'debit': debit,
  //     'credit': credit,
  //     'balance': debit - credit,
  //   };
  //   notifyListeners();
  // }

  // Future<void> exportReportPDF() async {
  //   final pdf = pw.Document();
  //   pdf.addPage(
  //     pw.Page(
  //       build: (context) {
  //         return pw.Column(
  //           crossAxisAlignment: pw.CrossAxisAlignment.start,
  //           children: [
  //             pw.Text(
  //               'Customer Report',
  //               style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
  //             ),
  //             pw.Text('Debit: ${report['debit'].toStringAsFixed(2)}'),
  //             pw.Text('Credit: ${report['credit'].toStringAsFixed(2)}'),
  //             pw.Text('Balance: ${report['balance'].toStringAsFixed(2)}'),
  //             pw.SizedBox(height: 20),
  //             pw.Table.fromTextArray(
  //               data: [
  //                 ['Invoice #', 'Amount', 'Type'],
  //                 ...transactions.map((t) => [
  //                   t['invoiceNumber'] ?? 'N/A',
  //                   t['grandTotal']?.toStringAsFixed(2) ?? '0.0',
  //                   t['paymentType'] ?? 'N/A',
  //                 ]),
  //               ],
  //             ),
  //           ],
  //         );
  //       },
  //     ),
  //   );
  //   await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  // }

  Future<void> exportReportPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Section
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('Moon Flex Printing', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Phone Number: 03006194719'),
                    pw.SizedBox(height: 10),
                    pw.Text('Customer Statement', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text('11 Jan 23 - 31 Dec 24'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              // Summary Section
              pw.Container(
                padding: const pw.EdgeInsets.all(8.0),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItemPDF('Opening Balance', 'Rs 0 (Settled)'),
                    _buildSummaryItemPDF('Total Debit (-)', 'Rs ${report['debit']?.toStringAsFixed(2)}'),
                    _buildSummaryItemPDF('Total Credit (+)', 'Rs ${report['credit']?.toStringAsFixed(2)}'),
                    _buildSummaryItemPDF(
                      'Net Balance',
                      'Rs ${report['balance']?.toStringAsFixed(2)}',
                      isHighlight: true,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              // Transactions Table
              pw.Table.fromTextArray(
                headers: ['Date', 'Details', 'Debit (-)', 'Credit (+)', 'Balance'],
                data: transactions.map((transaction) {
                  return [
                    transaction['date'] ?? 'N/A',
                    transaction['details'] ?? 'N/A',
                    transaction['debit']?.toStringAsFixed(2) ?? '-',
                    transaction['credit']?.toStringAsFixed(2) ?? '-',
                    transaction['balance']?.toStringAsFixed(2) ?? '-',
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _buildSummaryItemPDF(String title, String value, {bool isHighlight = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            color: isHighlight ? PdfColors.red : PdfColors.black,
            fontWeight: isHighlight ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }



  Future<void> fetchCustomerReport(String customerId) async {
    try {
      isLoading = true;
      error = '';
      report = {};
      transactions = [];

      // Fetch ledger entries for the customer
      final ledgerSnapshot = await _db.child('ledger').child(customerId).get();
      if (ledgerSnapshot.exists) {
        final ledgerData = Map<String, dynamic>.from(ledgerSnapshot.value as Map<dynamic, dynamic>);

        double totalDebit = 0.0;
        double totalCredit = 0.0;
        double currentBalance = 0.0;

        ledgerData.forEach((key, value) {
          final debit = (value['debitAmount'] ?? 0.0) as double;
          final credit = (value['creditAmount'] ?? 0.0) as double;

          // Accumulate debits and credits
          totalDebit += debit;
          totalCredit += credit;

          // Update current balance dynamically
          currentBalance += credit - debit;

          // Add each ledger entry to the transactions list
          transactions.add({
            'id': key,
            'date': value['createdAt'],
            'invoiceNumber': value['invoiceNumber'],
            // 'paymentType': value['paymentType'] ?? 'N/A', // Optional field
            // 'paymentMethod': value['paymentMethod'] ?? 'N/A', // Optional field
            'debit': debit,
            'credit': credit,
            'balance': currentBalance,
          });
        });

        // Prepare the final report
        report = {
          'debit': totalDebit,
          'credit': totalCredit,
          'balance': currentBalance,
        };
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = 'Failed to fetch customer report: $e';
      isLoading = false;
      notifyListeners();
    }
  }


}
