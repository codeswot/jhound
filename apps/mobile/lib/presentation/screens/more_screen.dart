import 'package:flutter/material.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Tile(
            icon: Icons.settings,
            title: 'Settings',
            subtitle: 'Theme, preferences, account',
            onTap: () {},
          ),
          _Tile(
            icon: Icons.dashboard,
            title: 'Dashboard',
            subtitle: 'jHound analytics and job stats',
            onTap: () {},
          ),
          _Tile(
            icon: Icons.bolt,
            title: 'Nostr',
            subtitle: 'Nostr client and DMs',
            onTap: () {},
          ),
          const SizedBox(height: 32),
          Text(
            'Coming soon',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.outline, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: scheme.onPrimaryContainer, size: 20),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }
}
