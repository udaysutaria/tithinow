/// Model representing a City with geographic coordinates for Panchang calculation.
class City {
  final int id;
  final String name;
  final String state;
  final double latitude;
  final double longitude;

  const City({
    required this.id,
    required this.name,
    required this.state,
    required this.latitude,
    required this.longitude,
  });

  /// Formatted display string, e.g. "Mumbai, Maharashtra"
  String get displayName => '$name, $state';

  /// Formatted coordinates string, e.g. "19.0761° N, 72.8775° E"
  String get coordinatesDisplay {
    final latDir = latitude >= 0 ? 'N' : 'S';
    final lonDir = longitude >= 0 ? 'E' : 'W';
    return '${latitude.abs().toStringAsFixed(4)}° $latDir, ${longitude.abs().toStringAsFixed(4)}° $lonDir';
  }

  factory City.fromMap(Map<String, dynamic> map) {
    return City(
      id: map['id'] as int,
      name: map['name'] as String,
      state: map['state'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is City &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'City(id: $id, name: $name, state: $state, lat: $latitude, lon: $longitude)';
}
