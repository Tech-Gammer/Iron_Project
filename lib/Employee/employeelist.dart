import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Provider/employeeprovider.dart';
import 'addemployee.dart';
import 'attendance.dart';

class EmployeeListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final employeeProvider = Provider.of<EmployeeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddEmployeePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AttendanceReportPage()),
              );
            },
          ),
        ],
        backgroundColor: Colors.teal.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Address')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Actions')),
                    DataColumn(label: Text('Attendance')),
                  ],
                  rows: employeeProvider.employees.entries.map((entry) {
                    final id = entry.key;
                    final employee = entry.value;
                    return DataRow(cells: [
                      DataCell(Text(employee['name'] ?? '')),
                      DataCell(Text(employee['address'] ?? '')),
                      DataCell(Text(employee['phone'] ?? '')),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.teal),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddEmployeePage(employeeId: id),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteConfirmationDialog(context, id),
                          ),
                        ],
                      )),
                      DataCell(Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => _markAttendance(context, id, 'present'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green, // Present button color
                            ),
                            child: const Text('Present'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _markAttendance(context, id, 'absent'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red, // Absent button color
                            ),
                            child: const Text('Absent'),
                          ),
                        ],
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show a dialog to confirm marking attendance
  void _markAttendance(BuildContext context, String id, String status) {
    String description = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Mark Attendance as $status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please provide a description for the $status status:'),
              TextField(
                onChanged: (value) {
                  description = value;
                },
                decoration: const InputDecoration(hintText: 'Enter description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog without action
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final currentDate = DateTime.now();
                // Call the method to mark attendance only if it hasn't been marked yet
                Provider.of<EmployeeProvider>(context, listen: false)
                    .markAttendance(context, id, status, description, currentDate);
                Navigator.pop(context); // Close the dialog after saving
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this employee?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Provider.of<EmployeeProvider>(context, listen: false)
                    .deleteEmployee(id);
                Navigator.pop(context); // Close the dialog after deletion
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

}
