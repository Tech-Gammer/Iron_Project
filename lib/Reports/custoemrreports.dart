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
              final date = DateFormat('dd MMM yy').parse(transaction['date']);
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold,fontSize: 20),
                          ),
                          Text('Phone Number: ${widget.customerPhone}'),
                          const SizedBox(height: 10),
                          Text(
                            selectedDateRange == null
                                ? 'All Transactions'
                                : '${DateFormat('dd MMM yy').format(selectedDateRange!.start)} - ${DateFormat('dd MMM yy').format(selectedDateRange!.end)}',
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
                        ),
                        if (selectedDateRange != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                selectedDateRange = null;
                              });
                            },
                            child: const Text('Clear Filter'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Summary Section
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSummaryItem('Opening Balance', 'Rs 0 (Settled)', context),
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
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 10),
                    DataTable(
                      columns: const [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Invoice Number')),
                        DataColumn(label: Text('Payment Type')),
                        DataColumn(label: Text('Payment Method')),
                        DataColumn(label: Text('Debit (-)')),
                        DataColumn(label: Text('Credit (+)')),
                        DataColumn(label: Text('Balance')),
                      ],
                      rows: transactions.map((transaction) {
                        final paymentMethod = transaction['paymentMethod']; // Assuming this field exists in your data
                        final paymentType = transaction['paymentType']; // Assuming this field exists in your data
                        final grandTotal = transaction['grandTotal'] ?? 0.0; // Assuming 'grandTotal' exists

                        // Determine values based on payment method
                        final debit = paymentMethod == 'cash' ? grandTotal : 0.0;
                        final credit = paymentType == 'udhaar' ? grandTotal : 0.0;
                        final balance = paymentMethod == 'cash' ? 0.0 : transaction['balance'];

                        return DataRow(
                          cells: [
                            DataCell(Text(transaction['createdAt'] ?? 'N/A')),
                            DataCell(Text(transaction['invoiceNumber'] ?? 'N/A')),
                            DataCell(Text(transaction['paymentType'] ?? 'N/A')),
                            DataCell(Text(transaction['paymentMethod'] ?? 'N/A')),
                            // DataCell(Text(transaction['debit']?.toStringAsFixed(2) ?? '-')),
                            // DataCell(Text(transaction['credit']?.toStringAsFixed(2) ?? '-')),
                            // DataCell(Text(transaction['balance']?.toStringAsFixed(2) ?? '-')),
                            DataCell(Text(debit != 0.0 ? 'Rs ${debit.toStringAsFixed(2)}' : '-')),
                            DataCell(Text(credit != 0.0 ? 'Rs ${credit.toStringAsFixed(2)}' : '-')),
                            DataCell(Text(balance != null ? 'Rs ${balance.toStringAsFixed(2)}' : '-')),
                          ],
                        );
                      }).toList(),
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
          style: Theme.of(context).textTheme.bodySmall,
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
