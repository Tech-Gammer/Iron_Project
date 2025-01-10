import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../Provider/lanprovider.dart';
import 'addexpensepage.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
class ViewExpensesPage extends StatefulWidget {
  @override
  _ViewExpensesPageState createState() => _ViewExpensesPageState();
}

class _ViewExpensesPageState extends State<ViewExpensesPage> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref("dailyKharcha");
  List<Map<String, dynamic>> expenses = [];
  double _originalOpeningBalance = 0.0;
  double _totalExpense = 0.0;
  double _remainingBalance = 0.0;
  DateTime _selectedDate = DateTime.now(); // Default date is today

  @override
  void initState() {
    super.initState();
    _fetchOpeningBalance();
    _fetchExpenses();
  }

  // Fetch the original opening balance for the selected date
  void _fetchOpeningBalance() {
    String formattedDate = DateFormat('dd:MM:yyyy').format(_selectedDate);
    dbRef.child("originalOpeningBalance").child(formattedDate).get().then((snapshot) {
      if (snapshot.exists) {
        setState(() {
          _originalOpeningBalance = snapshot.value as double;
          _remainingBalance = _originalOpeningBalance; // Initially set remaining balance to original balance
        });
      }
    });
  }

  // Fetch expenses for the selected date
  void _fetchExpenses() {
    String formattedDate = DateFormat('dd:MM:yyyy').format(_selectedDate);
    dbRef.child(formattedDate).child("expenses").onValue.listen((event) {
      final Map data = event.snapshot.value as Map? ?? {};
      final List<Map<String, dynamic>> loadedExpenses = [];
      double totalExpense = 0.0;

      data.forEach((key, value) {
        loadedExpenses.add({
          "id": key,
          "description": value["description"] ?? "No Description",
          "amount": value["amount"] ?? 0.0,
          "date": value["date"] ?? formattedDate,
        });

        totalExpense += value["amount"] ?? 0.0; // Sum of all expenses
      });

      setState(() {
        expenses = loadedExpenses;
        _totalExpense = totalExpense;
        _remainingBalance = _originalOpeningBalance - _totalExpense; // Update remaining balance
      });
    });
  }

  // Pick date for expenses view
  void _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _fetchOpeningBalance(); // Fetch opening balance for the new date
        _fetchExpenses(); // Fetch expenses for the new date
      });
    }
  }

  // Generate PDF for the expenses
  Future<void> _generatePdf() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    final pdf = pw.Document();

    // Add the opening balance, expenses, and total
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a5,
      build: (pw.Context context) {
        return pw.Column(
          children: [
            pw.Text(
                // "Daily Expenses Report",
            languageProvider.isEnglish ? 'Daily Expenses Report:' : 'روزانہ اخراجات کی رپورٹ',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text(
                // "Opening Balance: ${_originalOpeningBalance.toStringAsFixed(2)} rs",
                languageProvider.isEnglish ? 'Opening Balance:' : 'اوپننگ بیلنس:',

                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text(
                // "Selected Date: ${DateFormat('dd:MM:yyyy').format(_selectedDate)}",
                "${languageProvider.isEnglish ? 'Selected Date:' : 'تاریخ منتخب کریں:'} ${DateFormat('dd:MM:yyyy').format(_selectedDate)}",
                style: pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 20),
            pw.Text(
                // "Expenses",
                languageProvider.isEnglish ? "Expenses" : "اخراجات",
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return pw.Padding(
                  padding: pw.EdgeInsets.symmetric(vertical: 5),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                          expense["description"],
                          style: pw.TextStyle(fontSize: 14)),
                      pw.Text("${expense["amount"].toStringAsFixed(2)} rs", style: pw.TextStyle(fontSize: 14)),
                    ],
                  ),
                );
              },
            ),
            pw.SizedBox(height: 20),
            pw.Text(
                // "Total Expenses: ${_totalExpense.toStringAsFixed(2)} rs",
                "${languageProvider.isEnglish ? 'Total Expenses:' : 'کل اخراجات:'} ${_totalExpense.toStringAsFixed(2)} rs",
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text(
                // "Remaining Balance: ${_remainingBalance.toStringAsFixed(2)} rs",
                "${languageProvider.isEnglish ? 'Remaining Balance:' : 'بقایا رقم:'} ${_remainingBalance.toStringAsFixed(2)} rs",
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ],
        );
      },
    ));

    // Save PDF to file or print
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }


  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.isEnglish ? 'View Daily Expense:' : 'روزانہ کے اخراجات',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.teal.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddExpensePage()),
              );
            },
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _generatePdf, // Trigger PDF generation and printing
            color: Colors.white,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Show original opening balance and selected date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // "Opening Balance: ${_originalOpeningBalance.toStringAsFixed(2)} rs",
                      // '${languageProvider.isEnglish ? 'Opening Balance:' : 'اوپننگ بیلنس:'} ${_originalOpeningBalance.toStringAsFixed(2)} rs',
                      '${languageProvider.isEnglish ? 'Opening Balance: ${_originalOpeningBalance.toStringAsFixed(2)} rs' : ' اوپننگ بیلنس: ${_originalOpeningBalance.toStringAsFixed(2)} روپے'}',

                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      // "Selected Date: ${DateFormat('dd:MM:yyyy').format(_selectedDate)}",
                      '${languageProvider.isEnglish ? 'Selected Date:' : 'تاریخ منتخب کریں:'} ${DateFormat('dd:MM:yyyy').format(_selectedDate)}',

                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.date_range,color: Colors.white,),
                  // label: const Text('Change Date'),
                  label: Text(
                      '${languageProvider.isEnglish ? 'Change Date:' : 'تاریخ تبدیل کریں:'}',
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.teal.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Display expenses for the selected date
            expenses.isEmpty
                ? Center(
              child: Text(
                // "No expenses found for this date.",
                '${languageProvider.isEnglish ? 'No expenses found for this date' : 'اس تاریخ کے لیے کوئی اخراجات نہیں ملے'}',
                style: TextStyle(color: Colors.teal.shade700, fontSize: 18),
              ),
            )
                : Expanded(
              child: ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (ctx, index) {
                  final expense = expenses[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      title: Text(
                        expense["description"],
                        style: TextStyle(
                          color: Colors.teal.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        expense["date"],
                        style: TextStyle(color: Colors.teal.shade600),
                      ),
                      trailing: Text(
                        "${expense["amount"].toStringAsFixed(2)}rs",
                        style: TextStyle(
                          color: Colors.teal.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Show total expense and remaining balance
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Column(
                children: [
                  Text(
                    // "Total Expenses: ${_totalExpense.toStringAsFixed(2)} rs",
                    '${languageProvider.isEnglish ? 'Total Expenses: ${_totalExpense.toStringAsFixed(2)} rs' : 'کل اخراجات: ${_totalExpense.toStringAsFixed(2)} روپے'}',

                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade700,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    // "Remaining Balance: ${_remainingBalance.toStringAsFixed(2)} rs",
                    // '${languageProvider.isEnglish ? 'Remaining Balance:' : 'بقایا رقم'} ${_remainingBalance.toStringAsFixed(2)} rs',
                    '${languageProvider.isEnglish ? 'Remaining Balance: ${_remainingBalance.toStringAsFixed(2)} rs ': 'بقایا رقم${_remainingBalance.toStringAsFixed(2)}ّروپے'}',

                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
