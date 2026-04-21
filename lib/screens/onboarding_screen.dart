import 'package:flutter/material.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String travelStyle = 'Adventure';
  String homeCity = '';

  @override
  Widget build(BuildContext context) {
    final styles = ['Adventure', 'Relaxed', 'City', 'Food', 'Roadtrip'];

    return Scaffold(
      appBar: AppBar(title: const Text('Quick setup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your travel vibe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Container(height: 3, width: 40, color: const Color(0xFF4DB6AC)),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: travelStyle,
              items: styles.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => travelStyle = v ?? 'Adventure'),
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Travel style'),
            ),
            const SizedBox(height: 12),

            TextField(
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Home city (optional)'),
              onChanged: (v) => setState(() => homeCity = v),
            ),
            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(),
                    ),
                  );
                },
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}