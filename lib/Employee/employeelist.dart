import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Provider/employeeprovider.dart';
import '../Provider/lanprovider.dart';
import 'addemployee.dart';
import 'attendance.dart';

class EmployeeListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final employeeProvider = Provider.of<EmployeeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        // title: const Text('Employee List'),sss
        title: Text(languageProvider.isEnglish ? 'Employee List' : 'ملازمین کی فہرست',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.teal,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add,color: Colors.white,),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddEmployeePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics,color: Colors.white,),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AttendanceReportPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(languageProvider.isEnglish ? 'Name' : 'نام',style: TextStyle(fontSize: 20),)),
                    DataColumn(label: Text(languageProvider.isEnglish ? 'Address' : 'ایڈریس',style: TextStyle(fontSize: 20),)),
                    DataColumn(label: Text(languageProvider.isEnglish ? 'Phone No' : 'فون نمبر',style: TextStyle(fontSize: 20),)),
                    DataColumn(label: Text(languageProvider.isEnglish ? 'Action' : 'ایکشن',style: TextStyle(fontSize: 20),)),
                    DataColumn(label: Text(languageProvider.isEnglish ? 'Attendance' : 'حاضری',style: TextStyle(fontSize: 20),)),
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
                          // IconButton(
                          //   icon: const Icon(Icons.delete, color: Colors.red),
                          //   onPressed: () => _showDeleteConfirmationDialog(context, id),
                          // ),
                        ],
                      )),
                      DataCell(Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => _markAttendance(context, id, 'present'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green, // Present button color
                            ),
                            child:  Text(
                              languageProvider.isEnglish ? 'Present' : 'حاضر',                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _markAttendance(context, id, 'absent'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red, // Absent button color
                            ),
                            child:  Text(
                              languageProvider.isEnglish ? 'Absent' : 'غیرحاضر',
                            ),
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


  void _markAttendance(BuildContext parentContext, String id, String status) {
    final languageProvider = Provider.of<LanguageProvider>(parentContext, listen: false); // Access LanguageProvider

    String description = '';
    showDialog(
      context: parentContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          // title: Text('Mark Attendance as $status'),
          title: Text(
            languageProvider.isEnglish
                ? 'Mark Attendance as $status'
                // : 'حاضری کو $status کے طور پر نشان زد کریں',
                : 'کے طور پر حاضری درج کریں$status'
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Text('Please provide a description for the $status status:'),
              Text(
                languageProvider.isEnglish
                    ? 'Please provide a description for the $status status:'
                    : ' کی حالت کے لئے وضاحت فراہم کریں:''$status',
              ),
              TextField(
                onChanged: (value) {
                  description = value;
                },
                // decoration: const InputDecoration(hintText: 'Enter description'),
                decoration: InputDecoration(hintText: languageProvider.isEnglish ? 'Enter description' : 'وضاحت درج کریں'),

              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close the dialog without action
              },
              // child: const Text('Cancel'),
              child: Text(languageProvider.isEnglish ? 'Cancel' : 'رد کریں'),

            ),
            ElevatedButton(
              onPressed: () {
                final currentDate = DateTime.now();
                Provider.of<EmployeeProvider>(parentContext, listen: false)
                    .markAttendance(parentContext, id, status, description, currentDate);
                Navigator.pop(dialogContext); // Close the dialog after saving
              },
              // child: const Text('OK'),
              child: Text(languageProvider.isEnglish ? 'OK' : 'ٹھیک ہے'),

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
