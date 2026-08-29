import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void main() async {
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/openai/chat/completions');
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer testkey',
      'x-goog-api-key': 'testkey'
    },
    body: jsonEncode({"model": "gemini-1.5-flash", "messages": [{"role": "user", "content": "hello"}]})
  );
  print(response.statusCode);
  print(response.body);
}
