import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/animations/animated_route.dart';
import '../providers/sync_provider.dart';
import '../../data/models/email.dart';
import 'draft_compose_screen.dart';
import 'drafts_screen.dart';
import 'inbox_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    ref.watch(syncBootstrapProvider);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          InboxScreen(),
          InboxScreen(direction: EmailDirection.outbound),
          DraftsScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).push(
            SlideUpRoute<void>(builder: (_) => const DraftComposeScreen()),
          );
        },
        icon: const Icon(Icons.edit),
        label: const Text('Compose'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          HapticFeedback.lightImpact();
          setState(() => _index = i);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.inbox), label: 'Inbox'),
          NavigationDestination(icon: Icon(Icons.send), label: 'Sent'),
          NavigationDestination(icon: Icon(Icons.drafts), label: 'Drafts'),
        ],
      ),
    );
  }
}
