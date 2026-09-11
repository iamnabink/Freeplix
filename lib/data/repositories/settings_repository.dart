import 'package:shared_preferences/shared_preferences.dart';

/// The viewer's local profile and preferences. Freeplix has no accounts and no
/// backend, so none of this ever leaves the browser it was set in.
class SettingsRepository {
  SettingsRepository(this._prefs);

  static const _nameKey = 'freeplix.profile.name.v1';
  static const _accentKey = 'freeplix.profile.accent.v1';
  static const _defaultSourceKey = 'freeplix.settings.defaultSource.v1';

  final SharedPreferences _prefs;

  String loadName() => _prefs.getString(_nameKey) ?? '';

  /// The avatar accent as an ARGB int, or null when the viewer never picked
  /// one (the cubit then falls back to its default).
  int? loadAccent() => _prefs.getInt(_accentKey);

  /// The id of the preferred playback source, or null for "no preference".
  String? loadDefaultSource() => _prefs.getString(_defaultSourceKey);

  Future<void> saveName(String name) => _prefs.setString(_nameKey, name);

  Future<void> saveAccent(int accent) => _prefs.setInt(_accentKey, accent);

  Future<void> saveDefaultSource(String? id) => id == null
      ? _prefs.remove(_defaultSourceKey)
      : _prefs.setString(_defaultSourceKey, id);
}
