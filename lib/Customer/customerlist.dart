import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Provider/customerprovider.dart';
import 'addcustomers.dart';

class CustomerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customer List'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
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
                  snapshot.connectionState == ConnectionState.active  ) {
                return Center(child: CircularProgressIndicator());
              }

              if (customerProvider.customers.isEmpty) {
                return Center(
                  child: Text('No customers found.'),
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
                        columns: const [
                          DataColumn(label: Text('#')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Address')),
                          DataColumn(label: Text('Phone')),
                          DataColumn(label: Text('Actions')),
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
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    _showEditDialog(context, customer, customerProvider);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _confirmDelete(context, customer.id, customerProvider);
                                  },
                                ),
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
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('${index + 1}'),
                            ),
                            title: Text(customer.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(customer.address),
                                SizedBox(height: 4),
                                Text(customer.phone),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    _showEditDialog(context, customer, customerProvider);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _confirmDelete(context, customer.id, customerProvider);
                                  },
                                ),
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
          title: Text('Edit Customer'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
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
          title: Text('Delete Customer'),
          content: Text('Are you sure you want to delete this customer?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                customerProvider.deleteCustomer(customerId);
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
