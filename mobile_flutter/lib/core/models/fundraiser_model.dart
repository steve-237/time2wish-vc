class PledgeModel {
  final int id;
  final String contributorName;
  final double amount;
  final String? message;
  final DateTime createdAt;

  PledgeModel({
    required this.id,
    required this.contributorName,
    required this.amount,
    this.message,
    required this.createdAt,
  });

  factory PledgeModel.fromJson(Map<String, dynamic> json) {
    return PledgeModel(
      id: json['id'] ?? 0,
      contributorName: json['contributorName'] ?? 'Anonyme',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      message: json['message'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contributorName': contributorName,
      'amount': amount,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class FundraiserModel {
  final int id;
  final int giftId;
  final double targetAmount;
  final double currentAmount;
  final double remainingAmount;
  final bool isCompleted;
  final String currency;
  final bool active;
  final List<PledgeModel> pledges;

  FundraiserModel({
    required this.id,
    required this.giftId,
    required this.targetAmount,
    required this.currentAmount,
    required this.remainingAmount,
    this.isCompleted = false,
    this.currency = 'EUR',
    this.active = true,
    this.pledges = const [],
  });

  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    final ratio = currentAmount / targetAmount;
    return ratio > 1.0 ? 1.0 : ratio;
  }

  factory FundraiserModel.fromJson(Map<String, dynamic> json) {
    final rawPledges = json['pledges'] as List? ?? [];
    return FundraiserModel(
      id: json['id'] ?? 0,
      giftId: json['giftId'] ?? 0,
      targetAmount: (json['targetAmount'] is num)
          ? (json['targetAmount'] as num).toDouble()
          : 0.0,
      currentAmount: (json['currentAmount'] is num)
          ? (json['currentAmount'] as num).toDouble()
          : 0.0,
      remainingAmount: (json['remainingAmount'] is num)
          ? (json['remainingAmount'] as num).toDouble()
          : 0.0,
      isCompleted: json['isCompleted'] ?? false,
      currency: json['currency'] ?? 'EUR',
      active: json['active'] ?? true,
      pledges: rawPledges.map((p) => PledgeModel.fromJson(p)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'giftId': giftId,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'remainingAmount': remainingAmount,
      'isCompleted': isCompleted,
      'currency': currency,
      'active': active,
      'pledges': pledges.map((p) => p.toJson()).toList(),
    };
  }

  FundraiserModel copyWith({
    int? id,
    int? giftId,
    double? targetAmount,
    double? currentAmount,
    double? remainingAmount,
    bool? isCompleted,
    String? currency,
    bool? active,
    List<PledgeModel>? pledges,
  }) {
    return FundraiserModel(
      id: id ?? this.id,
      giftId: giftId ?? this.giftId,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      isCompleted: isCompleted ?? this.isCompleted,
      currency: currency ?? this.currency,
      active: active ?? this.active,
      pledges: pledges ?? this.pledges,
    );
  }
}
