class DonorModel {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String bloodType;
  final int? age;
  final String? gender;
  final String? city;
  final bool isAvailable;
  final String? lastDonation;
  final int totalDonations;
  final int livesSaved;
  final double rating;
  final bool isVerified;
  final int maxDistance;

  const DonorModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.bloodType,
    this.age,
    this.gender,
    this.city,
    this.isAvailable = true,
    this.lastDonation,
    this.totalDonations = 0,
    this.livesSaved = 0,
    this.rating = 0.0,
    this.isVerified = false,
    this.maxDistance = 10,
  });

  factory DonorModel.fromJson(Map<String, dynamic> json) {
    return DonorModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      fullName: json['full_name']?.toString() ?? json['name']?.toString() ?? 'Donor',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      bloodType: json['blood_type']?.toString() ?? '',
      age: json['age'] is int ? json['age'] : int.tryParse('${json['age']}'),
      gender: json['gender']?.toString(),
      city: json['city']?.toString(),
      isAvailable: json['is_available'] == true,
      lastDonation: json['last_donation']?.toString(),
      totalDonations: json['total_donations'] is int
          ? json['total_donations']
          : int.tryParse('${json['total_donations']}') ?? 0,
      livesSaved: json['lives_saved'] is int
          ? json['lives_saved']
          : int.tryParse('${json['lives_saved']}') ?? 0,
      rating: json['rating'] is num
          ? (json['rating'] as num).toDouble()
          : double.tryParse('${json['rating']}') ?? 0.0,
      isVerified: json['is_verified'] == true,
      maxDistance: json['max_distance'] is int
          ? json['max_distance']
          : int.tryParse('${json['max_distance']}') ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'blood_type': bloodType,
      'age': age,
      'gender': gender,
      'city': city,
      'is_available': isAvailable,
      'last_donation': lastDonation,
      'total_donations': totalDonations,
      'lives_saved': livesSaved,
      'rating': rating,
      'is_verified': isVerified,
      'max_distance': maxDistance,
    };
  }
}
