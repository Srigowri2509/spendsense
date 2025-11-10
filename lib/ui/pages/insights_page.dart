import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/insights_controller.dart';
import '../../models/insights_data.dart';
import '../theme.dart';
import 'package:app_settings/app_settings.dart';

class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  int _selectedDays = 30;

  @override
  Widget build(BuildContext context) {
    final insightsAsync = ref.watch(insightsProvider(_selectedDays));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(insightsProvider(_selectedDays));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              
              // Time range selector
              _buildTimeRangeSelector(),
              
              const SizedBox(height: 16),
              
              // Content based on async state
              insightsAsync.when(
                data: (insights) => _buildInsightsContent(insights),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => _buildErrorState(error),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            'Time Range:',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                _timeRangeChip(7, '7 days'),
                _timeRangeChip(30, '30 days'),
                _timeRangeChip(90, 'All time'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeRangeChip(int days, String label) {
    final isSelected = _selectedDays == days;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedDays = days;
        });
      },
      selectedColor: AppColors.mint,
      backgroundColor: Colors.grey.shade200,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.ink : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildInsightsContent(InsightsData insights) {
    if (insights.lockedDaysCount == 0 && insights.unlockedDaysCount == 0) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildSummaryCards(insights),
        const SizedBox(height: 16),
        _buildUsageComparison(insights),
        const SizedBox(height: 16),
        _buildPerAppBreakdown(insights),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          const Icon(
            Icons.insights_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No data yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start locking apps to see insights about your usage patterns',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    final isPermissionError = error.toString().contains('permission');
    
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          Text(
            isPermissionError
                ? 'Permission Required'
                : 'Unable to load insights',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPermissionError
                ? 'Grant usage access permission to see detailed insights about your app usage'
                : 'An error occurred while loading your insights',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
            ),
          ),
          if (isPermissionError) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                AppSettings.openAppSettings(type: AppSettingsType.settings);
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCards(InsightsData insights) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _summaryCard(
              icon: Icons.lock,
              iconColor: AppColors.accent,
              title: 'Locked Days',
              value: insights.lockedDaysCount.toString(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _summaryCard(
              icon: Icons.lock_open,
              iconColor: AppColors.mint,
              title: 'Unlocked Days',
              value: insights.unlockedDaysCount.toString(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageComparison(InsightsData insights) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Average Daily Usage',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            
            // Unlocked days bar
            _usageBar(
              label: 'Unlocked Days',
              duration: insights.avgUsageOnUnlockedDays,
              color: Colors.orange,
              maxDuration: _getMaxDuration(insights),
            ),
            
            const SizedBox(height: 12),
            
            // Locked days bar
            _usageBar(
              label: 'Locked Days',
              duration: insights.avgUsageOnLockedDays,
              color: AppColors.mint,
              maxDuration: _getMaxDuration(insights),
            ),
            
            const SizedBox(height: 16),
            
            // Reduction percentage
            if (insights.reductionPercent > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_down,
                      color: Colors.green,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${insights.reductionPercent.toStringAsFixed(1)}% reduction when using locks',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (insights.reductionPercent < 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${insights.reductionPercent.abs().toStringAsFixed(1)}% increase on locked days',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade800,
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
    );
  }

  Duration _getMaxDuration(InsightsData insights) {
    final max = insights.avgUsageOnUnlockedDays.inSeconds >
            insights.avgUsageOnLockedDays.inSeconds
        ? insights.avgUsageOnUnlockedDays
        : insights.avgUsageOnLockedDays;
    return max.inSeconds > 0 ? max : const Duration(hours: 1);
  }

  Widget _usageBar({
    required String label,
    required Duration duration,
    required Color color,
    required Duration maxDuration,
  }) {
    final percentage = maxDuration.inSeconds > 0
        ? (duration.inSeconds / maxDuration.inSeconds)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _formatDuration(duration),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 12,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Widget _buildPerAppBreakdown(InsightsData insights) {
    if (insights.perAppComparison.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedApps = insights.perAppComparison.entries.toList()
      ..sort((a, b) => b.value.changePercent.compareTo(a.value.changePercent));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Per-App Breakdown',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedApps.map((entry) {
              final comparison = entry.value;
              return _appComparisonItem(comparison);
            }),
          ],
        ),
      ),
    );
  }

  Widget _appComparisonItem(AppUsageComparison comparison) {
    final isReduction = comparison.changePercent > 0;
    final color = isReduction ? Colors.green : Colors.red;
    final icon = isReduction ? Icons.trending_down : Icons.trending_up;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  comparison.appName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                '${comparison.changePercent.abs().toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Unlocked: ${_formatDuration(comparison.avgWhenUnlocked)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Locked: ${_formatDuration(comparison.avgWhenLocked)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
