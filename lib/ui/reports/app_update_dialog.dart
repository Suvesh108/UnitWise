import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/native/native_channel.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';

class AppUpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const AppUpdateDialog({super.key, required this.updateInfo});

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  bool _isDownloading = false;
  int _progress = 0;
  int _downloaded = 0;
  int _total = 0;
  bool _isDownloaded = false;
  String? _downloadedFilePath;
  String? _errorMessage;

  Future<void> _startDownload() async {
    NativeChannel.triggerHaptic();
    setState(() {
      _isDownloading = true;
      _progress = 0;
      _errorMessage = null;
    });

    try {
      final filePath = await NativeChannel.startUpdateDownload(
        url: widget.updateInfo.downloadUrl,
        version: widget.updateInfo.latestVersion,
        onProgress: (progress, downloaded, total) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _downloaded = downloaded;
              _total = total;
            });
          }
        },
      );

      if (mounted) {
        if (filePath != null) {
          setState(() {
            _isDownloading = false;
            _isDownloaded = true;
            _downloadedFilePath = filePath;
            _progress = 100;
          });
        } else {
          setState(() {
            _isDownloading = false;
            _errorMessage = 'Failed to download update package.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = 'Download error: $e';
        });
      }
    }
  }

  Future<void> _installUpdate() async {
    NativeChannel.triggerHaptic();
    if (_downloadedFilePath != null) {
      final success = await NativeChannel.installUpdate(_downloadedFilePath!);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Installation intent launched. Follow system prompt to install.'),
            backgroundColor: AppTheme.emeraldPrimary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.updateInfo;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, size: 14, color: AppTheme.emeraldPrimary),
                      const SizedBox(width: 5),
                      Text(
                        'NEW UPDATE AVAILABLE',
                        style: AppTypography.style(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.emeraldPrimary,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: AppTheme.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 16, color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Title and Version
            Text(
              'UnitWise v${info.latestVersion}',
              style: AppTypography.style(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Installed: v${info.currentVersion} • Update: v${info.latestVersion} (${info.fileSizeMb} MB)',
              style: AppTypography.style(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),

            // Release Notes Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What\'s New:',
                    style: AppTypography.style(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    info.releaseNotes,
                    style: AppTypography.style(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Internal Download Banner Notice
            Row(
              children: [
                const Icon(Icons.shield_outlined, size: 16, color: AppTheme.emeraldPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    kIsWeb
                        ? 'Internal In-App Updater (Web Simulation Active)'
                        : 'Downloads internally via Kotlin OTA without browser / Chrome.',
                    style: AppTypography.style(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress Bar if Downloading
            if (_isDownloading) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Downloading update package...',
                    style: AppTypography.style(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    '$_progress%',
                    style: AppTypography.style(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.emeraldPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress / 100.0,
                  backgroundColor: AppTheme.borderSubtle,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.emeraldPrimary),
                  minHeight: 8,
                ),
              ),
              if (_total > 0) ...[
                const SizedBox(height: 6),
                Text(
                  '${(_downloaded / (1024 * 1024)).toStringAsFixed(1)} MB / ${(_total / (1024 * 1024)).toStringAsFixed(1)} MB',
                  style: AppTypography.style(fontSize: 11, color: AppTheme.textSubtle),
                ),
              ],
              const SizedBox(height: 12),
            ],

            // Error display
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.alertCoral.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: AppTheme.alertCoral),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTypography.style(fontSize: 11.5, color: AppTheme.alertCoral),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Actions
            if (_isDownloaded) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppTheme.emeraldPrimary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Package downloaded internally to app cache. Ready to install.',
                        style: AppTypography.style(
                          fontSize: 12,
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.system_update_rounded, size: 18),
                  label: const Text('Install Update Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emeraldPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _installUpdate,
                ),
              ),
            ] else if (!_isDownloading) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.borderSubtle),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Later'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Update Internally'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emeraldPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _startDownload,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
