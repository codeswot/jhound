import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/animations/animated_route.dart';
import '../../core/animations/expressive_refresh.dart';
import '../../core/animations/staggered_list.dart';
import '../../data/models/email.dart';
import '../providers/api_provider.dart';
import '../widgets/expressive_loader.dart';
import 'email_detail_screen.dart';
import 'more_screen.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key, this.direction});

  final EmailDirection? direction;

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  @override
  Widget build(BuildContext context) {
    final dir = widget.direction ?? EmailDirection.inbound;
    return Scaffold(
      appBar: AppBar(
        title: Text(dir == EmailDirection.inbound ? 'Inbox' : 'Sent'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'More',
            onPressed: () => Navigator.of(context).push(
              SlideUpRoute<void>(builder: (_) => const MoreScreen()),
            ),
          ),
        ],
      ),
      body: _CursorList(direction: dir),
    );
  }
}

class _CursorList extends ConsumerStatefulWidget {
  const _CursorList({required this.direction});
  final EmailDirection direction;

  @override
  ConsumerState<_CursorList> createState() => _CursorListState();
}

class _CursorListState extends ConsumerState<_CursorList> {
  final _scrollCtrl = ScrollController();
  final _items = <EmailSummary>[];
  String? _lastId;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      if (!_loading && _hasMore) _fetch();
    }
  }

  Future<void> _fetch() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(emailsRepoProvider);
      final page = widget.direction == EmailDirection.inbound
          ? await repo.listInbox(limit: 50, after: _lastId)
          : await repo.listSent(limit: 50, after: _lastId);

      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        if (page.items.isNotEmpty) _lastId = page.items.last.id;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('[jhound] inbox fetch failed — $e');
      setState(() {
        _error = 'Could not load emails. Pull to retry.';
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _lastId = null;
      _hasMore = true;
    });
    await _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_items.isEmpty && _loading) {
      return const Center(child: ExpressiveLoader());
    }

    if (_error != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 48, color: scheme.error),
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: scheme.error)),
              const SizedBox(height: 8),
              FilledButton(onPressed: _refresh, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox, size: 64, color: scheme.outline),
              const SizedBox(height: 16),
              Text(
                widget.direction == EmailDirection.inbound ? 'Inbox empty' : 'Nothing sent yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return ExpressiveRefreshIndicator(
      onRefresh: _refresh,
      scrollController: _scrollCtrl,
      child: ListView.separated(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, i) {
          if (i >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: ExpressiveLoader(size: 32)),
            );
          }
          return StaggeredItem(
            index: i,
            child: _EmailTile(email: _items[i]),
          );
        },
      ),
    );
  }
}

class _EmailTile extends StatelessWidget {
  const _EmailTile({required this.email});
  final EmailSummary email;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isInbound = email.direction == EmailDirection.inbound;
    final who = isInbound ? email.from : 'To: ${email.to.join(', ')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => Navigator.of(context).push(
            SlideUpRoute<void>(
              builder: (_) => EmailDetailScreen(id: email.id, direction: email.direction),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Hero(
                  tag: 'email-avatar-${email.id}',
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isInbound
                          ? scheme.primaryContainer
                          : scheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isInbound ? Icons.inbox : Icons.send,
                      size: 20,
                      color: isInbound
                          ? scheme.onPrimaryContainer
                          : scheme.onTertiaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        who,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email.subject ?? '(no subject)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMd().add_jm().format(email.createdAt.toLocal()),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    if (email.lastEvent != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _eventColor(email.lastEvent!, scheme).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          email.lastEvent!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _eventColor(email.lastEvent!, scheme),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _eventColor(String event, ColorScheme scheme) {
    switch (event) {
      case 'delivered':
        return Colors.greenAccent;
      case 'opened':
        return scheme.primary;
      case 'clicked':
        return scheme.secondary;
      case 'bounced':
      case 'failed':
        return scheme.error;
      default:
        return scheme.outline;
    }
  }
}
