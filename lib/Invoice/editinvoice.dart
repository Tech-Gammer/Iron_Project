import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Provider/invoice provider.dart';

class InvoiceEditPage extends StatefulWidget {
  final String invoiceId;
  final String invoiceNumber;
  final String customerId;
  final double subtotal;
  final double discount;
  final double grandTotal;
  final String paymentType;
  final String paymentMethod;
  final List<Map<String, dynamic>> items;

  InvoiceEditPage({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.customerId,
    required this.subtotal,
    required this.discount,
    required this.grandTotal,
    required this.paymentType,
    required this.paymentMethod,
    required this.items,
  });

  @override
  _InvoiceEditPageState createState() => _InvoiceEditPageState();
}

class _InvoiceEditPageState extends State<InvoiceEditPage> {
  late TextEditingController _invoiceNumberController;
  late TextEditingController _subtotalController;
  late TextEditingController _discountController;
  late TextEditingController _grandTotalController;

  @override
  void initState() {
    super.initState();
    _invoiceNumberController = TextEditingController(text: widget.invoiceNumber);
    _subtotalController = TextEditingController(text: widget.subtotal.toString());
    _discountController = TextEditingController(text: widget.discount.toString());
    _grandTotalController = TextEditingController(text: widget.grandTotal.toString());
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _subtotalController.dispose();
    _discountController.dispose();
    _grandTotalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoiceProvider = Provider.of<InvoiceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Invoice'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _invoiceNumberController,
              decoration: InputDecoration(labelText: 'Invoice Number'),
            ),
            TextField(
              controller: _subtotalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Subtotal'),
            ),
            TextField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Discount'),
            ),
            TextField(
              controller: _grandTotalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Grand Total'),
            ),
            ElevatedButton(
              onPressed: () async {
                await invoiceProvider.updateInvoice(
                  id: widget.invoiceId,
                  invoiceNumber: _invoiceNumberController.text,
                  customerId: widget.customerId,
                  subtotal: double.parse(_subtotalController.text),
                  discount: double.parse(_discountController.text),
                  grandTotal: double.parse(_grandTotalController.text),
                  paymentType: widget.paymentType,
                  paymentMethod: widget.paymentMethod,
                  items: widget.items,
                );
                Navigator.of(context).pop();
              },
              child: Text('Update Invoice'),
            ),
          ],
        ),
      ),
    );
  }
}
