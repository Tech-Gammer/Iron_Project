// import 'dart:ui';
//
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:printing/printing.dart';
// import 'package:provider/provider.dart';
// import 'package:sabir_tailors/Models/Admin model.dart';
// import 'package:sabir_tailors/providers/MeasurementProvider.dart';
// import 'package:sabir_tailors/providers/OrderProvider.dart';
// import 'Models/OrderModel.dart';
// import 'existingclients/ShowClientInfoInCurrentMeasurement/CoatMeasurementShowPage.dart';
// import 'existingclients/ShowClientInfoInCurrentMeasurement/PantMeasurementShowPage.dart';
// import 'existingclients/ShowClientInfoInCurrentMeasurement/ShalwarQameezMeasurementShowPage.dart';
// import 'existingclients/ShowClientInfoInCurrentMeasurement/SherwaniMeasurementShowPage.dart';
// import 'existingclients/ShowClientInfoInCurrentMeasurement/WaskitMeasurementShowPage.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:pdf/pdf.dart';
// import 'dart:typed_data';
// import 'package:syncfusion_flutter_pdf/pdf.dart';
// import 'dart:html' as html;
//
// class OrdersPage extends StatefulWidget {
//   @override
//   _OrdersPageState createState() => _OrdersPageState();
// }
//
// class _OrdersPageState extends State<OrdersPage> {
//   EmployeeModel? selectedEmployee;
//   TextEditingController searchController = TextEditingController();
//   String searchQuery = '';
//   Map? measurement;
//   bool isLoading = false;
//   Uint8List? byteList;
//   Uint8List? SbyteList;
//
//   @override
//   void initState() {
//     super.initState();
//     final orderProvider = Provider.of<OrderProvider>(context, listen: false);
//     orderProvider.fetchEmployeesforKatai();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final orderProvider = Provider.of<OrderProvider>(context);
//     List<EmployeeModel> employeesforKatai = orderProvider.employees;
//
//     return Scaffold(
//       appBar: AppBar(
//         title:
//         Text('Fresh Orders', style: TextStyle(fontWeight: FontWeight.bold)),
//         centerTitle: true,
//         backgroundColor: Colors.lightBlueAccent,
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: TextField(
//               controller: searchController,
//               decoration: InputDecoration(
//                 labelText: 'Search by Serial Number or Mobile No or Name',
//                 border: OutlineInputBorder(),
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   searchQuery = value.toLowerCase();
//                 });
//               },
//             ),
//           ),
//           Expanded(
//             child: FutureBuilder(
//               future: orderProvider.fetchOrders(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.active) {
//                   return Center(child: CircularProgressIndicator());
//                 }
//                 if (orderProvider.orders.isEmpty) {
//                   return Center(
//                       child: Text('No orders found.',
//                           style: TextStyle(fontSize: 18)));
//                 }
//
//                 // Filter orders based on search query
//                 List<Order> filteredOrders =
//                 orderProvider.orders.where((order) {
//                   return order.serial.toLowerCase().contains(searchQuery) ||
//                       order.custPhone.toLowerCase().contains(searchQuery) ||
//                       order.invoiceNumber.toString().contains(searchQuery) ||
//                       order.custName.toLowerCase().contains(searchQuery);
//                 }).toList();
//
//                 if (filteredOrders.isEmpty) {
//                   return Center(
//                       child: Text('No orders found for this serial.',
//                           style: TextStyle(fontSize: 18)));
//                 }
//
//                 return ListView.builder(
//                   itemCount: filteredOrders.length,
//                   itemBuilder: (context, index) {
//                     final order = filteredOrders[index];
//                     return _buildOrderCard(order, employeesforKatai);
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildOrderCard(Order order, List<EmployeeModel> employeesforKatai) {
//     return Card(
//       elevation: 4,
//       margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               order.measurementType,
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.lightBlueAccent,
//               ),
//             ),
//             SizedBox(height: 10),
//             Text('Serial: ${order.serial}', style: TextStyle(fontSize: 16)),
//             Text('Invoice Number: ${order.invoiceNumber}',
//                 style: TextStyle(fontSize: 16)),
//             Text('customer Name: ${order.custName}',
//                 style: TextStyle(fontSize: 16)),
//             Text('customer Mobile No: ${order.custPhone}',
//                 style: TextStyle(fontSize: 16)),
//             Text('Suits Count: ${order.suitsCount}',
//                 style: TextStyle(fontSize: 16)),
//             Text('Total Payment: ${order.paymentAmount.toStringAsFixed(2)}',
//                 style: TextStyle(fontSize: 16)),
//             Text('Advance Payment: ${order.advanceAmount.toStringAsFixed(2)}',
//                 style: TextStyle(fontSize: 16)),
//             Text('Remaining Payment: ${order.remainingPayment}',
//                 style: TextStyle(fontSize: 16)),
//             Text(
//                 'Order Date: ${order.orderDate.toLocal().toString().split(' ')[0]}',
//                 style: TextStyle(fontSize: 16)),
//             Text(
//                 'Completion Date: ${order.completionDate.toLocal().toString().split(' ')[0]}',
//                 style: TextStyle(fontSize: 16)),
//             SizedBox(height: 10),
//             Row(
//               children: [
//                 ElevatedButton(
//                   onPressed: () {
//                     _showEmployeeSelectionDialog(
//                         employeesforKatai,
//                         order.id.toString(),
//                         order.measurementType,
//                         order.serial);
//                   },
//                   child: Text('send to katai',
//                       style: TextStyle(color: Colors.white)),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.lightBlueAccent,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//                 SizedBox(
//                   width: 10,
//                 ),
//                 ElevatedButton(
//                   onPressed: () async {
//                     final measurementProvider =
//                     Provider.of<Measurementprovider>(context,
//                         listen: false);
//                     measurementProvider.FetchMeausurements(
//                         order.measurementType);
//                     if (order.measurementType == 'ShalwarQameez') {
//                       await measurementProvider.FetchMeausurements(
//                           'ShalwarQameez');
//                       await Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => ShalwarQameezMeasurementPage(
//                                 serialNo: order.serial.toString())),
//                       );
//                     } else if (order.measurementType == 'Coat') {
//                       await measurementProvider.FetchMeausurements('Coat');
//                       await Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => CoatMeasurementPage(
//                                 serialNo: order.serial.toString())),
//                       );
//                     } else if (order.measurementType == 'Pants') {
//                       await measurementProvider.FetchMeausurements('Pants');
//                       await Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => PantMeasurementShowPage(
//                                 serialNo: order.serial.toString())),
//                       );
//                     } else if (order.measurementType == 'Sherwani') {
//                       await measurementProvider.FetchMeausurements('Sherwani');
//                       await Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => SherwaniMeasurementShowPage(
//                                 serialNo: order.serial.toString())),
//                       );
//                     } else if (order.measurementType == 'Waskit') {
//                       await measurementProvider.FetchMeausurements('Waskit');
//                       await Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => WaskitMeasurementPage(
//                                 serialNo: order.serial.toString())),
//                       );
//                     }
//                   },
//                   child: Text('Show Measurements',
//                       style: TextStyle(color: Colors.white)),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.lightBlueAccent,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showEmployeeSelectionDialog(List<EmployeeModel> employees,
//       String orderId, String MeasurementType, String SerialNo) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return StatefulBuilder(
//           builder: (BuildContext context, StateSetter setState) {
//             return AlertDialog(
//               title: Text("Select Person for Katai"),
//               content: DropdownButton<EmployeeModel>(
//                 isExpanded: true,
//                 value: selectedEmployee != null &&
//                     employees.contains(selectedEmployee)
//                     ? selectedEmployee
//                     : null,
//                 hint: Text("Select Employee"),
//                 onChanged: (EmployeeModel? newValue) {
//                   setState(() {
//                     selectedEmployee = newValue;
//                   });
//                 },
//                 items: employees.map<DropdownMenuItem<EmployeeModel>>(
//                         (EmployeeModel employee) {
//                       return DropdownMenuItem<EmployeeModel>(
//                         value: employee,
//                         child: Text(employee
//                             .name), // assuming EmployeeModel has a 'name' property
//                       );
//                     }).toList(),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.of(context).pop(); // Dismiss the dialog
//                   },
//                   child: Text("Cancel"),
//                 ),
//                 TextButton(
//                   onPressed: !isLoading
//                       ? () async {
//                     if (selectedEmployee != null) {
//                       setState(() {
//                         isLoading = true;
//                       });
//                       String selectedEmployeeId =
//                           selectedEmployee!.employeeId;
//                       print("Selected Employee ID: $selectedEmployeeId");
//                       final orderProvider = Provider.of<OrderProvider>(
//                           context,
//                           listen: false);
//                       await _generateAndDownloadPDF(
//                           orderId,
//                           MeasurementType,
//                           SerialNo,
//                           selectedEmployee!.name,
//                           selectedEmployee!
//                               .employeeId); // Generate and download PDF after updating order status
//                       await orderProvider.updateOrderStatus(orderId,
//                           selectedEmployeeId, selectedEmployee!.name);
//                       setState(() {
//                         isLoading = false;
//                       });
//                       Navigator.of(context).pop();
//                     } else {
//                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                           content: Text('select employee first')));
//                       setState(() {
//                         isLoading = false;
//                       });
//                     }
//                     // Dismiss the dialog after confirming
//                   }
//                       : () {},
//                   child: !isLoading ? Text("OK") : CircularProgressIndicator(),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//
//   Future<Uint8List> _generateTextImage(String text) async {
//     final recorder = PictureRecorder();
//     final canvas = Canvas(recorder);
//     final paint = Paint()..color = Colors.black;
//
//     // Split the text into lines based on the newline character
//     final lines = text.split('\n');
//
//     // Determine text direction based on whether the text is in Urdu or English
//     final bool isUrduText = isUrdu(text); // Implement or use your existing isUrdu function
//     final textDirection = isUrduText ? TextDirection.rtl : TextDirection.ltr;
//
//     double lineHeight = 24.0; // Space between lines
//     double yOffset = 0.0; // Initial yOffset for the first line
//     double maxWidth = 200; // Set a max width for text wrapping
//
//     // Measure the total height of the text block
//     double totalTextHeight = lines.length * lineHeight;
//
//     // Measure the width of the longest line
//     double maxTextWidth = 0.0;
//     for (var line in lines) {
//       final textPainter = TextPainter(
//         text: TextSpan(text: line, style: TextStyle(color: Colors.black, fontSize: 22, fontFamily: 'JameelNoori', fontWeight: FontWeight.bold)),
//         textDirection: textDirection,
//       );
//       textPainter.layout(maxWidth: maxWidth);
//       maxTextWidth = maxTextWidth > textPainter.width ? maxTextWidth : textPainter.width;
//     }
//
//     // Calculate starting offsets to center the text block
//     final canvasWidth = 200; // Set canvas width
//     final canvasHeight = (lineHeight * lines.length).toInt(); // Set canvas height based on text height
//     final xCenterOffset = (canvasWidth - maxTextWidth) / 2;
//     final yCenterOffset = (canvasHeight - totalTextHeight) / 2;
//
//     yOffset = yCenterOffset;
//
//     // Paint each line on the canvas
//     for (var line in lines) {
//       final textPainter = TextPainter(
//         text: TextSpan(text: line, style: TextStyle(color: Colors.black, fontSize: 22, fontFamily: 'JameelNoori', fontWeight: FontWeight.bold)),
//         textDirection: textDirection,
//       );
//       textPainter.layout(maxWidth: maxWidth);
//
//       final offset = Offset(
//         xCenterOffset,
//         yOffset,
//       );
//
//       textPainter.paint(canvas, offset);
//
//       yOffset += lineHeight;
//     }
//
//     final picture = recorder.endRecording();
//     final image = await picture.toImage(canvasWidth, canvasHeight); // Adjust canvas dimensions
//     final byteData = await image.toByteData(format: ImageByteFormat.png);
//     return byteData!.buffer.asUint8List();
//   }
//
//
//   bool isUrdu(String text) {
//     // Regular expression to check for Arabic characters (which includes Urdu)
//     final urduRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
//     return urduRegex.hasMatch(text);
//   }
//
//   Future<void> _generateAndDownloadPDF(
//       String orderId,
//       String MeasureMentType,
//       String SerialNo,
//       String EmployeeName,
//       String EmployeeId,
//       ) async {
//     final orderProvider = Provider.of<OrderProvider>(context, listen: false);
//     final order = orderProvider.orders
//         .firstWhere((order) => order.id.toString() == orderId);
//     final measurementProvider =
//     Provider.of<Measurementprovider>(context, listen: false);
//     await measurementProvider.FetchMeausurements(MeasureMentType.toString());
//
//     // Create PDF document
//     final logoBytes = await _getCompanyLogoBytes();
//     final urduFont = pw.Font.ttf(
//         await rootBundle.load("assets/fonts/JameelNooriNastaleeq.ttf"));
//     final lorafont = pw.Font.ttf(
//         await rootBundle.load("assets/fonts/Lora-VariableFont_wght.ttf"));
//     final pdf = pw.Document();
//     dynamic measurement;
//
//     pw.Widget _buildHeader() {
//       return pw.Column(
//         children: [
//           pw.Center(
//             child: pw.Image(
//               pw.MemoryImage(logoBytes),
//               width: 100,
//               height: 100,
//             ), // Add your logo here
//           ),
//           pw.Center(
//             child: pw.Text('Sabir Tailor',
//                 style:
//                 pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
//           ),
//           pw.Center(
//             child: pw.Text('Suits for Katai',
//                 style:
//                 pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
//           ),
//           pw.Divider(thickness: 2),
//
//         ],
//       );
//     }
//
//
//
//     // Function to build measurement row
//     pw.Widget _buildMeasurementRow(String title, dynamic value) {
//       bool _isUrdu = isUrdu(value.toString()); // Check if the text is in Urdu
//
//       return pw.Padding(
//         padding: pw.EdgeInsets.symmetric(horizontal: 12),
//         child: pw.Row(
//           mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//           children: [
//             pw.Text(
//               title,
//               style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
//             ),
//             pw.Align(
//               alignment: _isUrdu
//                   ? pw.Alignment.centerRight
//                   : pw.Alignment.centerLeft, // Align text based on language
//               child:pw.Text(
//                 value?.toString() ?? "N/A",
//                 style: pw.TextStyle(
//                   fontSize: 22,
//                   fontWeight: pw.FontWeight.bold,
//                   font: _isUrdu ? urduFont : lorafont, // Use correct font
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
// // Helper Function to Convert Text to Image
//
//
//     // Switch case for different measurement types
//     switch (MeasureMentType) {
//       case 'ShalwarQameez':
//         measurement = measurementProvider.shalwarQameez
//             .firstWhere((m) => m['serialNo'] == SerialNo, orElse: () => {});
//
//         // Add pages and content specific to Shalwar Qameez
//         if(isUrdu(measurement['QameezNote'].toString())){
//           byteList = await _generateTextImage(measurement['QameezNote'].toString());
//         }
//         if(isUrdu(measurement['ShalwarNote'].toString())){
//           SbyteList = await _generateTextImage(measurement['ShalwarNote'].toString());
//         }
//         pdf.addPage(pw.Page(
//           build: (pw.Context context) => pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               _buildHeader(),
//
//               pw.Text('Suits Count ${order.suitsCount}',
//                   style: pw.TextStyle(
//                       fontSize: 24, fontWeight: pw.FontWeight.bold)),
//               _buildMeasurementRow("Serial No: ${measurement!['serialNo']}",
//                   measurement!['serialNo']),
//               _buildMeasurementRow(
//                   "Name: ${measurement!['name']}", measurement!['name']),
//               pw.SizedBox(height: 20),
//
//               pw.Divider(),
//               pw.Container(
//                   child: pw.Row(
//                     // mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
//                       children: [
//                         pw.Table(columnWidths: {
//                           0: pw.FixedColumnWidth(200),
//                           // Set the width of the Measurements column
//                           1: pw.FixedColumnWidth(60)
//                         }, children: [
//                           pw.TableRow(children: [
//                             pw.Text("",
//                                 style: pw.TextStyle(
//                                     fontWeight: pw.FontWeight.bold, fontSize: 20)),
//                             pw.Text("",
//                                 style: pw.TextStyle(
//                                     fontWeight: pw.FontWeight.bold, fontSize: 20)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow(
//                                 'Lambai', measurement!['bodyqameezLambai']),
//                             pw.Text(measurement!['qameezLambai'],
//                                 style: pw.TextStyle(
//                                     fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow(
//                                 'Chaati', measurement!['bodychaati']),
//                             pw.Text(measurement!['chaati'],
//                                 style: pw.TextStyle(
//                                     fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow(
//                                 'Kamar', measurement!['bodykamar']),
//                             pw.Text(measurement!['kamar'],
//                                 style: pw.TextStyle(
//                                     fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow(
//                                 'Daman', measurement!['bodydaman']),
//                             pw.Text(measurement!['daman'],
//                                 style: pw.TextStyle(
//                                     fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow('Bazu', measurement!['bodybazu']),
//                             pw.Text(measurement!['bazu'],
//                                 style: pw.TextStyle(
//                                     fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow(
//                                 'Teera', measurement!['bodyteera']),
//                             pw.Text(measurement!['teera'],
//                                 style: pw.TextStyle(
//                                     fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow('Gala', measurement!['bodygala']),
//                             pw.Text(measurement!['gala'],
//                                 style: pw.TextStyle(
//                                     fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                         ]),
//                         if(isUrdu(measurement['QameezNote'].toString()))...[
//                           pw.Row(
//                               mainAxisAlignment: pw.MainAxisAlignment.start,
//                               children: [
//                                 pw.Text("Note:", style: pw.TextStyle(
//                                     fontSize: 22,
//                                     fontWeight: pw.FontWeight.bold
//                                 )),
//                                 pw.Container(
//                                   height: 300,
//                                   width: 250,
//                                   child: pw.Image(
//                                       height: 200,
//                                       width: 210,
//                                       pw.MemoryImage(byteList!)
//                                   ),
//                                 )
//                               ]
//                           )
//                         ]else ...[
//                           _buildMeasurementRow('Note:  ', measurement['QameezNote'].toString())
//                         ]
//                       ])),
//
//               pw.Divider(),
//               pw.Container(
//                   child: pw.Row(
//                       mainAxisAlignment: pw.MainAxisAlignment.start,
//                       children: [
//                         if (measurement!['selectedBottomType'] == 'Shalwar') ...[
//                           pw.Table(columnWidths: {
//                             0: pw.FixedColumnWidth(240),
//                             // Set the width of the Measurements column
//                             1: pw.FixedColumnWidth(50)
//                           }, children: [
//                             pw.TableRow(children: [
//                               pw.Text("",
//                                   style: pw.TextStyle(
//                                       fontWeight: pw.FontWeight.bold, fontSize: 20)),
//                               pw.Text("",
//                                   style: pw.TextStyle(
//                                       fontWeight: pw.FontWeight.bold, fontSize: 20)),
//                             ]),
//                             pw.TableRow(children: [
//                               _buildMeasurementRow(
//                                   "Shalwar Lambai", measurement!['bodyshalwarLambai']),
//                               pw.Text(measurement!['shalwarLambai'],
//                                   style: pw.TextStyle(
//                                       fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                             ]),
//                             pw.TableRow(children: [
//                               _buildMeasurementRow(
//                                   "Pauncha", measurement!['bodypauncha']),
//                               pw.Text(measurement!['pauncha'],
//                                   style: pw.TextStyle(
//                                       fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                             ]),
//                             pw.TableRow(children: [
//                               _buildMeasurementRow(
//                                   "Shalwar Gheera", measurement!['bodygheera']),
//                               pw.Text(measurement!['gheera'],
//                                   style: pw.TextStyle(
//                                       fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                             ]),
//                           ]),
//                         ]
//                         else ...[
//                           pw.Table(columnWidths: {
//                             0: pw.FixedColumnWidth(240),
//                             // Set the width of the Measurements column
//                             1: pw.FixedColumnWidth(50)
//                           }, children: [
//                             pw.TableRow(children: [
//                               pw.Text("Measurements",
//                                   style: pw.TextStyle(
//                                       fontWeight: pw.FontWeight.bold, fontSize: 20)),
//                               pw.Text("",
//                                   style: pw.TextStyle(
//                                       fontWeight: pw.FontWeight.bold, fontSize: 20)),
//                             ]),
//                             pw.TableRow(children: [
//                               _buildMeasurementRow(
//                                   "Trouser Lambai", measurement!['bodytrouserLambai']),
//                               pw.Text(measurement!['trouserLambai'],
//                                   style: pw.TextStyle(
//                                       fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                             ]),
//                             pw.TableRow(children: [
//                               _buildMeasurementRow(
//                                   "Pauncha", measurement!['bodypauncha']),
//                               pw.Text(measurement!['pauncha'],
//                                   style: pw.TextStyle(
//                                       fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                             ]),
//                             pw.TableRow(children: [
//                               _buildMeasurementRow("Hip", measurement!['bodyhip']),
//                               pw.Text(measurement!['hip'],
//                                   style: pw.TextStyle(
//                                       fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                             ]),
//                           ]),
//                         ],
//                         if(isUrdu(measurement['ShalwarNote'].toString()))...[
//                           pw.Row(
//                               mainAxisAlignment: pw.MainAxisAlignment.start,
//                               children: [
//                                 pw.Text("Note:", style: pw.TextStyle(
//                                     fontSize: 22,
//                                     fontWeight: pw.FontWeight.bold
//                                 )),
//                                 pw.Container(
//
//                                   height: 500,
//                                   width: 50,
//                                   child: pw.Image(
//                                       height: 200,
//                                       width: 190,
//                                       fit: pw.BoxFit.contain,
//                                       pw.MemoryImage(SbyteList!)
//                                   ),
//                                 )
//                               ]
//                           )
//                         ]else ...[
//                           _buildMeasurementRow('Note:  ', measurement['ShalwarNote'].toString())
//                         ]
//                       ])),
//             ],
//           ),
//         ));
//
//         break;
//
//       case 'Coat':
//         measurement = measurementProvider.coat
//             .firstWhere((m) => m['serialNo'] == SerialNo, orElse: () => {});
//
//
//         if(isUrdu(measurement['note'].toString())){
//           byteList = await _generateTextImage(measurement['note'].toString());
//         }
//         pdf.addPage(pw.Page(
//           build: (pw.Context context) => pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               _buildHeader(),
//
//               pw.Text('Suits Count ${order.suitsCount}',
//                   style: pw.TextStyle(
//                       fontSize: 24, fontWeight: pw.FontWeight.bold)),
//               pw.SizedBox(height: 10),
//
//               _buildMeasurementRow("Serial No", measurement!['serialNo']),
//               _buildMeasurementRow("Name", measurement!['name']),
//               pw.SizedBox(height: 20),
//
//               pw.Divider(),
//               pw.Container(
//                   child: pw.Row(
//                       children: [
//                         pw.Table(columnWidths: {
//                           0: pw.FixedColumnWidth(200),
//                           // Set the width of the Measurements column
//                           1: pw.FixedColumnWidth(50)
//                         }, children: [
//                           pw.TableRow(children: [
//                             pw.Text("",
//                                 style: pw.TextStyle(
//                                     fontWeight: pw.FontWeight.bold, fontSize: 20)),
//                             pw.Text("",
//                                 style: pw.TextStyle(
//                                     fontWeight: pw.FontWeight.bold, fontSize: 20)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow("Lambai", measurement!['bodylambai']),
//                             pw.Text(measurement!['lambai'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow("Chaati", measurement!['bodychaati']),
//                             pw.Text(measurement!['chaati'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow("Kamar", measurement!['bodykamar']),
//                             pw.Text(measurement!['kamar'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow("Hip", measurement!['bodyhip']),
//                             pw.Text(measurement!['hip'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow("Baazu", measurement!['bodybazu']),
//                             pw.Text(measurement!['bazu'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow("Teera", measurement!['bodyteera']),
//                             pw.Text(measurement!['teera'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow("Gala", measurement!['bodygala']),
//                             pw.Text(measurement!['gala'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow(
//                                 "Cross Back", measurement!['bodycrossBack']),
//                             pw.Text(measurement!['crossBack'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                         ]),
//                         if(isUrdu(measurement['note'].toString()))...[
//                           pw.Container(
//                               height: 500,
//                               width: 350,
//                               child: pw.Image(
//                                   height: 200,
//                                   width: 220,
//                                   pw.MemoryImage(byteList!)
//                               )
//                           )
//                         ]else...[
//                           _buildMeasurementRow('Note: ', measurement['note'])
//                         ]
//                       ]
//                   )
//               ),
//
//             ],
//           ),
//         ));
//
//         break;
//
//       case 'Pants':
//         measurement = measurementProvider.pants
//             .firstWhere((m) => m['serialNo'] == SerialNo, orElse: () => {});
//
//         if(isUrdu(measurement['note'].toString())){
//           byteList = await _generateTextImage(measurement['note'].toString());
//         }
//
//         pdf.addPage(pw.Page(
//           build: (pw.Context context) => pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               _buildHeader(),
//               pw.Text('Suits Count ${order.suitsCount}',
//                   style: pw.TextStyle(
//                       fontSize: 24, fontWeight: pw.FontWeight.bold)),
//
//               pw.SizedBox(height: 20),
//               _buildMeasurementRow("Serial No", measurement!['serialNo']),
//               _buildMeasurementRow("Name", measurement!['name']),
//               pw.SizedBox(height: 20),
//
//               pw.Divider(),
//               pw.Container(
//                   child: pw.Row(
//                       children: [
//
//                         pw.Table(columnWidths: {
//                           0: pw.FixedColumnWidth(200),
//                           // Set the width of the Measurements column
//                           1: pw.FixedColumnWidth(50)
//                         }, children: [
//                           pw.TableRow(children: [
//                             pw.Text("",
//                                 style: pw.TextStyle(
//                                     fontWeight: pw.FontWeight.bold, fontSize: 20)),
//                             pw.Text("",
//                                 style: pw.TextStyle(
//                                     fontWeight: pw.FontWeight.bold, fontSize: 20)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow("Lambai", measurement!['bodylambai']),
//                             pw.Text(measurement!['lambai'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow("Kamar", measurement!['bodykamar']),
//                             pw.Text(measurement!['kamar'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow("Hip", measurement!['bodyhip']),
//                             pw.Text(measurement!['hip'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow("Pauncha", measurement!['bodypauncha']),
//                             pw.Text(measurement!['pauncha'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow("Thai", measurement!['bodythai']),
//                             pw.Text(measurement!['thai'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                         ]),
//                         if(isUrdu(measurement['note'].toString()))...[
//                           pw.Container(
//                               height: 500,
//                               width: 350,
//                               child: pw.Image(
//                                   height: 200,
//                                   width: 220,
//                                   pw.MemoryImage(byteList!)
//                               )
//                           )
//                         ]else...[
//                           _buildMeasurementRow('Note: ', measurement['note'])
//                         ]
//                       ]
//                   )
//               ),
//
//             ],
//           ),
//         ));
//         break;
//       case 'Sherwani':
//         measurement = measurementProvider.sherwani
//             .firstWhere((m) => m['serialNo'] == SerialNo, orElse: () => {});
//         if(isUrdu(measurement['note'].toString())){
//           byteList = await _generateTextImage(measurement['note'].toString());
//         }
//         pdf.addPage(pw.Page(
//           build: (pw.Context context) => pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               _buildHeader(),
//
//               pw.Text('Suits Count ${order.suitsCount}',
//                   style: pw.TextStyle(
//                       fontSize: 24, fontWeight: pw.FontWeight.bold)),
//               pw.SizedBox(height: 10),
//
//               _buildMeasurementRow("Serial No", measurement!['serialNo']),
//               _buildMeasurementRow("Name", measurement!['name']),
//               pw.SizedBox(height: 20),
//               pw.Container(
//                   child: pw.Row(
//                       children: [
//                         pw.Table(columnWidths: {
//                           0: pw.FixedColumnWidth(200),
//                           // Set the width of the Measurements column
//                           1: pw.FixedColumnWidth(50)
//                         }, children: [
//                           pw.TableRow(children: [
//                             pw.Text("",
//                                 style: pw.TextStyle(
//                                     fontWeight: pw.FontWeight.bold, fontSize: 20)),
//                             pw.Text("",
//                                 style: pw.TextStyle(
//                                     fontWeight: pw.FontWeight.bold, fontSize: 20)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow("Lambai", measurement!['bodylambai']),
//                             pw.Text(measurement!['lambai'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow("Chaati", measurement!['bodychaati']),
//                             pw.Text(measurement!['chaati'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow("Kamar", measurement!['bodykamar']),
//                             pw.Text(measurement!['kamar'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow("Hip", measurement!['bodyhip']),
//                             pw.Text(measurement!['hip'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow("Baazu", measurement!['bodybazu']),
//                             pw.Text(measurement!['bazu'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow("Teera", measurement!['bodyteera']),
//                             pw.Text(measurement!['teera'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow("Gala", measurement!['bodygala']),
//                             pw.Text(measurement!['gala'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow(
//                                 "Cross Back", measurement!['bodycrossBack']),
//                             pw.Text(measurement!['crossBack'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                         ]),
//                         if(isUrdu(measurement['note'].toString()))...[
//                           pw.Container(
//                               height: 500,
//                               width: 350,
//                               child: pw.Image(
//                                   height: 200,
//                                   width: 220,
//                                   pw.MemoryImage(byteList!)
//                               )
//                           )
//                         ]else...[
//                           _buildMeasurementRow('Note: ', measurement['note'])
//                         ]
//                       ]
//                   )
//               ),
//
//             ],
//           ),
//         ));
//         break;
//       case 'Waskit':
//         measurement = measurementProvider.Waskit.firstWhere(
//                 (m) => m['serialNo'] == SerialNo,
//             orElse: () => {});
//         if(isUrdu(measurement['note'].toString())){
//           byteList = await _generateTextImage(measurement['note'].toString());
//         }
//         pdf.addPage(pw.Page(
//           build: (pw.Context context) => pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               _buildHeader(),
//               pw.Text('Suits Count ${order.suitsCount}',
//                   style: pw.TextStyle(
//                       fontSize: 24, fontWeight: pw.FontWeight.bold)),
//               pw.SizedBox(height: 10),
//
//
//               _buildMeasurementRow("Serial No", measurement!['serialNo']),
//               _buildMeasurementRow("Name", measurement!['name']),
//               pw.SizedBox(height: 20),
//
//
//               pw.Container(
//                   child: pw.Row(
//                       children: [
//                         pw.Table(columnWidths: {
//                           0: pw.FixedColumnWidth(200),
//                           // Set the width of the Measurements column
//                           1: pw.FixedColumnWidth(50)
//                         }, children: [
//                           pw.TableRow(children: [
//                             pw.Text("",
//                                 style: pw.TextStyle(
//                                     fontWeight: pw.FontWeight.bold, fontSize: 20)),
//                             pw.Text("",
//                                 style: pw.TextStyle(
//                                     fontWeight: pw.FontWeight.bold, fontSize: 20)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow("Lambai", measurement!['bodylambai']),
//                             pw.Text(measurement!['lambai'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow("Chaati", measurement!['bodychaati']),
//                             pw.Text(measurement!['chaati'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow("Kamar", measurement!['bodykamar']),
//                             pw.Text(measurement!['kamar'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow("Hip", measurement!['bodyhip']),
//                             pw.Text(measurement!['hip'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow("Teera", measurement!['bodyteera']),
//                             pw.Text(measurement!['teera'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                           pw.TableRow(children: [
//                             _buildMeasurementRow("Gala", measurement!['bodygala']),
//                             pw.Text(measurement!['gala'],style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
//                           ]),
//                         ]),
//                         if(isUrdu(measurement['note'].toString()))...[
//                           pw.Container(
//                               height: 500,
//                               width: 350,
//                               child: pw.Image(
//                                   height: 200,
//                                   width: 220,
//                                   pw.MemoryImage(byteList!)
//                               )
//                           )
//                         ]else...[
//                           _buildMeasurementRow('Note: ', measurement['note'])
//                         ]
//                       ]
//                   )
//               )
//
//             ],
//           ),
//         ));
//         break;
//
//     // Add other measurement types as needed
//
//       default:
//         throw Exception("Invalid MeasureMentType: $MeasureMentType");
//     }
//
//     // Save the PDF document for web
//     try {
//       Uint8List pdfData = await pdf.save();
//       final blob = html.Blob([pdfData], 'application/pdf');
//       final url = html.Url.createObjectUrlFromBlob(blob);
//       // html.window.open(url, '_blank');
//
//       // Create a link to download the PDF
//       final anchor = html.AnchorElement(href: url)
//         ..setAttribute('download',
//             'measurements_${order.serial}/${order.invoiceNumber}.pdf')
//         ..click();
//       // print(pdfData);
//       await showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             contentPadding: EdgeInsets.zero,
//             content: SizedBox(
//               width: 400, // Adjust width as needed
//               height: 600, // Adjust height as needed
//               child: PdfPreview(
//                 build: (format) => pdfData,
//                 allowPrinting: true,
//                 allowSharing: true,
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop(); // Close the dialog
//                 },
//                 child: const Text('Close'),
//               ),
//             ],
//           );
//         },
//       );
//
//       // Cleanup
//     } catch (e) {
//       print("Error saving or opening PDF: $e");
//       // Optionally show an alert dialog here
//     }
//   }
//
//
//
//
//   Future<Uint8List> loadFontFromAssets(String path) async {
//     final ByteData data = await rootBundle.load(path);
//     return data.buffer.asUint8List();
//   }
//   Future<Uint8List> _getCompanyLogoBytes() async {
//     final logoData = await rootBundle.load('assets/images/logo.png');
//     return logoData.buffer.asUint8List();
//       }
// }