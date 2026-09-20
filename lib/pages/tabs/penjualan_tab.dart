import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/sale_record.dart';
import '../../services/auth_service.dart';
import '../../services/pos_service.dart';

class PenjualanTab extends StatefulWidget {
  const PenjualanTab({super.key});

  @override
  State<PenjualanTab> createState() => _PenjualanTabState();
}

class _PenjualanTabState extends State<PenjualanTab> {
  final PosService _posService = PosService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  List<SaleRecord> _sales = [];
  bool _filterTodayOnly = true;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    final user = AuthService().currentUser;
    final dateParam = _filterTodayOnly
        ? DateFormat('yyyy-MM-dd').format(DateTime.now())
        : null;

    final result = await _posService.getSales(
      cashierId: user?.id,
      date: dateParam,
    );

    if (mounted) {
      setState(() {
        _sales = result['sales'] as List<SaleRecord>? ?? [];
        _isLoading = false;
      });
    }
  }

  String _formatDateTimeIndonesian(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];

    try {
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
    } catch (_) {
      final monthName = months[date.month - 1];
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '${date.day.toString().padLeft(2, '0')} $monthName ${date.year}, $hour:$minute';
    }
  }

  void _showSaleDetailModal(SaleRecord sale) {
    final dateStr = _formatDateTimeIndonesian(
      DateTime.fromMillisecondsSinceEpoch(sale.createdAtEpochMs),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rincian Transaksi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B2B2B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sale.transactionId,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: sale.paymentMethod == 'QRIS'
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: sale.paymentMethod == 'QRIS'
                            ? const Color(0xFFD32F2F)
                            : Colors.green,
                      ),
                    ),
                    child: Text(
                      sale.paymentMethod,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: sale.paymentMethod == 'QRIS'
                            ? const Color(0xFFD32F2F)
                            : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Info Waktu & Kasir
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Waktu: $dateStr',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  Text('Kasir: ${sale.cashierName ?? 'Kasir'}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 14),

              // Daftar Item
              const Text(
                'Daftar Barang:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              if (sale.items.isEmpty)
                Text(
                  'Nominal Langsung (Quick Amount)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                )
              else
                ...sale.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.productName} x${item.quantity}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          _currencyFormat.format(item.lineTotal),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Pembayaran',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _currencyFormat.format(sale.total),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Tombol Cetak Struk
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Menghubungkan ke Printer Bluetooth...'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.print_rounded, size: 18),
                  label: const Text('Cetak Struk'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD32F2F),
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Riwayat Penjualan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Segarkan Data',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadSales,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── FILTER BAR HARI INI / SEMUA ──────────────────────────────────
          Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Row(
            children: [
              FilterChip(
                showCheckmark: false,
                label: const Text('Hari Ini'),
                selected: _filterTodayOnly,
                selectedColor: const Color(0xFFD32F2F),
                labelStyle: TextStyle(
                  color: _filterTodayOnly ? Colors.white : const Color(0xFF333333),
                  fontWeight:
                      _filterTodayOnly ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
                onSelected: (val) {
                  setState(() => _filterTodayOnly = true);
                  _loadSales();
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                showCheckmark: false,
                label: const Text('Semua Transaksi'),
                selected: !_filterTodayOnly,
                selectedColor: const Color(0xFFD32F2F),
                labelStyle: TextStyle(
                  color: !_filterTodayOnly ? Colors.white : const Color(0xFF333333),
                  fontWeight:
                      !_filterTodayOnly ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
                onSelected: (val) {
                  setState(() => _filterTodayOnly = false);
                  _loadSales();
                },
              ),
              const Spacer(),
              Text(
                '${_sales.length} Transaksi',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // ── LIST TRANSAKSI ───────────────────────────────────────────────
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD32F2F)),
                )
              : _sales.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            _filterTodayOnly
                                ? 'Belum ada transaksi penjualan hari ini.'
                                : 'Belum ada data penjualan.',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFFD32F2F),
                      onRefresh: _loadSales,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _sales.length,
                        itemBuilder: (context, index) {
                          final sale = _sales[index];
                          final dateStr =
                              DateFormat('dd/MM HH:mm').format(
                            DateTime.fromMillisecondsSinceEpoch(
                                sale.createdAtEpochMs),
                          );

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              onTap: () => _showSaleDetailModal(sale),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: sale.paymentMethod == 'QRIS'
                                    ? Colors.red.shade50
                                    : Colors.green.shade50,
                                child: Icon(
                                  sale.paymentMethod == 'QRIS'
                                      ? Icons.qr_code_2_rounded
                                      : Icons.payments_outlined,
                                  color: sale.paymentMethod == 'QRIS'
                                      ? const Color(0xFFD32F2F)
                                      : Colors.green,
                                  size: 20,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      sale.transactionId,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'LUNAS',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 3),
                                  Text(
                                    '$dateStr • ${sale.items.length} item • ${sale.paymentMethod}',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                _currencyFormat.format(sale.total),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFD32F2F),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    ),
  );
}
}
