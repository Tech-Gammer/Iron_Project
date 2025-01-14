import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../Provider/employeeprovider.dart';
import '../Provider/lanprovider.dart';

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
    final languageProvider = Provider.of<LanguageProvider>(context);

    // Filter employees by name
    final filteredEmployees = employees.keys.where((employeeId) {
      final employeeName = employees[employeeId]!['name']!.toLowerCase();
      return employeeName.contains(_searchName.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          // 'Attendance Report',
            languageProvider.isEnglish ? 'Attendance Report' : 'حاضری کی رپورٹ',
          style: const TextStyle(color: Colors.white),),
        backgroundColor: Colors.teal,
        centerTitle: true,
                actions: [
          IconButton(
            icon: const Icon(Icons.print,color: Colors.white,),
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
                    decoration:  InputDecoration(
                      labelText: languageProvider.isEnglish ? 'Search by Name' : 'نام سے تلاش کریں۔',
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
                      // lastDate: DateTime.now(),
                      lastDate: DateTime(20001)
                    );
                    if (pickedDateRange != null) {
                      setState(() {
                        _dateRange = pickedDateRange;
                      });
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label:  Text(
    // 'Select Date Range'
    languageProvider.isEnglish ? 'Select Date Range' : 'تاریخ کی حد منتخب کریں۔',
    ),
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

                return FutureBuilder<Map<String, Map<String, dynamic>>>(
                  future: _dateRange != null
                      ? employeeProvider.getAttendanceForDateRange(employeeId, _dateRange!)
                      : Future.value({}), // Empty map if no range is selected
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasData) {
                      final attendanceData = snapshot.data!;
                      if (attendanceData.isEmpty) {
                        return ListTile(
                          title: Text(employees[employeeId]!['name']!),
                          subtitle:  Text(
                          // 'No attendance marked for the selected range'
                          languageProvider.isEnglish ? 'No attendance marked for the selected range' : 'منتخب کردہ رینج کے لیے کوئی حاضری نشان زد نہیں ہے۔',
                          )
                        );
                      }

                      // Display attendance for each dates
                      return ExpansionTile(
                        title: Text(employees[employeeId]!['name']!),
                        children: attendanceData.entries.map((entry) {
                          final date = entry.key;
                          final attendance = entry.value;

                          return ListTile(
                            title: Text('Date: $date'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Status: ${attendance['status'] ?? 'N/A'}'),
                                Text('Description: ${attendance['description'] ?? 'N/A'}'),
                                Text('Time: ${attendance['time'] ?? 'N/A'}'),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    } else {
                      return ListTile(
                        title: Text(employees[employeeId]!['name']!),
                        subtitle:  Text(
                            // 'Error fetching attendance'
                          languageProvider.isEnglish ? 'Error fetching attendance' : 'حاضری حاصل کرنے میں خرابی۔',

                        ),
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

    final employeeAttendances = await Future.wait(
      filteredEmployees.map((employeeId) async {
        if (_dateRange != null) {
          return MapEntry(
            employeeId,
            await employeeProvider.getAttendanceForDateRange(employeeId, _dateRange!),
          );
        }
        return MapEntry(employeeId, {});
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
              pw.Table(
                border: pw.TableBorder.all(width: 1, color: PdfColors.black),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Employee Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  ...employeeAttendances.expand((entry) {
                    final employeeId = entry.key;
                    final attendanceData = entry.value;
                    final employeeName = employees[employeeId]!['name']!;

                    return attendanceData.entries.map((dateEntry) {
                      final date = dateEntry.key;
                      final attendance = dateEntry.value;

                      return pw.TableRow(
                        children: [
                          pw.Text(date),
                          // pw.Text('${attendance['date'] ?? 'N/A'} ${attendance['time'] ?? 'N/A'}'),
                          pw.Text(employeeName),
                          pw.Text(attendance['status'] ?? 'N/A'),
                          pw.Text(attendance['description'] ?? 'N/A'),
                        ],
                      );
                    });
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
