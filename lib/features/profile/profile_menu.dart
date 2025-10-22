import 'package:flutter/material.dart';
import 'package:ethiomealkit/supabase_client.dart';

class ProfileMenu extends StatelessWidget {
  const ProfileMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'signout') {
          final client = SupabaseConfig.client;
          if (client != null) {
            await client.auth.signOut();
          }
          if (context.mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/signin', (_) => false);
          }
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'signout', child: Text('Sign out')),
      ],
    );
  }
}
