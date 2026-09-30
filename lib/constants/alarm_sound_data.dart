/// Model representing a selectable alarm ringtone.
class AlarmSoundOption {
  /// Unique identifier stored in app settings (e.g., 'sound_1').
  final String id;

  /// Human-readable title displayed in Settings.
  final String title;

  /// Secondary description (e.g. "Serene & Meditative (4 min)").
  final String subtitle;

  /// Asset path to the MP3 file.
  final String assetPath;

  const AlarmSoundOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.assetPath,
  });
}

/// Catalog of available alarm ringtones in TithiNow.
class AlarmSounds {
  /// The default sound selected on fresh install.
  static const String defaultSoundId = 'sound_1';

  /// All 4 supported audio sounds.
  static const List<AlarmSoundOption> all = [
    AlarmSoundOption(
      id: 'sound_1',
      title: 'Divine Harmony',
      subtitle: 'Serene & Meditative (4 min)',
      assetPath: 'assets/audio/AlarmSound_01.mp3',
    ),
    AlarmSoundOption(
      id: 'sound_2',
      title: 'Temple Chimes',
      subtitle: 'Sacred Temple Bell (11 sec)',
      assetPath: 'assets/audio/AlarmSound_02.mp3',
    ),
    AlarmSoundOption(
      id: 'sound_3',
      title: 'Crisp Dawn',
      subtitle: 'Bright Morning Alert (8 sec)',
      assetPath: 'assets/audio/AlarmSound_03.mp3',
    ),
    AlarmSoundOption(
      id: 'sound_4',
      title: 'Peaceful Sunrise',
      subtitle: 'Uplifting Melodic Bell (19 sec)',
      assetPath: 'assets/audio/AlarmSound_04.mp3',
    ),
  ];

  /// Looks up an [AlarmSoundOption] by its identifier, falling back to the default sound.
  static AlarmSoundOption getById(String? id) {
    return all.firstWhere(
      (s) => s.id == id,
      orElse: () => all.first,
    );
  }
}
