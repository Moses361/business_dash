import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final String category;
  final int stock;
  final double buyingPrice;
  final double sellingPrice;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductCard({
    super.key,
    required this.name,
    required this.category,
    required this.stock,
    required this.buyingPrice,
    required this.sellingPrice,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  static const Color primary = Color(0xFF176B4D);
  static const Color softGreen = Color(0xFFE1F1EA);
  static const Color textPrimary = Color(0xFF17221D);
  static const Color textSecondary = Color(0xFF66736D);
  static const Color border = Color(0xFFE1E9E4);
  static const Color danger = Color(0xFFD64545);
  static const Color warning = Color(0xFFD58A18);

  @override
  Widget build(BuildContext context) {
    final bool isOutOfStock = stock <= 0;
    final bool isLowStock = stock > 0 && stock <= 5;
    final double profit = sellingPrice - buyingPrice;
    final bool positiveProfit = profit >= 0;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: softGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: textSecondary,
                    ),
                    tooltip: 'Product actions',
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit?.call();
                      } else if (value == 'delete') {
                        onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 12),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, color: danger),
                            SizedBox(width: 12),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _PriceBlock(
                      label: 'Selling price',
                      value: _formatAmount(sellingPrice),
                      valueColor: primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PriceBlock(
                      label: 'Buying price',
                      value: _formatAmount(buyingPrice),
                      valueColor: textPrimary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Container(height: 1, color: border),

              const SizedBox(height: 13),

              Row(
                children: [
                  Expanded(
                    child: _InfoBadge(
                      icon: isOutOfStock
                          ? Icons.remove_shopping_cart_outlined
                          : Icons.inventory_2_outlined,
                      label: isOutOfStock ? 'Out of stock' : 'Stock: $stock',
                      color: isOutOfStock
                          ? danger
                          : isLowStock
                          ? warning
                          : primary,
                      background: isOutOfStock
                          ? const Color(0xFFFCEAEA)
                          : isLowStock
                          ? const Color(0xFFFFF3DD)
                          : softGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InfoBadge(
                      icon: positiveProfit
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      label: 'Profit ${_formatAmount(profit)}',
                      color: positiveProfit ? primary : danger,
                      background: positiveProfit
                          ? softGreen
                          : const Color(0xFFFCEAEA),
                    ),
                  ),
                ],
              ),

              if (isLowStock || isOutOfStock) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: isOutOfStock
                        ? const Color(0xFFFCEAEA)
                        : const Color(0xFFFFF3DD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isOutOfStock
                            ? Icons.warning_rounded
                            : Icons.warning_amber_rounded,
                        size: 17,
                        color: isOutOfStock ? danger : warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isOutOfStock
                              ? 'This product is currently unavailable for sale.'
                              : 'Low stock — consider restocking soon.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isOutOfStock ? danger : warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    return 'KSh ${amount.toStringAsFixed(2)}';
  }
}

class _PriceBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _PriceBlock({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: ProductCard.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
