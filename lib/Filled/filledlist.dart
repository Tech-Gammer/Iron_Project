import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../Provider/filled provider.dart';
import 'filledpage.dart';

class filledListpage extends StatefulWidget {
  @override
  _filledListpageState createState() => _filledListpageState();
}

class _filledListpageState extends State<filledListpage> {
  TextEditingController _searchController = TextEditingController();
  final TextEditingController _paymentController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  List<Map<String, dynamic>> _filteredFilled = [];

  @override
  Widget build(BuildContext context) {
    final filledProvider = Provider.of<FilledProvider>(context);

    _filteredFilled = filledProvider.filled.where((filled) {
      final searchQuery = _searchController.text.toLowerCase();
      final filledNumber = (filled['filledNumber'] ?? '').toString().toLowerCase();
      final matchesSearch = filledNumber.contains(searchQuery);

      if (_selectedDateRange != null) {
        final filledDateStr = filled['createdAt'];
        DateTime? filledDate;

        // Parse the date, accounting for different formats
        try {
          filledDate = DateTime.tryParse(filledDateStr) ?? DateTime.fromMillisecondsSinceEpoch(int.parse( filledDateStr));
        } catch (e) {
          print('Error parsing date: $e');
          return false;
        }

        final isInDateRange = (filledDate.isAfter(_selectedDateRange!.start) ||
            filledDate.isAtSameMomentAs(_selectedDateRange!.start)) &&
            (filledDate.isBefore(_selectedDateRange!.end) ||
                filledDate.isAtSameMomentAs(_selectedDateRange!.end));

        return matchesSearch && isInDateRange;
      }

      return matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filled List'),
        centerTitle: true,
        backgroundColor: Colors.teal,  // AppBar background color
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => filledpage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Filled ID',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear(); // Clear the text in the TextField
                    });
                  },
                )
                    : null, // Only show clear icon when there's text
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {}); // Rebuild to show/hide the clear icon dynamically
              },
            ),
          ),

          // Date Range Picker
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton(
              onPressed: () async {
                DateTimeRange? pickedDateRange = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                  initialDateRange: _selectedDateRange,
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.light().copyWith(
                        primaryColor: Colors.blue,
                        hintColor: Colors.blue,
                        buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
                      ),
                      child: child!,
                    );
                  },
                );

                if (pickedDateRange != null) {
                  setState(() {
                    _selectedDateRange = pickedDateRange;
                  });
                }
              },
              child: Text(
                _selectedDateRange == null
                    ? 'Select Date Range'
                    : 'From: ${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start)} - To: ${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end)}',
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.teal.shade400, // Text color
              ),
            ),
          ),
          // Buttons to remove filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Clear date range filter button
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedDateRange = null;
                    });
                  },
                  child: const Text('Clear Date Range'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.teal.shade400, // Text color
                  ),
                ),
              ],
            ),
          ),
          // Filled List
          Expanded(
            child: FutureBuilder(
              future:  filledProvider.fetchFilled(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_filteredFilled.isEmpty) {
                  return const Center(child: Text('No  filled found.'));
                }
                return ListView.builder(
                  itemCount: _filteredFilled.length,
                  itemBuilder: (context, index) {
                    final  filled = Map<String, dynamic>.from(_filteredFilled[index]);
                    final grandTotal = filled['grandTotal'] ?? 0.0;
                    final debitAmount = filled['debitAmount'] ?? 0.0;
                    final remainingAmount = grandTotal - debitAmount;
                    return ListTile(
                      title: Text('Filled #${filled['filledNumber']}'),
                      subtitle: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text('Customer: ${filled['customerName']?? 'Unknown'}'),
                          const SizedBox(width: 20,),
                          Text('Date and Time: ${filled['createdAt']}'),
                          const SizedBox(width: 20,),
                          IconButton(
                            icon: const Icon(Icons.payment),
                            onPressed: () {
                              _showFilledPaymentDialog(filled, filledProvider);
                            },
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min, // Ensures the row takes only as much space as needed
                        children: [
                          Text('Rs ${filled['grandTotal']}', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10), // Adds some space between the two texts
                          Text(
                            'Remaining: Rs ${remainingAmount.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 16, color: Colors.red),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => filledpage(
                              filled: Map<String, dynamic>.from(_filteredFilled[index]), // Pass selected filled
                            ),
                          ),
                        );
                      },
                      onLongPress: () {
                        // Show delete confirmation dialog
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Delete Filled'),
                              content: const Text('Are you sure you want to delete this filled?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    // Call deletefilled from the filledProvider
                                    await filledProvider.deleteFilled(filled['id']);
                                    Navigator.of(context).pop(); // Close the dialog
                                  },
                                  child: const Text('Delete'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilledPaymentDialog(
      Map<String, dynamic> filled, FilledProvider filledProvider) async {
    _paymentController.clear();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pay Filled'),
          content: TextField(
            controller: _paymentController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Enter Payment Amount',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final amount = double.tryParse(_paymentController.text);
                if (amount != null && amount > 0) {
                  // awaitfilledProvider.addDebit(filled['id'], amount);
                  await filledProvider.payFilled(context, filled['id'], amount);
                  Navigator.of(context).pop();
                } else {
                  // Handle invalid input
                }
              },
              child: const Text('Pay'),
            ),
          ],
        );
      },
    );
  }
}
