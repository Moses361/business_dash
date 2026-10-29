
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
                ClipOval(
                  child: Image.asset(
                    'assets/veroon logo.png',
                    width: 92,
                    height: 92,
                    fit: BoxFit.cover,
                  ),
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
                  'Business Management',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          "assets/developer_icon.png",
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                        ),
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
          const SizedBox(height: 24),
          const Text(
            'About Veroon',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Veroon brings essential business management tools together '
            'in one place. Manage products, inventory, sales, expenses, '
            'and business performance with greater clarity, confidence, '
            'and control.',
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE1EAE5)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A Message from the Developer',
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.4,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'I built Veroon with a genuine passion for technology '
                  'and a belief that the right tools can make a meaningful '
                  'difference in how businesses operate and grow.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.7,
                    color: textSecondary,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'My vision is to make business management simpler, '
                  'more organized, and more accessible, giving business '
                  'owners greater confidence in their daily decisions. '
                  'Every feature is part of that journey, and every '
                  'improvement is an opportunity to serve businesses better.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.7,
                    color: textSecondary,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Veroon is more than an application to me. It represents '
                  'my commitment to creating technology that solves real '
                  'problems, supports ambition, and grows alongside the '
                  'people who use it.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.7,
                    color: textSecondary,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Thank you for believing in Veroon and being part of '
                  'this journey. Your trust inspires me to keep learning, '
                  'building, and making Veroon better every day.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.7,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Built with passion, purpose, and a vision for better business management.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 12),
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
            style: const TextStyle(
              color: Color(0xFF66736D),
              fontSize: 12,
            ),
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
