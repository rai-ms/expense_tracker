import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';

import '../../base/logger/app_logger.dart';
import '../objectbox_service/objectbox_service.dart';

/// Timeout duration options before the app locks itself after being backgrounded
enum AutoLockTimeout {
  immediately(0, 'Immediately'),
  seconds30(30, '30 Seconds'),
  minute1(60, '1 Minute'),
  minutes5(300, '5 Minutes');

  final int seconds;
  final String label;
  const AutoLockTimeout(this.seconds, this.label);

  static AutoLockTimeout fromSeconds(int? seconds) {
    if (seconds == null) return AutoLockTimeout.immediately;
    return AutoLockTimeout.values.firstWhere(
      (e) => e.seconds == seconds,
      orElse: () => AutoLockTimeout.immediately,
    );
  }
}

/// Comprehensive Security Service managing Biometric Auth, Fallback PIN, Auto-Lock, and Privacy Mode
@lazySingleton
class SecurityService {
  static const _prefBiometricEnabledKey = 'security_biometric_enabled';
  static const _prefPinEnabledKey = 'security_pin_enabled';
  static const _prefAutoLockTimeoutKey = 'security_autolock_timeout';
  static const _prefPrivacyModeKey = 'security_privacy_mode_enabled';

  static const _securePinHashKey = 'spendwise_secure_pin_hash';
  static const _securePinSaltKey = 'spendwise_secure_pin_salt';

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  final ValueNotifier<bool> isLockedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isPrivacyModeNotifier = ValueNotifier<bool>(false);

  DateTime? _lastPausedTime;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  SecurityService() {
    _init();
  }

  void _init() {
    final privacyStored = ObjectBoxService.instance.getBoolSetting(_prefPrivacyModeKey, defaultValue: false);
    isPrivacyModeNotifier.value = privacyStored;

    // If lock is enabled, start app in locked state
    if (isLockEnabled) {
      isLockedNotifier.value = true;
    }
  }

  // ===========================================================================
  // 🔒 Lock State & Settings
  // ===========================================================================

  bool get isBiometricEnabled =>
      ObjectBoxService.instance.getBoolSetting(_prefBiometricEnabledKey, defaultValue: false);

  set isBiometricEnabled(bool value) {
    ObjectBoxService.instance.setBoolSetting(_prefBiometricEnabledKey, value);
    if (!value && !isPinEnabled) {
      isLockedNotifier.value = false;
    }
  }

  bool get isPinEnabled =>
      ObjectBoxService.instance.getBoolSetting(_prefPinEnabledKey, defaultValue: false);

  set isPinEnabled(bool value) {
    ObjectBoxService.instance.setBoolSetting(_prefPinEnabledKey, value);
    if (!value && !isBiometricEnabled) {
      isLockedNotifier.value = false;
    }
  }

  bool get isLockEnabled => isBiometricEnabled || isPinEnabled;

  AutoLockTimeout get autoLockTimeout {
    final sec = ObjectBoxService.instance.getIntSetting(_prefAutoLockTimeoutKey);
    return AutoLockTimeout.fromSeconds(sec);
  }

  set autoLockTimeout(AutoLockTimeout timeout) {
    ObjectBoxService.instance.setIntSetting(_prefAutoLockTimeoutKey, timeout.seconds);
  }

  // ===========================================================================
  // 👁️ Privacy Mode (Masking Sensitive Balances)
  // ===========================================================================

  bool get isPrivacyMode => isPrivacyModeNotifier.value;

  void togglePrivacyMode() {
    final next = !isPrivacyModeNotifier.value;
    isPrivacyModeNotifier.value = next;
    ObjectBoxService.instance.setBoolSetting(_prefPrivacyModeKey, next);
  }

  // ===========================================================================
  // 🖐️ Biometrics Detection & Prompt
  // ===========================================================================

  Future<bool> canCheckBiometrics() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canAuthenticateWithBiometrics || isDeviceSupported;
    } on PlatformException catch (e) {
      Log.e('Error checking biometric support: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      Log.e('Error getting available biometrics: $e');
      return [];
    }
  }

  Future<bool> authenticateWithBiometrics({String reason = 'Unlock SpendWise'}) async {
    if (isLockoutActive) return false;

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );

      if (authenticated) {
        unlockApp();
        return true;
      }
      return false;
    } on PlatformException catch (e) {
      Log.e('Biometric authentication failed: $e');
      return false;
    }
  }

  // ===========================================================================
  // 🔢 PIN Setup, Hashing & Verification
  // ===========================================================================

  Future<bool> hasStoredPin() async {
    final hash = await _secureStorage.read(key: _securePinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  Future<void> setPin(String fourDigitPin) async {
    if (fourDigitPin.length != 4) {
      throw ArgumentError('PIN must be exactly 4 digits');
    }

    final salt = DateTime.now().microsecondsSinceEpoch.toString();
    final hash = _hashPin(fourDigitPin, salt);

    await _secureStorage.write(key: _securePinHashKey, value: hash);
    await _secureStorage.write(key: _securePinSaltKey, value: salt);
    isPinEnabled = true;
    _failedAttempts = 0;
    _lockoutUntil = null;
    Log.i('New 4-digit PIN configured successfully');
  }

  Future<bool> verifyPin(String enteredPin) async {
    if (isLockoutActive) return false;

    final storedHash = await _secureStorage.read(key: _securePinHashKey);
    final salt = await _secureStorage.read(key: _securePinSaltKey);

    if (storedHash == null || salt == null) {
      return false;
    }

    final computedHash = _hashPin(enteredPin, salt);
    final isMatch = storedHash == computedHash;

    if (isMatch) {
      _failedAttempts = 0;
      _lockoutUntil = null;
      unlockApp();
      return true;
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
        Log.w('5 failed PIN attempts. Locked out for 30 seconds.');
      }
      return false;
    }
  }

  Future<void> removePin() async {
    await _secureStorage.delete(key: _securePinHashKey);
    await _secureStorage.delete(key: _securePinSaltKey);
    isPinEnabled = false;
    _failedAttempts = 0;
    _lockoutUntil = null;
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$pin::$salt::spendwise_secure_salt_2026');
    return sha256.convert(bytes).toString();
  }

  // ===========================================================================
  // ⏱️ Lockout & Cooldown
  // ===========================================================================

  bool get isLockoutActive {
    if (_lockoutUntil == null) return false;
    if (DateTime.now().isBefore(_lockoutUntil!)) {
      return true;
    }
    _lockoutUntil = null;
    _failedAttempts = 0;
    return false;
  }

  int get remainingLockoutSeconds {
    if (!isLockoutActive || _lockoutUntil == null) return 0;
    final diff = _lockoutUntil!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  int get failedAttempts => _failedAttempts;

  // ===========================================================================
  // 🔄 App Lifecycle Handlers (Auto-Lock on Background)
  // ===========================================================================

  void onAppPaused() {
    if (!isLockEnabled) return;
    _lastPausedTime = DateTime.now();
    Log.d('App paused at $_lastPausedTime. Auto-lock timeout: ${autoLockTimeout.label}');
  }

  void onAppResumed() {
    if (!isLockEnabled) return;

    if (_lastPausedTime == null) {
      lockApp();
      return;
    }

    final elapsedSeconds = DateTime.now().difference(_lastPausedTime!).inSeconds;
    Log.d('App resumed after $elapsedSeconds seconds.');

    if (elapsedSeconds >= autoLockTimeout.seconds) {
      lockApp();
    }
    _lastPausedTime = null;
  }

  void lockApp() {
    if (isLockEnabled && !isLockedNotifier.value) {
      isLockedNotifier.value = true;
      Log.i('App locked by SecurityService');
    }
  }

  void unlockApp() {
    if (isLockedNotifier.value) {
      isLockedNotifier.value = false;
      Log.i('App unlocked successfully');
    }
  }
}
