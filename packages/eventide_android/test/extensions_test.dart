import 'dart:ui';

import 'package:eventide_platform_interface/eventide_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eventide_android/src/calendar_api.g.dart';
import 'package:eventide_android/src/extensions/account_extensions.dart';
import 'package:eventide_android/src/extensions/color_extensions.dart';
import 'package:eventide_android/src/extensions/duration_extensions.dart';

void main() {
  group('AccountExtensions tests', () {
    test('round-trip Account <-> ETAccount', () {
      final originalAccount = Account(id: 'round-trip-test', name: 'Round Trip Account', type: 'com.roundtrip');
      final etAccount = originalAccount.toETAccount();
      final convertedAccount = etAccount.toAccount();

      expect(convertedAccount.id, originalAccount.id);
      expect(convertedAccount.name, originalAccount.name);
      expect(convertedAccount.type, originalAccount.type);
    });

    test('List<Account> toETAccountList', () {
      final accounts = [
        Account(id: '1', name: 'Account 1', type: 'type1'),
        Account(id: '2', name: 'Account 2', type: 'type2'),
      ];
      final etAccounts = accounts.toETAccountList();
      expect(etAccounts, hasLength(2));
      expect(etAccounts.first, const ETAccount(id: '1', name: 'Account 1', type: 'type1'));
    });
  });

  group('ColorToValue tests', () {
    test('Color toValue', () {
      const color = Color(0xFF123456);
      expect(color.toValue(), 0xFF123456);
    });
  });

  group('Android duration extensions (minutes)', () {
    test('int toDuration converts minutes', () {
      expect(10.toDuration(), const Duration(minutes: 10));
      expect((-10).toDuration(), const Duration(minutes: 10));
    });

    test('Duration toNativeDuration converts to minutes', () {
      expect(const Duration(minutes: 10).toNativeDuration(), 10);
    });

    test('Iterable conversions', () {
      expect([const Duration(minutes: 10), const Duration(minutes: 20)].toNativeList(), [10, 20]);
      expect([10, 20].toDurationList(), [const Duration(minutes: 10), const Duration(minutes: 20)]);
    });
  });
}
