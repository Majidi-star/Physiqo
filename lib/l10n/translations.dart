import 'package:flutter/widgets.dart';

import 'lang_en.dart';
import 'lang_fa.dart';
import 'lang_zh.dart';
import 'lang_es.dart';
import 'lang_ar.dart';
import 'lang_fr.dart';
import 'lang_ru.dart';
import 'lang_pt.dart';
import 'lang_hi.dart';
import 'lang_bn.dart';
import 'lang_ur.dart';

class Translations {
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': langEn,
    'fa': langFa,
    'zh': langZh,
    'es': langEs,
    'ar': langAr,
    'fr': langFr,
    'ru': langRu,
    'pt': langPt,
    'hi': langHi,
    'bn': langBn,
    'ur': langUr,
  };

  static String get(BuildContext context, String key) {
    final locale = Localizations.localeOf(context);
    final langCode = locale.languageCode;
    final otherLangCode = langCode == 'en' ? 'fa' : 'en';
    
    final langMap = _localizedValues[langCode] ?? _localizedValues['en']!;
    final otherLangMap = _localizedValues[otherLangCode] ?? _localizedValues['en']!;
    
    String? val = langMap[key];
    if (val == null || val == key) {
      val = otherLangMap[key];
    }
    
    return (val == null || val == key) ? key : val;
  }
}

extension TranslationExtension on BuildContext {
  String tr(String key) => Translations.get(this, key);
}
