class BirthdayModel {
  final int id;
  final String name;
  final DateTime birthdate;
  final String category;
  final String? photoUrl;
  final String? notes;
  final int reminderDays;
  final bool showAge;
  final String? email;
  final String? whatsapp;
  final String? gender;
  final List<String> interests;
  final bool isFavorite;
  final String? shareToken;
  final String? partyDate;
  final String? partyTime;
  final String? partyLocation;
  final String? partyDescription;
  final DateTime? createdAt;

  BirthdayModel({
    required this.id,
    required this.name,
    required this.birthdate,
    this.category = 'AMIS',
    this.photoUrl,
    this.notes,
    this.reminderDays = 3,
    this.showAge = true,
    this.email,
    this.whatsapp,
    this.gender,
    this.interests = const [],
    this.isFavorite = false,
    this.shareToken,
    this.partyDate,
    this.partyTime,
    this.partyLocation,
    this.partyDescription,
    this.createdAt,
  });

  /// Days remaining until next birthday occurrence
  int get daysRemaining {
    final now = DateTime.now();
    var nextBirthday = DateTime(now.year, birthdate.month, birthdate.day);
    if (nextBirthday.isBefore(now) || nextBirthday.isAtSameMomentAs(now)) {
      nextBirthday = DateTime(now.year + 1, birthdate.month, birthdate.day);
    }
    return nextBirthday.difference(now).inDays;
  }

  /// Age on next birthday
  int get nextAge {
    final now = DateTime.now();
    var nextBirthday = DateTime(now.year, birthdate.month, birthdate.day);
    if (nextBirthday.isBefore(now)) {
      nextBirthday = DateTime(now.year + 1, birthdate.month, birthdate.day);
    }
    return nextBirthday.year - birthdate.year;
  }

  /// Whether the birthday is today
  bool get isToday {
    final now = DateTime.now();
    return now.month == birthdate.month && now.day == birthdate.day;
  }

  factory BirthdayModel.fromJson(Map<String, dynamic> json) {
    return BirthdayModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      birthdate: json['birthdate'] != null
          ? DateTime.parse(json['birthdate'])
          : DateTime.now(),
      category: json['category'] ?? 'AMIS',
      photoUrl: json['photoUrl'],
      notes: json['notes'],
      reminderDays: json['reminderDays'] ?? 3,
      showAge: json['showAge'] ?? true,
      email: json['email'],
      whatsapp: json['whatsapp'],
      gender: json['gender'],
      interests: json['interests'] != null
          ? List<String>.from(json['interests'])
          : [],
      isFavorite: json['isFavorite'] ?? false,
      shareToken: json['shareToken'],
      partyDate: json['partyDate'],
      partyTime: json['partyTime'],
      partyLocation: json['partyLocation'],
      partyDescription: json['partyDescription'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'birthdate': '${birthdate.year}-${birthdate.month.toString().padLeft(2, '0')}-${birthdate.day.toString().padLeft(2, '0')}',
      'category': category,
      'photoUrl': photoUrl,
      'notes': notes,
      'reminderDays': reminderDays,
      'showAge': showAge,
      'email': email,
      'whatsapp': whatsapp,
      'gender': gender,
      'interests': interests,
      'isFavorite': isFavorite,
      'partyDate': partyDate,
      'partyTime': partyTime,
      'partyLocation': partyLocation,
      'partyDescription': partyDescription,
    };
  }

  BirthdayModel copyWith({
    int? id,
    String? name,
    DateTime? birthdate,
    String? category,
    String? photoUrl,
    String? notes,
    int? reminderDays,
    bool? showAge,
    String? email,
    String? whatsapp,
    String? gender,
    List<String>? interests,
    bool? isFavorite,
    String? shareToken,
    String? partyDate,
    String? partyTime,
    String? partyLocation,
    String? partyDescription,
    DateTime? createdAt,
  }) {
    return BirthdayModel(
      id: id ?? this.id,
      name: name ?? this.name,
      birthdate: birthdate ?? this.birthdate,
      category: category ?? this.category,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
      reminderDays: reminderDays ?? this.reminderDays,
      showAge: showAge ?? this.showAge,
      email: email ?? this.email,
      whatsapp: whatsapp ?? this.whatsapp,
      gender: gender ?? this.gender,
      interests: interests ?? this.interests,
      isFavorite: isFavorite ?? this.isFavorite,
      shareToken: shareToken ?? this.shareToken,
      partyDate: partyDate ?? this.partyDate,
      partyTime: partyTime ?? this.partyTime,
      partyLocation: partyLocation ?? this.partyLocation,
      partyDescription: partyDescription ?? this.partyDescription,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
