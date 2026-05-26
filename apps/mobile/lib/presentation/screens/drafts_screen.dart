import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/animations/animated_route.dart';
import '../../core/animations/staggered_list.dart';
import '../../core/utils/toast.dart';
import '../../data/db/app_db.dart';
import '../providers/drafts_provider.dart';
import '../widgets/expressive_loader.dart';
import 'draft_compose_screen.dart';

class DraftsScreen extends ConsumerWidget {
  const DraftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(draftsStreamProvider);
    final coord = ref.read(draftsCoordinatorProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drafts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => coord.refresh(),
          ),
        ],
      ),
      body: stream.when(
        loading: () => const Center(child: ExpressiveLoader()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.drafts, size: 64, color: scheme.outline),
                    const SizedBox(height: 16),
                    Text('No drafts', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Tap compose to create a new email',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (_, i) => StaggeredItem(
              index: i,
              child: _DraftTile(draft: items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _DraftTile extends ConsumerWidget {
  const _DraftTile({required this.draft});
  final LocalDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isSent = draft.sentAt != null;
    final dirty = draft.syncState == 'dirty';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => Navigator.of(context).push(
            SlideUpRoute<void>(
              builder: (_) => DraftComposeScreen(localId: draft.localId),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSent
                        ? scheme.primaryContainer
                        : dirty
                            ? Colors.orangeAccent.withValues(alpha: 0.2)
                            : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isSent ? Icons.check_circle : Icons.drafts,
                    size: 20,
                    color: isSent
                        ? scheme.onPrimaryContainer
                        : dirty
                            ? Colors.orangeAccent
                            : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        draft.subject ?? '(no subject)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'To: ${draft.toAddresses}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMd().add_jm().format(draft.updatedAt.toLocal()),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (!isSent)
                  IconButton(
                    icon: const Icon(Icons.send),
                    tooltip: 'Send draft',
                    onPressed: () => _send(context, ref),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _send(BuildContext context, WidgetRef ref) async {
    try {
      final result = await ref.read(draftsCoordinatorProvider).send(draft.localId);
      toastSuccess(context, 'Email sent');
      debugPrint('[jhound] sent draft resend_id=${result.resendId}');
    } catch (err) {
      toastError(context, 'Could not send draft', err);
    }
  }
}
