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
    final today = DateTime(now.year, now.month, now.day);
    var nextBirthday = DateTime(now.year, birthdate.month, birthdate.day);
    if (nextBirthday.isBefore(today)) {
      nextBirthday = DateTime(now.year + 1, birthdate.month, birthdate.day);
    }
    return nextBirthday.difference(today).inDays;
  }

  /// Age on next birthday
  int get nextAge {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var nextBirthday = DateTime(now.year, birthdate.month, birthdate.day);
    if (nextBirthday.isBefore(today)) {
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
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      birthdate: json['birthdate'] != null
          ? DateTime.parse(json['birthdate'].toString())
          : DateTime.now(),
      category: json['category']?.toString() ?? 'AMIS',
      photoUrl: json['photoUrl']?.toString(),
      notes: json['notes']?.toString(),
      reminderDays: json['reminderDays'] is int
          ? json['reminderDays'] as int
          : int.tryParse(json['reminderDays']?.toString() ?? '') ?? 3,
      showAge: json['showAge'] == true || json['showAge'] == null,
      email: json['email']?.toString(),
      whatsapp: json['whatsapp']?.toString(),
      gender: json['gender']?.toString(),
      interests: json['interests'] != null
          ? List<String>.from(json['interests'])
          : [],
      isFavorite: json['isFavorite'] == true,
      shareToken: json['shareToken']?.toString(),
      partyDate: json['partyDate']?.toString(),
      partyTime: json['partyTime']?.toString(),
      partyLocation: json['partyLocation']?.toString(),
      partyDescription: json['partyDescription']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'shareToken': shareToken,
      'partyDate': partyDate,
      'partyTime': partyTime,
      'partyLocation': partyLocation,
      'partyDescription': partyDescription,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toApiJson() {
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
