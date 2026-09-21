import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_kop/models/owner_models.dart';

void main() {
  group('Owner Domain Models Tests', () {
    test('OwnerDashboardData fromJson parses correctly with complete data', () {
      final json = {
        'todayRevenue': 1500000,
        'todayTxCount': 25,
        'yesterdayRevenue': 1200000,
        'yesterdayTxCount': 20,
        'revenueGrowthPercent': 25.0,
        'txGrowthPercent': 25.0,
        'lowStockCount': 3,
        'totalAssetValue': 15000000,
        'salesTrend': [
          {'date': '20 Sep', 'total': 1200000},
          {'date': '21 Sep', 'total': 1500000},
        ],
        'topProducts': [
          {'name': 'Beras 5kg', 'quantity': 10, 'totalRevenue': 650000},
        ],
        'recentSales': [
          {
            'id': 1,
            'transactionId': 'TRX-001',
            'cashierName': 'Kasir A',
            'paymentMethod': 'TUNAI',
            'total': 50000,
            'createdAtEpochMs': 1700000000000,
          },
        ],
      };

      final data = OwnerDashboardData.fromJson(json);

      expect(data.todayRevenue, 1500000);
      expect(data.todayTxCount, 25);
      expect(data.revenueGrowthPercent, 25.0);
      expect(data.lowStockCount, 3);
      expect(data.totalAssetValue, 15000000);
      expect(data.salesTrend.length, 2);
      expect(data.salesTrend.first.date, '20 Sep');
      expect(data.salesTrend.first.total, 1200000);
      expect(data.topProducts.first.name, 'Beras 5kg');
      expect(data.recentSales.first.transactionId, 'TRX-001');
    });

    test('OwnerDashboardData handles empty or missing keys gracefully', () {
      final data = OwnerDashboardData.fromJson({});

      expect(data.todayRevenue, 0);
      expect(data.todayTxCount, 0);
      expect(data.yesterdayRevenue, 0);
      expect(data.revenueGrowthPercent, 0.0);
      expect(data.lowStockCount, 0);
      expect(data.totalAssetValue, 0);
      expect(data.salesTrend, isEmpty);
      expect(data.topProducts, isEmpty);
      expect(data.recentSales, isEmpty);
    });

    test('OwnerSalesData fromJson parses sales and cashier performance', () {
      final json = {
        'filter': '7d',
        'filterLabel': '7 Hari Terakhir',
        'revenue': 5000000,
        'txCount': 50,
        'itemsSold': 120,
        'avgBasket': 100000,
        'cashierPerformance': [
          {
            'cashierId': 2,
            'cashierName': 'Siti Rahma',
            'txCount': 30,
            'totalRevenue': 3200000,
          },
        ],
        'sales': [
          {
            'id': 5,
            'transactionId': 'TRX-005',
            'cashierName': 'Siti Rahma',
            'paymentMethod': 'QRIS',
            'total': 100000,
            'discount': 5000,
            'itemCount': 3,
            'createdAtEpochMs': 1700000000000,
          },
        ],
      };

      final data = OwnerSalesData.fromJson(json);

      expect(data.filter, '7d');
      expect(data.filterLabel, '7 Hari Terakhir');
      expect(data.revenue, 5000000);
      expect(data.itemsSold, 120);
      expect(data.avgBasket, 100000);
      expect(data.cashierPerformance.length, 1);
      expect(data.cashierPerformance.first.cashierName, 'Siti Rahma');
      expect(data.cashierPerformance.first.txCount, 30);
      expect(data.sales.first.paymentMethod, 'QRIS');
      expect(data.sales.first.itemCount, 3);
    });

    test('OwnerInventoryData parses low stock, dead stock, and category assets', () {
      final json = {
        'totalAssetValue': 25000000,
        'totalSku': 150,
        'lowStockCount': 2,
        'deadStockCount': 1,
        'deadStockValue': 300000,
        'lowStockProducts': [
          {
            'id': 10,
            'barcode': '899123456',
            'name': 'Gula Pasir 1kg',
            'category': 'Sembako',
            'stock': 2,
            'minimumStock': 10,
            'unit': 'pcs',
            'price': 15000,
          },
        ],
        'deadStockProducts': [
          {
            'id': 20,
            'barcode': '899987654',
            'name': 'Buku Tulis Hardcover',
            'category': 'Alat Tulis',
            'stock': 15,
            'price': 20000,
            'value': 300000,
          },
        ],
        'assetByCategory': [
          {
            'category': 'Sembako',
            'skuCount': 50,
            'totalValue': 15000000,
            'percentage': 60.0,
          },
        ],
      };

      final data = OwnerInventoryData.fromJson(json);

      expect(data.totalAssetValue, 25000000);
      expect(data.totalSku, 150);
      expect(data.lowStockCount, 2);
      expect(data.deadStockCount, 1);
      expect(data.deadStockValue, 300000);

      expect(data.lowStockProducts.first.name, 'Gula Pasir 1kg');
      expect(data.lowStockProducts.first.stock, 2);
      expect(data.lowStockProducts.first.minimumStock, 10);

      expect(data.deadStockProducts.first.name, 'Buku Tulis Hardcover');
      expect(data.deadStockProducts.first.value, 300000);

      expect(data.assetByCategory.first.category, 'Sembako');
      expect(data.assetByCategory.first.percentage, 60.0);
    });
  });
}
