import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class InvoiceProvider with ChangeNotifier {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _invoices = [];

  List<Map<String, dynamic>> get invoices => _invoices;

  Future<void> saveInvoice({
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
      // Clean up the items to remove controllers and save only the values
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
      print('Subtotal: $subtotal');
      print('Discount: $discount');
      print('Grand Total: $grandTotal');


      await _db.child('invoices').push().set(invoiceData);
    } catch (e) {
      throw Exception('Failed to save invoice: $e');
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
  // Update an existing invoice
  Future<void> updateInvoice({
    required String id,
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
      // Clean up the items to remove controllers and save only the values
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
        'createdAt': DateTime.now().toIso8601String(),
      };

      print('Subtotal: $subtotal');
      print('Discount: $discount');
      print('Grand Total: $grandTotal');

      await _db.child('invoices').child(id).update(updatedInvoiceData);
      await fetchInvoices();  // Refresh the invoices list after updating
    } catch (e) {
      throw Exception('Failed to update invoice: $e');
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


}
