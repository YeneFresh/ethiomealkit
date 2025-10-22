import 'package:flutter/material.dart';

class MenuAdminScreen extends StatelessWidget {
  const MenuAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin • Menu')),
      body: const Center(child: Text('Menu Admin')),
    );
  }
}
