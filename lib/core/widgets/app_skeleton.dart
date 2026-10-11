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

/// Skeleton untuk kartu metrik ringkasan (Dashboard Gudang, Owner, Admin)
class SkeletonMetricCard extends StatelessWidget {
  const SkeletonMetricCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppSkeleton(width: 38, height: 38, borderRadius: 10),
              AppSkeleton(width: 32, height: 18, borderRadius: 10),
            ],
          ),
          SizedBox(height: 12),
          AppSkeleton(width: 90, height: 20, borderRadius: 4),
          SizedBox(height: 4),
          AppSkeleton(width: 120, height: 12, borderRadius: 4),
        ],
      ),
    );
  }
}

/// Skeleton untuk item pengguna di Admin Sistem (admin_users_tab)
class SkeletonUserTile extends StatelessWidget {
  const SkeletonUserTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
          AppSkeleton.circular(size: 44),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton(width: 130, height: 14, borderRadius: 4),
                SizedBox(height: 6),
                AppSkeleton(width: 90, height: 12, borderRadius: 4),
                SizedBox(height: 6),
                AppSkeleton(width: 70, height: 18, borderRadius: 6),
              ],
            ),
          ),
          SizedBox(width: 10),
          AppSkeleton(width: 40, height: 24, borderRadius: 12),
        ],
      ),
    );
  }
}

/// Skeleton untuk kategori di Gudang (gudang_category_tab)
class SkeletonCategoryCard extends StatelessWidget {
  const SkeletonCategoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Row(
        children: [
          AppSkeleton(width: 40, height: 40, borderRadius: 10),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton(width: 120, height: 14, borderRadius: 4),
                SizedBox(height: 6),
                AppSkeleton(width: 80, height: 12, borderRadius: 4),
              ],
            ),
          ),
          AppSkeleton(width: 24, height: 24, borderRadius: 6),
        ],
      ),
    );
  }
}

/// Skeleton untuk item Audit Log (admin_audit_tab)
class SkeletonAuditLogTile extends StatelessWidget {
  const SkeletonAuditLogTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(width: 36, height: 36, borderRadius: 10),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppSkeleton(width: 110, height: 13, borderRadius: 4),
                    AppSkeleton(width: 60, height: 18, borderRadius: 6),
                  ],
                ),
                SizedBox(height: 6),
                AppSkeleton(width: double.infinity, height: 12, borderRadius: 4),
                SizedBox(height: 6),
                AppSkeleton(width: 80, height: 11, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton Dashboard serbaguna untuk Gudang, Owner, & Admin
class SkeletonDashboard extends StatelessWidget {
  final bool hasBanner;

  const SkeletonDashboard({
    super.key,
    this.hasBanner = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasBanner) ...[
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(16),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppSkeleton(width: 140, height: 14, borderRadius: 4),
                  SizedBox(height: 10),
                  AppSkeleton(width: 200, height: 26, borderRadius: 6),
                  SizedBox(height: 8),
                  AppSkeleton(width: 100, height: 12, borderRadius: 4),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: const [
              SkeletonMetricCard(),
              SkeletonMetricCard(),
              SkeletonMetricCard(),
              SkeletonMetricCard(),
            ],
          ),
          const SizedBox(height: 20),
          const AppSkeleton(width: 150, height: 16, borderRadius: 4),
          const SizedBox(height: 12),
          const SkeletonTransactionTile(),
          const SkeletonTransactionTile(),
          const SkeletonTransactionTile(),
        ],
      ),
    );
  }
}
