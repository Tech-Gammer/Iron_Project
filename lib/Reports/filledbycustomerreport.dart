import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class filledbycustomerreport extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String customerPhone;

  filledbycustomerreport({
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
  });

  @override
  _filledbycustomerreportState createState() => _filledbycustomerreportState();
}

class _filledbycustomerreportState extends State<filledbycustomerreport> {
  double? remainingBalance;

  @override
  void initState() {
    super.initState();
    // Fetch the remaining balance from Firebase
    _getCustomerBalance(widget.customerId);
  }

  Future<void> _getCustomerBalance(String customerId) async {
    try {
      final DatabaseReference filledledgerRef = FirebaseDatabase.instance.ref().child('filledledger').child(customerId);

      // Query to get the latest filledledger entry
      final snapshot = await filledledgerRef.orderByChild('createdAt').limitToLast(1).get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final lastTransaction = data.values.first;
        setState(() {
          // Extract the remainingBalance from the latest transaction
          remainingBalance = lastTransaction['remainingBalance'] ?? 0.0;
        });
      } else {
        setState(() {
          remainingBalance = 0.0; // If no filledledger entries exist, set balance to 0
        });
      }
    } catch (e) {
      print('Error fetching customer balance: $e');
      setState(() {
        remainingBalance = 0.0; // In case of error, set balance to 0
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customer Report'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer: ${widget.customerName}',
              style: TextStyle(fontSize: 18, color: Colors.teal.shade800),
            ),
            Text(
              'Phone: ${widget.customerPhone}',
              style: TextStyle(fontSize: 16, color: Colors.teal.shade600),
            ),
            SizedBox(height: 20),
            remainingBalance == null
                ? CircularProgressIndicator() // Show loading indicator while fetching data
                : Text(
              'Remaining Balance: Rs. ${remainingBalance?.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18, color: Colors.red.shade700),
            ),
          ],
        ),
      ),
    );
  }
}
