import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class FilledProvider with ChangeNotifier {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _filled = [];

  List<Map<String, dynamic>> get filled => _filled;

  Future<void> saveFilled({
    required String filledId, // Accepts the filled ID (instead of using push)
    required String filledNumber,
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
          // 'weight': item['weight'] ?? 0.0,
          'description': item['description'] ?? '',
        };
      }).toList();

      final filledData = {
        'filledNumber': filledNumber,
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
      // Save the filled at the specified filledId path
      await _db.child('filled').child(filledId).set(filledData);
      print('filled saved');
      // Now update the ledger for this customer
      await _updateCustomerLedger(
        customerId,
        creditAmount: grandTotal, // The filled total as a credit
        debitAmount: 0.0, // No payment yet
        remainingBalance: grandTotal, // Full amount due initially
        filledNumber: filledNumber,
      );
    } catch (e) {
      throw Exception('Failed to save filled: $e');
    }
  }

  Future<void> updateFilled({
    required String filledId, // Same filledId as the one used during save
    required String filledNumber,
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
          // 'weight': item['weight'] ?? 0.0,
          'description': item['description'] ?? '',
        };
      }).toList();

      final updatedFilledData = {
        'filledNumber': filledNumber,
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

      // Update the filled at the same path using the filledId
      await _db.child('filled').child(filledId).update(updatedFilledData);

      // Optionally refresh the filled list after updating
      await fetchFilled();
    } catch (e) {
      throw Exception('Failed to update filled: $e');
    }
  }

  Future<void> fetchFilled() async {
    try {
      final snapshot = await _db.child('filled').get();
      if (snapshot.exists) {
        _filled = [];
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          _filled.add({
            'id': key, // This is the unique ID for each filled
            'filledNumber': value['filledNumber'],
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
      throw Exception('Failed to fetch filled: $e');
    }
  }

  // Future<void> deleteFilled(String id) async {
  //   try {
  //     // Delete the filled from the Firebase database by its ID
  //     await _db.child('filled').child(id).remove();
  //
  //     // Refresh the filled list after deleting
  //     await fetchFilled();
  //   } catch (e) {
  //     throw Exception('Failed to delete filled: $e');
  //   }
  // }

  Future<void> deleteFilled(String filledId) async {
    try {
      // Fetch the filled to identify related customer and filled number
      final filled = _filled.firstWhere((inv) => inv['id'] == filledId);

      if (filled == null) {
        throw Exception("Filled not found.");
      }

      final customerId = filled['customerId'] as String;
      final filledNumber = filled['filledNumber'] as String;

      // Delete the filled from the database
      await _db.child('filled').child(filledId).remove();

      // Delete associated ledger entries
      final customerLedgerRef = _db.child('filledledger').child(customerId);

      // Find all ledger entries related to this filled
      final snapshot = await customerLedgerRef.orderByChild('filledNumber').equalTo(filledNumber).get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        for (var entryKey in data.keys) {
          await customerLedgerRef.child(entryKey).remove();
        }
      }

      // Refresh the filled list after deletion
      await fetchFilled();

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete filled and ledger entries: $e');
    }
  }


  // **New Method to Handle filled Payment**
  Future<void> payFilled(BuildContext context, String filledId, double paymentAmount) async {
    try {
      // Find the selected filled
      final filled = _filled.firstWhere((fill) => fill['id'] == filledId);

      if (filled['debitAmount'] == null) {
        filled['debitAmount'] = 0.0;
      }

      final currentDebit = filled['debitAmount'] as double;
      final grandTotal = filled['grandTotal'] as double;

      if (paymentAmount > (grandTotal - currentDebit)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment exceeds the remaining filled balance.")),
        );
        throw Exception("Payment exceeds the remaining filled balance.");
      }

      // Update filled data
      final updatedDebit = currentDebit + paymentAmount;
      final debitAt = DateTime.now().toIso8601String();

      await _db.child('filled').child(filledId).update({
        'debitAmount': updatedDebit, // **Update paid amount**
        'debitAt': debitAt, // **Update last payment date**
      });

      // Update the ledger with the calculated remaining balance
      await _updateCustomerLedger(
        filled['customerId'],
        creditAmount: 0.0,
        debitAmount: paymentAmount,
        remainingBalance: grandTotal - updatedDebit,
        filledNumber: filled['filledNumber'],
      );

      // Refresh the filled list
      await fetchFilled();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment of Rs. $paymentAmount recorded successfully.')),
      );
    } catch (e) {
      throw Exception('Failed to pay filled: $e');
    }
  }

  // **Updated Method to Handle Customer Ledger**
  Future<void> _updateCustomerLedger(
      String customerId, {
        required double creditAmount,
        required double debitAmount,
        required double remainingBalance,
        required String filledNumber,
      }) async {
    try {
      final customerLedgerRef = _db.child('filledledger').child(customerId);

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
        'filledNumber': filledNumber,
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

  List<Map<String, dynamic>> getFilledByPaymentMethod(String paymentMethod) {
    return _filled.where((filled) {
      final method = filled['paymentMethod'] ?? '';
      return method.toLowerCase() == paymentMethod.toLowerCase();
    }).toList();
  }

  Future<void> payFilledWithSeparateMethod(
      BuildContext context, String filledId, double paymentAmount, String paymentMethod) async {
    try {
      // Fetch the current filled data from the database
      final filledSnapshot = await _db.child('filled').child(filledId).get();
      if (!filledSnapshot.exists) {
        throw Exception("Filled not found.");
      }

      // Convert the retrieved data to Map<String, dynamic>
      final filled = Map<String, dynamic>.from(filledSnapshot.value as Map);

      // Get the current payment amounts (default to 0.0 if not set)
      final currentCashPaid = (filled['cashPaidAmount'] ?? 0.0) as double;
      final currentOnlinePaid = (filled['onlinePaidAmount'] ?? 0.0) as double;
      final grandTotal = (filled['grandTotal'] ?? 0.0) as double;

      // Calculate the total paid so far
      final totalPaid = currentCashPaid + currentOnlinePaid;

      // Check if the new payment exceeds the remaining balance
      if (paymentAmount > (grandTotal - totalPaid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment exceeds the remaining filled balance.")),
        );
        throw Exception("Payment exceeds the remaining filled balance.");
      }

      // Add the new payment to the appropriate field
      double updatedCashPaid = currentCashPaid;
      double updatedOnlinePaid = currentOnlinePaid;

      if (paymentMethod == 'Cash') {
        updatedCashPaid += paymentAmount;
        // Save the cash payment in a child node with date
        await _db.child('filled').child(filledId).child('cashPayments').push().set({
          'amount': paymentAmount,
          'date': DateTime.now().toIso8601String(),
        });
      } else if (paymentMethod == 'Online') {
        updatedOnlinePaid += paymentAmount;
        // Save the online payment in a child node with date
        await _db.child('filled').child(filledId).child('onlinePayments').push().set({
          'amount': paymentAmount,
          'date': DateTime.now().toIso8601String(),
        });
      }

      // Get the current debit amount (default to 0.0 if not set)
      final currentDebit = (filled['debitAmount'] ?? 0.0) as double;

      // Check if the payment amount exceeds the remaining balance
      if (paymentAmount > (grandTotal - currentDebit)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment exceeds the remaining filled balance.")),
        );
        throw Exception("Payment exceeds the remaining filled balance.");
      }

      // Update the filled with the new payment data
      final updatedDebit = currentDebit + paymentAmount;
      final debitAt = DateTime.now().toIso8601String();

      await _db.child('filled').child(filledId).update({
        'cashPaidAmount': updatedCashPaid,
        'onlinePaidAmount': updatedOnlinePaid,
        'debitAmount': updatedDebit, // Make sure this is updated
        'debitAt': debitAt,
      });

      // Update the ledger with the calculated remaining balance
      await _updateCustomerLedger(
        filled['customerId'],
        creditAmount: 0.0,
        debitAmount: paymentAmount,
        remainingBalance: grandTotal - updatedDebit,
        filledNumber: filled['filledNumber'],
      );

      // Refresh the filled list
      await fetchFilled();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment of Rs. $paymentAmount recorded successfully as $paymentMethod.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save payment: ${e.toString()}')),
      );
      throw Exception('Failed to save payment: $e');
    }
  }



}
