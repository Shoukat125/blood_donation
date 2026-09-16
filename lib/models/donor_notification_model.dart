class DonorNotificationModel {
  final int id;
  final int requestId;
  final String status;
  final DateTime? createdAt;
  final String? patientName;
  final String? bloodType;
  final int? unitsNeeded;
  final String? hospital;
  final String? urgency;
  final String? city;
  final String? requestStatus;

  const DonorNotificationModel({
    required this.id,
    required this.requestId,
    this.status = 'Pending',
    this.createdAt,
    this.patientName,
    this.bloodType,
    this.unitsNeeded,
    this.hospital,
    this.urgency,
    this.city,
    this.requestStatus,
  });

  factory DonorNotificationModel.fromJson(Map<String, dynamic> json) {
    return DonorNotificationModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      requestId: json['request_id'] is int
          ? json['request_id']
          : int.tryParse('${json['request_id']}') ?? 0,
      status: json['status']?.toString() ?? 'Pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      patientName: json['patient_name']?.toString(),
      bloodType: json['blood_type']?.toString(),
      unitsNeeded: json['units_needed'] is int
          ? json['units_needed']
          : int.tryParse('${json['units_needed']}'),
      hospital: json['hospital']?.toString(),
      urgency: json['urgency']?.toString(),
      city: json['city']?.toString(),
      requestStatus: json['request_status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'patient_name': patientName,
      'blood_type': bloodType,
      'units_needed': unitsNeeded,
      'hospital': hospital,
      'urgency': urgency,
      'city': city,
      'request_status': requestStatus,
    };
  }
}
