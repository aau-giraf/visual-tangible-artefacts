import 'package:vta_app/src/modelsDTOs/user.dart';

class PairingDTO {
  final String id;
  final String caregiverId;
  final String childId;
  final bool isActive;
  final DateTime createdAt;
  final User caregiver;
  final User child;

  PairingDTO({
    required this.id,
    required this.caregiverId,
    required this.childId,
    required this.isActive,
    required this.createdAt,
    required this.caregiver,
    required this.child,
  });

  factory PairingDTO.fromJson(Map<String, dynamic> json) {
    return PairingDTO(
      id: json['id'],
      caregiverId: json['caregiverId'],
      childId: json['childId'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
      caregiver: User.fromJson(json['caregiver']),
      child: User.fromJson(json['child']),
    );
  }
}
