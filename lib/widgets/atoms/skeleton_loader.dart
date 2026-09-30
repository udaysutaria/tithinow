import 'package:flutter/material.dart';
import '../../constants/panchang_terms.dart';
import '../../theme/design_system.dart';

/// Single placeholder box with subtle shimmer/pulse for loading skeleton screens.
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadiusGeometry borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadius.radius8)),
    this.margin,
  });

  /// Circular skeleton element (e.g. for moon, icons).
  const SkeletonBox.circle({
    super.key,
    required double size,
    this.margin,
  })  : width = size,
        height = size,
        borderRadius = const BorderRadius.all(Radius.circular(AppRadius.radius999));

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _opacityAnimation;

  bool get _isTesting =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    if (!_isTesting) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      )..repeat(reverse: true);
      _opacityAnimation = Tween<double>(begin: 0.04, end: 0.12).animate(
        CurvedAnimation(parent: _controller!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller != null && _opacityAnimation != null) {
      return AnimatedBuilder(
        animation: _opacityAnimation!,
        builder: (context, child) => _buildContainer(_opacityAnimation!.value),
      );
    }
    return _buildContainer(0.08);
  }

  Widget _buildContainer(double opacity) {
    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: widget.borderRadius,
      ),
    );
  }
}

/// Skeleton placeholder matching the layout, height, and border radius of [CardTithi].
class CardTithiSkeleton extends StatelessWidget {
  final double moonSize;
  final bool isDetail;

  const CardTithiSkeleton({
    super.key,
    this.moonSize = 96.0,
    this.isDetail = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.border24,
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side: Date, Tithi, Paksha placeholders
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date bar
                const SkeletonBox(
                  width: 140,
                  height: 18,
                  borderRadius: BorderRadius.all(Radius.circular(AppRadius.radius8)),
                ),
                const SizedBox(height: AppSpacing.spacing12),
                // Tithi name bar
                const SkeletonBox(
                  width: 180,
                  height: 28,
                  borderRadius: BorderRadius.all(Radius.circular(AppRadius.radius8)),
                ),
                const SizedBox(height: AppSpacing.spacing8),
                // Paksha bar
                const SkeletonBox(
                  width: 110,
                  height: 16,
                  borderRadius: BorderRadius.all(Radius.circular(AppRadius.radius8)),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.spacing16),
          // Right side: Moon placeholder
          SkeletonBox(
            width: moonSize,
            height: moonSize,
            borderRadius: BorderRadius.circular(moonSize > 80 ? AppRadius.radius8 : 36),
          ),
        ],
      ),
    );
  }
}

/// Skeleton placeholder matching the layout, height, and border radius of [CardPanchang].
class CardPanchangSkeleton extends StatelessWidget {
  const CardPanchangSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.border24,
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: _buildSubItemSkeleton()),
              const SizedBox(width: AppSpacing.spacing16),
              Expanded(child: _buildSubItemSkeleton()),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing16),
          Row(
            children: [
              Expanded(child: _buildSubItemSkeleton()),
              const SizedBox(width: AppSpacing.spacing16),
              Expanded(child: _buildSubItemSkeleton()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubItemSkeleton() {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.border16,
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: Row(
        children: [
          const SkeletonBox.circle(size: 28),
          const SizedBox(width: AppSpacing.spacing12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonBox(width: 50, height: 12),
                SizedBox(height: 6),
                SkeletonBox(width: 80, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton placeholder matching the layout, height, and border radius of [CardTimings].
class CardTimingsSkeleton extends StatelessWidget {
  const CardTimingsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.border24,
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tab bar placeholder
          Row(
            children: const [
              SkeletonBox(width: 70, height: 32, borderRadius: BorderRadius.all(Radius.circular(AppRadius.radius999))),
              SizedBox(width: AppSpacing.spacing8),
              SkeletonBox(width: 100, height: 32, borderRadius: BorderRadius.all(Radius.circular(AppRadius.radius999))),
              SizedBox(width: AppSpacing.spacing8),
              SkeletonBox(width: 80, height: 32, borderRadius: BorderRadius.all(Radius.circular(AppRadius.radius999))),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing16),
          // Interval items
          _buildTimingItemSkeleton(),
          const SizedBox(height: AppSpacing.spacing12),
          _buildTimingItemSkeleton(),
        ],
      ),
    );
  }

  Widget _buildTimingItemSkeleton() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.border16,
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              SkeletonBox(width: 100, height: 16),
              SizedBox(height: 6),
              SkeletonBox(width: 70, height: 12),
            ],
          ),
          const SkeletonBox(width: 80, height: 20),
        ],
      ),
    );
  }
}

/// Skeleton placeholder for individual [ListItemTithi] in calendar list.
class ListItemTithiSkeleton extends StatelessWidget {
  final double? maxWidth;

  const ListItemTithiSkeleton({
    super.key,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.border16,
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              SkeletonBox(width: 120, height: 14),
              SizedBox(height: 8),
              SkeletonBox(width: 160, height: 20),
            ],
          ),
          const SkeletonBox(width: 52, height: 52, borderRadius: BorderRadius.all(Radius.circular(AppRadius.radius8))),
        ],
      ),
    );

    if (maxWidth != null) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth!),
          child: card,
        ),
      );
    }
    return card;
  }
}

/// Clean empty state placeholder for [AlarmsView] when no alarms are scheduled.
class EmptyAlarmsState extends StatelessWidget {
  final AppLanguage language;
  final double? maxWidth;

  const EmptyAlarmsState({
    super.key,
    this.language = AppLanguage.english,
    this.maxWidth = 480.0,
  });

  String get _title => switch (language) {
    AppLanguage.english => 'No Alarms Scheduled',
    AppLanguage.hindi => 'कोई अलार्म सेट नहीं है',
    AppLanguage.gujarati => 'કોઈ એલાર્મ સેટ નથી',
  };

  String get _subtitle => switch (language) {
    AppLanguage.english =>
      'Set alarms for Tithis, Choghadiyas, or Muhurtas to receive timely notifications.',
    AppLanguage.hindi =>
      'समय पर सूचनाएं पाने के लिए तिथि, चौघड़िया या मुहूर्त के लिए अलार्म सेट करें।',
    AppLanguage.gujarati =>
      'સમયસર સૂચનાઓ મેળવવા માટે તિથિ, ચોઘડિયા અથવા મુહૂર્ત માટે એલાર્મ સેટ કરો.',
  };

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing24,
        vertical: AppSpacing.spacing48,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.border24,
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.outline, width: 1),
            ),
            child: const Center(
              child: Icon(
                Icons.notifications_none_rounded,
                color: AppColors.onSurface,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          Text(
            _title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Sora',
            ),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          Text(
            _subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              fontFamily: 'Inter',
              height: 1.4,
            ),
          ),
        ],
      ),
    );

    if (maxWidth != null) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth!),
          child: content,
        ),
      );
    }
    return content;
  }
}
