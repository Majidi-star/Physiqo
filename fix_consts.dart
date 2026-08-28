import 'dart:io';

void main() {
  final file = File('lib/screens/schedule_overview_screen.dart');
  var content = file.readAsStringSync();

  content = content.replaceAll("const InputDecoration(labelText: context.tr(", "InputDecoration(labelText: context.tr(");
  content = content.replaceAll("const Text(context.tr(", "Text(context.tr(");
  
  content = content.replaceAllMapped(RegExp(r'const\s+Text\(\s*context\.tr'), (m) => 'Text(context.tr');
  content = content.replaceAllMapped(RegExp(r'const\s+Text\(\s*\n\s*context\.tr'), (m) => 'Text(\n                context.tr');

  file.writeAsStringSync(content);
}
