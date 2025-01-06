import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // Import intl package

class AddExpensePage extends StatefulWidget {
  @override
  _AddExpensePageState createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref("dailyKharcha");
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  double _openingBalance = 0.0; // Variable to store the opening balance

  @override
  void initState() {
    super.initState();
    _checkOpeningBalanceForToday();
  }

  // Check if the opening balance is already set for the current day
  void _checkOpeningBalanceForToday() async {
    String formattedDate = DateFormat('dd:MM:yyyy').format(_selectedDate);
    dbRef.child("openingBalance").child(formattedDate).get().then((snapshot) {
      if (snapshot.exists) {
        // Safely check if the value is a double and cast it
        final value = snapshot.value;
        if (value is num) {
          setState(() {
            _openingBalance = value.toDouble();
          });
        } else {
          // Handle the case where the value is not a number
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid opening balance data')),
          );
        }
      } else {
        // If no balance is set for today, prompt the user to set one
        _showOpeningBalanceDialog();
      }
    });
  }

  // Show dialog to prompt user for opening balance
  void _showOpeningBalanceDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing without providing the balance
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Opening Balance for Today'),
          content: TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _openingBalance = double.tryParse(value) ?? 0.0;
              });
            },
            decoration: const InputDecoration(labelText: 'Enter opening balance'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Set'),
              onPressed: () {
                if (_openingBalance <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid balance')),
                  );
                } else {
                  Navigator.of(context).pop(); // Close the dialog
                  _saveOpeningBalanceToDB();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Save opening balance to Firebase (original balance is only saved once)
  void _saveOpeningBalanceToDB() {
    String formattedDate = DateFormat('dd:MM:yyyy').format(_selectedDate);

    // Only save original opening balance if it's not already set
    dbRef.child("openingBalance").child(formattedDate).set(_openingBalance).then((_) {
      if (_openingBalance > 0) {
        dbRef.child("originalOpeningBalance").child(formattedDate).set(_openingBalance); // Save original balance if it's not set yet
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening balance set successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving opening balance: $error')),
      );
    });
  }

  // Save the daily expense
  void _saveExpense() {
    if (_descriptionController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    double expenseAmount = double.parse(_amountController.text);

    // Check if opening balance is sufficient for the expense
    if (_openingBalance < expenseAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient funds!')),
      );
      return;
    }

    // Deduct the expense from the opening balance
    _openingBalance -= expenseAmount;

    // Format the date to dd:mm:yyyy
    String formattedDate = DateFormat('dd:MM:yyyy').format(_selectedDate);

    final data = {
      "description": _descriptionController.text,
      "amount": expenseAmount,
      "date": formattedDate, // Save formatted date without time
    };

    dbRef.child(formattedDate).child("expenses").push().set(data).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense added successfully')),
      );
      _descriptionController.clear();
      _amountController.clear();
      setState(() {
        _selectedDate = DateTime.now();
      });

      // Save updated opening balance to Firebase after adding expense
      _saveUpdatedOpeningBalance();
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding expense: $error')),
      );
    });
  }

  // Save the updated opening balance (after deducting the expense)
  void _saveUpdatedOpeningBalance() {
    String formattedDate = DateFormat('dd:MM:yyyy').format(_selectedDate);
    dbRef.child("openingBalance").child(formattedDate).set(_openingBalance).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening balance updated successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating opening balance: $error')),
      );
    });
  }

  // Pick date for expense
  void _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate; // Save the selected date
      });
      _checkOpeningBalanceForToday(); // Re-check balance for the selected date
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50, // Background color
      appBar: AppBar(
        title: const Text("Add Expense"),
        backgroundColor: Colors.teal.shade800, // AppBar color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  "Selected Date: ${_selectedDate.day.toString().padLeft(2, '0')}:${_selectedDate.month.toString().padLeft(2, '0')}:${_selectedDate.year}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.date_range),
                  label: const Text('Select Date'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.teal.shade400, // Text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: Colors.teal.shade700),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.teal.shade700),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: TextStyle(color: Colors.teal.shade700),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.teal.shade700),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            const Spacer(),
            ElevatedButton(
              onPressed: _saveExpense,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade800, // Button background color
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Save Expense',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
