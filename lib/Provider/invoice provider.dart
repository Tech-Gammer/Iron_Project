import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class InvoiceProvider with ChangeNotifier {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _invoices = [];

  List<Map<String, dynamic>> get invoices => _invoices;

  Future<void> saveInvoice({
    required String invoiceId,  // Accepts the invoice ID (instead of using push)
    required String invoiceNumber,
    required String customerId,
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
       await _updateCustomerLedger(customerId, grandTotal, invoiceNumber);
    } catch (e) {
      throw Exception('Failed to save invoice: $e');
    }
  }

  Future<void> updateInvoice({
    required String invoiceId, // Same invoiceId as the one used during save
    required String invoiceNumber,
    required String customerId,
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
            'subtotal': value['subtotal'],
            'discount': value['discount'],
            'grandTotal': value['grandTotal'],
            'paymentType': value['paymentType'],
            'paymentMethod': value['paymentMethod'],
            // 'items': value['items'],
            // Convert items to List<Map<String, dynamic>>
            'items': List<Map<String, dynamic>>.from(
              (value['items'] as List).map((item) => Map<String, dynamic>.from(item)),
            ),
            'createdAt': value['createdAt'],
          });
        });
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Failed to fetch invoices: $e');
    }
  }

  Future<void> deleteInvoice(String id) async {
    try {
      // Delete the invoice from the Firebase database by its ID
      await _db.child('invoices').child(id).remove();

      // Refresh the invoices list after deleting
      await fetchInvoices();
    } catch (e) {
      throw Exception('Failed to delete invoice: $e');
    }
  }

  Future<void> _updateCustomerLedger(String customerId, double creditAmount, String invoiceNumber) async {
    try {
      // Get the existing ledger data for the customer
      final customerLedgerRef = _db.child('ledger').child(customerId);
      final DatabaseEvent snapshot = await customerLedgerRef.once();

      double previousBalance = 0.0;

      if (snapshot.snapshot.exists) {
        // Cast snapshot.value to a Map<String, dynamic> safely
        final existingLedgerData = Map<String, dynamic>.from(snapshot.snapshot.value as Map);

        // Get the last entry in the ledger (the last invoice's remainingBalance)
        final lastLedgerEntry = existingLedgerData.isNotEmpty
            ? existingLedgerData.entries.last.value // Assuming the entries are ordered by createdAt
            : null;

        if (lastLedgerEntry != null) {
          previousBalance = lastLedgerEntry['remainingBalance'] ?? 0.0;
        }
      }

      // Calculate the new remaining balance (previous remainingBalance + current creditAmount)
      final remainingBalance = previousBalance + creditAmount;

      // Create the ledger data for the current invoice
      final ledgerData = {
        'invoiceNumber': invoiceNumber,
        'creditAmount': creditAmount,
        'remainingBalance': remainingBalance,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Save or update the ledger entry for the customer
      await customerLedgerRef.push().set(ledgerData);
    } catch (e) {
      throw Exception('Failed to update customer ledger: $e');
    }
  }
}
