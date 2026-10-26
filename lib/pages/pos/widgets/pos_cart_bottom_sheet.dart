import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/product_image_widget.dart';
import '../../../models/member.dart';
import '../../../models/product.dart';
import '../../../services/member_service.dart';
import '../../../services/pos_service.dart';

class PosCartBottomSheet extends StatefulWidget {
  final List<Product> products;
  final Map<int, int> cart;
  final VoidCallback onClearCart;
  final Function(Product product) onIncrement;
  final Function(Product product) onDecrement;
  final Function(int? memberId, bool redeemPoints) onCashPayment;
  final Function(int? memberId, bool redeemPoints) onQrisPayment;
  final Member? initialMember;
  final bool initialRedeemPoints;
  final Function(Member? member)? onMemberChanged;
  final Function(bool redeem)? onRedeemPointsChanged;

  const PosCartBottomSheet({
    super.key,
    required this.products,
    required this.cart,
    required this.onClearCart,
    required this.onIncrement,
    required this.onDecrement,
    required this.onCashPayment,
    required this.onQrisPayment,
    this.initialMember,
    this.initialRedeemPoints = false,
    this.onMemberChanged,
    this.onRedeemPointsChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Product> products,
    required Map<int, int> cart,
    required VoidCallback onClearCart,
    required Function(Product product) onIncrement,
    required Function(Product product) onDecrement,
    required Function(int? memberId, bool redeemPoints) onCashPayment,
    required Function(int? memberId, bool redeemPoints) onQrisPayment,
    Member? initialMember,
    bool initialRedeemPoints = false,
    Function(Member? member)? onMemberChanged,
    Function(bool redeem)? onRedeemPointsChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => PosCartBottomSheet(
        products: products,
        cart: cart,
        onClearCart: onClearCart,
        onIncrement: onIncrement,
        onDecrement: onDecrement,
        onCashPayment: onCashPayment,
        onQrisPayment: onQrisPayment,
        initialMember: initialMember,
        initialRedeemPoints: initialRedeemPoints,
        onMemberChanged: onMemberChanged,
        onRedeemPointsChanged: onRedeemPointsChanged,
      ),
    );
  }

  @override
  State<PosCartBottomSheet> createState() => _PosCartBottomSheetState();
}

class _PosCartBottomSheetState extends State<PosCartBottomSheet> {
  String _selectedPaymentMethod = 'CASH';
  Member? _selectedMember;
  bool _redeemPoints = false;
  Map<String, dynamic>? _serverCalculation;
  bool _isCalculatingServer = false;

  @override
  void initState() {
    super.initState();
    _selectedMember = widget.initialMember;
    _redeemPoints = widget.initialRedeemPoints;
    _fetchServerCalculation();
  }

  Future<void> _fetchServerCalculation() async {
    if (widget.cart.isEmpty) {
      if (mounted) {
        setState(() {
          _serverCalculation = null;
          _isCalculatingServer = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _isCalculatingServer = true);
    }

    final itemsPayload = widget.cart.entries.map((entry) => {
      'productId': entry.key,
      'qty': entry.value,
    }).toList();

    try {
      final res = await PosService().calculateOrder(
        items: itemsPayload,
        memberId: _selectedMember?.id,
        redeemPoints: _redeemPoints,
      );
      if (mounted) {
        setState(() {
          _serverCalculation = res;
          _isCalculatingServer = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isCalculatingServer = false);
      }
    }
  }

  int get _rawSubtotal {
    if (_serverCalculation != null && _serverCalculation!['subtotal'] is num) {
      return (_serverCalculation!['subtotal'] as num).toInt();
    }
    int total = 0;
    widget.cart.forEach((productId, qty) {
      final p = widget.products.firstWhere(
        (item) => item.id == productId,
        orElse: () => Product(id: productId, name: '', price: 0, stock: 0),
      );
      total += p.price * qty;
    });
    return total;
  }

  int get _memberDiscount {
    if (_serverCalculation != null && _serverCalculation!['memberDiscount'] is num) {
      return (_serverCalculation!['memberDiscount'] as num).toInt();
    }
    if (_selectedMember == null) return 0;
    int discount = 0;
    widget.cart.forEach((productId, qty) {
      final p = widget.products.firstWhere(
        (item) => item.id == productId,
        orElse: () => Product(id: productId, name: '', price: 0, stock: 0),
      );
      if (p.memberPrice != null && p.memberPrice! > 0 && p.memberPrice! < p.price) {
        discount += (p.price - p.memberPrice!) * qty;
      }
    });
    return discount;
  }

  int get _subtotalAfterMemberDiscount => _rawSubtotal - _memberDiscount;

  int get _pointsDiscount {
    if (_serverCalculation != null && _serverCalculation!['pointsDiscount'] is num) {
      return (_serverCalculation!['pointsDiscount'] as num).toInt();
    }
    if (!_redeemPoints || _selectedMember == null || _selectedMember!.points <= 0) {
      return 0;
    }
    return (_selectedMember!.points < _subtotalAfterMemberDiscount)
        ? _selectedMember!.points
        : _subtotalAfterMemberDiscount;
  }

  int get _globalDiscount {
    if (_serverCalculation != null && _serverCalculation!['globalDiscount'] is num) {
      return (_serverCalculation!['globalDiscount'] as num).toInt();
    }
    return 0;
  }

  int get _promoDiscount {
    if (_serverCalculation != null && _serverCalculation!['promoDiscount'] is num) {
      return (_serverCalculation!['promoDiscount'] as num).toInt();
    }
    return 0;
  }

  int get _tax {
    if (_serverCalculation != null && _serverCalculation!['tax'] is num) {
      return (_serverCalculation!['tax'] as num).toInt();
    }
    return 0;
  }

  int get _finalTotal {
    if (_serverCalculation != null && _serverCalculation!['total'] is num) {
      return (_serverCalculation!['total'] as num).toInt();
    }
    return (_subtotalAfterMemberDiscount - _pointsDiscount).clamp(0, 999999999);
  }

  int get _pointsEarned {
    if (_serverCalculation != null && _serverCalculation!['pointsEarned'] is num) {
      return (_serverCalculation!['pointsEarned'] as num).toInt();
    }
    if (_selectedMember == null || !_selectedMember!.isActive) return 0;
    if (_subtotalAfterMemberDiscount < 10000) return 0;
    return _subtotalAfterMemberDiscount ~/ 100; // 1%
  }

  Future<void> _pickMember() async {
    final picked = await showModalBottomSheet<Member>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MemberPickerSheet(currentSelected: _selectedMember),
    );

    if (picked != null) {
      setState(() {
        _selectedMember = picked;
        if (_selectedMember!.points <= 0) {
          _redeemPoints = false;
        }
      });
      widget.onMemberChanged?.call(_selectedMember);
      widget.onRedeemPointsChanged?.call(_redeemPoints);
      _fetchServerCalculation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = widget.cart.entries.map((entry) {
      final p = widget.products.firstWhere(
        (it) => it.id == entry.key,
        orElse: () => Product(id: entry.key, name: 'Produk #${entry.key}', price: 0, stock: 0),
      );
      final hasMemberPrice = _selectedMember != null &&
          p.memberPrice != null &&
          p.memberPrice! > 0 &&
          p.memberPrice! < p.price;
      final unitPrice = hasMemberPrice ? p.memberPrice! : p.price;

      return {
        'product': p,
        'qty': entry.value,
        'unitPrice': unitPrice,
        'hasMemberPrice': hasMemberPrice,
        'lineTotal': unitPrice * entry.value,
      };
    }).toList();

    final totalCount = widget.cart.values.fold(0, (a, b) => a + b);

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shopping_cart_rounded, color: Color(0xFFD32F2F)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Keranjang Belanja',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B2B2B),
                        ),
                      ),
                      Text(
                        '$totalCount barang dalam keranjang',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              if (widget.cart.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    widget.onClearCart();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.red),
                  label: const Text('Kosongkan', style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
            ],
          ),
          const Divider(height: 16),

          // Daftar Item Keranjang
          Expanded(
            child: cartItems.isEmpty
                ? const Center(
                    child: Text(
                      'Keranjang belanja kosong',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    itemCount: cartItems.length,
                    separatorBuilder: (ctx, i) => const Divider(height: 10),
                    itemBuilder: (ctx, idx) {
                      final item = cartItems[idx];
                      final p = item['product'] as Product;
                      final qty = item['qty'] as int;
                      final unitPrice = item['unitPrice'] as int;
                      final hasMemberPrice = item['hasMemberPrice'] as bool;
                      final lineTotal = item['lineTotal'] as int;

                      return Row(
                        children: [
                          ProductImageWidget.fromProduct(
                            product: p,
                            size: 42,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      '${formatRupiah(unitPrice)} x $qty = ${formatRupiah(lineTotal)}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                    if (hasMemberPrice) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Member',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1565C0),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                onPressed: () {
                                  widget.onDecrement(p);
                                  setState(() {});
                                  if (widget.cart.isEmpty) {
                                    Navigator.pop(context);
                                  } else {
                                    _fetchServerCalculation();
                                  }
                                },
                              ),
                              Text(
                                '$qty',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 20),
                                onPressed: () {
                                  if (qty < p.stock) {
                                    widget.onIncrement(p);
                                    setState(() {});
                                    _fetchServerCalculation();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Maksimal stok tercapai (${p.stock}).'),
                                        backgroundColor: Colors.red.shade700,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
          ),

          const SizedBox(height: 8),

          // SECTION MEMBER & LOYALTY POIN
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _selectedMember != null ? const Color(0xFFF0F7FF) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedMember != null ? const Color(0xFF90CAF9) : Colors.grey.shade300,
              ),
            ),
            child: _selectedMember == null
                ? InkWell(
                    onTap: _pickMember,
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: Color(0xFF1565C0)),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pilih Anggota / Member (Opsional)',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                              ),
                              Text(
                                'Dapatkan poin belanja (1%) & potongan poin',
                                style: TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1565C0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.badge_rounded, size: 16, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedMember!.name,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    _selectedMember!.memberNo,
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.shade300),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.stars_rounded, size: 14, color: Color(0xFFF57F17)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_selectedMember!.points} Poin',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFF57F17),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    _selectedMember = null;
                                    _redeemPoints = false;
                                  });
                                  widget.onMemberChanged?.call(null);
                                  widget.onRedeemPointsChanged?.call(false);
                                  _fetchServerCalculation();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_selectedMember!.points > 0) ...[
                        const Divider(height: 10),
                        InkWell(
                          onTap: () {
                            setState(() => _redeemPoints = !_redeemPoints);
                            widget.onRedeemPointsChanged?.call(_redeemPoints);
                            _fetchServerCalculation();
                          },
                          child: Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _redeemPoints,
                                  activeColor: const Color(0xFF2E7D32),
                                  onChanged: (val) {
                                    setState(() => _redeemPoints = val == true);
                                    widget.onRedeemPointsChanged?.call(_redeemPoints);
                                    _fetchServerCalculation();
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Tukarkan Saldo Poin (-${formatRupiah(_pointsDiscount)})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _redeemPoints ? const Color(0xFF2E7D32) : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
          ),

          const SizedBox(height: 8),

          // Total Belanja Card & Rincian
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                if (_memberDiscount > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Diskon Khusus Member', style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32))),
                      Text('- ${formatRupiah(_memberDiscount)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
                if (_globalDiscount > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Diskon Toko', style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32))),
                      Text('- ${formatRupiah(_globalDiscount)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
                if (_promoDiscount > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Diskon Promo', style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32))),
                      Text('- ${formatRupiah(_promoDiscount)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
                if (_redeemPoints && _pointsDiscount > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Potongan Poin ($_pointsDiscount pt)',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32))),
                      Text('- ${formatRupiah(_pointsDiscount)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
                if (_tax > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pajak (PPN)', style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
                      Text('+ ${formatRupiah(_tax)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Total Tagihan',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            if (_isCalculatingServer) ...[
                              const SizedBox(width: 6),
                              const SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(strokeWidth: 1.5),
                              ),
                            ],
                          ],
                        ),
                        if (_selectedMember != null && _pointsEarned > 0)
                          Text(
                            'Perolehan +$_pointsEarned Poin',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      formatRupiah(_finalTotal),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // RadioButton Metode Pembayaran
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _selectedPaymentMethod = 'CASH'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        decoration: BoxDecoration(
                          color: _selectedPaymentMethod == 'CASH' ? Colors.green.shade50 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedPaymentMethod == 'CASH' ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                            width: _selectedPaymentMethod == 'CASH' ? 1.5 : 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payments_rounded, color: Color(0xFF2E7D32), size: 18),
                            SizedBox(width: 6),
                            Text('Tunai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _selectedPaymentMethod = 'QRIS'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        decoration: BoxDecoration(
                          color: _selectedPaymentMethod == 'QRIS' ? Colors.red.shade50 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedPaymentMethod == 'QRIS' ? const Color(0xFFD32F2F) : Colors.grey.shade300,
                            width: _selectedPaymentMethod == 'QRIS' ? 1.5 : 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_2_rounded, color: Color(0xFFD32F2F), size: 18),
                            SizedBox(width: 6),
                            Text('QRIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _finalTotal < 1000
                  ? null
                  : () {
                      Navigator.pop(context);
                      if (_selectedPaymentMethod == 'CASH') {
                        widget.onCashPayment(_selectedMember?.id, _redeemPoints);
                      } else {
                        widget.onQrisPayment(_selectedMember?.id, _redeemPoints);
                      }
                    },
              icon: Icon(
                _selectedPaymentMethod == 'CASH' ? Icons.payments_rounded : Icons.qr_code_2_rounded,
                size: 20,
              ),
              label: Text(
                _selectedPaymentMethod == 'CASH'
                    ? 'Lanjutkan Pembayaran Tunai'
                    : 'Generate QRIS Pembayaran',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedPaymentMethod == 'CASH'
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberPickerSheet extends StatefulWidget {
  final Member? currentSelected;

  const _MemberPickerSheet({this.currentSelected});

  @override
  State<_MemberPickerSheet> createState() => _MemberPickerSheetState();
}

class _MemberPickerSheetState extends State<_MemberPickerSheet> {
  final MemberService _memberService = MemberService();
  List<Member> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers([String? search]) async {
    setState(() => _isLoading = true);
    final results = await _memberService.getMembers(search: search);
    if (mounted) {
      setState(() {
        _members = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const Row(
            children: [
              Icon(Icons.people_alt_rounded, color: Color(0xFF1565C0)),
              SizedBox(width: 8),
              Text(
                'Pilih Anggota / Member',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Cari nama, no. member, atau no. telepon...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) {
              _fetchMembers(val);
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _members.isEmpty
                    ? const Center(
                        child: Text(
                          'Anggota tidak ditemukan',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _members.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 8),
                        itemBuilder: (ctx, idx) {
                          final m = _members[idx];
                          final isSelected = widget.currentSelected?.id == m.id;

                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            leading: CircleAvatar(
                              backgroundColor: isSelected ? const Color(0xFF1565C0) : Colors.blue.shade50,
                              foregroundColor: isSelected ? Colors.white : const Color(0xFF1565C0),
                              child: Text(
                                m.name.isNotEmpty ? m.name[0].toUpperCase() : 'M',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              m.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFF1565C0) : Colors.black87,
                              ),
                            ),
                            subtitle: Text('${m.memberNo} â€¢ ${m.phone ?? "-"}'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.stars_rounded, size: 14, color: Color(0xFFF57F17)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${m.points} pt',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: Color(0xFFF57F17),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () => Navigator.pop(context, m),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
