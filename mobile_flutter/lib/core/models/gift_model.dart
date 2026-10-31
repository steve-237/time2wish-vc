class GiftModel {
  final int id;
  final int birthdayId;
  final String name;
  final String? description;
  final String? priceRange;
  final String? url;
  final String? imageUrl;
  final bool isReserved;
  final String? reservedByName;
  final int upvotes;
  final int downvotes;
  final DateTime? createdAt;

  const GiftModel({
    required this.id,
    required this.birthdayId,
    required this.name,
    this.description,
    this.priceRange,
    this.url,
    this.imageUrl,
    this.isReserved = false,
    this.reservedByName,
    this.upvotes = 0,
    this.downvotes = 0,
    this.createdAt,
  });

  factory GiftModel.fromJson(Map<String, dynamic> json, [int? fallbackId]) {
    final rawId = json['id'];
    int parsedId = 0;
    if (rawId is int) {
      parsedId = rawId;
    } else if (rawId != null) {
      parsedId = int.tryParse(rawId.toString()) ?? 0;
    }
    if (parsedId == 0 && fallbackId != null && fallbackId != 0) {
      parsedId = fallbackId;
    } else if (parsedId == 0) {
      parsedId = DateTime.now().microsecondsSinceEpoch;
    }

    return GiftModel(
      id: parsedId,
      birthdayId: json['birthdayId'] is int
          ? json['birthdayId'] as int
          : int.tryParse(json['birthdayId']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      priceRange: json['priceRange']?.toString(),
      url: json['url']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      isReserved: json['isReserved'] == true,
      reservedByName: json['reservedByName']?.toString(),
      upvotes: json['upvotes'] is int
          ? json['upvotes'] as int
          : int.tryParse(json['upvotes']?.toString() ?? '') ?? 0,
      downvotes: json['downvotes'] is int
          ? json['downvotes'] as int
          : int.tryParse(json['downvotes']?.toString() ?? '') ?? 0,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is String
              ? DateTime.tryParse(json['createdAt'] as String)
              : null)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'birthdayId': birthdayId,
      'name': name,
      'description': description,
      'priceRange': priceRange,
      'url': url,
      'imageUrl': imageUrl,
      'isReserved': isReserved,
      'reservedByName': reservedByName,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toApiJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      if (priceRange != null) 'priceRange': priceRange,
      if (url != null) 'url': url,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  GiftModel copyWith({
    int? id,
    int? birthdayId,
    String? name,
    String? description,
    String? priceRange,
    String? url,
    String? imageUrl,
    bool? isReserved,
    String? reservedByName,
    int? upvotes,
    int? downvotes,
    DateTime? createdAt,
  }) {
    return GiftModel(
      id: id ?? this.id,
      birthdayId: birthdayId ?? this.birthdayId,
      name: name ?? this.name,
      description: description ?? this.description,
      priceRange: priceRange ?? this.priceRange,
      url: url ?? this.url,
      imageUrl: imageUrl ?? this.imageUrl,
      isReserved: isReserved ?? this.isReserved,
      reservedByName: reservedByName ?? this.reservedByName,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
