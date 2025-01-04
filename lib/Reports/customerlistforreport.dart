import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Provider/customerprovider.dart';
import 'custoemrreports.dart';

class CustomerListPage extends StatefulWidget {
  @override
  _CustomerListPageState createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  @override
  void initState() {
    super.initState();
    // Fetch customers when the page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CustomerProvider>(context, listen: false).fetchCustomers();
    });
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
                  // Navigate to the customer report page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomerReportPage(
                        customerId: customer.id,
                        customerName: customer.name,
                        customerPhone: customer.phone,
                      ),
                    ),
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
