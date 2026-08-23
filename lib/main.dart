import 'package:freeplix/app/app.dart';
import 'package:freeplix/bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  await bootstrap(() async {
    final prefs = await SharedPreferences.getInstance();
    return App(preferences: prefs);
  });
}
