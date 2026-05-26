import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/toast.dart';
import '../../core/animations/animated_route.dart';
import '../../data/models/email.dart';
import '../providers/emails_provider.dart';
import '../providers/api_provider.dart';
import '../widgets/expressive_loader.dart';
import 'draft_compose_screen.dart';

class EmailDetailScreen extends ConsumerWidget {
  const EmailDetailScreen({super.key, required this.id, required this.direction});

  final String id;
  final EmailDirection direction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = ref.watch(emailBodyProvider((id: id, direction: direction)));
    final attachments = ref.watch(emailAttachmentsProvider((id: id, direction: direction)));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(direction == EmailDirection.inbound ? 'Inbox' : 'Sent'),
        actions: [
          if (body.hasValue)
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy body text',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: body.value!.text ?? body.value!.html ?? ''));
                toastSuccess(context, 'Body copied to clipboard');
              },
            ),
          if (direction == EmailDirection.inbound)
            IconButton(
              icon: const Icon(Icons.reply),
              tooltip: 'Reply',
              onPressed: () => _reply(context, body.valueOrNull),
            ),
        ],
      ),
      body: body.when(
        loading: () => const Center(child: ExpressiveLoader()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: scheme.error),
                const SizedBox(height: 12),
                Text('$e', style: TextStyle(color: scheme.error)),
              ],
            ),
          ),
        ),
        data: (email) => _Body(
          email: email,
          attachmentsAsync: attachments,
          direction: direction,
        ),
      ),
    );
  }

  void _reply(BuildContext context, EmailBody? email) {
    if (email == null) return;
    Navigator.of(context).push(
      SlideUpRoute<void>(
        builder: (_) => DraftComposeScreen(
          replyToInboundId: email.id,
          prefillTo: [email.from],
          prefillSubject: _prefixReply(email.subject),
        ),
      ),
    );
  }

  static String? _prefixReply(String? subject) {
    if (subject == null || subject.isEmpty) return 'Re:';
    return subject.toLowerCase().startsWith('re:') ? subject : 'Re: $subject';
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.email,
    required this.attachmentsAsync,
    required this.direction,
  });
  final EmailBody email;
  final AsyncValue<List<AttachmentInfo>> attachmentsAsync;
  final EmailDirection direction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = DateFormat.yMMMd().add_jm();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(email.subject ?? '(no subject)',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Hero(
                      tag: 'email-avatar-${email.id}',
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: scheme.primaryContainer,
                        child: Text(
                          (email.from.isNotEmpty ? email.from[0] : '?').toUpperCase(),
                          style: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(email.from, style: Theme.of(context).textTheme.titleMedium),
                          Text('To: ${email.to.join(', ')}',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: scheme.outline),
                    const SizedBox(width: 6),
                    Text(fmt.format(email.createdAt.toLocal()),
                        style: Theme.of(context).textTheme.bodySmall),
                    if (email.lastEvent != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(email.lastEvent!,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        attachmentsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: ExpressiveLoader(size: 24)),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (attachments) {
            if (attachments.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Attachments', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...attachments.map((att) => _AttachmentTile(
                      attachment: att,
                      emailId: email.id,
                      direction: direction,
                    )),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: email.html != null && email.html!.isNotEmpty
                ? HtmlWidget(email.html!)
                : email.text != null && email.text!.isNotEmpty
                    ? SelectableText(email.text!)
                    : Text('(empty body)', style: TextStyle(color: scheme.outline)),
          ),
        ),
      ],
    );
  }
}

class _AttachmentTile extends ConsumerWidget {
  const _AttachmentTile({
    required this.attachment,
    required this.emailId,
    required this.direction,
  });

  final AttachmentInfo attachment;
  final String emailId;
  final EmailDirection direction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => _download(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _iconFor(attachment.contentType),
                  color: scheme.onTertiaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(attachment.filename,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(attachment.sizeLabel,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.download, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String mime) {
    if (mime.startsWith('image/')) return Icons.image;
    if (mime.contains('pdf')) return Icons.picture_as_pdf;
    if (mime.contains('word') || mime.contains('document')) return Icons.description;
    return Icons.insert_drive_file;
  }

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(emailsRepoProvider);
      final bytes = await repo.downloadAttachment(emailId, attachment.id, direction);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${attachment.filename}');
      await file.writeAsBytes(bytes);

      toastSuccess(context, 'Saved ${attachment.filename}');
      final uri = Uri.file(file.path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      toastError(context, 'Download failed', e);
    }
  }
}
