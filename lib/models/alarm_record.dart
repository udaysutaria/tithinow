import '../widgets/molecules/list_item_alarms.dart' show AlarmType;

/// Represents a persistent alarm schedule stored in SQLite.
class AlarmRecord {
  /// Internal database ID.
  final int? id;

  /// Deterministic or unique external alarm ID (used by Alarm plugin and scheduling).
  final int externalId;

  /// Category: choghadiya, muhurta, or tithi.
  final AlarmType type;

  /// Display title (e.g., "Abhijit Muhurt", "Dashmi", "Amrit").
  final String title;

  /// Formatted date string (e.g., "25 Sep 2026").
  final String date;

  /// Formatted time string (e.g., "02:18 am - 02:18 am" or "02:18 am").
  final String timeDisplay;

  /// The exact [DateTime] when the alarm is scheduled to trigger.
  final DateTime triggerTime;

  /// Whether this alarm is actively scheduled or toggled off.
  final bool isActive;

  /// Timestamp when the alarm record was created.
  final DateTime createdAt;

  /// Optional parent rule ID grouping repeating alarm occurrences.
  final String? parentRuleId;

  /// Whether this alarm was scheduled as part of a repeating rule.
  final bool isRepeating;

  /// The associated Tithi name if type is [AlarmType.tithi].
  final String? tithiName;

  AlarmRecord({
    this.id,
    required this.externalId,
    required this.type,
    required this.title,
    required this.date,
    required this.timeDisplay,
    required this.triggerTime,
    this.isActive = true,
    DateTime? createdAt,
    this.parentRuleId,
    this.isRepeating = false,
    this.tithiName,
  }) : createdAt = createdAt ?? DateTime.now();

  AlarmRecord copyWith({
    int? id,
    int? externalId,
    AlarmType? type,
    String? title,
    String? date,
    String? timeDisplay,
    DateTime? triggerTime,
    bool? isActive,
    DateTime? createdAt,
    String? parentRuleId,
    bool? isRepeating,
    String? tithiName,
  }) {
    return AlarmRecord(
      id: id ?? this.id,
      externalId: externalId ?? this.externalId,
      type: type ?? this.type,
      title: title ?? this.title,
      date: date ?? this.date,
      timeDisplay: timeDisplay ?? this.timeDisplay,
      triggerTime: triggerTime ?? this.triggerTime,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      parentRuleId: parentRuleId ?? this.parentRuleId,
      isRepeating: isRepeating ?? this.isRepeating,
      tithiName: tithiName ?? this.tithiName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'external_id': externalId,
      'type': type.name,
      'title': title,
      'date': date,
      'time_display': timeDisplay,
      'trigger_time': triggerTime.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      if (parentRuleId != null) 'parent_rule_id': parentRuleId,
      'is_repeating': isRepeating ? 1 : 0,
      if (tithiName != null) 'tithi_name': tithiName,
    };
  }

  factory AlarmRecord.fromMap(Map<String, dynamic> map) {
    return AlarmRecord(
      id: map['id'] as int?,
      externalId: map['external_id'] as int,
      type: AlarmType.values.firstWhere(
        (e) => e.name == (map['type'] as String),
        orElse: () => AlarmType.choghadiya,
      ),
      title: map['title'] as String,
      date: map['date'] as String,
      timeDisplay: map['time_display'] as String,
      triggerTime: DateTime.fromMillisecondsSinceEpoch(map['trigger_time'] as int),
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      parentRuleId: map['parent_rule_id'] as String?,
      isRepeating: (map['is_repeating'] as int?) == 1,
      tithiName: map['tithi_name'] as String?,
    );
  }
}
