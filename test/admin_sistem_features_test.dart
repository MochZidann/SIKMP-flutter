import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_kop/models/auth_user.dart';
import 'package:flutter_kop/models/store_setting.dart';
import 'package:flutter_kop/services/admin_service.dart';

void main() {
  group('Admin Sistem Models & Security Unit Tests', () {
    test('AuthUser correctly parses isActive and copyWith preserves state', () {
      final jsonActive = {
        'id': 1,
        'name': 'Administrator',
        'username': 'admin',
        'role': 'ADMIN_SISTEM',
        'isActive': 1,
      };

      final userActive = AuthUser.fromJson(jsonActive);
      expect(userActive.id, 1);
      expect(userActive.isActive, isTrue);
      expect(userActive.isAdmin, isTrue);

      final jsonInactive = {
        'id': 2,
        'name': 'Kasir Dua',
        'username': 'kasir2',
        'role': 'KASIR',
        'isActive': 0,
      };

      final userInactive = AuthUser.fromJson(jsonInactive);
      expect(userInactive.isActive, isFalse);
      expect(userInactive.isKasir, isTrue);

      final toggled = userInactive.copyWith(isActive: true);
      expect(toggled.isActive, isTrue);
      expect(toggled.username, 'kasir2');
    });

    test('StoreSetting parses data correctly and converts to JSON', () {
      final json = {
        'id': 10,
        'koperasiName': 'Koperasi Maju Sejahtera',
        'koperasiAddress': 'Jl. Pahlawan No. 45',
        'koperasiPhone': '08129876543',
        'taxPercent': 11.0,
        'discountPercent': 5.0,
        'updatedAtEpochMs': 1774184833000,
      };

      final setting = StoreSetting.fromJson(json);
      expect(setting.id, 10);
      expect(setting.koperasiName, 'Koperasi Maju Sejahtera');
      expect(setting.taxPercent, 11.0);
      expect(setting.discountPercent, 5.0);

      final exportedJson = setting.toJson();
      expect(exportedJson['koperasiName'], 'Koperasi Maju Sejahtera');
      expect(exportedJson['taxPercent'], 11.0);
      expect(exportedJson['discountPercent'], 5.0);
    });

    test('AdminService generates correct adminBaseUrl and syncBaseUrl', () {
      final adminService = AdminService();
      expect(adminService.adminBaseUrl.endsWith('/admin'), isTrue);
      expect(adminService.syncBaseUrl.endsWith('/sync'), isTrue);
    });
  });
}
