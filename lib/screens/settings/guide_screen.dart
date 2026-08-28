import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/physiqo_header.dart';
import '../../l10n/translations.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  static const Map<String, Map<String, String>> _localizedGuides = {
    'en': {
      'serverless_title': 'Serverless Architecture',
      'serverless_body': 'Physiqo runs entirely offline-first on your device. Your AI API keys are saved securely in local storage, and your workouts are generated without any cloud subscription fees.',
      'providers_title': 'Free AI Key Providers',
      'providers_body': 'To get API keys without any financial subscription, check these free tiers:\n\n1. OpenRouter (openrouter.ai):\nCreate a free account to access free-tier endpoints (like Llama-3 free-tier models).\n\n2. Nvidia NIM (build.nvidia.com):\nNvidia gives substantial free developer credits to access high-speed models upon sign up.\n\n3. Reka AI (reka.ai):\nIdeal for body scan analysis and image parsing with generous free credits.',
      'injuries_title': 'Importance of Injury Profile',
      'injuries_body': 'When setting up your fitness profile, be sure to detail any active injuries (e.g. knee pain, lower back disc issues). The AI coach automatically scans these limitations to filter out dangerous routines and swap in safer alternative movements.',
    },
    'fa': {
      'serverless_title': 'معماری بدون سرور (Serverless)',
      'serverless_body': 'برنامه فیزیکو کاملاً آفلاین‌محور و بدون سرور مرکزی است. برای ساخت برنامه‌های تمرینی، کلیدهای ارتباطی (API Key) شما مستقیماً در دستگاه شما به صورت امن ذخیره می‌شوند و هیچ اطلاعات خصوصی به سرورهای خارجی ارسال نخواهد شد.',
      'providers_title': 'ارائه‌دهندگان کلید هوش مصنوعی رایگان',
      'providers_body': 'برای دریافت کلیدهای رایگان و بدون هزینه از سرویس‌های زیر استفاده کنید:\n\n۱. OpenRouter (openrouter.ai):\nبا ساخت حساب کاربری، می‌توانید از ده‌ها مدل رایگان و پرسرعت (مانند Llama 3) بدون نیاز به پرداخت مالی استفاده کنید.\n\n۲. Nvidia NIM (build.nvidia.com):\nشرکت انویدیا با ثبت‌نام اولیه، حجم قابل توجهی اعتبار توسعه‌دهنده رایگان برای دسترسی به سریع‌ترین مدل‌های زبانی به شما هدیه می‌دهد.\n\n۳. Reka AI (reka.ai):\nبرای تحلیل چندرسانه‌ای اسکن بدن و تصاویر، اعتبار آزمایشی رایگان خوبی ارائه می‌دهد.',
      'injuries_title': 'نقش آسیب‌دیدگی‌ها در ساخت برنامه',
      'injuries_body': 'هنگام تنظیم پروفایل تناسب اندام، حتماً آسیب‌دیدگی‌ها یا محدودیت‌های فیزیکی خود را بنویسید (مثلاً: درد زانو در اسکوات، دیسک کمر خفیف). هوش مصنوعی مربی فیزیکو به طور خودکار حرکات سنگین روی آن نواحی را حذف کرده یا حرکات جایگزین امن‌تری برای شما در برنامه تمرینی قرار می‌دهد.',
    },
    'zh': {
      'serverless_title': '无服务器架构',
      'serverless_body': 'Physiqo 完全在您的设备上本地运行。您的 AI API 密钥安全地保存在本地存储中，无需支付任何云订阅费用即可生成运动计划。',
      'providers_title': '免费 AI 密钥提供商',
      'providers_body': '要免费获取 API 密钥，请查看以下免费额度：\n\n1. OpenRouter (openrouter.ai)：\n创建免费账户以访问免费端点（如 Llama-3 免费模型）。\n\n2. Nvidia NIM (build.nvidia.com)：\n注册后，英伟达提供大量免费的开发者额度来使用高速模型。\n\n3. Reka AI (reka.ai)：\n非常适合用于人脸和身体扫描分析的免费图像解析额度。',
      'injuries_title': '伤病资料的重要性',
      'injuries_body': '在设置您的健身资料时，请务必详细说明任何现有的伤病（例如膝盖疼痛、腰椎间盘问题）。AI 教练会自动扫描这些限制，过滤掉危险的动作，并换成更安全的替代动作。',
    },
    'hi': {
      'serverless_title': 'सर्वर रहित आर्किटेक्चर',
      'serverless_body': 'Physiqo पूरी तरह से आपके डिवाइस पर पहले ऑफ़लाइन काम करता है। आपके AI API की स्थानीय स्टोरेज में सुरक्षित रूप से सहेजे जाते हैं, और आपके वर्कआउट बिना किसी क्लाउड सदस्यता शुल्क के उत्पन्न होते हैं।',
      'providers_title': 'मुफ्त एआई कुंजी प्रदाता',
      'providers_body': 'बिना किसी वित्तीय सदस्यता के एपीआई कुंजियाँ प्राप्त करने के लिए, इन मुफ्त स्तरों की जाँच करें:\n\n1. OpenRouter (openrouter.ai):\nमुफ्त-स्तरीय एंडपॉइंट्स (जैसे Llama-3 मुफ्त मॉडल) तक पहुंचने के लिए एक निःशुल्क खाता बनाएं।\n\n2. Nvidia NIM (build.nvidia.com):\nएनवीडिया साइन अप करने पर उच्च गति वाले मॉडल तक पहुंचने के लिए पर्याप्त मुफ्त डेवलपर क्रेडिट देता है।\n\n3. Reka AI (reka.ai):\nउदार मुफ्त क्रेडिट के साथ बॉडी स्कैन विश्लेषण और छवि पार्सिंग के लिए आदर्श।',
      'injuries_title': 'चोट प्रोफ़ाइल का महत्व',
      'injuries_body': 'अपनी फिटनेस प्रोफ़ाइल सेट करते समय, किसी भी सक्रिय चोट (जैसे घुटने का दर्द, पीठ के निचले हिस्से की डिस्क की समस्या) का विवरण देना सुनिश्चित करें। एआई कोच इन सीमाओं को स्कैन करता है ताकि खतरनाक व्यायामों को हटाया जा सके और सुरक्षित वैकल्पिक मूवमेंट को जोड़ा जा सके।',
    },
    'es': {
      'serverless_title': 'Arquitectura sin servidor',
      'serverless_body': 'Physiqo funciona de forma local en tu dispositivo. Tus claves API de IA se guardan de forma segura en el almacenamiento local y tus entrenamientos se generan sin cargos de suscripción en la nube.',
      'providers_title': 'Proveedores de claves de IA gratuitas',
      'providers_body': 'Para obtener claves API sin suscripciones financieras, prueba estos niveles gratuitos:\n\n1. OpenRouter (openrouter.ai):\nCrea una cuenta gratuita para acceder a endpoints gratuitos (como los modelos gratuitos Llama-3).\n\n2. Nvidia NIM (build.nvidia.com):\nNvidia otorga créditos de desarrollo gratuitos para acceder a modelos de alta velocidad al registrarte.\n\n3. Reka AI (reka.ai):\nIdeal para análisis de escaneo corporal y procesamiento de imágenes con generosos créditos gratuitos.',
      'injuries_title': 'Importancia de registrar lesiones',
      'injuries_body': 'Al configurar tu perfil de fitness, asegúrate de detallar cualquier lesión activa (por ejemplo, dolor de rodilla, problemas de disco lumbar). El entrenador de IA escanea automáticamente estas limitaciones para filtrar rutinas peligrosas y cambiarlas por movimientos alternativos más seguros.',
    },
    'ar': {
      'serverless_title': 'بنية بدون خادم',
      'serverless_body': 'يعمل Physiqo بشكل كامل دون اتصال بالإنترنت أولاً على جهازك. يتم حفظ مفاتيح AI API الخاصة بك بأمان في التخزين المحلي, ويتم إنشاء تمارينك دون أي رسوم اشتراك سحابي.',
      'providers_title': 'موفرو مفاتيح الذكاء الاصطناعي المجانية',
      'providers_body': 'للحصول على مفاتيح API دون أي اشتراكات مالية، تحقق من المستويات المجانية التالية:\n\n1. OpenRouter (openrouter.ai):\nأنشئ حسابًا مجانيًا للوصول إلى النماذج المجانية (مثل موديلات Llama-3 المجانية).\n\n2. Nvidia NIM (build.nvidia.com):\nتمنحك Nvidia أرصدة مطور مجانية كبيرة للوصول إلى النماذج عالية السرعة عند التسجيل.\n\n3. Reka AI (reka.ai):\nمثالي لتحليل صور مسح الجسم مع أرصدة مجانية سخية.',
      'injuries_title': 'أهمية ملف الإصابات',
      'injuries_body': 'عند إعداد ملفك البدني، تأكد من تفصيل أي إصابات نشطة (مثل ألم الركبة، مشاكل ديسك أسفل الظهر). يقوم مدرب الذكاء الاصطناعي تلقائيًا بفحص هذه القيود لتصفية الحركات الخطيرة واستبدالها بحركات بديلة أكثر أمانًا.',
    },
    'fr': {
      'serverless_title': 'Architecture sans serveur',
      'serverless_body': 'Physiqo fonctionne entièrement en local sur votre appareil. Vos clés API IA sont enregistrées en toute sécurité dans le stockage local et vos entraînements sont générés sans frais d\'abonnement cloud.',
      'providers_title': 'Fournisseurs de clés IA gratuites',
      'providers_body': 'Pour obtenir des clés API sans aucun abonnement financier, consultez ces offres gratuites :\n\n1. OpenRouter (openrouter.ai) :\nCréez un compte gratuit pour accéder aux modèles de l\'offre gratuite (comme Llama-3).\n\n2. Nvidia NIM (build.nvidia.com) :\nNvidia offre d\'importants crédits de développement gratuits lors de votre inscription pour accéder à des modèles ultra-rapides.\n\n3. Reka AI (reka.ai) :\nIdéal pour l\'analyse de scans corporels et l\'analyse d\'images grâce à des crédits gratuits généreux.',
      'injuries_title': 'Importance du profil de blessures',
      'injuries_body': 'Lors de la configuration de votre profil, veillez à détailler toute blessure active (ex. douleur au genou, hernie discale). L\'entraîneur IA analyse automatiquement ces limites pour filtrer les exercices dangereux et proposer des alternatives plus sûres.',
    },
    'bn': {
      'serverless_title': 'সার্ভারহীন আর্কিটেকচার',
      'serverless_body': 'Physiqo সম্পূর্ণ অফলাইন-ফার্স্ট সিস্টেমে আপনার ডিভাইসে কাজ করে। আপনার AI API কীগুলি লোকাল স্টোরেজে সুরক্ষিতভাবে সংরক্ষিত থাকে এবং কোনো ক্লাউড সাবস্ক্রিপশন ফি ছাড়াই আপনার ওয়ার্কআউট প্ল্যান তৈরি করা হয়।',
      'providers_title': 'ফ্রি এআই কী প্রোভাইডারসমূহ',
      'providers_body': 'কোনো সাবস্ক্রিপশন ছাড়াই বিনামূল্যে API কী পেতে এই ফ্রি টিয়ারগুলি চেক করুন:\n\n১. OpenRouter (openrouter.ai):\nফ্রি-টিয়ার মডেল (যেমন Llama-3 ফ্রি মডেল) ব্যবহারের জন্য একটি ফ্রি অ্যাকাউন্ট তৈরি করুন।\n\n২. Nvidia NIM (build.nvidia.com):\nনিবন্ধন করার পরে হাই-স্পিড মডেল ব্যবহারের জন্য এনভিডিয়া প্রচুর পরিমাণ ফ্রি ডেভেলপার ক্রেডিট দেয়।\n\n৩. Reka AI (reka.ai):\nবডি স্ক্যান বিশ্লেষণ এবং ইমেজ পার্সিংয়ের জন্য দুর্দান্ত এবং এতে চমৎকার ফ্রি ক্রেডিট পাওয়া যায়।',
      'injuries_title': 'আঘাতের বিবরণ বা লিমিটেশনের গুরুত্ব',
      'injuries_body': 'আপনার ফিটনেস প্রোফাইল সেট আপ করার সময় যেকোনো আঘাতের কথা (যেমন: হাঁটু ব্যথা, কোমর ব্যথার সমস্যা) বিস্তারিত জানাতে ভুলবেন না। এআই কোচ স্বয়ংক্রিয়ভাবে আপনার সীমাবদ্ধতাগুলি স্ক্যান করে সম্ভাব্য ঝুঁকিপূর্ণ ওয়ার্কআউট বাদ দেবে এবং নিরাপদ বিকল্প ব্যায়াম যুক্ত করবে।',
    },
    'pt': {
      'serverless_title': 'Arquitetura Sem Servidor',
      'serverless_body': 'O Physiqo funciona inteiramente offline no seu dispositivo. Suas chaves de API de IA são salvas com segurança no armazenamento local, e seus treinos são gerados sem taxas de assinatura em nuvem.',
      'providers_title': 'Provedores de Chaves de IA Gratuitas',
      'providers_body': 'Para obter chaves de API sem custos de assinatura, verifique estes níveis gratuitos:\n\n1. OpenRouter (openrouter.ai):\nCrie uma conta gratuita para acessar endpoints gratuitos (como modelos gratuitos Llama-3).\n\n2. Nvidia NIM (build.nvidia.com):\nA Nvidia concede créditos de desenvolvedor gratuitos substanciais para acessar modelos de alta velocidade ao se cadastrar.\n\n3. Reka AI (reka.ai):\nIdeal para análise de escaneamento corporal com créditos gratuitos generosos.',
      'injuries_title': 'Importância do Registro de Lesões',
      'injuries_body': 'Ao configurar seu perfil de condicionamento físico, certifique-se de detalhar quaisquer lesões ativas (por exemplo, dor no joelho, problemas de disco na lombar). O treinador de IA varre essas limitações para filtrar rotinas perigosas e substituí-las por movimentos alternativos mais seguros.',
    },
    'ru': {
      'serverless_title': 'Бессерверная архитектура',
      'serverless_body': 'Physiqo работает локально на вашем устройстве. Ваши API-ключи ИИ надежно хранятся в памяти устройства, а тренировки создаются без каких-либо облачных подписок.',
      'providers_title': 'Бесплатные API-ключи ИИ',
      'providers_body': 'Чтобы получить API-ключи совершенно бесплатно, воспользуйтесь этими тарифами:\n\n1. OpenRouter (openrouter.ai):\nСоздайте бесплатный аккаунт для доступа к бесплатным моделям (например, Llama-3).\n\n2. Nvidia NIM (build.nvidia.com):\nNvidia дарит щедрые бесплатные кредиты разработчика для доступа к самым быстрым моделям при регистрации.\n\n3. Reka AI (reka.ai):\nИдеально подходит для анализа сканирования тела с предоставлением бесплатного баланса.',
      'injuries_title': 'Учет травм и ограничений',
      'injuries_body': 'При настройке фитнес-профиля обязательно укажите все травмы или ограничения (например, боль в коленях, проблемы с поясничным диском). Тренер ИИ автоматически исключит опасные упражнения и заменит их на безопасные альтернативы.',
    },
    'ur': {
      'serverless_title': 'سرور لیس آرکیٹیکچر',
      'serverless_body': 'فیزیکو مکمل طور پر آپ کے ڈیوائس پر آف لائن کام کرتا ہے۔ آپ کی AI API کیز لوکل اسٹوریج میں محفوظ طریقے سے محفوظ کی جاتی ہیں، اور آپ کے ورک آؤٹ بنا کسی کلاؤڈ سبسکرپشن فیس کے تیار کیے جاتے ہیں۔',
      'providers_title': 'مفت اے آئی کی فراہم کنندگان',
      'providers_body': 'بغیر کسی فیس کے API کیز حاصل کرنے کے لیے، ان مفت سروسز کو دیکھیں:\n\n1. OpenRouter (openrouter.ai):\nمفت سروسز (جیسے Llama-3 مفت ماڈلز) تک رسائی کے لیے ایک مفت اکاؤنٹ بنائیں۔\n\n2. Nvidia NIM (build.nvidia.com):\nانوائڈیا سائن اپ کرنے پر تیز رفتار ماڈلز تک رسائی کے لیے مفت کریڈٹ فراہم کرتا ہے۔\n\n3. Reka AI (reka.ai):\nفری کریڈٹ کے ساتھ باڈی اسکین اور امیج تجزیہ کے لیے بہترین سروس۔',
      'injuries_title': 'چوٹوں کی تفصیل کی اہمیت',
      'injuries_body': 'پروفائل بناتے وقت، کسی भी चوٹ (جیسے گھٹنے کا درد، کمر کا درد) کی تفصیل ضرور درج کریں۔ اے آئی کوچ خود بخود ان حدود کو مدنظر رکھتے ہوئے خطرناک ورزشوں کو خارج کر کے ان کی جگہ محفوظ متبادل ورزشیں شامل کرے گا۔',
    }
  };

  Widget _buildGuideCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.bodyLg.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          const Divider(color: AppTheme.outline),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            content,
            style: AppTheme.bodyMd.copyWith(
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final Map<String, String> copy = _localizedGuides[lang] ?? _localizedGuides['en']!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              PhysiqoHeader.back(
                title: context.tr('settings_user_guide'),
                onBackTap: () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.gutter),
                  child: Column(
                    children: [
                      _buildGuideCard(
                        context: context,
                        icon: Icons.psychology_outlined,
                        title: copy['serverless_title']!,
                        content: copy['serverless_body']!,
                      ),
                      _buildGuideCard(
                        context: context,
                        icon: Icons.vpn_key_outlined,
                        title: copy['providers_title']!,
                        content: copy['providers_body']!,
                      ),
                      _buildGuideCard(
                        context: context,
                        icon: Icons.medical_services_outlined,
                        title: copy['injuries_title']!,
                        content: copy['injuries_body']!,
                      ),
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
}
