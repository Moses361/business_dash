import 'package:flutter/material.dart';

class AboutVeroonScreen extends StatelessWidget {
  const AboutVeroonScreen({super.key});

  static const Color primary = Color(0xFF176B4D);
  static const Color background = Color(0xFFF6F8F7);
  static const Color textPrimary = Color(0xFF17221D);
  static const Color textSecondary = Color(0xFF66736D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'About Veroon',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),

          // Veroon business avatar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primary, Color(0xFF0F513A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                _AvatarBubble(
                  size: 92,
                  background: Colors.white.withValues(alpha: 0.16),
                  borderColor: Colors.white.withValues(alpha: 0.4),
                  icon: Icons.storefront_rounded,
                  iconSize: 44,
                  iconColor: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Veroon',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Business & Sales Operations',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Developer card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      const _AvatarBubble(
                        size: 58,
                        background: Color(0xFFE1F1EA),
                        borderColor: Color(0xFFB9DCCB),
                        icon: Icons.computer_rounded,
                        iconSize: 28,
                        iconColor: primary,
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Developed by',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Moses',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'App Developer',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  const _AboutRow(
                    icon: Icons.phone_outlined,
                    label: 'Contact',
                    value: '0759930912',
                  ),
                  const Divider(height: 24),
                  const _AboutRow(
                    icon: Icons.verified_outlined,
                    label: 'Version',
                    value: '1.0.0',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'About this app',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Veroon helps small businesses keep track of products, '
            'sales, expenses, stock levels and business performance '
            'in one simple place.',
            style: TextStyle(fontSize: 13, height: 1.5, color: textSecondary),
          ),
          const SizedBox(height: 28),
          Center(
            child: Text(
              'Built with care for everyday business.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  final double size;
  final Color background;
  final Color borderColor;
  final IconData icon;
  final double iconSize;
  final Color iconColor;

  const _AvatarBubble({
    required this.size,
    required this.background,
    required this.borderColor,
    required this.icon,
    required this.iconSize,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
        border: Border.all(color: borderColor, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: iconSize, color: iconColor),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AboutRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE1F1EA),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: const Color(0xFF176B4D), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF66736D), fontSize: 12),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF17221D),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
