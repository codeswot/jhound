import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/config/pin_service.dart';
import 'settings_provider.dart';

final pinServiceProvider = Provider<PinService>((ref) {
  return PinService(ref.watch(secureStorageProvider));
});

final localAuthProvider = Provider<LocalAuthentication>((ref) => LocalAuthentication());

class LockState {
  const LockState({
    required this.loading,
    required this.hasPin,
    required this.isUnlocked,
    required this.attempts,
    required this.biometricEnabled,
  });

  final bool loading;
  final bool hasPin;
  final bool isUnlocked;
  final int attempts;
  final bool biometricEnabled;

  static const initial = LockState(
    loading: true,
    hasPin: false,
    isUnlocked: false,
    attempts: 0,
    biometricEnabled: false,
  );

  LockState copyWith({
    bool? loading,
    bool? hasPin,
    bool? isUnlocked,
    int? attempts,
    bool? biometricEnabled,
  }) =>
      LockState(
        loading: loading ?? this.loading,
        hasPin: hasPin ?? this.hasPin,
        isUnlocked: isUnlocked ?? this.isUnlocked,
        attempts: attempts ?? this.attempts,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      );
}

class LockNotifier extends StateNotifier<LockState> {
  LockNotifier(this._pin, this._auth) : super(LockState.initial) {
    _bootstrap();
  }

  final PinService _pin;
  final LocalAuthentication _auth;

  Future<void> _bootstrap() async {
    final hasPin = await _pin.hasPin();
    final attempts = await _pin.attempts();
    final bio = await _pin.biometricEnabled();
    state = LockState(
      loading: false,
      hasPin: hasPin,
      isUnlocked: false,
      attempts: attempts,
      biometricEnabled: bio,
    );
  }

  Future<void> setPin(String pin) async {
    await _pin.setPin(pin);
    state = state.copyWith(hasPin: true, isUnlocked: true, attempts: 0);
  }

  Future<bool> verifyPin(String pin) async {
    final ok = await _pin.verify(pin);
    state = state.copyWith(
      isUnlocked: ok ? true : state.isUnlocked,
      attempts: ok ? 0 : state.attempts + 1,
    );
    return ok;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _pin.setBiometricEnabled(enabled);
    state = state.copyWith(biometricEnabled: enabled);
  }

  Future<bool> tryBiometric({String reason = 'Unlock jHound'}) async {
    if (!state.biometricEnabled) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (ok) state = state.copyWith(isUnlocked: true);
      return ok;
    } catch (_) {
      return false;
    }
  }

  void lock() => state = state.copyWith(isUnlocked: false);

  Future<void> reset() async {
    await _pin.reset();
    state = const LockState(
      loading: false,
      hasPin: false,
      isUnlocked: false,
      attempts: 0,
      biometricEnabled: false,
    );
  }
}

final lockProvider = StateNotifierProvider<LockNotifier, LockState>((ref) {
  return LockNotifier(ref.watch(pinServiceProvider), ref.watch(localAuthProvider));
});
