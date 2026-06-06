import 'package:uuid/uuid.dart';

enum GrainType {
  wheat,
  jowar,
  bajra,
  rice,
  maize,
  other;

  String get displayName {
    switch (this) {
      case GrainType.wheat:
        return 'गहू';
      case GrainType.jowar:
        return 'ज्वारी';
      case GrainType.bajra:
        return 'बाजरी';
      case GrainType.rice:
        return 'तांदूळ';
      case GrainType.maize:
        return 'मका';
      case GrainType.other:
        return 'इतर';
    }
  }

  String get englishName {
    return name;
  }

  String get emoji {
    switch (this) {
      case GrainType.wheat:
        return '🌾';
      case GrainType.jowar:
        return '🌿';
      case GrainType.bajra:
        return '🌱';
      case GrainType.rice:
        return '🍚';
      case GrainType.maize:
        return '🌽';
      case GrainType.other:
        return '🫘';
    }
  }

  static GrainType fromString(String value) {
    return GrainType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GrainType.other,
    );
  }
}

enum EntryStatus {
  paid,
  credit;

  String get displayName {
    switch (this) {
      case EntryStatus.paid:
        return 'दिले';
      case EntryStatus.credit:
        return 'उधारी';
    }
  }

  static EntryStatus fromString(String value) {
    return EntryStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EntryStatus.credit,
    );
  }
}

class Entry {
  final String id;
  final String customerId;
  final GrainType grainType;
  final double weightKg;
  final double ratePerKg;
  final double amount;
  final EntryStatus status;
  final DateTime workDate;
  final String workTime;
  final DateTime createdAt;
  final String? notes;

  Entry({
    String? id,
    required this.customerId,
    required this.grainType,
    required this.weightKg,
    required this.ratePerKg,
    required this.amount,
    this.status = EntryStatus.credit,
    required this.workDate,
    String? workTime,
    DateTime? createdAt,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        workTime = workTime ?? _formatTime(DateTime.now()),
        createdAt = createdAt ?? DateTime.now();

  static String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'grain_type': grainType.name,
      'weight_kg': weightKg,
      'rate_per_kg': ratePerKg,
      'amount': amount,
      'status': status.name,
      'work_date': workDate.toIso8601String().substring(0, 10),
      'work_time': workTime,
      'created_at': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory Entry.fromMap(Map<String, dynamic> map) {
    return Entry(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      grainType: GrainType.fromString(map['grain_type'] as String),
      weightKg: (map['weight_kg'] as num).toDouble(),
      ratePerKg: (map['rate_per_kg'] as num).toDouble(),
      amount: (map['amount'] as num).toDouble(),
      status: EntryStatus.fromString(map['status'] as String),
      workDate: DateTime.parse(map['work_date'] as String),
      workTime: map['work_time'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      notes: map['notes'] as String?,
    );
  }

  Entry copyWith({EntryStatus? status}) {
    return Entry(
      id: id,
      customerId: customerId,
      grainType: grainType,
      weightKg: weightKg,
      ratePerKg: ratePerKg,
      amount: amount,
      status: status ?? this.status,
      workDate: workDate,
      workTime: workTime,
      createdAt: createdAt,
      notes: notes,
    );
  }
}
