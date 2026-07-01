import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:uuid/uuid.dart';

class SecurityService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static final _localAuth = LocalAuthentication();

  // Keys
  static const _keyProfileName = 'profile_name';
  static const _keyHashedPin = 'hashed_pin';
  static const _keyFingerprintEnabled = 'fingerprint_enabled';
  static const _keyAppLockEnabled = 'app_lock_enabled';
  static const _keySessionTimeout = 'session_timeout_seconds';
  static const _keyLastActive = 'last_active_timestamp';
  static const _keyDbEncryptionKey = 'database_encryption_key';
  static const _keyDeviceId = 'device_unique_id';

  /// Hashes a PIN using SHA-256 with a device-specific salt.
  static String hashPin(String pin, {required String salt}) {
    final bytes = utf8.encode('$pin:$salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Sets up a new profile with a name and a PIN.
  static Future<void> setupProfile({
    required String name,
    required String pin,
    required bool enableFingerprint,
  }) async {
    final deviceId = await getDeviceId();
    await _storage.write(key: _keyProfileName, value: name);
    await _storage.write(
      key: _keyHashedPin,
      value: hashPin(pin, salt: deviceId),
    );
    await _storage.write(
      key: _keyFingerprintEnabled,
      value: enableFingerprint.toString(),
    );
    await _storage.write(
      key: _keyAppLockEnabled,
      value: 'true',
    ); // enabled by default
    await _storage.write(
      key: _keySessionTimeout,
      value: '60',
    ); // default 1 minute (60s)

    // Generate database key if not already generated
    await getDatabaseKey();
  }

  /// Verifies if a PIN is correct.
  static Future<bool> verifyPin(String pin) async {
    final storedHash = await _storage.read(key: _keyHashedPin);
    if (storedHash == null) return false;
    final deviceId = await getDeviceId();
    return hashPin(pin, salt: deviceId) == storedHash;
  }

  /// Changes the user's PIN.
  static Future<void> changePin(String oldPin, String newPin) async {
    final isValid = await verifyPin(oldPin);
    if (!isValid) throw Exception('Invalid old PIN');
    final deviceId = await getDeviceId();
    await _storage.write(
      key: _keyHashedPin,
      value: hashPin(newPin, salt: deviceId),
    );
  }

  /// Checks if a profile has been created.
  static Future<bool> hasProfile() async {
    final name = await _storage.read(key: _keyProfileName);
    return name != null && name.isNotEmpty;
  }

  /// Retrieves the user's full name.
  static Future<String?> getProfileName() async {
    return await _storage.read(key: _keyProfileName);
  }

  /// Updates the user's full name.
  static Future<void> updateProfileName(String name) async {
    await _storage.write(key: _keyProfileName, value: name);
  }

  /// Checks if fingerprint lock is enabled.
  static Future<bool> isFingerprintEnabled() async {
    final val = await _storage.read(key: _keyFingerprintEnabled);
    return val == 'true';
  }

  /// Toggles fingerprint lock.
  static Future<void> setFingerprintEnabled(bool enabled) async {
    await _storage.write(
      key: _keyFingerprintEnabled,
      value: enabled.toString(),
    );
  }

  /// Checks if biometrics are enabled.
  static Future<bool> isBiometricsEnabled() async {
    return await isFingerprintEnabled();
  }

  /// Checks if App Lock is enabled.
  static Future<bool> isAppLockEnabled() async {
    return true;
  }

  /// Toggles App Lock.
  static Future<void> setAppLockEnabled(bool enabled) async {
    await _storage.write(key: _keyAppLockEnabled, value: 'true');
  }

  /// Gets the session timeout duration in seconds.
  static Future<int> getSessionTimeout() async {
    final val = await _storage.read(key: _keySessionTimeout);
    if (val == null) return 60; // default 1 minute
    return int.tryParse(val) ?? 60;
  }

  /// Sets the session timeout duration.
  static Future<void> setSessionTimeout(int seconds) async {
    await _storage.write(key: _keySessionTimeout, value: seconds.toString());
  }

  /// Updates last active timestamp.
  static Future<void> updateLastActive() async {
    await _storage.write(
      key: _keyLastActive,
      value: DateTime.now().toIso8601String(),
    );
  }

  /// Checks if a lock is required based on session timeout.
  static Future<bool> isLockRequired() async {
    final lockEnabled = await isAppLockEnabled();
    if (!lockEnabled) return false;

    final timeout = await getSessionTimeout();
    if (timeout == -1) return false; // Never lock

    final lastActiveStr = await _storage.read(key: _keyLastActive);
    if (lastActiveStr == null) return true; // Lock if no timestamp is present

    try {
      final lastActive = DateTime.parse(lastActiveStr);
      final difference = DateTime.now().difference(lastActive).inSeconds;
      return difference >= timeout;
    } catch (_) {
      return true;
    }
  }

  /// Performs biometric authentication.
  static Future<bool> authenticateBiometrics() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    if (!canCheck || !isSupported) return false;

    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock KhataFlow',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Retrives or securely generates the 64-byte database encryption key.
  static Future<Uint8List> getDatabaseKey() async {
    final storedKeyHex = await _storage.read(key: _keyDbEncryptionKey);
    if (storedKeyHex != null) {
      return Uint8List.fromList(
        List<int>.generate(
          64,
          (i) => int.parse(storedKeyHex.substring(i * 2, i * 2 + 2), radix: 16),
        ),
      );
    }

    // Generate random 64-byte key
    final random = Random.secure();
    final keyBytes = List<int>.generate(64, (i) => random.nextInt(256));
    final keyHex = keyBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    await _storage.write(key: _keyDbEncryptionKey, value: keyHex);
    return Uint8List.fromList(keyBytes);
  }

  /// Retrieves or securely generates a unique device identifier for backup mapping.
  static Future<String> getDeviceId() async {
    var id = await _storage.read(key: _keyDeviceId);
    if (id == null) {
      id = const Uuid().v4();
      await _storage.write(key: _keyDeviceId, value: id);
    }
    return id;
  }
}
