class BookingPriceModel {
  final double duration;
  final double hourlyRate;
  final double subtotal;
  final double serviceFee;
  final double totalAmount;

  const BookingPriceModel({
    required this.duration,
    required this.hourlyRate,
    required this.subtotal,
    this.serviceFee = 0.0,
    required this.totalAmount,
  });

  factory BookingPriceModel.fromJson(Map<String, dynamic> json) {
    final dur = double.tryParse(json['duration']?.toString() ?? '4.0') ?? 4.0;
    final rate = double.tryParse(json['hourlyRate']?.toString() ?? '1500.0') ?? 1500.0;
    final sub = double.tryParse(json['subtotal']?.toString() ?? '') ?? (dur * rate);
    final fee = double.tryParse(json['serviceFee']?.toString() ?? '0.0') ?? 0.0;
    final tot = double.tryParse(json['totalAmount']?.toString() ?? json['total']?.toString() ?? '') ?? (sub + fee);

    return BookingPriceModel(
      duration: dur,
      hourlyRate: rate,
      subtotal: sub,
      serviceFee: fee,
      totalAmount: tot,
    );
  }

  Map<String, dynamic> toJson() => {
    'duration': duration,
    'hourlyRate': hourlyRate,
    'subtotal': subtotal,
    'serviceFee': serviceFee,
    'totalAmount': totalAmount,
  };
}
