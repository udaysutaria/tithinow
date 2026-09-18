import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/design_system.dart';
import 'button_alarm.dart';

/// Temporal state representing where an interval sits relative to current time.
enum ItemTemporalState {
  /// Elapsed interval with dimmed 50% opacity text.
  past,

  /// Active interval with full opacity and live countdown counter.
  current,

  /// Upcoming interval with full opacity and an embedded alarm button.
  future,
}

/// Unified list item molecule used across tab content lists:
/// - `list_tab_content_now.dart`
/// - `list_tab_content_choghadiya.dart`
/// - `list_tab_content_muhurta.dart`
class ListItemTabContent extends StatelessWidget {
  final String title;
  final String timeRange;
  final Color indicatorColor;
  final ItemTemporalState state;
  final String? tag;

  /// Target end time for active current interval countdown.
  final DateTime? endTime;

  /// Callback triggered when the live counter reaches 0 (transitioning to PastItem).
  final VoidCallback? onCountdownEnded;

  /// Optional static countdown string fallback (if endTime is not provided).
  final String? countdownText;

  /// Alarm state when in [ItemTemporalState.future].
  final bool isAlarmActive;
  final VoidCallback? onAlarmTap;
  final VoidCallback? onTap;

  const ListItemTabContent({
    super.key,
    required this.title,
    required this.timeRange,
    required this.indicatorColor,
    required this.state,
    this.tag,
    this.endTime,
    this.onCountdownEnded,
    this.countdownText,
    this.isAlarmActive = false,
    this.onAlarmTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPast = state == ItemTemporalState.past;
    final bool isCurrent = state == ItemTemporalState.current;
    final bool isFuture = state == ItemTemporalState.future;

    Widget textColumn = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row with optional Category / Tag pill
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.50,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (tag != null) ...[
              const SizedBox(width: AppSpacing.spacing8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: ShapeDecoration(
                  color: AppColors.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.border999,
                  ),
                ),
                child: Text(
                  tag!,
                  style: GoogleFonts.inter(
                    color: AppColors.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ],
        ),

        // Time range string
        Text(
          timeRange,
          style: GoogleFonts.inter(
            color: AppColors.onSurfaceVariant,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.50,
          ),
        ),
      ],
    );

    if (isPast) {
      textColumn = Opacity(
        opacity: 0.50,
        child: textColumn,
      );
    }

    Widget? trailing;
    if (isCurrent) {
      if (endTime != null) {
        trailing = _LiveCountdownText(
          endTime: endTime!,
          onEnded: onCountdownEnded,
        );
      } else if (countdownText != null) {
        trailing = Text(
          countdownText!,
          style: GoogleFonts.inter(
            color: AppColors.tertiary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.60,
          ),
        );
      }
    } else if (isFuture) {
      trailing = ButtonAlarm(
        isActive: isAlarmActive,
        onTap: onAlarmTap,
      );
    }

    final rowContent = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 10x10 Indicator Dot
        Container(
          width: 10,
          height: 10,
          decoration: ShapeDecoration(
            color: indicatorColor,
            shape: const OvalBorder(),
          ),
        ),
        const SizedBox(width: AppSpacing.spacing16),

        // Text content
        Expanded(child: textColumn),

        // Optional Trailing element
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.spacing16),
          trailing,
        ],
      ],
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.border24,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.border24,
              ),
            ),
            child: rowContent,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.border24,
        ),
      ),
      child: rowContent,
    );
  }
}

/// Ticking countdown widget that updates every second and notifies on completion.
class _LiveCountdownText extends StatefulWidget {
  final DateTime endTime;
  final VoidCallback? onEnded;

  const _LiveCountdownText({
    required this.endTime,
    this.onEnded,
  });

  @override
  State<_LiveCountdownText> createState() => _LiveCountdownTextState();
}

class _LiveCountdownTextState extends State<_LiveCountdownText> {
  Timer? _timer;
  late Duration _remaining;
  bool _hasTriggeredEnd = false;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _LiveCountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endTime != widget.endTime) {
      _hasTriggeredEnd = false;
      _calculateRemaining();
      _startTimer();
    }
  }

  void _calculateRemaining() {
    final now = DateTime.now();
    if (widget.endTime.isAfter(now)) {
      _remaining = widget.endTime.difference(now);
    } else {
      _remaining = Duration.zero;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_remaining > Duration.zero) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        final now = DateTime.now();
        if (widget.endTime.isAfter(now)) {
          setState(() {
            _remaining = widget.endTime.difference(now);
          });
        } else {
          timer.cancel();
          setState(() {
            _remaining = Duration.zero;
          });
          _handleEnded();
        }
      });
    }
  }

  void _handleEnded() {
    if (!_hasTriggeredEnd) {
      _hasTriggeredEnd = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onEnded?.call();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    if (totalSeconds <= 0) return '';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final secondsStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final minutesStr = minutes.toString().padLeft(2, '0');
      return 'Ends in ${hours}h ${minutesStr}m ${secondsStr}s';
    } else {
      return 'Ends in ${minutes}m ${secondsStr}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDuration(_remaining),
      style: GoogleFonts.inter(
        color: AppColors.tertiary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.60,
      ),
    );
  }
}
