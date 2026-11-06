enum CheckoutPaymentMethod { cash, mpesa }

class CheckoutCartItem {
  final int productId;
  final int quantity;

  const CheckoutCartItem({required this.productId, required this.quantity});
}

class CheckoutPaymentInput {
  final CheckoutPaymentMethod method;
  final double amount;
  final String? reference;
  final String? note;

  const CheckoutPaymentInput({
    required this.method,
    required this.amount,
    this.reference,
    this.note,
  });
}

class CheckoutResult {
  final int orderId;
  final String orderSyncId;
  final double totalAmount;
  final double amountPaid;
  final double balanceDue;
  final List<int> saleIds;

  const CheckoutResult({
    required this.orderId,
    required this.orderSyncId,
    required this.totalAmount,
    required this.amountPaid,
    required this.balanceDue,
    required this.saleIds,
  });
}
