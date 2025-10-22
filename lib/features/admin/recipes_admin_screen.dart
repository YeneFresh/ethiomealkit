import 'package:flutter/material.dart';

class RecipesAdminScreen extends StatelessWidget {
  const RecipesAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin • Recipes')),
      body: const Center(child: Text('Recipes Admin')),
    );
  }
}
