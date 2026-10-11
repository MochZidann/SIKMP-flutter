import 'package:flutter/material.dart';

/// Komponen dasar shimmer animasi lembut untuk placeholder loading.
class AppSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry? margin;

  const AppSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
    this.margin,
  });

  const AppSkeleton.circular({
    super.key,
    required double size,
    this.margin,
  })  : width = size,
        height = size,
        borderRadius = 0,
        shape = BoxShape.circle;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.rectangle
                ? BorderRadius.circular(widget.borderRadius)
                : null,
            gradient: LinearGradient(
              begin: Alignment(-2.2 + (4.4 * progress), -0.2),
              end: Alignment(-1.0 + (4.4 * progress), 0.2),
              stops: const [0.0, 0.5, 1.0],
              colors: const [
                Color(0xFFEBEBEB),
                Color(0xFFF7F7F7),
                Color(0xFFEBEBEB),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton untuk item riwayat transaksi kasir
class SkeletonTransactionTile extends StatelessWidget {
  const SkeletonTransactionTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      child: const Row(
        children: [
          AppSkeleton(width: 40, height: 40, borderRadius: 10),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton(width: 130, height: 13, borderRadius: 4),
                SizedBox(height: 6),
                AppSkeleton(width: 170, height: 11, borderRadius: 4),
              ],
            ),
          ),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppSkeleton(width: 65, height: 14, borderRadius: 4),
              SizedBox(height: 6),
              AppSkeleton(width: 44, height: 16, borderRadius: 6),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton untuk item produk di tab cek produk kasir
class SkeletonProductTile extends StatelessWidget {
  const SkeletonProductTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
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
      child: const Row(
        children: [
          AppSkeleton(width: 56, height: 56, borderRadius: 10),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton(width: 140, height: 14, borderRadius: 4),
                SizedBox(height: 6),
                AppSkeleton(width: 90, height: 12, borderRadius: 4),
                SizedBox(height: 6),
                AppSkeleton(width: 80, height: 13, borderRadius: 4),
              ],
            ),
          ),
          SizedBox(width: 8),
          AppSkeleton(width: 36, height: 36, borderRadius: 10),
        ],
      ),
    );
  }
}

/// Skeleton untuk kartu produk di POS catalog
class SkeletonPosCard extends StatelessWidget {
  const SkeletonPosCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppSkeleton(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 10,
            ),
          ),
          SizedBox(height: 8),
          AppSkeleton(width: 100, height: 13, borderRadius: 4),
          SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppSkeleton(width: 65, height: 14, borderRadius: 4),
              AppSkeleton(width: 28, height: 28, borderRadius: 8),
            ],
          ),
        ],
      ),
    );
  }
}
