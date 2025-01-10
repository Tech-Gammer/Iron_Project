import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Provider/customerprovider.dart';
import '../Provider/lanprovider.dart';
import 'addcustomers.dart';

class CustomerList extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
            // 'Customer List',
            languageProvider.isEnglish ? 'Customer List' : 'کسٹمر کی فہرست', // Dynamic text based on language

            style: TextStyle(color: Colors.white)
        ),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddCustomer()),
              );
            },
          ),
        ],
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, customerProvider, child) {
          return FutureBuilder(
            future: customerProvider.fetchCustomers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active ||
                  snapshot.connectionState == ConnectionState.active) {
                return Center(child: CircularProgressIndicator());
              }

              if (customerProvider.customers.isEmpty) {
                return Center(
                  child: Text(
                      // 'No customers found.',
                      languageProvider.isEnglish ? 'No customers found.' : 'کوئی کسٹمر موجود نہیںٓ',

                      style: TextStyle(color: Colors.teal.shade600)),
                );
              }

              // Responsive layout
              return LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 600) {
                    // Web layout
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: DataTable(
                        columns: [
                          const DataColumn(label: Text('#')),
                          DataColumn(label: Text(languageProvider.isEnglish ? 'Name' : 'نام',style: TextStyle(fontSize: 20),)),
                          DataColumn(label: Text(languageProvider.isEnglish ? 'Name' : 'نام',style: TextStyle(fontSize: 20),)),
                          DataColumn(label: Text(languageProvider.isEnglish ? 'Phone' : 'فون',style: TextStyle(fontSize: 20),)),
                          DataColumn(label: Text(languageProvider.isEnglish ? 'Actions' : 'عمل',style: TextStyle(fontSize: 20),)),
                        ],
                        rows: customerProvider.customers
                            .asMap()
                            .entries
                            .map((entry) {
                          final index = entry.key + 1;
                          final customer = entry.value;
                          return DataRow(cells: [
                            DataCell(Text('$index')),
                            DataCell(Text(customer.name)),
                            DataCell(Text(customer.address)),
                            DataCell(Text(customer.phone)),
                            DataCell(Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.teal),
                                  onPressed: () {
                                    _showEditDialog(context, customer, customerProvider);
                                  },
                                ),
                                // IconButton(
                                //   icon: Icon(Icons.delete, color: Colors.red),
                                //   onPressed: () {
                                //     _confirmDelete(context, customer.id, customerProvider);
                                //   },
                                // ),
                              ],
                            )),
                          ]);
                        }).toList(),
                      ),
                    );
                  } else {
                    // Mobile layout
                    return ListView.builder(
                      itemCount: customerProvider.customers.length,
                      itemBuilder: (context, index) {
                        final customer = customerProvider.customers[index];
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          color: Colors.teal.shade50,  // Add background color from the palette
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal.shade400,
                              child: Text('${index + 1}', style: TextStyle(color: Colors.white)),
                            ),
                            title: Text(customer.name, style: TextStyle(color: Colors.teal.shade800)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(customer.address, style: TextStyle(color: Colors.teal.shade600)),
                                SizedBox(height: 4),
                                Text(customer.phone, style: TextStyle(color: Colors.teal.shade600)),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.teal),
                                  onPressed: () {
                                    _showEditDialog(context, customer, customerProvider);
                                  },
                                ),
                                // IconButton(
                                //   icon: Icon(Icons.delete, color: Colors.red),
                                //   onPressed: () {
                                //     _confirmDelete(context, customer.id, customerProvider);
                                //   },
                                // ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showEditDialog(
      BuildContext context,
      Customer customer,
      CustomerProvider customerProvider,
      ) {
    final nameController = TextEditingController(text: customer.name);
    final addressController = TextEditingController(text: customer.address);
    final phoneController = TextEditingController(text: customer.phone);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
              'Edit Customer',
              style: TextStyle(color: Colors.teal.shade800)),
          backgroundColor: Colors.teal.shade50,
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.teal.shade600)),
                ),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(labelText: 'Address', labelStyle: TextStyle(color: Colors.teal.shade600)),
                ),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'Phone', labelStyle: TextStyle(color: Colors.teal.shade600)),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.teal.shade800)),
            ),
            ElevatedButton(
              onPressed: () {
                customerProvider.updateCustomer(
                  customer.id,
                  nameController.text,
                  addressController.text,
                  phoneController.text,
                );
                Navigator.pop(context);
              },
              child: Text('Save'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade400),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String customerId, CustomerProvider customerProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Customer', style: TextStyle(color: Colors.teal.shade800)),
          backgroundColor: Colors.teal.shade50,
          content: Text('Are you sure you want to delete this customer?', style: TextStyle(color: Colors.teal.shade600)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.teal.shade800)),
            ),
            ElevatedButton(
              onPressed: () {
                customerProvider.deleteCustomer(customerId);
                Navigator.pop(context);
              },
              child: Text('Delete'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade400),
            ),
          ],
        );
      },
    );
  }
}
