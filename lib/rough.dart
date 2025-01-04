// class InvoiceProvider with ChangeNotifier {
//   List<Map<String, dynamic>> _invoices = [];
//
//   List<Map<String, dynamic>> get invoices => _invoices;
//
//   // Fetch invoices from Firebase
//   Future<void> fetchInvoices() async {
//     try {
//       final snapshot = await _db.child('invoices').get();
//       if (snapshot.exists) {
//         _invoices = [];
//         final data = snapshot.value as Map<dynamic, dynamic>;
//         data.forEach((key, value) {
//           _invoices.add({
//             'id': key,
//             'invoiceNumber': value['invoiceNumber'],
//             'customerId': value['customerId'],
//             'subtotal': value['subtotal'],
//             'discount': value['discount'],
//             'grandTotal': value['grandTotal'],
//             'paymentType': value['paymentType'],
//             'paymentMethod': value['paymentMethod'],
//             'debitAmount': value['debitAmount'] ?? 0.0,
//             'debitAt': value['debitAt'],
//             'items': List<Map<String, dynamic>>.from(
//               (value['items'] as List).map((item) => Map<String, dynamic>.from(item)),
//             ),
//             'createdAt': value['createdAt'] is int
//                 ? DateTime.fromMillisecondsSinceEpoch(value['createdAt']).toIso8601String()
//                 : value['createdAt'],
//           });
//         });
//         notifyListeners();
//         print('Invoices fetched: $_invoices'); // Debugging line
//       }
//     } catch (e) {
//       throw Exception('Failed to fetch invoices: $e');
//     }
//   }
//
//   // Filter invoices by payment method
//   List<Map<String, dynamic>> getInvoicesByPaymentMethod(String paymentMethod) {
//     print('Filtering invoices by payment method: $paymentMethod'); // Debugging line
//     return _invoices.where((invoice) => invoice['paymentMethod'] == paymentMethod).toList();
//   }
// }
