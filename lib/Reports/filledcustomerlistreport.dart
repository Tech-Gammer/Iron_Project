import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Provider/customerprovider.dart';
import '../Provider/lanprovider.dart';
import 'filledbycustomerreport.dart';
import 'filledledgerreport.dart';

class Filledcustomerlistpage extends StatefulWidget {
  @override
  _FilledcustomerlistpageState createState() => _FilledcustomerlistpageState();
}

class _FilledcustomerlistpageState extends State<Filledcustomerlistpage> {
  @override
  void initState() {
    super.initState();
    // Fetch customers when the page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CustomerProvider>(context, listen: false).fetchCustomers();
    });
  }
  void _showReportOptions(BuildContext context, String customerName, String customerPhone, String customerId) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            languageProvider.isEnglish ? 'Select Report' : ' رپورٹس منتخب کریں',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: Text(
                  // 'Ledger'
                  languageProvider.isEnglish ? 'Ledger' : 'لیجر', // Dynamic text based on language
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FilledLedgerReportPage(
                        customerId: customerId,
                        customerName: customerName,
                        customerPhone: customerPhone,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                title: Text(
                  // 'Reports by customerName'
                  languageProvider.isEnglish ? 'Reports by CustomerName' : 'کسٹمر نام کے ذریعہ رپورٹس', // Dynamic text based on language
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => filledbycustomerreport(
                        customerId: customerId,
                        customerName: customerName,
                        customerPhone: customerPhone,
                      ),
                    ),
                  );
                },
              ),

            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          // 'Customer List For Filled ledger',
          languageProvider.isEnglish ? 'Customer List For Filled Ledger' : 'فلڈ لیجر کے لیے صارفین کی فہرست',
          style: TextStyle(
            color: Colors.white, // Title text color
            fontSize: 20
          ),
        ),
        backgroundColor: Colors.teal, // AppBar background color
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, customerProvider, child) {
          // Check if customers have been loaded
          if (customerProvider.customers.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.teal.shade400), // Loading indicator color
              ),
            );
          }
          // Display customers in a ListView
          return ListView.builder(
            itemCount: customerProvider.customers.length,
            itemBuilder: (context, index) {
              final customer = customerProvider.customers[index];
              return ListTile(
                title: Text(
                  customer.name,
                  style: TextStyle(
                    color: Colors.teal.shade800, // Title text color
                  ),
                ),
                subtitle: Text(
                  customer.phone,
                  style: TextStyle(
                    color: Colors.teal.shade600, // Subtitle text color
                  ),
                ),
                onTap: () {
                  // Navigate to the customer report page
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => CustomerReportPage(
                  //       customerId: customer.id,
                  //       customerName: customer.name,
                  //       customerPhone: customer.phone,
                  //     ),
                  //   ),
                  // );
                  _showReportOptions(
                    context,
                    customer.name,
                    customer.phone,
                    customer.id,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
