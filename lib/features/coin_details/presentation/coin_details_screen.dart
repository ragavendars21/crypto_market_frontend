import 'package:flutter/material.dart';

// Placeholder until Phase 7 builds the details screen and chart.
class CoinDetailsScreen extends StatelessWidget {
  const CoinDetailsScreen({super.key, required this.coinId});

  final String coinId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(coinId)),
      body: const Center(child: Text('Coin details coming in Phase 7')),
    );
  }
}
