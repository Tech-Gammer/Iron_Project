import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Provider/lanprovider.dart';
import 'FilledbypaymentType.dart';
import 'bypaymentType.dart';
import 'custoemrreports.dart';
import 'customerlistforreport.dart';
import 'filledcustomerlistreport.dart';


class ledgerselection extends StatelessWidget {
  const ledgerselection({Key? key}) : super(key: key);

  // Function to navigate or perform actions when a card is tapped
  void _onCardTap(BuildContext context, String reportType) {
    if (reportType == 'Sarya Ledger') {
      // Navigate to PaymentTypeReportPage
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CustomerListPage()),
      );
    } else if (reportType == 'Filled Ledger') {
      // Show a SnackBar or navigate to another page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => Filledcustomerlistpage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            // 'Ledger Reports'
          languageProvider.isEnglish ? 'Ledger Reports' : 'لیجر رپورٹس', // Dynamic text based on language
            style: TextStyle(color: Colors.white)
        ),
        centerTitle: true,
        backgroundColor: Colors.teal.shade800, // AppBar color to teal

      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          // Align cards to the start vertically
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sarya Reports Card
            GestureDetector(
              onTap: () => _onCardTap(context, 'Sarya Ledger'),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.insert_drive_file,
                        size: 48,
                        color: Colors.blue,
                      ),
                      SizedBox(height: 16),
                      Text(
                        // 'Sarya Ledger',
                        languageProvider.isEnglish ? 'Sarya Ledger' : 'سریا لیجر', // Dynamic text based on language
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            // Filled Reports Card
            GestureDetector(
              onTap: () => _onCardTap(context, 'Filled Ledger'),
              child: Card(
                elevation: 4,
                color: Colors.green[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.assignment_turned_in,
                        size: 48,
                        color: Colors.green,
                      ),
                      SizedBox(height: 16),
                      Text(
                        // 'Filled Ledger',
                        languageProvider.isEnglish ? 'Filled Ledger' : 'فلڈ لیجر', // Dynamic text based on language

                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // You can add more widgets here if needed
          ],
        ),
      ),
    );
  }
}
