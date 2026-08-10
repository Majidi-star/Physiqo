import 'package:flutter_timezone/flutter_timezone.dart';
void main() async {
  var x = await FlutterTimezone.getLocalTimezone();
  print(x.runtimeType);
}
