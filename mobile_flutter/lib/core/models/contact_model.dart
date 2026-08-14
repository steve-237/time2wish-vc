class ContactModel {
  final int id;
  final int userId;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String status; // PENDING, ACCEPTED, REJECTED
  final DateTime? createdAt;

  ContactModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    required this.status,
    this.createdAt,
  });

  bool get isPending => status == 'PENDING';
  bool get isAccepted => status == 'ACCEPTED';

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      fullName: json['fullName'] ?? json['email'] ?? 'Contact',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'],
      status: json['status'] ?? 'ACCEPTED',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'avatarUrl': avatarUrl,
      'status': status,
    };
  }
}
