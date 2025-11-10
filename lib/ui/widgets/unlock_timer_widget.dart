import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';

class UnlockTimerWidget extends StatefulWidget {
  final DateTime expiresAt;

  const UnlockTimerWidget({
    super.key,
    required this.expiresAt,
  });

  @override
  State<UnlockTimerWidget> createState() => _UnlockTimerWidgetState();
}

class _UnlockTimerWidgetState extends State<UnlockTimerWidget> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    final now = DateTime.now();
    if (widget.expiresAt.isAfter(now)) {
      setState(() {
        _remaining = widget.expiresAt.difference(now);
      });
    } else {
      setState(() {
        _remaining = Duration.zero;
      });
      _timer?.cancel();
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining.inSeconds <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 51),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.mint, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_open,
            size: 16,
            color: AppColors.ink,
          ),
          const SizedBox(width: 6),
          Text(
            'Unlocked for ${_formatDuration(_remaining)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
