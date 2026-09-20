import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/qris_response.dart';
import '../../services/pos_service.dart';
import 'widgets/cash_payment_bottom_sheet.dart';
import 'widgets/pos_cart_bottom_sheet.dart';
import 'widgets/pos_checkout_bar.dart';
import 'widgets/pos_product_catalog.dart';
import 'widgets/pos_receipt_dialog.dart';
import 'widgets/pos_settings_dialog.dart';
import 'widgets/qris_modal_bottom_sheet.dart';

class PosPage extends StatefulWidget {
  final bool isEmbedded;

  const PosPage({super.key, this.isEmbedded = false});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  final PosService _posService = PosService();

  List<Product> _products = [];
  bool _isLoadingProducts = true;
  final Map<int, int> _cart = {}; // productId -> quantity

  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    final prods = await _posService.getProducts();
    if (mounted) {
      setState(() {
        _products = prods;
        _isLoadingProducts = false;
      });
    }
  }

  int get _cartTotal {
    int total = 0;
    _cart.forEach((productId, qty) {
      final p = _products.firstWhere(
        (item) => item.id == productId,
        orElse: () => Product(
          id: productId,
          name: '',
          category: 'Umum',
          price: 0,
          stock: 0,
          barcode: '',
        ),
      );
      total += p.price * qty;
    });
    return total;
  }

  String _getProductName(dynamic productId) {
    if (productId == null) return 'Barang Toko';
    final p = _products.where((item) => item.id == productId).firstOrNull;
    return p?.name ?? 'Produk #$productId';
  }

  Map<String, dynamic>? _getOrderPayload() {
    if (_cart.isEmpty) {
      _showErrorSnackbar('Keranjang belanja kosong. Ketuk kartu produk untuk menambahkan.');
      return null;
    }

    final itemsPayload = _cart.entries.map((entry) {
      return {
        'productId': entry.key,
        'qty': entry.value,
      };
    }).toList();

    return {
      'amount': _cartTotal,
      'items': itemsPayload,
    };
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // -------------------------------------------------------------
  // PEMBAYARAN TUNAI (CASH)
  // -------------------------------------------------------------
  void _handleCashPayment() {
    final payload = _getOrderPayload();
    if (payload == null) return;

    CashPaymentBottomSheet.show(
      context,
      finalAmount: payload['amount'] as int,
      itemsPayload: payload['items'] as List<Map<String, dynamic>>?,
      onSuccess: _showSuccessReceiptDialog,
      onError: _showErrorSnackbar,
    );
  }

  // -------------------------------------------------------------
  // PEMBAYARAN QRIS
  // -------------------------------------------------------------
  Future<void> _handleGenerateQris() async {
    final payload = _getOrderPayload();
    if (payload == null) return;

    final finalAmount = payload['amount'] as int;
    final itemsPayload = payload['items'] as List<Map<String, dynamic>>?;

    setState(() => _isGenerating = true);

    try {
      final response = await _posService.generateQris(
        amount: itemsPayload == null ? finalAmount : null,
        items: itemsPayload,
      );

      if (mounted) {
        setState(() => _isGenerating = false);
        _showQrisModal(response);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        _showErrorSnackbar('Gagal membuat QRIS: $e');
      }
    }
  }

  void _showQrisModal(QrisResponse qris) {
    QrisModalBottomSheet.show(
      context,
      qris: qris,
      onSuccess: _showSuccessReceiptDialog,
      onCancelled: () {
        _showErrorSnackbar('Transaksi QRIS berhasil dibatalkan.');
      },
    );
  }

  // -------------------------------------------------------------
  // MODAL SUKSES & STRUK PEMBAYARAN
  // -------------------------------------------------------------
  void _showSuccessReceiptDialog(Map<String, dynamic> data) {
    setState(() {
      _cart.clear();
    });

    PosReceiptDialog.show(
      context,
      data: data,
      getProductName: _getProductName,
    );
  }

  // -------------------------------------------------------------
  // BOTTOM SHEET KERANJANG
  // -------------------------------------------------------------
  void _showCartDetailsBottomSheet() {
    PosCartBottomSheet.show(
      context,
      products: _products,
      cart: _cart,
      onClearCart: () => setState(() => _cart.clear()),
      onIncrement: (p) => setState(() => _cart[p.id] = (_cart[p.id] ?? 0) + 1),
      onDecrement: (p) {
        setState(() {
          final current = _cart[p.id] ?? 0;
          if (current > 1) {
            _cart[p.id] = current - 1;
          } else {
            _cart.remove(p.id);
          }
        });
      },
      onCashPayment: _handleCashPayment,
      onQrisPayment: _handleGenerateQris,
    );
  }

  // -------------------------------------------------------------
  // PENGATURAN API BACKEND
  // -------------------------------------------------------------
  void _showSettingsDialog() {
    PosSettingsDialog.show(context, onSaved: _loadProducts);
  }

  @override
  Widget build(BuildContext context) {
    final total = _cartTotal;
    final totalItems = _cart.values.fold(0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isEmbedded,
        backgroundColor: const Color(0xFFD32F2F),
        elevation: 0,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kasir POS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              'Sentuh kartu produk untuk menambah ke keranjang',
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.85)),
            ),
          ],
        ),
        actions: [
          if (_cart.isNotEmpty)
            IconButton(
              tooltip: 'Kosongkan Keranjang',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () {
                setState(() => _cart.clear());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Keranjang berhasil dikosongkan'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          IconButton(
            tooltip: 'Keranjang Belanja',
            icon: Badge(
              isLabelVisible: _cart.isNotEmpty,
              backgroundColor: Colors.white,
              textColor: const Color(0xFFD32F2F),
              label: Text(
                '$totalItems',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              ),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: _cart.isEmpty ? null : _showCartDetailsBottomSheet,
          ),
          IconButton(
            tooltip: 'Muat Ulang Produk',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadProducts,
          ),
          IconButton(
            tooltip: 'Pengaturan Server API',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: PosProductCatalog(
        products: _products,
        isLoading: _isLoadingProducts,
        cart: _cart,
        onReload: _loadProducts,
        onAddToCart: (p) => setState(() => _cart[p.id] = (_cart[p.id] ?? 0) + 1),
        onIncrement: (p) => setState(() => _cart[p.id] = (_cart[p.id] ?? 0) + 1),
        onDecrement: (p) {
          setState(() {
            final current = _cart[p.id] ?? 0;
            if (current > 1) {
              _cart[p.id] = current - 1;
            } else {
              _cart.remove(p.id);
            }
          });
        },
      ),
      bottomNavigationBar: PosCheckoutBar(
        total: total,
        totalItems: totalItems,
        productCount: _cart.length,
        isBusy: _isGenerating,
        isProcessingCash: false,
        isGeneratingQris: _isGenerating,
        onOpenCart: _showCartDetailsBottomSheet,
        onCashPayment: _handleCashPayment,
        onQrisPayment: _handleGenerateQris,
      ),
    );
  }
}
