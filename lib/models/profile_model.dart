class ProfileModel {
  final String id;
  final String? displayName;
  final DateTime? noFapLastReset;
  final DateTime updatedAt;

  ProfileModel({
    required this.id,
    this.displayName,
    this.noFapLastReset,
    required this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      displayName: json['display_name'],
      noFapLastReset: json['no_fap_last_reset'] != null
          ? DateTime.parse(json['no_fap_last_reset'])
          : null,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'no_fap_last_reset': noFapLastReset?.toIso8601String(),
    };
  }
}
