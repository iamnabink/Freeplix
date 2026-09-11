import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:freeplix/data/repositories/settings_repository.dart';

/// The default avatar accent when the viewer has not picked one — the
/// projector lamp, Freeplix's warm accent.
const kDefaultAccent = 0xFFFFC24B;

class SettingsState extends Equatable {
  const SettingsState({
    this.name = '',
    this.accent = kDefaultAccent,
    this.defaultSourceId,
  });

  /// The viewer's display name. Empty until they set one.
  final String name;

  /// Avatar accent as an ARGB int.
  final int accent;

  /// Preferred playback source id, or null for "no preference" (Freeplix then
  /// starts on the first configured source).
  final String? defaultSourceId;

  /// One or two uppercase letters drawn from the name, for the avatar. Empty
  /// when there is no name yet, so the avatar can show a placeholder instead.
  String get initials {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return (words.first.substring(0, 1) + words.last.substring(0, 1))
        .toUpperCase();
  }

  SettingsState copyWith({
    String? name,
    int? accent,
    String? Function()? defaultSourceId,
  }) {
    return SettingsState(
      name: name ?? this.name,
      accent: accent ?? this.accent,
      defaultSourceId: defaultSourceId == null
          ? this.defaultSourceId
          : defaultSourceId(),
    );
  }

  @override
  List<Object?> get props => [name, accent, defaultSourceId];
}

/// Holds the viewer's local profile and preferences, writing each change
/// straight through to the device.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({required SettingsRepository repository})
    : _repository = repository,
      super(
        SettingsState(
          name: repository.loadName(),
          accent: repository.loadAccent() ?? kDefaultAccent,
          defaultSourceId: repository.loadDefaultSource(),
        ),
      );

  final SettingsRepository _repository;

  Future<void> setName(String name) async {
    final trimmed = name.trim();
    emit(state.copyWith(name: trimmed));
    await _repository.saveName(trimmed);
  }

  Future<void> setAccent(int accent) async {
    emit(state.copyWith(accent: accent));
    await _repository.saveAccent(accent);
  }

  Future<void> setDefaultSource(String? id) async {
    emit(state.copyWith(defaultSourceId: () => id));
    await _repository.saveDefaultSource(id);
  }
}
