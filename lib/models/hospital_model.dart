class HospitalModel {
  final int id;
  final String name;
  final String city;
  final String? address;
  final double? distanceKm;

  const HospitalModel({
    required this.id,
    required this.name,
    required this.city,
    this.address,
    this.distanceKm,
  });

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    return HospitalModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      address: json['address']?.toString(),
      distanceKm: json['distance_km'] is num
          ? (json['distance_km'] as num).toDouble()
          : double.tryParse('${json['distance_km']}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'address': address,
      'distance_km': distanceKm,
    };
  }
}
