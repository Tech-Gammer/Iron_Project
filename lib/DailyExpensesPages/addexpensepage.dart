import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../Provider/lanprovider.dart'; // Import intl package

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
  bool _isSaveButtonPressed = false; // Flag to track button press status

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
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing without providing the balance
      builder: (context) {
        return AlertDialog(
          // title: const Text('Set Opening Balance for Today'),
          title: Text(
            languageProvider.isEnglish ? 'Set Opening Balance for Today:' : 'آج کے لیے اوپننگ بیلنس سیٹ کریں۔',
          ),
          content: TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _openingBalance = double.tryParse(value) ?? 0.0;
              });
            },
            decoration:  InputDecoration(
                labelText:  languageProvider.isEnglish ? 'Enter Opening Balance' : 'اوپننگ بیلنس درج کریں۔',

            ),
          ),
          actions: <Widget>[
            TextButton(
              child:  Text(
                languageProvider.isEnglish ? 'Cancel' : 'منسوخ کریں۔',
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child:  Text(
                languageProvider.isEnglish ? 'Set' : 'سیٹ',
              ),
              onPressed: () {
                if (_openingBalance <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(
                        // 'Please enter a valid balance'
                      languageProvider.isEnglish ? 'Please enter a valid balance' : 'براہ کرم ایک درست بیلنس درج کریں۔',
                      )
                    ),
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
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    String formattedDate = DateFormat('dd:MM:yyyy').format(_selectedDate);

    // Only save original opening balance if it's not already set
    dbRef.child("openingBalance").child(formattedDate).set(_openingBalance).then((_) {
      if (_openingBalance > 0) {
        dbRef.child("originalOpeningBalance").child(formattedDate).set(_openingBalance); // Save original balance if it's not set yet
      }
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(
            // 'Opening balance set successfully'
          languageProvider.isEnglish ? 'Opening balance set successfully' : 'اوپننگ بیلنس کامیابی سے سیٹ ہو گیا۔',

        )),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
            // 'Error saving opening balance: $error'
          languageProvider.isEnglish ? 'Error saving opening balance:$error' : '$errorاوپننگ بیلنس بچانے میں خرابی:' ,

        )),
      );
    });
  }


  void _saveExpense() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    if (_descriptionController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            languageProvider.isEnglish ? 'Please fill in all fields' : 'براہ کرم تمام فیلڈز کو پُر کریں۔',
          )));
      return;
    }

    double expenseAmount = double.parse(_amountController.text);

    // Check if opening balance is sufficient for the expense
    if (_openingBalance < expenseAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            languageProvider.isEnglish ? 'Insufficient funds!' : 'ناکافی فنڈز!',
          )));
      return;
    }

    // Disable the button to prevent multiple submissions
    setState(() {
      _isSaveButtonPressed = true;
    });

    // Deduct the expense from the opening balance
    _openingBalance -= expenseAmount;

    // Format the date to dd:mm:yyyy
    String formattedDate = DateFormat('dd:MM:yyyy').format(_selectedDate);

    final data = {
      "description": _descriptionController.text,
      "amount": expenseAmount,
      "date": formattedDate,
    };

    try {
      await dbRef.child(formattedDate).child("expenses").push().set(data);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            languageProvider.isEnglish ? 'Expense added successfully' : 'اخراجات کامیابی کے ساتھ شامل ہو گئے۔',
          )));
      _descriptionController.clear();
      _amountController.clear();
      setState(() {
        _selectedDate = DateTime.now();
      });

      // Save updated opening balance to Firebase after adding expense
       _saveUpdatedOpeningBalance();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            languageProvider.isEnglish ? 'Error adding expense: $error' : 'اخراجات شامل کرنے میں خرابی:$error',
          )));
    } finally {
      // Re-enable the button after the operation is complete
      setState(() {
        _isSaveButtonPressed = false;
      });
    }
  }

  // Save the updated opening balance (after deducting the expense)s
  void _saveUpdatedOpeningBalance() {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    String formattedDate = DateFormat('dd:MM:yyyy').format(_selectedDate);
    dbRef.child("openingBalance").child(formattedDate).set(_openingBalance).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(
            // 'Opening balance updated successfully'
          languageProvider.isEnglish ? 'Opening balance updated successfully' : 'اوپننگ بیلنس کامیابی کے ساتھ اپ ڈیٹ ہو گیا۔',

        )),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
            // 'Error updating opening balance: $error'
          languageProvider.isEnglish ? 'Error updating opening balance: $error' : 'اوپننگ بیلنس کو اپ ڈیٹ کرنے میں خرابی: $error',

        )),
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

  void _adjustOpeningBalanceDialog() {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        TextEditingController adjustmentController = TextEditingController();
        return AlertDialog(
          title: Text(
            languageProvider.isEnglish
                ? 'Adjust Opening Balance'
                : 'اوپننگ بیلنس کو ایڈجسٹ کریں۔',
          ),
          content: TextField(
            controller: adjustmentController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: languageProvider.isEnglish
                  ? 'Enter Additional Amount'
                  : 'اضافی رقم درج کریں۔',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                languageProvider.isEnglish ? 'Cancel' : 'منسوخ کریں۔',
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                languageProvider.isEnglish ? 'Add' : 'شامل کریں۔',
              ),
              onPressed: () {
                double? additionalBalance = double.tryParse(adjustmentController.text);
                if (additionalBalance == null || additionalBalance <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        languageProvider.isEnglish
                            ? 'Please enter a valid amount'
                            : 'براہ کرم ایک درست رقم درج کریں۔',
                      ),
                    ),
                  );
                } else {
                  Navigator.of(context).pop();
                  _updateOpeningBalance(additionalBalance);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _updateOpeningBalance(double additionalBalance) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    String formattedDate = DateFormat('dd:MM:yyyy').format(_selectedDate);

    dbRef.child("openingBalance").child(formattedDate).get().then((snapshot) {
      if (snapshot.exists) {
        final currentBalance = snapshot.value as num? ?? 0.0;
        final updatedBalance = currentBalance.toDouble() + additionalBalance;

        // Save updated balance to the "openingBalance" node
        dbRef.child("openingBalance").child(formattedDate).set(updatedBalance).then((_) {
          setState(() {
            _openingBalance = updatedBalance;
          });

          // Also update the original opening balance to the new value
          dbRef.child("originalOpeningBalance").child(formattedDate).set(updatedBalance).then((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  languageProvider.isEnglish
                      ? 'Opening balance and original balance updated successfully!'
                      : 'اوپننگ بیلنس اور اصل بیلنس کامیابی کے ساتھ اپ ڈیٹ ہو گئے۔',
                ),
              ),
            );
          }).catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  languageProvider.isEnglish
                      ? 'Error updating original opening balance: $error'
                      : 'اصل اوپننگ بیلنس کو اپ ڈیٹ کرنے میں خرابی: $error',
                ),
              ),
            );
          });
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                languageProvider.isEnglish
                    ? 'Error updating opening balance: $error'
                    : 'اوپننگ بیلنس کو اپ ڈیٹ کرنے میں خرابی: $error',
              ),
            ),
          );
        });
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageProvider.isEnglish
                ? 'Error fetching current opening balance: $error'
                : 'موجودہ اوپننگ بیلنس کو حاصل کرنے میں خرابی: $error',
          ),
        ),
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.teal.shade50, // Background colorss
      appBar: AppBar(
        // title: const Text("Add Expense"),
        title: Text(
          languageProvider.isEnglish ? 'Add Expense' : 'اخراجات شامل کریں۔',
          style: TextStyle(color: Colors.white),

        ),
        actions: [
          IconButton(onPressed: (){
            _adjustOpeningBalanceDialog();
          }, icon: Icon(Icons.add,color: Colors.white,))
        ],
        backgroundColor: Colors.teal,
        centerTitle: true,      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  // "Selected Date: ${_selectedDate.day.toString().padLeft(2, '0')}:${_selectedDate.month.toString().padLeft(2, '0')}:${_selectedDate.year}",
                  "${languageProvider.isEnglish ? 'Selected Date:' : 'تاریخ منتخب کریں:'} ${_selectedDate.day.toString().padLeft(2, '0')}:${_selectedDate.month.toString().padLeft(2, '0')}:${_selectedDate.year}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.date_range,color: Colors.white,),
                  label:  Text(
                      // 'Select Date'
                    languageProvider.isEnglish ? 'Select Date' : 'تاریخ منتخب کریں',

                  ),
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
                labelText: languageProvider.isEnglish ? 'Description' : 'تفصیل',

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
                labelText: languageProvider.isEnglish ? 'Amount' : 'رقم',
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
              // onPressed: _saveExpense,
              onPressed: _isSaveButtonPressed ? null : _saveExpense, // Disable if pressed

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal, // Button background color
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child:  Text(
                // 'Save Expense',
                languageProvider.isEnglish ? 'Save Expense' : 'اخراجات محفوظ کریں',
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
