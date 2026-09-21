/// Model data tren penjualan harian
class SalesTrendItem {
  final String date;
  final int total;

  const SalesTrendItem({
    required this.date,
    required this.total,
  });

  factory SalesTrendItem.fromJson(Map<String, dynamic> json) {
    return SalesTrendItem(
      date: json['date']?.toString() ?? '',
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Model data produk terlaris
class TopProductItem {
  final String name;
  final int quantity;
  final int totalRevenue;

  const TopProductItem({
    required this.name,
    required this.quantity,
    required this.totalRevenue,
  });

  factory TopProductItem.fromJson(Map<String, dynamic> json) {
    return TopProductItem(
      name: json['name']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Model transaksi penjualan untuk ringkasan eksekutif
class OwnerRecentSaleItem {
  final int id;
  final String transactionId;
  final String cashierName;
  final String paymentMethod;
  final int total;
  final int discount;
  final int itemCount;
  final int createdAtEpochMs;

  const OwnerRecentSaleItem({
    required this.id,
    required this.transactionId,
    required this.cashierName,
    required this.paymentMethod,
    required this.total,
    this.discount = 0,
    this.itemCount = 0,
    required this.createdAtEpochMs,
  });

  factory OwnerRecentSaleItem.fromJson(Map<String, dynamic> json) {
    return OwnerRecentSaleItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      transactionId: json['transactionId']?.toString() ?? '',
      cashierName: json['cashierName']?.toString() ?? 'Kasir',
      paymentMethod: json['paymentMethod']?.toString() ?? 'TUNAI',
      total: (json['total'] as num?)?.toInt() ?? 0,
      discount: (json['discount'] as num?)?.toInt() ?? 0,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      createdAtEpochMs: (json['createdAtEpochMs'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Model performa dan kontribusi penjualan kasir
class CashierPerformanceItem {
  final int cashierId;
  final String cashierName;
  final int txCount;
  final int totalRevenue;

  const CashierPerformanceItem({
    required this.cashierId,
    required this.cashierName,
    required this.txCount,
    required this.totalRevenue,
  });

  factory CashierPerformanceItem.fromJson(Map<String, dynamic> json) {
    return CashierPerformanceItem(
      cashierId: (json['cashierId'] as num?)?.toInt() ?? 0,
      cashierName: json['cashierName']?.toString() ?? 'Kasir',
      txCount: (json['txCount'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Model response Dashboard Eksekutif
class OwnerDashboardData {
  final int todayRevenue;
  final int todayTxCount;
  final int yesterdayRevenue;
  final int yesterdayTxCount;
  final double revenueGrowthPercent;
  final double txGrowthPercent;
  final int lowStockCount;
  final int totalAssetValue;
  final List<SalesTrendItem> salesTrend;
  final List<TopProductItem> topProducts;
  final List<OwnerRecentSaleItem> recentSales;

  const OwnerDashboardData({
    required this.todayRevenue,
    required this.todayTxCount,
    required this.yesterdayRevenue,
    required this.yesterdayTxCount,
    required this.revenueGrowthPercent,
    required this.txGrowthPercent,
    required this.lowStockCount,
    required this.totalAssetValue,
    required this.salesTrend,
    required this.topProducts,
    required this.recentSales,
  });

  factory OwnerDashboardData.fromJson(Map<String, dynamic> json) {
    return OwnerDashboardData(
      todayRevenue: (json['todayRevenue'] as num?)?.toInt() ?? 0,
      todayTxCount: (json['todayTxCount'] as num?)?.toInt() ?? 0,
      yesterdayRevenue: (json['yesterdayRevenue'] as num?)?.toInt() ?? 0,
      yesterdayTxCount: (json['yesterdayTxCount'] as num?)?.toInt() ?? 0,
      revenueGrowthPercent: (json['revenueGrowthPercent'] as num?)?.toDouble() ?? 0.0,
      txGrowthPercent: (json['txGrowthPercent'] as num?)?.toDouble() ?? 0.0,
      lowStockCount: (json['lowStockCount'] as num?)?.toInt() ?? 0,
      totalAssetValue: (json['totalAssetValue'] as num?)?.toInt() ?? 0,
      salesTrend: (json['salesTrend'] as List<dynamic>?)
              ?.map((e) => SalesTrendItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topProducts: (json['topProducts'] as List<dynamic>?)
              ?.map((e) => TopProductItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentSales: (json['recentSales'] as List<dynamic>?)
              ?.map((e) => OwnerRecentSaleItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Model response Laporan Penjualan
class OwnerSalesData {
  final String filter;
  final String filterLabel;
  final int revenue;
  final int txCount;
  final int itemsSold;
  final int avgBasket;
  final List<CashierPerformanceItem> cashierPerformance;
  final List<OwnerRecentSaleItem> sales;

  const OwnerSalesData({
    required this.filter,
    required this.filterLabel,
    required this.revenue,
    required this.txCount,
    required this.itemsSold,
    required this.avgBasket,
    required this.cashierPerformance,
    required this.sales,
  });

  factory OwnerSalesData.fromJson(Map<String, dynamic> json) {
    return OwnerSalesData(
      filter: json['filter']?.toString() ?? 'today',
      filterLabel: json['filterLabel']?.toString() ?? 'Hari Ini',
      revenue: (json['revenue'] as num?)?.toInt() ?? 0,
      txCount: (json['txCount'] as num?)?.toInt() ?? 0,
      itemsSold: (json['itemsSold'] as num?)?.toInt() ?? 0,
      avgBasket: (json['avgBasket'] as num?)?.toInt() ?? 0,
      cashierPerformance: (json['cashierPerformance'] as List<dynamic>?)
              ?.map((e) => CashierPerformanceItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sales: (json['sales'] as List<dynamic>?)
              ?.map((e) => OwnerRecentSaleItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Model produk dengan stok menipis (kritis)
class LowStockProductItem {
  final int id;
  final String barcode;
  final String name;
  final String category;
  final int stock;
  final int minimumStock;
  final String unit;
  final int price;

  const LowStockProductItem({
    required this.id,
    required this.barcode,
    required this.name,
    required this.category,
    required this.stock,
    required this.minimumStock,
    this.unit = 'pcs',
    required this.price,
  });

  factory LowStockProductItem.fromJson(Map<String, dynamic> json) {
    return LowStockProductItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      barcode: json['barcode']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Umum',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      minimumStock: (json['minimumStock'] as num?)?.toInt() ?? 0,
      unit: json['unit']?.toString() ?? 'pcs',
      price: (json['price'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Model barang dead stock (>30 hari tidak bergerak)
class DeadStockProductItem {
  final int id;
  final String barcode;
  final String name;
  final String category;
  final int stock;
  final int price;
  final int value;

  const DeadStockProductItem({
    required this.id,
    required this.barcode,
    required this.name,
    required this.category,
    required this.stock,
    required this.price,
    required this.value,
  });

  factory DeadStockProductItem.fromJson(Map<String, dynamic> json) {
    return DeadStockProductItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      barcode: json['barcode']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Umum',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toInt() ?? 0,
      value: (json['value'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Model sebaran nilai aset berdasarkan kategori produk
class CategoryAssetItem {
  final String category;
  final int skuCount;
  final int totalValue;
  final double percentage;

  const CategoryAssetItem({
    required this.category,
    required this.skuCount,
    required this.totalValue,
    required this.percentage,
  });

  factory CategoryAssetItem.fromJson(Map<String, dynamic> json) {
    return CategoryAssetItem(
      category: json['category']?.toString() ?? 'Umum',
      skuCount: (json['skuCount'] as num?)?.toInt() ?? 0,
      totalValue: (json['totalValue'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Model response Kesehatan Inventori & Valuasi Aset
class OwnerInventoryData {
  final int totalAssetValue;
  final int totalSku;
  final int lowStockCount;
  final int deadStockCount;
  final int deadStockValue;
  final List<LowStockProductItem> lowStockProducts;
  final List<DeadStockProductItem> deadStockProducts;
  final List<CategoryAssetItem> assetByCategory;

  const OwnerInventoryData({
    required this.totalAssetValue,
    required this.totalSku,
    required this.lowStockCount,
    required this.deadStockCount,
    required this.deadStockValue,
    required this.lowStockProducts,
    required this.deadStockProducts,
    required this.assetByCategory,
  });

  factory OwnerInventoryData.fromJson(Map<String, dynamic> json) {
    return OwnerInventoryData(
      totalAssetValue: (json['totalAssetValue'] as num?)?.toInt() ?? 0,
      totalSku: (json['totalSku'] as num?)?.toInt() ?? 0,
      lowStockCount: (json['lowStockCount'] as num?)?.toInt() ?? 0,
      deadStockCount: (json['deadStockCount'] as num?)?.toInt() ?? 0,
      deadStockValue: (json['deadStockValue'] as num?)?.toInt() ?? 0,
      lowStockProducts: (json['lowStockProducts'] as List<dynamic>?)
              ?.map((e) => LowStockProductItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      deadStockProducts: (json['deadStockProducts'] as List<dynamic>?)
              ?.map((e) => DeadStockProductItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      assetByCategory: (json['assetByCategory'] as List<dynamic>?)
              ?.map((e) => CategoryAssetItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
