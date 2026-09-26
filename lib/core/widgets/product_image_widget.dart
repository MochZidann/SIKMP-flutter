import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/pos_service.dart';
import '../utils/category_helper.dart';

/// Widget serbaguna untuk menampilkan foto produk dengan URL resolver otomatis,
/// animasi loading elegan, dan fallback responsif ke icon kategori produk.
class ProductImageWidget extends StatelessWidget {
  final String? imagePath;
  final String? category;
  final double? width;
  final double? height;
  final double? size;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final Color? fallbackColor;
  final IconData? fallbackIcon;
  final Widget? placeholder;

  const ProductImageWidget({
    super.key,
    this.imagePath,
    this.category,
    this.width,
    this.height,
    this.size,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.fallbackColor,
    this.fallbackIcon,
    this.placeholder,
  });

  /// Factory constructor praktis langsung dari objek [Product]
  factory ProductImageWidget.fromProduct({
    Key? key,
    required Product product,
    double? width,
    double? height,
    double? size,
    BorderRadius? borderRadius,
    BoxFit fit = BoxFit.cover,
    Color? fallbackColor,
    Widget? placeholder,
  }) {
    return ProductImageWidget(
      key: key,
      imagePath: product.imagePath,
      category: product.category,
      width: width,
      height: height,
      size: size,
      borderRadius: borderRadius,
      fit: fit,
      fallbackColor: fallbackColor,
      placeholder: placeholder,
    );
  }

  /// Helper untuk mengubah relative imagePath (e.g. 'products/abc.jpg' atau '/storage/products/abc.jpg')
  /// menjadi full HTTP URL yang valid berdasarkan host server yang aktif.
  static String? resolveUrl(String? path) {
    if (path == null) return null;
    final trimmed = path.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    // Normalisasi base server URL (misal: http://10.0.2.2:8000 atau http://127.0.0.1:8000)
    String host = PosService.baseUrl;
    if (host.endsWith('/api/pos')) {
      host = host.substring(0, host.length - '/api/pos'.length);
    } else if (host.endsWith('/api')) {
      host = host.substring(0, host.length - '/api'.length);
    }
    while (host.endsWith('/')) {
      host = host.substring(0, host.length - 1);
    }

    String cleanPath = trimmed;
    if (cleanPath.startsWith('/storage/')) {
      cleanPath = cleanPath.substring('/storage/'.length);
    } else if (cleanPath.startsWith('storage/')) {
      cleanPath = cleanPath.substring('storage/'.length);
    }
    while (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    return '$host/storage/$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = size ?? width ?? 44;
    final effectiveHeight = size ?? height ?? 44;
    final radius = borderRadius ?? BorderRadius.circular(10);
    final catColor = fallbackColor ?? CategoryHelper.getColor(category);
    final catIcon = fallbackIcon ?? CategoryHelper.getIcon(category);

    final url = resolveUrl(imagePath);

    final defaultPlaceholder = Container(
      width: effectiveWidth,
      height: effectiveHeight,
      decoration: BoxDecoration(
        color: catColor.withValues(alpha: 0.12),
        borderRadius: radius,
      ),
      child: Center(
        child: Icon(
          catIcon,
          color: catColor,
          size: (effectiveWidth < 36 || effectiveHeight < 36) ? 16 : 22,
        ),
      ),
    );

    final effectivePlaceholder = placeholder ?? defaultPlaceholder;

    if (url == null) {
      return effectivePlaceholder;
    }

    final int? memCacheWidth = effectiveWidth.isFinite ? (effectiveWidth * 2.5).toInt().clamp(60, 600) : null;
    final int? memCacheHeight = effectiveHeight.isFinite ? (effectiveHeight * 2.5).toInt().clamp(60, 600) : null;

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: effectiveWidth,
        height: effectiveHeight,
        color: catColor.withValues(alpha: 0.08),
        child: Image.network(
          url,
          width: effectiveWidth,
          height: effectiveHeight,
          cacheWidth: memCacheWidth,
          cacheHeight: memCacheHeight,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: effectiveWidth,
              height: effectiveHeight,
              color: Colors.grey.shade100,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: catColor,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => effectivePlaceholder,
        ),
      ),
    );
  }
}
