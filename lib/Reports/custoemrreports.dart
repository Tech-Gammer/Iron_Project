import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../Provider/reportprovider.dart';

class CustomerReportPage extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String customerPhone;

  const CustomerReportPage({
    Key? key,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
  }) : super(key: key);

  @override
  State<CustomerReportPage> createState() => _CustomerReportPageState();
}

class _CustomerReportPageState extends State<CustomerReportPage> {
  DateTimeRange? selectedDateRange;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CustomerReportProvider()..fetchCustomerReport(widget.customerId),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Customer Report'),
          backgroundColor: Colors.teal,  // Customize the AppBar color
        ),
        body: Consumer<CustomerReportProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error.isNotEmpty) {
              return Center(child: Text(provider.error));
            }

            final report = provider.report;
            final transactions = selectedDateRange == null
                ? provider.transactions
                : provider.transactions.where((transaction) {
              final date = DateTime.parse(transaction['date']);
              return date.isAfter(selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                  date.isBefore(selectedDateRange!.end.add(const Duration(days: 1)));
            }).toList();

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Center(
                      child: Column(
                        children: [
                          Text(
                            widget.customerName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: Colors.teal.shade800,  // Title color
                            ),
                          ),
                          Text(
                            'Phone Number: ${widget.customerPhone}',
                            style: TextStyle(color: Colors.teal.shade600),  // Subtext color
                          ),
                          const SizedBox(height: 10),
                          Text(
                            selectedDateRange == null
                                ? 'All Transactions'
                                : '${DateFormat('dd MMM yy').format(selectedDateRange!.start)} - ${DateFormat('dd MMM yy').format(selectedDateRange!.end)}',
                            style: TextStyle(color: Colors.teal.shade700),  // Date range color
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Date Range Picker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final pickedDateRange = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (pickedDateRange != null) {
                              setState(() {
                                selectedDateRange = pickedDateRange;
                              });
                            }
                          },
                          icon: const Icon(Icons.date_range),
                          label: const Text('Select Date Range'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white, backgroundColor: Colors.teal.shade400, // Text color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        if (selectedDateRange != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                selectedDateRange = null;
                              });
                            },
                            child: const Text('Clear Filter', style: TextStyle(color: Colors.teal)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Summary Section
                    Card(
                      color: Colors.teal.shade50,  // Background color for summary card
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSummaryItem('Total Debit (-)', 'Rs ${report['debit']?.toStringAsFixed(2)}', context),
                            _buildSummaryItem('Total Credit (+)', 'Rs ${report['credit']?.toStringAsFixed(2)}', context),
                            _buildSummaryItem(
                              'Net Balance',
                              'Rs ${report['balance']?.toStringAsFixed(2)}',
                              context,
                              isHighlight: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Transactions Table
                    Text(
                      'No. of Entries: ${transactions.length} (Filtered)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.teal.shade700),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: SizedBox(
                        width: double.infinity,  // Make the table take full width
                        child: DataTable(
                          headingRowHeight: 60,  // Increase heading row height
                          dataRowHeight: 60,  // Increase data row height
                          columnSpacing: 20,  // Increase column spacing
                          columns: const [
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Invoice Number')),
                            DataColumn(label: Text('Transaction Type')),
                            DataColumn(label: Text('Debit (-)')),
                            DataColumn(label: Text('Credit (+)')),
                            DataColumn(label: Text('Balance')),
                          ],
                          rows: transactions.map((transaction) {
                            return DataRow(
                              cells: [
                                DataCell(Text(transaction['date'] ?? 'N/A')),
                                DataCell(Text(transaction['invoiceNumber'] ?? 'N/A')),
                                DataCell(Text(transaction['credit'] != 0.0 ? 'Invoice' : (transaction['debit'] != 0.0 ? 'Bill' : '-'))),
                                DataCell(Text(transaction['debit'] != 0.0 ? 'Rs ${transaction['debit']?.toStringAsFixed(2)}' : '-')),
                                DataCell(Text(transaction['credit'] != 0.0 ? 'Rs ${transaction['credit']?.toStringAsFixed(2)}' : '-')),
                                DataCell(Text('Rs ${transaction['balance']?.toStringAsFixed(2)}')),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, BuildContext context, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.teal.shade600),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isHighlight ? Colors.red : Colors.black,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
