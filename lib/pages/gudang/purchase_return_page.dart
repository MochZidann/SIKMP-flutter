import 'package:flutter/material.dart';
import '../../services/return_service.dart';

class PurchaseReturnPage extends StatefulWidget {
  const PurchaseReturnPage({super.key});
  @override
  State<PurchaseReturnPage> createState() => _PurchaseReturnPageState();
}

class _PurchaseReturnPageState extends State<PurchaseReturnPage> {
  final _search = TextEditingController();
  final _reason = TextEditingController();
  final Map<int, int> _quantities = {};
  List<Map<String, dynamic>> _receipts = [];
  List<Map<String, dynamic>> _history = [];
  Map<String, dynamic>? _summary;
  String? _error;
  bool _loading = false;
  bool _saving = false;
  int _page = 1;
  int _lastPage = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ReturnService().getPurchaseReceipts(
        search: _search.text.trim(),
        page: page,
      );
      final history = await ReturnService().getPurchaseReturns();
      if (!mounted) return;
      setState(() {
        _receipts = List<Map<String, dynamic>>.from(data['data'] as List);
        _history = history;
        _page = page;
        _lastPage = (data['pagination']['last_page'] as num).toInt();
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Gagal memuat penerimaan dan riwayat retur. Silakan coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _select(Map<String, dynamic> receipt) async {
    setState(() {
      _loading = true;
      _error = null;
      _summary = null;
      _quantities.clear();
    });
    final data = await ReturnService().getReceiptReturnableSummary(
      receipt['id'],
    );
    if (!mounted) return;
    setState(() {
      _summary = data;
      _loading = false;
      if (data == null) _error = 'Gagal memuat rincian penerimaan.';
    });
  }

  Future<void> _submit() async {
    if (_saving || _summary == null) return;
    final items = <Map<String, dynamic>>[];
    for (final item in _summary!['items'] as List) {
      final qty = _quantities[item['batch_id']] ?? 0;
      if (qty > 0) {
        items.add({
          'product_batch_id': item['batch_id'],
          'goods_receipt_item_id': item['goods_receipt_item_id'],
          'quantity': qty,
          'condition': 'DEFECTIVE',
        });
      }
    }
    if (items.isEmpty || _reason.text.trim().isEmpty) {
      setState(() => _error = 'Pilih barang dan isi alasan retur.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final receipt = _summary!['receipt'] as Map<String, dynamic>;
    final result = await ReturnService().createPurchaseReturn(
      supplierId: (receipt['supplier_id'] as num).toInt(),
      goodsReceiptId: receipt['id'],
      items: items,
      reason: _reason.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result['success'] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'] as String)));
      _reason.clear();
      await _select(receipt);
      await _load(page: _page);
    } else {
      setState(() => _error = result['message'] as String? ?? 'Retur gagal.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final receipt = _summary?['receipt'] as Map<String, dynamic>?;
    final items = _summary?['items'] as List? ?? [];
    final total = items.fold<int>(
      0,
      (sum, item) =>
          sum +
          (_quantities[item['batch_id']] ?? 0) *
              ((item['purchase_price'] as num?)?.toInt() ?? 0),
    );
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Retur Pembelian')),
        body: AbsorbPointer(
          absorbing: _saving,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Pilih penerimaan barang untuk mengembalikan barang ke supplier.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                decoration: InputDecoration(
                  labelText: 'Nomor penerimaan',
                  suffixIcon: IconButton(
                    onPressed: _loading ? null : () => _load(),
                    icon: const Icon(Icons.search),
                  ),
                ),
                onSubmitted: (_) => _load(),
              ),
              if (_loading) const LinearProgressIndicator(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ..._receipts.map(
                (r) => ListTile(
                  title: Text(r['receipt_no'] as String),
                  subtitle: Text(r['supplier_name_snapshot'] as String? ?? ''),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _loading ? null : () => _select(r),
                ),
              ),
              if (!_loading && _receipts.isEmpty)
                const Text('Penerimaan tidak ditemukan.'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _loading || _page <= 1
                        ? null
                        : () => _load(page: _page - 1),
                    child: const Text('Sebelumnya'),
                  ),
                  Text('$_page / $_lastPage'),
                  TextButton(
                    onPressed: _loading || _page >= _lastPage
                        ? null
                        : () => _load(page: _page + 1),
                    child: const Text('Berikutnya'),
                  ),
                ],
              ),
              if (receipt != null) ...[
                const Divider(),
                Text(
                  '${receipt['receipt_no']} Â· ${receipt['supplier_name']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ...items.map((item) {
                  final id = (item['batch_id'] as num?)?.toInt();
                  final max = (item['quantity_returnable'] as num).toInt();
                  final qty = _quantities[id] ?? 0;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['product_name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Batch ${item['batch_no']} Â· sisa retur $max'),
                          Text(
                            'Harga beli Rp ${item['purchase_price']} / unit',
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _loading || qty == 0 || id == null
                                    ? null
                                    : () => setState(
                                        () => _quantities[id] = qty - 1,
                                      ),
                                icon: const Icon(Icons.remove),
                              ),
                              Text('$qty'),
                              IconButton(
                                onPressed: _loading || qty >= max || id == null
                                    ? null
                                    : () => setState(
                                        () => _quantities[id] = qty + 1,
                                      ),
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                TextField(
                  controller: _reason,
                  maxLength: 255,
                  decoration: const InputDecoration(
                    labelText: 'Alasan retur (wajib)',
                  ),
                ),
                Text('Nilai retur: Rp $total'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed:
                      _loading || _saving || _summary!['is_returnable'] != true
                      ? null
                      : _submit,
                  child: Text(
                    _saving ? 'Memproses...' : 'Proses retur ke supplier',
                  ),
                ),
              ],
              const Divider(height: 32),
              const Text(
                'Retur terbaru',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._history.map(
                (r) => ExpansionTile(
                  title: Text(r['return_no'] as String),
                  subtitle: Text(
                    '${r['supplier_name_snapshot']} Â· Rp ${r['total_amount']}',
                  ),
                  children: [
                    ListTile(
                      title: Text(r['reason'] as String? ?? ''),
                      subtitle: Text(
                        r['processed_by_snapshot'] as String? ?? '',
                      ),
                    ),
                    ...(r['items'] as List? ?? []).map(
                      (i) => ListTile(
                        title: Text(i['product_name_snapshot'] as String),
                        trailing: Text('${i['quantity']} unit'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
