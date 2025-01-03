// Table(
//   border: TableBorder.all(),
//   columnWidths: {
//     0: const FlexColumnWidth(2),
//     1: const FlexColumnWidth(2),
//     2: const FlexColumnWidth(2),
//     3: const FlexColumnWidth(2),
//     4: const FlexColumnWidth(3),
//     5: const FlexColumnWidth(1),
//   },
//   children: [
//     // Table headers
//     TableRow(
//       children: [
//         TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(languageProvider.isEnglish ? 'Total' : 'کل', textAlign: TextAlign.center))),
//         TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(languageProvider.isEnglish ? 'Sarya Rate' : 'سرئے کی قیمت', textAlign: TextAlign.center))),
//         TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(languageProvider.isEnglish ? 'Sarya Qty' : 'سرئے کی مقدار', textAlign: TextAlign.center))),
//         TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(languageProvider.isEnglish ? 'Sarya Weight(Kg)' : 'سرئے کا وزن(کلوگرام)', textAlign: TextAlign.center))),
//         TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(languageProvider.isEnglish ? 'Description' : 'تفصیل', textAlign: TextAlign.center))),
//         TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(languageProvider.isEnglish ? 'Delete' : 'حذف کریں', textAlign: TextAlign.center))),
//       ],
//     ),
//     // Table rows
//     for (int i = 0; i < _invoiceRows.length; i++)
//       TableRow(
//         children: [
//           TableCell(child: Text(_invoiceRows[i]['total'].toStringAsFixed(2))),
//           TableCell(
//             child: TextField(
//               controller: TextEditingController(text: _invoiceRows[i]['rate'].toStringAsFixed(2)),
//               keyboardType: TextInputType.number,
//               onChanged: (value) => _updateRow(i, 'rate', double.tryParse(value) ?? 0.0),
//             ),
//           ),
//           TableCell(
//             child: TextField(
//               controller: TextEditingController(text: _invoiceRows[i]['qty'].toStringAsFixed(2)),
//               keyboardType: TextInputType.number,
//               onChanged: (value) => _updateRow(i, 'qty', double.tryParse(value) ?? 0.0),
//             ),
//           ),
//           TableCell(
//             child: TextField(
//               controller: TextEditingController(text: _invoiceRows[i]['weight'].toStringAsFixed(2)),
//               keyboardType: TextInputType.number,
//               onChanged: (value) => _updateRow(i, 'weight', double.tryParse(value) ?? 0.0),
//             ),
//           ),
//           TableCell(
//             child: TextField(
//               controller: TextEditingController(text: _invoiceRows[i]['description']),
//               onChanged: (value) => _updateRow(i, 'description', value),
//             ),
//           ),
//           TableCell(
//             child: IconButton(
//               icon: Icon(Icons.delete),
//               onPressed: () => _deleteRow(i),
//             ),
//           ),
//         ],
//       ),
//   ],
// ),
