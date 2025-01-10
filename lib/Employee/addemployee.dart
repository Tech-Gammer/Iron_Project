import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Provider/employeeprovider.dart';

class AddEmployeePage extends StatefulWidget {
  final String? employeeId; // Null for adding, non-null for editing

  AddEmployeePage({this.employeeId});

  @override
  _AddEmployeePageState createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends State<AddEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.employeeId != null) {
      _loadEmployeeData();
    }
  }

  void _loadEmployeeData() {
    final employee = Provider.of<EmployeeProvider>(context, listen: false)
        .employees[widget.employeeId!];
    if (employee != null) {
      _nameController.text = employee['name'] ?? '';
      _addressController.text = employee['address'] ?? '';
      _phoneController.text = employee['phone'] ?? '';
    }
  }

  void _saveEmployee() {
    if (_formKey.currentState!.validate()) {
      final employeeData = {
        'name': _nameController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
      };

      final provider = Provider.of<EmployeeProvider>(context, listen: false);
      if (widget.employeeId == null) {
        // Add new employee
        String newId = provider.employees.length.toString();
        provider.addOrUpdateEmployee(newId, employeeData);
      } else {
        // Update existing employee
        provider.addOrUpdateEmployee(widget.employeeId!, employeeData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Employee saved successfully!')),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employeeId == null ? 'Add Employee' : 'Edit Employee'),
        backgroundColor: Colors.teal.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Colors.teal.shade700),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.teal.shade700),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  labelStyle: TextStyle(color: Colors.teal.shade700),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.teal.shade700),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(color: Colors.teal.shade700),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.teal.shade700),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveEmployee,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  widget.employeeId == null ? 'Add Employee' : 'Save Changes',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
