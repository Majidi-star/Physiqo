import 'dart:io';

void main() {
  final file = File('lib/l10n/chat_translations.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "'ai_debug_response': 'Response',",
    "'ai_debug_response': 'Response',\n    'ai_debug_chat_id': 'Chat ID: {0}',\n    'ai_debug_log_num': 'Log {0}',\n    'ai_debug_latency': '⏱ Latency: {0}s',\n    'ai_debug_input': '📥 Input: {0} t',\n    'ai_debug_output': '📤 Output: {0} t',\n    'ai_debug_est': 'Est',\n    'ai_debug_act': 'Act',\n    'ai_debug_copy_json': 'Copy JSON',\n    'ai_debug_copied': 'Log copied to clipboard',"
  );
  content = content.replaceFirst(
    "'ai_debug_response': 'پاسخ',",
    "'ai_debug_response': 'پاسخ',\n    'ai_debug_chat_id': 'شناسه گفتگو: {0}',\n    'ai_debug_log_num': 'گزارش {0}',\n    'ai_debug_latency': '⏱ تاخیر: {0} ثانیه',\n    'ai_debug_input': '📥 ورودی: {0} توکن',\n    'ai_debug_output': '📤 خروجی: {0} توکن',\n    'ai_debug_est': 'تخمینی',\n    'ai_debug_act': 'واقعی',\n    'ai_debug_copy_json': 'کپی JSON',\n    'ai_debug_copied': 'گزارش در حافظه کپی شد',"
  );
  content = content.replaceFirst(
    "'ai_debug_response': '响应',",
    "'ai_debug_response': '响应',\n    'ai_debug_chat_id': '聊天 ID: {0}',\n    'ai_debug_log_num': '日志 {0}',\n    'ai_debug_latency': '⏱ 延迟: {0}秒',\n    'ai_debug_input': '📥 输入: {0} t',\n    'ai_debug_output': '📤 输出: {0} t',\n    'ai_debug_est': '预',\n    'ai_debug_act': '实',\n    'ai_debug_copy_json': '复制 JSON',\n    'ai_debug_copied': '日志已复制到剪贴板',"
  );
  content = content.replaceFirst(
    "'ai_debug_response': 'प्रतिक्रिया',",
    "'ai_debug_response': 'प्रतिक्रिया',\n    'ai_debug_chat_id': 'चैट आईडी: {0}',\n    'ai_debug_log_num': 'लॉग {0}',\n    'ai_debug_latency': '⏱ विलंबता: {0}s',\n    'ai_debug_input': '📥 इनपुट: {0} t',\n    'ai_debug_output': '📤 आउटपुट: {0} t',\n    'ai_debug_est': 'अनुमानित',\n    'ai_debug_act': 'वास्तविक',\n    'ai_debug_copy_json': 'JSON कॉपी करें',\n    'ai_debug_copied': 'लॉग क्लिपबोर्ड पर कॉपी किया गया',"
  );
  content = content.replaceFirst(
    "'ai_debug_response': 'Respuesta',",
    "'ai_debug_response': 'Respuesta',\n    'ai_debug_chat_id': 'ID de Chat: {0}',\n    'ai_debug_log_num': 'Registro {0}',\n    'ai_debug_latency': '⏱ Latencia: {0}s',\n    'ai_debug_input': '📥 Entrada: {0} t',\n    'ai_debug_output': '📤 Salida: {0} t',\n    'ai_debug_est': 'Est',\n    'ai_debug_act': 'Real',\n    'ai_debug_copy_json': 'Copiar JSON',\n    'ai_debug_copied': 'Registro copiado al portapapeles',"
  );
  content = content.replaceFirst(
    "'ai_debug_response': 'الاستجابة',",
    "'ai_debug_response': 'الاستجابة',\n    'ai_debug_chat_id': 'معرف الدردشة: {0}',\n    'ai_debug_log_num': 'سجل {0}',\n    'ai_debug_latency': '⏱ الكمون: {0}ث',\n    'ai_debug_input': '📥 الإدخال: {0} t',\n    'ai_debug_output': '📤 الإخراج: {0} t',\n    'ai_debug_est': 'مقدر',\n    'ai_debug_act': 'فعلي',\n    'ai_debug_copy_json': 'نسخ JSON',\n    'ai_debug_copied': 'تم نسخ السجل إلى الحافظة',"
  );
  content = content.replaceFirst(
    "'ai_debug_response': 'Réponse',",
    "'ai_debug_response': 'Réponse',\n    'ai_debug_chat_id': 'ID du Chat: {0}',\n    'ai_debug_log_num': 'Journal {0}',\n    'ai_debug_latency': '⏱ Latence: {0}s',\n    'ai_debug_input': '📥 Entrée: {0} t',\n    'ai_debug_output': '📤 Sortie: {0} t',\n    'ai_debug_est': 'Est',\n    'ai_debug_act': 'Réel',\n    'ai_debug_copy_json': 'Copier JSON',\n    'ai_debug_copied': 'Journal copié dans le presse-papiers',"
  );
  content = content.replaceFirst(
    "'ai_debug_response': 'Ответ',",
    "'ai_debug_response': 'Ответ',\n    'ai_debug_chat_id': 'ID чата: {0}',\n    'ai_debug_log_num': 'Журнал {0}',\n    'ai_debug_latency': '⏱ Задержка: {0}с',\n    'ai_debug_input': '📥 Ввод: {0} t',\n    'ai_debug_output': '📤 Вывод: {0} t',\n    'ai_debug_est': 'Оц',\n    'ai_debug_act': 'Факт',\n    'ai_debug_copy_json': 'Копировать JSON',\n    'ai_debug_copied': 'Журнал скопирован в буфер обмена',"
  );
  content = content.replaceFirst(
    "'ai_debug_response': 'Resposta',",
    "'ai_debug_response': 'Resposta',\n    'ai_debug_chat_id': 'ID do Chat: {0}',\n    'ai_debug_log_num': 'Log {0}',\n    'ai_debug_latency': '⏱ Latência: {0}s',\n    'ai_debug_input': '📥 Entrada: {0} t',\n    'ai_debug_output': '📤 Saída: {0} t',\n    'ai_debug_est': 'Est',\n    'ai_debug_act': 'Real',\n    'ai_debug_copy_json': 'Copiar JSON',\n    'ai_debug_copied': 'Log copiado para a área de transferência',"
  );
  content = content.replaceFirst(
    "'ai_debug_response': 'প্রতিক্রিয়া',",
    "'ai_debug_response': 'প্রতিক্রিয়া',\n    'ai_debug_chat_id': 'চ্যাট আইডি: {0}',\n    'ai_debug_log_num': 'লগ {0}',\n    'ai_debug_latency': '⏱ লেটেন্সি: {0}s',\n    'ai_debug_input': '📥 ইনপুট: {0} t',\n    'ai_debug_output': '📤 আউটপুট: {0} t',\n    'ai_debug_est': 'আনু',\n    'ai_debug_act': 'প্রকৃত',\n    'ai_debug_copy_json': 'JSON কপি করুন',\n    'ai_debug_copied': 'লগ ক্লিপবোর্ডে কপি করা হয়েছে',"
  );
  content = content.replaceFirst(
    "'ai_debug_response': 'جواب',",
    "'ai_debug_response': 'جواب',\n    'ai_debug_chat_id': 'چیٹ آئی ڈی: {0}',\n    'ai_debug_log_num': 'لاگ {0}',\n    'ai_debug_latency': '⏱ تاخیر: {0}s',\n    'ai_debug_input': '📥 ان پٹ: {0} t',\n    'ai_debug_output': '📤 آؤٹ پٹ: {0} t',\n    'ai_debug_est': 'تخمینہ',\n    'ai_debug_act': 'حقیقی',\n    'ai_debug_copy_json': 'JSON کاپی کریں',\n    'ai_debug_copied': 'لاگ کلپ بورڈ پر کاپی ہو گیا',"
  );

  file.writeAsStringSync(content);
}
