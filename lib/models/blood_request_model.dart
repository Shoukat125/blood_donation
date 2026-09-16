class BloodRequestModel {
  final int id;
  final String patientName;
  final int? patientAge;
  final String? patientGender;
  final String bloodType;
  final int unitsNeeded;
  final String urgency;
  final String hospital;
  final String? city;
  final String status;
  final String refNumber;
  final String? requiredBy;
  final DateTime? createdAt;
  final String? donorName;
  final String? donorPhone;

  const BloodRequestModel({
    required this.id,
    required this.patientName,
    this.patientAge,
    this.patientGender,
    required this.bloodType,
    this.unitsNeeded = 1,
    this.urgency = 'Normal',
    required this.hospital,
    this.city,
    this.status = 'Searching',
    required this.refNumber,
    this.requiredBy,
    this.createdAt,
    this.donorName,
    this.donorPhone,
  });

  factory BloodRequestModel.fromJson(Map<String, dynamic> json) {
    return BloodRequestModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      patientName: json['patient_name']?.toString() ?? 'Patient',
      patientAge: json['patient_age'] is int
          ? json['patient_age']
          : int.tryParse('${json['patient_age']}'),
      patientGender: json['patient_gender']?.toString(),
      bloodType: json['blood_type']?.toString() ?? '',
      unitsNeeded: json['units_needed'] is int
          ? json['units_needed']
          : int.tryParse('${json['units_needed']}') ?? 1,
      urgency: json['urgency']?.toString() ?? 'Normal',
      hospital: json['hospital']?.toString() ?? '',
      city: json['city']?.toString(),
      status: json['status']?.toString() ?? 'Searching',
      refNumber: json['ref_number']?.toString() ?? '',
      requiredBy: json['required_by']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      donorName: json['donor_name']?.toString(),
      donorPhone: json['donor_phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_name': patientName,
      'patient_age': patientAge,
      'patient_gender': patientGender,
      'blood_type': bloodType,
      'units_needed': unitsNeeded,
      'urgency': urgency,
      'hospital': hospital,
      'city': city,
      'status': status,
      'ref_number': refNumber,
      'required_by': requiredBy,
      'created_at': createdAt?.toIso8601String(),
      'donor_name': donorName,
      'donor_phone': donorPhone,
    };
  }
}
