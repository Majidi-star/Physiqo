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
import 'schedule_translations.dart';
import 'chat_translations.dart';

class Translations {
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {...langEn, ...?scheduleTranslations['en'], ...?chatTranslations['en']},
    'fa': {...langFa, ...?scheduleTranslations['fa'], ...?chatTranslations['fa']},
    'zh': {...langZh, ...?scheduleTranslations['zh'], ...?chatTranslations['zh']},
    'es': {...langEs, ...?scheduleTranslations['es'], ...?chatTranslations['es']},
    'ar': {...langAr, ...?scheduleTranslations['ar'], ...?chatTranslations['ar']},
    'fr': {...langFr, ...?scheduleTranslations['fr'], ...?chatTranslations['fr']},
    'ru': {...langRu, ...?scheduleTranslations['ru'], ...?chatTranslations['ru']},
    'pt': {...langPt, ...?scheduleTranslations['pt'], ...?chatTranslations['pt']},
    'hi': {...langHi, ...?scheduleTranslations['hi'], ...?chatTranslations['hi']},
    'bn': {...langBn, ...?scheduleTranslations['bn'], ...?chatTranslations['bn']},
    'ur': {...langUr, ...?scheduleTranslations['ur'], ...?chatTranslations['ur']},
  };

  static const Map<String, Map<String, String>> _extraValues = {
    'en': {
      'settings_user_guide': 'User Guide',
      'onboarding_step_lang': 'Language',
      'onboarding_step_ai': 'AI Setup',
      'onboarding_step_profile': 'Profile',
      'onboarding_lang_subtitle': 'Choose your app language',
      'onboarding_ai_guide_title': 'AI Connection Setup',
      'onboarding_ai_guide_body': 'Physiqo is 100% serverless. Your API keys are saved securely on-device. \n\nRecommended Free Providers:\n\n1. OpenRouter (openrouter.ai): Register to access free Llama 3 or Gemini models.\n2. Nvidia NIM (build.nvidia.com): Sign up to get developer credits for high-speed APIs.\n3. Reka AI (reka.ai): Get free credits for vision & body scan analysis.',
      'onboarding_profile_injuries': 'Injuries & Limitations',
      'onboarding_profile_injuries_hint': 'e.g. knee pain, lower back disc, shoulder stiffness',
      'onboarding_ai_skip': 'Skip & Enter App',
      'onboarding_ai_recommendation': 'Recommended Free Keys',
      'onboarding_ai_setup_success': 'Connection tested successfully!',
      'onboarding_ai_setup_failed': 'Connection test failed. Please verify credentials.',
      'onboarding_next': 'Next',
      'testing_diagnostics_title': 'Testing & Diagnostics',
      'testing_settings_entry': 'Testing & Diagnostics',
      'testing_privacy_note': 'Logs stay on your device. No data is sent to any server. Export only when you choose to share.',
      'testing_enable_logging': 'Enable session logging',
      'testing_include_chat_text': 'Include AI chat text in logs',
      'testing_stat_sessions': 'Stored sessions',
      'testing_stat_size': 'Total size',
      'testing_stat_events': 'Events this session',
      'testing_export': 'Export logs (ZIP)',
      'testing_clear': 'Clear all logs',
      'testing_no_logs': 'No logs to export yet.',
      'testing_clear_confirm_title': 'Clear all logs?',
      'testing_clear_confirm_body': 'This permanently deletes all stored session logs and screenshots on this device. This cannot be undone.',
      'testing_cancel': 'Cancel',
      'testing_consent_title': 'Help improve Physiqo',
      'testing_consent_body': 'Physiqo can record anonymous, on-device interaction logs (taps, screen views, errors) to help diagnose issues. Nothing is sent anywhere automatically. You can review and export logs anytime in Settings, and opt out whenever you like. Do you want to enable session logging?',
      'testing_consent_decline': 'Not now',
      'testing_consent_accept': 'Enable logging',
      'testing_report_title': 'Report an issue',
      'testing_report_hint': 'Describe what happened…',
      'testing_report_thanks': 'Thanks! Your note was attached to this session.',
      'testing_report_submit': 'Submit',
      'test_mode': 'Test Mode',
    },
    'fa': {
      'settings_user_guide': 'راهنمای استفاده',
      'onboarding_step_lang': 'زبان',
      'onboarding_step_ai': 'هوش مصنوعی',
      'onboarding_step_profile': 'پروفایل',
      'onboarding_lang_subtitle': 'زبان برنامه را انتخاب کنید',
      'onboarding_ai_guide_title': 'راهنمای اتصال به هوش مصنوعی',
      'onboarding_ai_guide_body': 'برنامه فیزیکو کاملاً آفلاین‌محور و بدون سرور مرکزی است. کلیدهای ارتباطی (API Key) شما مستقیماً در دستگاه شما به صورت امن ذخیره می‌شوند.\n\nپیشنهاد ما برای مربی رایگان:\n\n۱. OpenRouter (openrouter.ai): برای دسترسی به مدل‌های رایگان لاما و جمینی ثبت‌نام کنید.\n۲. Nvidia NIM (build.nvidia.com): برای دریافت اعتبار رایگان مدل‌های پرسرعت ثبت‌نام کنید.\n۳. Reka AI (reka.ai): برای دریافت اعتبار تحلیل اسکن زنده بدن ثبت‌نام کنید.',
      'onboarding_profile_injuries': 'آسیب‌دیدگی‌ها و محدودیت‌ها',
      'onboarding_profile_injuries_hint': 'مثال: درد زانو، دیسک کمر، کشیدگی کتف',
      'onboarding_ai_skip': 'رد کردن و ورود به برنامه',
      'onboarding_ai_recommendation': 'توصیه‌های کلید رایگان',
      'onboarding_ai_setup_success': 'اتصال با موفقیت تست شد!',
      'onboarding_ai_setup_failed': 'تست ناموفق بود. مجدداً بررسی کنید.',
      'onboarding_next': 'بعدی',
      'testing_diagnostics_title': 'تست و عیب‌یابی',
      'testing_settings_entry': 'تست و عیب‌یابی',
      'testing_privacy_note': 'لاگ‌ها فقط روی دستگاه شما نگه‌داری می‌شوند و به هیچ سروری ارسال نمی‌شوند. خروجی فقط زمانی که خودتان بخواهید.',
      'testing_enable_logging': 'فعال‌سازی ثبت لاگ نشست',
      'testing_include_chat_text': 'شامل متن گفتگوی هوش مصنوعی در لاگ',
      'testing_stat_sessions': 'نشست‌های ذخیره‌شده',
      'testing_stat_size': 'حجم کل',
      'testing_stat_events': 'رویدادهای این نشست',
      'testing_export': 'خروجی لاگ‌ها (ZIP)',
      'testing_clear': 'پاک‌سازی همه لاگ‌ها',
      'testing_no_logs': 'هنوز لاگی برای خروجی وجود ندارد.',
      'testing_clear_confirm_title': 'همه لاگ‌ها پاک شوند؟',
      'testing_clear_confirm_body': 'این کار تمام لاگ‌های نشست و اسکرین‌شات‌های ذخیره‌شده روی این دستگاه را برای همیشه حذف می‌کند و قابل بازگشت نیست.',
      'testing_cancel': 'لغو',
      'testing_consent_title': 'کمک به بهبود فیزیکو',
      'testing_consent_body': 'فیزیکو می‌تواند لاگ‌های تعاملی ناشناس را روی دستگاه ثبت کند (لمس‌ها، بازدید صفحات، خطاها) تا در عیب‌یابی کمک کند. چیزی به‌صورت خودکار ارسال نمی‌شود. هر زمان می‌توانید لاگ‌ها را در تنظیمات مرور و خروجی بگیرید و هر زمان غیرفعال کنید. آیا ثبت لاگ نشست فعال شود؟',
      'testing_consent_decline': 'الان نه',
      'testing_consent_accept': 'فعال‌سازی لاگ',
      'testing_report_title': 'گزارش مشکل',
      'testing_report_hint': 'توضیح دهید چه اتفاقی افتاد…',
      'testing_report_thanks': 'ممنون! یادداشت شما به این نشست پیوست شد.',
      'testing_report_submit': 'ارسال',
      'test_mode': 'حالت تست',
    },
    'zh': {
      'settings_user_guide': '用户指南',
      'onboarding_step_lang': '语言',
      'onboarding_step_ai': 'AI 设置',
      'onboarding_step_profile': '个人资料',
      'onboarding_lang_subtitle': '选择您的应用语言',
      'onboarding_ai_guide_title': 'AI 连接设置',
      'onboarding_ai_guide_body': 'Physiqo 是 100% 无服务器的。您的 API 密钥安全地保存在设备上。\n\n推荐的免费提供商：\n\n1. OpenRouter (openrouter.ai)：注册以访问免费的 Llama 3 或 Gemini 模型。\n2. Nvidia NIM (build.nvidia.com)：注册以获得高速 API 的开发人员额度。\n3. Reka AI (reka.ai)：获得用于视觉和身体扫描分析的免费额度。',
      'onboarding_profile_injuries': '伤病与身体局限',
      'onboarding_profile_injuries_hint': '例如：膝盖疼痛、腰椎间盘突出、肩膀僵硬',
      'onboarding_ai_skip': '跳过并进入应用',
      'onboarding_ai_recommendation': '推荐的免费密钥',
      'onboarding_ai_setup_success': '连接测试成功！',
      'onboarding_ai_setup_failed': '连接测试失败。请核对凭据。',
      'onboarding_next': '下一步',
    },
    'es': {
      'settings_user_guide': 'Guía del Usuario',
      'onboarding_step_lang': 'Idioma',
      'onboarding_step_ai': 'Configuración de IA',
      'onboarding_step_profile': 'Perfil',
      'onboarding_lang_subtitle': 'Elija el idioma de su aplicación',
      'onboarding_ai_guide_title': 'Configuración de Conexión de IA',
      'onboarding_ai_guide_body': 'Physiqo es 100% sin servidor. Sus claves API se guardan de forma segura en el dispositivo.\n\nProveedores Gratuitos Recomendados:\n\n1. OpenRouter (openrouter.ai): Regístrese para acceder a modelos gratuitos de Llama 3 o Gemini.\n2. Nvidia NIM (build.nvidia.com): Regístrese para obtener créditos de desarrollador para APIs de alta velocidad.\n3. Reka AI (reka.ai): Obtenga créditos gratuitos para análisis visual y escaneo corporal.',
      'onboarding_profile_injuries': 'Lesiones y Limitaciones',
      'onboarding_profile_injuries_hint': 'Ej. dolor de rodilla, hernia discal lumbar, rigidez de hombro',
      'onboarding_ai_skip': 'Omitir e ingresar a la aplicación',
      'onboarding_ai_recommendation': 'Claves Gratuitas Recomendadas',
      'onboarding_ai_setup_success': '¡Conexión probada con éxito!',
      'onboarding_ai_setup_failed': 'Error de conexión. Verifique las credenciales.',
      'onboarding_next': 'Siguiente',
    },
    'ar': {
      'settings_user_guide': 'دليل المستخدم',
      'onboarding_step_lang': 'اللغة',
      'onboarding_step_ai': 'إعداد الذكاء الاصطناعي',
      'onboarding_step_profile': 'الملف الشخصي',
      'onboarding_lang_subtitle': 'اختر لغة التطبيق الخاصة بك',
      'onboarding_ai_guide_title': 'إعداد اتصال الذكاء الاصطناعي',
      'onboarding_ai_guide_body': 'تطبيق Physiqo خالي من الخوادم 100%. يتم حفظ مفاتيح API الخاصة بك بأمان على جهازك.\n\nموفرو الخدمة المجانيون الموصى بهم:\n\n1. OpenRouter (openrouter.ai): سجل للوصول إلى نماذج Llama 3 أو Gemini المجانية.\n2. Nvidia NIM (build.nvidia.com): سجل للحصول على رصيد مطور مجاني لواجهات برمجة التطبيقات عالية السرعة.\n3. Reka AI (reka.ai): احصل على رصيد مجاني لتحليل صور مسح الجسم.',
      'onboarding_profile_injuries': 'الإصابات والقيود الطبية',
      'onboarding_profile_injuries_hint': 'مثال: ألم الركبة، ديسك أسفل الظهر، تيبس الكتف',
      'onboarding_ai_skip': 'تخطي والدخول إلى التطبيق',
      'onboarding_ai_recommendation': 'مفاتيح مجانية موصى بها',
      'onboarding_ai_setup_success': 'تم اختبار الاتصال بنجاح!',
      'onboarding_ai_setup_failed': 'فشل اختبار الاتصال. يرجى التحقق من البيانات.',
      'onboarding_next': 'التالي',
    },
    'fr': {
      'settings_user_guide': 'Guide de l\'Utilisateur',
      'onboarding_step_lang': 'Langue',
      'onboarding_step_ai': 'Configuration IA',
      'onboarding_step_profile': 'Profil',
      'onboarding_lang_subtitle': 'Choisissez la langue de votre application',
      'onboarding_ai_guide_title': 'Configuration de la Connexion IA',
      'onboarding_ai_guide_body': 'Physiqo est 100% sans serveur. Vos clés API sont enregistrées en toute sécurité sur votre appareil.\n\nFournisseurs Gratuits Recommandés:\n\n1. OpenRouter (openrouter.ai): Inscrivez-vous pour accéder aux modèles gratuits Llama 3 ou Gemini.\n2. Nvidia NIM (build.nvidia.com): Inscrivez-vous pour obtenir des crédits développeur pour des API ultra-rapides.\n3. Reka AI (reka.ai): Obtenez des crédits gratuits pour l\'analyse visuelle et le scan corporel.',
      'onboarding_profile_injuries': 'Blessures & Limitations',
      'onboarding_profile_injuries_hint': 'Ex. douleur au genou, hernie discale lombaire, raideur de l\'épaule',
      'onboarding_ai_skip': 'Passer et accéder à l\'application',
      'onboarding_ai_recommendation': 'Clés Gratuites Recommandées',
      'onboarding_ai_setup_success': 'Connexion testée avec succès !',
      'onboarding_ai_setup_failed': 'Échec du test de connexion. Veuillez vérifier les informations.',
      'onboarding_next': 'Suivant',
    },
    'ru': {
      'settings_user_guide': 'Руководство пользователя',
      'onboarding_step_lang': 'Язык',
      'onboarding_step_ai': 'Настройка ИИ',
      'onboarding_step_profile': 'Профиль',
      'onboarding_lang_subtitle': 'Выберите язык вашего приложения',
      'onboarding_ai_guide_title': 'Настройка подключения к ИИ',
      'onboarding_ai_guide_body': 'Physiqo работает полностью локально и без серверов. Ваши API-ключи надежно хранятся на устройстве.\n\nРекомендуемые бесплатные сервисы:\n\n1. OpenRouter (openrouter.ai): Зарегистрируйтесь для доступа к бесплатным моделям Llama 3 или Gemini.\n2. Nvidia NIM (build.nvidia.com): Зарегистрируйтесь, чтобы получить бесплатные кредиты разработчика для высокоскоростных моделей.\n3. Reka AI (reka.ai): Получите бесплатный баланс для сканирования тела.',
      'onboarding_profile_injuries': 'Травмы и ограничения',
      'onboarding_profile_injuries_hint': 'Например: боль в колене, грыжа поясничного отдела, жесткость плеча',
      'onboarding_ai_skip': 'Пропустить и войти в приложение',
      'onboarding_ai_recommendation': 'Рекомендуемые бесплатные ключи',
      'onboarding_ai_setup_success': 'Подключение успешно протестировано!',
      'onboarding_ai_setup_failed': 'Ошибка подключения. Пожалуйста, проверьте данные.',
      'onboarding_next': 'Далее',
    },
    'pt': {
      'settings_user_guide': 'Guia do Usuário',
      'onboarding_step_lang': 'Idioma',
      'onboarding_step_ai': 'Configuração de IA',
      'onboarding_step_profile': 'Perfil',
      'onboarding_lang_subtitle': 'Escolha o idioma do seu aplicativo',
      'onboarding_ai_guide_title': 'Configuração da Conexão de IA',
      'onboarding_ai_guide_body': 'Physiqo é 100% sem servidor. Suas chaves API são salvas com segurança no dispositivo.\n\nProvedores Gratuitos Recomendados:\n\n1. OpenRouter (openrouter.ai): Registre-se para acessar modelos Llama 3 ou Gemini gratuitos.\n2. Nvidia NIM (build.nvidia.com): Registre-se para obter créditos de desenvolvedor para APIs de alta velocidade.\n3. Reka AI (reka.ai): Obtenha créditos gratuitos para análise visual e escaneamento corporal.',
      'onboarding_profile_injuries': 'Lesões e Limitações',
      'onboarding_profile_injuries_hint': 'Ex. dor no joelho, hérnia de disco lombar, rigidez no ombro',
      'onboarding_ai_skip': 'Pular e entrar no aplicativo',
      'onboarding_ai_recommendation': 'Chaves Gratuitas Recomendadas',
      'onboarding_ai_setup_success': 'Conexão testada com sucesso!',
      'onboarding_ai_setup_failed': 'Falha no teste de conexão. Verifique as credenciais.',
      'onboarding_next': 'Avançar',
    },
    'hi': {
      'settings_user_guide': 'उपयोगकर्ता गाइड',
      'onboarding_step_lang': 'भाषा',
      'onboarding_step_ai': 'एआई सेटअप',
      'onboarding_step_profile': 'प्रोफ़ाइल',
      'onboarding_lang_subtitle': 'अपनी ऐप भाषा चुनें',
      'onboarding_ai_guide_title': 'एआई कनेक्शन सेटअप',
      'onboarding_ai_guide_body': 'Physiqo 100% सर्वर रहित है। आपकी एपी进ी कुंजियाँ डिवाइस पर सुरक्षित रूप से सहेजी जाती हैं।\n\nअनुशंसित मुफ्त प्रदाता:\n\n1. OpenRouter (openrouter.ai): मुफ्त Llama 3 या Gemini मॉडल के लिए साइन अप करें।\n2. Nvidia NIM (build.nvidia.com): हाई-स्पीड एपीआई के लिए मुफ्त डेवलपर क्रेडिट प्राप्त करें।\n3. Reka AI (reka.ai): बॉडी स्कैन विश्लेषण के लिए मुफ्त क्रेडिट प्राप्त करें।',
      'onboarding_profile_injuries': 'चोटें और शारीरिक सीमाएँ',
      'onboarding_profile_injuries_hint': 'उदा. घुटने का दर्द, पीठ के निचले हिस्से का डिस्क, कंधे की जकड़न',
      'onboarding_ai_skip': 'छोड़ें और ऐप में प्रवेश करें',
      'onboarding_ai_recommendation': 'अनुशंसित मुफ्त कुंजियाँ',
      'onboarding_ai_setup_success': 'कनेक्शन का सफलतापूर्वक परीक्षण किया गया!',
      'onboarding_ai_setup_failed': 'कनेक्शन परीक्षण विफल रहा। कृपया क्रेडेंशियल सत्यापित करें।',
      'onboarding_next': 'अगला',
    },
    'bn': {
      'settings_user_guide': 'ব্যবহারকারী নির্দেশিকা',
      'onboarding_step_lang': 'ভাষা',
      'onboarding_step_ai': 'এআই সেটআপ',
      'onboarding_step_profile': 'প্রোফাইল',
      'onboarding_lang_subtitle': 'আপনার অ্যাপের ভাষা নির্বাচন করুন',
      'onboarding_ai_guide_title': 'এআই সংযোগ সেটআপ',
      'onboarding_ai_guide_body': 'Physiqo ১০০% সার্ভারহীন। আপনার API কীগুলি ডিভাইসে নিরাপদে সংরক্ষিত থাকে।\n\nঅনুমোদিত ফ্রি প্রোভাইডারসমূহ:\n\n১. OpenRouter (openrouter.ai): ফ্রি Llama 3 বা Gemini মডেল ব্যবহার করতে নিবন্ধন করুন।\n২. Nvidia NIM (build.nvidia.com): হাই-স্পিড মডেলের জন্য বিনামূল্যে ডেভেলপার ক্রেডিট পান।\n৩. Reka AI (reka.ai): বডি স্ক্যান বিশ্লেষণের জন্য ফ্রি ক্রেডিট পান।',
      'onboarding_profile_injuries': 'আঘাত এবং শারীরিক সীমাবদ্ধতা',
      'onboarding_profile_injuries_hint': 'যেমন: হাঁটু ব্যথা, লোয়ার ব্যাক ডিস্কের সমস্যা, কাঁধের শক্ততা',
      'onboarding_ai_skip': 'ড়িয়ে যান এবং অ্যাপে প্রবেশ করুন',
      'onboarding_ai_recommendation': 'প্রস্তাবিত ফ্রি কীসমূহ',
      'onboarding_ai_setup_success': 'সংযোগ সফলভাবে পরীক্ষা করা হয়েছে!',
      'onboarding_ai_setup_failed': 'সংযোগ পরীক্ষা ব্যর্থ হয়েছে। ক্রেডেনশিয়াল যাচাই করুন।',
      'onboarding_next': 'পরবর্তী',
    },
    'ur': {
      'settings_user_guide': 'صارف گائیڈ',
      'onboarding_step_lang': 'زبان',
      'onboarding_step_ai': 'اے آئی سیٹ اپ',
      'onboarding_step_profile': 'پروفائل',
      'onboarding_lang_subtitle': 'اپنی ایپ کی زبان منتخب کریں',
      'onboarding_ai_guide_title': 'اے آئی کنکشن سیٹ اپ',
      'onboarding_ai_guide_body': 'فیزیکو ۱۰۰٪ سرور کے بغیر ہے۔ آپ کی API کیز ڈیوائس پر محفوظ طریقے سے محفوظ رہتی ہیں۔\n\nمفت فراہم کنندگان کی سفارش:\n\n۱. OpenRouter (openrouter.ai): مفت Llama 3 یا Gemini ماڈلز کے لیے سائن اپ کریں۔\n۲. Nvidia NIM (build.nvidia.com): تیز رفتار ماڈلز کے لیے مفت ڈویلپر کریڈٹ حاصل کریں۔\n۳. Reka AI (reka.ai): باڈی اسکین تجزیہ کے لیے مفت کریڈٹ حاصل کریں۔',
      'onboarding_profile_injuries': 'چوٹیں اور جسمانی حدود',
      'onboarding_profile_injuries_hint': 'مثال: گھٹنے کا درد، کمر کے نچلے حصے کا ڈسک، کندھے کی جکڑن',
      'onboarding_ai_skip': 'چھوڑیں اور ایپ میں داخل ہوں',
      'onboarding_ai_recommendation': 'سفارش کردہ مفت کیز',
      'onboarding_ai_setup_success': 'کنکشن کا کامیابی سے تجربہ کیا گیا!',
      'onboarding_ai_setup_failed': 'کنکشن کا تجربہ ناکام رہا۔ براہ کرم معلومات کی تصدیق کریں۔',
      'onboarding_next': 'اگلا',
    }
  };

  static String get(BuildContext context, String key) {
    final locale = Localizations.localeOf(context);
    final langCode = locale.languageCode;

    if (_extraValues.containsKey(langCode) && _extraValues[langCode]!.containsKey(key)) {
      return _extraValues[langCode]![key]!;
    }
    if (_extraValues['en']!.containsKey(key)) {
      return _extraValues['en']![key]!;
    }

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
