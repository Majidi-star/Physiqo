import 'dart:convert';
import 'package:http/http.dart' as http;
void main() async {
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1/openai/chat/completions');
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer testkey'
    },
    body: jsonEncode({"model": "gemini-3.5-flash-lite", "messages": [{"role": "user", "content": "hello"}]})
  );
  print(response.statusCode);
  print(response.body);
}
