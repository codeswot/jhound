import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_db.dart';
import '../../core/utils/toast.dart';
import '../providers/api_provider.dart';
import '../providers/drafts_provider.dart';
import '../providers/emails_provider.dart';

class _Attachment {
  _Attachment(
      {required this.filename,
      required this.contentBase64,
      required this.contentType});
  final String filename;
  final String contentBase64;
  final String contentType;

  Map<String, String> toJson() => {
        'filename': filename,
        'content': contentBase64,
        if (contentType.isNotEmpty) 'content_type': contentType,
      };
}

class DraftComposeScreen extends ConsumerStatefulWidget {
  const DraftComposeScreen({
    super.key,
    this.localId,
    this.replyToInboundId,
    this.prefillTo,
    this.prefillSubject,
    this.prefillJobId,
  });

  final String? localId;
  final String? replyToInboundId;
  final List<String>? prefillTo;
  final String? prefillSubject;
  final String? prefillJobId;

  @override
  ConsumerState<DraftComposeScreen> createState() => _DraftComposeScreenState();
}

class _DraftComposeScreenState extends ConsumerState<DraftComposeScreen> {
  final _toCtrl = TextEditingController();
  final _ccCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _busy = false;
  LocalDraft? _draft;
  final List<_Attachment> _attachments = [];

  bool get _isReply => widget.replyToInboundId != null;

  @override
  void initState() {
    super.initState();
    if (widget.localId != null) {
      _load(widget.localId!);
    } else {
      if (widget.prefillTo != null) _toCtrl.text = widget.prefillTo!.join(', ');
      if (widget.prefillSubject != null)
        _subjectCtrl.text = widget.prefillSubject!;
    }
  }

  Future<void> _load(String id) async {
    setState(() => _busy = true);
    try {
      final draft = await ref.read(draftsCoordinatorProvider).findByLocalId(id);
      if (draft == null) throw StateError('draft not found');
      _draft = draft;
      _toCtrl.text = draft.toAddresses.replaceAll(',', ', ');
      _ccCtrl.text = draft.ccAddresses?.replaceAll(',', ', ') ?? '';
      _subjectCtrl.text = draft.subject ?? '';
      _bodyCtrl.text = draft.bodyText ?? draft.bodyHtml ?? '';
    } catch (e) {
      if (mounted) toastError(context, 'Could not load draft', e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _toCtrl.dispose();
    _ccCtrl.dispose();
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  List<String> _splitEmails(String s) => s
      .split(RegExp(r'[,;\s]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform
        .pickFiles(allowMultiple: true, withData: true);
    if (result == null) return;
    for (final f in result.files) {
      if (f.bytes == null) continue;
      _attachments.add(_Attachment(
        filename: f.name,
        contentBase64: base64Encode(f.bytes!),
        contentType: _guessType(f.name),
      ));
    }
    setState(() {});
  }

  String _guessType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    final emailsRepo = ref.read(emailsRepoProvider);
    final coord = ref.read(draftsCoordinatorProvider);

    try {
      final to = _splitEmails(_toCtrl.text);
      final cc = _splitEmails(_ccCtrl.text);
      if (to.isEmpty) throw ArgumentError('to: at least one recipient');

      if (_isReply) {
        await emailsRepo.reply(
          widget.replyToInboundId!,
          text: _bodyCtrl.text,
          subject: _subjectCtrl.text.trim().isEmpty
              ? null
              : _subjectCtrl.text.trim(),
          jobId: widget.prefillJobId,
        );
      } else {
        await emailsRepo.sendRaw(
          to: to,
          subject: _subjectCtrl.text.trim().isEmpty
              ? '(no subject)'
              : _subjectCtrl.text.trim(),
          text: _bodyCtrl.text.isEmpty ? null : _bodyCtrl.text,
          cc: cc.isEmpty ? null : cc,
          jobId: widget.prefillJobId,
          attachments: _attachments.isNotEmpty
              ? _attachments.map((a) => a.toJson()).toList()
              : null,
        );
      }

      if (_draft != null) await coord.remove(_draft!.localId);
      ref.invalidate(draftsStreamProvider);
      ref.invalidate(sentProvider);

      if (mounted) toastSuccess(context, 'Email sent');
      if (mounted) navigator.pop();
    } catch (e) {
      if (mounted)
        toastError(context,
            'Could not send email. Check connection and try again.', e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveDraft() async {
    setState(() => _busy = true);
    final coord = ref.read(draftsCoordinatorProvider);

    try {
      final to = _splitEmails(_toCtrl.text);
      if (to.isEmpty) throw ArgumentError('to: at least one recipient');
      final cc = _splitEmails(_ccCtrl.text);

      if (_draft == null) {
        final saved = await coord.create(
          toAddresses: to,
          ccAddresses: cc.isEmpty ? null : cc,
          replyToResendId: widget.replyToInboundId,
          jobId: widget.prefillJobId,
          subject: _subjectCtrl.text.trim().isEmpty
              ? null
              : _subjectCtrl.text.trim(),
          bodyText: _bodyCtrl.text.isEmpty ? null : _bodyCtrl.text,
        );
        _draft = saved;
      } else {
        await coord.update(
          _draft!.localId,
          toAddresses: to,
          ccAddresses: cc.isEmpty ? null : cc,
          subject: _subjectCtrl.text.trim(),
          bodyText: _bodyCtrl.text,
        );
      }
      ref.invalidate(draftsStreamProvider);
      if (mounted) toastSuccess(context, 'Draft saved');
    } catch (e) {
      if (mounted) toastError(context, 'Could not save draft', e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.localId != null
        ? 'Edit draft'
        : _isReply
            ? 'Reply'
            : 'New email';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          _ActionPill(
            icon: Icons.attach_file,
            tooltip: 'Attach files',
            onTap: _busy ? null : _pickAttachments,
            side: _PillSide.left,
          ),
          _ActionPill(
            icon: Icons.save,
            tooltip: 'Save as draft',
            onTap: _busy ? null : _saveDraft,
            side: _PillSide.center,
          ),
          _ActionPill(
            icon: Icons.send,
            tooltip: 'Send',
            onTap: _busy ? null : _send,
            side: _PillSide.right,
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _toCtrl,
              decoration:
                  const InputDecoration(labelText: 'To (comma separated)'),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ccCtrl,
              decoration: const InputDecoration(labelText: 'Cc'),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyCtrl,
              decoration: const InputDecoration(labelText: 'Body'),
              maxLines: 14,
              minLines: 8,
              keyboardType: TextInputType.multiline,
            ),
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Attachments',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: List.generate(_attachments.length, (i) {
                  final a = _attachments[i];
                  return InputChip(
                    avatar: const Icon(Icons.insert_drive_file, size: 16),
                    label: Text(a.filename),
                    onDeleted: () => setState(() => _attachments.removeAt(i)),
                  );
                }),
              ),
            ],
            if (_busy) ...const [
              SizedBox(height: 16),
              Center(child: CircularProgressIndicator())
            ],
          ],
        ),
      ),
    );
  }
}

enum _PillSide { left, center, right }

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.tooltip,
    required this.side,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final _PillSide side;
  final VoidCallback? onTap;

  static const _rLarge = Radius.circular(14);
  static const _rSmall = Radius.circular(8);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    BorderRadius borderRadius;
    switch (side) {
      case _PillSide.left:
        borderRadius = const BorderRadius.only(
          topLeft: _rLarge,
          bottomLeft: _rLarge,
          topRight: _rSmall,
          bottomRight: _rSmall,
        );
      case _PillSide.right:
        borderRadius = const BorderRadius.only(
          topLeft: _rSmall,
          bottomLeft: _rSmall,
          topRight: _rLarge,
          bottomRight: _rLarge,
        );
      case _PillSide.center:
        borderRadius = BorderRadius.circular(8);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: onTap != null
            ? scheme.surfaceContainerHigh
            : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: Tooltip(
            message: tooltip,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}
