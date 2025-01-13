import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

import 'Provider/lanprovider.dart';

class UsersPage extends StatefulWidget {
  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref("users");
  List<Map<String, dynamic>> _usersList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() async {
    try {
      final DataSnapshot snapshot = await _databaseRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _usersList = data.entries.map((e) {
            return {
              // "id": e.key,
              "name": e.value["name"],
              "email": e.value["email"],
              "password": e.value["password"],
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching users: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.isEnglish ? 'Users Profile:' : 'صارفین کا پروفائل:',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.teal.shade800,
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _usersList.isEmpty
          ? const Center(child: Text("No users found"))
          : ListView.builder(
        itemCount: _usersList.length,
        itemBuilder: (context, index) {
          final user = _usersList[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text(user["name"]),
              subtitle: Text("Email: ${user["email"]}\nPassword: ${user["password"]}"),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
