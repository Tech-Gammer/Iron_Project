import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'Provider/customerprovider.dart'; // Import your customer provider

class InvoicePage extends StatefulWidget {
  @override
  _InvoicePageState createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  String? _selectedCustomerId;
  double _discount = 0.0; // Discount amount or percentage

  List<Map<String, dynamic>> _invoiceRows = [
    {
      'total': 0.0,
      'rate': 0.0,
      'qty': 0.0,
      'weight': 0.0,
      'description': '',
    },
  ];

  String generateInvoiceNumber() {
    // Generate a timestamp as invoice number (in milliseconds)
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  void _addNewRow() {
    setState(() {
      _invoiceRows.add({
        'total': 0.0,
        'rate': 0.0,
        'qty': 0.0,
        'weight': 0.0,
        'description': '',
      });
    });
  }

  void _updateRow(int index, String field, dynamic value) {
    setState(() {
      _invoiceRows[index][field] = value;

      // If both Sarya Rate and Sarya Qty are filled, calculate the Total
      if (_invoiceRows[index]['rate'] != 0.0 && _invoiceRows[index]['qty'] != 0.0) {
        _invoiceRows[index]['total'] = _invoiceRows[index]['rate'] * _invoiceRows[index]['qty'];
      }
    });
  }

  void _deleteRow(int index) {
    setState(() {
      _invoiceRows.removeAt(index);
    });
  }

  double _calculateSubtotal() {
    return _invoiceRows.fold(0.0, (sum, row) => sum + row['total']);
  }

  // double _calculateGrandTotal() {
  //   double subtotal = _calculateSubtotal();
  //   double discountAmount = _discount > 0 ? (subtotal * (_discount / 100)) : _discount;
  //   return subtotal - discountAmount;
  // }

  double _calculateGrandTotal() {
    double subtotal = _calculateSubtotal();
    // Discount is directly subtracted from subtotal
    double discountAmount = _discount;
    return subtotal - discountAmount;
  }

  @override
  void initState() {
    super.initState();
    // Fetch the customers when the page is initialized
    Provider.of<CustomerProvider>(context, listen: false).fetchCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Invoice'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Invoice #${generateInvoiceNumber()}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Consumer<CustomerProvider>(
          builder: (context, customerProvider, child) {
            if (customerProvider.customers.isEmpty) {
              return const Center(child: CircularProgressIndicator()); // Show loading indicator if customers are still being fetched
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dropdown to select customer
                  const Text('Select Customer:', style: TextStyle(fontSize: 18)),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCustomerId,
                    hint: const Text('Choose a customer'),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCustomerId = newValue;
                      });
                    },
                    items: customerProvider.customers.map<DropdownMenuItem<String>>((Customer customer) {
                      return DropdownMenuItem<String>(
                        value: customer.id,
                        child: Text(customer.name), // Display customer's name
                      );
                    }).toList(),
                  ),
                  // Show selected customer name
                  if (_selectedCustomerId != null)
                    Text('Selected Customer: ${customerProvider.customers.firstWhere((customer) => customer.id == _selectedCustomerId).name}'),

                  // Space between sections
                  const SizedBox(height: 20),

                  // Display columns for the invoice details
                  const Text('Invoice Details:', style: TextStyle(fontSize: 18)),
                  Table(
                    border: TableBorder.all(),
                    columnWidths: {
                      0: const FlexColumnWidth(2),
                      1: const FlexColumnWidth(2),
                      2: const FlexColumnWidth(2),
                      3: const FlexColumnWidth(2),
                      4: const FlexColumnWidth(3),
                      5: const FlexColumnWidth(1), // For Delete button column
                    },
                    children: [
                      const TableRow(
                        children: [
                          TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Total', textAlign: TextAlign.center))),
                          TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Sarya Rate', textAlign: TextAlign.center))),
                          TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Sarya Qty', textAlign: TextAlign.center))),
                          TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Sarya Weight', textAlign: TextAlign.center))),
                          TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Description', textAlign: TextAlign.center))),
                          TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Delete', textAlign: TextAlign.center))),
                        ],
                      ),
                      // Generate a row for each item in _invoiceRows
                      for (int i = 0; i < _invoiceRows.length; i++)
                        TableRow(
                          children: [
                            // Total
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(_invoiceRows[i]['total'].toStringAsFixed(2), textAlign: TextAlign.center),
                              ),
                            ),
                            // Sarya Rate
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    _updateRow(i, 'rate', double.tryParse(value) ?? 0.0);
                                  },
                                  decoration: const InputDecoration(hintText: 'Rate'),
                                ),
                              ),
                            ),
                            // Sarya Qty
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    _updateRow(i, 'qty', double.tryParse(value) ?? 0.0);
                                  },
                                  decoration: const InputDecoration(hintText: 'Qty'),
                                ),
                              ),
                            ),
                            // Sarya Weight
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  onChanged: (value) {
                                    _updateRow(i, 'weight', double.tryParse(value) ?? 0.0);
                                  },
                                  decoration: const InputDecoration(hintText: 'Weight'),
                                ),
                              ),
                            ),
                            // Description
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  onChanged: (value) {
                                    _updateRow(i, 'description', value);
                                  },
                                  decoration: const InputDecoration(hintText: 'Description'),
                                ),
                              ),
                            ),
                            // Delete Button
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: IconButton(
                                  icon: const Icon(Icons.delete,color: Colors.red,),
                                  onPressed: () {
                                    _deleteRow(i); // Delete the current row
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  // add row button
                  IconButton(onPressed: (){
                    _addNewRow();
                  }, icon: const Icon(Icons.add)),
                  // Subtotal row
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Subtotal: ${_calculateSubtotal().toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Discount (Amount):', style: TextStyle(fontSize: 18)),
                  TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _discount = double.tryParse(value) ?? 0.0;
                      });
                    },
                    decoration: const InputDecoration(hintText: 'Enter discount'),
                  ),
                  // Grand Total row
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Grand Total: ${_calculateGrandTotal().toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
