import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/translations.dart';
import '../../services/test_logger.dart';
import '../../theme/app_theme.dart';
import '../../widgets/physiqo_header.dart';

/// Hidden diagnostics screen for exporting on-device session logs.
///
/// Accessible only via the hidden tap trigger on the splash `test mode''
/// label. Logging is always-on during the testing phase; this screen exists
/// solely to export or clear the accumulated JSONL logs.
class TestingDiagnosticsScreen extends StatefulWidget {
  const TestingDiagnosticsScreen({super.key});

  @override
  State<TestingDiagnosticsScreen> createState() =>
      _TestingDiagnosticsScreenState();
}

class _TestingDiagnosticsScreenState extends State<TestingDiagnosticsScreen> {
  int _sessionCount = 0;
  int _totalSizeBytes = 0;
  int _currentEventCount = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  Future<void> _refreshStats() async {
    final s = await TestLogger.instance.getStats();
    if (mounted) {
      setState(() {
        _sessionCount = s.sessionCount;
        _totalSizeBytes = s.totalSizeBytes;
        _currentEventCount = s.currentSessionEventCount;
      });
    }
  }

  String _fmtBytes(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              PhysiqoHeader.back(
                title: context.tr('testing_diagnostics_title'),
                onBackTap: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppTheme.spacingMd),
                      _StatsCard(
                        sessionCount: _sessionCount,
                        totalSize: _fmtBytes(_totalSizeBytes),
                        currentEvents: _currentEventCount,
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      _ActionRow(
                        icon: Icons.ios_share,
                        label: context.tr('testing_export'),
                        enabled: !_busy,
                        onTap: () => _export(context),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      _ActionRow(
                        icon: Icons.delete_outline,
                        label: context.tr('testing_clear'),
                        isDestructive: true,
                        enabled: !_busy,
                        onTap: () => _clear(context),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final noLogsMsg = context.tr('testing_no_logs');
    setState(() => _busy = true);
    try {
      final file = await TestLogger.instance.exportLogs();
      if (file == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(noLogsMsg)),
        );
        return;
      }
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Physiqo testing logs',
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
      await _refreshStats();
    }
  }

  Future<void> _clear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: const BorderSide(color: AppTheme.outline, width: 1),
        ),
        title: Text(context.tr('testing_clear_confirm_title'),
            style: AppTheme.headlineMd),
        content: Text(context.tr('testing_clear_confirm_body'),
            style: AppTheme.bodyMd.copyWith(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('testing_cancel'),
                style: AppTheme.bodyMd
                    .copyWith(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('testing_clear'),
                style: AppTheme.bodyMd.copyWith(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await TestLogger.instance.clearLogs();
    } finally {
      if (mounted) setState(() => _busy = false);
      await _refreshStats();
    }
  }
}

class _StatsCard extends StatelessWidget {
  final int sessionCount;
  final String totalSize;
  final int currentEvents;
  const _StatsCard({
    required this.sessionCount,
    required this.totalSize,
    required this.currentEvents,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        children: [
          _statRow(context.tr('testing_stat_sessions'), '$sessionCount'),
          const Divider(color: AppTheme.outline, height: 1),
          _statRow(context.tr('testing_stat_size'), totalSize),
          const Divider(color: AppTheme.outline, height: 1),
          _statRow(context.tr('testing_stat_events'), '$currentEvents'),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTheme.bodyMd
                  .copyWith(color: AppTheme.textSecondary)),
          Text(value,
              style: AppTheme.bodyLg.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final bool enabled;
  final VoidCallback onTap;
  const _ActionRow({
    required this.icon,
    required this.label,
    this.isDestructive = false,
    this.enabled = true,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppTheme.error : AppTheme.textPrimary;
    return Container(
      decoration: AppTheme.cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd, vertical: 14),
          child: Row(
            children: [
              Icon(icon,
                  color: enabled ? color : AppTheme.textSecondary, size: 22),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Text(label,
                    style: AppTheme.bodyMd.copyWith(
                        color: enabled ? color : AppTheme.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
