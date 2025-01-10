import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class InvoiceProvider with ChangeNotifier {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _invoices = [];

  List<Map<String, dynamic>> get invoices => _invoices;

  Future<void> saveInvoice({
    required String invoiceId, // Accepts the invoice ID (instead of using push)
    required String invoiceNumber,
    required String customerId,
    required String customerName, // Accept the customer name as a parameter
    required double subtotal,
    required double discount,
    required double grandTotal,
    required String paymentType,
    String? paymentMethod, // For instant payments
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final cleanedItems = items.map((item) {
        return {
          'rate': item['rate'] ?? 0.0,
          'qty': item['qty'] ?? 0.0,
          'weight': item['weight'] ?? 0.0,
          'description': item['description'] ?? '',
        };
      }).toList();

      final invoiceData = {
        'invoiceNumber': invoiceNumber,
        'customerId': customerId,
        'customerName': customerName, // Save customer name here
        'subtotal': subtotal,
        'discount': discount,
        'grandTotal': grandTotal,
        'paymentType': paymentType,
        'paymentMethod': paymentMethod ?? '',
        'items': cleanedItems,
        'createdAt': DateTime.now().toIso8601String(),
      };
      // Save the invoice at the specified invoiceId path
      await _db.child('invoices').child(invoiceId).set(invoiceData);
      print('invoice saved');
      // Now update the ledger for this customer
      await _updateCustomerLedger(
      customerId,
      creditAmount: grandTotal, // The invoice total as a credit
      debitAmount: 0.0, // No payment yet
      remainingBalance: grandTotal, // Full amount due initially
      invoiceNumber: invoiceNumber,
      );
    } catch (e) {
      throw Exception('Failed to save invoice: $e');
    }
  }

  Future<void> updateInvoice({
    required String invoiceId, // Same invoiceId as the one used during save
    required String invoiceNumber,
    required String customerId,
    required String customerName, // Accept the customer name as a parameter
    required double subtotal,
    required double discount,
    required double grandTotal,
    required String paymentType,
    String? paymentMethod, // For instant payments
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final cleanedItems = items.map((item) {
        return {
          'rate': item['rate'] ?? 0.0,
          'qty': item['qty'] ?? 0.0,
          'weight': item['weight'] ?? 0.0,
          'description': item['description'] ?? '',
        };
      }).toList();

      final updatedInvoiceData = {
        'invoiceNumber': invoiceNumber,
        'customerId': customerId,
        'customerName': customerName, // Update customer name here as well
        'subtotal': subtotal,
        'discount': discount,
        'grandTotal': grandTotal,
        'paymentType': paymentType,
        'paymentMethod': paymentMethod ?? '',
        'items': cleanedItems,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Update the invoice at the same path using the invoiceId
      await _db.child('invoices').child(invoiceId).update(updatedInvoiceData);

      // Optionally refresh the invoices list after updating
      await fetchInvoices();
    } catch (e) {
      throw Exception('Failed to update invoice: $e');
    }
  }

  Future<void> fetchInvoices() async {
    try {
      final snapshot = await _db.child('invoices').get();
      if (snapshot.exists) {
        _invoices = [];
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          _invoices.add({
            'id': key, // This is the unique ID for each invoice
            'invoiceNumber': value['invoiceNumber'],
            'customerId': value['customerId'],
            'customerName': value['customerName'],
            'subtotal': value['subtotal'],
            'discount': value['discount'],
            'grandTotal': value['grandTotal'],
            'paymentType': value['paymentType'],
            'paymentMethod': value['paymentMethod'],
            'debitAmount': value['debitAmount'] ?? 0.0, // **Added field for paid amount**
            'debitAt': value['debitAt'], // **Added field for last payment date**
            'items': List<Map<String, dynamic>>.from(
              (value['items'] as List).map((item) => Map<String, dynamic>.from(item)),
            ),
            'createdAt': value['createdAt'] is int
                ? DateTime.fromMillisecondsSinceEpoch(value['createdAt']).toIso8601String()
                : value['createdAt'],
          });
        });
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Failed to fetch invoices: $e');
    }
  }


  Future<void> deleteInvoice(String invoiceId) async {
    try {
      // Fetch the invoice to identify related customer and invoice number
      final invoice = _invoices.firstWhere((inv) => inv['id'] == invoiceId);

      if (invoice == null) {
        throw Exception("Invoice not found.");
      }

      final customerId = invoice['customerId'] as String;
      final invoiceNumber = invoice['invoiceNumber'] as String;

      // Delete the invoice from the database
      await _db.child('invoices').child(invoiceId).remove();

      // Delete associated ledger entries
      final customerLedgerRef = _db.child('ledger').child(customerId);

      // Find all ledger entries related to this invoice
      final snapshot = await customerLedgerRef.orderByChild('invoiceNumber').equalTo(invoiceNumber).get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        for (var entryKey in data.keys) {
          await customerLedgerRef.child(entryKey).remove();
        }
      }

      // Refresh the invoices list after deletion
      await fetchInvoices();

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete invoice and ledger entries: $e');
    }
  }


  // **New Method to Handle Invoice Payment**
  Future<void> payInvoice(BuildContext context, String invoiceId, double paymentAmount) async {
    try {
      // Find the selected invoice
      final invoice = _invoices.firstWhere((inv) => inv['id'] == invoiceId);

      if (invoice['debitAmount'] == null) {
        invoice['debitAmount'] = 0.0;
      }

      final currentDebit = invoice['debitAmount'] as double;
      final grandTotal = invoice['grandTotal'] as double;

      if (paymentAmount > (grandTotal - currentDebit)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment exceeds the remaining invoice balance.")),
        );
        throw Exception("Payment exceeds the remaining invoice balance.");
      }

      // Update invoice data
      final updatedDebit = currentDebit + paymentAmount;
      final debitAt = DateTime.now().toIso8601String();

      await _db.child('invoices').child(invoiceId).update({
        'debitAmount': updatedDebit, // **Update paid amount**
        'debitAt': debitAt, // **Update last payment date**
      });

      // Update the ledger with the calculated remaining balance
      await _updateCustomerLedger(
        invoice['customerId'],
        creditAmount: 0.0,
        debitAmount: paymentAmount,
        remainingBalance: grandTotal - updatedDebit,
        invoiceNumber: invoice['invoiceNumber'],
      );

      // Refresh the invoices list
      await fetchInvoices();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment of Rs. $paymentAmount recorded successfully.')),
      );
    } catch (e) {
      throw Exception('Failed to pay invoice: $e');
    }
  }

  // **Updated Method to Handle Customer Ledger**
  Future<void> _updateCustomerLedger(
      String customerId, {
        required double creditAmount,
        required double debitAmount,
        required double remainingBalance,
        required String invoiceNumber,
      }) async {
    try {
      final customerLedgerRef = _db.child('ledger').child(customerId);

      // Fetch the last ledger entry to calculate the new remaining balance
      final snapshot = await customerLedgerRef.orderByChild('createdAt').limitToLast(1).get();

      double lastRemainingBalance = 0.0;
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final lastTransaction = data.values.first;
        lastRemainingBalance = lastTransaction['remainingBalance'] as double;
      }

      // Calculate the new remaining balance
      final newRemainingBalance = lastRemainingBalance + creditAmount - debitAmount;

      // Ledger data to be saved
      final ledgerData = {
        'invoiceNumber': invoiceNumber,
        'creditAmount': creditAmount,
        'debitAmount': debitAmount,
        'remainingBalance': newRemainingBalance, // Updated balance
        'createdAt': DateTime.now().toIso8601String(),
      };

      await customerLedgerRef.push().set(ledgerData);
    } catch (e) {
      throw Exception('Failed to update customer ledger: $e');
    }
  }

  List<Map<String, dynamic>> getInvoicesByPaymentMethod(String paymentMethod) {
    return _invoices.where((invoice) {
      final method = invoice['paymentMethod'] ?? '';
      return method.toLowerCase() == paymentMethod.toLowerCase();
    }).toList();
  }




}
