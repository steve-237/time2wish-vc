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

  GiftModel({
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

  factory GiftModel.fromJson(Map<String, dynamic> json) {
    return GiftModel(
      id: json['id'] ?? 0,
      birthdayId: json['birthdayId'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      priceRange: json['priceRange'],
      url: json['url'],
      imageUrl: json['imageUrl'],
      isReserved: json['isReserved'] ?? false,
      reservedByName: json['reservedByName'],
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'priceRange': priceRange,
      'url': url,
      'imageUrl': imageUrl,
    };
  }
}
