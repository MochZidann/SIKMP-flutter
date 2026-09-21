class AuthUser {
  final int id;
  final String name;
  final String username;
  final String role;

  final bool isActive;

  AuthUser({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    this.isActive = true,
  });

  AuthUser copyWith({
    int? id,
    String? name,
    String? username,
    String? role,
    bool? isActive,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    bool active = true;
    if (json.containsKey('isActive')) {
      final v = json['isActive'];
      active = v == 1 || v == true || v == '1';
    } else if (json.containsKey('is_active')) {
      final v = json['is_active'];
      active = v == 1 || v == true || v == '1';
    }

    return AuthUser(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      isActive: active,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'role': role,
      'isActive': isActive ? 1 : 0,
    };
  }

  bool get isKasir => role == 'KASIR';
  bool get isAdmin => role == 'ADMIN_SISTEM';
  bool get isGudang => role == 'ADMIN_GUDANG';
  bool get isOwner => role == 'OWNER_PENGAWAS';

  String get roleLabel {
    switch (role) {
      case 'ADMIN_SISTEM':
        return 'Admin Sistem';
      case 'ADMIN_GUDANG':
        return 'Admin Gudang';
      case 'KASIR':
        return 'Kasir';
      case 'OWNER_PENGAWAS':
        return 'Owner / Pengawas';
      default:
        return role;
    }
  }
}
