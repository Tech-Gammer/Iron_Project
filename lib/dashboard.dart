// import 'package:flutter/material.dart';
//
// class Dashboard extends StatefulWidget {
//   const Dashboard({super.key});
//
//   @override
//   State<Dashboard> createState() => _DashboardState();
// }
//
// class _DashboardState extends State<Dashboard> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Dashboard'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.notifications),
//             onPressed: () {
//               // Handle notifications
//             },
//           ),
//           IconButton(
//             icon: Icon(Icons.search),
//             onPressed: () {
//               // Handle search
//             },
//           ),
//         ],
//       ),
//       drawer: _buildDrawer(context),
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           if (constraints.maxWidth > 600) {
//             // Web view
//             return Row(
//               children: [
//                 _buildSidebar(),
//                 Expanded(child: _buildContent()),
//               ],
//             );
//           } else {
//             // Mobile view
//             return _buildContent();
//           }
//         },
//       ),
//       bottomNavigationBar: MediaQuery.of(context).size.width <= 600
//           ? BottomNavigationBar(
//         items: [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.add),
//             label: 'Add Entry',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: 'Settings',
//           ),
//         ],
//         onTap: (index) {
//           // Handle navigation
//         },
//       )
//           : null,
//     );
//   }
//
//   Widget _buildDrawer(BuildContext context) {
//     return Drawer(
//       child: ListView(
//         children: [
//           DrawerHeader(
//             decoration: BoxDecoration(color: Colors.blue),
//             child: Text(
//               'Welcome, User!',
//               style: TextStyle(color: Colors.white, fontSize: 18),
//             ),
//           ),
//           ListTile(
//             leading: Icon(Icons.home),
//             title: Text('Home'),
//             onTap: () {
//               Navigator.pop(context);
//             },
//           ),
//           ListTile(
//             leading: Icon(Icons.account_balance_wallet),
//             title: Text('Transactions'),
//             onTap: () {
//               Navigator.pop(context);
//             },
//           ),
//           ListTile(
//             leading: Icon(Icons.settings),
//             title: Text('Settings'),
//             onTap: () {
//               Navigator.pop(context);
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSidebar() {
//     return Container(
//       width: 200,
//       color: Colors.blue[50],
//       child: ListView(
//         children: [
//           ListTile(
//             leading: Icon(Icons.home),
//             title: Text('Home'),
//             onTap: () {
//               // Navigate to Home
//             },
//           ),
//           ListTile(
//             leading: Icon(Icons.account_balance_wallet),
//             title: Text('Transactions'),
//             onTap: () {
//               // Navigate to Transactions
//             },
//           ),
//           ListTile(
//             leading: Icon(Icons.settings),
//             title: Text('Settings'),
//             onTap: () {
//               // Navigate to Settings
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildContent() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: GridView.count(
//         crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 16,
//         children: [
//           _buildDashboardCard(Icons.add, 'Add Entry', Colors.blue),
//           _buildDashboardCard(Icons.list, 'View Transactions', Colors.green),
//           _buildDashboardCard(Icons.report, 'Reports', Colors.red),
//           _buildDashboardCard(Icons.settings, 'Settings', Colors.orange),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDashboardCard(IconData icon, String title, Color color) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: InkWell(
//         onTap: () {
//           // Handle card tap
//         },
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircleAvatar(
//               backgroundColor: color.withOpacity(0.2),
//               child: Icon(icon, color: color),
//             ),
//             SizedBox(height: 10),
//             Text(
//               title,
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Customer/customerlist.dart';
import 'DailyExpensesPages/viewexpensepage.dart';
import 'Filled/filledlist.dart';
import 'Reports/bypaymentType.dart';
import 'Reports/customerlistforreport.dart';
import 'Invoice/invoiceslist.dart';
import 'Provider/lanprovider.dart';
import 'Reports/ledgerselcttion.dart';
import 'Reports/reportselecttionpage.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.isEnglish ? 'Dashboard' : 'ڈیش بورڈ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: languageProvider.toggleLanguage,
            tooltip: languageProvider.isEnglish ? 'Switch to Urdu' : 'انگریزی میں تبدیل کریں',
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Handle notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Handle search
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, languageProvider),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            // Web view
            return Row(
              children: [
                _buildSidebar(languageProvider),
                Expanded(child: _buildContent(context,languageProvider)),
              ],
            );
          } else {
            // Mobile view
            return _buildContent(context,languageProvider);
          }
        },
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width <= 600
          ? BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: languageProvider.isEnglish ? 'Home' : 'ہوم',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.add),
            label: languageProvider.isEnglish ? 'Add Entry' : 'نیا اندراج',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: languageProvider.isEnglish ? 'Settings' : 'ترتیبات',
          ),
        ],
        onTap: (index) {
          // Handle navigation
        },
      )
          : null,
    );
  }

  Widget _buildDrawer(BuildContext context, LanguageProvider languageProvider) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: Text(
              languageProvider.isEnglish ? 'Welcome, User!' : 'خوش آمدید، صارف!',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(languageProvider.isEnglish ? 'Home' : 'ہوم'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: Text(languageProvider.isEnglish ? 'Transactions' : 'لین دین'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(languageProvider.isEnglish ? 'Settings' : 'ترتیبات'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(LanguageProvider languageProvider) {
    return Container(
      width: 200,
      color: Colors.blue[50],
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(languageProvider.isEnglish ? 'Home' : 'ہوم'),
            onTap: () {
              // Navigate to Home
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: Text(languageProvider.isEnglish ? 'Transactions' : 'لین دین'),
            onTap: () {
              // Navigate to Transactions
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(languageProvider.isEnglish ? 'Settings' : 'ترتیبات'),
            onTap: () {
              // Navigate to Settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, LanguageProvider languageProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildDashboardCard(
              Icons.add, languageProvider.isEnglish ? 'Invoice' : 'بل اندراج', Colors.blue,
              (){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>InvoiceListPage()));
              }
          ),
          _buildDashboardCard(
              Icons.add, languageProvider.isEnglish ? 'Filled' : 'فلڈ اندراج', Colors.blue,
                  (){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>filledListpage()));
              }
          ),
          _buildDashboardCard(
              Icons.add, languageProvider.isEnglish ? 'Expenses' : 'اخراجات', Colors.blue,
                  (){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>ViewExpensesPage()));
              }
          ),
          _buildDashboardCard(
              Icons.list, languageProvider.isEnglish ? 'Customers' : 'کسٹمرز', Colors.green,(){
            Navigator.push(context, MaterialPageRoute(builder: (context)=>CustomerList()));

          }),
          _buildDashboardCard(
              Icons.list, languageProvider.isEnglish ? 'View Ledger' : 'کھاتہ دیکھیں', Colors.green,(){
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ledgerselection(),
              ),
            );
          }),
          _buildDashboardCard(
              Icons.report, languageProvider.isEnglish ? 'Reports' : 'رپورٹس', Colors.red,(){
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportsPage(),
              ),
            );
          }),
          _buildDashboardCard(
              Icons.settings, languageProvider.isEnglish ? 'Settings' : 'ترتیبات', Colors.orange,(){}),
        ],
      ),
    );
  }


  Widget _buildDashboardCard(IconData icon, String title, Color color,VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
//
// class Dashboard extends StatefulWidget {
//   const Dashboard({super.key});
//
//   @override
//   State<Dashboard> createState() => _DashboardState();
// }
//
// class _DashboardState extends State<Dashboard> {
//   bool _isEnglish = true; // Language state: true for English, false for Urdu
//
//   void _toggleLanguage() {
//     setState(() {
//       _isEnglish = !_isEnglish;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_isEnglish ? 'Dashboard' : 'ڈیش بورڈ'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.language),
//             onPressed: _toggleLanguage,
//             tooltip: _isEnglish ? 'Switch to Urdu' : 'انگریزی میں تبدیل کریں',
//           ),
//           IconButton(
//             icon: Icon(Icons.notifications),
//             onPressed: () {
//               // Handle notifications
//             },
//           ),
//           IconButton(
//             icon: Icon(Icons.search),
//             onPressed: () {
//               // Handle search
//             },
//           ),
//         ],
//       ),
//       drawer: _buildDrawer(context),
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           if (constraints.maxWidth > 600) {
//             // Web view
//             return Row(
//               children: [
//                 _buildSidebar(),
//                 Expanded(child: _buildContent()),
//               ],
//             );
//           } else {
//             // Mobile view
//             return _buildContent();
//           }
//         },
//       ),
//       bottomNavigationBar: MediaQuery.of(context).size.width <= 600
//           ? BottomNavigationBar(
//         items: [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: _isEnglish ? 'Home' : 'ہوم',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.add),
//             label: _isEnglish ? 'Add Entry' : 'نیا اندراج',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: _isEnglish ? 'Settings' : 'ترتیبات',
//           ),
//         ],
//         onTap: (index) {
//           // Handle navigation
//         },
//       )
//           : null,
//     );
//   }
//
//   Widget _buildDrawer(BuildContext context) {
//     return Drawer(
//       child: ListView(
//         children: [
//           DrawerHeader(
//             decoration: BoxDecoration(color: Colors.blue),
//             child: Text(
//               _isEnglish ? 'Welcome, User!' : 'خوش آمدید، صارف!',
//               style: TextStyle(color: Colors.white, fontSize: 18),
//             ),
//           ),
//           ListTile(
//             leading: Icon(Icons.home),
//             title: Text(_isEnglish ? 'Home' : 'ہوم'),
//             onTap: () {
//               Navigator.pop(context);
//             },
//           ),
//           ListTile(
//             leading: Icon(Icons.account_balance_wallet),
//             title: Text(_isEnglish ? 'Transactions' : 'لین دین'),
//             onTap: () {
//               Navigator.pop(context);
//             },
//           ),
//           ListTile(
//             leading: Icon(Icons.settings),
//             title: Text(_isEnglish ? 'Settings' : 'ترتیبات'),
//             onTap: () {
//               Navigator.pop(context);
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSidebar() {
//     return Container(
//       width: 200,
//       color: Colors.blue[50],
//       child: ListView(
//         children: [
//           ListTile(
//             leading: Icon(Icons.home),
//             title: Text(_isEnglish ? 'Home' : 'ہوم'),
//             onTap: () {
//               // Navigate to Home
//             },
//           ),
//           ListTile(
//             leading: Icon(Icons.account_balance_wallet),
//             title: Text(_isEnglish ? 'Transactions' : 'لین دین'),
//             onTap: () {
//               // Navigate to Transactions
//             },
//           ),
//           ListTile(
//             leading: Icon(Icons.settings),
//             title: Text(_isEnglish ? 'Settings' : 'ترتیبات'),
//             onTap: () {
//               // Navigate to Settings
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildContent() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: GridView.count(
//         crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 16,
//         children: [
//           _buildDashboardCard(Icons.add, _isEnglish ? 'Add Entry' : 'نیا اندراج', Colors.blue),
//           _buildDashboardCard(Icons.list, _isEnglish ? 'View Transactions' : 'لین دین دیکھیں', Colors.green),
//           _buildDashboardCard(Icons.report, _isEnglish ? 'Reports' : 'رپورٹس', Colors.red),
//           _buildDashboardCard(Icons.settings, _isEnglish ? 'Settings' : 'ترتیبات', Colors.orange),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDashboardCard(IconData icon, String title, Color color) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: InkWell(
//         onTap: () {
//           // Handle card tap
//         },
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircleAvatar(
//               backgroundColor: color.withOpacity(0.2),
//               child: Icon(icon, color: color),
//             ),
//             SizedBox(height: 10),
//             Text(
//               title,
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
