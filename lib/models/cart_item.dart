import 'product.dart';

class CartItem {
  final Product product;
  int quantity;
  double discount;

  CartItem({required this.product, this.quantity = 1, this.discount = 0.0});

  double get subtotal => (product.price * quantity) - discount;
  double get totalDiscount => discount;

  void increaseQuantity() {
    if (quantity < product.stock) {
      quantity++;
    }
  }

  void decreaseQuantity() {
    if (quantity > 1) {
      quantity--;
    }
  }

  void setQuantity(int newQuantity) {
    if (newQuantity > 0 && newQuantity <= product.stock) {
      quantity = newQuantity;
    }
  }
}
