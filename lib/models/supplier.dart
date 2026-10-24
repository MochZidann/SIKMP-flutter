class Supplier {
  final int id;
  final String code;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final String? note;
  final bool isActive;
  final int totalIn;
  final int totalOut;
  final int totalTransactions;

  const Supplier({
    required this.id,
    required this.code,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.note,
    this.isActive = true,
    this.totalIn = 0,
    this.totalOut = 0,
    this.totalTransactions = 0,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      contactPerson: json['contact_person']?.toString() ?? json['contactPerson']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      note: json['note']?.toString(),
      isActive: json['is_active'] == 1 || json['is_active'] == true || json['isActive'] == true,
      totalIn: (json['total_in'] is num)
          ? (json['total_in'] as num).toInt()
          : int.tryParse(json['total_in']?.toString() ?? '0') ?? 0,
      totalOut: (json['total_out'] is num)
          ? (json['total_out'] as num).toInt()
          : int.tryParse(json['total_out']?.toString() ?? '0') ?? 0,
      totalTransactions: (json['total_transactions'] is num)
          ? (json['total_transactions'] as num).toInt()
          : int.tryParse(json['total_transactions']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'note': note,
      'is_active': isActive,
    };
  }
}
