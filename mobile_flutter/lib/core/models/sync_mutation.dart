class SyncMutation {
  final String id;
  final String endpoint;
  final String method; // 'POST', 'PUT', 'DELETE'
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final int retryCount;

  SyncMutation({
    required this.id,
    required this.endpoint,
    required this.method,
    this.data,
    required this.createdAt,
    this.retryCount = 0,
  });

  SyncMutation copyWith({
    String? id,
    String? endpoint,
    String? method,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
  }) {
    return SyncMutation(
      id: id ?? this.id,
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'endpoint': endpoint,
    'method': method,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
  };

  factory SyncMutation.fromJson(Map<String, dynamic> json) => SyncMutation(
    id: json['id'] as String,
    endpoint: json['endpoint'] as String,
    method: json['method'] as String,
    data: json['data'] != null ? Map<String, dynamic>.from(json['data'] as Map) : null,
    createdAt: DateTime.parse(json['createdAt'] as String),
    retryCount: (json['retryCount'] as int?) ?? 0,
  );
}
