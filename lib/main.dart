import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Auth/login.dart';
import 'Auth/register.dart';
import 'Provider/customerprovider.dart';
import 'Provider/employeeprovider.dart';
import 'Provider/filled provider.dart';
import 'Provider/filledreportprovider.dart';
import 'Provider/invoice provider.dart';
import 'Provider/lanprovider.dart';
import 'dashboard.dart';
import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Initialize with the generated options
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => FilledProvider()),
        ChangeNotifierProvider(create: (_) => FilledCustomerReportProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()), // Add CustomerProvider
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home:  LoginPage(),
          theme: ThemeData(
            fontFamily: languageProvider.isEnglish ? 'Roboto' : 'JameelNoori',
          ),
        );
      },
    );
  }
}