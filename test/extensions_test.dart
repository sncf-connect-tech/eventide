import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:eventide/src/calendar_api.g.dart';
import 'package:eventide/src/eventide_platform_interface.dart';
import 'package:eventide/src/extensions/account_extensions.dart';
import 'package:eventide/src/extensions/color_extensions.dart';
import 'package:eventide/src/extensions/duration_extensions.dart';

void main() {
  group('AccountExtensions tests', () {
    test('Account toETAccount conversion', () {
      // Given
      final account = Account(id: 'test-id', name: 'Test Account', type: 'com.google');

      // When
      final etAccount = account.toETAccount();

      // Then
      expect(etAccount.id, 'test-id');
      expect(etAccount.name, 'Test Account');
      expect(etAccount.type, 'com.google');
    });

    test('Account toETAccount with special characters', () {
      // Given
      final account = Account(id: 'special-123_test', name: 'user+tag@example.com', type: 'com.test.special');

      // When
      final etAccount = account.toETAccount();

      // Then
      expect(etAccount.id, 'special-123_test');
      expect(etAccount.name, 'user+tag@example.com');
      expect(etAccount.type, 'com.test.special');
    });

    test('List<Account> toETAccountList conversion', () {
      // Given
      final accounts = [
        Account(id: '1', name: 'Account 1', type: 'type1'),
        Account(id: '2', name: 'Account 2', type: 'type2'),
        Account(id: '3', name: 'Account 3', type: 'type3'),
      ];

      // When
      final etAccounts = accounts.toETAccountList();

      // Then
      expect(etAccounts, hasLength(3));
      expect(etAccounts[0].id, '1');
      expect(etAccounts[0].name, 'Account 1');
      expect(etAccounts[0].type, 'type1');
      expect(etAccounts[1].id, '2');
      expect(etAccounts[1].name, 'Account 2');
      expect(etAccounts[1].type, 'type2');
      expect(etAccounts[2].id, '3');
      expect(etAccounts[2].name, 'Account 3');
      expect(etAccounts[2].type, 'type3');
    });

    test('empty List<Account> toETAccountList conversion', () {
      // Given
      final accounts = <Account>[];

      // When
      final etAccounts = accounts.toETAccountList();

      // Then
      expect(etAccounts, isEmpty);
      expect(etAccounts, isA<List<ETAccount>>());
    });

    test('ETAccount toAccount conversion', () {
      // Given
      const etAccount = ETAccount(id: 'et-test-id', name: 'ET Test Account', type: 'com.eventide');

      // When
      final account = etAccount.toAccount();

      // Then
      expect(account.id, 'et-test-id');
      expect(account.name, 'ET Test Account');
      expect(account.type, 'com.eventide');
    });

    test('ETAccount toAccount with unicode characters', () {
      // Given
      const etAccount = ETAccount(id: 'unicode-test', name: 'Ñoño\'s Calendar 📅', type: 'com.unicode.test');

      // When
      final account = etAccount.toAccount();

      // Then
      expect(account.id, 'unicode-test');
      expect(account.name, 'Ñoño\'s Calendar 📅');
      expect(account.type, 'com.unicode.test');
    });

    test('round-trip conversion Account -> ETAccount -> Account', () {
      // Given
      final originalAccount = Account(id: 'round-trip-test', name: 'Round Trip Account', type: 'com.roundtrip');

      // When
      final etAccount = originalAccount.toETAccount();
      final convertedAccount = etAccount.toAccount();

      // Then
      expect(convertedAccount.id, originalAccount.id);
      expect(convertedAccount.name, originalAccount.name);
      expect(convertedAccount.type, originalAccount.type);
    });

    test('round-trip conversion ETAccount -> Account -> ETAccount', () {
      // Given
      const originalETAccount = ETAccount(
        id: 'et-round-trip-test',
        name: 'ET Round Trip Account',
        type: 'com.et.roundtrip',
      );

      // When
      final account = originalETAccount.toAccount();
      final convertedETAccount = account.toETAccount();

      // Then
      expect(convertedETAccount.id, originalETAccount.id);
      expect(convertedETAccount.name, originalETAccount.name);
      expect(convertedETAccount.type, originalETAccount.type);
    });
  });

  group('ColorToValue tests', () {
    test('Color toValue', () {
      const color = Color(0xFF123456);
      expect(color.toValue(), 0xFF123456);
    });
  });

  group('NativeToDuration tests', () {
    test('int toDuration on iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(10.toDuration(), Duration(seconds: 10));
      debugDefaultTargetPlatformOverride = null;
    });

    test('int toDuration on Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(10.toDuration(), Duration(minutes: 10));
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('DurationToNative tests', () {
    test('Duration toNativeDuration on iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(Duration(seconds: 10).toNativeDuration(), 10);
      debugDefaultTargetPlatformOverride = null;
    });

    test('Duration toNativeDuration on Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(Duration(minutes: 10).toNativeDuration(), 10);
      debugDefaultTargetPlatformOverride = null;
    });

    test('Iterable<Duration> toNativeList', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final durations = [Duration(minutes: 10), Duration(minutes: 20)];
      expect(durations.toNativeList(), [10, 20]);
      debugDefaultTargetPlatformOverride = null;
    });

    test('Iterable<int> toDurationList', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final durations = [10, 20];
      expect(durations.toDurationList(), [Duration(minutes: 10), Duration(minutes: 20)]);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
