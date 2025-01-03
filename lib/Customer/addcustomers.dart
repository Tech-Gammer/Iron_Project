import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Provider/customerprovider.dart';

class AddCustomer extends StatefulWidget {
  @override
  State<AddCustomer> createState() => _AddCustomerState();
}

class _AddCustomerState extends State<AddCustomer> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _address = '';
  String _phone = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Customer')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                onSaved: (value) => _name = value!,
                validator: (value) => value!.isEmpty ? 'Please enter the customer\'s name' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                onSaved: (value) => _address = value!,
                validator: (value) => value!.isEmpty ? 'Please enter the customer\'s address' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                onSaved: (value) => _phone = value!,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter the customer\'s phone number';
                  if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value)) return 'Please enter a valid phone number';
                  return null;
                },
              ),
              SizedBox(height: 20),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () => _saveCustomer(context),
                  child: Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveCustomer(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      Provider.of<CustomerProvider>(context, listen: false).addCustomer(_name, _address, _phone);
      Navigator.pop(context);
    }
  }
}
