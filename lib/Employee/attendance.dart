import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../Provider/employeeprovider.dart';

class AttendanceReportPage extends StatefulWidget {
  @override
  _AttendanceReportPageState createState() => _AttendanceReportPageState();
}

class _AttendanceReportPageState extends State<AttendanceReportPage> {
  String _searchName = '';
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final employeeProvider = Provider.of<EmployeeProvider>(context);
    final employees = employeeProvider.employees;

    // Filter employees by name
    final filteredEmployees = employees.keys.where((employeeId) {
      final employeeName = employees[employeeId]!['name']!.toLowerCase();
      return employeeName.contains(_searchName.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Report'),
        backgroundColor: Colors.teal.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _generateAndPrintPdf(filteredEmployees, employeeProvider, employees),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Widgets
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search by Name',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchName = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final pickedDateRange = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDateRange != null) {
                      setState(() {
                        _dateRange = pickedDateRange;
                      });
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label: const Text('Select Date Range'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.teal.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredEmployees.length,
              itemBuilder: (context, index) {
                final employeeId = filteredEmployees[index];

                // Filter attendance based on date range
                if (_dateRange != null) {
                  final currentDate = DateTime.now();
                  if (currentDate.isBefore(_dateRange!.start) ||
                      currentDate.isAfter(_dateRange!.end)) {
                    return const SizedBox.shrink(); // Skip this employee
                  }
                }

                return FutureBuilder<Map<String, dynamic>>(
                  future: employeeProvider.getAttendance(employeeId, DateTime.now()),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      final attendance = snapshot.data!;
                      return ListTile(
                        title: Text(employees[employeeId]!['name']!),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Description: ${attendance['description']}'),
                            Row(
                              children: [
                                Text('Last Attendance: ${attendance['status']}'),
                                const Spacer(),
                                Text(
                                    'Date & Time: ${attendance['date']} ${attendance['time']}'),
                              ],
                            ),
                          ],
                        ),
                      );
                    } else {
                      return ListTile(
                        title: Text(employees[employeeId]!['name']!),
                        subtitle: const Text('No attendance marked for today'),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _generateAndPrintPdf(
      List<String> filteredEmployees,
      EmployeeProvider employeeProvider,
      Map<String, Map<String, String>> employees) async {

    final pdf = pw.Document();

    // Wait for all attendance data asynchronously before generating the PDF
    final employeeAttendances = await Future.wait(
      filteredEmployees.map((employeeId) async {
        final attendance = await employeeProvider.getAttendance(employeeId, DateTime.now());
        return MapEntry(employeeId, attendance);
      }),
    );

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Attendance Report',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 16),
              // Creating table headers
              pw.Table(
                border: pw.TableBorder.all(width: 1, color: PdfColors.black),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Employee Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      // pw.Text('Time', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),

                    ],
                  ),
                  // Adding table rows for each employee attendance
                  ...employeeAttendances.map((entry) {
                    final employeeId = entry.key;
                    final attendance = entry.value;
                    final employeeName = employees[employeeId]!['name']!;

                    // If attendance data is empty
                    if (attendance.isEmpty) {
                      return pw.TableRow(
                        children: [
                          pw.Text('N/A'),
                          pw.Text(employeeName),
                          pw.Text('No attendance data'),
                          // pw.Text('N/A'),
                          pw.Text('N/A'),
                        ],
                      );
                    }
                    // If attendance data is available
                    return pw.TableRow(
                      children: [
                        pw.Text('${attendance['date'] ?? 'N/A'} ${attendance['time'] ?? 'N/A'}'),
                        pw.Text(employeeName),
                        // pw.Text(attendance['time'] ?? 'N/A'),
                        pw.Text(attendance['description'] ?? 'N/A'),
                        pw.Text(attendance['status'] ?? 'N/A'),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }


}
