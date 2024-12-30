import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../dashboard.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  String _email = '';
  String _password = '';

  void _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        await _auth.signInWithEmailAndPassword(
          email: _email,
          password: _password,
        );
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Login successful!'),
        ));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Dashboard()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Login failed: $e'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login'),
      automaticallyImplyLeading: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                border: Border.all(
                  color: Colors.blue, // Set the color of the border
                  width: 2.0,        // Set the width of the border
                ),
              ),
              width: constraints.maxWidth > 600 ? 400 : double.infinity,
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 20,),
                    CircleAvatar(
                      radius: 70,
                      backgroundImage: AssetImage('images/logo.png'), // Correct usage
                    ),
                    SizedBox(height: 15,),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Email',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: Colors.grey)
                          )
                      ),
                      onSaved: (value) => _email = value!,
                      validator: (value) => value!.isEmpty || !value.contains('@') ? 'Enter a valid email' : null,
                    ),SizedBox(height: 8,),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Password',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: Colors.grey)
                          )
                      ),
                      obscureText: true,
                      onSaved: (value) => _password = value!,
                      validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
                    ),
                    SizedBox(height: 20),
                    Container(
                        width: 200,
                        decoration: BoxDecoration(
                          color: Colors.lightBlueAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextButton(
                            onPressed: (){
                              _login();
                            },
                            child: Text("Login",style: TextStyle(color: Colors.black,fontSize: 20,fontWeight: FontWeight.bold),)
                        )
                    ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     Text("If you are new click on"),
                    //     TextButton(onPressed: (){
                    //       Navigator.push(context, MaterialPageRoute(builder: (context)=>RegisterPage()));
                    //     }, child: Text('Register'))
                    //   ],
                    // )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

