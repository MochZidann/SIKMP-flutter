class Member {
  final int id;
  final String memberNo;
  final String name;
  final String? phone;
  final String? address;
  final bool isActive;
  final int? createdAtEpochMs;

  const Member({
    required this.id,
    required this.memberNo,
    required this.name,
    this.phone,
    this.address,
    this.isActive = true,
    this.createdAtEpochMs,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      memberNo: json['memberNo']?.toString() ?? json['member_no']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      isActive: json['isActive'] == 1 || json['isActive'] == true || json['is_active'] == 1 || json['is_active'] == true,
      createdAtEpochMs: json['createdAtEpochMs'] is int
          ? json['createdAtEpochMs']
          : int.tryParse(json['created_at_epoch_ms']?.toString() ?? json['createdAtEpochMs']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memberNo': memberNo,
      'name': name,
      'phone': phone,
      'address': address,
      'isActive': isActive ? 1 : 0,
      'createdAtEpochMs': createdAtEpochMs,
    };
  }
}
