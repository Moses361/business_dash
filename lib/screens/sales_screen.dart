import 'package:flutter/material.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today's Sales",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'KSh 8,450',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 24),

            const Text(
              'Recent transactions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    leading: Icon(Icons.receipt_long),
                    title: Text('Brake Pads'),
                    subtitle: Text('Today • 10:32 AM'),
                    trailing: Text('KSh 2,500'),
                  ),
                  ListTile(
                    leading: Icon(Icons.receipt_long),
                    title: Text('Chain Kit'),
                    subtitle: Text('Today • 11:45 AM'),
                    trailing: Text('KSh 1,800'),
                  ),
                  ListTile(
                    leading: Icon(Icons.receipt_long),
                    title: Text('Engine Oil'),
                    subtitle: Text('Today • 1:20 PM'),
                    trailing: Text('KSh 1,200'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
