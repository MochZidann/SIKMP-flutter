import 'package:flutter/material.dart';
import 'pos/pos_page.dart';

export 'pos/pos_page.dart';

/// Adapter kompatibilitas mundur untuk [QrisPaymentPage].
/// Logika dan komponen tampilan sekarang telah dimodularisasi di folder [lib/pages/pos/].
class QrisPaymentPage extends StatelessWidget {
  final bool isEmbedded;

  const QrisPaymentPage({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    return PosPage(isEmbedded: isEmbedded);
  }
}
