class AuditLog {
  final int id;
  final int? userId;
  final String action;
  final String? entity;
  final int? entityId;
  final String? detail;
  final int? createdAtEpochMs;

  const AuditLog({
    required this.id,
    this.userId,
    required this.action,
    this.entity,
    this.entityId,
    this.detail,
    this.createdAtEpochMs,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['userId'] is int
          ? json['userId']
          : int.tryParse(json['user_id']?.toString() ?? json['userId']?.toString() ?? ''),
      action: json['action']?.toString() ?? '',
      entity: json['entity']?.toString(),
      entityId: json['entityId'] is int
          ? json['entityId']
          : int.tryParse(json['entity_id']?.toString() ?? json['entityId']?.toString() ?? ''),
      detail: json['detail']?.toString(),
      createdAtEpochMs: json['createdAtEpochMs'] is int
          ? json['createdAtEpochMs']
          : int.tryParse(json['created_at_epoch_ms']?.toString() ?? json['createdAtEpochMs']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'action': action,
      'entity': entity,
      'entityId': entityId,
      'detail': detail,
      'createdAtEpochMs': createdAtEpochMs,
    };
  }
}
