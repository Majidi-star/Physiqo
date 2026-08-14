import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/user_profile.dart';

class AccountManager {
  static const String _keyAccounts = 'app_accounts';
  static const String _keyActiveAccountId = 'app_active_account_id';
  
  static List<Account> _accounts = [];
  static String? _activeAccountId;

  static List<Account> get accounts => _accounts;
  static Account? get currentAccount => _accounts.cast<Account?>().firstWhere((a) => a?.id == _activeAccountId, orElse: () => null);
  static String? get currentAccountId => _activeAccountId;
  
  static bool hasAccounts() => _accounts.isNotEmpty;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if migration is needed
    final legacyName = prefs.getString('user_name');
    final hasAccountsSaved = prefs.containsKey(_keyAccounts);
    
    if (!hasAccountsSaved && legacyName != null) {
      // Migrate legacy user to an account
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      final legacyPhoto = prefs.getString('user_photoPath');
      final acc = Account(id: newId, name: legacyName, photoPath: legacyPhoto);
      _accounts = [acc];
      _activeAccountId = newId;
      
      final keysToMigrate = [
        'user_name', 'user_height', 'user_weight', 'user_photoPath', 
        'user_age', 'user_gender', 'user_experienceLevel', 'user_primaryGoal',
        'user_equipmentAccess', 'user_limitations', 'user_additionalNotes',
        'unit_system', 'workout_days', 'default_rest_time', 'physiqo_exercises', 'physiqo_chats'
      ];
      for (final k in keysToMigrate) {
        final val = prefs.get(k);
        if (val != null) {
          final newKey = '${newId}_$k';
          if (val is String) await prefs.setString(newKey, val);
          if (val is int) await prefs.setInt(newKey, val);
          if (val is double) await prefs.setDouble(newKey, val);
          if (val is bool) await prefs.setBool(newKey, val);
          if (val is List<String>) await prefs.setStringList(newKey, val);
        }
      }
      
      await _saveState(prefs);
      return;
    }

    final accountsJson = prefs.getString(_keyAccounts);
    if (accountsJson != null) {
      final List<dynamic> decoded = jsonDecode(accountsJson);
      _accounts = decoded.map((e) => Account.fromJson(e)).toList();
    }
    
    _activeAccountId = prefs.getString(_keyActiveAccountId);
    
    // fallback if active id is lost but accounts exist
    if (_activeAccountId == null && _accounts.isNotEmpty) {
      _activeAccountId = _accounts.first.id;
      await prefs.setString(_keyActiveAccountId, _activeAccountId!);
    }
  }

  static String getPrefKey(String key) {
    if (_activeAccountId == null) return key; // fallback
    return '${_activeAccountId}_$key';
  }

  static Future<void> addAccount(Account account) async {
    _accounts.add(account);
    if (_activeAccountId == null) {
      _activeAccountId = account.id;
    }
    final prefs = await SharedPreferences.getInstance();
    await _saveState(prefs);
  }

  static Future<void> switchAccount(String id) async {
    _activeAccountId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveAccountId, id);
    await UserProfile.current().loadFromPrefs();
  }

  static Future<void> deleteAccount(String id) async {
    _accounts.removeWhere((a) => a.id == id);
    if (_activeAccountId == id && _accounts.isNotEmpty) {
      _activeAccountId = _accounts.first.id;
    } else if (_accounts.isEmpty) {
      _activeAccountId = null;
    }
    
    final prefs = await SharedPreferences.getInstance();
    await _saveState(prefs);
    
    // Clean up keys for deleted account to save space
    final prefix = '${id}_';
    final keysToRemove = prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
    for (final k in keysToRemove) {
      await prefs.remove(k);
    }
  }

  static Future<void> updateCurrentAccount({required String name, String? photoPath}) async {
    if (_activeAccountId == null) return;
    
    final index = _accounts.indexWhere((a) => a.id == _activeAccountId);
    if (index != -1) {
      _accounts[index] = Account(
        id: _activeAccountId!,
        name: name,
        photoPath: photoPath,
      );
      final prefs = await SharedPreferences.getInstance();
      await _saveState(prefs);
    }
  }

  static Future<void> _saveState(SharedPreferences prefs) async {
    final accountsJson = jsonEncode(_accounts.map((a) => a.toJson()).toList());
    await prefs.setString(_keyAccounts, accountsJson);
    if (_activeAccountId != null) {
      await prefs.setString(_keyActiveAccountId, _activeAccountId!);
    } else {
      await prefs.remove(_keyActiveAccountId);
    }
  }
}
