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

  void _updateRemainingBalance() {
    setState(() {
      _remainingBalance = _originalOpeningBalance - _totalExpense;
    });
  }

  // Fetch the original opening balance for the selected date
  void _fetchOpeningBalance() async {
    String formattedDate = DateFormat('dd:MM:yyyy').format(_selectedDate);
    final snapshot = await dbRef.child("originalOpeningBalance").child(formattedDate).get();
    if (snapshot.exists) {
      setState(() {
        _originalOpeningBalance = (snapshot.value as num).toDouble();
      });
      _updateRemainingBalance();
    }
  }


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
          "amount": (value["amount"] as num).toDouble(),
          "date": value["date"] ?? formattedDate,
        });

        totalExpense += (value["amount"] as num).toDouble();
      });

      setState(() {
        expenses = loadedExpenses;
        _totalExpense = totalExpense;
      });
      _updateRemainingBalance();
    });
  }


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

  void _generatePdf() async {
    final pdf = pw.Document();

    // Split expenses into chunks of 20 items per page
    const int itemsPerPage = 20;
    int pageCount = (expenses.length / itemsPerPage).ceil();

    for (int pageIndex = 0; pageIndex < pageCount; pageIndex++) {
      // Create the PDF layout for each page
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final start = pageIndex * itemsPerPage;
          final end = (start + itemsPerPage > expenses.length)
              ? expenses.length
              : start + itemsPerPage;
          final pageExpenses = expenses.sublist(start, end);

          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Daily Expense Report',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF00695C),
                  ),
                ),
                pw.SizedBox(height: 15),
                pw.Text(
                  'Opening Balance: ${_originalOpeningBalance.toStringAsFixed(2)} rs',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.normal,
                  ),
                ),
                pw.Text(
                  'Selected Date: ${DateFormat('dd:MM:yyyy').format(_selectedDate)}',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.normal,
                  ),
                ),
                pw.SizedBox(height: 25),
                pw.Text(
                  'Expenses',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.ListView.builder(
                  itemCount: pageExpenses.length,
                  itemBuilder: (context, index) {
                    final expense = pageExpenses[index];
                    return pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          expense["description"],
                          style: pw.TextStyle(
                            fontSize: 20,
                          ),
                        ),
                        pw.Text(
                          "${expense["amount"].toStringAsFixed(2)} rs",
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          expense["date"],
                          style: pw.TextStyle(
                            fontSize: 20,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                pw.SizedBox(height: 25),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Total Expenses: ${_totalExpense.toStringAsFixed(2)} rs',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Remaining Balance: ${_remainingBalance.toStringAsFixed(2)} rs',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ));
    }

    // Save the PDF to a file or print it
    final output = await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }


  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.isEnglish ? 'View Daily Expense' : 'روزانہ کے اخراجات',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.teal,
        centerTitle: true,

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
            // Show original opening balance and selected dates
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
