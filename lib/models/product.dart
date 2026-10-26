class Product {
  final int id;
  final String name;
  final String? barcode;
  final String? category;
  final int price;
  final int? memberPrice;
  final int stock;
  final int purchasePrice;
  final int minimumStock;
  final String? imagePath;
  final bool isExpired;
  final int? sellableStock;
  final String? expiredDate;

  Product({
    required this.id,
    required this.name,
    this.barcode,
    this.category,
    required this.price,
    this.memberPrice,
    required this.stock,
    this.purchasePrice = 0,
    this.minimumStock = 5,
    this.imagePath,
    this.isExpired = false,
    this.sellableStock,
    this.expiredDate,
  });

  bool get isOutOfStock => (sellableStock != null ? sellableStock! <= 0 : stock <= 0) || isExpired;
  bool get isLowStock => (sellableStock ?? stock) > 0 && (sellableStock ?? stock) < 5;

  Product copyWith({
    int? id,
    String? name,
    String? barcode,
    String? category,
    int? price,
    int? memberPrice,
    int? stock,
    int? purchasePrice,
    int? minimumStock,
    String? imagePath,
    bool? isExpired,
    int? sellableStock,
    String? expiredDate,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      price: price ?? this.price,
      memberPrice: memberPrice ?? this.memberPrice,
      stock: stock ?? this.stock,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      minimumStock: minimumStock ?? this.minimumStock,
      imagePath: imagePath ?? this.imagePath,
      isExpired: isExpired ?? this.isExpired,
      sellableStock: sellableStock ?? this.sellableStock,
      expiredDate: expiredDate ?? this.expiredDate,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      name: json['name']?.toString() ?? 'Produk Tanpa Nama',
      barcode: json['barcode']?.toString(),
      category: json['category']?.toString(),
      price: json['price'] is int
          ? json['price']
          : (double.tryParse(json['price']?.toString() ?? '0')?.toInt() ?? 0),
      memberPrice: json['memberPrice'] is int
          ? json['memberPrice']
          : (json['member_price'] is int
              ? json['member_price']
              : (json['memberPrice'] != null || json['member_price'] != null
                  ? double.tryParse(json['memberPrice']?.toString() ?? json['member_price']?.toString() ?? '')?.toInt()
                  : null)),
      stock: json['stock'] is int
          ? json['stock']
          : (double.tryParse(json['stock']?.toString() ?? '0')?.toInt() ?? 0),
      purchasePrice: json['purchasePrice'] is int
          ? json['purchasePrice']
          : (json['purchase_price'] is int
              ? json['purchase_price']
              : (double.tryParse(json['purchasePrice']?.toString() ?? json['purchase_price']?.toString() ?? '0')?.toInt() ?? 0)),
      minimumStock: json['minimumStock'] is int
          ? json['minimumStock']
          : (json['minimum_stock'] is int
              ? json['minimum_stock']
              : (int.tryParse(json['minimumStock']?.toString() ?? json['minimum_stock']?.toString() ?? '5') ?? 5)),
      imagePath: json['imagePath']?.toString() ?? json['image_path']?.toString(),
      isExpired: json['is_expired'] == true || json['isExpired'] == true,
      sellableStock: json['sellable_stock'] is int
          ? json['sellable_stock']
          : (json['sellableStock'] is int
              ? json['sellableStock']
              : int.tryParse(json['sellable_stock']?.toString() ?? json['sellableStock']?.toString() ?? '')),
      expiredDate: json['expired_date']?.toString() ?? json['expiredDate']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'category': category,
      'price': price,
      'memberPrice': memberPrice,
      'stock': stock,
      'purchasePrice': purchasePrice,
      'minimumStock': minimumStock,
      'imagePath': imagePath,
      'is_expired': isExpired,
      'sellable_stock': sellableStock,
      'expired_date': expiredDate,
    };
  }
}
