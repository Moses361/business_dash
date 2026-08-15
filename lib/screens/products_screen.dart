import 'package:flutter/material.dart';

import '../widgets/product_card.dart';
import 'add_product_screen.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Products',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.tune_rounded)),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _CustomFilterChip(
                    label: 'All',
                    selected: true,
                    onSelected: (_) {},
                  ),
                  const SizedBox(width: 8),
                  _CustomFilterChip(
                    label: 'Motorcycle Parts',
                    selected: false,
                    onSelected: (_) {},
                  ),
                  const SizedBox(width: 8),
                  _CustomFilterChip(
                    label: 'Agrovet',
                    selected: false,
                    onSelected: (_) {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '125 Products',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'In Stock: 52',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                children: const [
                  ProductCard(
                    name: 'Brake Pads',
                    category: 'Motorcycle Parts',
                    stock: 15,
                    price: 'KSh 2,500',
                  ),

                  ProductCard(
                    name: 'Chain Kit',
                    category: 'Motorcycle Parts',
                    stock: 8,
                    price: 'KSh 1,800',
                  ),

                  ProductCard(
                    name: 'Engine Oil',
                    category: 'Lubricants',
                    stock: 4,
                    price: 'KSh 1,200',
                  ),

                  ProductCard(
                    name: 'Spark Plug',
                    category: 'Motorcycle Parts',
                    stock: 20,
                    price: 'KSh 450',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }
}

class _CustomFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final Function(bool) onSelected;

  const _CustomFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<_CustomFilterChip> createState() => _CustomFilterChipState();
}

class _CustomFilterChipState extends State<_CustomFilterChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onSelected(!widget.selected);
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: widget.selected
                ? LinearGradient(
                    colors: [Colors.green.shade600, Colors.green.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: widget.selected
                ? null
                : Border.all(color: Colors.grey.shade300),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.selected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
