import 'dart:io';
import 'package:flutter/material.dart';
import 'package:physiqo/l10n/translations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/physiqo_header.dart';
import '../../utils/account_manager.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  void _switchAccount(String id) async {
    if (AccountManager.currentAccountId == id) return;
    
    await AccountManager.switchAccount(id);
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/main', (r) => false);
    }
  }

  void _deleteAccount(String id) async {
    if (AccountManager.accounts.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('err_delete_last_account'))),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceHigh,
        title: Text(context.tr('delete_account_title'), style: AppTheme.headlineMd),
        content: Text(context.tr('delete_account_desc'), style: AppTheme.bodyMd),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('action_cancel'), style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('action_delete'), style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AccountManager.deleteAccount(id);
      if (mounted) {
        if (AccountManager.currentAccountId == id) {
          // If we deleted the active account, restart app basically
          Navigator.pushNamedAndRemoveUntil(context, '/main', (r) => false);
        } else {
          setState(() {});
        }
      }
    }
  }

  void _addAccount() {
    Navigator.pushNamed(context, '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final accounts = AccountManager.accounts;
    final activeId = AccountManager.currentAccountId;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              PhysiqoHeader.back(
                title: context.tr('settings_accounts'),
                onBackTap: () => Navigator.pop(context),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.gutter),
                  itemCount: accounts.length + 1,
                  itemBuilder: (context, index) {
                    if (index == accounts.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: AppTheme.spacingLg),
                        child: ElevatedButton.icon(
                          onPressed: _addAccount,
                          icon: const Icon(Icons.add, color: AppTheme.onPrimary),
                          label: Text(
                            context.tr('action_add_account'),
                            style: const TextStyle(
                              color: AppTheme.onPrimary,
                              fontFamily: 'Vazirmatn',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                          ),
                        ),
                      );
                    }

                    final acc = accounts[index];
                    final isActive = acc.id == activeId;

                    return GestureDetector(
                      onTap: () => _switchAccount(acc.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingMd),
                        margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceHigh,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          border: Border.all(
                            color: isActive ? AppTheme.primary : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppTheme.surface,
                              backgroundImage: acc.photoPath != null ? FileImage(File(acc.photoPath!)) : null,
                              child: acc.photoPath == null 
                                ? const Icon(Icons.person, color: AppTheme.textSecondary, size: 20)
                                : null,
                            ),
                            const SizedBox(width: AppTheme.spacingMd),
                            Expanded(
                              child: Text(
                                acc.name,
                                style: AppTheme.bodyLg.copyWith(
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                  color: isActive ? AppTheme.primary : AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            if (isActive)
                              const Icon(Icons.check_circle, color: AppTheme.primary)
                            else
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                                onPressed: () => _deleteAccount(acc.id),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
