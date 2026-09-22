/// One address the customer can pick at booking time.
class SavedAddress {
  final String id;

  /// Short tag: Home, Farm, Work or anything the customer typed.
  final String label;

  /// Street-level line as it should be handed to the worker.
  final String line;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.line,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  SavedAddress copyWith({bool? isDefault}) => SavedAddress(
    id: id,
    label: label,
    line: line,
    latitude: latitude,
    longitude: longitude,
    isDefault: isDefault ?? this.isDefault,
  );

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
    id: json['id'] as String,
    label: json['label'] as String,
    line: json['line'] as String,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    isDefault: (json['isDefault'] as bool?) ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'line': line,
    'latitude': latitude,
    'longitude': longitude,
    'isDefault': isDefault,
  };
}
