import 'dart:io';

void main() {
  final file = File('lib/screens/chat_screen.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll(
    "isFa\n          ? 'خطای امنیتی یا بارگذاری شبکه (TLS/SSL/413).\\nاین خطا معمولاً به دلیل محدودیت‌های شدید اینترنتی یا قطع اتصال فیلترشکن (VPN) رخ می‌دهد. لطفاً وضعیت فیلترشکن خود را بررسی کرده یا آن را تغییر دهید و مجدداً تلاش کنید.'",
    "context.tr('chat_error_tls')"
  );
  content = content.replaceAll(
    "isFa\n          ? 'خطا در ارتباط با سرور.\\nامکان برقراری ارتباط با سرور هوش مصنوعی وجود ندارد. لطفاً مطمئن شوید که اتصال اینترنت شما برقرار است و فیلترشکن (VPN) متصل و فعال است.'",
    "context.tr('chat_error_connection')"
  );
  content = content.replaceAll(
    "isFa\n          ? 'پایان زمان پاسخ‌گویی سرور.\\nارتباط با سرور به دلیل سرعت پایین اینترنت برقرار نشد. لطفاً مجدداً تلاش کنید.'",
    "context.tr('chat_error_timeout')"
  );

  content = content.replaceAll(
    "isFa ? 'خطای امنیتی یا بارگذاری شبکه (TLS/SSL/413).\\nاین خطا معمولاً به دلیل محدودیت‌های شدید اینترنتی یا قطع اتصال فیلترشکن (VPN) رخ می‌دهد. لطفاً وضعیت فیلترشکن خود را بررسی کرده یا آن را تغییر دهید و مجدداً تلاش کنید.'",
    "context.tr('chat_error_tls')"
  );
  content = content.replaceAll(
    "isFa ? 'خطا در ارتباط با سرور.\\nامکان برقراری ارتباط با سرور هوش مصنوعی وجود ندارد. لطفاً مطمئن شوید که اتصال اینترنت شما برقرار است و فیلترشکن (VPN) متصل و فعال است.'",
    "context.tr('chat_error_connection')"
  );
  content = content.replaceAll(
    "isFa ? 'پایان زمان پاسخ‌گویی سرور.\\nارتباط با سرور به دلیل سرعت پایین اینترنت برقرار نشد. لطفاً مجدداً تلاش کنید.'",
    "context.tr('chat_error_timeout')"
  );

  file.writeAsStringSync(content);
}
