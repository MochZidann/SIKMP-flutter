class AuthUser {
  final int id;
  final String name;
  final String username;
  final String role;

  AuthUser({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'role': role,
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
