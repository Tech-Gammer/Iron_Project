import 'package:flutter/material.dart';
import 'package:iron_project_new/Reports/udhaar.dart';
import 'package:provider/provider.dart';
import '../Provider/customerprovider.dart';
import 'bankreport.dart';
import 'cashreport.dart';
import 'custoemrreports.dart'; // Assuming the report pages are imported here

class Threetypesreportslistcustomer extends StatefulWidget {
  @override
  _ThreetypesreportslistcustomerState createState() =>
      _ThreetypesreportslistcustomerState();
}

class _ThreetypesreportslistcustomerState
    extends State<Threetypesreportslistcustomer> {
  @override
  void initState() {
    super.initState();
    // Fetch customers when the page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CustomerProvider>(context, listen: false).fetchCustomers();
    });
  }

  // Function to show the dialog with the three report options
  void _showReportDialog(BuildContext context, String customerName, String customerPhone) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Payment Type Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Online Bank Transfer report
              ListTile(
                title: Text('Online Bank Transfer'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OnlineBankTransferReportPage(
                        customerName: customerName,
                        customerPhone: customerPhone,
                        paymentMethod: 'Online Bank Transfer',
                      ),
                    ),
                  );
                },
              ),
              // Cash report
              ListTile(
                title: Text('Cash Payment'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CashPaymentReportPage(
                        customerName: customerName,
                        customerPhone: customerPhone,
                        paymentMethod: 'Cash',
                      ),
                    ),
                  );
                },
              ),
              // Udhaar report
              ListTile(
                title: Text('Udhaar (Credit)'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UdhaarPaymentReportPage(
                        customerName: customerName,
                        customerPhone: customerPhone,
                        paymentMethod: 'Udhaar',
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Customer List',
          style: TextStyle(
            color: Colors.teal.shade800, // Title text color
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
                  // Show the dialog when a customer is selected
                  _showReportDialog(context, customer.name, customer.phone);
                },
              );
            },
          );
        },
      ),
    );
  }
}
