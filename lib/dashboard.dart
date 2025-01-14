import 'package:flutter/material.dart';
import 'package:iron_project_new/userspage.dart';
import 'package:provider/provider.dart';
import 'Customer/customerlist.dart';
import 'DailyExpensesPages/viewexpensepage.dart';
import 'Employee/addemployee.dart';
import 'Employee/employeelist.dart';
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
        title: Text(
          languageProvider.isEnglish ? 'Dashboard' : 'ڈیش بورڈ',
        ),
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
                _buildSidebar(context, languageProvider),
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
          switch (index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Dashboard()),
              );
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ledgerselection()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UsersPage()),
              );
              break;
          }
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
              Navigator.push(context, MaterialPageRoute(builder: (context)=>const Dashboard()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: Text(languageProvider.isEnglish ? 'Transactions' : 'لین دین'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ledgerselection(),
                ),
              );              },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(languageProvider.isEnglish ? 'Settings' : 'ترتیبات'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UsersPage(),
                ),
              );
              },
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, LanguageProvider languageProvider) {
    return Container(
      width: 200,
      color: Colors.blue[50],
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(languageProvider.isEnglish ? 'Home' : 'ہوم'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Dashboard()),
              );
              },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: Text(languageProvider.isEnglish ? 'Transactions' : 'لین دین'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ledgerselection(),
                ),
              );            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(languageProvider.isEnglish ? 'Settings' : 'ترتیبات'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UsersPage(),
                ),
              );
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
              Icons.add, languageProvider.isEnglish ? 'Employee' : 'ورکر', Colors.blue,
                  (){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>EmployeeListPage()));
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
                builder: (context) => const ledgerselection(),
              ),
            );
          }),
          _buildDashboardCard(
              Icons.report, languageProvider.isEnglish ? 'Reports' : 'رپورٹس', Colors.red,(){
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReportsPage(),
              ),
            );
          }),
          _buildDashboardCard(
              Icons.settings, languageProvider.isEnglish ? 'Settings' : 'ترتیبات', Colors.orange,(){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>UsersPage()));
          }),
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

