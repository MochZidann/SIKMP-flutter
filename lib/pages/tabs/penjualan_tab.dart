import '../pos/widgets/pos_return_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/app_skeleton.dart';
import '../../core/widgets/app_top_bar_title.dart';
import '../../models/sale_record.dart';
import '../../services/auth_service.dart';
import '../../services/pos_service.dart';

class PenjualanTab extends StatefulWidget {
  const PenjualanTab({super.key});

  @override
  PenjualanTabState createState() => PenjualanTabState();
}

class PenjualanTabState extends State<PenjualanTab> {
  final PosService _posService = PosService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  List<SaleRecord> _sales = [];
  bool _filterTodayOnly = true;

  /// Memuat ulang riwayat penjualan kasir dari server
  Future<void> reload() async {
    await _loadSales();
  }

  // â”€â”€ FITUR DATEPICKER & TIMEPICKER â”€â”€
  DateTime? _selectedFilterDate;
  TimeOfDay? _selectedFilterTime;

  // â”€â”€ FITUR CONTEXTMENU (POSISI TAP) â”€â”€
  Offset? _lastTapDownPosition;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    final user = AuthService().currentUser;
    String? dateParam;

    if (_selectedFilterDate != null) {
      dateParam = DateFormat('yyyy-MM-dd').format(_selectedFilterDate!);
    } else if (_filterTodayOnly) {
      dateParam = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }

    final result = await _posService.getSales(
      cashierId: user?.id,
      date: dateParam,
    );

    if (mounted) {
      List<SaleRecord> list = result['sales'] as List<SaleRecord>? ?? [];

      // Filter jam transaksi jika _selectedFilterTime diatur
      if (_selectedFilterTime != null) {
        list = list.where((s) {
          final dt = DateTime.fromMillisecondsSinceEpoch(s.createdAtEpochMs);
          return dt.hour == _selectedFilterTime!.hour;
        }).toList();
      }

      setState(() {
        _sales = list;
        _isLoading = false;
      });
    }
  }

  /// â”€â”€ FITUR DATEPICKER & TIMEPICKER DALAM 1 ALUR â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _pickDateTimeFilterCombined() async {
    // 1. Munculkan showDatePicker() terlebih dahulu
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedFilterDate ?? DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2035),
      helpText: 'LANGKAH 1/2: PILIH TANGGAL TRANSAKSI',
      cancelText: 'Batal',
      confirmText: 'Lanjut ke Jam',
    );

    if (pickedDate == null || !mounted) return;

    // 2. Langsung lanjutkan memunculkan showTimePicker() untuk jam
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedFilterTime ?? TimeOfDay.now(),
      helpText: 'LANGKAH 2/2: PILIH JAM TRANSAKSI',
      cancelText: 'Lewati Jam',
      confirmText: 'Terapkan Filter',
    );

    if (!mounted) return;

    setState(() {
      _selectedFilterDate = pickedDate;
      _selectedFilterTime = pickedTime;
      _filterTodayOnly = false;
    });
    _loadSales();
  }

  /// â”€â”€ FITUR DATEPICKER DIALOG â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _pickDateFilter() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedFilterDate ?? DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2035),
      helpText: 'Pilih Tanggal Transaksi',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (picked != null) {
      setState(() {
        _selectedFilterDate = picked;
        _filterTodayOnly = false;
      });
      _loadSales();
    }
  }

  /// â”€â”€ FITUR TIMEPICKER DIALOG â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _pickTimeFilter() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedFilterTime ?? TimeOfDay.now(),
      helpText: 'Pilih Jam Transaksi',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (picked != null) {
      setState(() {
        _selectedFilterTime = picked;
      });
      _loadSales();
    }
  }

  void _resetDateTimeFilter() {
    setState(() {
      _selectedFilterDate = null;
      _selectedFilterTime = null;
      _filterTodayOnly = true;
    });
    _loadSales();
  }

  /// â”€â”€ FITUR CONTEXTMENU (showMenu pada onLongPress) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _showTransactionContextMenu(
    Offset tapPosition,
    SaleRecord sale,
  ) async {
    HapticFeedback.mediumImpact();
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        tapPosition.dx,
        tapPosition.dy,
        tapPosition.dx + 1,
        tapPosition.dy + 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 6,
      items: const [
        PopupMenuItem(
          value: 'detail',
          child: Row(
            children: [
              Icon(Icons.receipt_long_rounded, size: 18, color: Color(0xFFD32F2F)),
              SizedBox(width: 10),
              Text('Lihat Rincian', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.copy_rounded, size: 18, color: Colors.blueGrey),
              SizedBox(width: 10),
              Text('Salin No. Struk', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'print',
          child: Row(
            children: [
              Icon(Icons.print_rounded, size: 18, color: Colors.green),
              SizedBox(width: 10),
              Text('Cetak Struk Transaksi', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );

    if (!mounted || selected == null) return;
    if (selected == 'return') {
      PosReturnDialog.show(
        context,
        sale: sale,
        onReturnSuccess: _loadSales,
      );
    } else if (selected == 'detail') {
      _showSaleDetailModal(sale);
    } else if (selected == 'copy') {
      await Clipboard.setData(ClipboardData(text: sale.transactionId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nomor struk ${sale.transactionId} disalin ke clipboard!'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else if (selected == 'print') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menghubungkan ke Printer Thermal Bluetooth...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
        title: const AppTopBarTitle(roleName: 'Kasir'),
        actions: [
          // â”€â”€ MENU FILTER TANGGAL & WAKTU DI NAVBAR KANAN ATAS â”€â”€
          PopupMenuButton<String>(
            tooltip: 'Filter Tanggal & Jam Penjualan',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.filter_alt_outlined, color: Colors.white),
                if (_selectedFilterDate != null || _selectedFilterTime != null)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Colors.amberAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD32F2F), width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            onSelected: (val) {
              if (val == 'combined') {
                _pickDateTimeFilterCombined();
              } else if (val == 'date') {
                _pickDateFilter();
              } else if (val == 'time') {
                _pickTimeFilter();
              } else if (val == 'today') {
                setState(() {
                  _filterTodayOnly = true;
                  _selectedFilterDate = null;
                  _selectedFilterTime = null;
                });
                _loadSales();
              } else if (val == 'all') {
                setState(() {
                  _filterTodayOnly = false;
                  _selectedFilterDate = null;
                  _selectedFilterTime = null;
                });
                _loadSales();
              } else if (val == 'reset') {
                _resetDateTimeFilter();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'combined',
                child: Row(
                  children: [
                    Icon(Icons.event_available_rounded, color: Color(0xFFD32F2F), size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Pilih Tanggal & Jam (1 Alur)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            'DatePicker -> TimePicker berurutan',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'date',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: Color(0xFF1976D2), size: 20),
                    SizedBox(width: 12),
                    Text('Pilih Tanggal Saja (DatePicker)', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'time',
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: Color(0xFF388E3C), size: 20),
                    SizedBox(width: 12),
                    Text('Pilih Jam Saja (TimePicker)', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'today',
                child: Row(
                  children: [
                    Icon(
                      Icons.today_rounded,
                      color: (_filterTodayOnly && _selectedFilterDate == null)
                          ? const Color(0xFFD32F2F)
                          : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Hari Ini Saja',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: (_filterTodayOnly && _selectedFilterDate == null)
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(
                      Icons.all_inclusive_rounded,
                      color: (!_filterTodayOnly && _selectedFilterDate == null)
                          ? const Color(0xFFD32F2F)
                          : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Semua Transaksi',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: (!_filterTodayOnly && _selectedFilterDate == null)
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedFilterDate != null || _selectedFilterTime != null) ...[
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'reset',
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt_off_rounded, color: Colors.red, size: 20),
                      SizedBox(width: 12),
                      Text('Reset Filter', style: TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // â”€â”€ BANNER INDIKATOR FILTER AKTIF DARI NAVBAR â”€â”€
          if (_selectedFilterDate != null || _selectedFilterTime != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.amber.shade200),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_rounded, size: 16, color: Color(0xFFE65100)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filter Aktif: '
                      '${_selectedFilterDate != null ? DateFormat('dd/MM/yyyy').format(_selectedFilterDate!) : ''}'
                      '${_selectedFilterDate != null && _selectedFilterTime != null ? ' â€¢ ' : ''}'
                      '${_selectedFilterTime != null ? 'Jam ${_selectedFilterTime!.format(context)}' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE65100),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _resetDateTimeFilter,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.close_rounded, size: 13, color: Colors.red),
                          SizedBox(width: 3),
                          Text('Reset', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // â”€â”€ BAR QUICK FILTER & TOTAL TRANSAKSI â”€â”€
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                FilterChip(
                  showCheckmark: false,
                  label: const Text('Hari Ini'),
                  selected: _filterTodayOnly && _selectedFilterDate == null,
                  selectedColor: const Color(0xFFD32F2F),
                  labelStyle: TextStyle(
                    color: (_filterTodayOnly && _selectedFilterDate == null)
                        ? Colors.white
                        : const Color(0xFF333333),
                    fontWeight: (_filterTodayOnly && _selectedFilterDate == null)
                        ? FontWeight.bold
                        : FontWeight.w500,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    setState(() {
                      _filterTodayOnly = true;
                      _selectedFilterDate = null;
                      _selectedFilterTime = null;
                    });
                    _loadSales();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  showCheckmark: false,
                  label: const Text('Semua'),
                  selected: !_filterTodayOnly && _selectedFilterDate == null,
                  selectedColor: const Color(0xFFD32F2F),
                  labelStyle: TextStyle(
                    color: (!_filterTodayOnly && _selectedFilterDate == null)
                        ? Colors.white
                        : const Color(0xFF333333),
                    fontWeight: (!_filterTodayOnly && _selectedFilterDate == null)
                        ? FontWeight.bold
                        : FontWeight.w500,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    setState(() {
                      _filterTodayOnly = false;
                      _selectedFilterDate = null;
                      _selectedFilterTime = null;
                    });
                    _loadSales();
                  },
                ),
                const Spacer(),
                Text(
                  '${_sales.length} Transaksi',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // â”€â”€ LIST TRANSAKSI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 6,
                    itemBuilder: (context, index) => const SkeletonTransactionTile(),
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
                              _selectedFilterDate != null || _selectedFilterTime != null
                                  ? 'Tidak ada transaksi pada filter tanggal/jam ini.'
                                  : (_filterTodayOnly
                                      ? 'Belum ada transaksi penjualan hari ini.'
                                      : 'Belum ada data penjualan.'),
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
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTapDown: (details) {
                                  _lastTapDownPosition = details.globalPosition;
                                },
                                child: ListTile(
                                  onTap: () => _showSaleDetailModal(sale),
                                  // â”€â”€ FITUR CONTEXTMENU PADA ONLONGPRESS â”€â”€
                                  onLongPress: () {
                                    _showTransactionContextMenu(
                                      _lastTapDownPosition ??
                                          const Offset(100, 250),
                                      sale,
                                    );
                                  },
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
                                    '$dateStr â€¢ ${sale.items.length} item â€¢ ${sale.paymentMethod}',
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
