class Product {
  final int id;
  final String name;
  final String? barcode;
  final String? category;
  final int price;
  final int stock;
  final int purchasePrice;
  final int minimumStock;
  final String? imagePath;

  Product({
    required this.id,
    required this.name,
    this.barcode,
    this.category,
    required this.price,
    required this.stock,
    this.purchasePrice = 0,
    this.minimumStock = 5,
    this.imagePath,
  });

  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => stock > 0 && stock < 5;

  Product copyWith({
    int? id,
    String? name,
    String? barcode,
    String? category,
    int? price,
    int? stock,
    int? purchasePrice,
    int? minimumStock,
    String? imagePath,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      minimumStock: minimumStock ?? this.minimumStock,
      imagePath: imagePath ?? this.imagePath,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'category': category,
      'price': price,
      'stock': stock,
      'purchasePrice': purchasePrice,
      'minimumStock': minimumStock,
      'imagePath': imagePath,
    };
  }
}
