import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/lock_provider.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _enableBio = true;

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final pin = _pinCtrl.text.trim();
      final confirm = _confirmCtrl.text.trim();
      if (pin.length < 4 || pin.length > 12 || !RegExp(r'^[0-9]+$').hasMatch(pin)) {
        throw ArgumentError('PIN must be 4-12 digits');
      }
      if (pin != confirm) throw ArgumentError('PINs do not match');

      final notifier = ref.read(lockProvider.notifier);
      await notifier.setPin(pin);
      await notifier.setBiometricEnabled(_enableBio);
      if (_enableBio) {
        await notifier.tryBiometric(reason: 'Enable biometric unlock');
      }
    } catch (err) {
      debugPrint('[jhound] pin setup failed — $err');
      setState(() => _error = 'Could not save PIN. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Set PIN', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('4–12 digits. Required on every cold start.'),
              const SizedBox(height: 24),
              TextField(
                controller: _pinCtrl,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)],
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New PIN'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmCtrl,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)],
                keyboardType: TextInputType.number,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm PIN'),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Use biometrics if available'),
                value: _enableBio,
                onChanged: _busy ? null : (v) => setState(() => _enableBio = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save PIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
