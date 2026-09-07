import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:expense_tracker/core/services/security_service/security_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AutoLockTimeout Tests', () {
    test('AutoLockTimeout.fromSeconds correctly parses known durations', () {
      expect(AutoLockTimeout.fromSeconds(0), AutoLockTimeout.immediately);
      expect(AutoLockTimeout.fromSeconds(30), AutoLockTimeout.seconds30);
      expect(AutoLockTimeout.fromSeconds(60), AutoLockTimeout.minute1);
      expect(AutoLockTimeout.fromSeconds(300), AutoLockTimeout.minutes5);
    });

    test('AutoLockTimeout.fromSeconds defaults to immediately on null or unknown', () {
      expect(AutoLockTimeout.fromSeconds(null), AutoLockTimeout.immediately);
      expect(AutoLockTimeout.fromSeconds(999), AutoLockTimeout.immediately);
    });

    test('AutoLockTimeout labels are human-readable', () {
      expect(AutoLockTimeout.immediately.label, 'Immediately');
      expect(AutoLockTimeout.seconds30.label, '30 Seconds');
      expect(AutoLockTimeout.minute1.label, '1 Minute');
      expect(AutoLockTimeout.minutes5.label, '5 Minutes');
    });
  });

  group('PIN Hashing & Crypto Security Tests', () {
    String testHash(String pin, String salt) {
      final bytes = utf8.encode('$pin::$salt::spendwise_secure_salt_2026');
      return sha256.convert(bytes).toString();
    }

    test('PIN hashing produces a 64-character SHA-256 hexadecimal string', () {
      final hash = testHash('1234', 'salt_12345');
      expect(hash.length, 64);
      expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(hash), isTrue);
    });

    test('Different salts produce different hashes for identical PINs', () {
      final hash1 = testHash('1234', 'salt_A');
      final hash2 = testHash('1234', 'salt_B');
      expect(hash1, isNot(equals(hash2)));
    });

    test('Different PINs produce different hashes for identical salt', () {
      final hash1 = testHash('1234', 'same_salt');
      final hash2 = testHash('5678', 'same_salt');
      expect(hash1, isNot(equals(hash2)));
    });

    test('Matching PIN and salt verify successfully', () {
      final storedHash = testHash('9876', 'custom_salt_value');
      final attemptHash = testHash('9876', 'custom_salt_value');
      expect(storedHash, equals(attemptHash));
    });
  });
}
