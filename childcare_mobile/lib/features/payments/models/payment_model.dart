import 'package:flutter/material.dart';

class PaymentModel {
  final String id;
  final String bookingId;
  final String parentId;
  final String babysitterId;
  final String provider;
  final String paymentIntentId;
  final double amount;
  final String currency;
  final String status;
  final DateTime? paidAt;
  final String? receiptUrl;
  final DateTime? createdAt;

  const PaymentModel({
    required this.id,
    required this.bookingId,
    required this.parentId,
    required this.babysitterId,
    this.provider = 'stripe',
    required this.paymentIntentId,
    required this.amount,
    this.currency = 'lkr',
    this.status = 'pending',
    this.paidAt,
    this.receiptUrl,
    this.createdAt,
  });

  String get formattedAmount => 'Rs. ${amount.toStringAsFixed(0)}';

  bool get isSucceeded => status == 'succeeded' || status == 'paid';
  bool get isPending => status == 'pending' || status == 'processing';
  bool get isFailed => status == 'failed';

  String get displayStatus {
    switch (status.toLowerCase()) {
      case 'succeeded':
      case 'paid':
        return 'Paid';
      case 'processing':
        return 'Processing';
      case 'failed':
        return 'Failed';
      case 'refunded':
        return 'Refunded';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'succeeded':
      case 'paid':
        return const Color(0xFF166534);
      case 'processing':
        return const Color(0xFF0369A1);
      case 'failed':
        return const Color(0xFFB91C1C);
      case 'refunded':
        return const Color(0xFF7C3AED);
      case 'pending':
      default:
        return const Color(0xFFD97706);
    }
  }

  Color get statusBgColor {
    switch (status.toLowerCase()) {
      case 'succeeded':
      case 'paid':
        return const Color(0xFFDCFCE7);
      case 'processing':
        return const Color(0xFFE0F2FE);
      case 'failed':
        return const Color(0xFFFEE2E2);
      case 'refunded':
        return const Color(0xFFEDE9FE);
      case 'pending':
      default:
        return const Color(0xFFFEF3C7);
    }
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      bookingId: (json['bookingId'] is Map ? json['bookingId']['_id'] : json['bookingId'] ?? '').toString(),
      parentId: (json['parentId'] is Map ? json['parentId']['_id'] : json['parentId'] ?? '').toString(),
      babysitterId: (json['babysitterId'] is Map ? json['babysitterId']['_id'] : json['babysitterId'] ?? '').toString(),
      provider: (json['provider'] ?? 'stripe').toString(),
      paymentIntentId: (json['paymentIntentId'] ?? '').toString(),
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : double.tryParse('${json['amount']}') ?? 0.0,
      currency: (json['currency'] ?? 'lkr').toString().toLowerCase(),
      status: (json['status'] ?? 'pending').toString(),
      paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt'].toString()) : null,
      receiptUrl: json['receiptUrl']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bookingId': bookingId,
    'parentId': parentId,
    'babysitterId': babysitterId,
    'provider': provider,
    'paymentIntentId': paymentIntentId,
    'amount': amount,
    'currency': currency,
    'status': status,
    'paidAt': paidAt?.toIso8601String(),
    'receiptUrl': receiptUrl,
    'createdAt': createdAt?.toIso8601String(),
  };
}
