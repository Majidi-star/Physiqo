import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';
import 'physiqo_logo.dart';
import 'physiqo_back_button.dart';
import '../l10n/translations.dart';

/// A single unified header widget for all screens in the Physiqo app.
/// Consolidates both the profile/logo header style and the back-title header style.
class PhysiqoHeader extends StatelessWidget implements PreferredSizeWidget {
  /// The title of the page (if null, renders the profile header).
  final String? title;

  /// Optional subtitle (only for back-title headers, e.g. results analysis).
  final String? subtitle;

  /// Custom action on back button tap (default pops the navigation stack).
  final VoidCallback? onBackTap;

  const PhysiqoHeader({
    super.key,
    this.title,
    this.subtitle,
    this.onBackTap,
  });

  /// Factory constructor for the standard profile/logo header.
  factory PhysiqoHeader.profile({Key? key}) => PhysiqoHeader(key: key);

  /// Factory constructor for the back-title header.
  factory PhysiqoHeader.back({
    Key? key,
    required String title,
    String? subtitle,
    VoidCallback? onBackTap,
  }) {
    return PhysiqoHeader(
      key: key,
      title: title,
      subtitle: subtitle,
      onBackTap: onBackTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasTitle = title != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.gutter,
        AppTheme.spacingMd,
        AppTheme.gutter,
        AppTheme.spacingSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: hasTitle ? _buildBackTitleHeader() : _buildProfileHeader(),
      ),
    );
  }

  List<Widget> _buildProfileHeader() {
    return [
      // Profile on the right (start of row in RTL)
      Expanded(
        child: ListenableBuilder(
          listenable: UserProfile.current(),
          builder: (context, child) {
            final profile = UserProfile.current();
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.surfaceHigh,
                  backgroundImage: profile.photoPath != null ? FileImage(File(profile.photoPath!)) : null,
                  child: profile.photoPath == null ? const Icon(Icons.person, color: AppTheme.textSecondary, size: 20) : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profile.name,
                        style: AppTheme.bodyLg.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${context.tr('header_height')}: ${profile.height} / ${context.tr('header_weight')}: ${profile.weight}',
                        style: AppTheme.labelMd.copyWith(color: AppTheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      const SizedBox(width: 8),
      // Logo on the left (end of row in RTL)
      const PhysiqoLogo(height: 24),
    ];
  }

  List<Widget> _buildBackTitleHeader() {
    return [
      PhysiqoBackButton(onTap: onBackTap),
      const Spacer(),
      if (subtitle != null)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title!, style: AppTheme.headlineMd),
            Text(
              subtitle!,
              style: AppTheme.labelMd.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        )
      else
        Text(title!, style: AppTheme.headlineMd),
      const Spacer(),
      const SizedBox(width: 28), // Balances the back button size for center alignment
    ];
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
