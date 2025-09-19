import 'package:flutter/material.dart';

/// Supported payment methods across checkout flows.
enum PaymentMethod { cash, card, qris, ewallet }

extension PaymentMethodDetails on PaymentMethod {
  /// Identifier saved to storage or sent to services.
  String get id {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.qris:
        return 'qris';
      case PaymentMethod.ewallet:
        return 'ewallet';
    }
  }

  /// Human-friendly label.
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Tunai';
      case PaymentMethod.card:
        return 'Kartu';
      case PaymentMethod.qris:
        return 'QRIS';
      case PaymentMethod.ewallet:
        return 'E-Wallet';
    }
  }

  /// Icon representing the payment method.
  IconData get icon {
    switch (this) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.qris:
        return Icons.qr_code;
      case PaymentMethod.ewallet:
        return Icons.account_balance_wallet;
    }
  }
}

/// Helper utilities for mapping persisted payment identifiers back to enum values.
class PaymentMethodHelper {
  const PaymentMethodHelper._();

  /// Convert a string identifier to its [PaymentMethod] equivalent.
  static PaymentMethod parse(String id) {
    switch (id) {
      case 'cash':
        return PaymentMethod.cash;
      case 'card':
        return PaymentMethod.card;
      case 'qris':
        return PaymentMethod.qris;
      case 'ewallet':
        return PaymentMethod.ewallet;
      default:
        return PaymentMethod.cash;
    }
  }

  /// Return the human label for a payment identifier.
  static String labelFor(String id) => parse(id).label;
}
