// core/draft_cache.dart
import 'package:shared_preferences/shared_preferences.dart';

class DraftCache {
  static const kPeople = 'box.people';
  static const kRecipes = 'box.recipes';
  static const kPref = 'box.pref';
  static const kStep = 'box.step'; // 1..5

  static Future<void> saveBox({
    required int people,
    required int recipes,
    required String prefSeed,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(kPeople, people);
    await sp.setInt(kRecipes, recipes);
    await sp.setString(kPref, prefSeed);
    await sp.setInt(kStep, 1); // we're in Step 1
  }

  static Future<(int?, int?, String?, int?)> load() async {
    final sp = await SharedPreferences.getInstance();
    return (
      sp.getInt(kPeople),
      sp.getInt(kRecipes),
      sp.getString(kPref),
      sp.getInt(kStep),
    );
  }

  static Future<void> setStep(int step) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(kStep, step);
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(kPeople);
    await sp.remove(kRecipes);
    await sp.remove(kPref);
    await sp.remove(kStep);
  }
}
