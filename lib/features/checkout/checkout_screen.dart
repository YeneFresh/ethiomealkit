import 'package:flutter/material.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String? addressId;
  String? windowId;
  bool cashOnDelivery = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Address'),
          DropdownButton<String>(
            value: addressId,
            items: const [
              DropdownMenuItem(value: 'addr1', child: Text('Home')),
              DropdownMenuItem(value: 'addr2', child: Text('Work')),
            ],
            onChanged: (v) => setState(() => addressId = v),
          ),
          const SizedBox(height: 16),
          const Text('Delivery Window'),
          DropdownButton<String>(
            value: windowId,
            items: const [
              DropdownMenuItem(value: 'wed-am', child: Text('Wednesday AM')),
              DropdownMenuItem(value: 'sat-pm', child: Text('Saturday PM')),
            ],
            onChanged: (v) => setState(() => windowId = v),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Cash on Delivery'),
            value: cashOnDelivery,
            onChanged: (v) => setState(() => cashOnDelivery = v),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (addressId == null || windowId == null) ? null : () {},
            child: const Text('Place Order'),
          )
        ],
      ),
    );
  }
}



