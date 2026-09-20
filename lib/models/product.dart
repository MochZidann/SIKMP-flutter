class Product {
  final int id;
  final String name;
  final String? barcode;
  final String? category;
  final int price;
  final int stock;
  final String? imagePath;

  Product({
    required this.id,
    required this.name,
    this.barcode,
    this.category,
    required this.price,
    required this.stock,
    this.imagePath,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? 'Produk Tanpa Nama',
      barcode: json['barcode']?.toString(),
      category: json['category']?.toString(),
      price: json['price'] is int
          ? json['price']
          : (double.tryParse(json['price'].toString())?.toInt() ?? 0),
      stock: json['stock'] is int
          ? json['stock']
          : (double.tryParse(json['stock'].toString())?.toInt() ?? 0),
      imagePath: json['imagePath']?.toString(),
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
      'imagePath': imagePath,
    };
  }
}
