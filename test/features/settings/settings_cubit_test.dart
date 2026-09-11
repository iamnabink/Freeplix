import 'package:flutter_test/flutter_test.dart';
import 'package:freeplix/data/repositories/settings_repository.dart';
import 'package:freeplix/features/settings/bloc/settings_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SettingsRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = SettingsRepository(await SharedPreferences.getInstance());
  });

  group('SettingsCubit', () {
    test('starts with the defaults', () {
      final cubit = SettingsCubit(repository: repository);
      expect(cubit.state.name, isEmpty);
      expect(cubit.state.accent, kDefaultAccent);
      expect(cubit.state.defaultSourceId, isNull);
      expect(cubit.state.initials, isEmpty);
    });

    test('initials use the first and last word of the name', () async {
      final cubit = SettingsCubit(repository: repository);

      await cubit.setName('Ada Lovelace');
      expect(cubit.state.initials, 'AL');

      await cubit.setName('  cher ');
      expect(cubit.state.name, 'cher');
      expect(cubit.state.initials, 'C');
    });

    test('setDefaultSource can set and clear the preference', () async {
      final cubit = SettingsCubit(repository: repository);

      await cubit.setDefaultSource('vidsrc');
      expect(cubit.state.defaultSourceId, 'vidsrc');

      await cubit.setDefaultSource(null);
      expect(cubit.state.defaultSourceId, isNull);
    });

    test('changes survive a round trip through storage', () async {
      final first = SettingsCubit(repository: repository);
      await first.setName('Grace Hopper');
      await first.setAccent(0xFF5AA9FF);
      await first.setDefaultSource('vidking');

      final reloaded = SettingsCubit(repository: repository);
      expect(reloaded.state.name, 'Grace Hopper');
      expect(reloaded.state.accent, 0xFF5AA9FF);
      expect(reloaded.state.defaultSourceId, 'vidking');
    });
  });
}
