import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class EmployeeProvider with ChangeNotifier {
  final DatabaseReference _database = FirebaseDatabase.instance.ref('employees');
  Map<String, Map<String, String>> _employees = {};
  final DatabaseReference _attendanceRef = FirebaseDatabase.instance.ref('attendance');

  Map<String, Map<String, String>> get employees => _employees;

  EmployeeProvider() {
    _fetchEmployees();
  }

  void _fetchEmployees() {
    _database.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        _employees = data.map((key, value) =>
            MapEntry(key, Map<String, String>.from(value as Map)));
      } else if (data is List) {
        // If the data is a List, convert it to a Map
        _employees = {
          for (int i = 0; i < data.length; i++)
            if (data[i] != null)
              i.toString(): Map<String, String>.from(data[i] as Map),
        };
      } else {
        _employees = {};
      }
      notifyListeners();
    });
  }


  Future<void> addOrUpdateEmployee(String id, Map<String, String> employeeData) async {
    await _database.child(id).set(employeeData);
  }

  Future<void> deleteEmployee(String id) async {
    await _database.child(id).remove();
  }



  // Method to save attendance to Firebase
  Future<void> markAttendance(
      BuildContext context,
      String employeeId,
      String status,
      String description,
      DateTime date) async {
    final dateString = date.toIso8601String().split('T').first; // Format the date (e.g., "2025-01-08")
    final timeString = date.toIso8601String().split('T').last.split('.').first; // Extract the time (e.g., "14:30:00")


    // Check if attendance for this day already exists
    final snapshot = await _attendanceRef.child(employeeId).child(dateString).get();
    if (snapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Attendance already marked for today.")),
      );
      print("Attendance already marked for today.");
      return; // Do not save if attendance already exists for today
    }

    // Save attendance data in Firebase if not already marked
    try {
      await _attendanceRef.child(employeeId).child(dateString).set({
        'status': status,
        'description': description,
        'date':dateString,
        'time': timeString
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Attendance already marked for today.")),
      );
      print("Attendance marked for today.");
      notifyListeners(); // Notify listeners after data is saved
    } catch (e) {
      print("Error saving attendance: $e");
    }
  }

  // Fetch attendance data for an employee
  Future<Map<String, dynamic>> getAttendance(String employeeId, DateTime date) async {
    final dateString = date.toIso8601String().split('T').first;
    final snapshot = await _attendanceRef.child(employeeId).child(dateString).get();

    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    } else {
      return {};
    }
  }


}
