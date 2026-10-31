/// Represents a selected travel destination.
class Destination {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final DateTime? savedAt;

  const Destination({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.savedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'savedAt': (savedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      name: json['name'] as String? ?? 'Unknown Destination',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      savedAt: json['savedAt'] != null
          ? DateTime.tryParse(json['savedAt'] as String)
          : null,
    );
  }

  @override
  String toString() => 'Destination(name: $name, lat: $latitude, lng: $longitude)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Destination &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => name.hashCode ^ latitude.hashCode ^ longitude.hashCode;
}
