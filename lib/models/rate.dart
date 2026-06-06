class Rate {
  final String id;
  final String grainType;
  final double ratePerKg;
  final DateTime updatedAt;

  Rate({
    required this.id,
    required this.grainType,
    required this.ratePerKg,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'grain_type': grainType,
      'rate_per_kg': ratePerKg,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Rate.fromMap(Map<String, dynamic> map) {
    return Rate(
      id: map['id'] as String,
      grainType: map['grain_type'] as String,
      ratePerKg: (map['rate_per_kg'] as num).toDouble(),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
