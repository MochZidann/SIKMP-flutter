class ProductSupplierItem {
  final int id;
  final String name;
  final String? code;
  final int totalIn;
  final int totalOut;
  final int netAvailable;
  final String? lastInDate;
  final String? lastRef;

  const ProductSupplierItem({
    required this.id,
    required this.name,
    this.code,
    required this.totalIn,
    required this.totalOut,
    required this.netAvailable,
    this.lastInDate,
    this.lastRef,
  });

  factory ProductSupplierItem.fromJson(Map<String, dynamic> json) {
    return ProductSupplierItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'Supplier',
      code: json['code']?.toString(),
      totalIn: (json['total_in'] is num)
          ? (json['total_in'] as num).toInt()
          : int.tryParse(json['total_in']?.toString() ?? '0') ?? 0,
      totalOut: (json['total_out'] is num)
          ? (json['total_out'] as num).toInt()
          : int.tryParse(json['total_out']?.toString() ?? '0') ?? 0,
      netAvailable: (json['net_available'] is num)
          ? (json['net_available'] as num).toInt()
          : int.tryParse(json['net_available']?.toString() ?? '0') ?? 0,
      lastInDate: json['last_in_date']?.toString(),
      lastRef: json['last_ref']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'total_in': totalIn,
    'total_out': totalOut,
    'net_available': netAvailable,
    'last_in_date': lastInDate,
    'last_ref': lastRef,
  };
}

