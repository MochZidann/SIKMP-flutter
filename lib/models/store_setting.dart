class StoreSetting {
  final int? id;
  final String koperasiName;
  final String koperasiAddress;
  final String koperasiPhone;
  final double taxPercent;
  final double discountPercent;
  final int? updatedAtEpochMs;

  const StoreSetting({
    this.id,
    required this.koperasiName,
    this.koperasiAddress = '',
    this.koperasiPhone = '',
    this.taxPercent = 0.0,
    this.discountPercent = 0.0,
    this.updatedAtEpochMs,
  });

  factory StoreSetting.fromJson(Map<String, dynamic> json) {
    return StoreSetting(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      koperasiName: json['koperasiName']?.toString() ?? json['koperasi_name']?.toString() ?? 'Koperasi Desa Jajar',
      koperasiAddress: json['koperasiAddress']?.toString() ?? json['koperasi_address']?.toString() ?? '',
      koperasiPhone: json['koperasiPhone']?.toString() ?? json['koperasi_phone']?.toString() ?? '',
      taxPercent: json['taxPercent'] != null
          ? double.tryParse(json['taxPercent'].toString()) ?? 0.0
          : double.tryParse(json['tax_percent']?.toString() ?? '0') ?? 0.0,
      discountPercent: json['discountPercent'] != null
          ? double.tryParse(json['discountPercent'].toString()) ?? 0.0
          : double.tryParse(json['discount_percent']?.toString() ?? '0') ?? 0.0,
      updatedAtEpochMs: json['updatedAtEpochMs'] is int
          ? json['updatedAtEpochMs']
          : int.tryParse(json['updated_at_epoch_ms']?.toString() ?? json['updatedAtEpochMs']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'koperasiName': koperasiName,
      'koperasiAddress': koperasiAddress,
      'koperasiPhone': koperasiPhone,
      'taxPercent': taxPercent,
      'discountPercent': discountPercent,
      if (updatedAtEpochMs != null) 'updatedAtEpochMs': updatedAtEpochMs,
    };
  }

  StoreSetting copyWith({
    int? id,
    String? koperasiName,
    String? koperasiAddress,
    String? koperasiPhone,
    double? taxPercent,
    double? discountPercent,
    int? updatedAtEpochMs,
  }) {
    return StoreSetting(
      id: id ?? this.id,
      koperasiName: koperasiName ?? this.koperasiName,
      koperasiAddress: koperasiAddress ?? this.koperasiAddress,
      koperasiPhone: koperasiPhone ?? this.koperasiPhone,
      taxPercent: taxPercent ?? this.taxPercent,
      discountPercent: discountPercent ?? this.discountPercent,
      updatedAtEpochMs: updatedAtEpochMs ?? this.updatedAtEpochMs,
    );
  }
}
