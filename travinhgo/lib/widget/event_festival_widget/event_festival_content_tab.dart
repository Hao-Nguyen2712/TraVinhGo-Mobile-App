import 'package:flutter/material.dart';

class EventFestivalContentTab extends StatelessWidget {
  final String? description;

  const EventFestivalContentTab({
    super.key,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 18,
          ),
          const Row(
            children: [
              Icon(Icons.library_books_outlined,
                  color: Color(0xFF8F83F3), size: 24),
              SizedBox(width: 8),
              Text(
                "Mô tả sự kiện",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description ?? 'Chưa có mô tả cho sự kiện này.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
