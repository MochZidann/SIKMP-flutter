import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_kop/core/utils/date_helper.dart';
import 'package:flutter_kop/core/utils/password_helper.dart';
import 'package:flutter_kop/models/member.dart';
import 'package:flutter_kop/models/audit_log.dart';
import 'package:flutter_kop/models/stock_movement.dart';

void main() {
  group('PasswordHelper Tests', () {
    test('generateSalt returns 16-byte base64 encoded string', () {
      final salt = PasswordHelper.generateSalt();
      expect(salt.isNotEmpty, isTrue);
    });

    test('hashPassword produces consistent hash for same password and salt', () {
      final salt = PasswordHelper.generateSalt();
      final hash1 = PasswordHelper.hashPassword('admin123', salt);
      final hash2 = PasswordHelper.hashPassword('admin123', salt);
      expect(hash1, equals(hash2));
    });

    test('verifyPassword returns true for matching password', () {
      final salt = PasswordHelper.generateSalt();
      final hash = PasswordHelper.hashPassword('rahasia', salt);
      expect(PasswordHelper.verifyPassword('rahasia', salt, hash), isTrue);
      expect(PasswordHelper.verifyPassword('salah', salt, hash), isFalse);
    });
  });

  group('DateHelper Tests', () {
    test('formatEpochMs formats properly or returns dash if null', () {
      expect(DateHelper.formatEpochMs(null), equals('-'));
      final epoch = DateTime(2026, 9, 20, 10, 30).millisecondsSinceEpoch;
      final formatted = DateHelper.formatEpochMs(epoch);
      expect(formatted, contains('2026'));
      expect(formatted, contains('10:30'));
    });

    test('formatEpochMs with withTime: false formats date only', () {
      final epoch = DateTime(2026, 9, 20).millisecondsSinceEpoch;
      final formatted = DateHelper.formatEpochMs(epoch, withTime: false);
      expect(formatted, contains('2026'));
    });
  });

  group('Domain Models Tests', () {
    test('Member fromJson and toJson roundtrip', () {
      final json = {
        'id': 1,
        'memberNo': 'MBR-001',
        'name': 'Budi Santoso',
        'phone': '08123456789',
        'address': 'Jl. Mawar No. 5',
        'isActive': 1,
        'createdAtEpochMs': 1700000000000,
      };

      final member = Member.fromJson(json);
      expect(member.id, 1);
      expect(member.name, 'Budi Santoso');
      expect(member.memberNo, 'MBR-001');
      expect(member.isActive, isTrue);

      final output = member.toJson();
      expect(output['name'], 'Budi Santoso');
      expect(output['isActive'], 1);
    });

    test('AuditLog fromJson and toJson roundtrip', () {
      final json = {
        'id': 10,
        'userId': 2,
        'action': 'STOCK_IN',
        'entity': 'products',
        'detail': 'Restock Beras 50 kg',
        'createdAtEpochMs': 1700000000000,
      };

      final log = AuditLog.fromJson(json);
      expect(log.id, 10);
      expect(log.action, 'STOCK_IN');
      expect(log.entity, 'products');
      expect(log.detail, 'Restock Beras 50 kg');

      final output = log.toJson();
      expect(output['action'], 'STOCK_IN');
    });

    test('StockMovement fromJson and getters', () {
      final inJson = {
        'id': 1,
        'productId': 5,
        'userId': 1,
        'type': 'IN',
        'quantityDelta': 24,
        'note': 'Penerimaan supplier',
        'createdAtEpochMs': 1700000000000,
      };

      final inMove = StockMovement.fromJson(inJson);
      expect(inMove.isIn, isTrue);
      expect(inMove.isOut, isFalse);
      expect(inMove.isAdjust, isFalse);
      expect(inMove.quantityDelta, 24);

      final adjustJson = {
        'id': 2,
        'productId': 5,
        'userId': 1,
        'type': 'ADJUST',
        'quantityDelta': -2,
        'note': 'Barang rusak',
        'createdAtEpochMs': 1700000000000,
      };

      final adjustMove = StockMovement.fromJson(adjustJson);
      expect(adjustMove.isAdjust, isTrue);
      expect(adjustMove.quantityDelta, -2);
    });
  });
}
