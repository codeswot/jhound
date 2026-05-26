import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/lock_provider.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> with WidgetsBindingObserver {
  final _pinCtrl = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _attemptedBio = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeBio());
  }

  Future<void> _maybeBio() async {
    if (_attemptedBio) return;
    _attemptedBio = true;
    await ref.read(lockProvider.notifier).tryBiometric();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    HapticFeedback.lightImpact();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ok = await ref.read(lockProvider.notifier).verifyPin(_pinCtrl.text.trim());
      if (!ok) {
        _pinCtrl.clear();
        setState(() => _error = 'Wrong PIN');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lockProvider);
    final tooMany = state.attempts >= 5;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock, size: 48),
              const SizedBox(height: 12),
              Text(
                'jHound locked',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _pinCtrl,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)],
                keyboardType: TextInputType.number,
                obscureText: true,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, letterSpacing: 8),
                decoration: const InputDecoration(hintText: '••••'),
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              if (state.attempts > 0) ...[
                const SizedBox(height: 4),
                Text('Wrong attempts: ${state.attempts}', style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: const Text('Unlock'),
              ),
              if (state.biometricEnabled) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          ref.read(lockProvider.notifier).tryBiometric();
                        },
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Use biometrics'),
                ),
              ],
              if (tooMany) ...[
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          HapticFeedback.mediumImpact();
                          await ref.read(lockProvider.notifier).reset();
                        },
                  child: const Text('Reset device (wipes token + PIN)'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
