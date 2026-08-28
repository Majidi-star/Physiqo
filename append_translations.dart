import 'dart:io';

void main() {
  final file = File('lib/l10n/schedule_translations.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "'schedule_image_error': 'Error generating image',", 
    "'schedule_image_error': 'Error generating image',\n    'moves_days_count': '{0} workout days included',\n    'moves_date_range': 'From {0} to {1}',"
  );
  content = content.replaceFirst(
    "'schedule_image_error': 'خطا در خروجی تصویر',",
    "'schedule_image_error': 'خطا در خروجی تصویر',\n    'moves_days_count': 'شامل {0} روز تمرینی',\n    'moves_date_range': 'شروع از {0} تا {1}',"
  );
  content = content.replaceFirst(
    "'schedule_image_error': '生成图像错误',",
    "'schedule_image_error': '生成图像错误',\n    'moves_days_count': '包含 {0} 个训练日',\n    'moves_date_range': '从 {0} 到 {1}',"
  );
  content = content.replaceFirst(
    "'schedule_image_error': 'छवि बनाने में त्रुटि',",
    "'schedule_image_error': 'छवि बनाने में त्रुटि',\n    'moves_days_count': '{0} कसरत दिन शामिल हैं',\n    'moves_date_range': '{0} से {1} तक',"
  );
  content = content.replaceFirst(
    "'schedule_image_error': 'Error al generar imagen',",
    "'schedule_image_error': 'Error al generar imagen',\n    'moves_days_count': '{0} días de entrenamiento incluidos',\n    'moves_date_range': 'Desde {0} hasta {1}',"
  );
  content = content.replaceFirst(
    "'schedule_image_error': 'خطأ في إنشاء الصورة',",
    "'schedule_image_error': 'خطأ في إنشاء الصورة',\n    'moves_days_count': 'يتضمن {0} أيام تدريب',\n    'moves_date_range': 'من {0} إلى {1}',"
  );
  content = content.replaceFirst(
    "'schedule_image_error': 'Erreur de génération d\\'image',",
    "'schedule_image_error': 'Erreur de génération d\\'image',\n    'moves_days_count': '{0} jours d\\'entraînement inclus',\n    'moves_date_range': 'Du {0} au {1}',"
  );
  content = content.replaceFirst(
    "'schedule_image_error': 'Ошибка при создании изображения',",
    "'schedule_image_error': 'Ошибка при создании изображения',\n    'moves_days_count': 'Включено {0} тренировочных дней',\n    'moves_date_range': 'С {0} по {1}',"
  );
  content = content.replaceFirst(
    "'schedule_image_error': 'Erro ao gerar imagem',",
    "'schedule_image_error': 'Erro ao gerar imagem',\n    'moves_days_count': '{0} dias de treino incluídos',\n    'moves_date_range': 'De {0} a {1}',"
  );
  content = content.replaceFirst(
    "'schedule_image_error': 'ইমেজ তৈরি করতে ত্রুটি',",
    "'schedule_image_error': 'ইমেজ তৈরি করতে ত্রুটি',\n    'moves_days_count': '{0} টি ওয়ার্কআউট দিন অন্তর্ভুক্ত',\n    'moves_date_range': '{0} থেকে {1} পর্যন্ত',"
  );
  content = content.replaceFirst(
    "'schedule_image_error': 'تصویر بنانے میں خرابی',",
    "'schedule_image_error': 'تصویر بنانے میں خرابی',\n    'moves_days_count': '{0} ورک آؤٹ دن شامل ہیں',\n    'moves_date_range': '{0} سے {1} تک',"
  );

  file.writeAsStringSync(content);
}
