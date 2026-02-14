import 'package:flutter/material.dart';

class LocationConfirmSheet extends StatelessWidget {
  final String? city;
  final String? district;
  final Function(bool) onResult;

  const LocationConfirmSheet({
    super.key,
    this.city,
    this.district,
    required this.onResult,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Konumunuz: $district / $city",
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          const Text("Burası doğru konum mu?"),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onResult(true),
                  child: const Text("Evet"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onResult(false),
                  child: const Text("Hayır"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}