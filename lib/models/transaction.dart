import 'transaction_item.dart';

class Transaction {
  final int? id;
  final double total;
  final double tax;
  final double discount;
  final String paymentMethod;
  final double amountPaid;
  final double change;
  final String? customerName;
  final String? customerPhone;
  final String? notes;
  final DateTime createdAt;
  final List<TransactionItem> items;

  Transaction({
    this.id,
    required this.total,
    this.tax = 0.0,
    this.discount = 0.0,
    required this.paymentMethod,
    required this.amountPaid,
    this.change = 0.0,
    this.customerName,
    this.customerPhone,
    this.notes,
    DateTime? createdAt,
    this.items = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total': total,
      'tax': tax,
      'discount': discount,
      'payment_method': paymentMethod,
      'amount_paid': amountPaid,
      'change': change,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      total: (map['total'] ?? 0).toDouble(),
      tax: (map['tax'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      paymentMethod: map['payment_method'] ?? 'cash',
      amountPaid: (map['amount_paid'] ?? 0).toDouble(),
      change: (map['change'] ?? 0).toDouble(),
      customerName: map['customer_name'],
      customerPhone: map['customer_phone'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Transaction copyWith({
    int? id,
    double? total,
    double? tax,
    double? discount,
    String? paymentMethod,
    double? amountPaid,
    double? change,
    String? customerName,
    String? customerPhone,
    String? notes,
    DateTime? createdAt,
    List<TransactionItem>? items,
  }) {
    return Transaction(
      id: id ?? this.id,
      total: total ?? this.total,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amountPaid: amountPaid ?? this.amountPaid,
      change: change ?? this.change,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }

  double get subtotal => total - tax + discount;

  String get receiptNumber =>
      'TRX${id?.toString().padLeft(6, '0') ?? '000000'}';
}
